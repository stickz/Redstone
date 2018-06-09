#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <nd_stocks>
#include <nd_print>
#include <nd_maps>
#include <nd_redstone>
#include <nd_rounds>
#include <nd_com_eng>

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
	
#define AC_MAPS_SIZE 5
char nd_autocycle[AC_MAPS_SIZE][32];
void createAutoCycleMaps() {
	nd_autocycle[0] = ND_CustomMaps[ND_Sandbrick];
	nd_autocycle[1] = ND_CustomMaps[ND_Submarine];
	nd_autocycle[2] = ND_CustomMaps[ND_Nuclear];
	nd_autocycle[3] = ND_CustomMaps[ND_Mars];
	nd_autocycle[4] = ND_CustomMaps[ND_Rock];
}

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
	reducedResumeTime
};

enum Convars {
	ConVar:enableTimeLimit,
	ConVar:regularTimeLimit,
	ConVar:extendedTimeLimit,
	
	ConVar:reducedTimeLimit,
	ConVar:reducedResumeTime,
	
	ConVar:extendTimeLimit,
	ConVar:extendMinPlayers,
	ConVar:extendPercentage
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
	
	createAutoCycleMaps(); //thanks sourcemod, you suck!
	
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

public void OnClientPutInServer(int client)
{
	if (g_Bool[noTimeLimit] && ND_RoundStarted() && !g_Bool[startedCountdown] && ND_GetClientCount() > g_Cvar[enableTimeLimit].IntValue)
	{
		PrintMessageAll("Limit Effect");
			
		CreateTimer(g_Bool[reducedResumeTime] ? g_Cvar[reducedTimeLimit].FloatValue : g_Cvar[regularTimeLimit].FloatValue, 
					TIMER_TotalTimeLeft, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		
		g_Bool[startedCountdown] = true;
	}
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

bool IsAutoCycleMap(const char[] currentMap)
{
	for (int idx = 0; idx < AC_MAPS_SIZE; idx++)
		if (StrEqual(currentMap, nd_autocycle[idx], false))
			return true;	

	return false;
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
	g_Bool[reducedResumeTime] = false;
}

void createConVars()
{
	g_Cvar[enableTimeLimit] = CreateConVar("sm_timelimit_enable", "13", "Sets the number of players required to enable the time limit");
	
	g_Cvar[regularTimeLimit] = CreateConVar("sm_timelimit_regular", "60", "Sets the regular time limit on the server");
	g_Cvar[extendedTimeLimit] = CreateConVar("sm_timelimit_corner", "75", "Sets the time for the corner map");
	
	g_Cvar[reducedTimeLimit] = CreateConVar("sm_timelimit_reduced", "45", "Sets the reduced time limit on resume");
	g_Cvar[reducedResumeTime] = CreateConVar("sm_timelimit_rtime", "20", "Sets the time required for a reduced resume");
	
	g_Cvar[extendTimeLimit] = CreateConVar("sm_timelimit_extend", "15", "Sets how many minutes to add when an extension is voted"); 
	g_Cvar[extendMinPlayers] = CreateConVar("sm_timelimit_eplayers", "6", "Sets the minimum number of players for an extension");
	g_Cvar[extendPercentage] = CreateConVar("sm_timelimit_epercent", "40", "Sets the percent from each team required to extend timelimit");
	
	AutoExecConfig(true, "nd_timelimit");
}

/* Events */
public void ND_OnRoundStarted()
{
	setVarriableDefaults();
	
	char currentMap[32];
	GetCurrentMap(currentMap, sizeof(currentMap));

	if (ND_GetClientCount() > 10 || IsAutoCycleMap(currentMap))
		SetTimeLimit(currentMap);
	
	else
	{
		g_Bool[noTimeLimit] = true;
		CreateTimer(g_Cvar[reducedResumeTime].FloatValue, TIMER_ChangeResumeTime, _, TIMER_FLAG_NO_MAPCHANGE);
	}	
}

//helper function for event round start
void SetTimeLimit(const char[] currentMap)
{
	int fiveMinutesRemaining = 60;
		
	if (	StrEqual(currentMap, ND_CustomMaps[ND_Corner], false) ||
		StrEqual(currentMap, ND_StockMaps[ND_Silo], flase))
	{
		int extendTime = g_Cvar[extendedTimeLimit].IntValue;
		ServerCommand("mp_roundtime %d", extendTime);
		fiveMinutesRemaining *= (extendTime - 5);
	}
	else
	{
		int regularTime = g_Cvar[regularTimeLimit].IntValue;
		ServerCommand("mp_roundtime %d", regularTime);
		fiveMinutesRemaining *= (regularTime - 5);
	}
			
	CreateTimer(float(fiveMinutesRemaining), TIMER_FiveMinLeft, _,  TIMER_FLAG_NO_MAPCHANGE);
}

/* Timers */
public Action TIMER_ChangeResumeTime(Handle timer) {
	g_Bool[reducedResumeTime] = true;
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
	
	if (IsAutoCycleMap(nextMap))
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
