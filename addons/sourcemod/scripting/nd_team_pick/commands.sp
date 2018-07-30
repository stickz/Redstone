void RegisterCommands()
{
	RegConsoleCmd("ToggleLocks", DisableTeamChg, "Disable team locks");
	RegConsoleCmd("ShowPickMenu", ShowPickMenu, "Show team pick menu");	
	RegConsoleCmd("ReloadPicker", ReloadTeamPicker, "Reload team picker");
	RegConsoleCmd("StopPicker", StopTeamPicking, "Stop team picker");	
}

public Action StopTeamPicking(int client, int args)
{
	if (!SWMG_OfficerOrRoot(client))
	{
		ReplyToCommand(client, "You must be a RedstoneND officer to use this command!");
		return Plugin_Handled;
	}
	
	FinishPicking(true);	
	return Plugin_Handled;
}

public Action ReloadTeamPicker(int client, int args)
{
	if (!SWMG_OfficerOrRoot(client))
	{
		ReplyToCommand(client, "You must be a RedstoneND officer to use this command!");
		return Plugin_Handled;
	}
	
	// Terminate team picking procress before reloading
	FinishPicking(true);
	
	// Display a message the plugin is about to be reloaded
	DisplayReloadedPlugin(client);
	
	// Reload the team picking plugin
	ReloadThePlugin();	
	return Plugin_Handled;
}

void DisplayReloadedPlugin(int client)
{
	char Name[32];
	GetClientName(client, Name, sizeof(Name));	
	PrintToChatAll("\x05[xG] %s reloaded the team picker plugin!", Name);
}

void ReloadThePlugin() {
	ServerCommand("sm plugins reload nd_team_picking");
}

public Action DisableTeamChg(int client, intargs) 
{	
	if (!SWMG_OfficerOrRoot(client))
	{
		ReplyToCommand(client, "You must be a RedstoneND officer to use this command!");
		return Plugin_Handled;
	}
	
	PrintToChatAll("Team Changing is now %s!", g_bEnabled ? "allowed" : "disabled");
	g_bEnabled = !g_bEnabled;
	return Plugin_Handled;
}

public Action ShowPickMenu(int client, int args) 
{
	if (!SWMG_OfficerOrRoot(client))
	{
		ReplyToCommand(client, "You must be a RedstoneND officer to use this command!");
		return Plugin_Handled;
	}
	
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
	
	if (!IsVoteInProgress())
	{	
		DebugTeamPicking = true;
		PutEveryoneInSpectate();
		
		if (args == 2)
		{
			char putTeam[64]
			GetCmdArg(2, putTeam, sizeof(putTeam));	
			
			if (StrEqual(putTeam, "true", false))
			{
				char team_str[64]
				GetCmdArg(1, team_str, sizeof(team_str));
				int teamNum = StringToInt(team_str) == TEAM_CONSORT ? TEAM_CONSORT : TEAM_EMPIRE;
				ChangeClientTeam(client, teamNum);
			}
		}
		
		
		Menu_PlayerPick(client);	
	}	

	return Plugin_Handled;
}
