#include <sourcemod>
#include <nd_stocks>
#include <nd_maps>
#include <nd_shuffle>
#include <nd_rounds>
#include <nd_redstone>

#define VALUE_TYPE_ENABLED 1
#define VALUE_TYPE_DISABLED 0

#define TIME_RAPID_START 15

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
	pauseWarmup
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

public void OnPluginStart()
{
	LoadTranslations("nd_warmup.phrases");
	
	CreatePluginConvars();
	
	RegAdminCmd("sm_NextPick", CMD_TriggerPicking, ADMFLAG_RESERVATION, "enable/disable picking for next map");
	
	g_Bool[pauseWarmup] = false;
	
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

public void ND_OnRoundStarted()
{
	if (g_Bool[pauseWarmup])
		ServerCommand("sm_cvar mp_friendlyfire 0");	

	else
		ToogleWarmupConvars(VALUE_TYPE_DISABLED);
}

public Action TIMER_WarmupRound(Handle timer)
{
	g_Integer[warmupCountdown]--;

	switch (g_Integer[warmupCountdown])
	{
		case TIME_RAPID_START:
		{
			// Get the client count on the server. Try Redstone native first.
			int clientCount = RED_CC_AVAILABLE() ? RED_ClientCount() : ValidClientCount(); 	

			// If the client count is within range, start the game faster
			if (clientCount <= g_Cvar[rapidStartClientCount].IntValue)
			{
				SetWarmupEndType();
				return Plugin_Stop;				
			}
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

/* Toggle player picking mode */
public Action CMD_TriggerPicking(int client, int args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: !NextPick <on or off>");
		return Plugin_Handled;	
	}
	
	char arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	char Name[32];
	GetClientName(client, Name, sizeof(Name));	
		
	if (StrEqual(arg1, "on", false))
	{
		g_Bool[pauseWarmup] = true;
		PrintToChatAll("\x05%s triggered picking game(s) next map!", Name);		
	}
	
	else if (StrEqual(arg1, "off", false))
	{
		g_Bool[pauseWarmup] = false;
		PrintToChatAll("\x05%s triggered regular game(s) next map!", Name);		
	}
	
	else
	{
		ReplyToCommand(client, "[SM] Usage: !NextPick <on or off>");
		return Plugin_Handled;	
	}
		
	return Plugin_Handled;	
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
	if (g_Bool[pauseWarmup])
	{
		ServerCommand("sm_cvar sv_alltalk 0"); //Disable AT while picking, but enable FF.
		ServerCommand("sm_balance 0");
		PrintToAdmins("\x05[xG] Team Picking is now availible!", "b");		
		
		return;
	}
			
	/* Start Round using team balancer if applicable */		
	else if (RunWarmupBalancer())
		WB2_BalanceTeams();
			
	/* Otherwise, Start the Round normally */			
	else 
		StartRound();
		
	ServerCommand("sm_balance 1");
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
