#include <sourcemod>
#include <clientprefs>
#include <nd_print>

#define RESPAWN_COMMANDS_SIZE 6

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
	RegServerCmd("quit", OnDown); // Register quit to attempt client reconnection
	
	AddUpdaterLibrary(); //Auto-Updater
	
	AddClientPrefsSupport(); // For solution assist
	
	/* Translations for print-outs */
	LoadTranslations("nd_tools.phrases");
}

public Action OnDown(int args) 
{
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsClientInGame(i) && !IsFakeClient(i)) 
		{
           	ClientCommand(i, "retry"); // force retry
		}
	}
	return Plugin_Continue;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (client && GetClientTeam(client) > 1)
	{
		for (int idx = 0; idx < RESPAWN_COMMANDS_SIZE; idx++)
		{
			if (StrContains(sArgs, nd_respawn_commands[idx], false) > -1)
			{
				new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);
				
				PrintToChat(client, "\x05[xG] %t!", "Spawn Bug"); //Change class and select anther spawn point			
					
				SetCmdReplySource(old);
				return Plugin_Stop; 					
			}		
		}	
	}	
	return Plugin_Continue;
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
