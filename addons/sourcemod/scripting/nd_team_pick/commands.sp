void RegisterCommands()
{
	RegAdminCmd("ToggleLocks", DisableTeamChg, ADMFLAG_GENERIC);
	RegAdminCmd("ShowPickMenu", ShowPickMenu, ADMFLAG_GENERIC);	
	RegAdminCmd("ReloadPicker", ReloadTeamPicker, ADMFLAG_GENERIC);
	RegAdminCmd("StopPicker", StopTeamPicking, ADMFLAG_GENERIC);	
}

public Action StopTeamPicking(int client, int args)
{
	TerminatePicking();	
	return Plugin_Handled;
}

public Action ReloadTeamPicker(int client, int args)
{
	char Name[32];
	GetClientName(client, Name, sizeof(Name));
	
	PrintToChatAll("\x05[xG] %s reloaded the team picker plugin!", Name);
	ServerCommand("sm plugins reload ND_TeamPicking");
	
	return Plugin_Handled;
}

public Action DisableTeamChg(int client, intargs) 
{	
	PrintToChatAll("Team Changing is now %s!", g_bEnabled ? "allowed" : "disabled");
	g_bEnabled = !g_bEnabled;
	return Plugin_Handled;
}

public Action ShowPickMenu(int client, int args) 
{
	if (g_bPickStarted)
	{
		ReplyToCommand(client, "[SM] Cannot use while picking is running!");
		return Plugin_Handled;
	}
	
	if (!args) 
	{
		ReplyToCommand(client, "[SM] Usage: ShowPickMenu <2 or 3>  2=Consortium, 3=Empire.");
		return Plugin_Handled;
	}
	
	char team_str[64]
	GetCmdArg(2, team_str, sizeof(team_str));
	
	if (!IsVoteInProgress())
	{
		int teamNum = StringToInt(team_str) == TEAM_CONSORT ? TEAM_CONSORT : TEAM_EMPIRE;
		Menu_PlayerPick(team_captain[CONSORT_aIDX], teamNum);	
	}	

	return Plugin_Handled;
}
