#define STRING_STARTS_WITH 	0
#define IS_WITHIN_STRING	-1

stock bool:StrStartsWith(const String:sArgs[], const String:segment[])
{
	return STRING_STARTS_WITH == StrContains(sArgs, segment, false);
}

stock bool:StrIsWithin(const String:sArgs[], const String:segment[])
{
	return StrContains(sArgs, segment, false) > IS_WITHIN_STRING;
}

stock bool:IsOnTeam(client, team)
{
	return IsValidClient(client) && GetClientTeam(client) == team;
}

stock ND_GetCommanderOn(team)
{
	return GameRules_GetPropEnt("m_hCommanders", team - 2);
}

stock ND_GetCommanderBy(client)
{
	return GameRules_GetPropEnt("m_hCommanders", GetClientTeam(client) - 2);
}
