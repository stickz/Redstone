#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <nd_rounds>
#include <nd_redstone>
#include <nd_print>
#include <nd_afk>
#include <nd_swgm>
#include <nd_warmup>

public Plugin myinfo =
{
	name = "[ND] Team Picker",
	author = "Stickz",
	description = "Lets two selected commanders pick their team",
	version = "recompile",
	url = "https://github.com/stickz/Redstone/"
}

#define CONSORT_aIDX 0
#define EMPIRE_aIDX 1

int team_captain[2];
int picking_index = 0;

ArrayList PickedConsort;
ArrayList PickedEmpire;

bool g_bEnabled = false;
bool g_bPickStarted = false;
bool g_bPickedThisMap = false;
bool DebugTeamPicking = false;

ConVar cvarPickTimeLimit;
ConVar cvarFirstPickTime;

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_team_picking/nd_team_picking.txt"
#include "updater/standard.sp"

#include "nd_team_pick/commands.sp"
#include "nd_team_pick/start_picking.sp"
#include "nd_team_pick/picking_timer.sp"
#include "nd_team_pick/picking_process.sp"
#include "nd_team_pick/natives.sp"

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("nd_team_picking.phrases");

	cvarPickTimeLimit = CreateConVar("sm_tp_time", "20", "Set time allocated for each pick");
	cvarFirstPickTime = CreateConVar("sm_tp_time_first", "40", "Set time allocated for first pick");
	AutoExecConfig(true, "nd_teampick");

	PickedConsort = new ArrayList(32);
	PickedEmpire = new ArrayList(32);

	RegisterPickingCommand(); //start_picking.sp: Command for starting team picking
	RegisterCommands(); //commands.sp: Extra commands, not directly related to picking

	AddCommandListener(Command_JoinTeam, "jointeam");
	PrintToChatAll("\x05[xG] Team picker plugin reloaded successfully");

	AddUpdaterLibrary(); //auto-updater
}

public void OnMapStart() {
	FinishPicking(true);
}

public void OnMapEnd() {
	InitiateRoundEnd();
}

public void ND_OnRoundEnded() {
	InitiateRoundEnd();
}

public Action Command_JoinTeam(int client, char[] command, int argc)
{
	if (!ND_RoundStarted() && g_bEnabled)
	{
		PrintToChat(client,"\x05Please stay in spectator until you're chosen.");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

void InitiateRoundEnd()
{
	g_bPickedThisMap = false;
	PickedConsort.Clear();
	PickedEmpire.Clear();
}

bool PlayerIsPickable(int client) {
	// If the client is valid by Redstone standards and not already on a team
	return IsValidClient(client, !DebugTeamPicking) && IsValidClient(client) &&
				     GetClientTeam(client) < 2 && !ND_IsMarkedAFK(client);
}

int GetPickingTimeLimit() {
	return picking_index <= 1 ? cvarFirstPickTime.IntValue : cvarPickTimeLimit.IntValue;
}

void MarkPlayerPicked(int client, int team)
{
	char gAuth[32];
	GetClientAuthId(client, AuthId_Steam2, gAuth, sizeof(gAuth));

	switch (team)
	{
		case TEAM_EMPIRE: 	PickedEmpire.PushString(gAuth);
		case TEAM_CONSORT:  PickedConsort.PushString(gAuth);
	}
}
