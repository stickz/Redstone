#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <nd_maps>
#include <nd_print>
#include <nd_stocks>
#include <nd_classes>
#include <nd_structures>
#include <nd_research_eng>
#include <autoexecconfig>

//Version is auto-filled by the travis builder
public Plugin myinfo = 
{
	name 		= "[ND] Player Health",
	author 		= "stickz",
	description	= "Changes damage taken for certain classes",
    version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
}

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_player_health/nd_player_health.txt"
#include "updater/standard.sp"

#define IBLEVELS 4
#define DEFAULT_EXO_DAMAGE_MULT 0.8
#define DEFAULT_DAMAGE_MULT 1.0

bool HookedDamage[MAXPLAYERS+1] = {false, ...};

bool cornerMap = false;

ConVar RocketTurretDamage[2];

ConVar cvarExoDamageMult[IBLEVELS];
ConVar cvarExoRocketDamageMult[IBLEVELS];

ConVar cvarAssaultDamageMult[IBLEVELS];
ConVar cvarStealthDamageMult[IBLEVELS];
ConVar cvarSupportDamageMult[IBLEVELS];

float ExoDamageMult[TEAM_COUNT] = { DEFAULT_EXO_DAMAGE_MULT, ... };
float ExoRocketDamageMult[TEAM_COUNT] = { DEFAULT_DAMAGE_MULT, ... };

float AssaultDamageMult[TEAM_COUNT] = { DEFAULT_DAMAGE_MULT, ... };
float StealthDamageMult[TEAM_COUNT] = { DEFAULT_DAMAGE_MULT, ... };
float SupportDamageMult[TEAM_COUNT] = { DEFAULT_DAMAGE_MULT, ... };

public void OnPluginStart() 
{
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_PostNoCopy);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_PostNoCopy);
	
	LoadTranslations("nd_player_health.phrases");
	
	CreatePluginConVars();
	AddUpdaterLibrary(); //auto-updater
}

public void OnMapStart()
{
	// Check if the corner map is corner to enable rocket turret protection
	cornerMap = ND_CurrentMapIsCorner();
}

void CreatePluginConVars()
{	
	AutoExecConfig_Setup("nd_player_health");
	
	RocketTurretDamage[0] = AutoExecConfig_CreateConVar("sm_rocket_consort", "90.0", "Amount of damage consort rocket turret does to players");
	RocketTurretDamage[1] = AutoExecConfig_CreateConVar("sm_rocket_empire", "75.0", "Amount of damage empire rocket turret does to players");
	
	cvarExoDamageMult[0] = AutoExecConfig_CreateConVar("sm_health_exo_ib0", "0.80", "Amount of damage dealt to exo at Infantry Boost 0.");
	cvarExoDamageMult[1] = AutoExecConfig_CreateConVar("sm_health_exo_ib1", "0.75", "Amount of damage dealt to exo at Infantry Boost 1.");
	cvarExoDamageMult[2] = AutoExecConfig_CreateConVar("sm_health_exo_ib2", "0.70", "Amount of damage dealt to exo at Infantry Boost 2.");
	cvarExoDamageMult[3] = AutoExecConfig_CreateConVar("sm_health_exo_ib3", "0.60", "Amount of damage dealt to exo at Infantry Boost 3.");
	
	cvarExoRocketDamageMult[0] = AutoExecConfig_CreateConVar("sm_rocket_exo_ib0", "0.80", "Amount of damage dealt to exo by rocket turrets at Infantry Boost 0.");
	cvarExoRocketDamageMult[1] = AutoExecConfig_CreateConVar("sm_rocket_exo_ib1", "0.70", "Amount of damage dealt to exo by rocket turrets at Infantry Boost 1.");
	cvarExoRocketDamageMult[2] = AutoExecConfig_CreateConVar("sm_rocket_exo_ib2", "0.60", "Amount of damage dealt to exo by rocket turrets at Infantry Boost 2.");
	cvarExoRocketDamageMult[3] = AutoExecConfig_CreateConVar("sm_rocket_exo_ib3", "0.40", "Amount of damage dealt to exo by rocket turrets at Infantry Boost 3.");
	
	cvarAssaultDamageMult[0] = AutoExecConfig_CreateConVar("sm_health_assault_ib0", "1.00", "Amount of damage dealt to assault at Infantry Boost 0.");
	cvarAssaultDamageMult[1] = AutoExecConfig_CreateConVar("sm_health_assault_ib1", "0.98", "Amount of damage dealt to assault at Infantry Boost 1.");
	cvarAssaultDamageMult[2] = AutoExecConfig_CreateConVar("sm_health_assault_ib2", "0.96", "Amount of damage dealt to assault at Infantry Boost 2.");
	cvarAssaultDamageMult[3] = AutoExecConfig_CreateConVar("sm_health_assault_ib3", "0.92", "Amount of damage dealt to assault at Infantry Boost 3.");
	
	cvarStealthDamageMult[0] = AutoExecConfig_CreateConVar("sm_health_stealth_ib0", "1.00", "Amount of damage dealt to stealth at Infantry Boost 0.");
	cvarStealthDamageMult[1] = AutoExecConfig_CreateConVar("sm_health_stealth_ib1", "0.98", "Amount of damage dealt to stealth at Infantry Boost 1.");
	cvarStealthDamageMult[2] = AutoExecConfig_CreateConVar("sm_health_stealth_ib2", "0.96", "Amount of damage dealt to stealth at Infantry Boost 2.");
	cvarStealthDamageMult[3] = AutoExecConfig_CreateConVar("sm_health_stealth_ib3", "0.92", "Amount of damage dealt to stealth at Infantry Boost 3.");
	
	cvarSupportDamageMult[0] = AutoExecConfig_CreateConVar("sm_health_support_ib0", "1.00", "Amount of damage dealt to support at Infantry Boost 0.");
	cvarSupportDamageMult[1] = AutoExecConfig_CreateConVar("sm_health_support_ib1", "0.98", "Amount of damage dealt to support at Infantry Boost 1.");
	cvarSupportDamageMult[2] = AutoExecConfig_CreateConVar("sm_health_support_ib2", "0.96", "Amount of damage dealt to support at Infantry Boost 2.");
	cvarSupportDamageMult[3] = AutoExecConfig_CreateConVar("sm_health_support_ib3", "0.92", "Amount of damage dealt to support at Infantry Boost 3.");
	
	AutoExecConfig_EC_File();
}

/* Functions that restore varriables to default */
public void OnClientDisconnect(int client) {
	ResetVariables(client);
}
public void ND_OnRoundStart() 
{
	for (int client = 0; client <= MAXPLAYERS; client++) 
		ResetVariables(client);
	
	
	for (int team = 2; team < TEAM_COUNT; team++)
	{
		ExoDamageMult[team] = cvarExoDamageMult[0].FloatValue;
		ExoRocketDamageMult[team] = cvarExoDamageMult[0].FloatValue;
		AssaultDamageMult[team] = cvarAssaultDamageMult[0].FloatValue;
		StealthDamageMult[team] = cvarStealthDamageMult[0].FloatValue;
		SupportDamageMult[team] = cvarSupportDamageMult[0].FloatValue;		
	}
}
void ResetVariables(int client) {
	HookedDamage[client] = false;
}

/* Armor increase logic */
public void OnInfantryBoostResearched(int team, int level) 
{
	UpdateDamageMultipliers(team, level);
	
	// Print a message to chat about until Armor increases
	PrintMessageTeam(team, "Armor Increases");
	
	/* Display console values for armor increases */
	PrintTeamSpacer(team); // Print spacer in console
	PrintConsoleTeam(team, "Armor Header Console"); // Add armor header
	PrintArmorIncreases(team, level); // Add Armor increase values
	PrintTeamSpacer(team); // Print spacer in console
}

void UpdateDamageMultipliers(int team, int level)
{
	ExoDamageMult[team] 	= cvarExoDamageMult[level].FloatValue;
	AssaultDamageMult[team] = cvarAssaultDamageMult[level].FloatValue;
	StealthDamageMult[team] = cvarStealthDamageMult[level].FloatValue;
	SupportDamageMult[team] = cvarSupportDamageMult[level].FloatValue;	
	
	// If the current map is corner, change the rocket turret damage multiplier for exos; otherwise leave it alone
	ExoRocketDamageMult[team] = cornerMap ? cvarExoRocketDamageMult[level].FloatValue : ExoDamageMult[team];
}

void PrintTeamSpacer(int team)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == team)
		{
			PrintToConsole(client, "");
		}
	}
}
void PrintArmorIncreases(int team, int level)
{
	int exo = CalcDisplayArmorExo(cvarExoDamageMult[level].FloatValue);
	int assault = CalcDisplayArmor(cvarAssaultDamageMult[level].FloatValue);
	int stealth = CalcDisplayArmor(cvarStealthDamageMult[level].FloatValue);
	int support = CalcDisplayArmor(cvarSupportDamageMult[level].FloatValue);
	
	for (int m = 1; m <= MaxClients; m++)
	{
		if (IsClientInGame(m) && GetClientTeam(m) == team)
		{			
			PrintToConsole(m, "%t", "Armor Increase", assault, exo, stealth, support);			
		}
	}
	
	// If the map is corner, display the rocket turret exo protection values
	if (cornerMap)
	{
		int amount = CalcDisplayProtectRT(level);
		
		for (int c = 1; c <= MaxClients; c++)
		{
			if (IsClientInGame(c) && GetClientTeam(c) == team)
			{
				PrintToConsole(c, "%t", "RT Exo Protection", amount);				
			}	
		}
	}	
}

int CalcDisplayProtectRT(int level)
{
	float defValue = 1.0 - DEFAULT_EXO_DAMAGE_MULT
	float exoValue = DEFAULT_EXO_DAMAGE_MULT - cvarExoDamageMult[level].FloatValue;
	float rtValue = cvarExoRocketDamageMult[level].FloatValue;
	return RoundFloat((1.0 - rtValue - defValue - exoValue) * 100.0);
}

int CalcDisplayArmorExo(float cValue) 
{
	float defValue = 1.0 - DEFAULT_EXO_DAMAGE_MULT;	
	return RoundFloat((1.0 - cValue - defValue) * 100.0);
}
int CalcDisplayArmor(float cValue) {
	return RoundFloat((1.0 - cValue) * 100);
}

/* Event hooks */
public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));	
	
	if (!HookedDamage[client])
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
		HookedDamage[client] = true;	
	}
	
	return Plugin_Continue;	
}
public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));	
	
	if (HookedDamage[client])
	{
		SDKUnhook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
		HookedDamage[client] = false;
	}

	return Plugin_Continue;
}
public Action OnPlayerTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	// If the inflictor or attacker entity is invalid, we must stop the checks
	if (!IsValidEntity(inflictor) || !IsValidBounds(attacker))
		return Plugin_Continue;
	
	// Get the team of the victim
	int team = GetClientTeam(victim);
	
	// Get the inflictor weapon class
	char className[64];
	GetEntityClassname(inflictor, className, sizeof(className));
	
	// Get the main class of the victim
	int mainClass = ND_GetMainClass(victim);
	
	// Get if the client's main class is an exo
	bool IsClientExoClass = IsExoClass(mainClass);
	
	// If the structure is a rocket turret, apply the damage fix
	if (StrEqual(className, STRUCT_ROCKET_TURRET, false))
	{
		float maxRDamage = GetRocketMaxDamage(team);
		damage = maxRDamage;
		
		// If the client is exo apply the rocket turret damage protection
		// Currently only applies to corner map, otherwise damage will match exo mult
		if (IsClientExoClass)
		{
			float multExoRT = ExoRocketDamageMult[team];
			damage *= multExoRT;
			return Plugin_Changed;			
		}		
	}	
	
	// If the client is an exo, apply the 20% health rescaling
	// Also apply 5% armor (damage resistance) per infantry boost level
	if (IsClientExoClass)
	{
		// Do not apply armor to exos for machine gun turrets
		if (StrEqual(className, STRUCT_MG_TURRET, false))
		{
			damage *= DEFAULT_EXO_DAMAGE_MULT;
			return Plugin_Changed;
		}		
		
		float multExo = ExoDamageMult[team];
		damage *= multExo;		
		return Plugin_Changed
	}	
	
	// If the client is assault apply 1% 3% 5% infantry boost armor
	else if (IsAssaultClass(mainClass))
	{
		float multAssault = AssaultDamageMult[team];
		damage *= multAssault;
		return Plugin_Changed;		
	}
	
	// If the client is stealth apply 1% 3% 5% infantry boost armor
	else if (IsStealthClass(mainClass))
	{
		float multStealth = StealthDamageMult[team];
		damage *= multStealth;
		return Plugin_Changed;		
	}
	
	// If the client is support apply 1% 3% 5% infantry boost armor
	else if (IsSupportClass(mainClass))
	{
		float multSupport = SupportDamageMult[team];
		damage *= multSupport;
		return Plugin_Changed;		
	}
	
	return Plugin_Continue;
}

float GetRocketMaxDamage(int team)
{	
	if (team == TEAM_EMPIRE || team == TEAM_CONSORT)
		return RocketTurretDamage[team-2].FloatValue;
		
	return 0.0;
}