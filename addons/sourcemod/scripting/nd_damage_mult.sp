#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <nd_rounds>
#include <nd_structures>

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

/* Plugin Includes */
#include "nd_damage/convars.sp"
#include "nd_damage/damage_events.sp"

public void OnPluginStart()
{
	AddUpdaterLibrary(); //auto-updater
	
	CreatePluginConVars();
	HookConVarChanges();
	AutoExecConfig(true, "nd_damage_mult");
	
	// Account for plugin late-loading
	if (ND_RoundStarted())
	{
		HookEntitiesDamaged(true);
		UpdateConVarCache();	
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (ND_RoundStarted())
	{		
		if (StrEqual(classname, STRUCT_ASSEMBLER, true))
			SDKHook(entity, SDKHook_OnTakeDamage, ND_OnAssemblerDamaged);
		
		else if (StrEqual(classname, STRUCT_TRANSPORT, true))
			SDKHook(entity, SDKHook_OnTakeDamage, ND_OnTransportDamaged);

		else if (StrEqual(classname, STRUCT_ARTILLERY, true))
			SDKHook(entity, SDKHook_OnTakeDamage, ND_OnArtilleryDamaged);
		
		else if (StrEqual(classname, STRUCT_SONIC_TURRET, true) ||
			 StrEqual(classname, STRUCT_FT_TURRET, true))
			SDKHook(entity, SDKHook_OnTakeDamage, ND_OnFlamerTurretDamaged);
		
		else if (StrEqual(classname, STRUCT_POWER_STATION, true))
			SDKHook(entity, SDKHook_OnTakeDamage, ND_OnPowerPlantDamaged);
		
		else if (StrEqual(classname, STRUCT_ARMOURY, true))
			SDKHook(entity, SDKHook_OnTakeDamage, ND_OnArmouryDamaged);
		
		else if (StrEqual(classname, STRUCT_RADAR, true))
			SDKHook(entity, SDKHook_OnTakeDamage, ND_OnRadarDamaged);
	}	
}

public void ND_OnRoundStarted()
{
	HookEntitiesDamaged();
	UpdateConVarCache();
}

void HookEntitiesDamaged(bool lateLoad = false)
{
	SDK_HookEntityDamaged("struct_command_bunker", ND_OnBunkerDamaged);
	SDK_HookEntityDamaged(STRUCT_ASSEMBLER, ND_OnAssemblerDamaged);
	SDK_HookEntityDamaged(STRUCT_TRANSPORT, ND_OnTransportDamaged);
	
	if (lateLoad) // Save interations by only checking for these when required
	{
		SDK_HookEntityDamaged(STRUCT_ARTILLERY, ND_OnArtilleryDamaged);
		
		// Flamethrower and sonic turrets on same event
		SDK_HookEntityDamaged(STRUCT_SONIC_TURRET, ND_OnFlamerTurretDamaged);
		SDK_HookEntityDamaged(STRUCT_FT_TURRET, ND_OnFlamerTurretDamaged);
		SDK_HookEntityDamaged(STRUCT_POWER_STATION, ND_OnPowerPlantDamaged);
		SDK_HookEntityDamaged(STRUCT_ARMOURY, ND_OnArmouryDamaged);
		SDK_HookEntityDamaged(STRUCT_RADAR, ND_OnRadarDamaged);
	}
}

void SDK_HookEntityDamaged(const char[] classname, SDKHookCB callback)
{
        /* Find and hook when entities is damaged. */
	int loopEntity = INVALID_ENT_REFERENCE;
	while ((loopEntity = FindEntityByClassname(loopEntity, classname)) != INVALID_ENT_REFERENCE) {
		SDKHook(loopEntity, SDKHook_OnTakeDamage, callback);		
	}
}
