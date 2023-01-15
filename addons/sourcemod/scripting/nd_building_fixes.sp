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

#define NOTE_PREFIX "CANNOT BUILD TOO NEAR"

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_building_fixes/nd_building_fixes.txt"
#include "updater/standard.sp"

#define DISTANCE_INSIDE_RELAY 60

// Check for nd_structure_intercept being available
bool g_bStructureDetourAvailable = true;
public void OnAllPluginsLoaded()
{
    g_bStructureDetourAvailable = LibraryExists("nd_structure_intercept");
    if (!g_bStructureDetourAvailable)
    {
        LogError("Problem was found and automatically reverting to ND_OnStructureCreated. Check gamedata.");
    }
}

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

        if (IsPowerTooCloseToWall(relayTeam, position))
        {
            char notice[64];
            Format(notice, sizeof(notice), "%s %s.", \
                NOTE_PREFIX, \
                GetStructureDisplayName(ND_Wall, true));
            UTIL_Commander_FailureText(client, notice);
            return Plugin_Stop;
        }
    }
    else if (structure == ND_Wall)
    {
        // Get the team the wall belongs to
        int wallTeam = GetClientTeam(client);

        if (IsWallTooCloseToPower(wallTeam, position))
        {
            char notice[64];
            Format(notice, sizeof(notice), "%s %s.", \
                NOTE_PREFIX, \
                GetStructureDisplayName(wallTeam == TEAM_CONSORT ? ND_Wireless_Repeater : ND_Relay_Tower, true));
            UTIL_Commander_FailureText(client, notice);
            return Plugin_Stop;
        }
    }

    return Plugin_Continue;
}
public void ND_OnStructureCreated(int entity, const char[] classname)
{
    if (!g_bStructureDetourAvailable && ND_RoundStarted())
    {
        int entref = EntIndexToEntRef(entity);
        if (ND_IsStructRelay(classname))
        {
            CreateTimer(0.1, Timer_CheckRelay, entref, TIMER_FLAG_NO_MAPCHANGE);
        }
        else if (StrEqual(classname, STRUCT_WALL, true))
        {
            CreateTimer(0.1, Timer_CheckWall, entref, TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public Action Timer_CheckRelay(Handle timer, any entref)
{
    int entity = EntRefToEntIndex(entref);
    if (entity == INVALID_ENT_REFERENCE || !IsValidEdict(entity))
    {
        return Plugin_Handled;
    }

    // Get the team the structure belongs to
    int team = GetEntProp(entity, Prop_Send, "m_iTeamNum");

    // Get the position of the structure
    float position[3];
    GetEntPropVector(entity, Prop_Data, "m_vecOrigin", position);

    if (IsPowerTooCloseToWall(team, position))
    {
        int client = GameRules_GetPropEnt("m_hCommanders", team-2);
        if (client && IsClientInGame(client))
        {
            char notice[64];
            Format(notice, sizeof(notice), "%s %s.", \
                NOTE_PREFIX, \
                GetStructureDisplayName(ND_Wall, true));
            UTIL_Commander_FailureText(client, notice);
        }

        SDKHooks_TakeDamage(entity, 0, 0, 10000.0);
    }

    return Plugin_Handled;
}

public Action Timer_CheckWall(Handle timer, any entref)
{
    int entity = EntRefToEntIndex(entref);
    if (entity == INVALID_ENT_REFERENCE || !IsValidEdict(entity))
    {
        return Plugin_Handled;
    }

    // Get the team the structure belongs to
    int team = GetEntProp(entity, Prop_Send, "m_iTeamNum");

    // Get the position of the structure
    float position[3];
    GetEntPropVector(entity, Prop_Data, "m_vecOrigin", position);

    if (IsWallTooCloseToPower(team, position))
    {
        int client = GameRules_GetPropEnt("m_hCommanders", team-2);
        if (client && IsClientInGame(client))
        {
            char notice[64];
            Format(notice, sizeof(notice), "%s %s.", \
                NOTE_PREFIX, \
                GetStructureDisplayName(team == TEAM_CONSORT ? ND_Wireless_Repeater : ND_Relay_Tower, true));
            UTIL_Commander_FailureText(client, notice);
        }

        SDKHooks_TakeDamage(entity, 0, 0, 10000.0);
    }

    return Plugin_Handled;
}

bool IsPowerTooCloseToWall(int team, float position[3])
{
    int wallEntity = INVALID_ENT_REFERENCE;
    while ((wallEntity = FindEntityByClassname(wallEntity, STRUCT_WALL)) != INVALID_ENT_REFERENCE)
    {
        // Get the team of the entity from the wall index
        // If the wall belongs to the same team as the relay
        int wallTeam = GetEntProp(wallEntity, Prop_Send, "m_iTeamNum");
        if (wallTeam == team)
        {
            // Get the position of the wall
            float wallPos[3];
            GetEntPropVector(wallEntity, Prop_Data, "m_vecOrigin", wallPos);

            // Compare it to the relay tower. Get the vector distance apart.
            int distance = RoundFloat(GetVectorDistance(position, wallPos));
            if (distance <= DISTANCE_INSIDE_RELAY)
            {
                return true;
            }
        }
    }

    return false;
}

bool IsWallTooCloseToPower(int team, float position[3])
{
    // Get the name of the relay tower (wireless repeater or relay tower)
    char relayName[32];
    Format(relayName, sizeof(relayName), "%s", GetRelayTowerName(team));

    int relayEntity = INVALID_ENT_REFERENCE;
    while ((relayEntity = FindEntityByClassname(relayEntity, relayName)) != INVALID_ENT_REFERENCE)
    {
        // Get the team of the entity from the relay index
        // If the wall belongs to the same team as the relay
        int relayTeam = GetEntProp(relayEntity, Prop_Send, "m_iTeamNum");
        if (team == relayTeam)
        {
            // Get the position of the relay tower or wireless repeater
            float relayPos[3];
            GetEntPropVector(relayEntity, Prop_Data, "m_vecOrigin", relayPos);

            // Compare it to the wall. Get the vector distance apart.
            int distance = RoundFloat(GetVectorDistance(relayPos, position));
            if (distance <= DISTANCE_INSIDE_RELAY)
            {
                return true;
            }
        }
    }

    return false;
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
