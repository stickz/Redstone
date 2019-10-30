//#pragma newdecls required
#include <sourcemod>
#include <nd_stocks>
#include <nd_rounds>
#include <nd_redstone>

#define _DEBUG 0
#define MAX_INGAME_LEVEL 80.0

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_gameme_skill/nd_gameme_skill.txt"
#include "updater/standard.sp"

/* This plugin proccess data from server statistics and creates a skill level for each player.
 * The skill value is then passes onto other plugins such as nd_team_shuffle for team balance.
 */

/* Include Base Requirements */
#include "nd_gskill/convars.sp"

/* The exponential equation */
float EXP_CalculateSkill(int value, int base, float multipler, float growth) {
	return growth * Logarithm(float(value / base), multipler);
}

/* Include GameMe Features */
#include "nd_gskill/gameme/gameme.sp"
#include "nd_gskill/gameme/kill_stats.sp"

/* Include natives & test commands */
#include "nd_gskill/commands.sp"

public Plugin myinfo =
{
	name = "[ND] GameMe Skill Calculator",
	author = "Stickz",
	description = "Creates a skill level based on each player's GameME data.",
	version = "dummy",
	url = "https://github.com/stickz/Redstone"
};

public void OnPluginStart()
{
	/* Create convars for plugin and exec cfg file */
	GameME_CreateConvars();
	AutoExecConfig(true, "nd_gameme_skill");
	
	/* Intialize Features */
	GameME_InitializeFeatures();
	
	/* Register the test commands */
	RegTestCommands();
	
	/* Recalculate skill if plugin loaded late */
	if (ND_MapStarted())
		GameMe_RecalculateSkill();
		
	LoadTranslations("common.phrases"); //required for FindTarget
	AddUpdaterLibrary(); //auto-updater
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen) {
	GameME_ResetVariables(client);
	return true;
}

public void OnClientDisconnect(int client) {
	 GameME_ResetVariables(client);
}

/* Natives */
//functag NativeCall public(Handle:plugin, numParams);
public APLRes:AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("GameME_GetFinalSkill", Native_GameME_GetFinalSkill);
	CreateNative("GameME_GetSkillBase", Native_GameME_GetSkillBase);
	return APLRes_Success;
}

public Native_GameME_GetFinalSkill(Handle plugin, int numParams) {
	return _:GameME_FinalSkill[GetNativeCell(1)];
}

public Native_GameME_GetSkillBase(Handle plugin, int numParams) {
	return _:GameME_SkillBase[GetNativeCell(1)];
}
