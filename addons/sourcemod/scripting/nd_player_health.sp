#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <nd_classes>
#include <autoexecconfig>

//Version is auto-filled by the travis builder
public Plugin myinfo = 
{
	name 		= "[ND] Player Health",
	author 		= "stickz",
    description	= "Changes damage taken for certain classes",
    version 	= "recompile",
	url 		= "https://github.com/stickz/Redstone/"
}

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_player_health/nd_player_health.txt"
#include "updater/standard.sp"

bool HookedDamage[MAXPLAYERS+1] = {false, ...};
ConVar ExoDamageMult;

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
	int mainClass = ND_GetMainClass(victim);
	
	if (IsExoClass(mainClass))
	{
		float multDamage = ExoDamageMult.FloatValue;
		damage *= multDamage;
		return Plugin_Changed;		
	}
	
	return Plugin_Continue;
}