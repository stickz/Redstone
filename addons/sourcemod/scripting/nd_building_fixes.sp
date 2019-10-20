#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <nd_rounds>
#include <nd_struct_eng>
#include <nd_stocks>

//Version is auto-filled by the travis builder
public Plugin myinfo = 
{
	name 		= "[ND] Buildings Fixes",
	author 		= "stickz",
    description	= "Prevent building walls inside relays/repeaters",
    version 	= "recompile",
	url 		= "https://github.com/stickz/Redstone/"
}

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_building_fixes/nd_building_fixes.txt"
#include "updater/standard.sp"

#define DISTANCE_INSIDE_RELAY 60

public void OnPluginStart() {
	AddUpdaterLibrary(); //auto-updater	
}

public void ND_OnStructureCreated(int entity, const char[] classname)
{	
	if (!ND_RoundStarted())
		return;
	
	if (ND_IsStructRelay(classname)) {
		CreateTimer(0.1, CheckRelay, entity);		
	}
	else if (StrEqual(classname, STRUCT_WALL, true)) {
		CreateTimer(0.1, CheckWall, entity);
	}		
}

public Action CheckRelay(Handle timer, any entity) 
{
	if (!IsValidEdict(entity))
    	return Plugin_Handled;	
	
	CheckRelayInsideWall(entity);
	return Plugin_Handled;
}

public Action CheckWall(Handle timer, any entity) 
{
	if (!IsValidEdict(entity))
    	return Plugin_Handled;	
	
	CheckWallInsideRelay(entity);
	return Plugin_Handled;
}

stock void ShowDebugInfo(int entity)
{
	float pos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", pos);
	
	int team = GetEntProp(entity, Prop_Send, "m_iTeamNum");
	
	char className[64];
	GetEntityClassname(entity, className, sizeof(className));
	
	PrintToChatAll("Structure: %s, Team: %d", className, team);
	PrintToChatAll("Structure Cords: %f, %f, %f", pos[0], pos[1], pos[2]);	
}

void CheckRelayInsideWall(int entity)
{
	// Get the team the relay tower or wireless repeater belongs to
	int relayTeam = GetEntProp(entity, Prop_Send, "m_iTeamNum");	
	
	// Get the position of the relay tower or wireless repeater
	float relayPos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", relayPos);
	
	int wallEntity = INVALID_ENT_REFERENCE;
	while ((wallEntity = FindEntityByClassname(wallEntity, STRUCT_WALL)) != INVALID_ENT_REFERENCE) 
	{
		// Get the team of the entity from the wall index
		// If the wall belongs to the same team as the relay
		int wallTeam = GetEntProp(wallEntity, Prop_Send, "m_iTeamNum");		
		if (wallTeam == relayTeam)
		{
			// Get the position of the wall
			float wallPos[3];
			GetEntPropVector(wallEntity, Prop_Data, "m_vecOrigin", wallPos);
			
			// Compare it to the relay tower. Get the vector distance apart.
			int distance = RoundFloat(GetVectorDistance(relayPos, wallPos));
			if (distance <= DISTANCE_INSIDE_RELAY)
			{
				PrintToChatAll("\x05[xG] Wall built inside relay destoryed!");
				SDKHooks_TakeDamage(wallEntity, 0, 0, 10000.0);
				break; // Exit the loop becuase we just destoryed the wall
			}
		}
	}	
}

void CheckWallInsideRelay(int entity)
{
	// Get the team the wall belongs to
	int wallTeam = GetEntProp(entity, Prop_Send, "m_iTeamNum");
	
	// Get the position of the wall
	float wallPos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", wallPos);
	
	// Get the name of the relay tower (wireless repeater or relay tower)
	char relayName[32];
	Format(relayName, sizeof(relayName), "%s", GetRelayTowerName(wallTeam));
	
	int relayEntity = INVALID_ENT_REFERENCE;
	while ((relayEntity = FindEntityByClassname(relayEntity, relayName)) != INVALID_ENT_REFERENCE) 
	{
		// Get the team of the entity from the relay index
		// If the wall belongs to the same team as the relay
		int relayTeam = GetEntProp(relayEntity, Prop_Send, "m_iTeamNum");		
		if (wallTeam == relayTeam)
		{
			// Get the position of the relay tower or wireless repeater
			float relayPos[3];
			GetEntPropVector(relayEntity, Prop_Data, "m_vecOrigin", relayPos);
			
			// Compare it to the wall. Get the vector distance apart.
			int distance = RoundFloat(GetVectorDistance(relayPos, wallPos));
			if (distance <= DISTANCE_INSIDE_RELAY)
			{
				PrintToChatAll("\x05[xG] Wall built inside relay destoryed!");
				SDKHooks_TakeDamage(entity, 0, 0, 10000.0);
				break; // Exit the loop becuase we just destoryed the wall
			}
		}		
	}
}
