int countdown;
bool balanceTeams = false;
Handle CountDownTimer = INVALID_HANDLE;

void RegCommandsCountDown()
{
	RegAdminCmd("sm_start", Command_Start, ADMFLAG_GENERIC);
	RegAdminCmd("sm_stop", Command_Cancel, ADMFLAG_GENERIC);
}

void ClearCountDownHandle() {
	CountDownTimer = INVALID_HANDLE;
}

void StartCountDown(int timervalue)
{
	countdown = timervalue;       
	CountDownTimer = CreateTimer(1.0, TheCountDownTimer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}
 
void CancelCountDown()
{
	if (CountDownTimer != INVALID_HANDLE)
	{
		KillTimer(CountDownTimer);
		CountDownTimer = INVALID_HANDLE;
	}
}

public Action Command_Start(int client, int args)
{
	if (args == 1)
	{
		char runBalance[16]; // Get the argument inputed
		GetCmdArg(1, runBalance, sizeof(runBalance));
		balanceTeams = StrEqual(runBalance, "true", false);
	}
	
	if (!ND_RoundStarted())
		StartCountDown(15);     

	else 
		ReplyToCommand(client, "Start Error! The round has already been started.");
		
	return Plugin_Handled;
}
 
public Action Command_Cancel(int client, int args)
{
	CancelCountDown();
	return Plugin_Handled;
}

public Action TheCountDownTimer(Handle timer)
{  
	if (countdown <= 0)
	{
		StartRound(balanceTeams);
		CountDownTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	else
	{
		Handle HudText = CreateHudSynchronizer();
		SetHudTextParams(-1.0, 0.4, 1.0, 236, 120, 15, 255); 
		
		for (int i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i))
				ShowSyncHudText(i, HudText, "%d", countdown);
			
		CloseHandle(HudText);	
	}
	
	countdown--;
	return Plugin_Continue;
}
