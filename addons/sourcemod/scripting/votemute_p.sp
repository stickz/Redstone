#include <sourcemod>
#include <sdktools>
#include <sourcecomms>
#include <nd_stocks>

#undef REQUIRE_PLUGIN
#tryinclude <adminmenu>
#define REQUIRE_PLUGIN

ConVar g_Cvar_Limits;
ConVar g_Cvar_Admins;
ConVar g_Cvar_Duration;

Menu g_hVoteMenu = null;

#define VOTE_CLIENTID	0
#define VOTE_USERID		1
#define VOTE_NAME		0
#define VOTE_NO 		"###no###"
#define VOTE_YES 		"###yes###"

#define VOTE_TYPE_GAG 0
#define VOTE_TYPE_MUTE 1
#define VOTE_TYPE_SILENCE 2

#define INVALID_TARGET -1
#define PREFIX "\x05[xG]"

int g_voteClient[2];
char g_voteInfo[3][65];

int g_votetype = 0;

//Version is auto-filled by the travis builder
public Plugin myinfo =
{
	name 		= "Vote Gag, Mute, Silence",
	author 		= "<eVa>Dog, Stickz",
	description 	= "Allows vote gag, mute and silencing for sourcecomms",
	version 	= "dummy",
	url 		= "http://www.theville.org"
}

/* Auto Updater */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/votemute_p/votemute_p.txt"
#include "updater/standard.sp"

public void OnPluginStart()
{
	g_Cvar_Limits = CreateConVar("sm_votemute_limit", "0.51", "percent required for successful mute vote or mute silence.");
	g_Cvar_Admins = CreateConVar("sm_votemute_adminonly", "0", "1= admins only, 0 = regular players allowed");
	g_Cvar_Duration = CreateConVar("sm_votemute_duration", "60", "set punishment duration, 0 = permanent");
	
	AutoExecConfig(true, "votemute_p");
	
	//Allowed for ALL players
	RegConsoleCmd("sm_votemute", Command_Votemute,  "sm_votemute <player> ");  
	RegConsoleCmd("sm_votesilence", Command_Votesilence,  "sm_votesilence <player> ");  
	RegConsoleCmd("sm_votegag", Command_Votegag,  "sm_votegag <player> "); 

	LoadTranslations("common.phrases");
	LoadTranslations("votemute_p.phrases");
	
	AddUpdaterLibrary(); //auto-updater
}

public Action Command_Votemute(int client, int args)
{
	if (!CanStartVote(client))
		return Plugin_Handled;
	
	if (args < 1)
	{
		g_votetype = VOTE_TYPE_MUTE;
		DisplayVoteTargetMenu(client);
	}
	else
	{
		char arg[64];
		GetCmdArg(1, arg, sizeof(arg));
		
		int target = FindTarget(client, arg);
		if (target == INVALID_TARGET)
			return Plugin_Handled;

		else if (SourceComms_GetClientMuteType(target) != bNot)
		{
			PrintToChat(client, "%s %t!", PREFIX, "Already Muted"); //This client is already muted!
			return Plugin_Handled;
		}

		g_votetype = VOTE_TYPE_MUTE;
		DisplayVoteMuteMenu(client, target);
	}
	
	return Plugin_Handled;
}

public Action Command_Votesilence(int client, int args)
{
	if (!CanStartVote(client))
		return Plugin_Handled;
	
	if (args < 1)
	{
		g_votetype = VOTE_TYPE_SILENCE;
		DisplayVoteTargetMenu(client);
	}
	else
	{
		char arg[64];
		GetCmdArg(1, arg, sizeof(args));
		
		int target = FindTarget(client, arg);
		if (target == INVALID_TARGET)
			return Plugin_Handled;

		else if (isSilenced(target))
		{
			PrintToChat(client, "%s %t!", PREFIX, "Already Silenced"); //This client is already silenced
			return Plugin_Handled;		
		}

		g_votetype = VOTE_TYPE_SILENCE;
		DisplayVoteMuteMenu(client, target);
	}
	return Plugin_Handled;
}

public Action Command_Votegag(int client, int args)
{
	if (!CanStartVote(client))
		return Plugin_Handled;

	if (args < 1)
	{
		g_votetype = VOTE_TYPE_GAG;
		DisplayVoteTargetMenu(client);
	}
	else
	{
		char arg[64];
		GetCmdArg(1, arg, sizeof(arg));
		
		int target = FindTarget(client, arg);
		if (target == INVALID_TARGET)
			return Plugin_Handled;

		else if (SourceComms_GetClientGagType(target) != bNot)
		{
			PrintToChat(client, "%s %t!", PREFIX, "Already Gagged"); //This client is already gagged
			return Plugin_Handled;
		}
		
		g_votetype = VOTE_TYPE_GAG;
		DisplayVoteMuteMenu(client, target);
	}
	return Plugin_Handled;
}

bool CanStartVote(int client)
{
	if (IsVoteInProgress())
	{
		PrintToChat(client, "%s %t.", PREFIX, "Vote in Progress"); //Please wait for the current server-wide vote to finish
		return false;
	}

	if (g_Cvar_Admins.BoolValue && !IsValidAdmin(client, "k"))
	{
		PrintToChat(client, "%s %t.", PREFIX, "Moderater Only"); //This command is for server moderators only
		return false;
	}		
	
	if (!TestVoteDelay(client))
		return false;
		
	if (isSilenced(client))
	{
		PrintToChat(client, "%s %t!", PREFIX, "Silence Use"); //You cannot use this feature while silenced
		return false;				
	}

	return true;
}

void DisplayVoteMuteMenu(int client, int target)
{
	g_voteClient[VOTE_CLIENTID] = target;
	g_voteClient[VOTE_USERID] = GetClientUserId(target);

	GetClientName(target, g_voteInfo[VOTE_NAME], sizeof(g_voteInfo[]));
	
	char Name[16];
	switch (g_votetype)
	{
		case VOTE_TYPE_MUTE: 	Format(Name, sizeof(Name), "Mute");
		case VOTE_TYPE_GAG:  	Format(Name, sizeof(Name), "Gag");
		case VOTE_TYPE_SILENCE: Format(Name, sizeof(Name), "Silence");	
	}
	
	PrintAndLogVoteStart(client, target, Name);
	g_hVoteMenu = CreateGlobalVoteMenu(Name);
}

Menu CreateGlobalVoteMenu(const char[] name)
{
	//Create new menu object
	Menu menu = new Menu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
	
	//Set various menu properties
	menu.SetTitle("%s Player:", name);
	menu.AddItem(VOTE_YES, "Yes");
	menu.AddItem(VOTE_NO, "No");
	menu.ExitButton(false);
	menu.DisplayVoteToAll(20);
	
	//return the created menu
	return menu;
}

void PrintAndLogVoteStart(int client, int target, const char name[])
{
	char Message[64];
	Format(Message, sizeof(Message), "\"%L\" initiated a %s vote against \"%L\"", client, Name, target);
	PrintToAdmins(Message, "a");
	LogAction(client, target, Message);
}

void DisplayVoteTargetMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Vote);
	
	char title[100];
	Format(title, sizeof(title), "%s", "Choose player:");
	menu.SetTitle(title);
	menu.ExitBackButton(true);
	
	char playername[128], identifier[64];
	for (int i = 1; i < GetMaxClients(); i++)
	{
		if (IsClientInGame(i) && !(GetUserFlagBits(i) & ADMFLAG_CHAT))
		{
			GetClientName(i, playername, sizeof(playername));
			IntToString(i, identifier, sizeof(identifier));
			menu.AddItem(identifier, playername);
		}
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}


public int MenuHandler_Vote(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			char info[32], String:name[32];
			menu.GetItem(param2, info, sizeof(info), _, name, sizeof(name));
			
			int target = StringToInt(info);
			if (target == 0)
				PrintToChat(param1, "[SM] %s", "Player no longer available");

			else
				DisplayVoteMuteMenu(param1, target);	
		}
	}
}

public int Handler_VoteCallback(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete(g_hVoteMenu);
			g_hVoteMenu = null;
		}
		
		case MenuAction_Display:
		{
			char title[64];
			menu.GetTitle(title, sizeof(title));
			
			char buffer[255];
			Format(buffer, sizeof(buffer), "%s %s", title, g_voteInfo[VOTE_NAME]);

			Panel panel = Panel param2;
			panel.SetTitle(buffer);	
		}
		
		case MenuAction_DisplayItem:
		{
			char display[64];
			menu.GetItem(param2, "", 0, _, display, sizeof(display));
		 
			if (strcmp(display, "No") == 0 || strcmp(display, "Yes") == 0)
			{
				char buffer[255];
				Format(buffer, sizeof(buffer), "%s", display);

				return RedrawMenuItem(buffer);
			}		
		}
		//case MenuAction_Select: VoteSelect(menu, param1, param2);
		
		case MenuAction_VoteCancel:
		{
			if (param1 == VoteCancel_NoVotes)	
				PrintToChatAll("[SM] %s", "No Votes Cast");
		}
		
		case MenuAction_VoteEnd:
		{
			char item[64], display[64];
			float percent, limit;
			int votes, totalVotes;
			
			GetMenuVoteInfo(param2, votes, totalVotes);
			menu.GetItem(param1, item, sizeof(item), _, display, sizeof(display));
			
			if (strcmp(item, VOTE_NO) == 0 && param1 == 1)
				votes = totalVotes - votes; // Reverse the votes to be in relation to the Yes option.
			
			percent = GetVotePercent(votes, totalVotes);
			limit = g_Cvar_Limits.FloatValue;
			
			if ((strcmp(item, VOTE_YES) == 0 && FloatCompare(percent,limit) < 0 && param1 == 0) || (strcmp(item, VOTE_NO) == 0 && param1 == 1))
			{
				LogAction(-1, -1, "Vote failed.");
				PrintToChatAll("[SM] %s", "Vote Failed", RoundToNearest(100.0*limit), RoundToNearest(100.0*percent), totalVotes);
			}
			else
			{
				PrintToChatAll("[SM] %s", "Vote Successful", RoundToNearest(100.0*percent), totalVotes);			
				
				switch (g_votetype)
				{
					case VOTE_TYPE_MUTE:
					{
						PrintToChatAll("[SM] %s", "Muted target", "_s", g_voteInfo[VOTE_NAME]);
						LogAction(-1, g_voteClient[VOTE_CLIENTID], "Vote mute successful, muted \"%L\" ", g_voteClient[VOTE_CLIENTID]);
						SourceComms_SetClientMute(g_voteClient[VOTE_CLIENTID], true, g_Cvar_Duration.IntValue, true, "Voted by players");
					}
					
					case VOTE_TYPE_GAG:
					{
						PrintToChatAll("[SM] %s", "Gagged target", "_s", g_voteInfo[VOTE_NAME]);	
						LogAction(-1, g_voteClient[VOTE_CLIENTID], "Vote gag successful, gagged \"%L\" ", g_voteClient[VOTE_CLIENTID]);
						SourceComms_SetClientGag(g_voteClient[VOTE_CLIENTID], true, g_Cvar_Duration.IntValue, true, "Voted by players");						
					}
					
					case VOTE_TYPE_SILENCE:
					{
						PrintToChatAll("[SM] %s", "Silenced target", "_s", g_voteInfo[VOTE_NAME]);	
						LogAction(-1, g_voteClient[VOTE_CLIENTID], "Vote silence successful, silenced \"%L\" ", g_voteClient[VOTE_CLIENTID]);
						SourceComms_SetClientGag(g_voteClient[VOTE_CLIENTID], true, g_Cvar_Duration.IntValue, true, "Voted by players");
						SourceComms_SetClientMute(g_voteClient[VOTE_CLIENTID], true, g_Cvar_Duration.IntValue, true, "Voted by players");					
					}				
				}
			}		
		}	
	}
	return 0;	
}

bool isSilenced(client)
{
	return SourceComms_GetClientMuteType(client) != bNot && SourceComms_GetClientGagType(client) != bNot;
}

float GetVotePercent(int votes, int totalVotes)
{
	return FloatDiv(float(votes),float(totalVotes));
}

bool TestVoteDelay(client)
{
 	int delay = CheckVoteDelay();
 	
 	if (delay > 0)
 	{
 		PrintToChat(client, "%s %t.", PREFIX, "Wait Seconds", delay);
 		return false;
 	}
 	
	return true;
}
