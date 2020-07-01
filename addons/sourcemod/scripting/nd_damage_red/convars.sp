#include <autoexecconfig>

/* Enumerated values for accessing ConVar arrays */
enum multREDs 
{
	red_ib0_base_mult,
	red_ib1_base_mult,
	red_ib2_base_mult,
	red_ib3_base_mult
}

/* ConVar and float arrays for the different types */
ConVar gCvar_RedMult[multREDs];
float gFloat_RedMult[multREDs];

ConVar gCvar_RedCooldown[multREDs];
float gFloat_RedCooldown[multREDs];

void CreateRedConVars()
{
	AutoExecConfig_SetFile("nd_mult_reds");
	
	/* RED base damage multipliers */
	char convarNameMult[multREDs][] = {
		"sm_mult_baseIB0_red_mult",
		"sm_mult_baseIB1_red_mult",
		"sm_mult_baseIB2_red_mult",
		"sm_mult_baseIB3_red_mult"	
	};	
	char convarDescMult[multREDs][] = {
		"Percentage of normal damage REDs deal at Infantry Boost 0",
		"Percentage of normal damage REDs deal after Infantry Boost 1",
		"Percentage of normal damage REDs deal after Infantry Boost 2",
		"Percentage of normal damage REDs deal after Infantry Boost 3"
	};	
	char convarDefMult[multREDs][] = { 
		"100", "110", "115", "125"
	};
	
	/* RED damage multiplier cooldowns */
	char convarNameCD[multREDs][] = {
		"sm_mult_baseIB0_red_cooldown",
		"sm_mult_baseIB1_red_cooldown",
		"sm_mult_baseIB2_red_cooldown",
		"sm_mult_baseIB3_red_cooldown"	
	};	
	char convarDescCD[multREDs][] = {
		"Percentage of normal damage REDs deal at Infantry Boost 0",
		"Percentage of normal damage REDs deal after Infantry Boost 1",
		"Percentage of normal damage REDs deal after Infantry Boost 2",
		"Percentage of normal damage REDs deal after Infantry Boost 3"
	};	
	char convarDefCD[multREDs][] = { 
		"135", "120", "105", "90"
	};
	
	for (int convar = 0; convar < view_as<int>(multREDs); convar++) 
	{
		gCvar_RedMult[convar] 		= 	AutoExecConfig_CreateConVar(convarNameMult[convar], convarDefMult[convar], convarDescMult[convar]);
		gCvar_RedCooldown[convar] 	= 	AutoExecConfig_CreateConVar(convarNameCD[convar], convarDefCD[convar], convarDescCD[convar]);
	}
	
	AutoExecConfig_EC_File();
}

/* Manage when ConVars change mid-game */
void UpdateConVarCache()
{
	for (int red = 0; red < view_as<int>(multREDs); red++) 
	{
		gFloat_RedMult[red] = gCvar_RedMult[red].FloatValue / 100.0;
		gFloat_RedCooldown[red] = gCvar_RedCooldown[red].FloatValue;
	}
}
void HookConVarChanges()
{
	for (int red = 0; red < view_as<int>(multREDs); red++) 
	{
		HookConVarChange(gCvar_RedMult[red], OnConfigPercentChange);
		HookConVarChange(gCvar_RedCooldown[red], OnConfigPercentChange);
	}
}
public void OnConfigPercentChange(ConVar convar, char[] oldValue, char[] newValue) {	
	UpdateConVarCache();
}
