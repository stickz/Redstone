void RegAdminCmds()
{
	RegAdminCmd("sm_AddComDep", CMD_AddComDep, ADMFLAG_ROOT, "dummy");
	RegAdminCmd("sm_AddCommanderDep", CMD_AddComDep, ADMFLAG_ROOT, "dummy");
	
	RegAdminCmd("sm_RemoveComDep", CMD_AddComDep, ADMFLAG_ROOT, "dummy");
	RegAdminCmd("sm_RemoveCommanderDep", CMD_RemoveComDep, ADMFLAG_ROOT, "dummy");	
	
	RegAdminCmd("sm_CheckComDep", CMD_CheckComDep, ADMFLAG_KICK, "dummy");
	RegAdminCmd("sm_PrintComDeps", CMD_PrintComDeps, ADMFLAG_KICK, "dummy");	
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

public Action CMD_AddComDep(int client, int args)
{
	/* Find target, and check for invalid args */
	char player[64];
	GetCmdArg(1, player, sizeof(player));
	int target = FindTarget(client, player, true, true);
	
	if (InvalidCommandUse(client, target, args))
		return Plugin_Handled;	
	
	AddClientDep(target);
	return Plugin_Handled;
}

public Action CMD_RemoveComDep(int client, int args)
{
	/* Find target, and check for invalid args */
	char player[64];
	GetCmdArg(1, player, sizeof(player));
	int target = FindTarget(client, player, true, true);
	
	if (InvalidCommandUse(client, target, args))
		return Plugin_Handled;	
	
	RemoveClientDep(target, client);
	return Plugin_Handled;
}

public Action CMD_CheckComDep(int client, int args)
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

public Action CMD_PrintComDeps(int client, int args)
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