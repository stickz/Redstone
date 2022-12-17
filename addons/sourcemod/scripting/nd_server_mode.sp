#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
    name = "[ND] Server Mode",
    author = "Stickz",
    description = "Enables map test mode for gameserver",
    version = "dummy",
    url = "https://github.com/stickz/Redstone"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_server_mode/nd_server_mode.txt"
#include "updater/standard.sp"

#define SERVER_MODE_REGULAR 0
#define SERVER_MODE_MAPTEST 1

int serverMode = SERVER_MODE_REGULAR;

public void OnPluginStart()
{
	RegAdminCmd("sm_MapTestMode", CMD_TriggerMapTestMode, ADMFLAG_VOTE, "enable/disable map test mode");
	AddUpdaterLibrary(); //auto-updater
}

/* Toggle player picking mode */
public Action CMD_TriggerMapTestMode(int client, int args)
{
  	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: !MapTest <on or off>");
		return Plugin_Handled;	
	}
	
	char arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	char Name[32];
	GetClientName(client, Name, sizeof(Name));	
		
	if (StrEqual(arg1, "on", false))
	{
		serverMode = SERVER_MODE_MAPTEST;
		PrintToChatAll("\x05%s triggered map test mode until further notified!", Name);
	}
	
	else if (StrEqual(arg1, "off", false))
	{
		serverMode = SERVER_MODE_REGULAR;
		PrintToChatAll("\x05%s triggered regular game mode until further notified!", Name);
	}
	
	else
	{
		ReplyToCommand(client, "[SM] Usage: !MapTest <on or off>");
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_GetServerMode", Native_GetServerMode);
	return APLRes_Success;
}

public int Native_GetServerMode(Handle plugin, int numParams) {
	return serverMode;
}
