#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0.3"

#define MAX_BUILD_TIME 57

new placementEntCount = 0;

public Plugin:myinfo = 
{
	name = "[ND] Build Shadow Fix",
	author = "stickz",
	description = "Fixes stuck build shadows when a building fails to build",
	version = PLUGIN_VERSION,
	url = "N/A"
}

#define UPDATE_URL  "https://github.com/stickz/Redstone/blob/master/updater/nd_build_shadow_fix/nd_build_shadow_fix.txt"
#include "updater/standard.sp"

public OnPluginStart()
{
	AddUpdaterLibrary(); //auto-updater
}

public OnMapStart()
{
	placementEntCount = 0;
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "nd_structure_placement_instance"))
	{	
		placementEntCount++;		
		new shouldBeBuilt = placementEntCount * MAX_BUILD_TIME; 
		CreateTimer(float(shouldBeBuilt), Timer_DestoryGlitchedPlacement, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public OnEntityDestroyed(entity)
{
	if (IsValidEntity(entity))
	{	
		decl String:className[32];
		GetEntityClassname(entity, className, sizeof(className));	
		
		if (StrEqual(className, "nd_structure_placement_instance"))
			placementEntCount--;
	}
}

public Action:Timer_DestoryGlitchedPlacement(Handle:timer, any:entRef)
{
	// try and get the entity back
	new entity = EntRefToEntIndex(entRef);

	if (entity != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(entity, "Kill");
		PrintToChatAll("\x05[xG] Beta Feature: Removed a glitched building shadow, to free the build space!");
	}

	return Plugin_Stop;
}