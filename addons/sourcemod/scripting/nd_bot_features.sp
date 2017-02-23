/* Key Defintions
 * Modulous Quota: When team counts are less than 8 by default, bots are blasted.
 * Filler Quota: When lots of people are on teams, fill player count differences with bots
 */

#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <nd_slots>

#pragma newdecls required
#include <nd_rounds>
#include <nd_maps>

bool visibleBoosted = false;

enum convars
{
	 ConVar:BotCount,
	 ConVar:BoostBots,
	 ConVar:BotReduction,
	 ConVar:BoosterQuota,
	 ConVar:DisableBotsAt,
	 ConVar:BotOverblance,
	 ConVar:RegOverblance	 
};

ConVar g_cvar[convars];

//functions required to create a modulous bot quota
//simply calling getBotModulusQuota() will return the integer
#include "nd_bot_feat/modulus_quota.sp"

#define TEAM_UNASSIGNED		0
#define TEAM_SPEC			1
#define TEAM_CONSORT		2
#define TEAM_EMPIRE			3

#define VERSION "1.3.1"

public Plugin myinfo =
{
	name = "[ND] Bot Features",
	author = "Stickz",
	description = "Give more control over the bots on the server",
	version = VERSION,
	url = "N/A"
};

public void OnClientDisconnect_Post(int client)
{
	checkCount();
}
	
public void OnPluginStart()
{
	g_cvar[BoostBots] = CreateConVar("sm_boost_bots", "1", "0 to disable, 1 to enable (server count - 2 bots)");
	g_cvar[BotCount] = CreateConVar("sm_botcount", "20", "sets the regular bot count.");
	g_cvar[BotReduction] = CreateConVar("sm_bot_quota_reduct", "8", "How many bots to take off max for small maps");
	g_cvar[BoosterQuota] = CreateConVar("sm_booster_bot_quota", "28", "sets the bota bot quota"); 
	g_cvar[DisableBotsAt] = CreateConVar("sm_disable_bots_at", "8", "sets when disable bots"); 
	g_cvar[BotOverblance] = CreateConVar("sm_bot_overbalance", "3", "sets team difference allowed with bots enabled"); 
	g_cvar[RegOverblance] = CreateConVar("sm_reg_overbalance", "1", "sets team difference allowed with bots disabled"); 
		
	HookConVarChange(g_cvar[BoostBots], OnBotBoostChange);
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	
	AddCommandListener(PlayerJoinTeam, "jointeam");
	
	HookEvent("round_win", Event_RoundEnd, EventHookMode_Pre);
	HookEvent("timeleft_5s", Event_RoundEnd, EventHookMode_PostNoCopy);	

	AutoExecConfig(true, "nd_bot_features");
}

public void OnMapEnd()
{
	SignalMapChange();	
}

public void OnBotBoostChange(ConVar convar, char[] oldValue, char[] newValue)
{	
	if ((!convar.BoolValue && visibleBoosted) ||
		(convar.BoolValue && !visibleBoosted && OnTeamCount() < g_cvar[DisableBotsAt].IntValue))
	{		
		if (TDS_AVAILABLE())
		{		
			ToggleDynamicSlots(visibleBoosted);
			visibleBoosted = convar.BoolValue;
		}
	}
}

public Action PlayerJoinTeam(int client, char[] command, int argc) {
	CheckBotCounts(client);
}

public void TB_OnTeamPlacement(int client, int team) {
	CheckBotCounts(client);
}

void CheckBotCounts(int client)
{
	if (IsValidClient(client))	{
		CreateTimer(0.1, TIMER_CC, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action TIMER_CC(Handle timer)
{
	checkCount();
	return Plugin_Handled;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	SignalMapChange();
}

void checkCount()
{
	if (ND_RoundStarted())
	{
		int quota = 0;
		
		int teamCount = OnTeamCount();
		if (teamCount < g_cvar[DisableBotsAt].IntValue)
		{
			if (g_cvar[BoostBots].BoolValue && TDS_AVAILABLE())
			{			
				quota += getBotModulusQuota();
				
				if (!visibleBoosted)
					toggleBooster(true);
			}
			else
			{
				quota += g_cvar[BotCount].IntValue;
				ServerCommand("mp_limitteams %d", g_cvar[BotOverblance].IntValue);	
			}
		}
		
		else
		{			
			bool excludeSpecs = ValidClientCount(true) < GetDynamicSlotCount() - 2;		
			quota = getBotFillerQuota(teamCount, !excludeSpecs, excludeSpecs);			
			
			if (GDSC_AVAILABLE() && quota >= GetDynamicSlotCount() - 2 && getPositiveOverBalance() >= 3)
			{
				quota = getBotFillerQuota(teamCount, true);
				
				if (!visibleBoosted)
					toggleBooster(true, false);
			}
				
			else if (visibleBoosted)
				toggleBooster(false);
		}
		
		ServerCommand("bot_quota %d", quota);
	}
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	int quota = 0;
	
	if (g_cvar[BoostBots].BoolValue && TDS_AVAILABLE())
	{	
		if (OnTeamCount() < g_cvar[DisableBotsAt].IntValue)
		{
			if (!visibleBoosted)
				toggleBooster(true);
				
			quota = getBotModulusQuota();
		}
	}
	else
		quota = g_cvar[BotCount].IntValue;
	
	ServerCommand("bot_quota %d", quota);
}

//Turn 32 slots on or off for bot quota
void toggleBooster(bool state, bool teamCaps = true)
{	
	visibleBoosted = state;
	
	if (TDS_AVAILABLE())
		ToggleDynamicSlots(!state);
		
	else
	{
		PrintToChatAll("\x05[xG] ToggleDynamicSlots() is broken. Please notify a server admin.");
		ServerCommand("sv_visiblemaxplayers 32");
	}
		
	//Unlock team joining when bots are blasting
	if (teamCaps)
		ServerCommand("mp_limitteams %d", state ? 	g_cvar[BotOverblance].IntValue :
													g_cvar[RegOverblance].IntValue);
}

//Disable the 32 slots (if activate) when the map changes
void SignalMapChange()
{
	if (visibleBoosted)
		toggleBooster(false);	

	ServerCommand("bot_quota 0");
}

//When teams have two or more less players
int getBotFillerQuota(int teamCount, bool excludeSpectators = false, bool addSpectators = false) 
{
	if (ValidTeamCount(TEAM_EMPIRE) == ValidTeamCount(TEAM_CONSORT))
		return 0;
		
	int total = teamCount + getPositiveOverBalance() - 1;
		
	/* Notice: It's assumed this code will only call ValidTeamCount() once for performance reasons */
	if (addSpectators)
		total += ValidTeamCount(TEAM_SPEC);
		
	if (excludeSpectators)
		total -= ValidTeamCount(TEAM_SPEC);

	return total;
}