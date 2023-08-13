#include <sourcemod>
#include <nd_commander_build>
#include <nd_entities>
#include <nd_struct_eng>

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
    int entType; float entPos[3]; char entClass[32];
    ND_GetBuildingInfo(iEntity, entType, entPos, entClass);

    // check if commander is trying to sell a spawn
    if (entType == view_as<int>(ND_Transport_Gate))
    {
        // check if this spawn is powered by the Command Bunker of the player
        int iTeam = GetClientTeam(iPlayer);
        float fDistanceFromBunker = ND_GetBunkerDistance(iTeam, entPos);

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
    
    ArrayList buildings;
    ND_GetBuildInfoArrayTypeTeam(buildings, view_as<int>(ND_Transport_Gate), iBaseTeam);
    
    for (int i = 0; i < buildings.Length; i++)
    {
        BuildingEntity ent;
        buildings.GetArray(i, ent);
        float fDistanceFromBunker = ND_GetBunkerDistance(iBaseTeam, ent.vecPos);
        if (fDistanceFromBunker <= COMMAND_BUNKER_POWERED_DISTANCE)
        {
            iBaseSpawns++;
        }
    }

    return iBaseSpawns;
}
