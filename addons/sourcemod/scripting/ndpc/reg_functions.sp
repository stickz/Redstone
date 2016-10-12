/* Get the space count in a given chat message (or string) */
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
	
	CPrintToChat(client, "%s%s %s%s: %s%s", TAG_COLOUR, NDPC_GetTransTag(client), 
						tColour[team - 2], pName,
						MESSAGE_COLOUR, sArgs);
}

/* Convert no translation keyword phrases found to string, then print using colors wrapper */
void NDPC_PrintNoTransFound(int client)
{
	char noKeyword[32];
	Format(noKeyword, sizeof(noKeyword), "%T", client, "No Translate Keyword");
	
	//First segment is (Translator) in green. Second is "No keyword found" in olive
	CPrintToChat(client, "%s%s %s%s.", TAG_COLOUR, NDPC_GetTransTag(client), MESSAGE_COLOUR, noKeyword);
}

/* Convert translator tag phrase to char array (string) */
char NDPC_GetTransTag(client)
{
	char transTag[32];
	Format(transTag, sizeof(transTag), "%T", client, "Translate Tag");	
	return transTag;
}
