/* The convar mess starts here! */
#define CONFIG_VARS 20
enum
{
    	nx300_bunker_mult = 0,
		
	// REDs (Remote Explosive Devices)
    	red_bunker_mult,
	red_assembler_mult,
	red_transport_mult,
	red_artillery_mult,
	red_ft_turret_mult,
	red_power_plant_mult,
	red_armoury_mult,
	red_radar_mult,
		
	// Bullets (Chainguns, Pistols, Rifles, SMGs etc)
	bullet_bunker_mult,
	bullet_assembler_mult,
	bullet_transport_mult,
	bullet_artillery_mult,
	bullet_ft_turret_mult,
	bullet_power_plant_mult,
	bullet_armoury_mult,
	bullet_radar_mult,
	bullet_mg_turret_mult,
	bullet_rocket_turret_mult,
	bullet_supply_station_mult
}
ConVar g_Cvar[CONFIG_VARS];
float g_Float[CONFIG_VARS];

/* The convar mess for controlling plugin settings on the fly */
void CreatePluginConVars()
{
	char convarName[CONFIG_VARS][] = {
		"sm_mult_bunker_nx300",
		
		// REDs (Remote Denotinated Explosives)
		"sm_mult_bunker_red",
		"sm_mult_assembler_red",
		"sm_mult_transport_red",
		"sm_mult_artillery_red",
		"sm_mult_ft_turret_red",
		"sm_mult_power_plant_red",
		"sm_mult_armoury_red",
		"sm_mult_radar_red",
		
		// Bullets (Chainguns, Pistols, Rifles, SMGs etc)
		"sm_mult_bunker_bullet",
		"sm_mult_assembler_bullet",
		"sm_mult_transport_bullet",
		"sm_mult_artillery_bullet",
		"sm_mult_ft_turret_bullet",
		"sm_mult_power_plant_bullet",
		"sm_mult_armoury_bullet",
		"sm_mult_radar_bullet",
		"sm_mult_mg_turret_bullet",
		"sm_mult_rocket_turret_bullet",
		"sm_mult_supply_station_bullet"
	};
	
	char convarDef[CONFIG_VARS][] = { 
		"85", // NX300 (Flamethrower)
		// REDs (Remote Explosive Devices)
		"120", "105", "150", "110", "140", "105", "105", "105",
		// Bullets (Chainguns, Pistols, Rifles, SMGs etc)
		"150", "140", "135", "95", "115", "125", "115", "100", "115", "100", "75"};
	
	char convarDesc[CONFIG_VARS][] = {
		"Percentage of normal damage nx300 does to bunker",
		
		// REDs (Remote Explosive Devices)
		"Percentage of normal damage REDs deal to the bunker",
		"Percentage of normal damage REDs deal to assemblers",
		"Percentage of normal damage REDs deal to transport gates",
		"Percentage of normal damage REDs deal to artillery",
		"Percentage of normal damage REDs deal to ft/sonic turrets",
		"Percentage of normal damage REDs deal to power plants",
		"Percentage of normal damage REDs deal to armouries",
		"Percentage of normal damage REDs deal to radars",
		
		// Bullets (Chainguns, Pistols, Rifles, SMGs etc)
		"Percentage of normal damage bullets deal to the bunker",
		"Percentage of normal damage bullets deal to assemblers",
		"Percentage of normal damage bullets deal to transport gates",
		"Percentage of normal damage bullets deal to artillery",
		"Percentage of normal damage bullets deal to ft/sonic turrets",
		"Percentage of normal damage bullets deal to power plants",
		"Percentage of normal damage bullets deal to armouries",
		"Percentage of normal damage bullets deal to radars",
		"Percentage of normal damage bullets deal to mg turrets",
		"Percentage of normal damage bullets deal to rocket turrets",
		"Percentage of normal damage bullets deal to supply stations"
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
