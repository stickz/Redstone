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

	PrintToChat(client, "%s %s%s: %s%s",	NDPC_GetTransTag(client),
						NAME_COLOUR, pName, 
						MESSAGE_COLOUR, sArgs);
}

/* Convert no translation keyword phrases found to string, then print using colors wrapper */
void NDPC_PrintNoTransFound(int client)
{
	char noKeyword[32];
	Format(noKeyword, sizeof(noKeyword), "%T", client, "No Translate Keyword");	
	
	//First segment is (Translator) in green. Second is "No keyword found" in olive
	PrintToChat(client, "%s %s%s.", NDPC_GetTransTag(client), MESSAGE_COLOUR, noKeyword);
}

/* Convert translator tag phrase to string and colour it */
char NDPC_GetTransTag(int client)
{
	char final[64];
	StrCat(final, sizeof(final), TAG_COLOUR);
		
	char transTag[32];
	Format(transTag, sizeof(transTag), "%T", client, "Translate Tag");
	StrCat(final, sizeof(final), transTag);
	
	return final;
}
