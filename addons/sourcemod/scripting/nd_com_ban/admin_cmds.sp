void RegAdminCmds()
{
	RegAdminCmd("sm_AddComBan", CMD_AddComBan, ADMFLAG_ROOT, "dummy");
	RegAdminCmd("sm_AddCommanderBan", CMD_AddComBan, ADMFLAG_ROOT, "dummy");
	
	RegAdminCmd("sm_RemoveComBan", CMD_RemoveComBan, ADMFLAG_ROOT, "dummy");
	RegAdminCmd("sm_RemoveCommanderBan", CMD_RemoveComBan, ADMFLAG_ROOT, "dummy");	
	
	RegAdminCmd("sm_CheckComBan", CMD_CheckComBan, ADMFLAG_KICK, "dummy");
	RegAdminCmd("sm_PrintComBans", CMD_PrintComBans, ADMFLAG_KICK, "dummy");	
}

bool InvalidCommandUse(int client, int target, int args)
{
	if (!args)
	{
		PrintToChat(client, "Incorrect usage");
		return true;		
	}
	
	if (target == -1)
	{
		PrintToChat(client, "Invalid player name.");
		return true;		
	}	
	
	return false;
}

public Action CMD_AddComBan(int client, int args)
{
	/* Find target, and check for invalid args */
	char player[64];
	GetCmdArg(1, player, sizeof(player));
	int target = FindTarget(client, player, true, true);
	
	if (InvalidCommandUse(client, target, args))
		return Plugin_Handled;	
	
	AddComBan(target);
	return Plugin_Handled;
}

public Action CMD_RemoveComBan(int client, int args)
{
	/* Find target, and check for invalid args */
	char player[64];
	GetCmdArg(1, player, sizeof(player));
	int target = FindTarget(client, player, true, true);
	
	if (InvalidCommandUse(client, target, args))
		return Plugin_Handled;	
	
	RemoveComBan(target, client);
	return Plugin_Handled;
}

public Action CMD_CheckComBan(int client, int args)
{
	/* Find target, and check for invalid args */
	char player[64];
	GetCmdArg(1, player, sizeof(player));
	int target = FindTarget(client, player, true, true);
	
	if (InvalidCommandUse(client, target, args))
		return Plugin_Handled;	
	
	/* Get and trim client steamid */
	char steamid[STEAMID_SIZE];
	GetClientAuthId(target, AuthId_Steam2, steamid, STEAMID_SIZE);
	TrimString(steamid);
	
	/* Print wether or not the player was found */
	int found = g_SteamIDList.FindString(steamid);
	PrintToChat(client, found == -1 ? "player not found" : "player found");	
	return Plugin_Handled;
}

public Action CMD_PrintComBans(int client, int args)
{
	for (int i = 0; i < g_SteamIDList.Length; i++)
	{
		char steamid[STEAMID_SIZE];
		g_SteamIDList.GetString(i, steamid, STEAMID_SIZE);
		PrintToConsole(client, "found %s", steamid);		
	}
	
	PrintToChat(client, "see console for output");
	return Plugin_Handled;
}