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
void NPDC_PrintToChat(int client, const char[] sArgs)
{
	PrintToChat(client, "%s%t %s%s", TAG_COLOUR, "Translate Tag", MESSAGE_COLOUR, sArgs);
}