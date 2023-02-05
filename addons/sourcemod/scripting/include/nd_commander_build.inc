#if defined _nd_commmander_build_included_
  #endinput
#endif

#define _nd_commmander_build_included_

/**
 * Allows a plugin to block a structure from being built by returning Plugin_Stop
 * or change the structure and/or position by returning Plugin_Changed.
 *
 * @param int client                     client index of the commander who attempted to build the structure
 * @param ND_Structures structure        type of structure being built
 * @param float position[3]              x,y,z coordinate of where structure is being built
 * @return                               Action that should be taken (Plugin_Stop to prevent building)
 */
forward Action ND_OnCommanderBuildStructure(int client, ND_Structures &structure, float position[3]);

/**
 * Allows a plugin to block a structure from being sold by returning Plugin_Stop.
 *
 * @param int client                     client index of the commander who attempted to build the structure
 * @param int entity                     entity index of the structure that is trying to be sold
 * @return                               Action that should be taken (Plugin_Stop to prevent sale)
 */
forward Action ND_OnCommanderSellStructure(int client, int entity)

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
