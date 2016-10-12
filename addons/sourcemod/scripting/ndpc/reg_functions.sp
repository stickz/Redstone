/**
 * Wrapper for looping clients on team
 * matching the specified flags.
 *
 * @param 1		Name of index varriable (accessible inside the loop)
 * @param 2		Team varriable check if each client is on.
 */
#define LOOP_TEAM(%1,%2) for (int %1=Client_GetNext(%2); %1 >= 1 && %1 <= MaxClients; %1=Client_GetNext(%2, ++%1))	
int Client_GetNext(int team, int index = 1)
{
	for (int client = index; client <= MaxClients; client++) 
	{
		if (IsOnTeam(client, team)) 
		{
			return client;
		}
	}

	return -1;
}

#define PRINT_SIZE 128
#define PHRASE_SIZE 64

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

void NDPC_PrintRequest(int team, const char[] request, const char[] pName)
{
	LOOP_TEAM(idx, team) 
	{
		char ToPrint[128];
		Format(ToPrint, sizeof(ToPrint), "%T", request, idx);
		NDPC_PrintToChat(idx, pName, ToPrint);	
	}	
}

void NDPC_PrintRequestEx(int team, const char[] request, const char[] pName, char[][] args)
{
	int size = sizeof(args[]);	

	char transString[size][PHRASE_SIZE];
	char ToPrint[PRINT_SIZE];	
	
	LOOP_TEAM(idx, team) 
	{
		Format(transString, sizeof(transSize), GetTransString(client, args));
		
		// Reswitching for each client is bad, but it saves ALOT of duplication
		switch (size)
		{
			case 1:	Format(ToPrint, PRINT_SIZE, "%T", request, idx, transString[0]);						
			case 2:	Format(ToPrint, PRINT_SIZE, "%T", request, idx, transString[0], transString[1]);
			case 3:	Format(ToPrint, PRINT_SIZE, "%T", request, idx, transString[0], transString[1] ,transString[2]);
		}
				
		NDPC_PrintToChat(idx, pName, ToPrint);		
	}	
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

/* Translation Strings */
char GetTransString(int client, char[][] args)
{
	int size = sizeof(args[]);	
	
	char trans = new char[size][PHRASE_SIZE];	
	for (int idx = 0; idx < size; idx++) {
		Format(trans[idx], PHRASE_SIZE, "%T", args[idx], client);	
	}	

	return trans;
}
