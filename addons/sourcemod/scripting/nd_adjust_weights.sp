#include <sourcemod>

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_adjust_weights/nd_adjust_weights.txt"
#include "updater/standard.sp"

/* This plugin is designed to handle the effects of alt steam accounts on team balance.
 * It allows player skill to be permanently modified and stored in a text file.
 * It's essentially a wrapper that passes information to other plugins via natives.
 */

public Plugin myinfo =
{
	name = "[ND] Weighting Adjuster",
	author = "Stickz",
	description = "Allows admins to set asign floors to player skill",
	version = "recompile",
	url = "https://github.com/stickz/Redstone/"
};

#define STRING_NOT_FOUND -1
#define MIN_SKILL_VALUE 20

ArrayList g_PlayerSkillFloors;
ArrayList g_SteamIDList;

#include "nd_weight/text_files.sp"
#include "nd_weight/admin_cmds.sp"
#include "nd_weight/natives.sp"

public void OnPluginStart()
{
	g_PlayerSkillFloors = new ArrayList(32);
	g_SteamIDList = new ArrayList(32);
	
	LoadTranslations("common.phrases"); //required for find target
	
	CreateTextFiles();
	ReadTextFiles();
	RegAdminCmds();
	
	AddUpdaterLibrary(); //auto-updater
}

public void OnMapStart() {
	ReadTextFiles();
}

void AddClientWeighting(int client, int fileIDX)
{	
	/* Get and trim the client's steamid */
	char steamid[STEAMID_SIZE];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	
	/* Add the steamid to the arraylist */
	int skillValue = MIN_SKILL_VALUE + (fileIDX * 20);	
	g_SteamIDList.PushString(steamid);	
	g_PlayerSkillFloors.Push(skillValue);
	
	WriteSteamID(steamid, fileIDX);
}

void RemoveClientWeighting(int client)
{
	/* Get and trim the client's steamid */
	char steamid[STEAMID_SIZE];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	
	int found = g_SteamIDList.FindString(steamid);
	if (found == STRING_NOT_FOUND)
	{
		PrintToChat(client, "player not found");
		return;
	}
	
	/* Get the weight before erasing things */
	int weight = g_PlayerSkillFloors.Get(found) - MIN_SKILL_VALUE;
	
	/* Erase skill values from array list */	
	g_SteamIDList.Erase(found);
	g_PlayerSkillFloors.Erase(found);
	
	/* Find the file is rewrite information to it */
	int fileIDX = weight > 0 ? weight / 20 : weight;
	RemoveSteamIdFromFile(steamid, fileIDX);
}
