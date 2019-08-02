#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <nd_entities>
#include <nd_stype>
#include <nd_print>
#include <nd_rounds>

#include <autoexecconfig>

public Plugin myinfo =
{
    name = "[ND] Teleport Bots",
    author = "yed, Stickz",
    description = "Move bots to a better position",
    version = "recompile2",
    url = "https://github.com/stickz/Redstone"
};

/* Convars for Plugin */
ConVar gCheck_BunkerDistance;
ConVar gCheck_SpawnDelay;
ConVar mBot_MaxDistance;
ConVar mBot_RetryDelay;

// Module 1: Allow players to pull bots toward them
#include "nd_pull_bot/move_bot.sp"

// Module 2: Automatically teleport bots stuck into the ground
#include "nd_pull_bot/ground_check.sp"

// Auto updater support for game-servers
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_pull_bot/nd_pull_bot.txt"
#include "updater/standard.sp"

public void OnPluginStart()
{	
	RegPullBotCommand(); // for move_bot.sp
	
	// Only enable ground checks on the alpha server for now
	if (ND_GetServerTypeEx(ND_SType_Stable) >= SERVER_TYPE_STABLE)
		RegBotGroundCheck(); // for ground_check.sp
	
	LoadTranslations("nd_pull_bot.phrases"); // Translated messages	
	
	/* Create convars and exec config file */
	CreatePluginConvars();
	AutoExecConfig(true, "nd_pull_bot");
	
	AddUpdaterLibrary(); //auto-updater
}

public void ND_OnRoundStarted() {
	ResetPullCooldowns(); // for move_bot.sp
}

public void OnClientConnected(int client) {
	CanPullBot[client] = true;
}

void CreatePluginConvars()
{
	AutoExecConfig_Setup("nd_pull_bot");
	
	gCheck_BunkerDistance	= AutoExecConfig_CreateConVar("sm_gcheck_bdistance", "1500", "Distance away from bunker spawn must be to use feature");
	gCheck_SpawnDelay 	= AutoExecConfig_CreateConVar("sm_gcheck_sdelay", "8", "Delay after spawning to perform bot ground check");
	mBot_MaxDistance	= AutoExecConfig_CreateConVar("sm_mbot_bdistance", "300", "Distance player must be away from bot to pull them");
	mBot_RetryDelay		= AutoExecConfig_CreateConVar("sm_mbot_pdelay", "8", "Delay player must wait before performing pulls");
	
	AutoExecConfig_EC_File();
}
