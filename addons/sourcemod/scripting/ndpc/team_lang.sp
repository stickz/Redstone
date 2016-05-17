PrintTeamLanguages()
{
	if (!g_Enable[TeamLang].BoolValue)
		return; //don't use this feature if not enabled
	
	new bool:ShowMessage[2] = {false, ...};
	new langCount[2][LANGUAGE_COUNT];
	new clientTeam, teamIDX;
	
	//initialize langCount Array
	for (new i = 0; i < LANGUAGE_COUNT; i++)
	{
		langCount[0][i] = 0;
		langCount[1][i] = 0;
	}
	
	//sort through players to find languages
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			clientTeam = GetClientTeam(client);
			
			if (clientTeam > 2)
			{
				new langNum = GetClientLanguage(client);
				decl String:langCode[8], String:langName[32];
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
	for (new team = 0; team < 2; team++)
	{
		if (ShowMessage[team])
		{
			decl String:PrintOut[128];
			for (new lang = 0; lang < LANGUAGE_COUNT; lang++)
			{
				if (langCount[team][lang] > 0)
				{
					decl String:langCode[8], String:langName[32];
					GetLanguageInfo(lang, langCode, sizeof(langCode), langName, sizeof(langName));  
					
					decl String:ToCopy[18];
					Format(ToCopy, sizeof(ToCopy), " %s: %d", langCode, langCount[team][lang]);
					StrCat(PrintOut, sizeof(PrintOut), ToCopy);
				}
			}
			PrintTLangToTeam(team + 2, PrintOut);
		}
	}
}

PrintTLangToTeam(team, const String:printOut[])
{
	decl String:MessageColour[8];
	Format(MessageColour, sizeof(MessageColour), MESSAGE_COLOUR);
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsOnTeam(client, team))
		{
			decl String:tPhrase[128];
			Format(tPhrase, sizeof(tPhrase), "%T", "Team Languages", client, printOut);
			
			decl String:toPrint[150];
			StrCat(toPrint, sizeof(toPrint), MessageColour);
			StrCat(toPrint, sizeof(toPrint), tPhrase);
			
			PrintToChat(client, "%s", toPrint);	
		}
	}
}
