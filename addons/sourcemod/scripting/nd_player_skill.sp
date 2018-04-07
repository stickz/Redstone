#include <sourcemod>
#include <sdktools>
#include <nd_gskill>
#include <nd_stats>
#include <nd_stocks>
#include <nd_rounds>
#include <nd_redstone>
#include <nd_com_eng>
#include <nd_aweight>
#include <nd_entities>
#include <smlib/math>

#define _DEBUG 0

#define CONSORT_aIDX 0
#define EMPIRE_aIDX 1

#define ROOKIE_SKILL_ADJUSTMENT 1.25

float GameME_PlayerSkill[MAXPLAYERS+1] = {-1.0,...};
float GameME_CommanderSkill[MAXPLAYERS+1] = {-1.0,...};

float lastAverage = 0.0;
float lastMedian = 0.0;

/* These two things much be accessible ealier than spm logic */
bool g_isSkilledRookie[MAXPLAYERS+1] = {false, ...};
bool g_isWeakVeteran[MAXPLAYERS+1] = {false, ...};

enum Bools
{
	tdChange,
	adjustedRookie
};
bool g_Bool[Bools];

/* Include various plugin modules */
#include "nd_ply_skill/convars.sp"
#include "nd_ply_skill/ply_level.sp"
#include "nd_ply_skill/prediction.sp"
#include "nd_ply_skill/skill_calc.sp"
#include "nd_ply_skill/spm_logic.sp"
#include "nd_ply_skill/extras.sp"
#include "nd_ply_skill/natives.sp"

/* Include test commands */
#include "nd_ply_skill/commands.sp"

public Plugin myinfo =
{
	name = "[ND] Player Skill Management",
	author = "Stickz",
	description = "Finalizes a player's skill level",
	version = "recompile",
	url = "https://github.com/stickz/Redstone"
};

public void OnPluginStart()
{
	CreatePluginConvars();
	RegisterCommands();
	
	AutoExecConfig(true, "nd_final_skill");
	
	if (ND_MapStarted())
		ReloadGameMeSkill();
	
	if (ND_RoundStarted())
		startSPMTimer();
}

public void GameME_OnSkillCalculated(int client, float base, float skill) {
	GameME_PlayerSkill[client] = skill;	
	GameME_CommanderSkill[client] = base;
}

public void ND_OnRoundStarted() {
	startSPMTimer();	
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen) {
	resetVarriables(client);
	return true;
}

public void OnClientDisconnect(int client) {
	resetVarriables(client);
}

void resetVarriables(int client)
{
	g_isSkilledRookie[client] = false;
	g_isWeakVeteran[client] = false;
	LevelCacheArray[client] = -1;
	connectionTime[client] = -1;
	scorePerMinute[client] = -1;
	previousTeam[client] = -1;
	GameME_PlayerSkill[client] = -1.0;
}

void ReloadGameMeSkill()
{
	if (!GM_GFS_LOADED())
		return;
	
	RED_LOOP_CLIENTS(client) {
		GameME_PlayerSkill[client] = GameME_GetFinalSkill(client);	
		GameME_CommanderSkill[client] = GameME_GetSkillBase(client);
	}
}
