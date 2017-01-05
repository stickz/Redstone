/* Natives */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_GetSkillFloor", Native_GetPlayerFloor);	
	return APLRes_Success;
}

public int Native_GetPlayerFloor(Handle plugin, int numParms)
{
	int client = GetNativeCell(1);
	
	/* Get and trim the client's steamid */
	char steamid[STEAMID_SIZE];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));	
	
	int found = g_SteamIDList.FindString(steamid);
	if (found == STRING_NOT_FOUND)
		return STRING_NOT_FOUND;
	
	return g_PlayerSkillFloors.Get(found);
}