#include <sourcemod>

public Plugin:myinfo =
{
	name = "Auto Reconnect",
	author = "stickz",
	description = "Sends client command retry on server restart",
	version = "dummy",
	url = "https://github.com/stickz/Redstone/"
};

/* Auto Updater */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/autoreconnect/autoreconnect.txt"
#include "updater/standard.sp"

public OnPluginStart()
{
	RegServerCmd("quit", OnDown);
	RegServerCmd("_restart", OnDown);
}

public Action:OnDown(args)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
           		ClientCommand(i, "retry"); // force retry
           	}
        }
}
