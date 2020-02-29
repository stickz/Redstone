#include <sourcemod>
#include <nd_maps>

#define MAX_MAPNANE_LENGTH 128
#define MAX_INT_STRING 6
#define MIN_PLAYERS	1
#define USERID_NOT_FOUND -1

public Plugin myinfo = 
{
	name = "Default Map Changer",
	author = "TigerOx, stickz",
	description = "Changes the map to default if the server is empty.",
	version = "recompile",
	url = "https://github.com/stickz/Redstone/"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/defaultmap/defaultmap.txt"
#include "updater/standard.sp"

int g_PlyrCount;
Handle g_hPlyrData;

char g_DefaultMap[MAX_MAPNANE_LENGTH];

bool isHostMap = false;

public OnPluginStart()
{
	GetCurrentMap(g_DefaultMap, MAX_MAPNANE_LENGTH);
	
	g_hPlyrData = CreateTrie();

	HookEvent("player_disconnect", EventPlayerDisconnect, EventHookMode_Pre);
	
	AddUpdaterLibrary(); //auto-updater
}

public void OnClientConnected(int client)
{
	char index[MAX_INT_STRING];
	
	if(!client || IsFakeClient(client))
		return;
	
	IntToString(GetClientUserId(client),index,MAX_INT_STRING);
	
	if(SetTrieValue(g_hPlyrData, index, 0, false) && !g_PlyrCount++)
	{
		new time;
		
		if(GetMapTimeLimit(time) && time && GetMapTimeLeft(time) && time < 0)
			ServerCommand("mp_restartgame 1");
	}
}

public Action EventPlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	char index[MAX_INT_STRING];
	int userid = event.GetInt("userid", -1);
	
	if (userid == USERID_NOT_FOUND)
		return Plugin_Continue;
	
	IntToString(userid,index,MAX_INT_STRING);
	
	if(RemoveFromTrie(g_hPlyrData,index) && (--g_PlyrCount < MIN_PLAYERS))
		SetDefaultMap();
	
	return Plugin_Continue;
}

public void OnMapStart()
{
	isHostMap = ND_IsServerHostMap();
	
	if(!g_PlyrCount)
		SetDefaultMap();
}

void SetDefaultMap()
{
	if(!isHostMap)
	{
		ForceChangeLevel(g_DefaultMap, "Server empty. Going to default map...");
	}
}