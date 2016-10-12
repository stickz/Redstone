void PrintTeamLanguages()
{
	if (!g_Enable[TeamLang].BoolValue)
		return; //don't use this feature if not enabled
	
	bool ShowMessage[2] = {false, ...};
	int langCount[2][LANGUAGE_COUNT];
	int clientTeam, teamIDX;
	
	//initialize langCount Array
	for (int i = 0; i < LANGUAGE_COUNT; i++)
	{
		langCount[0][i] = 0;
		langCount[1][i] = 0;
	}
	
	//sort through players to find languages
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			clientTeam = GetClientTeam(client);
			
			if (clientTeam > 2)
			{
				int langNum = GetClientLanguage(client);
				char langCode[8]; 
				char langName[32];
				GetLanguageInfo(langNum, langCode, sizeof(langCode), langName, sizeof(langName));
				
				if (!StrEqual("english", langName, true))
				{
					teamIDX = clientTeam - 2;
					ShowMessage[teamIDX] = true;
					langCount[teamIDX][langNum]++;
				}
			}
		}
	}
	
	//sort through language talley and print them out
	for (int team = 0; team < 2; team++)
	{
		if (ShowMessage[team])
		{
			char PrintOut[128];
			for (int lang = 0; lang < LANGUAGE_COUNT; lang++)
			{
				if (langCount[team][lang] > 0)
				{
					char langCode[8];
					char langName[32];
					GetLanguageInfo(lang, langCode, sizeof(langCode), langName, sizeof(langName));  
					
					char ToCopy[18];
					Format(ToCopy, sizeof(ToCopy), " %s: %d", langCode, langCount[team][lang]);
					StrCat(PrintOut, sizeof(PrintOut), ToCopy);
				}
			}
			PrintTLangToTeam(team + 2, PrintOut);
		}
	}
}

void PrintTLangToTeam(int team, const char[] printOut)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsOnTeam(client, team))
		{
			char ToPrint[128];
			Format(ToPrint, sizeof(ToPrint), "%T", "Team Languages", client, printOut);
			
			PrintToChat(client, "%s%s", MESSAGE_COLOUR, ToPrint);	
		}
	}
}
