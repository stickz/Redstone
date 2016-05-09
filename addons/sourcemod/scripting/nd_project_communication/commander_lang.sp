public Event_CommanderPromo(Handle:event, const String:name[], bool:dontBroadcast)
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

PrintCLangToTeam(team, const String:langName[])
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && GetClientTeam(client) == team)
		{
			PrintToChat(client, "\x05The commander's game client language is %s.", langName);  
		}
	}
}
