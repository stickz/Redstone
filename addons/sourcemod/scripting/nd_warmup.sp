#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <nd_maps>
#include <nd_rounds>
#include <nd_redstone>

#define VALUE_TYPE_ENABLED 1
#define VALUE_TYPE_DISABLED 0

#define RAPID_START 15

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

enum struct Integers
{
	int warmupCountdown;
	int warmupTextType;
}

enum struct Convars
{
	ConVar stockWarmupTime;
	ConVar customWarmupTime;
	ConVar rapidStartClientCount;
	ConVar funFeaturesClientCount;
}

bool warmupCompleted;
int enableFunFeatures = VALUE_TYPE_DISABLED;

Integers g_Integer;
Convars g_Cvar;

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
	
	StartWarmupRound();
}

public void ND_OnRoundStarted() {
	ToogleWarmupConvars(VALUE_TYPE_DISABLED);
}

public void ND_OnRoundEnded() 
{
	enableFunFeatures = ND_GetClientCount() >= g_Cvar.funFeaturesClientCount.IntValue ? VALUE_TYPE_ENABLED : VALUE_TYPE_DISABLED;
	ToogleWarmupConvars(VALUE_TYPE_ENABLED);
}

public Action TIMER_WarmupRound(Handle timer)
{
	g_Integer.warmupCountdown--;

	switch (g_Integer.warmupCountdown)
	{
		// Notice: These hacks assume short circuit evaluation is used.
		case RAPID_START:
		{
			if (CheckRapidStart())
				return Plugin_Stop;
		}		
		
		//case 4: ServerCommand("bot_quota 0");		
		case 3: g_Integer.warmupTextType = 1;
		
		case 1: 
		{
			FireWarmupCompleteForward();
			return Plugin_Stop;
		}
	}
	
	DisplayHudText();
	return Plugin_Continue;
}

bool CheckRapidStart()
{
	// Get the client count on the server. Try Redstone native first.
	// If the client count is within range, start the game faster
	if (ND_GetClientCount() <= g_Cvar.rapidStartClientCount.IntValue)
	{
		FireWarmupCompleteForward();
		return true;				
	}
	
	return false;
}

void CreatePluginConvars()
{
	g_Cvar.stockWarmupTime			=	CreateConVar("sm_warmup_rtime", "40", "Sets the warmup time for stock maps");
	g_Cvar.customWarmupTime			=	CreateConVar("sm_warmup_ctime", "55", "Sets the warmup time for custom maps");
	g_Cvar.rapidStartClientCount	=	CreateConVar("sm_warmup_rscc", "4", "Sets the number of players for rapid starting");
	g_Cvar.funFeaturesClientCount 	=	CreateConVar("sm_warmup_ffcc", "8", "Sets the number of players for fun features");
	
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
			
			switch (g_Integer.warmupTextType)
			{
				case 0, 1: Format(hudTXT, sizeof(hudTXT), "%T", "Waiting", idx);
				case 2: Format(hudTXT, sizeof(hudTXT), "%T...", "Please Wait", idx);
			}
	
			ShowSyncHudText(idx, HudText, "%s",hudTXT);
		}		
					
	CloseHandle(HudText);
}

void FireWarmupCompleteForward()
{
	warmupCompleted = true;
	
	Action dummy;
	Call_StartForward(g_OnWarmupCompleted);
	Call_Finish(dummy);
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
	g_Integer.warmupCountdown = ND_IsCustomMap(currentMap) ? g_Cvar.customWarmupTime.IntValue : g_Cvar.stockWarmupTime.IntValue;
}

void SetVarDefaults()
{
	warmupCompleted = false;
	g_Integer.warmupTextType = 0;
}

void ToogleWarmupConvars(int value)
{	
	// Only enable these if enough players are connected
	value = value == VALUE_TYPE_ENABLED ? enableFunFeatures : VALUE_TYPE_DISABLED;
	
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
	return APLRes_Success;
}

public int Native_GetWarmupCompleted(Handle plugin, int numParms) {
	return warmupCompleted;
}
