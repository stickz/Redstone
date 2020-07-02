#include <autoexecconfig>

#define RED_COOLDOWN_SIZE 4

/* Enumerated values for accessing ConVar arrays */
enum multREDs 
{
	// Infantry boost multipliers
	red_ib0_base_mult,
	red_ib1_base_mult,
	red_ib2_base_mult,
	red_ib3_base_mult,
	
	// Base damage multipliers
	red_bunker_mult,
	red_transport_mult,
	red_ft_turret_mult,
	red_wall_mult,
	red_barrier_mult
}

/* ConVar and float arrays for the different types */
ConVar gCvar_RedMult[multREDs];
float gFloat_RedMult[multREDs];

ConVar gCvar_RedCooldown[RED_COOLDOWN_SIZE];
float gFloat_RedCooldown[RED_COOLDOWN_SIZE];

void CreateRedConVars()
{
	AutoExecConfig_SetFile("nd_mult_reds");
	
	/* RED base damage multipliers */
	char convarNameMult[multREDs][] = {
		// Infantry boost multipliers
		"sm_mult_baseIB0_red",
		"sm_mult_baseIB1_red",
		"sm_mult_baseIB2_red",
		"sm_mult_baseIB3_red",
		
		// Base damage multipliers
		"sm_mult_bunker_red",
		"sm_mult_transport_red",
		"sm_mult_ft_turret_red",
		"sm_mult_wall_red",
		"sm_mult_barrier_red"
	};	
	char convarDescMult[multREDs][] = {
		// Infantry boost multipliers
		"Percentage of normal damage REDs deal at Infantry Boost 0",
		"Percentage of normal damage REDs deal after Infantry Boost 1",
		"Percentage of normal damage REDs deal after Infantry Boost 2",
		"Percentage of normal damage REDs deal after Infantry Boost 3",
		
		// Base damage multipliers
		"Percentage of normal damage REDs deal to the bunker",
		"Percentage of normal damage REDs deal to transport gates",
		"Percentage of normal damage REDs deal to ft/sonic turrets",
		"Percentage of normal damage REDs deal to walls",
		"Percentage of normal damage REDs deal to barriers"
	};	
	char convarDefMult[multREDs][] = { 
		// Infantry boost multipliers
		"100", "110", "115", "125",
		
		// Base damage multipliers
		"100", "100", "100", "100", "100"
	};
	
	for (int mult = 0; mult < view_as<int>(multREDs); mult++) {
		gCvar_RedMult[mult] = 	AutoExecConfig_CreateConVar(convarNameMult[mult], convarDefMult[mult], convarDescMult[mult]);
	}
	
	/* RED damage multiplier cooldowns */
	char convarNameCD[RED_COOLDOWN_SIZE][] = {
		"sm_mult_baseIB0_red_cooldown",
		"sm_mult_baseIB1_red_cooldown",
		"sm_mult_baseIB2_red_cooldown",
		"sm_mult_baseIB3_red_cooldown"	
	};	
	char convarDescCD[RED_COOLDOWN_SIZE][] = {
		"Percentage of normal damage REDs deal at Infantry Boost 0",
		"Percentage of normal damage REDs deal after Infantry Boost 1",
		"Percentage of normal damage REDs deal after Infantry Boost 2",
		"Percentage of normal damage REDs deal after Infantry Boost 3"
	};	
	char convarDefCD[RED_COOLDOWN_SIZE][] = { 
		"135", "120", "105", "90"
	};
	
	for (int convar = 0; convar < RED_COOLDOWN_SIZE; convar++) {
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
