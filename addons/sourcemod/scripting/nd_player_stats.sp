#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <nd_rounds>
#include <nd_redstone>
#include <nd_com_eng>

#define SCORE_BASED_MULTIPLIER 100.0
#define MIN_ADJUSTMENT_CLIENT_COUNT 6
#define LOW_SPM_ADJUST_REGARDLESS 1000
#define REQUIRED_MINS_FOR_ADJUSTMENT 5
#define ROOKIE_ADJUST_AT_MINUTE 15
#define BOMBER_ADJUST_AT_MINUTE 6
#define VETERAN_IS_BOMBING 1.5
#define ROOKIE_SKILL_ADJUSTMENT 1.25
#define VETERAN_BOMB_FACTOR 2.0
#define MIN_CONNECT_TO_SAVE 15

public Plugin myinfo =
{
	name = "[ND] Player Stats Creator",
	author = "Stickz",
	description = "Creates player stats for skill",
	version = "dummy",
	url = "https://github.com/stickz/Redstone"
};

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_player_stats/nd_player_stats.txt"
#include "updater/standard.sp"

int	connectionTime[MAXPLAYERS+1] = {-1, ...};
int	scorePerMinute[MAXPLAYERS+1] = {-1, ...};

Handle DatabaseHandle;
Handle hTimerSPM = INVALID_HANDLE;
Handle SaveSPMTimer;

public void OnPluginStart()
{
    AddUpdaterLibrary(); //auto-updater

    if (!SQL_CheckConfig("nd_stats"))
    {
        SetFailState("Could not find configuration for \"nd_stats\" database");
    }

    SQL_TConnect(OnDatabaseConnected, "nd_stats");
}

public OnDatabaseConnected(Handle owner, Handle handle, const char[] error, any data)
{
    if (!IsValidHandle(handle))
    {
        SetFailState("Unable to connect to \"nd_stats\" database: %s", error);
    }

    DatabaseHandle = handle;
    SQL_SetCharset(DatabaseHandle, "utf8mb4");

    char query[1024];
    FormatEx(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `spm` (`id` int NOT NULL AUTO_INCREMENT, `steamid` varchar(128) NOT NULL, `score` bigint NOT NULL, `rounds` int NOT NULL, PRIMARY KEY (`id`))");
    SQL_TQuery(DatabaseHandle, Setup_Step1_CreateTable, query, _, DBPrio_Low);
}

void Setup_Step1_CreateTable(Handle owner, Handle handle, const char[] error, any data)
{
    if (!IsValidHandle(handle))
    {
        SetFailState("Unable to create \"spm\" table in \"nd_stats\" database: %s", error);
    }
}

void SaveSPM()
{
    if (IsValidHandle(SaveSPMTimer))
        delete SaveSPMTimer;

    SaveSPMTimer = CreateTimer(0.5, Timer_SaveSPM, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_SaveSPM(Handle timer)
{
	RED_LOOP_CLIENTS(client)
	{
		if (connectionTime[client] >= MIN_CONNECT_TO_SAVE)
		{
			char steamid[32];
			GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
			
			char query[1024];
			FormatEx(query, sizeof(query), "SELECT id, score, rounds FROM spm WHERE steamid = '%s'", steamid);
			SQL_TQuery(DatabaseHandle, SaveTeams_Step2_SelectSPM, query, GetClientUserId(client), DBPrio_Low);
		}
	}
	
	return Plugin_Continue;
}

void SaveTeams_Step2_SelectSPM(Handle owner, Handle handle, const char[] error, any userid)
{
	if (!IsValidHandle(handle))
	{
		LogAction(0, -1, "Select spm failed: %s", error);
		return;
	}
	
	int client = GetClientOfUserId(userid);
	char query[1024];
	if (SQL_GetRowCount(handle) > 0 && SQL_FetchRow(handle))
	{
		int rowID = SQL_FetchInt(handle, 0);
		int scoreTotal = SQL_FetchInt(handle, 1) + scorePerMinute[client];
		int roundCount = SQL_FetchInt(handle, 2) + 1;
		
		FormatEx(query, sizeof(query), "UPDATE spm SET score = %i, rounds = %i WHERE id = %i", scoreTotal, roundCount, rowID);
	}
	else
	{
		char steamid[32];
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));		
		char escSteamID[32];
		SQL_EscapeString(DatabaseHandle, steamid, escSteamID, sizeof(escSteamID));
		
		FormatEx(query, sizeof(query), "INSERT INTO spm (steamid, score, rounds) VALUES ('%s', %i, %i)", escSteamID, scorePerMinute[client], 1);
	}
	SQL_TQuery(DatabaseHandle, SaveTeams_Step3_InsertSPM, query, _, DBPrio_Low);	
}

void SaveTeams_Step3_InsertSPM(Handle owner, Handle handle, const char[] error, any userid)
{
    if (!IsValidHandle(handle))
    {
        LogAction(0, -1, "Inserting spm failed: %s", error);
    }
}

public void ND_OnRoundStarted() {
	startSPMTimer();	
}

public void OnClientConnected(int client) {
	resetVarriables(client);
}

public void OnClientDisconnect(int client) {
	resetVarriables(client);
}

public void ND_OnRoundEndedEX() 
{
	PrintScoreValues();
	SaveSPM();
	
	// If the round ended & started this map, reset the client varriables
	for (int client = 1; client <= MaxClients; client++)
		resetVarriables(client);
	
	// If the round ended & started this map, stop the SPM logic timer
	if (hTimerSPM != INVALID_HANDLE && IsValidHandle(hTimerSPM))
	{
		KillTimer(hTimerSPM);
		hTimerSPM = INVALID_HANDLE;
	}
}

void PrintScoreValues()
{
	PrintSpacer(); PrintSpacer();
	PrintToConsoleAll("--> Player SPM Values <--");
	PrintToConsoleAll("Format: Name, ScorePerMinute * 100, SessionTime");
	PrintSpacer();
	
	PrintToConsoleAll("Team %s:", ND_GetTeamName(TEAM_CONSORT));
	dumpClientsOnTeam(TEAM_CONSORT);
	PrintSpacer();
	
	PrintToConsoleAll("Team %s:", ND_GetTeamName(TEAM_EMPIRE));
	dumpClientsOnTeam(TEAM_EMPIRE);
	PrintSpacer();	
}

void PrintSpacer() {
	PrintToConsoleAll("");
}

void dumpClientsOnTeam(int team)
{
	char Name[32];
	RED_LOOP_CLIENTS(client)
	{
		if (GetClientTeam(client) == team)
		{
			GetClientName(client, Name, sizeof(Name));
			PrintToConsoleAll("Name: %s, SPM: %d, CT: %d", Name, scorePerMinute[client], connectionTime[client]);
		}
	}
}

void resetVarriables(int client)
{
	connectionTime[client] = -1;
	scorePerMinute[client] = -1;
}

/*Update Score per Minute Data */
public Action TIMER_updateSPM(Handle timer)
{
	UpdateSPM();	
	return Plugin_Continue;
}

void startSPMTimer() {
	hTimerSPM = CreateTimer(60.0, TIMER_updateSPM, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	
}

void UpdateSPM()
{
	int clientScore;
	int	spmAverage[2];
	float SPM;

	spmAverage[CONSORT_AIDX] = getSPMaverage(TEAM_CONSORT);
	spmAverage[EMPIRE_AIDX] = getSPMaverage(TEAM_EMPIRE);
	
	RED_LOOP_CLIENTS(client)
	{
		if (isOnTeam(client) && !ND_IsCommander(client))
		{
			connectionTime[client]++;
			if (connectionTime[client] >= 1)
			{
				/* Update client's score per minute each minute */
				clientScore = ND_RetrieveScoreEx(client);
				SPM = (float(clientScore) / float(connectionTime[client])) * SCORE_BASED_MULTIPLIER;
				scorePerMinute[client] = RoundFloat(SPM);
			}
		}
	}
}

int getSPMaverage(int team)
{
	int score, count;
	RED_LOOP_CLIENTS(client)
	{
		if (GetClientTeam(client) == team)
		{
			if (scorePerMinute[client] != -1)
			{
				score += scorePerMinute[client];
				count++;
			}
		}
	}
	return count > 0 ? score / count : -1;
}