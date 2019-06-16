#if defined _nd_print_included_
  #endinput
#endif
#define _nd_print_included_

#define PREFIX "\x05[xG]"
#define PREFIX_TB "\x05[TB]"
#define COLOUR "\x05"

stock void PrintMessage(int client, const char[] phrase) {
	PrintToChat(client, "%s %t.", PREFIX, phrase);
}
stock void PrintMessageTI1(int client, const char[] phrase, int intArg) {
	PrintToChat(client, "%s%t.", PREFIX, phrase, intArg);
}
stock void PrintMessageTB(int client, const char[] phrase) {
	PrintToChat(client, "%s %t.", PREFIX_TB, phrase);
}

stock void PrintMessageEx(int client, const char[] phrase) {
	PrintToChat(client, "%s%t.", COLOUR, phrase);
}
stock void PrintMessageExTI1(int client, const char[] phrase, int intArg) {
	PrintToChat(client, "%s%t.", COLOUR, phrase, intArg);
}

stock void PrintMessageCom(int client, const char[] phrase) {
	if (client != -1) {
		PrintMessage(client, phrase);
	}
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

stock void PrintMessageAllTB(const char[] phrase) 
{
	for (int client = 1; client <= MaxClients; client++) 
	{
		if (IsClientInGame(client))
		{	
			PrintMessageTB(client, phrase);
		}
	}
}

stock void PrintMessageAllTS1(char[] transString, char[] stringArg) 
{
	for (int client = 1; client <= MaxClients; client++) 
	{
		if (IsClientInGame(client))
		{	
			PrintToChat(client, "%s %t!", PREFIX, transString, stringArg);	
		}
	}
}

stock void PrintMessageAllTB_TS1(char[] transString, char[] stringArg) 
{
	for (int client = 1; client <= MaxClients; client++) 
	{
		if (IsClientInGame(client))
		{	
			PrintToChat(client, "%s %t!", PREFIX_TB, transString, stringArg);	
		}
	}
}

stock void PrintMessageTeamTS1(int team, char[] transString, char[] stringArg)
{
	for (int client = 1; client <= MaxClients; client++) 
	{
		if (IsClientInGame(client) && GetClientTeam(client) == team)
		{
			PrintToChat(client, "%s %t!", PREFIX, transString, stringArg);
		}
	}
}

stock void PrintMessageAllTI1(char[] transString, int intArg) 
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			PrintToChat(client, "%s %t!", PREFIX, transString, intArg);
		}
	}	
}

stock void PrintMessageTeamTI1(int team, char[] transString, int intArg)
{
	for (int client = 1; client <= MaxClients; client++) 
	{
		if (IsClientInGame(client) && GetClientTeam(client) == team)
		{
			PrintToChat(client, "%s %t!", PREFIX, transString, intArg);
		}
	}
}

stock void PrintConsoleTeamTI1(int team, char[] transString, int intArg)
{
	for (int client = 1; client <= MaxClients; client++) 
	{
		if (IsClientInGame(client) && GetClientTeam(client) == team)
		{
			PrintToConsole(client, "%s %t!", PREFIX, transString, intArg);
		}
	}
}

// This function is an alais, to symbolize printing translations instead of strings
stock void PrintMessageTeamTT1(int team, char[] transString, char[] transArg) {
	PrintMessageTeamTS1(team, transString, transArg);
}
