#include <sourcemod>
#include <nextmap>
#include <nd_stocks>
#include <nd_fskill>
#include <nd_redstone>
#include <nd_rounds>
#include <nd_print>
#include <nd_maps>
#include <nd_stype>
#include <nd_gameme>

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_managed_slots/nd_managed_slots.txt"
#include "updater/standard.sp"

public Plugin myinfo =
{
	name = "[ND] Dynamic Sever Slots",
	author = "Stickz",
	description = "Controls server slots by map and reserved",
	version = "recompile",
	url = "https://github.com/stickz/Redstone/"	
};

enum convars
{
	ConVar:MaxServerSlots,
	ConVar:HighSkill,
	ConVar:LowSkill,
	ConVar:MinPlayServerSlots,
	ConVar:AfkKickSlots
};
ConVar g_Cvar[convars];

enum Integers
{
	maxKickCount,
	mapTargetPlayers
};
int g_Integer[Integers];

bool slotUsed[MAXPLAYERS + 1] = {false, ...};
bool eDynamicSlots = true;
bool pluginStarted = false;

#include "nd_slots/thresholds.sp"

public void OnPluginStart()
{
	RegAdminCmd("sm_ClampSlots", Command_ClampSlots, ADMFLAG_KICK, "Sets the server slots a specified value");

	/* Notice: Please launch server with 32 or 33 slots, this plugin will cap slots as required */	
	g_Cvar[MaxServerSlots] 		= CreateConVar("sm_serverslots_max", "32", "Set Maximum  slots");
	g_Cvar[HighSkill] 		= CreateConVar("sm_serverslots_hskill", "85", "Set the skill to decrease slots");
	g_Cvar[LowSkill] 		= CreateConVar("sm_serverslots_lskill", "65", "Set the skill to decrease slots");
	g_Cvar[MinPlayServerSlots] 	= CreateConVar("sm_serverslots_pmin", "14", "Set min amount of players to decrease slots");
	g_Cvar[AfkKickSlots]		= CreateConVar("sm_serverslots_afk", "3", "Set amount of afk players to kick from ceiling");
	
	LoadTranslations("nd_managed_slots.phrases");
	
	InitializeVariables();
	
	AutoExecConfig(true, "nd_server_slots");
	
	AddUpdaterLibrary(); //auto-updater
}

public void OnConfigsExecuted()
{
	if (!pluginStarted)
	{
		pluginStarted = true;
		ServerCommand("sm_cvar sm_afk_kick_min_players 18"); 		
	}
}

public void OnClientPutInServer(int client)
{
	if (slotUsed[client])
	{
		PrintMessage(client, "Slot Used");
		slotUsed[client] = false;
	}
}

public void OnClientAuthorized(int client)
{	
	if (!IsFakeClient(client) && GetClientCount(false) > g_Integer[maxKickCount])
	{		
		if (eDynamicSlots)
		{			
			slotUsed[client] = RED_IsDonator(client);
			if (!slotUsed[client])
			{
				KickClient(client, "%t", "Donors Only");
				return;
			}
		}
		g_Integer[maxKickCount]++;
	}
}

public void ND_OnRoundEnded()
{
	/* Delay by 2.0 seconds incase anther plugin needs to adjust the next map */
	CreateTimer(2.0, TIMER_SetNextMapCount, _, TIMER_FLAG_NO_MAPCHANGE);	
}

public Action Event_PlayerDisconnected(Event event, const char[] name, bool dontBroadcast)
{
	char steam_id[32];
	event.GetString("networkid", steam_id, sizeof(steam_id));
	
	if (strncmp(steam_id, "STEAM_", 6) == 0)
	{
		if (g_Integer[maxKickCount] > g_Integer[mapTargetPlayers])
			g_Integer[maxKickCount]--;
	}
}

public Action TIMER_SetNextMapCount(Handle timer)
{
	SetNextMapCount();
	return Plugin_Handled;
}

public Action Command_ClampSlots(int client, int args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "Ussage: !ClampSlots <count>");
		return Plugin_Handled;
	}
	
	char slot_count[64];
	GetCmdArg(1, slot_count, sizeof(slot_count));

	int slots = StringToInt(slot_count);
	
	if (slots > 32)
	{
		ReplyToCommand(client, "Error: Cannot clamp slots above 32");
		return Plugin_Handled;
	}
	
	else if (slots < 16)
	{
		ReplyToCommand(client, "Error: Cannot clamp slots bellow 16");
		return Plugin_Handled;	
	}
	
	setMapPlayerCount(slots);
	PrintToChat(client, "\x05[xG] Server slots successfully clamped!");	
	return Plugin_Handled;
}

void InitializeVariables()
{
	/*Set Integers */	
	g_Integer[maxKickCount] = 30;
	g_Integer[mapTargetPlayers] = 30;
		
	/*Set Booleans */
	for (int client = 1; client <= MaxClients; client++) {
		slotUsed[client] = false;
	}

	eDynamicSlots = true;
}

void SetNextMapCount()
{	
	char nextMap[32];
	GetNextMap(nextMap, sizeof(nextMap));	
	setMapPlayerCount(GetMapPlayerCount(nextMap));
}

void setMapPlayerCount(int cap)
{
	int newCap = cap;
		
	int maxSlots = g_Cvar[MaxServerSlots].IntValue;
	
	if (newCap > maxSlots)
		newCap = maxSlots;
		
	g_Integer[maxKickCount] = g_Integer[maxKickCount] > newCap ? g_Integer[maxKickCount] : newCap;
	g_Integer[mapTargetPlayers] = newCap;	
	ServerCommand("sv_visiblemaxplayers %d", newCap);
	ServerCommand("sm_cvar sm_afk_kick_min_players %d", newCap - g_Cvar[AfkKickSlots].IntValue); 
}

/* Natives */
functag NativeCall public(Handle:plugin, numParams);

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ToggleDynamicSlots", Native_ToggleDynamicSlots);
	CreateNative("GetDynamicSlotStatus", Native_GetDynamicSlotStatus);
	CreateNative("GetDynamicSlotCount", Native_GetDynamicSlotCount);
	return APLRes_Success;
}

public Native_ToggleDynamicSlots(Handle plugin, int numParams)
{
	bool state = GetNativeCell(1);
	ServerCommand("sv_visiblemaxplayers %d", state ? g_Integer[mapTargetPlayers] : 32);
	eDynamicSlots = state;
	return;
}

public Native_GetDynamicSlotCount(Handle plugin, int numParams) {
	return _:g_Integer[mapTargetPlayers];
}

public Native_GetDynamicSlotStatus(Handle plugin, int numParams) {
	return _:eDynamicSlots;
}
