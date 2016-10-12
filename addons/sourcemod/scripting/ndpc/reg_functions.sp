int GetStringSpaceCount(const char[] sArgs)
{
	int spaceCount = 0;
	
	for (int idx = 0; idx < strlen(sArgs); idx++)
	{
		if (IsCharSpace(sArgs[idx]))
			spaceCount++;
	}
	
	return spaceCount;
}

/* Wrapper for printing a translation to client chat */
void NDPC_PrintToChat(int client, int team, const char[] sArgs)
{
	char pName[64];
	GetClientName(client, pName, sizeof(pName));
	
	char transTag[32];
	Format(transTag, sizeof(transTag), "%T", client, "Translate Tag");
	
	CPrintToChat(client, "%s%s %s%s: %s%s", TAG_COLOUR, transTag, 
						tColour[team - 2], pName,
						MESSAGE_COLOUR, sArgs);
}
