void RegisterCommands()
{
	RegAdminCmd("sm_QueryPlayer", CMD_RefreshPlayerSkill, ADMFLAG_KICK, "requeries a player to refresh their skill level");
}

public Action CMD_RefreshPlayerSkill(int client, int args)
{
	if (!args)
	{
		ReplyToCommand(client, "[SM] Usage: sm_QueryPlayer <Name|#UserID>");
		return Plugin_Handled;
	}
	
	char player[64];
	GetCmdArg(1, player, sizeof(player));
	
	int target = FindTarget(client, player, true, true);
	
	if (target == -1)
	{
		ReplyToCommand(client, "Invalid player name.");
		return Plugin_Handled;	
	}
	
	ReplyToCommand(client, "Querying Data... Recheck in 10s.");
	QueryPlayerData(target);
	
	return Plugin_Handled;
}

