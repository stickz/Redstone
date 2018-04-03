#include <autoexecconfig>
/* The convar mess starts here! */

/* Enumerated values for accessing ConVar arrays */
enum multREDs 
{
	red_bunker_mult,
	red_assembler_mult,
	red_transport_mult,
	red_artillery_mult,
	red_ft_turret_mult,
	red_power_plant_mult,
	red_armoury_mult,
	red_radar_mult
}
enum multBullets
{
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
enum multOther
{
	nx300_bunker_mult = 0,
	
	// GLs (Grenade Launchers)
	gl_bunker_mult,
	gl_assembler_mult,
	gl_transport_mult,
	gl_ft_turret_mult
}

/* ConVar and float arrays for the different types */
ConVar gCvar_Red[multREDs];
ConVar gCvar_Bullet[multBullets];
ConVar gCvar_Other[multOther];
ConVar cvarNoWarmupBunkerDamage;

float gFloat_Red[multREDs];
float gFloat_Bullet[multBullets];
float gFloat_Other[multOther];

/* Functions for creating covnars */
void CreatePluginConVars()
{
	CreateRedConVars();
	CreateBulletConVars();
	CreateOtherConVars();
	
	cvarNoWarmupBunkerDamage = CreateConVar("sm_warmup_protect_bunker", "1", "Disable bunker damage during the warmup round.");
}

void CreateRedConVars()
{
	AutoExecConfig_SetFile("nd_mult_reds");
	
	char convarName[multREDs][] = {
		"sm_mult_bunker_red",
		"sm_mult_assembler_red",
		"sm_mult_transport_red",
		"sm_mult_artillery_red",
		"sm_mult_ft_turret_red",
		"sm_mult_power_plant_red",
		"sm_mult_armoury_red",
		"sm_mult_radar_red"		
	};
	
	char convarDef[multREDs][] = { "120", "105", "150", "110", "140", "105", "105", "105"};
	
	char convarDesc[multREDs][] = {
		"Percentage of normal damage REDs deal to the bunker",
		"Percentage of normal damage REDs deal to assemblers",
		"Percentage of normal damage REDs deal to transport gates",
		"Percentage of normal damage REDs deal to artillery",
		"Percentage of normal damage REDs deal to ft/sonic turrets",
		"Percentage of normal damage REDs deal to power plants",
		"Percentage of normal damage REDs deal to armouries",
		"Percentage of normal damage REDs deal to radars"
	};	
	
	for (int convar = 0; convar < view_as<int>(multREDs); convar++) {
		gCvar_Red[convar] = AutoExecConfig_CreateConVar(convarName[convar], convarDef[convar], convarDesc[convar]);	
	}
	
	AutoExecConfig_EC_File();
}
void CreateBulletConVars()
{
	AutoExecConfig_SetFile("nd_mult_bullet");
	
	char convarName[multBullets][] = {	
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
	
	char convarDef[multBullets][] = { "150", "140", "135", "95", "115", "125", "115", "100", "115", "100", "75" };
	
	char convarDesc[multBullets][] = {
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
	
	for (int convar = 0; convar < view_as<int>(multBullets); convar++) {
		gCvar_Bullet[convar] = AutoExecConfig_CreateConVar(convarName[convar], convarDef[convar], convarDesc[convar]);	
	}
	
	AutoExecConfig_EC_File();	
}
void CreateOtherConVars()
{
	AutoExecConfig_SetFile("nd_mult_other");
	
	char convarName[multOther][] = {	
		sm_mult_bunker_nx300",
		
		// GLs (Grenade Launchers)
		"sm_mult_bunker_gl",
		"sm_mult_assembler_gl",
		"sm_mult_transport_gl",
		"sm_mult_ft_turret_gl"
	};
	
	char convarDef[multOther][] = { "120", "110", "125", "115" };
	
	char convarDesc[multOther][] = {
		"Percentage of normal damage nx300 does to bunker",
		
		// GLs (Grenade Launchers)
		"Percentage of normal damage GLs deal to the bunker",
		"Percentage of normal damage GLs deal to assemblers",
		"Percentage of normal damage GLs deal to transport gates",
		"Percentage of normal damage GLs deal to ft/sonic turrets"
	};
	
	for (int convar = 0; convar < view_as<int>(multOther); convar++) {
		gCvar_Other[convar] = AutoExecConfig_CreateConVar(convarName[convar], convarDef[convar], convarDesc[convar]);	
	}
	
	AutoExecConfig_EC_File();	
}

void AutoExecConfig_EC_File()
{
	// Execute and clean the cfg file
	AutoExecConfig_ExecuteFile();	
	AutoExecConfig_CleanFile();
}

/* Manage when ConVars change mid-game */
void UpdateConVarCache()
{
	for (int r = 0; r < view_as<int>(multREDs); r++) {
		gFloat_Red[r] = gCvar_Red[r].FloatValue / 100.0;
	}
	
	for (int b = 0; b < view_as<int>(multBullets); b++) {
		g_Float_Bullet[b] = gCvar_Bullets[b].FloatValue / 100.0;
	}
	
	for (int o = 0; o < view_as<int>(multOther); o++) {
		g_Float_Other[o] = g_Cvar_Other[o].FloatValue / 100.0;
	}
}
void HookConVarChanges()
{
	for (int r = 0; r < view_as<int>(multREDs); r++) {
		HookConVarChange(gCvar_Red[r], OnConfigPercentChange);
	}
	
	for (int b = 0; b < view_as<int>(multBullets); b++) {
		HookConVarChange(gCvar_Bullets[b], OnConfigPercentChange);
	}
	
	for (int o = 0; o < view_as<int>(multOther); o++) {
		HookConVarChange(g_Cvar_Other[o], OnConfigPercentChange);
	}
}
public void OnConfigPercentChange(ConVar convar, char[] oldValue, char[] newValue) {	
	UpdateConVarCache();
}
