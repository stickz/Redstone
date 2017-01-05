#define FILE80 	0
#define FILE100 1
#define FILE120 2
#define FILE140 3

#define COMMAND_DESC "Sets a custom weighting for a player"

void RegAdminCmds()
{
	RegAdminCmd("sm_Weight80", CMD_Weight80, ADMFLAG_ROOT, COMMAND_DESC);
	RegAdminCmd("sm_Weight100", CMD_Weight100, ADMFLAG_ROOT, COMMAND_DESC);
	RegAdminCmd("sm_Weight120", CMD_Weight120, ADMFLAG_ROOT, COMMAND_DESC);
	RegAdminCmd("sm_Weight140", CMD_Weight140, ADMFLAG_ROOT, COMMAND_DESC);
	RegAdminCmd("sm_WeightRemove", CMD_RemoveWeight, ADMFLAG_ROOT, COMMAND_DESC);
	
	RegAdminCmd("sm_CheckWeight", CMD_GetPlayerWFloor, ADMFLAG_KICK, COMMAND_DESC);
	RegAdminCmd("sm_PrintALW", CMD_PrintArrayList, ADMFLAG_KICK, COMMAND_DESC);
}

public Action CMD_PrintArrayList(int client, int args)
{
	for (int i = 0; i < g_SteamIDList.Length; i++)
	{
		char steamid[STEAMID_SIZE];
		g_SteamIDList.GetString(i, steamid, sizeof(steamid));
		PrintToConsole(client, "found %s", steamid);	
	}
	
	PrintToChat(client, "see console for output");
	return Plugin_Handled;	
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

public Action CMD_RemoveWeight(int client, int args)
{
	char player[64];
	GetCmdArg(1, player, sizeof(player));	
	int target = FindTarget(client, player, true, true);
	
	if (InvalidCommandUse(client, target, args))
		return Plugin_Handled;	
	
	RemoveClientWeighting(target);	
	return Plugin_Handled;
}

public Action CMD_GetPlayerWFloor(int client, int args)
{
	char player[64];
	GetCmdArg(1, player, sizeof(player));	
	int target = FindTarget(client, player, true, true);
	
	if (InvalidCommandUse(client, target, args))
		return Plugin_Handled;
	
	/* Get and trim the client's steamid */
	char steamid[STEAMID_SIZE];
	GetClientAuthId(target, AuthId_Steam2, steamid, sizeof(steamid));
	TrimString(steamid);
	
	PrintToConsole(client, "Getting %s", steamid);
	
	int found = g_SteamIDList.FindString(steamid);
	if (found == STRING_NOT_FOUND)
	{
		PrintToChat(client, "player not found");
		return Plugin_Handled;
	}
	
	int weight = g_PlayerSkillFloors.Get(found)
	PrintToChat(client, "player weight is %d", weight);	
	return Plugin_Handled;
}

public Action CMD_Weight80(int client, int args)
{
	char player[64];
	GetCmdArg(1, player, sizeof(player));	
	int target = FindTarget(client, player, true, true);
	
	if (InvalidCommandUse(client, target, args))
		return Plugin_Handled;
	
	AddClientWeighting(target, FILE80);	
	return Plugin_Handled;
}

public Action CMD_Weight100(int client, int args)
{
	char player[64];
	GetCmdArg(1, player, sizeof(player));	
	int target = FindTarget(client, player, true, true);
	
	if (InvalidCommandUse(client, target, args))
		return Plugin_Handled;
	
	AddClientWeighting(target, FILE100);	
	return Plugin_Handled;
}

public Action CMD_Weight120(int client, int args)
{
	char player[64];
	GetCmdArg(1, player, sizeof(player));	
	int target = FindTarget(client, player, true, true);
	
	if (InvalidCommandUse(client, target, args))
		return Plugin_Handled;
	
	AddClientWeighting(target, FILE120);	
	return Plugin_Handled;
}

public Action CMD_Weight140(int client, int args)
{
	char player[64];
	GetCmdArg(1, player, sizeof(player));	
	int target = FindTarget(client, player, true, true);
	
	if (InvalidCommandUse(client, target, args))
		return Plugin_Handled;
	
	AddClientWeighting(target, FILE140);	
	return Plugin_Handled;
}