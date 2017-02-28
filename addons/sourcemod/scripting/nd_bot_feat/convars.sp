enum convars
{
	 ConVar:BotCount,
	 ConVar:BoostBots,
	 ConVar:BotReduction,
	 ConVar:BotReductionDec,
	 ConVar:BoosterQuota,
	 ConVar:DisableBotsAt,
	 ConVar:DisableBotsAtDec,
	 ConVar:DisableBotsAtInc,
	 ConVar:BotOverblance,
	 ConVar:RegOverblance	 
};

ConVar g_cvar[convars];

bool visibleBoosted = false;

void CreatePluginConvars()
{
	g_cvar[BoostBots] = CreateConVar("sm_boost_bots", "1", "0 to disable, 1 to enable (server count - 2 bots)");
	g_cvar[BotCount] = CreateConVar("sm_botcount", "20", "sets the regular bot count.");
	g_cvar[BotReduction] = CreateConVar("sm_bot_quota_reduct", "8", "How many bots to take off max for small maps");
	g_cvar[BotReductionDec] = CreateConVar("sm_bot_quota_reduct_dec", "12", "How many bots to take off max for small maps");
	g_cvar[BoosterQuota] = CreateConVar("sm_booster_bot_quota", "28", "sets the bota bot quota"); 
	g_cvar[DisableBotsAt] = CreateConVar("sm_disable_bots_at", "8", "sets when disable bots"); 
	g_cvar[DisableBotsAtDec] = CreateConVar("sm_disable_bots_at_dec", "6", "sets when disable bots sooner on certain maps");
	g_cvar[DisableBotsAtInc] = CreateConVar("sm_disable_bots_at_inc", "8", "sets when disable bots later on certain maps");
	g_cvar[BotOverblance] = CreateConVar("sm_bot_overbalance", "3", "sets team difference allowed with bots enabled"); 
	g_cvar[RegOverblance] = CreateConVar("sm_reg_overbalance", "1", "sets team difference allowed with bots disabled"); 
	
	HookConVarChange(g_cvar[BoostBots], OnBotBoostChange);
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
