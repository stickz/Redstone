bool currentlyPicking = false;

void WarmupCompleteStartActions()
{
	if (pauseWarmup)
	{
		ServerCommand("sm_cvar sv_alltalk 0"); //Disable AT while picking, but enable FF.
		//ServerCommand("sm_balance 0"); Disable team balancer plugin
		ServerCommand("sm_commander_restrictions 0"); // Disable commander restrictions
		ServerCommand("sm_cvar nd_commander_election_time 15.0");
		
		currentlyPicking = true;
		PrintToAdmins("\x05[xG] Team Picking is now availible!", "b");	
		
		return;
	}
			
	/* Start Round using team balancer if applicable */		
	else if (RunWarmupBalancer())
		WB2_BalanceTeams();
			
	/* Otherwise, Start the Round normally */			
	else
		StartRound();
	
	RestoreServerConvars();	
}

void RestoreServerConvars()
{
	ServerCommand("sm_balance 1");
	ServerCommand("sm_commander_restrictions 1");
}

bool RunWarmupBalancer()
{
	if (BT2_AVAILABLE() && g_Cvar[enableWarmupBalance].BoolValue)
		return ReadyToBalanceCount() >= g_Cvar[minPlayersForBalance].IntValue;
	
	return false;
}
