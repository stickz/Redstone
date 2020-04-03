#include <autoexecconfig>

ConVar RocketTurretDamage[2];

ConVar cvarExoDamageMult[IBLEVELS];
ConVar cvarExoRocketDamageMult[IBLEVELS];
ConVar cvarExoArtilleryDamageMult[IBLEVELS];

ConVar cvarAssaultDamageMult[IBLEVELS];
ConVar cvarStealthDamageMult[IBLEVELS];
ConVar cvarSupportDamageMult[IBLEVELS];

void CreatePluginConVars()
{	
	CreatePlayerHealthConvars();
	CreateOtherHealthConvars();
}

void CreatePlayerHealthConvars()
{
	AutoExecConfig_Setup("nd_health_player");
	
	cvarExoDamageMult[0] = AutoExecConfig_CreateConVar("sm_health_exo_ib0", "0.80", "Amount of damage dealt to exo at Infantry Boost 0.");
	cvarExoDamageMult[1] = AutoExecConfig_CreateConVar("sm_health_exo_ib1", "0.75", "Amount of damage dealt to exo at Infantry Boost 1.");
	cvarExoDamageMult[2] = AutoExecConfig_CreateConVar("sm_health_exo_ib2", "0.70", "Amount of damage dealt to exo at Infantry Boost 2.");
	cvarExoDamageMult[3] = AutoExecConfig_CreateConVar("sm_health_exo_ib3", "0.65", "Amount of damage dealt to exo at Infantry Boost 3.");
	
	cvarAssaultDamageMult[0] = AutoExecConfig_CreateConVar("sm_health_assault_ib0", "0.95", "Amount of damage dealt to assault at Infantry Boost 0.");
	cvarAssaultDamageMult[1] = AutoExecConfig_CreateConVar("sm_health_assault_ib1", "0.93", "Amount of damage dealt to assault at Infantry Boost 1.");
	cvarAssaultDamageMult[2] = AutoExecConfig_CreateConVar("sm_health_assault_ib2", "0.91", "Amount of damage dealt to assault at Infantry Boost 2.");
	cvarAssaultDamageMult[3] = AutoExecConfig_CreateConVar("sm_health_assault_ib3", "0.87", "Amount of damage dealt to assault at Infantry Boost 3.");
	
	cvarStealthDamageMult[0] = AutoExecConfig_CreateConVar("sm_health_stealth_ib0", "0.95", "Amount of damage dealt to stealth at Infantry Boost 0.");
	cvarStealthDamageMult[1] = AutoExecConfig_CreateConVar("sm_health_stealth_ib1", "0.93", "Amount of damage dealt to stealth at Infantry Boost 1.");
	cvarStealthDamageMult[2] = AutoExecConfig_CreateConVar("sm_health_stealth_ib2", "0.91", "Amount of damage dealt to stealth at Infantry Boost 2.");
	cvarStealthDamageMult[3] = AutoExecConfig_CreateConVar("sm_health_stealth_ib3", "0.87", "Amount of damage dealt to stealth at Infantry Boost 3.");
	
	cvarSupportDamageMult[0] = AutoExecConfig_CreateConVar("sm_health_support_ib0", "0.95", "Amount of damage dealt to support at Infantry Boost 0.");
	cvarSupportDamageMult[1] = AutoExecConfig_CreateConVar("sm_health_support_ib1", "0.93", "Amount of damage dealt to support at Infantry Boost 1.");
	cvarSupportDamageMult[2] = AutoExecConfig_CreateConVar("sm_health_support_ib2", "0.91", "Amount of damage dealt to support at Infantry Boost 2.");
	cvarSupportDamageMult[3] = AutoExecConfig_CreateConVar("sm_health_support_ib3", "0.87", "Amount of damage dealt to support at Infantry Boost 3.");
	
	AutoExecConfig_EC_File();	
}

void CreateOtherHealthConvars()
{
	AutoExecConfig_Setup("nd_health_other");
	
	RocketTurretDamage[0] = AutoExecConfig_CreateConVar("sm_rocket_consort", "90.0", "Amount of damage consort rocket turret does to players");
	RocketTurretDamage[1] = AutoExecConfig_CreateConVar("sm_rocket_empire", "75.0", "Amount of damage empire rocket turret does to players");
	
	cvarExoRocketDamageMult[0] = AutoExecConfig_CreateConVar("sm_rocket_exo_ib0", "0.80", "Amount of damage dealt to exo by rocket turrets at Infantry Boost 0.");
	cvarExoRocketDamageMult[1] = AutoExecConfig_CreateConVar("sm_rocket_exo_ib1", "0.70", "Amount of damage dealt to exo by rocket turrets at Infantry Boost 1.");
	cvarExoRocketDamageMult[2] = AutoExecConfig_CreateConVar("sm_rocket_exo_ib2", "0.55", "Amount of damage dealt to exo by rocket turrets at Infantry Boost 2.");
	cvarExoRocketDamageMult[3] = AutoExecConfig_CreateConVar("sm_rocket_exo_ib3", "0.40", "Amount of damage dealt to exo by rocket turrets at Infantry Boost 3.");
	
	cvarExoArtilleryDamageMult[0] = AutoExecConfig_CreateConVar("sm_artillery_exo_ib0", "0.80", "Amount of damage dealt to exo by artillery at Infantry Boost 0.");
	cvarExoArtilleryDamageMult[1] = AutoExecConfig_CreateConVar("sm_artillery_exo_ib1", "0.70", "Amount of damage dealt to exo by artillery at Infantry Boost 1.");
	cvarExoArtilleryDamageMult[2] = AutoExecConfig_CreateConVar("sm_artillery_exo_ib2", "0.60", "Amount of damage dealt to exo by artillery at Infantry Boost 2.");
	cvarExoArtilleryDamageMult[3] = AutoExecConfig_CreateConVar("sm_artillery_exo_ib3", "0.45", "Amount of damage dealt to exo by artillery at Infantry Boost 3.");
	
	AutoExecConfig_EC_File();	
}