#include <sourcemod>
#include <sdkhooks>
#include <nd_classes>
#include <nd_rounds>
#include <nd_stocks>
#include <nd_research_eng>
#include <nd_print>

// Bug: "m_flLaggedMovementValue" is reset if a player change class fails
// Continuously leaving the pre-hook think running doesn't change anything.
// This is resimulated by changing class on the hud away from the armory

// To Do: Figure out why setting movement speed on change class doesn't work.
// It could have something to do the "m_iPlayerClass" and "m_iDesiredPlayerClass"
// prop integers. Extensive debugging is required to resolve this issue.

public Plugin myinfo =
{
	name = "[ND] Player Speed",
	author = "Stickz",
	description = "Adjusts player movement speeds",
	version = "dummy",
	url = "https://github.com/stickz/Redstone/"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_player_speed/nd_player_speed.txt"
#include "updater/standard.sp"

#define IBLEVELS 4
#define DEFAULT_SPEED 1.0

enum MovementClasses {
	StealthAssassin,
	SupportBBQ,
	StealthClass
};
public int move(MovementClasses mc) {
	return view_as<int>(mc);
}

ConVar InfantryBoostConVars[IBLEVELS];
ConVar AssassinSpeedConVar;
ConVar BBQSpeedConVar;

float MovementSpeedFloat[TEAM_COUNT][MovementClasses];

bool HookedThink[MAXPLAYERS+1] = {false, ...};
float PlayerMoveSpeed[MAXPLAYERS+1] = {1.0, ...};
bool FirstThink[MAXPLAYERS+1] = {false, ...};

bool FirstAssassinSpawn[MAXPLAYERS+1] = {false, ...};
bool FirstBBQSpawn[MAXPLAYERS+1] = {false, ...};

public void OnPluginStart()
{
	// Don't hook convar change for now. It disables the players movement speed. This feature is optional.
	
	AssassinSpeedConVar = CreateConVar("sm_speed_assassin", "1.06", "Sets speed of stealth assassin class");
	//AssassinSpeedConVar.AddChangeHook(OnConvarChanged);
	
	BBQSpeedConVar = CreateConVar("sm_speed_bbqkit", "1.06", "Sets speed of bbq kit class");
	//BBQSpeedConVar.AddChangeHook(OnConvarChanged);
	
	InfantryBoostConVars[1] = CreateConVar("sm_speed_ib1_stealth", "1.02", "Sets ib1 speed of stealth class");
	InfantryBoostConVars[2] = CreateConVar("sm_speed_ib2_stealth", "1.04", "Sets ib2 speed of stealth class");
	InfantryBoostConVars[3] = CreateConVar("sm_speed_ib3_stealth", "1.06", "Sets ib3 speed of stealth class");	
	
	/*for (int i = 1; i < IBLEVELS; i++) {
		InfantryBoostConVars[i].AddChangeHook(OnConvarChanged);
	}*/
	
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_PostNoCopy);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_PostNoCopy);
	HookEvent("player_changeclass", OnPlayerChangeClass, EventHookMode_Post);
	
	LoadTranslations("nd_player_speed.phrases");		
	AddUpdaterLibrary(); //auto-updater
}

/* Functions that update team movement speeds */
public void OnConfigsExecuted() {
	UpdateMovementSpeeds();
}
/*public void OnConvarChanged(ConVar convar, char[] oldValue, char[] newValue) {
	UpdateMovementSpeeds();	
}*/
public void OnPluginEnd() {
	UpdateMovementSpeeds();
}
public void OnInfantryBoostResearched(int team, int level) 
{
	UpdateTeamMoveSpeeds(team);
	PrintMessageAllTI1("Stealth Speed Increase", level * 2);
}
void UpdateMovementSpeeds()
{	
	for (int team = TEAM_START; team < TEAM_COUNT; team++) {	
		UpdateTeamMoveSpeeds(team);
	}
}
void UpdateTeamMoveSpeeds(int team)
{
	MovementSpeedFloat[team][move(SupportBBQ)] = BBQSpeedConVar.FloatValue;
	MovementSpeedFloat[team][move(StealthAssassin)] = AssassinSpeedConVar.FloatValue;
	MovementSpeedFloat[team][move(StealthClass)] = DEFAULT_SPEED;	
		
	int ibLevel = ND_GetItemResearchLevel(team, Infantry_Boost);	
	if (ibLevel >= 1)
	{
		MovementSpeedFloat[team][move(StealthAssassin)] *= InfantryBoostConVars[ibLevel].FloatValue;
		MovementSpeedFloat[team][move(StealthClass)] *= InfantryBoostConVars[ibLevel].FloatValue;
	}
	
	DisableTeamMoveSpeeds(team);
}
void DisableTeamMoveSpeeds(int team)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client, false) && GetClientTeam(client) == team)
		{
			DisableMovementSpeed(client);			
		}
	}
}

/* Functions that set current client movement speeds */
public void OnPreThinkPost_Movement(int client)
{
	if (IsClientInGame(client))
	{
		// Only think once, then immediately unhook for performance reasons.
		// "m_flLaggedMovementValue" only needs set once before the first think
		if (!FirstThink[client])
		{
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", PlayerMoveSpeed[client]);
			FirstThink[client] = true;		
		}
		else
		{
			FirstThink[client] = false;		
			SDKUnhook(client, SDKHook_PreThinkPost, OnPreThinkPost_Movement);
		}
	}
}

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	// Hook the think event for the client and set their movement speed
	int client = GetClientOfUserId(event.GetInt("userid"));	
	NotifyMoveIncrease(client);
	
	if (UpdateMovementSpeed(client))
	{
		SDKHook(client, SDKHook_PreThinkPost, OnPreThinkPost_Movement);
		HookedThink[client] = true;
	}
}

bool UpdateMovementSpeed(int client)
{
	int mainClass = ND_GetMainClass(client);
	int subClass = ND_GetSubClass(client);
	int team = GetClientTeam(client);
	
	if (IsStealthAss(mainClass, subClass))
		PlayerMoveSpeed[client] = MovementSpeedFloat[team][move(StealthAssassin)];
	
	else if (IsSupportBBQ(mainClass, subClass))
		PlayerMoveSpeed[client] = MovementSpeedFloat[team][move(SupportBBQ)];

	else if (IsStealthClass(mainClass))
		PlayerMoveSpeed[client] = MovementSpeedFloat[team][move(StealthClass)];
	
	return PlayerMoveSpeed[client] != DEFAULT_SPEED;
}

void NotifyMoveIncrease(int client)
{
	int mainClass = ND_GetMainClass(client);
	int subClass = ND_GetSubClass(client);
	if (!FirstAssassinSpawn[client] && IsStealthAss(mainClass, subClass))
	{
		PrintMessage(client, "Assassin Speed Increase");
		FirstAssassinSpawn[client] = true;
	}
	
	else if (!FirstBBQSpawn[client] && IsSupportBBQ(mainClass, subClass))
	{
		PrintMessage(client, "BBQ Speed Increase");
		FirstBBQSpawn[client] = true;
	}
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	// Unhook the think event for the client and reset movement speed
	int client = GetClientOfUserId(event.GetInt("userid"));	
	if (HookedThink[client])
	{
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", DEFAULT_SPEED);
		PlayerMoveSpeed[client] = DEFAULT_SPEED;
		HookedThink[client] = false;
	}	
}

public Action OnPlayerChangeClass(Event event, const char[] name, bool dontBroadcast)
{
	// Unhook the think event for the client and disable movement speed
	DisableMovementSpeed(GetClientOfUserId(event.GetInt("userid")));
}

// Changing movement speed breaks if done while the player is alive, so disable it for now.
void DisableMovementSpeed(int client)
{		
	// Speed setting breaks if this is fired while the client is dead.
	// The speed is set after they spawn, so doing this is not required.
	if (IsPlayerAlive(client))
	{
		if (HookedThink[client])
		{	
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", DEFAULT_SPEED);
			PlayerMoveSpeed[client] = DEFAULT_SPEED;
			HookedThink[client] = false;
		}		
	}
}
