#include <sdktools>

/* Auto Updater */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_kill_bots/nd_kill_bots.txt"
#include "updater/standard.sp"

#pragma newdecls required
#include <sourcemod>
#include <nd_stocks>
#include <nd_rounds>
#include <nd_com_eng>

public Plugin myinfo =
{
	name = "[ND] Bot Slaying",
	author = "Stickz",
	description = "Allows killing of bots on a particular team",
	version = "dummy",
	url = "https://github.com/stickz/Redstone/"
};

bool CanKillBots[2] = {true, ...};
bool BotsReset = false;

ConVar cvarBotSlayCooldown;

public void OnPluginStart()
{
	cvarBotSlayCooldown = CreateConvar("sm_bslay_cooldown", "180", "Set the cooldown for slaying bots");
	
	RegisterCommands(); // commands to slay bots
	AddUpdaterLibrary(); // auto-updater
}

public void OnMapEnd() {
	ResetKillBots();
}

public void ND_OnRoundEnded() {
	ResetKillBots();
}

public Action CMD_KillBots(int client, int args)
{
	if (!RoundStarted(client))
		return Plugin_Handled;
	
	if (!ND_IsCommander(client))
	{
		ReplyToCommand(client, "[SM] This command for commanders only!");
		return Plugin_Handled;
	}
	
	int team = GetClientTeam(client);
	
	if (!CanKillBots[team - 2])
	{
		ReplyToCommand(client, "[SM] This has a five minute cooldown!");
		return Plugin_Handled;	
	}
	
	CreateCooldown(team);
	PerformKillBots(team);
	
	return Plugin_Handled;
}

public Action CMD_AdminKillBots(int client, int args)
{
	if (!RoundStarted(client))
		return Plugin_Handled;	
	
	if (!args)
	{
		ReplyToCommand(client, "Usage: sm_aKillBots <empire/consort>");
		return Plugin_Handled;
	}
	
	char teamArg[16];
	GetCmdArg(1, teamArg, sizeof(teamArg));
	
	int team;
	
	if (StrContains(teamArg, "emp", false) > -1)
		team = TEAM_EMPIRE;
	else if (StrContains(teamArg, "con", false) > -1)
		team = TEAM_CONSORT;
	else
	{
		ReplyToCommand(client, "Invalid team name.");
		return Plugin_Handled;	
	}	
	
	PerformKillBots(team);	
	return Plugin_Handled;
}

public Action Timer_EnableBotKill(Handle timer, any team) {
	CanKillBots[team - 2] = true;
}

bool RoundStarted(int client)
{
	if (!ND_RoundStarted())
	{
		PrintToChat(client, "[SM] This command requires the round to be running!");
		return false;
	}
	
	return true;
}

void PerformKillBots(int team)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if ( IsValidClient(client, false) && IsFakeClient(client) && 
		     IsPlayerAlive(client) && GetClientTeam(client) == team)
		{
			ForcePlayerSuicide(client);		
		}
	}
}

void CreateCooldown(int team)
{
	CanKillBots[team - 2] = false;	
	CreateTimer(cvarBotSlayCooldown.FloatValue, Timer_EnableBotKill, team, TIMER_FLAG_NO_MAPCHANGE);
}

void ResetKillBots()
{
	if (!BotsReset)
	{		
		CanKillBots[0] = true;
		CanKillBots[1] = true;
		BotsReset = true;
	}
}

void RegisterCommands()
{
	RegConsoleCmd("sm_KillBots", CMD_KillBots, "Allows a commander to kill their bots");
	RegConsoleCmd("sm_SlayBots", CMD_KillBots, "Allows a commander to kill their bots");
	RegAdminCmd("sm_aKillBots", CMD_AdminKillBots, ADMFLAG_KICK, "Allows a command to kill bots on a team");
	RegAdminCmd("sm_aSlayBots", CMD_AdminKillBots, ADMFLAG_KICK, "Allows a command to kill bots on a team");
}
