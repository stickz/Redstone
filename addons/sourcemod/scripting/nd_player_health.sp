#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
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
#define DEFAULT_EXO_DAMAGE_MULT 0.7

bool HookedDamage[MAXPLAYERS+1] = {false, ...};
ConVar cvarExoDamageMult[IBLEVELS];
ConVar RocketTurretDamage[2];

float ExoDamageMult[TEAM_COUNT] = { DEFAULT_EXO_DAMAGE_MULT, ... };

public void OnPluginStart() 
{
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_PostNoCopy);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_PostNoCopy);
	
	LoadTranslations("nd_player_health.phrases");
	
	CreatePluginConVars();
	AddUpdaterLibrary(); //auto-updater
}

void CreatePluginConVars()
{	
	AutoExecConfig_Setup("nd_player_health");
	
	cvarExoDamageMult[0] = AutoExecConfig_CreateConVar("sm_health_exo_ib0", "0.70", "Amount of damage dealt to exo at Infantry Boost 0.");
	cvarExoDamageMult[1] = AutoExecConfig_CreateConVar("sm_health_exo_ib1", "0.65", "Amount of damage dealt to exo at Infantry Boost 1.");
	cvarExoDamageMult[2] = AutoExecConfig_CreateConVar("sm_health_exo_ib2", "0.60", "Amount of damage dealt to exo at Infantry Boost 2.");
	cvarExoDamageMult[3] = AutoExecConfig_CreateConVar("sm_health_exo_ib3", "0.55", "Amount of damage dealt to exo at Infantry Boost 3.");
	
	RocketTurretDamage[0] = AutoExecConfig_CreateConVar("sm_rocket_consort", "80.0", "Amount of damage consort rocket turret does to players");
	RocketTurretDamage[1] = AutoExecConfig_CreateConVar("sm_rocket_empire", "60.0", "Amount of damage empire rocket turret does to players");
	
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
	
	ExoDamageMult[TEAM_EMPIRE] = DEFAULT_EXO_DAMAGE_MULT;
	ExoDamageMult[TEAM_CONSORT] = DEFAULT_EXO_DAMAGE_MULT;
}
void ResetVariables(int client) {
	HookedDamage[client] = false;
}

/* Armor increase logic */
public void OnInfantryBoostResearched(int team, int level) 
{
	float exoMultiplier = cvarExoDamageMult[level].FloatValue;	
	ExoDamageMult[team] = exoMultiplier;
	
	// Print a message to chat about until Armor increases
	PrintMessageTeam(team, "Armor Increases");
	
	/* Display console values for armor increases */
	PrintTeamSpacer(team); // Print spacer in console
	PrintConsoleTeam(team, "Armor Header Console"); // Add armor header
	PrintArmorIncreases(team, exoMultiplier); // Add Armor increase values
	PrintTeamSpacer(team); // Print spacer in console
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
void PrintArmorIncreases(int team, float exoMult)
{
	int exo = CalcDisplayArmorExo(exoMult);
	
	for (int m = 1; m <= MaxClients; m++)
	{
		if (IsClientInGame(m) && GetClientTeam(m) == team)
		{			
			PrintToConsole(m, "%t", "Armor Increase", exo);
		}
	}
}
int CalcDisplayArmorExo(float cValue) 
{
	float defValue = 1.0 - DEFAULT_EXO_DAMAGE_MULT;	
	return RoundFloat((1.0 - cValue + defValue) * 100.0);
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
	
	// If the structure is a rocket turret, apply the damage fix
	bool changed = false;	
	if (StrEqual(iClass(inflictor), STRUCT_ROCKET_TURRET, false))
	{
		float maxRDamage = GetRocketMaxDamage(victim);
		damage = maxRDamage;
		changed = true;
	}	
	
	// If the client is an exo, apply the 20% health rescaling
	int mainClass = ND_GetMainClass(victim);	
	if (IsExoClass(mainClass))
	{
		int team = GetClientTeam(victim);
		float multDamage = ExoDamageMult[team];
		damage *= multDamage;		
		changed = true;
	}
	
	return changed ? Plugin_Changed : Plugin_Continue;
}

stock float GetRocketMaxDamage(int client)
{	
	int team = GetClientTeam(client);	
	if (team == TEAM_EMPIRE || team == TEAM_CONSORT)
		return RocketTurretDamage[team-2].FloatValue;
		
	return 0.0;
}

stock char iClass(int &inflictor)
{
	char className[64];
	GetEntityClassname(inflictor, className, sizeof(className));
	return className;			
}