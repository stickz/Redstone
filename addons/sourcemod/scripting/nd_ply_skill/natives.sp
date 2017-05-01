/* Natives */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_GetPlayerSkill", Native_GetPlayerSkill);
	CreateNative("ND_GetCommanderSkill", Native_GetComSkill);
	CreateNative("ND_GetPlayerLevel", Native_GetPlayerLevel);
	CreateNative("ND_GetSkillAverage", Native_GetSkillAverage);
	CreateNative("ND_GetTeamSkillAverage", Native_GetTeamSkillAverage);
	CreateNative("ND_GetTeamDifference", Native_GetTeamDifference);
	CreateNative("ND_GetSkillMedian", Native_GetSkillMedian);
	CreateNative("ND_GetEnhancedAverage", Native_GetEnhancedAverage);
	
	MarkNativeAsOptional("GameME_GetFinalSkill");
	return APLRes_Success;
}

public Native_GetPlayerSkill(Handle plugin, int numParms) {
	UpdateSkillAverage();
	return _:GetSkillLevel(GetNativeCell(1)); //native cell = client
}

public Native_GetComSkill(Handle plugin, int numParms) {
	return _:GetCommanderSkill(GetNativeCell(1));
}

public Native_GetPlayerLevel(Handle plugin, int numParms) {
	return _:getClientLevel(GetNativeCell(1)); //native cell = client
}

public Native_GetSkillAverage(Handle plugin, int numParms) {
	UpdateSkillAverage();
	return _:lastAverage;
}

public Native_GetTeamSkillAverage(Handle plugin, int numParms) {
	int team = GetNativeCell(1);
	return _:GetTeamSkillAverage(team);
}

public Native_GetTeamDifference(Handle plugin, int numParms) {
	return _:GetTeamDifference();
}

public Native_GetSkillMedian(Handle plugin, int numParms) {
	UpdateSkillMedian();
	return _:lastMedian;
}

public Native_GetEnhancedAverage(Handle plugin, int numParms) {
	UpdateSkillAverage();
	UpdateSkillMedian();
	
	float value = (lastAverage * 0.7) + (lastMedian * 0.3);
	return _:value;
}