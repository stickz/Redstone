#include <sourcemod>

#define STRING_NOT_FOUND -1

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_commander_deprioritization/nd_commander_deprioritization.txt"
#include "updater/standard.sp"

public Plugin myinfo =
{
	name = "[ND] Commander Deprioritization",
	author = "Stickz",
	description = "Deprioritizes commanders in the selection proccess.",
	version = "recompile",
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
	
	AddUpdaterLibrary(); //auto-updater

	LoadTranslations("common.phrases"); // required for find target
}

public OnMapStart() {
	ReadTextFile();
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
