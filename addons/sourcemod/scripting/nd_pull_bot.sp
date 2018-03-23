#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <nd_entities>
#include <nd_stype>

#define INVALID_USERID 0

public Plugin myinfo =
{
    name = "[ND] Teleport Bots",
    author = "yed, Stickz",
    description = "Move bots to a better position",
    version = "dummy",
    url = "https://github.com/stickz/Redstone"
};

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
	if (ND_GetServerTypeEx(ND_SType_Alpha) == SERVER_TYPE_ALPHA)
		RegBotGroundCheck(); // for ground_check.sp
	
	AddUpdaterLibrary(); //auto-updater
}