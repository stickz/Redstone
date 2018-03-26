#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#include <nd_stocks>
#include <nd_com_eng>
#include <nd_print>
#include <nd_rounds>

#define KILL_COMMANDS_SIZE 6
#define RESPAWN_COMMANDS_SIZE 6

#define INVALID_USERID 0

public Plugin myinfo =
{
	name = "[ND] Useful Tools",
	author = "stickz",
	description = "Provides useful tools for nuclear dawn",
	version = "dummy",
	url = "https://github.com/stickz/Redstone/"	
};

/* Auto-Updater */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_tools/nd_tools.txt"
#include "updater/standard.sp"

ConVar hSuicideDelay;

char nd_kill_commands[KILL_COMMANDS_SIZE][] =
{
	"stuck",
	"i'm stuck",
	"im stuck",
	"i am stuck",
	"suicide",
	"die"};

char nd_respawn_commands[RESPAWN_COMMANDS_SIZE][] =
{
	"can't spawn",
	"cant spawn",
	"cannot spawn",
	"can not spawn",
	"i can't spawn",
	"respawn"};

public void OnPluginStart()
{
	/* Related to player suicide */
	RegKillCommands(); // Chat commands to suicide
	AddCommandListener(Command_InterceptSuicide, "kill"); // Interrupt for console suicide
	hSuicideDelay = CreateConVar("sm_suicide_delay", "3", "set suicide delay between 0-8 seconds.");
	
	RegServerCmd("quit", OnDown); // Register quit to attempt client reconnection
	
	AddUpdaterLibrary(); //Auto-Updater
	
	AddClientPrefsSupport(); // For solution assist
	
	/* Translations for print-outs */
	LoadTranslations("nd_tools.phrases");
	LoadTranslations("numbers.phrases");
}

void RegKillCommands()
{
	RegConsoleCmd("sm_kill", Command_killme);
	RegConsoleCmd("sm_die", Command_killme);
	RegConsoleCmd("sm_suicide", Command_killme);
	RegConsoleCmd("sm_stuck", Command_killme);	
}

public Action Command_killme(int client, int args)
{   
	commitSucide(client);	
	return Plugin_Handled;        
}

public Action OnDown(int args)
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && !IsFakeClient(i))
           ClientCommand(i, "retry"); // force retry
}	   

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (client)
	{
		if (GetClientTeam(client) > 1)
		{	
			for (int idx = 0; idx < KILL_COMMANDS_SIZE; idx++)
			{
				if (strcmp(sArgs, nd_kill_commands[idx], false) == 0)
				{
					new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);

					//ForcePlayerSuicide(client);
					commitSucide(client);
					
					SetCmdReplySource(old);
					return Plugin_Stop;					
				}

				else if (StrContains(sArgs, nd_respawn_commands[idx], false) > -1)
				{
					new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);
				
					PrintToChat(client, "\x05[xG] %t!", "Spawn Bug"); //Change class and select anther spawn point			
					
					SetCmdReplySource(old);
					return Plugin_Stop; 					
				}		
			}	
		}
	}	
	return Plugin_Continue;
}			


public Action Command_InterceptSuicide(int client, const char[] command, int args)
{
	if (client && GetClientTeam(client) > 1)
	{	
		commitSucide(client);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

void commitSucide(int client)
{
	if (IsPlayerAlive(client))
	{	
		int delay = hSuicideDelay.IntValue;

		if (delay == 0 || ND_IsCommander(client) || !ND_RoundStarted())
		{
			ForcePlayerSuicide(client);
			return;
		}
		
		PrintToChat(client, "\x05[xG] %t", "Suicide Request", NumberInEnglish(delay));
		CreateTimer(float(delay), TIMER_DelayedSucide, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action TIMER_DelayedSucide(Handle timer, any Userid)
{
	// If the client is invalid, return
	int client = GetClientOfUserId(Userid);	
	if (client == INVALID_USERID)
		return Plugin_Handled;
	
	// If the client is alive, kill them
	if (IsPlayerAlive(client))
		ForcePlayerSuicide(client);

	return Plugin_Handled;
}

/* Client prefs support */
Handle cookie_solution_assist = INVALID_HANDLE;
bool option_solution_assist[MAXPLAYERS + 1] = {true,...};

void AddClientPrefsSupport()
{
	cookie_solution_assist = RegClientCookie("Solution Assist On/Off", "", CookieAccess_Protected);
	new info;
	SetCookieMenuItem(CookieMenuHandler_SolutionAssist, any:info, "Solution Assist");
	
	LoadTranslations("common.phrases"); //required for on and off	
}

public CookieMenuHandler_SolutionAssist(int client, CookieMenuAction:action, any:info, char[] buffer, int maxlen)
{
	switch (action)
	{
		case CookieMenuAction_DisplayOption:
		{
			char status[10];
			Format(status, sizeof(status), "%T", option_solution_assist[client] ? "On" : "Off", client);		
			Format(buffer, maxlen, "%T: %s", "Cookie Solution Assist", client, status);		
		}
		
		case CookieMenuAction_SelectOption:
		{
			option_solution_assist[client] = !option_solution_assist[client];
			SetClientCookie(client, cookie_solution_assist, option_solution_assist[client] ? "On" : "Off");		
			ShowCookieMenu(client);		
		}	
	}
}

public void OnClientCookiesCached(int client) {
	option_solution_assist[client] = GetCookieSolutionAssist(client);
}

bool GetCookieSolutionAssist(int client)
{
	char buffer[10];
	GetClientCookie(client, cookie_solution_assist, buffer, sizeof(buffer));
	
	return !StrEqual(buffer, "Off");
}