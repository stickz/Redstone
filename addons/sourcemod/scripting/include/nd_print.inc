#define PREFIX "\x05[xG]"
#define COLOUR "\x05"

stock void PrintMessage(int client, const char[] phrase) {
	PrintToChat(client, "%s %t.", PREFIX, phrase);
}
stock void PrintMessageTI1(int client, const char[] phrase, int intArg) {
	PrintToChat(client, "%s%t.", PREFIX, phrase, intArg);
}

stock void PrintMessageEx(int client, const char[] phrase) {
	PrintToChat(client, "%s%t.", COLOUR, phrase);
}
stock void PrintMessageExTI1(int client, const char[] phrase, int intArg) {
	PrintToChat(client, "%s%t.", COLOUR, phrase, intArg);
}

stock void PrintMessageAll(const char[] phrase) 
{
	for (int client = 1; client <= MaxClients; client++) 
	{
		if (IsClientInGame(client))
		{
			PrintMessage(client, phrase);
		}
	}
}

stock void PrintMessageAllEx(const char[] phrase) 
{
	for (int client = 1; client <= MaxClients; client++) 
	{
		if (IsClientInGame(client))
		{	
			PrintMessageEx(client, phrase);
		}
	}
}

stock void PrintTMessageAll(char[] transString, any:argValue)
{
	for (int client = 1; client <= MaxClients; client++) 
	{
		if (IsClientInGame(client))
		{	
			PrintToChat(client, "%s %t!", PREFIX, transString, argValue);	
		}
	}
}

stock void PrintTMessageTeam(int team, char[] transString, any:argValue)
{
	for (int client = 1; client <= MaxClients; client++) 
	{
		if (IsClientInGame(client) && GetClientTeam(client) == team)
		{
			PrintToChat(client, "%s %t!", PREFIX, transString, argValue);
		}
	}
}

stock void PrintMessageAllTS1(char[] transString, char[] stringArg) {
	PrintTMessageAll(transString, stringArg);
}

stock void PrintMessageTeamTS1(int team, char[] transString, char[] stringArg) {
	PrintTMessageTeam(team, transString, stringArg);
}

stock void PrintMessageAllTI1(char[] transString, int intArg) {
	PrintTMessageAll(transString, intArg);	
}

stock void PrintMessageTeamTI1(int team, char[] transString, int intArg) {
	PrintTMessageTeam(team, transString, intArg);
}

// This function is an alais, to symbolize printing translations instead of strings
stock void PrintMessageTeamTT1(int team, char[] transString, char[] transArg) {
	PrintTMessageAll(transString, transArg);
}
