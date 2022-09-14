#define CLANG_PRINTOUT_SIZE 3

char nd_cl_commands[CLANG_PRINTOUT_SIZE][] = 
{
	"sm_comlang",
	"sm_commanderlang",
	"sm_commanderlanguage"
};

void RegComLangCommands()
{
	for (int p = 0; p < CLANG_PRINTOUT_SIZE; p++)
	{
		RegConsoleCmd(nd_cl_commands[p], CMD_PrintCLang);
	}
}

public Action CMD_PrintCLang(int client, int args)
{
	int team = GetClientTeam(client);
	if (team != TEAM_CONSORT && team != TEAM_EMPIRE)
	{
		PrintMessage(client, "On Team");
		return Plugin_Handled;	
	}
	
	int commander = ND_GetCommanderOnTeam(team);
	if (commander == NO_COMMANDER)
	{
		PrintMessage(client, "No Team Commander");
		return Plugin_Handled;
	}
	
	PrintToChat(client, "%s%t", MESSAGE_COLOUR, "Commander Language", GetLanguageName(commander));
	return Plugin_Handled;
}

public void ND_OnCommanderPromoted(int client, int team)
{
	if (g_Enable[CommanderLang].BoolValue) //only use feature if enabled
	{
		if (IsValidClient(client))
		{
			char langName[32];
			Format(langName, sizeof(langName), GetLanguageName(client));

			if (!StrEqual("english", langName, true))
				PrintCLangToTeam(team, langName);
		}
	}
}

void PrintCLangToTeam(int team, const char[] langName)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsOnTeam(client, team))
		{
			PrintToChat(client, "%s%t", MESSAGE_COLOUR, "Commander Language", langName);  
		}
	}
}

stock char[] GetLanguageName(int client)
{
	char langName[32];
	
	char langCode[8];
	GetLanguageInfo(GetClientLanguage(client), langCode, sizeof(langCode), langName, sizeof(langName));
	
	return langName;
}
