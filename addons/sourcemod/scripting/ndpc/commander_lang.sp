public Event_CommanderPromo(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_Enable[CommanderLang].BoolValue) //only use feature if enabled
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new team = GetEventInt(event, "teamid");
		
		if (IsValidClient(client))
		{
			new langNum = GetClientLanguage(client);
			decl String:langCode[8], String:langName[32];
			GetLanguageInfo(langNum, langCode, sizeof(langCode), langName, sizeof(langName));
			
			if (!StrEqual("english", langName, true))
				PrintCLangToTeam(team, langName);
		}
	}
}

PrintCLangToTeam(team, const String:langName[])
{
	decl String:MessageColour[8];
	Format(MessageColour, sizeof(MessageColour), MESSAGE_COLOUR);
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsOnTeam(client, team))
		{
			decl String:tPhrase[64];
			Format(tPhrase, sizeof(tPhrase), "%T", "Commander Language", client, langName);
			
			decl String:toPrint[80];
			StrCat(toPrint, sizeof(toPrint), MessageColour);
			StrCat(toPrint, sizeof(toPrint), tPhrase);
			
			PrintToChat(client, "%s", toPrint);  
		}
	}
}
