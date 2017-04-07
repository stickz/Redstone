#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <nd_rounds>

#define WEAPON_NX300_DT -2147481592
#define WEAPON_RED_DT 64

public Plugin myinfo = 
{
	name 		= "[ND] Damage Multiplers",
	author 		= "Stickz",
	description 	= "Creates new damage multiplers for better game balance",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_damage_mult/nd_damage_mult.txt"
#include "updater/standard.sp"

/* The convar mess starts here! */
#define CONFIG_VARS 2

enum convars
{
	ConVar:nx300_bunker_per,
	ConVar:red_bunker_per
};
ConVar g_Cvar[convars];

enum floats
{
	Float:nx300_bunker_mult,
	Float:red_bunker_mult
};
float g_Float[floats];

public void OnPluginStart()
{
	// Account for plugin late-loading
	if (ND_RoundStarted())
		HookBunkerEntities();
		
	AddUpdaterLibrary(); //auto-updater
	
	CreatePluginConVars();
	HookConVarChanges();
	AutoExecConfig(true, "nd_damage_mult");
}

public void ND_OnRoundStarted() {	
	HookBunkerEntities();
}

public Action ND_OnBunkerDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	// If the damage type is flamethrower, reduce the total damage
	if (damagetype == WEAPON_NX300_DT)
		damage *= g_Float[nx300_bunker_mult];
	
	// If the damage type is a RED, increase the total damage
	else if (damagetype == WEAPON_RED_DT)
		damage *= g_Float[red_bunker_mult];
	
	//PrintToChatAll("The damage type is %d.", damagetype);
}

void HookBunkerEntities()
{
	/* Find and hook when the bunker entities are damaged. */
	int loopEntity = INVALID_ENT_REFERENCE;
	while ((loopEntity = FindEntityByClassname(loopEntity, "struct_command_bunker")) != INVALID_ENT_REFERENCE) {
		SDKHook(loopEntity, SDKHook_OnTakeDamage, ND_OnBunkerDamaged);		
	}
}

/* The convar mess for controlling plugin settings on the fly */
void CreatePluginConVars()
{
	g_Cvar[nx300_bunker_per] = CreateConVar("sm_mult_bunker_nx300", "85", "Percentage of normal damage nx300 does to bunker");
	g_Cvar[red_bunker_per] = CreateConVar("sm_mult_bunker_nx300", "120", "Percentage of normal damage REDs do to the bunker");
}

void UpdateConVarCache()
{
	for (int i = 0; i < CONFIG_VARS; i++)	{
		g_Float[i] = g_Cvar[i].FloatValue / 100;	
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
