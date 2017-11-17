#define PREFIX "\x05[xG]"

stock void PrintMessage(int client, const char[] phrase) {
	PrintToChat(client, "%s %t.", PREFIX, phrase);
}

stock void PrintMessageEx(int client, const char[] phrase) {
	PrintToChat(client, "%t.", phrase);
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