#define STRING_STARTS_WITH 	0
#define IS_WITHIN_STRING	-1
#define NO_COMMANDER		-1

stock bool StrStartsWith(const char[] sArgs, const char[] segment)
{
	return STRING_STARTS_WITH == StrContains(sArgs, segment, false);
}

stock bool StrIsWithin(const char[] sArgs, const char[] segment)
{
	return StrContains(sArgs, segment, false) > IS_WITHIN_STRING;
}

stool bool StrIsWithinArray(const char[] sArgs, const char[][] bArray)
{
	int arraySize = sizeof(bArray);
	
	if (arraySize == 0)
		return false;
	
	for (int building = 0; building < arraySize; building++)
	{
		if (StrContains(sArgs, bArray[building], false) > IS_WITHIN_STRING)
			return true;	
	}
	
	return false;
}

stock bool IsOnTeam(int client, int team)
{
	return IsValidClient(client) && GetClientTeam(client) == team;
}
