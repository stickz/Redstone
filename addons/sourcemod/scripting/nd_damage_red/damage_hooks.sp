#include <nd_struct_eng>

public void ND_OnStructureCreated(int entity, const char[] classname)
{
	if (ND_RoundStarted())
	{		
		if (StrEqual(classname, STRUCT_ASSEMBLER))
			SDKHook(entity, SDKHook_OnTakeDamage, ND_OnAssemblerDamaged);
		
		else if (StrEqual(classname, STRUCT_TRANSPORT))
			SDKHook(entity, SDKHook_OnTakeDamage, ND_OnTransportDamaged);

		else if (StrEqual(classname, STRUCT_ARTILLERY))
			SDKHook(entity, SDKHook_OnTakeDamage, ND_OnArtilleryDamaged);
		
		else if (StrEqual(classname, STRUCT_SONIC_TURRET) ||
				 StrEqual(classname, STRUCT_FT_TURRET))
			SDKHook(entity, SDKHook_OnTakeDamage, ND_OnFlamerTurretDamaged);
		
		else if (StrEqual(classname, STRUCT_POWER_STATION))
			SDKHook(entity, SDKHook_OnTakeDamage, ND_OnPowerPlantDamaged);
		
		else if (StrEqual(classname, STRUCT_ARMOURY))
			SDKHook(entity, SDKHook_OnTakeDamage, ND_OnArmouryDamaged);
		
		else if (StrEqual(classname, STRUCT_RADAR))
			SDKHook(entity, SDKHook_OnTakeDamage, ND_OnRadarDamaged);
		
		else if (StrEqual(classname, STRUCT_MG_TURRET))
			SDKHook(entity, SDKHook_OnTakeDamage, ND_OnMGTurretDamaged);
		
		else if (StrEqual(classname, STRUCT_ROCKET_TURRET))
			SDKHook(entity, SDKHook_OnTakeDamage, ND_OnRocketTurretDamaged);
		
		else if (StrEqual(classname, STRUCT_SUPPLY))
			SDKHook(entity, SDKHook_OnTakeDamage, ND_OnSupplyStationDamaged);
			
		else if (StrEqual(classname, STRUCT_WALL))
			SDKHook(entity, SDKHook_OnTakeDamage, ND_OnWallDamaged);
			
		else if (StrEqual(classname, STRUCT_BARRIER))
			SDKHook(entity, SDKHook_OnTakeDamage, ND_OnBarrierDamaged);
	}
}

void HookEntitiesDamaged(bool lateLoad = false)
{
	SDK_HookEntityDamaged(STRUCT_BUNKER, ND_OnBunkerDamaged);
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
		SDK_HookEntityDamaged(STRUCT_MG_TURRET, ND_OnMGTurretDamaged);
		SDK_HookEntityDamaged(STRUCT_ROCKET_TURRET, ND_OnRocketTurretDamaged);
		SDK_HookEntityDamaged(STRUCT_SUPPLY, ND_OnSupplyStationDamaged);
		SDK_HookEntityDamaged(STRUCT_WALL, ND_OnWallDamaged);
		SDK_HookEntityDamaged(STRUCT_BARRIER, ND_OnBarrierDamaged);
	}
}

void UnHookEntitiesDamaged()
{
	SDK_UnHookEntityDamaged(STRUCT_BUNKER, ND_OnBunkerDamaged);
	SDK_UnHookEntityDamaged(STRUCT_ASSEMBLER, ND_OnAssemblerDamaged);
	SDK_UnHookEntityDamaged(STRUCT_TRANSPORT, ND_OnTransportDamaged);	
	SDK_UnHookEntityDamaged(STRUCT_ARTILLERY, ND_OnArtilleryDamaged);
	SDK_UnHookEntityDamaged(STRUCT_SONIC_TURRET, ND_OnFlamerTurretDamaged);
	SDK_UnHookEntityDamaged(STRUCT_FT_TURRET, ND_OnFlamerTurretDamaged);
	SDK_UnHookEntityDamaged(STRUCT_POWER_STATION, ND_OnPowerPlantDamaged);
	SDK_UnHookEntityDamaged(STRUCT_ARMOURY, ND_OnArmouryDamaged);
	SDK_UnHookEntityDamaged(STRUCT_RADAR, ND_OnRadarDamaged);
	SDK_UnHookEntityDamaged(STRUCT_MG_TURRET, ND_OnMGTurretDamaged);
	SDK_UnHookEntityDamaged(STRUCT_ROCKET_TURRET, ND_OnRocketTurretDamaged);
	SDK_UnHookEntityDamaged(STRUCT_SUPPLY, ND_OnSupplyStationDamaged);
	SDK_UnHookEntityDamaged(STRUCT_WALL, ND_OnWallDamaged);
	SDK_UnHookEntityDamaged(STRUCT_BARRIER, ND_OnBarrierDamaged);
}