#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <nd_rounds>
#include <nd_struct_eng>
#include <nd_stocks>
#include <nd_structures>
#include <nd_commander_build>

//Version is auto-filled by the travis builder
public Plugin myinfo =
{
    name        = "[ND] Buildings Fixes",
    author      = "stickz, databomb",
    description = "Prevent building walls inside relays/repeaters",
    version     = "dummy",
    url         = "https://github.com/stickz/Redstone/"
}

char g_sPowerStructErrorMessage[2][64] = {"CANNOT BUILD TOO NEAR WIRELESS REPEATER.", "CANNOT BUILD TOO NEAR RELAY TOWER."};

// Check for dependency on nd_structure_intercept
public void OnAllPluginsLoaded()
{
    if (!LibraryExists("nd_structure_intercept"))
    {
        SetFailState("Failed to find plugin dependency nd_structure_intercept");
    }
}

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_building_fixes/nd_building_fixes.txt"
#include "updater/standard.sp"

#define DISTANCE_INSIDE_RELAY 60

public void OnPluginStart()
{
    AddUpdaterLibrary(); //auto-updater
}

public Action ND_OnCommanderBuildStructure(int client, ND_Structures &structure, float position[3])
{
    if (!ND_RoundStarted())
        return Plugin_Continue;

    if (structure == ND_Relay_Tower || structure == ND_Wireless_Repeater)
    {
        // Get the team the relay tower or wireless repeater belongs to
        int relayTeam = GetClientTeam(client);

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
                int distance = RoundFloat(GetVectorDistance(position, wallPos));
                if (distance <= DISTANCE_INSIDE_RELAY)
                {
                    UTIL_Commander_FailureText(client, "CANNOT BUILD TOO NEAR WALL.");
                    return Plugin_Stop;
                }
            }
        }
    }
    else if (structure == ND_Wall)
    {
        // Get the team the wall belongs to
        int wallTeam = GetClientTeam(client);

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
                int distance = RoundFloat(GetVectorDistance(relayPos, position));
                if (distance <= DISTANCE_INSIDE_RELAY)
                {
                    UTIL_Commander_FailureText(client, g_sPowerStructErrorMessage[wallTeam-2]);
                    return Plugin_Stop;
                }
            }
        }
    }

    return Plugin_Continue;
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
