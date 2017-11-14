#define INVALID_TARGET -1

void RegisterPickingCommand()
{
	RegAdminCmd("PlayerPicking", StartPicking, ADMFLAG_GENERIC);
}

/* Functions for starting the team pick process
 * Includes lots of error handling to ensure stability
 */
public Action StartPicking(int client, int args) 
{
	// If there's a common error condition, we can't continue
	if (CatchCommonFailure(args))
		return Plugin_Handled;	

	char con_name[64]; // Get the player target in the first argument
	GetCmdArg(1, con_name, sizeof(con_name));		
	int target1 = FindTarget(client, con_name, false, false);
	
	char emp_name[64]; // Get the player target in the second argument
	GetCmdArg(2, emp_name, sizeof(emp_name));
	int target2 = FindTarget(client, emp_name, false, false);

	// If etheir of the players are invalid, we can't continue. 
	if (TargetingIsInvalid(target1, con_name, target2, emp_name))
		return Plugin_Handled;
	
	// Set the default starting team to consort
	int teamName = TEAM_CONSORT;
	int teamCaptain = target1;
	
	// If an optional third argument is inputed for the starting team
	if (args == 3)
	{
		char startTeam[16]; // Get the third argument inputed
		GetCmdArg(3, startTeam, sizeof(startTeam));		
		
		// Set the starting team to etheir Consort or Empire
		if (StrContains(startTeam, "con", false) > -1)
		{
			teamName = TEAM_CONSORT;
			teamCaptain = target1;
		}			
		else if (StrContains(startTeam, "emp", false) > -1)
		{
			teamName = TEAM_EMPIRE;
			teamCaptain = target2;
		}
		
		// If the starting team is invalid, don't countinue and have the command run again
		else
		{
			PrintToChatAll("\x05[xG] !PlayerPicking Failure: '%s' was specified, but is an invalid starting team!", startTeam);
			return Plugin_Handled;		
		}
	}
	
	// Run player picking preparation
	BeforePicking(client, target1, target2);
	
	// Check if the user wants to enable debugging
	if (args == 4)
	{
		char useDebug[16]; // Get the forth argument inputed
		GetCmdArg(4, useDebug, sizeof(useDebug));
		DebugTeamPicking = StrEqual(useDebug, "true", false);	
	}
	
	// Allow running the team picker for bots after round start if debugging
	if (ND_RoundStarted() && !DebugTeamPicking)
	{
		PrintToChatAll("\x05[xG] !PlayerPicking Failure: Use '!Nexpick on' then Reload the map!");
		return Plugin_Handled;	
	}
	
	// Display the first picking menu
	Menu_PlayerPick(teamCaptain, teamName);
	return Plugin_Handled;
}
bool CatchCommonFailure(int args)
{
	if (g_bPickStarted) 
	{
		PrintToChatAll("\x05[xG] !PlayerPicking Failure: Already running or glitched. Use !ReloadPicker if required.");
		return true;
	}
	
	if (GetClientCount(false) < 4)
	{		
		PrintToChatAll("\x05[xG] !PlayerPicking Failure: Four players required to use!");
		return true;
	}
	
	if (args < 2 || args > 4)
	{
		PrintToChatAll("\x05[xG] !PlayerPicking Failure: Format Incorrect. Usage: !PlayerPicking captain1 captain2 startingTeam");
		return true;
	}
	
	if (IsVoteInProgress())
	{
		PrintToChatAll("\x05[xG] !PlayerPicking Failure: Is a !vote or mapvote currently in progress?");
		return true;
	}	
	
	return false;
}
bool TargetingIsInvalid(int target1, char[] con_name, int target2, char[] emp_name)
{
	if (target1 == INVALID_TARGET) 
	{
		PrintToChatAll("\x05[xG] !PlayerPicking Failure: '%s' name segment invalid OR found multiple times!", con_name);
		return true;
	}	

	if (target2 == INVALID_TARGET)
	{
		PrintToChatAll("\x05[xG] !PlayerPicking Failure: '%s' name segment invalid OR found multiple times!", emp_name);
		return true;
	}

	if (target1 == target2)
	{
		char pickerName[64];
		GetClientName(target1, pickerName, sizeof(pickerName));
		
		PrintToChatAll("\x05[xG] !PlayerPicking Failure: '%s' targeted as picker on both teams!", pickerName);
		return true;	
	}
	
	return false;
}

/* Functions for running a routine before team picking is started */
public void BeforePicking(int client, int consortTarget, int empireTarget) 
{	
	SetVarriableDefaults();		
	PutEveryoneInSpectate();	
	SetCaptainTeams(consortTarget, empireTarget);
	PrintToChatAll("\x05Player Picking has Started!");
}
void SetVarriableDefaults()
{
	last_choice[CONSORT_aIDX] = 0;
	last_choice[EMPIRE_aIDX] = 0;
	
	/* Switch Algorithum */
	doublePlace = true;
	firstPlace = true;
	checkPlacement = true;	
	
	g_bEnabled=true;
	g_bPickStarted=true;
	DebugTeamPicking = false;
}
void PutEveryoneInSpectate()
{
	for (int idx = 1; idx <= MaxClients; idx++)
		if (IsValidClient(idx, false))
			ChangeClientTeam(idx, TEAM_SPEC);	
}
void SetCaptainTeams(int consortCaptain, int empireCaptain)
{
	// Assign team captains to the array
	team_captain[CONSORT_aIDX] = consortCaptain;
	team_captain[EMPIRE_aIDX] = empireCaptain;
	
	// Change team captains to their teams	
	ChangeClientTeam(consortCaptain, TEAM_CONSORT);
	ChangeClientTeam(empireCaptain, TEAM_EMPIRE);
}
