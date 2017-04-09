/* The convar mess starts here! */
#define CONFIG_VARS 9
enum
{
    	nx300_bunker_mult = 0,
    	red_bunker_mult,
	red_assembler_mult,
	red_transport_mult,
	red_artillery_mult,
	red_ft_turret_mult,
	red_power_plant_mult,
	red_armoury_mult,
	red_radar_mult
}
ConVar g_Cvar[CONFIG_VARS];
float g_Float[CONFIG_VARS];

/* The convar mess for controlling plugin settings on the fly */
void CreatePluginConVars()
{
	char convarName[CONFIG_VARS][] = {
		"sm_mult_bunker_nx300",
		"sm_mult_bunker_red",
		"sm_mult_assembler_red",
		"sm_mult_transport_red",
		"sm_mult_artillery_red",
		"sm_mult_ft_turret_red",
		"sm_mult_power_plant_red",
		"sm_mult_armoury_red",
		"sm_mult_radar_red"
	};
	
	char convarDef[CONFIG_VARS][] = { "85", "120", "105", "130", "110", "120", "105", "105", "105" };
	
	char convarDesc[CONFIG_VARS][] = {
		"Percentage of normal damage nx300 does to bunker",
		"Percentage of normal damage REDs do to the bunker",
		"Percentage of normal damage REDs deal to assemblers",
		"Percentage of normal damage REDs deal to transport gates",
		"Percentage of normal damage REDs deal to artillery",
		"Percentage of normal damage REDs deal to ft/sonic turrets",
		"Percentage of normal damage REDs deal to power plants",
		"Percentage of normal damage REDs deal to armouries",
		"Percentage of normal damage REDs deal to radars"
	};
	
	for (int convar = 0; convar < CONFIG_VARS; convar++) {
		g_Cvar[convar] = CreateConVar(convarName[convar], convarDef[convar], convarDesc[convar]);	
	}
}

void UpdateConVarCache()
{
	for (int i = 0; i < CONFIG_VARS; i++)	{
		g_Float[i] = g_Cvar[i].FloatValue / 100.0;	
	}
}

void HookConVarChanges()
{
	for (int i = 0; i < CONFIG_VARS; i++)	{
		HookConVarChange(g_Cvar[i], OnConfigPercentChange);
	}
}

public void OnConfigPercentChange(ConVar convar, char[] oldValue, char[] newValue) {	
	UpdateConVarCache();
}
