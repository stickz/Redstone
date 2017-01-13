/* Natives */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_IsCommanderDeprioritised", Native_GetComDep);	
	return APLRes_Success;
}

public int Native_GetComDep(Handle plugin, int numParms)
{
	int client = GetNativeCell(1);
	
	/* Get and trim the client's steamid */
	char steamid[STEAMID_SIZE];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));	
	
	int found = g_SteamIDList.FindString(steamid);
	return found != STRING_NOT_FOUND;
}