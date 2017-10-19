#include <sourcemod>
#include <nd_stocks>
#include <nd_rounds>
#include <nd_redstone>

public Plugin:myinfo = 
{
	name = "[ND] Team Picker",
	author = "Stickz",
	description = "Lets two selected commanders pick their team",
	version = "dummy",
	url = "<- URL ->"
}

#define CONSORT_aIDX 0
#define EMPIRE_aIDX 1

int last_choice[2];
int team_captain[2];

bool g_bEnabled = false;
bool g_bPickStarted = false;
bool doublePlace = true;
bool firstPlace = true;
bool checkPlacement = true;

#include "nd_team_pick/commands.sp"
#include "nd_team_pick/start_picking.sp"
#include "nd_team_pick/picking_process.sp"

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_team_picking/nd_team_picking.txt"
#include "updater/standard.sp"

public void OnPluginStart() 
{
	LoadTranslations("common.phrases");
	
	RegisterPickingCommand(); //start_picking.sp: Command for starting team picking
	RegisterCommands(); //commands.sp: Extra commands, not directly related to picking
	
	AddCommandListener(Command_JoinTeam, "jointeam");	
	PrintToChatAll("\x05[xG] Team picker plugin reloaded successfully");

	AddUpdaterLibrary(); //auto-updater
}

public Action Command_JoinTeam(int client, char[] command, int argc)
{
	if (g_bEnabled)
	{
		PrintToChat(client,"\x05Please stay in spectator until you're chosen.");
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}