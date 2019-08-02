#include <sourcemod>
#include <clientprefs>
#include <nd_stocks>
#include <nd_fskill>
#include <nd_print>
#include <nd_redstone>
#include <nd_rounds>

#define TEAMDIFF_UPDATE_RATE 3.0 //NOTE: This value MUST be a float (ie. 3.0 not 3)

public Plugin myinfo =
{
	name 		= "[ND] Teamdiff Display",
	author		= "Stickz",
	description 	= "Display team difference to players",
	version 	= "recompile",
	url 		= "https://github.com/stickz/Redstone/"
};

#include "nd_teamdiff/hud_display.sp"
#include "nd_teamdiff/commands.sp"

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_teamdiff_display/nd_teamdiff_display.txt"
#include "updater/standard.sp"

public void OnPluginStart()
{
	LoadTranslations("common.phrases"); //required for on and off
	LoadTranslations("nd_common.phrases"); // required for common phrases
	LoadTranslations("nd_team_balancer.phrases"); //required until seperated
	
	loadHudDisplayFeature(); // hud_display.sp
	RegisterCommands(); // commands.sp
	
	AddUpdaterLibrary(); //Auto-Updater
}

public void ND_OnRoundStarted() {
	CreateTimer(TEAMDIFF_UPDATE_RATE, TIMER_UpdateTeamDiffHint, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("ND_GetTeamDifference");
	MarkNativeAsOptional("ND_GetPlayerSkill");
	MarkNativeAsOptional("ND_GetEnhancedAverage");
	return APLRes_Success;
}
