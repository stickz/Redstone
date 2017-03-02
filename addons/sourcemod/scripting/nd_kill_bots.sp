#include <sourcemod>
#include <sdktools>
#include <nd_stocks>

#undef REQUIRE_PLUGIN
#tryinclude <nd_commander>
#define REQUIRE_PLUGIN

#define VERSION "1.0.2"

#define TEAM_CONSORT		2
#define TEAM_EMPIRE			3

public Plugin:myinfo =
{
	name = "[ND] Bot Slaying",
	author = "Stickz",
	description = "Allows killing of bots on a particular team",
	version = VERSION,
	url = "N/A"
};

new bool:CanKillBots[2] = {true, ...};
new bool:BotsReset = false;
new bool:RoundStarted = false;

public OnPluginStart()
{
	RegisterCommands();
	HookEvents();
}

public OnMapEnd()
{
	ResetKillBots();
	RoundStarted = false;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundStarted = true;
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetKillBots();
	RoundStarted = false;
}

public Action:CMD_KillBots(client, args)
{
	if (!RoundStarted)
	{
		ReplyToCommand(client, "[SM] This command requires the round to be running!");
		return Plugin_Handled;	
	}
	
	if (!NDC_IsCommander(client))
	{
		ReplyToCommand(client, "[SM] This command for commanders only!");
		return Plugin_Handled;
	}
	
	new team = GetClientTeam(client);
	
	if (!CanKillBots[team - 2])
	{
		ReplyToCommand(client, "[SM] This has a five minute cooldown!");
		return Plugin_Handled;	
	}
	
	CreateCooldown(team);
	PerformKillBots(team);
	
	return Plugin_Handled;
}

public Action:CMD_AdminKillBots(client, args)
{
	if (!RoundStarted)
	{
		ReplyToCommand(client, "[SM] This command requires the round to be running!");
		return Plugin_Handled;	
	}
	
	if (!args)
	{
		ReplyToCommand(client, "Usage: sm_aKillBots <empire/consort>");
		return Plugin_Handled;
	}
	
	decl String:teamArg[16];
	GetCmdArg(1, teamArg, sizeof(teamArg));
	
	new team;
	
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

public Action:Timer_EnableBotKill(Handle:timer, any:team)
{
	CanKillBots[team - 2] = true;
}

PerformKillBots(team)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client, false) && IsFakeClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == team)
		{
			ForcePlayerSuicide(client);		
		}	
	}
}

CreateCooldown(team)
{
	CanKillBots[team - 2] = false;	
	CreateTimer(300.0, Timer_EnableBotKill, team, TIMER_FLAG_NO_MAPCHANGE);
}

ResetKillBots()
{
	if (!BotsReset)
	{		
		CanKillBots[0] = true;
		CanKillBots[1] = true;
		BotsReset = true;
	}
}

RegisterCommands()
{
	RegConsoleCmd("sm_KillBots", CMD_KillBots, "Allows a commander to kill their bots");
	RegConsoleCmd("sm_KillBots", CMD_KillBots, "Allows a commander to kill their bots");
	RegAdminCmd("sm_aKillBots", CMD_AdminKillBots, ADMFLAG_KICK, "Allows a command to kill bots on a team");
}

HookEvents()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("timeleft_5s", Event_RoundEnd, EventHookMode_PostNoCopy);
}