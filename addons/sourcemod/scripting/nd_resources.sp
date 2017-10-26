#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <nd_entities>

// This plugin is a prototype for future endeavors
public Plugin myinfo =
{
	name = "[ND] Resource Management",
	author = "Stickz",
	description = "Checks team resources",
	version = "dummy",
	url = "https://github.com/stickz/Redstone/"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_resources/nd_resources.txt"
#include "updater/standard.sp"

public void OnPluginStart()
{
	RegAdminCmd("sm_checkresources", CheckResources, ADMFLAG_ROOT, "Returns the current resources for both teams");
	AddUpdaterLibrary(); //auto-updater
}

public Action CheckResources(int client, int args)
{
	ReplyToCommand(	client, "Consort %d | Empire %d", 
					ND_GetCurrentResources(TEAM_CONSORT), 
					ND_GetCurrentResources(TEAM_EMPIRE));
	return Plugin_Handled;
}
