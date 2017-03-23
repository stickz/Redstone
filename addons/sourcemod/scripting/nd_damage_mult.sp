#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <nd_rounds>

#define BUNKER_DAMAGE_MULT 0.85
#define FLAMETHROWER_DT -2147481592

public Plugin myinfo = 
{
	name 		= "[ND] Damage Multiplers",
	author 		= "Stickz",
	description = "Creates new damage multiplers for better game balance",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_damage_mult/nd_damage_mult.txt"
#include "updater/standard.sp"

public void OnPluginStart()
{
	// Account for plugin late-loading
	if (ND_RoundStarted())
		HookBunkerEntities();
		
	AddUpdaterLibrary(); //auto-updater
}

public void ND_OnRoundStarted() {	
	HookBunkerEntities();
}

public Action ND_OnBunkerDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	// If the damage type is flamethrower, reduce the total damage
	if (damagetype == FLAMETHROWER_DT)
		damage *= BUNKER_DAMAGE_MULT;
	
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
