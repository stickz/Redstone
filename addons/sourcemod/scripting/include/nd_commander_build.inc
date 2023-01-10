#if defined _nd_commmander_build_included_
  #endinput
#endif

#define _nd_commmander_build_included_

enum eNDStructures
{
    eND_CommandBunker = 0,
    eND_MachineGunTurret,
    eND_TransportGate,
    eND_PowerStation,
    eND_WirelessRepeater,
    eND_RelayTower,
    eND_SupplyStation,
    eND_Assembler,
    eND_Armory,
    eND_Artillery,
    eND_RadarStation,
    eND_FlamethrowerTurret,
    eND_SonicTurret,
    eND_RocketTurret,
    eND_Wall,
    eND_Barrier
}

/**
 * Allows a plugin to block a structure form being built by returning Plugin_Stop
 * or change the structure and/or position by returning Plugin_Changed.
 *
 * @param int client                     client index of the commander who attempted to build the structure
 * @param eNDStructures structure        type of structure being built
 * @param float position[3]              x,y,z coordinate of where structure is being built
 * @return                               Action that should be taken (Plugin_Stop to prevent building)
 */
forward Action ND_OnCommanderBuildStructure(int client, eNDStructures &structure, float position[3]);

// This helper function will display red text and a failed sound to the commander
stock void UTIL_Commander_FailureText(int iClient, char sMessage[64])
{
    ClientCommand(iClient, "play buttons/button7");

    Handle hBfCommanderText;
    hBfCommanderText = StartMessageOne("CommanderNotice", iClient, USERMSG_BLOCKHOOKS);
    BfWriteString(hBfCommanderText, sMessage);
    EndMessage();

    // clear other messages from notice area
    hBfCommanderText = StartMessageOne("CommanderNotice", iClient, USERMSG_BLOCKHOOKS);
    BfWriteString(hBfCommanderText, "");
    EndMessage();
}
