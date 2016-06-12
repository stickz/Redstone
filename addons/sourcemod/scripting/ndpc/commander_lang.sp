#define CLANG_PRINTOUT_SIZE 6

new const String:nd_cl_commands[CLANG_PRINTOUT_SIZE][] = 
{
	"sm_comlang",
	"sm_commanderlang",
	"sm_commanderlanguage",
	"sm_ComLang",
	"sm_CommanderLang",
	"sm_CommanderLanguage"
};

RegComLangCommands()
{
	for (new p = 0; p < CLANG_PRINTOUT_SIZE; p++)
	{
		RegConsoleCmd(nd_cl_commands[p], CMD_PrintCLang);
	}
}

public Action:CMD_PrintCLang(client, args)
{
	new commander = ND_GetCommanderBy(client);
	if (commander == NO_COMMANDER)
	{
		PrintToChat(client, "%s%t", CHAT_PREFIX, "No Team Commander");
		return Plugin_Handled;
	}
	
	PrintToChat(client, "%s%t", MESSAGE_COLOUR, "Commander Language", GetLanguageName(client));
	return Plugin_Handled;
}

public Event_CommanderPromo(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_Enable[CommanderLang].BoolValue) //only use feature if enabled
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new team = GetEventInt(event, "teamid");
		
		if (IsValidClient(client))
		{
			decl String:langName[32];
			Format(langName, sizeof(langName), GetLanguageName(client));

			if (!StrEqual("english", langName, true))
				PrintCLangToTeam(team, langName);
		}
	}
}

PrintCLangToTeam(team, const String:langName[])
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsOnTeam(client, team))
		{
			PrintToChat(client, "%s%t", MESSAGE_COLOUR, "Commander Language", langName);  
		}
	}
}

stock String:GetLanguageName(client)
{
	new String:langName[32];
	
	decl String:langCode[8];
	GetLanguageInfo(GetClientLanguage(client), langCode, sizeof(langCode), langName, sizeof(langName));
	
	return langName;
}
