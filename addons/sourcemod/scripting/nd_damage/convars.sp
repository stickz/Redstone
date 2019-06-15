#include <autoexecconfig>
/* The convar mess starts here! */

/* Enumerated values for accessing ConVar arrays */
enum multREDs 
{
	red_bunker_mult = 0,
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
	bullet_bunker_mult = 0,
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
enum multSiege
{
	// Siegers (m95 & x01)
	siege_bunker_mult = 0,
	siege_assembler_mult,
	siege_transport_mult,
	siege_ft_turret_mult
}

enum multGL
{
	gl_bunker_mult = 0,
	gl_assembler_mult,
	gl_transport_mult,
	gl_ft_turret_mult
}

enum multOther
{
	nx300_ib1_base_mult = 0,
	nx300_ib2_base_mult,
	nx300_ib3_base_mult,
	nx300_bunker_mult,
	artillery_ib1_base_mult,
	artillery_ib2_base_mult,
	artillery_ib3_base_mult
}

/* ConVar and float arrays for the different types */
ConVar gCvar_Red[multREDs];
ConVar gCvar_Bullet[multBullets];
ConVar gCvar_Siege[multSiege];
ConVar gCvar_GL[multGL];
ConVar gCvar_Other[multOther];
ConVar cvarNoWarmupBunkerDamage;

float gFloat_Red[multREDs];
float gFloat_Bullet[multBullets];
float gFloat_Siege[multSiege];
float gFloat_GL[multGL];
float gFloat_Other[multOther];

/* Functions for creating covnars */
void CreatePluginConVars()
{
	// Tell the wrapper to create the files. Required for multiples.
	AutoExecConfig_SetCreateFile(true);
	
	CreateRedConVars();
	CreateBulletConVars();
	CreateSiegeConVars();
	CreateGLConVars();
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

void CreateSiegeConVars()
{
	AutoExecConfig_SetFile("nd_mult_siege");
	
	// Siegers (m95 & x01)
	char convarName[multSiege][] = {	
		"sm_mult_bunker_siege",
		"sm_mult_assembler_siege",
		"sm_mult_transport_siege",
		"sm_mult_ft_turret_siege"
	};
	char convarDesc[multSiege][] = {
		"Percentage of normal damage Siegers deal to the bunker",
		"Percentage of normal damage Siegers deal to assemblers",
		"Percentage of normal damage Siegers deal to transport gates",
		"Percentage of normal damage Siegers deal to ft/sonic turrets"		
	};	
	char convarDef[multSiege][] = { "110", "105", "110", "105"};	

	for (int convar = 0; convar < view_as<int>(multSiege); convar++) {
		gCvar_Siege[convar] = AutoExecConfig_CreateConVar(convarName[convar], convarDef[convar], convarDesc[convar]);	
	}
	
	AutoExecConfig_EC_File();
}

void CreateGLConVars()
{
	AutoExecConfig_SetFile("nd_mult_gl");
	
	// GLs (Grenade Launchers)
	char convarName[multGL][] = {		
		"sm_mult_bunker_gl",
		"sm_mult_assembler_gl",
		"sm_mult_transport_gl",
		"sm_mult_ft_turret_gl"
	};
	char convarDesc[multGL][] = {		
		// GLs (Grenade Launchers)
		"Percentage of normal damage GLs deal to the bunker",
		"Percentage of normal damage GLs deal to assemblers",
		"Percentage of normal damage GLs deal to transport gates",
		"Percentage of normal damage GLs deal to ft/sonic turrets"	
	};
	char convarDef[multGL][] = { "120", "110", "125", "110" };
	
	for (int convar = 0; convar < view_as<int>(multGL); convar++) {
		gCvar_GL[convar] = AutoExecConfig_CreateConVar(convarName[convar], convarDef[convar], convarDesc[convar]);	
	}
	
	AutoExecConfig_EC_File();
}

void CreateOtherConVars()
{
	AutoExecConfig_SetFile("nd_mult_other");
	
	char convarName[multOther][] = {	
		"sm_mult_baseIB1_nx300",
		"sm_mult_baseIB2_nx300",
		"sm_mult_baseIB3_nx300",
		"sm_mult_bunker_nx300",
		"sm_mult_baseSR1_artillery",
		"sm_mult_baseSR2_artillery",
		"sm_mult_baseSR3_artillery"
	};
	char convarDesc[multOther][] = {
		"Percentage of normal damage nx300 does after IB1",
		"Percentage of normal damage nx300 does after IB2",
		"Percentage of normal damage nx300 does after IB3",
		"Percentage of normal damage nx300 does to bunker",
		"Percentage of normal damage artillery does after SR1",
		"Percentage of normal damage artillery does after SR2",
		"Percentage of normal damage artillery does after SR13",
	};	
	char convarDef[multOther][] = { 
		// nx300 ib 1-3 base damage
		"103", "105", "107", 
		"85", // nx300 bunker damage
		// artillery sr 1-3 base damage
		"95", "90", "85"
	};		
	
	for (int convar = 0; convar < view_as<int>(multOther); convar++) {
		gCvar_Other[convar] = AutoExecConfig_CreateConVar(convarName[convar], convarDef[convar], convarDesc[convar]);	
	}
	
	AutoExecConfig_EC_File();	
}

/* Manage when ConVars change mid-game */
void UpdateConVarCache()
{
	for (int r = 0; r < view_as<int>(multREDs); r++) {
		gFloat_Red[r] = gCvar_Red[r].FloatValue / 100.0;
	}
	
	for (int b = 0; b < view_as<int>(multBullets); b++) {
		gFloat_Bullet[b] = gCvar_Bullet[b].FloatValue / 100.0;
	}
	
	for (int s = 0; s < view_as<int>(multSiege); s++) {
		gFloat_Siege[s] = gCvar_Siege[s].FloatValue / 100.0;
	}
	
	for (int g = 0; g < view_as<int>(multGL); g++) {
		gFloat_GL[g] = gCvar_GL[g].FloatValue / 100.0;
	}
	
	for (int o = 0; o < view_as<int>(multOther); o++) {
		gFloat_Other[o] = gCvar_Other[o].FloatValue / 100.0;
	}
}
void HookConVarChanges()
{
	for (int r = 0; r < view_as<int>(multREDs); r++) {
		HookConVarChange(gCvar_Red[r], OnConfigPercentChange);
	}
	
	for (int b = 0; b < view_as<int>(multBullets); b++) {
		HookConVarChange(gCvar_Bullet[b], OnConfigPercentChange);
	}
	
	for (int s = 0; s < view_as<int>(multSiege); s++) {
		HookConVarChange(gCvar_Siege[s], OnConfigPercentChange);
	}
	
	for (int g = 0; g < view_as<int>(multGL); g++) {
		HookConVarChange(gCvar_GL[g], OnConfigPercentChange);
	}
	
	for (int o = 0; o < view_as<int>(multOther); o++) {
		HookConVarChange(gCvar_Other[o], OnConfigPercentChange);
	}
}
public void OnConfigPercentChange(ConVar convar, char[] oldValue, char[] newValue) {	
	UpdateConVarCache();
}
