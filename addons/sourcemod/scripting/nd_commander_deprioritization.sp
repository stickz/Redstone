#include <sourcemod>

#define STRING_NOT_FOUND -1

public Plugin myinfo =
{
	name = "[ND] Commander Deprioritization",
	author = "Stickz",
	description = "Deprioritizes commanders in the selection proccess.",
	version = "dummy",
	url = "https://github.com/stickz/Redstone/"
}

ArrayList g_SteamIDList;

#include "nd_com_dep/text_files.sp"
#include "nd_com_dep/admin_cmds.sp"
#include "nd_com_dep/natives.sp"

public void OnPluginStart()
{
	g_SteamIDList = new ArrayList(32);
	
	CreateTextFile();
	ReadTextFile();
	RegAdminCmds();

	LoadTranslations("common.phrases"); // required for find target
}

void AddClientDep(int client)
{
	char steamid[STEAMID_SIZE];
	GetClientAuthId(client, AuthId_Steam2, steamid, STEAMID_SIZE);	
	g_SteamIDList.PushString(steamid);	
	WriteSteamId(steamid);
}

void RemoveClientDep(int client, int admin)
{
	char steamid[STEAMID_SIZE];
	GetClientAuthId(client, AuthId_Steam2, steamid, STEAMID_SIZE);
	
	int found = g_SteamIDList.FindString(steamid);
	if (found == STRING_NOT_FOUND)
	{
		PrintToChat(admin, "player not found");
		return;
	}
	
	g_SteamIDList.Erase(found);
	RemoveSteamId(steamid);
}