#if _eNATIVES
/* Natives */
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("GameME_GetClientSkill", Native_GameME_GetClientSkill);
	CreateNative("GameME_GetClientRank", Native_GameME_GetClientRank);
	CreateNative("GameME_GetClientKills", Native_GameME_GetClientKills);
	CreateNative("GameME_GetClientDeaths", Native_GameME_GetClientDeaths);
	CreateNative("GameME_GetClientHeadshots", Native_GameME_GetClientHeadshots);
	CreateNative("GameME_GetClientKDR", Native_GameME_GetClientKDR);
	CreateNative("GameME_GetClientHPK", Native_GameMe_GetClientHPK)
	return APLRes_Success;
}

public Native_GameME_GetClientSkill(Handle plugin, int numParams) {
	return playerInt[pSkill][GetNativeCell(1)];
}

public Native_GameME_GetClientRank(Handle plugin, int numParams) {	
	return playerInt[pRank][GetNativeCell(1)];
}

public Native_GameME_GetClientKills(Handle plugin, int numParams) {	
	return playerInt[pKills][GetNativeCell(1)];
}

public Native_GameME_GetClientDeaths(Handle plugin, int numParams) {	
	return playerInt[pDeaths][GetNativeCell(1)];
}

public Native_GameME_GetClientHeadshots(Handle plugin, int numParams) {	
	return playerInt[pHeadshots][GetNativeCell(1)];
}

public Native_GameMe_GetClientHPK(Handle plugin, int numParams) {
	return _:playerFloat[pHPK][GetNativeCell(1)];
}

public Native_GameME_GetClientKDR(Handle plugin, int numParams) {
	return _:playerFloat[pKDR][GetNativeCell(1)];
}
#endif