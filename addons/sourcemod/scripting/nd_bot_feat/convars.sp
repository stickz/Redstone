#include <autoexecconfig>

enum convars
{
	 ConVar:BotCount,
	 ConVar:BoostBots,
	 ConVar:BotReduction,
	 ConVar:BotReductionDec,
	 ConVar:BotDiffMult,
	 ConVar:BoosterQuota,
	 
	 ConVar:DisableBotsAt,
	 ConVar:DisableBotsAtDec,
	 ConVar:DisableBotsAtInc,
	 ConVar:DisableBotsTeam,
	 ConVar:DisableBotsTeamDec,
	 ConVar:DisableBotsTeamInc,
	 
	 ConVar:BotOverblance,
	 ConVar:RegOverblance
};

ConVar g_cvar[convars];

bool visibleBoosted = false;

void CreatePluginConvars()
{
	AutoExecConfig_Setup("nd_bot_features");
	
	g_cvar[BoostBots] = AutoExecConfig_CreateConVar("sm_boost_bots", "1", "0 to disable, 1 to enable (server count - 2 bots)");
	g_cvar[BotCount] = AutoExecConfig_CreateConVar("sm_botcount", "20", "sets the regular bot count.");
	g_cvar[BotReduction] = AutoExecConfig_CreateConVar("sm_bot_quota_reduct", "8", "How many bots to take off max for small maps");
	g_cvar[BotReductionDec] = AutoExecConfig_CreateConVar("sm_bot_quota_reduct_dec", "12", "How many bots to take off max for small maps");
	g_cvar[BotDiffMult] = AutoExecConfig_CreateConVar("sm_bot_quota_dmult", "2.15", "Bot Fill = Player Count Difference * x - 1");
	g_cvar[BoosterQuota] = AutoExecConfig_CreateConVar("sm_booster_bot_quota", "28", "sets the bota bot quota");
	
	g_cvar[DisableBotsAt] = AutoExecConfig_CreateConVar("sm_disable_bots_at", "8", "sets when disable bots"); 
	g_cvar[DisableBotsAtDec] = AutoExecConfig_CreateConVar("sm_disable_bots_at_dec", "6", "sets when disable bots sooner on certain maps");
	g_cvar[DisableBotsAtInc] = AutoExecConfig_CreateConVar("sm_disable_bots_at_inc", "8", "sets when disable bots later on certain maps");
	g_cvar[DisableBotsTeam] = AutoExecConfig_CreateConVar("sm_disable_bots_team", "5", "sets when team-based disable bots"); 
	g_cvar[DisableBotsTeamDec] = AutoExecConfig_CreateConVar("sm_disable_bots_team_dec", "4", "sets when team disable bots sooner on certain maps");
	g_cvar[DisableBotsTeamInc] = AutoExecConfig_CreateConVar("sm_disable_bots_team_inc", "5", "sets when team disable bots later on certain maps");
	
	g_cvar[BotOverblance] = AutoExecConfig_CreateConVar("sm_bot_overbalance", "3", "sets team difference allowed with bots enabled"); 
	g_cvar[RegOverblance] = AutoExecConfig_CreateConVar("sm_reg_overbalance", "1", "sets team difference allowed with bots disabled");
	
	HookConVarChange(g_cvar[BoostBots], OnBotBoostChange);
	
	AutoExecConfig_EC_File();
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
