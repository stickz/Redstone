bool pauseWarmup = false;

void RegNextPickCommand() {
	RegAdminCmd("sm_NextPick", CMD_TriggerPicking, ADMFLAG_CUSTOM6, "enable/disable picking for next map");
}

/* Toggle player picking mode */
public Action CMD_TriggerPicking(int client, int args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: !NextPick <on or off>");
		return Plugin_Handled;	
	}
	
	char arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	char Name[32];
	GetClientName(client, Name, sizeof(Name));	
		
	if (StrEqual(arg1, "on", false))
	{
		pauseWarmup = true;
		PrintToChatAll("\x05%s triggered picking game(s) next map!", Name);		
	}
	
	else if (StrEqual(arg1, "off", false))
	{
		pauseWarmup = false;
		PrintToChatAll("\x05%s triggered regular game(s) next map!", Name);		
	}
	
	else
	{
		ReplyToCommand(client, "[SM] Usage: !NextPick <on or off>");
		return Plugin_Handled;	
	}
		
	return Plugin_Handled;	
}
