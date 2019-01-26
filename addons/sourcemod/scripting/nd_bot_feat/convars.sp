#include <autoexecconfig>

enum convars
{
	 ConVar:BotCount,
	 ConVar:BoostBots,
	 ConVar:BotReduction,
	 ConVar:BotReductionDec,
	 ConVar:BotDiffMult,
	 ConVar:BotSkillMult,
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
int totalDisable, teamDisable;
int botReductionValue;

void CreatePluginConvars()
{
	AutoExecConfig_Setup("nd_bot_features");
	
	g_cvar[BoostBots] = AutoExecConfig_CreateConVar("sm_boost_bots", "1", "0 to disable, 1 to enable (server count - 2 bots)");
	g_cvar[BotCount] = AutoExecConfig_CreateConVar("sm_botcount", "20", "sets the regular bot count.");
	g_cvar[BotReduction] = AutoExecConfig_CreateConVar("sm_bot_quota_reduct", "8", "How many bots to take off max for small maps");
	g_cvar[BotReductionDec] = AutoExecConfig_CreateConVar("sm_bot_quota_reduct_dec", "12", "How many bots to take off max for small maps");
	g_cvar[BotDiffMult] = AutoExecConfig_CreateConVar("sm_bot_quota_dmult", "2.15", "Bot Fill = Player Count Difference * x - 1");
	g_cvar[BotSkillMult] =	AutoExecConfig_CreateConVar("sm_bot_quota_smult", "1.2", "Multiply teamdiff by x to increase bots");
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
	
	SetBotDisableValues();
	SetBotReductionValues();
}

void SetBotDisableValues()
{
	// Get the current map we're playing
	char map[32];
	GetCurrentMap(map, sizeof(map));

	// Disable bots sooner if it's a tiny maps
	if (ND_CustomMapEquals(map, ND_Sandbrick))
	{		
		teamDisable = g_cvar[DisableBotsTeamDec].IntValue;
		totalDisable = g_cvar[DisableBotsAtDec].IntValue;
	}
	
	// Disable bots later on big maps, to compensate for the size
	else if (ND_StockMapEquals(map, ND_Gate) || ND_StockMapEquals(map, ND_Downtown))
	{
		teamDisable = g_cvar[DisableBotsTeamInc].IntValue;
		totalDisable = g_cvar[DisableBotsAtInc].IntValue;	
	}
	
	else
	{
		teamDisable = g_cvar[DisableBotsTeam].IntValue;
		totalDisable = g_cvar[DisableBotsAt].IntValue
	}	
}

void SetBotReductionValues()
{
	// Get the current map we're playing
	char map[32];
	GetCurrentMap(map, sizeof(map));
	
	// If small map, reduce the mnumber of bots. Otherwise, use the regular bot count
	bool smallMap = ND_CustomMapEquals(map, ND_Sandbrick) || ND_CustomMapEquals(map, ND_Mars);
	botReductionValue = smallMap ? g_cvar[BotReductionDec].IntValue : g_cvar[BotReduction].IntValue;
}
