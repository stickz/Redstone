#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <nd_stocks>
#include <nd_classes>
#include <nd_structures>
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

bool HookedDamage[MAXPLAYERS+1] = {false, ...};
ConVar ExoDamageMult;
ConVar RocketTurretDamage[2];

public void OnPluginStart() 
{
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_PostNoCopy);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_PostNoCopy);
	
	CreatePluginConVars();
	AddUpdaterLibrary(); //auto-updater
}

void CreatePluginConVars()
{	
	AutoExecConfig_Setup("nd_player_health");
	
	ExoDamageMult = AutoExecConfig_CreateConVar("sm_health_exo", "0.70", "Amount of damage dealt to exo. Example: 1 = 100%, 0.5 = 50%");
	RocketTurretDamage[0] = AutoExecConfig_CreateConVar("sm_rocket_consort", "80.0", "Amount of damage consort rocket turret does to players");
	RocketTurretDamage[1] = AutoExecConfig_CreateConVar("sm_rocket_empire", "60.0", "Amount of damage empire rocket turret does to players");
	
	AutoExecConfig_EC_File();
}

/* Functions that restore varriables to default */
public void OnClientDisconnect(int client) {
	ResetVariables(client);
}
public void ND_OnRoundStart() {
	for (int client = 0; client <= MAXPLAYERS; client++) 
		ResetVariables(client);
}
void ResetVariables(int client) {
	HookedDamage[client] = false;
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
	// If the inflictor entity is invalid, we must stop the checks
	if (!IsValidEntity(inflictor))
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
		float multDamage = ExoDamageMult.FloatValue;
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