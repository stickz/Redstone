#define INVALID_TARGET -1

void RegisterPickingCommand()
{
	RegConsoleCmd("PlayerPicking", StartPicking, "Start the team picker");
}

/* Functions for starting the team pick process
 * Includes lots of error handling to ensure stability
 */
public Action StartPicking(int client, int args) 
{
	if (!SWMG_OfficerOrRoot(client))
	{
		ReplyToCommand(client, "You must be a RedstoneND officer to use this command!");
		return Plugin_Handled;
	}
	
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
	int teamCaptain = target1;
	
	// If an optional third argument is inputed for the starting team
	if (args == 3)
	{
		char startTeam[16]; // Get the third argument inputed
		GetCmdArg(3, startTeam, sizeof(startTeam));		
		
		// Set the starting team to etheir Consort or Empire
		if (StrContains(startTeam, "con", false) > -1)
			teamCaptain = target1;

		else if (StrContains(startTeam, "emp", false) > -1)
			teamCaptain = target2;
		
		// If the starting team is invalid, don't countinue and have the command run again
		else
		{
			PrintMessageAllTS1("Invalid Starting Team", startTeam);
			return Plugin_Handled;		
		}
	}
	
	// Set default varriables early in-case of debugging mode
	SetVarriableDefaults();	
	
	// Check if the user wants to enable debugging
	if (args == 4)
	{
		char useDebug[16]; // Get the forth argument inputed
		GetCmdArg(4, useDebug, sizeof(useDebug));
		DebugTeamPicking = StrEqual(useDebug, "true", false);
		
		char debugStatus[32];
		Format(debugStatus, sizeof(debugStatus), "Status of debug team picking is %d", DebugTeamPicking);
		ConsoleToAdmins(debugStatus, "b");
	}
	
	// Allow running the team picker for bots after round start if debugging
	if (ND_RoundStarted() && !DebugTeamPicking)
	{
		PrintMessageAll("Next Pick On");
		return Plugin_Handled;
	}
	
	// Run before picking starts
	BeforePicking(target1, target2);
	
	// Display the first picking menu
	Menu_PlayerPick(teamCaptain);
	return Plugin_Handled;
}
bool CatchCommonFailure(int args)
{
	if (g_bPickStarted) 
	{
		PrintMessageAll("Already Running");
		return true;
	}
	
	if (GetClientCount(false) < 4)
	{		
		PrintMessageAll("Four Players Required");
		return true;
	}
	
	if (args < 2 || args > 4)
	{
		PrintMessageAll("Correct Usage");
		return true;
	}
	
	if (IsVoteInProgress())
	{
		PrintMessageAll("Vote Currently Running");
		return true;
	}	
	
	return false;
}
bool TargetingIsInvalid(int target1, char[] con_name, int target2, char[] emp_name)
{
	if (target1 == INVALID_TARGET) 
	{
		PrintMessageAllTS1("Name Segment Invalid", con_name);
		return true;
	}	

	if (target2 == INVALID_TARGET)
	{
		PrintMessageAllTS1("Name Segment Invalid", emp_name);
		return true;
	}

	if (target1 == target2)
	{
		char pickerName[64];
		GetClientName(target1, pickerName, sizeof(pickerName));
		PrintMessageAllTS1("Name Segment Duplicate", pickerName);
		return true;	
	}
	
	return false;
}

/* Functions for running a routine before team picking is started */
void BeforePicking(int consortTarget, int empireTarget) 
{	
	PutEveryoneInSpectate();	
	SetCaptainTeams(consortTarget, empireTarget);
	PrintPickingMessages();
	PickedConsort.Clear();
	PickedEmpire.Clear();
}

void PrintPickingMessages()
{
	PrintMessageAll("Picking Started");
	PrintMessageAllTI1("Each Pick Time", cvarPickTimeLimit.IntValue);
	PrintMessageAllTI1("First Pick Time", cvarFirstPickTime.IntValue);	
}

void SetVarriableDefaults()
{
	team_captain[CONSORT_aIDX] = -1;
	team_captain[EMPIRE_aIDX] = -1;
	
	/* Switch Algorithum */
	picking_index = 0;
	
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
	
	// Push their steamid to the picked array list
	MarkPlayerPicked(consortCaptain, TEAM_CONSORT);
	MarkPlayerPicked(empireCaptain, TEAM_EMPIRE);
}
