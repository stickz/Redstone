#include <sourcemod>
#include <dhooks>
#include <sdkhooks>

#tryinclude <nd_structures>

#if !defined _nd_structures_included

    enum ND_Structures: {
        ND_Command_Bunker,
        ND_MG_Turret,
        ND_Transport_Gate,
        ND_Power_Plant,
        ND_Wireless_Repeater,
        ND_Relay_Tower,
        ND_Supply_Station,
        ND_Assembler,
        ND_Armory,
        ND_Artillery,
        ND_Radar_Station,
        ND_FT_Turret,
        ND_Sonic_Turret,
        ND_Rocket_Turret,
        ND_Wall,
        ND_Barrier,
        ND_StructCount
    }

#endif

#define PLUGIN_VERSION "1.1.3"

#define BUILD_PARAM_PLACEMENT 1
#define BUILD_PARAM_STRUCTURE 2
#define BUILD_PARAM_POSITION 3
#define BUILD_PARAM_ANGLES 4
#define BUILD_PARAM_ID 5

#define BUILD_EMERGENCY_ASSEMBLER_PARAM_PLACEMENT 1
#define BUILD_EMERGENCY_ASSEMBLER_PARAM_POSITION 2
#define BUILD_EMERGENCY_ASSEMBLER_PARAM_ANGLES 3
#define BUILD_EMERGENCY_ASSEMBLER_PARAM_ID 4

public Plugin myinfo =
{
    name = "[ND] Intercept Structure Build",
    author = "databomb",
    description = "Intercepts and allows plugins to block or change structures before the build order is finalized",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/member.php?u=54648"
};


public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iMaxError)
{
    RegPluginLibrary("nd_structure_intercept");
    return APLRes_Success;
}

Handle gH_Frwd_OnCommanderBuildStructure = INVALID_HANDLE;

public void OnPluginStart()
{
    GameData hGameData = new GameData("build-structure.games");
    if (!hGameData)
    {
        SetFailState("Failed to find gamedata/build-structure.games.txt");
    }

    DynamicDetour detourPlayerBuildStructure = DynamicDetour.FromConf(hGameData, "CNDPlayer::Commander_BuildStructure");
    if (!detourPlayerBuildStructure)
    {
        SetFailState("Failed to find signature CNDPlayer::Commander_BuildStructure");
    }
    detourPlayerBuildStructure.Enable(Hook_Pre, Detour_PlayerBuildStructure);
    delete detourPlayerBuildStructure;

    DynamicDetour detourPlayerBuildEmergencyAssembler = DynamicDetour.FromConf(hGameData, "CNDPlayer::Commander_BuildEmergencyAssembler");
    if (!detourPlayerBuildEmergencyAssembler)
    {
        SetFailState("Failed to find signature CNDPlayer::Commander_BuildEmergencyAssembler");
    }
    detourPlayerBuildEmergencyAssembler.Enable(Hook_Pre, Detour_PlayerBuildEmergencyAssembler);
    delete detourPlayerBuildEmergencyAssembler;

    gH_Frwd_OnCommanderBuildStructure = CreateGlobalForward("ND_OnCommanderBuildStructure", ET_Hook, Param_Cell, Param_CellByRef, Param_Array);
}

MRESReturn Detour_PlayerBuildStructure(int iClient, DHookParam hParams)
{
    ND_Structures eStructure = DHookGetParam(hParams, BUILD_PARAM_STRUCTURE);
    float fOrigin[3];
    DHookGetParamVector(hParams, BUILD_PARAM_POSITION, fOrigin);
    float fAngles[3];
    DHookGetParamVector(hParams, BUILD_PARAM_ANGLES, fAngles);
    int iID = DHookGetParam(hParams, BUILD_PARAM_ID);

    // receive feedback from other plugins
    Action aBuildStructure;
    Call_StartForward(gH_Frwd_OnCommanderBuildStructure);
    Call_PushCell(iClient);
    Call_PushCellRef(eStructure);
    Call_PushArrayEx(fOrigin, sizeof(fOrigin), SM_PARAM_COPYBACK);
    Call_Finish(aBuildStructure);

    switch (aBuildStructure)
    {
        case Plugin_Stop:
        {
            UTIL_SendBuildingFailed(iClient, iID);
            return MRES_Supercede;
        }
        case Plugin_Changed:
        {
            DHookSetParam(hParams, BUILD_PARAM_STRUCTURE, eStructure);
            DHookSetParamVector(hParams, BUILD_PARAM_POSITION, fOrigin);
            DHookSetParamVector(hParams, BUILD_PARAM_ANGLES, fAngles);
            return MRES_ChangedHandled;
        }
        case Plugin_Handled:
        {
            return MRES_Handled;
        }
    }

    // aBuildStructure = Plugin_Continue
    return MRES_Ignored;
}

MRESReturn Detour_PlayerBuildEmergencyAssembler(int iClient, DHookParam hParams)
{
    ND_Structures eStructure = ND_Assembler;
    float fOrigin[3];
    DHookGetParamVector(hParams, BUILD_EMERGENCY_ASSEMBLER_PARAM_POSITION, fOrigin);
    float fAngles[3];
    DHookGetParamVector(hParams, BUILD_EMERGENCY_ASSEMBLER_PARAM_ANGLES, fAngles);
    int iID = DHookGetParam(hParams, BUILD_EMERGENCY_ASSEMBLER_PARAM_ID);

    // receive feedback from other plugins
    Action aBuildStructure;
    Call_StartForward(gH_Frwd_OnCommanderBuildStructure);
    Call_PushCell(iClient);
    Call_PushCellRef(eStructure);
    Call_PushArrayEx(fOrigin, sizeof(fOrigin), SM_PARAM_COPYBACK);
    Call_Finish(aBuildStructure);

    switch (aBuildStructure)
    {
        case Plugin_Stop:
        {
            UTIL_SendBuildingFailed(iClient, iID);
            return MRES_Supercede;
        }
        case Plugin_Changed:
        {
            if (eStructure != ND_Assembler)
            {
                LogError("Cannot change emergency assembler build structure to non-assembler structure type.");
                return MRES_Ignored;
            }
            DHookSetParamVector(hParams, BUILD_EMERGENCY_ASSEMBLER_PARAM_ANGLES, fAngles);
            DHookSetParamVector(hParams, BUILD_EMERGENCY_ASSEMBLER_PARAM_POSITION, fOrigin);
            return MRES_ChangedHandled;
        }
        case Plugin_Handled:
        {
            return MRES_Handled;
        }
    }

    // aBuildStructure = Plugin_Continue
    return MRES_Ignored;
}

// This helper function will gracefully cancel the building and remove the yellow structure outline
void UTIL_SendBuildingFailed(int iClient, int iID)
{
    Handle hBfBuildFailed;
    hBfBuildFailed = StartMessageOne("BuildingFailed", iClient, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);
    BfWriteShort(hBfBuildFailed, iID);
    EndMessage();
}
