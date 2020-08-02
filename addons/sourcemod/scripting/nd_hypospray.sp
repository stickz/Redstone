#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <nd_print>
#include <nd_stocks>
#include <nd_weapons>
#include <nd_research_eng>
#include <autoexecconfig>

//Version is auto-filled by the travis builder
public Plugin myinfo = 
{
	name 		= "[ND] Hypospray",
	author 		= "stickz",
	description	= "Makes hypospray more balanced by attaching value to it",
    	version 	= "recompile",
	url 		= "https://github.com/stickz/Redstone/"
}

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_hypospray/nd_hypospray.txt"
#include "updater/standard.sp"

#define IBLEVELS 4
#define COND_HYPOSPRAY (1<<10)
#define DEFAULT_HYPOSPRAY_MULT 0.7

ConVar cvarHyposprayDamageMult[IBLEVELS];

bool HookedDamage[MAXPLAYERS+1] = {false, ...};

float HyposprayDamageMult[TEAM_COUNT] = { DEFAULT_HYPOSPRAY_MULT, ... };

public void OnPluginStart() 
{
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_PostNoCopy);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_PostNoCopy);
	
	LoadTranslations("nd_hypospray.phrases");
	
	CreatePluginConVars(); // convars.sp
	AddUpdaterLibrary(); //auto-updater
}

public void OnPluginEnd()
{
	// Restore hypospray damage back to normal if the plugin ends
	ServerCommand("nd_hypospray_damage_reduction %d", DEFAULT_HYPOSPRAY_MULT);	
}

void CreatePluginConVars()
{	
	AutoExecConfig_Setup("nd_hypospray");
	
	cvarHyposprayDamageMult[0] = AutoExecConfig_CreateConVar("sm_hypo_protect_ib0", "0.6", "Damage protection hypospray offers at Infantry Boost 0.");
	cvarHyposprayDamageMult[1] = AutoExecConfig_CreateConVar("sm_hypo_protect_ib1", "0.7", "Damage protection hypospray offers at Infantry Boost 1.");
	
	AutoExecConfig_EC_File();
}

public void OnConfigsExecuted()
{
	// Disable hypospray damage protect as the plugin overrides it
	ServerCommand("sm_cvar nd_hypospray_damage_reduction 0");
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
		HyposprayDamageMult[team] = cvarHyposprayDamageMult[0].FloatValue;
}

void ResetVariables(int client) {
	HookedDamage[client] = false;
}

/* Hypospray increase logic */
public void OnInfantryBoostResearched(int team, int level) 
{
	if (level == 1)
	{
		HyposprayDamageMult[team] = cvarHyposprayDamageMult[1].FloatValue;
	
		// Print a message to chat about hypospray increases
		PrintMessageTeam(team, "Hypospray Increases");
		
		/* Display console values for hypospray increases */
		PrintTeamSpacer(team); // Print spacer in console
		PrintConsoleTeam(team, "Hypospray Header Console"); // Add hypospray header
		PrintHypoIncreases(team, level); // Add Hypospray increase values
		PrintTeamSpacer(team); // Print spacer in console
	}
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

void PrintHypoIncreases(int team, int level)
{
	for (int m = 1; m <= MaxClients; m++)
	{
		if (IsClientInGame(m) && GetClientTeam(m) == team)
		{			
			PrintToConsole(m, "%t", "Hypospray Increase");
		}
	}
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
	
	// If the inflictor is a grenade, don't modify the damage taken
	if (InflictorIsGasGrenade(className))
		return Plugin_Continue;
	
	// If the player is hyposprayed, change the damage inflicted to them
	if (GetEntProp(victim, Prop_Send, "m_nPlayerCond") & COND_HYPOSPRAY)
	{
		// Multiply damage taken: IE. 70% protection means 30% damage taken
		float HyposprayDamage = 1.0 - HyposprayDamageMult[team];
		damage *= HyposprayDamage;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}
