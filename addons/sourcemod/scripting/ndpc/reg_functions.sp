/**
 * Wrapper for looping clients on team
 * matching the specified flags.
 *
 * @param 1		Name of index varriable (accessible inside the loop)
 * @param 2		Team varriable check if each client is on.
 */
#define LOOP_TEAM(%1, %2) for (int %1 = Client_GetNext(%2); %1 >= 1 && %1 <= MaxClients; %1=Client_GetNext(%2, ++%1))	
void Client_GetNext(int team, int index = 1)
{
	for (new client = index; client <= MaxClients; client++) 
	{
		if (IsOnTeam(client, team)) 
		{
			return client;
		}
	}

	return -1;
}

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
void NDPC_PrintToChat(int client, const char[] pName, const char[] sArgs)
{
	PrintToChat(client, "%s%t %s%s: %s%s",	TAG_COLOUR, "Translate Tag",
						NAME_COLOUR, pName, 
						MESSAGE_COLOUR, sArgs);
}

/* Convert no translation keyword phrases found to string, then print using colors wrapper */
void NDPC_PrintNoTransFound(int client)
{	
	//First segment is (Translator) in green. Second is "No keyword found" in olive
	PrintToChat(client, "%s%t %s%t.", TAG_COLOUR, "Translate Tag", MESSAGE_COLOUR, "No Translate Keyword");
}
