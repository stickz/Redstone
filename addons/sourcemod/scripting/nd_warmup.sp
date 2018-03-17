#include <sourcemod>
#include <nd_stocks>
#include <nd_maps>
#include <nd_shuffle>
#include <nd_rounds>
#include <nd_redstone>
#include <nd_rstart>

#define VALUE_TYPE_ENABLED 1
#define VALUE_TYPE_DISABLED 0

#define STOCK_RAPID_START 15
#define CUSTOM_RAPID_START 30

public Plugin myinfo =
{
	name = "[ND] Warmup Round",
	author = "Stickz",
	description = "Creates a warmup round on map change",
	version = "dummy",
	url = "https://github.com/stickz/Redstone/"
};

/* Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_warmup/nd_warmup.txt"
#include "updater/standard.sp"

enum Bools
{
	useBalancer,
	runBalancer,
	enableBalancer,
	warmupCompleted,
	currentlyPicking
};

enum Integers
{
	warmupCountdown,
	warmupTextType
};

enum Convars
{
	ConVar:enableWarmupBalance,
	ConVar:stockWarmupTime,
	ConVar:customWarmupTime,
	ConVar:rapidStartClientCount,
	ConVar:minPlayersForBalance
};

bool g_Bool[Bools];
int g_Integer[Integers];
ConVar g_Cvar[Convars];

/* Forwards */
Handle g_OnWarmupCompleted = INVALID_HANDLE;

public void OnPluginStart()
{
	LoadTranslations("nd_warmup.phrases");
	
	CreatePluginConvars();

	g_OnWarmupCompleted = CreateGlobalForward("ND_OnWarmupComplete", ET_Ignore);
	
	AddUpdaterLibrary(); //Add updater support if included
}

public void OnMapStart()
{	
	SetVarDefaults();
	
	SetMapWarmupTime();	
	ServerCommand("bot_quota 0"); //Make sure bots are disabled
	
	StartWarmupRound();
}

public OnMapEnd() {
	InitiateRoundEnd();
}

public void ND_OnRoundEnded() {
	InitiateRoundEnd();	
}

public void ND_OnRoundStarted() {
	ToogleWarmupConvars(VALUE_TYPE_DISABLED);
}

public Action TIMER_WarmupRound(Handle timer)
{
	g_Integer[warmupCountdown]--;

	switch (g_Integer[warmupCountdown])
	{
		// Notice: These hacks assume short circuit evaluation is used.
		case CUSTOM_RAPID_START:
		{
			if (!CurMapIsStock() && CheckRapidStart())
				return Plugin_Stop;
		}		
		case STOCK_RAPID_START:
		{
			if (CurMapIsStock() && CheckRapidStart())
				return Plugin_Stop;
		}
		
		case 4: ServerCommand("bot_quota 0");		
		case 3: g_Integer[warmupTextType] = 1;
		
		case 1: 
		{
			SetWarmupEndType();
			return Plugin_Stop;
		}
	}
	
	DisplayHudText();
	return Plugin_Continue;
}

bool CurMapIsStock()
{
	char curMap[32];
	GetCurrentMap(curMap, sizeof(curMap));
	
	return ND_IsStockMap(curMap);
}

bool CheckRapidStart()
{
	// Get the client count on the server. Try Redstone native first.
	// If the client count is within range, start the game faster
	if (ND_GetClientCount() <= g_Cvar[rapidStartClientCount].IntValue)
	{
		SetWarmupEndType();
		return true;				
	}
	
	return false;
}

bool RunWarmupBalancer()
{
	if (BT2_AVAILABLE() && g_Bool[runBalancer] && g_Bool[enableBalancer])
		return ReadyToBalanceCount() >= g_Cvar[minPlayersForBalance].IntValue;
	
	return false;
}

void CreatePluginConvars()
{
	g_Cvar[enableWarmupBalance] 	=	CreateConVar("sm_warmup_balance", "1", "Warmup Balancer: 0 to disable, 1 to enable");
	g_Cvar[stockWarmupTime]		=	CreateConVar("sm_warmup_rtime", "40", "Sets the warmup time for stock maps");
	g_Cvar[customWarmupTime]	=	CreateConVar("sm_warmup_ctime", "55", "Sets the warmup time for custom maps");
	g_Cvar[rapidStartClientCount]	=	CreateConVar("sm_warmup_rscc", "4", "Sets the number of players for rapid starting");
	g_Cvar[minPlayersForBalance]	=	CreateConVar("sm_warmup_bmin", "6", "Sets minium number of players for warmup balance");
	
	AutoExecConfig(true, "nd_warmup");
}

void DisplayHudText()
{
	Handle HudText = CreateHudSynchronizer();
	SetHudTextParams(-1.0, 0.4, 1.0, 220, 20, 60, 255);
	
	for (int idx = 1; idx <= MaxClients; idx++)
		if (IsClientInGame(idx))
		{
			char hudTXT[32];
			
			switch (g_Integer[warmupTextType])
			{
				case 0, 1: Format(hudTXT, sizeof(hudTXT), "%T", "Waiting", idx);
				case 2: Format(hudTXT, sizeof(hudTXT), "%T...", "Please Wait", idx);
			}
	
			ShowSyncHudText(idx, HudText, "%s",hudTXT);
		}		
					
	CloseHandle(HudText);
}

void SetWarmupEndType()
{	
	/* Start Round using team picker if applicable */
	if (ND_PauseWarmupRound())
	{
		ServerCommand("sm_cvar sv_alltalk 0"); //Disable AT while picking, but enable FF.
		ServerCommand("sm_balance 0"); // Disable team balancer plugin
		ServerCommand("sm_commander_restrictions 0"); // Disable commander restrictions
		ServerCommand("sm_cvar nd_commander_election_time 15.0");
		
		g_Bool[currentlyPicking] = true;
		PrintToAdmins("\x05[xG] Team Picking is now availible!", "b");		
		
		FireWarmupCompleteForward();
		
		return;
	}
			
	/* Start Round using team balancer if applicable */		
	else if (RunWarmupBalancer())
		WB2_BalanceTeams();
			
	/* Otherwise, Start the Round normally */			
	else
		StartRound();
	
	FireWarmupCompleteForward();
	ServerCommand("sm_balance 1");
	ServerCommand("sm_cvar nd_commander_election_time 90.0");
}

void FireWarmupCompleteForward()
{
	g_Bool[warmupCompleted] = true;
	
	Action dummy;
	Call_StartForward(g_OnWarmupCompleted);
	Call_Finish(dummy);
}

void InitiateRoundEnd()
{
	ServerCommand("mp_minplayers 32");		
	ServerCommand("sm_cvar sv_alltalk 1");
}

void StartWarmupRound()
{
	CreateTimer(1.0, TIMER_WarmupRound, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	ToogleWarmupConvars(VALUE_TYPE_ENABLED);
}

void SetMapWarmupTime()
{
	char currentMap[32];
	GetCurrentMap(currentMap, sizeof(currentMap));		
	g_Integer[warmupCountdown] = ND_IsCustomMap(currentMap) ? g_Cvar[customWarmupTime].IntValue : g_Cvar[stockWarmupTime].IntValue;
}

void StartRound()
{
	ServerCommand("mp_minplayers 1"); //start round
	PrintToChatAll("\x05[TB] %t", "Balancer Off");
}

void SetVarDefaults()
{
	g_Bool[useBalancer] = false;
	g_Bool[runBalancer] = true;
	g_Bool[warmupCompleted] = false;
	g_Bool[currentlyPicking] = false;
	g_Bool[enableBalancer] = g_Cvar[enableWarmupBalance].BoolValue;
	g_Integer[warmupTextType] = 0;
}

ToogleWarmupConvars(value)
{
	ServerCommand("sm_cvar sv_alltalk %d", value);
	ServerCommand("sm_cvar mp_friendlyfire %d", value);	
	
	/* 
	 * cannot use spawn time feature yet due to quick join penalty
	 * ServerCommand("nd_spawn_min_time 6");
	 * ServerCommand("nd_spawn_wave_interval 12");
	 */
}

/* Natives */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_WarmupCompleted", Native_GetWarmupCompleted);
	CreateNative("ND_TeamPickMode", Native_GetTeamPickMode);
	return APLRes_Success;
}

public Native_GetWarmupCompleted(Handle plugin, int numParms) {
	return _:g_Bool[warmupCompleted];
}

public Native_GetTeamPickMode(Handle plugin, int numParms) {
	return _:g_Bool[currentlyPicking];
}
