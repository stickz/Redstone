#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <nd_stocks>
#include <nd_print>
#include <nd_maps>
#include <nd_redstone>
#include <nd_rounds>
#include <nd_com_eng>
#include <nd_fskill>
#include <autoexecconfig>

public Plugin myinfo =
{
	name = "[ND] TimeLimit Features",
	author = "Stickz",
	description = "Provides time limit features.",
	version = "dummy",
	url = "https://github.com/stickz/Redstone/"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_timelimit/nd_timelimit.txt"
#include "updater/standard.sp"

#define TIMELIMIT_COMMANDS_SIZE 2
char nd_timelimit_commands[TIMELIMIT_COMMANDS_SIZE][] =
{
	"time",
	"timeleft"};
	
enum Integers
{
	totalTimeLeft,
	countdown
};

enum Bools
{
	noTimeLimit,
	startedCountdown,
	enableExtend,
	hasExtended,
	justExtended,
	roundHasEnded,
	reducedResumeTime2,
	canChangeTimeLimit
};

enum Convars {
	ConVar:enableTimeLimit,
	ConVar:regularTimeLimit,
	ConVar:extendedTimeLimit,
	
	ConVar:reducedTimeLimit,
	ConVar:reducedResumeTime,
	
	ConVar:extendTimeLimit,
	ConVar:extendMinPlayers,
	ConVar:extendPercentage,
	
	ConVar:comIncSkill,
	ConVar:comIncTime
};

ConVar g_Cvar[Convars];

int voteCount[2];
int g_Integer[Integers];

Handle cookie_timelimit_features;

bool g_Bool[Bools];
bool g_hasVotedEmpire[MAXPLAYERS+1] = {false, ... };
bool g_hasVotedConsort[MAXPLAYERS+1] = {false, ... };
bool option_timelimit_features[MAXPLAYERS + 1] = {true,...};

#include "nd_timelimit/clientprefs.sp"
#include "nd_timelimit/commands.sp"
#include "nd_timelimit/extend.sp"
	
public void OnPluginStart()
{
	regConsoleCommands();
	
	AddCommandListener(PlayerJoinTeam, "jointeam");	
	HookEvent("timeleft_1m", Event_MinuteLeft, EventHookMode_PostNoCopy);
	
	addClientPrefs(); //client personalization	
	
	createConVars(); //plugin controls
	
	AddUpdaterLibrary(); //auto-updater
	
	LoadTranslations("nd_common.phrases");
	LoadTranslations("nd_timelimit.phrases");
}

public void OnMapStart() {
	setVarriableDefaults();
}

// Must fire OnMapEnd(), in-case the round is restarted
public void OnMapEnd() {
	//next map *may* get changed by anther plug-in onMapEnd()
	CreateTimer(3.0, TIMER_CheckAutoCycleMap, _, TIMER_FLAG_NO_MAPCHANGE);
}

// Must fire this, in-case the round is restarted
public void ND_OnRoundEnded() {
	setVarriableDefaults();
}

public Event_MinuteLeft(Event event, const char[] name, bool dontBroadcast) {
	CreateTimer(1.0, TIMER_ShowMinLeft, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void ND_BothCommandersPromoted(int consort, int empire) 
{
	if (g_Bool[canChangeTimeLimit])
	{
		// Get the name of the current map
		char currentMap[32];
		GetCurrentMap(currentMap, sizeof(currentMap));
		
		// Recheck the time limit, if thresholds are ment
		if (ND_GetClientCount() > 10 || ND_IsAutoCycleMap(currentMap))
			SetTimeLimit(currentMap);
		
		// Reset the varriable, so we can't change it again
		g_Bool[canChangeTimeLimit] = false;
	}
}

public void OnClientPutInServer(int client)
{
	if (	g_Bool[noTimeLimit] && ND_RoundStarted() && !g_Bool[startedCountdown] && 
		ND_GetClientCount() > g_Cvar[enableTimeLimit].IntValue)
	{
		PrintMessageAll("Limit Effect");
			
		CreateTimer(GetTimeLimit(), TIMER_TotalTimeLeft, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		
		g_Bool[startedCountdown] = true;
	}
}

float GetTimeLimit()
{
	// Decide wether to set the reduced time limit or the regular time limit
	float time = g_Bool[reducedResumeTime2] ? g_Cvar[reducedTimeLimit].FloatValue : g_Cvar[regularTimeLimit].FloatValue;
	
	if (ND_InitialCommandersReady(false) && IncComSkillTimeLimit())
		time += g_Cvar[comIncTime].FloatValue;
		
	return time;
}

bool IncComSkillTimeLimit()
{
	for (int team = TEAM_CONSORT; team <= TEAM_EMPIRE; team++)
	{
		int commander = ND_GetCommanderOnTeam(team);
		
		if (commander == NO_COMMANDER)
			return false;
		
		if (ND_GetRoundedCSkill(commander) >= g_Cvar[comIncSkill].IntValue)
			return false;
	}
	
	return true;
}

public void OnClientDisconnect(int client) {
	resetValues(client);
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (client && GetClientTeam(client) > 1)
	{
		if (strEqualsTime(client, sArgs) || strEqualsExtend(client, sArgs))
		{
			new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);						
			SetCmdReplySource(old);
			return Plugin_Stop;				
		}	
	}	
	return Plugin_Continue;
}

public Action PlayerJoinTeam(client, char[] command, int argc)
{
	resetValues(client);	
	return Plugin_Continue;
}

void setVarriableDefaults()
{
	g_Integer[totalTimeLeft] = 60;
	g_Integer[countdown] = 61;
	g_Bool[noTimeLimit] = false;
	g_Bool[startedCountdown] = false;
	
	g_Bool[roundHasEnded] = false;
	g_Bool[hasExtended] = false;
	g_Bool[justExtended] = false;
	g_Bool[enableExtend] = false;
	g_Bool[reducedResumeTime2] = false;
	g_Bool[canChangeTimeLimit] = false;
}

void createConVars()
{
	AutoExecConfig_Setup("nd_timelimit");
	
	g_Cvar[enableTimeLimit] = AutoExecConfig_CreateConVar("sm_timelimit_enable", "13", "Sets the number of players required to enable the time limit");
	
	g_Cvar[regularTimeLimit] = AutoExecConfig_CreateConVar("sm_timelimit_regular", "60", "Sets the regular time limit on the server");
	g_Cvar[extendedTimeLimit] = AutoExecConfig_CreateConVar("sm_timelimit_corner", "75", "Sets the time for the corner map");
	
	g_Cvar[reducedTimeLimit] = AutoExecConfig_CreateConVar("sm_timelimit_reduced", "45", "Sets the reduced time limit on resume");
	g_Cvar[reducedResumeTime] = AutoExecConfig_CreateConVar("sm_timelimit_rtime", "20", "Sets the time required for a reduced resume");
	
	g_Cvar[extendTimeLimit] = AutoExecConfig_CreateConVar("sm_timelimit_extend", "15", "Sets how many minutes to add when an extension is voted"); 
	g_Cvar[extendMinPlayers] = AutoExecConfig_CreateConVar("sm_timelimit_eplayers", "6", "Sets the minimum number of players for an extension");
	g_Cvar[extendPercentage] = AutoExecConfig_CreateConVar("sm_timelimit_epercent", "40", "Sets the percent from each team required to extend timelimit");
	
	g_Cvar[comIncSkill] = AutoExecConfig_CreateConVar("sm_timelimit_cominc_skill", "15", "Sets skill level of commanders to increase time limit");
	g_Cvar[comIncTime] = AutoExecConfig_CreateConVar("sm_timelimit_cominc_time", "30", "Sets the amount of time to add to the time limit");
	
	AutoExecConfig_EC_File();
}

/* Events */
public void ND_OnRoundStarted()
{
	setVarriableDefaults();
	
	// Get the name of the current map
	char currentMap[32];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	// Ether set the time limit now, or wait and set it later
	if (ND_GetClientCount() > 10 || ND_IsAutoCycleMap(currentMap))
		SetTimeLimit(currentMap);
	
	else
	{
		g_Bool[noTimeLimit] = true;
		CreateTimer(g_Cvar[reducedResumeTime].FloatValue, TIMER_ChangeResumeTime, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	// Allow the time limit to be changed in the first five minutes for rookie commanders
	g_Bool[canChangeTimeLimit] = true;
	CreateTimer(float(60 * 5), TIMER_CanChangeTimeLimit, _, TIMER_FLAG_NO_MAPCHANGE);	
}

//helper function for event round start
void SetTimeLimit(const char[] currentMap)
{
	// Calculate the base time limit, based on the current map
	int timeLimit = ND_ExtendedTimeLimitMap(currentMap) ? g_Cvar[extendedTimeLimit].IntValue 
														: g_Cvar[regularTimeLimit].IntValue;
		
	// Increase the time limit, if there are rookie commanders
	if (ND_InitialCommandersReady(false) && IncComSkillTimeLimit())
		timeLimit += g_Cvar[comIncTime].IntValue;
	
	// Set the time limit via the server command
	ServerCommand("mp_roundtime %d", timeLimit);
	
	// Calculate and trigger a timer when five minutes are remaining
	int fiveMinutesRemaining = 60 * (timeLimit - 5);			
	CreateTimer(float(fiveMinutesRemaining), TIMER_FiveMinLeft, _,  TIMER_FLAG_NO_MAPCHANGE);
}

/* Timers */
public Action TIMER_ChangeResumeTime(Handle timer) {
	g_Bool[reducedResumeTime2] = true;
}

public Action TIMER_CanChangeTimeLimit(Handle timer) {
	g_Bool[canChangeTimeLimit] = false;
}

public Action TIMER_ShowMinLeft(Handle timer)
{
	if (g_Bool[justExtended])
	{
		g_Bool[justExtended] = false;
		return Plugin_Stop;
	}
	
	g_Integer[countdown]--;
	switch (g_Integer[countdown])
	{
		case 0:
		{
			if (g_Bool[noTimeLimit])
				PrintMessageAll("Time End");
			
			ServerCommand("mp_roundtime 1");
			return Plugin_Stop;
		}
		
		default: cpShowCountDown(); //clientprefs countdown feature
		
	}
	return Plugin_Continue;
}

public Action TIMER_TotalTimeLeft(Handle timer)
{
	g_Integer[totalTimeLeft]--;
	
	switch (g_Integer[totalTimeLeft])
	{
		case 45,30,15: PrintTimeLeft();
		
		case 5:
		{
			g_Bool[enableExtend] = true;
		
			PrintTimeLeft();
		}
		
		case 1: 
		{
			PrintTimeLeft();
			CreateTimer(1.0, TIMER_ShowMinLeft, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			return Plugin_Stop;
		}
	}
	
	return Plugin_Continue;
}

void PrintTimeLeft() {
	PrintToChatAll("\x05 %d Minutes remaining!", g_Integer[totalTimeLeft]);
}

public Action TIMER_CheckAutoCycleMap(Handle timer)
{
	char nextMap[64];
	GetNextMap(nextMap, sizeof(nextMap));
	
	if (ND_IsAutoCycleMap(nextMap))
		ServerCommand("mp_roundtime %d", g_Cvar[regularTimeLimit].IntValue);
	
	return Plugin_Handled;	
}

public Action TIMER_FiveMinLeft(Handle timer)
{
	//PrintToAdmins("debug: Five minutes left triggered", "b");
	g_Bool[enableExtend] = true;
	
	if (!g_Bool[hasExtended])
		PrintExtendToEnabled();
}
