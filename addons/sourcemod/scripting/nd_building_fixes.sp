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
        LogError("Structure detour not available. Reverting to ND_OnStructureCreated. Check gamedata.");
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

        if (IsBuildingTooClose(relayTeam, ND_Wall, position))
        {
            char notice[64];
            FormatFailureNotice(notice, sizeof(notice), ND_Wall);
            UTIL_Commander_FailureText(client, notice);
            return Plugin_Stop;
        }
    }
    
    else if (structure == ND_Wall)
    {
        // Get the team the wall belongs to
        int wallTeam = GetClientTeam(client);
        ND_Structures teamRelayStruct = wallTeam == TEAM_CONSORT ? ND_Wireless_Repeater : ND_Relay_Tower;

        if (IsBuildingTooClose(wallTeam, teamRelayStruct, position))
        {
            char notice[64];
            FormatFailureNotice(notice, sizeof(notice), teamRelayStruct);
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

    if (IsBuildingTooClose(team, ND_Wall, position))
    {
        int client = GameRules_GetPropEnt("m_hCommanders", team-2);
        if (client && IsClientInGame(client))
        {
            char notice[64];
            FormatFailureNotice(notice, sizeof(notice), ND_Wall);
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
    
    ND_Structures structure = team == TEAM_CONSORT ? ND_Wireless_Repeater : ND_Relay_Tower;
    if (IsBuildingTooClose(team, structure, position))
    {
        int client = GameRules_GetPropEnt("m_hCommanders", team-2);
        if (client && IsClientInGame(client))
        {
            char notice[64];
            FormatFailureNotice(notice, sizeof(notice), structure);
            UTIL_Commander_FailureText(client, notice);
        }

        SDKHooks_TakeDamage(entity, 0, 0, 10000.0);
    }

    return Plugin_Handled;
}

void FormatFailureNotice(char[] string, int size, ND_Structures structure)
{
    Format(string, size, "%s %s.", NOTE_PREFIX, GetStructureDisplayName(structure, true));
}

bool IsBuildingTooClose(int team, ND_Structures structure, float position[3])
{
    ArrayList buildings;
    ND_GetBuildInfoArrayTypeTeam(buildings, view_as<int>(structure), team);
    
    for (int i = 0; i < buildings.Length; i++)
    {
        BuildingEntity ent;
        buildings.GetArray(i, ent);

        if (IsBuildingInsideRelay(position, ent.vecPos))
        {
            return true;
        }
    }

    return false;
}

bool IsBuildingInsideRelay(float first[3], float second[3])
{
    return RoundFloat(GetVectorDistance(first, second)) <= DISTANCE_INSIDE_RELAY;
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
