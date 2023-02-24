#include <sourcemod>
#include <nd_commander_build>
#include <nd_entities>
#include <nd_structures>

#define PLUGIN_VERSION "1.0.0"

public Plugin myinfo =
{
    name = "[ND] Save Base Spawn",
    author = "databomb",
    description = "Prevents selling of all base spawns (transport gates powered by the Command Bunker)",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/member.php?u=54648"
};

#define COMMAND_BUNKER_POWERED_DISTANCE     1250.0

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_save_basespawn/nd_save_basespawn.txt"
#include "updater/standard.sp"

public void OnPluginStart()
{
    AddUpdaterLibrary(); //auto-updater
}

public void OnAllPluginsLoaded()
{
    if (!LibraryExists("nd_structure_intercept"))
    {
        SetFailState("Structure sell detour not available. Check gamedata.");
    }

    RequireFeature(FeatureType_Native, "ND_GetTeamBunkerEntity", "Native ND_GetTeamBunkerEntity not found. Exiting.");
}

public Action ND_OnCommanderSellStructure(int iPlayer, int iEntity)
{
    // check if commander is trying to sell a spawn
    char sEntityName[32];
    GetEdictClassname(iEntity, sEntityName, sizeof(sEntityName));
    if (StrEqual(sEntityName, STRUCT_TRANSPORT))
    {
        // check if this spawn is powered by the Command Bunker of the player
        int iTeam = GetClientTeam(iPlayer);
        float fStructurePosition[3];
        GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fStructurePosition);
        float fDistanceFromBunker = ND_GetBunkerDistance(iTeam, fStructurePosition);

        if (fDistanceFromBunker <= COMMAND_BUNKER_POWERED_DISTANCE)
        {
            // check the total number of spawns remaining powered by the command bunker
            if (ND_GetBaseTransportCount(iTeam) <= 1)
            {
                UTIL_Commander_FailureText(iPlayer, "CANNOT SELL LAST BASE SPAWN.");
                LogMessage("%N attempted to sell the last base spawn.", iPlayer);
                return Plugin_Stop;
            }
        }
    }

    return Plugin_Continue;
}

stock int ND_GetBaseTransportCount(int iBaseTeam)
{
    int iBaseSpawns = 0;
    int iLoopIndex = INVALID_ENT_REFERENCE;

    while ((iLoopIndex = FindEntityByClassname(iLoopIndex, STRUCT_TRANSPORT)) != INVALID_ENT_REFERENCE)
    {
        int iEntityTeam = GetEntProp(iLoopIndex, Prop_Send, "m_iTeamNum");
        if (iEntityTeam == iBaseTeam)
        {
            // check if powered by the bunker
            float fStructurePosition[3];
            GetEntPropVector(iLoopIndex, Prop_Send, "m_vecOrigin", fStructurePosition);
            float fDistanceFromBunker = ND_GetBunkerDistance(iBaseTeam, fStructurePosition);

            if (fDistanceFromBunker <= COMMAND_BUNKER_POWERED_DISTANCE)
            {
                iBaseSpawns++;
            }
        }
    }

    return iBaseSpawns;
}
