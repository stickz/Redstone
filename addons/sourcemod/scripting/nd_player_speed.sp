#include <sourcemod>
#include <sdkhooks>
#include <nd_classes>
#include <nd_rounds>
#include <nd_stocks>
#include <nd_print>
#include <nd_research_eng>
#include <autoexecconfig>

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
	StealthClass,
	ExoClass,
	AssaultClass,
	SupportClass
};
public int move(MovementClasses mc) {
	return view_as<int>(mc);
}

ConVar AssaultIBConVars[IBLEVELS];
ConVar ExoIBConVars[IBLEVELS];
ConVar SupportIBConVars[IBLEVELS];
ConVar StealthIBConVars[IBLEVELS];
ConVar BBQIBConVars[IBLEVELS];

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
	CreatePluginConVars();
	
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_PostNoCopy);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_PostNoCopy);
	HookEvent("player_changeclass", OnPlayerChangeClass, EventHookMode_Post);
	
	LoadTranslations("nd_player_speed.phrases");		
	AddUpdaterLibrary(); //auto-updater
}

void CreatePluginConVars()
{	
	AutoExecConfig_Setup("nd_player_speed");
	
	AssassinSpeedConVar = AutoExecConfig_CreateConVar("sm_speed_assassin", "1.06", "Sets speed of stealth assassin class");	
	
	/ * Base & Infantry boost changes to BBQ class */
	BBQSpeedConVar = AutoExecConfig_CreateConVar("sm_speed_bbqkit", "1.03", "Sets speed of bbq kit class");		
	BBQIBConVars[1] = AutoExecConfig_CreateConVar("sm_speed_ib1_bbq", "1.01", "Sets ib1 speed of bbq class");
	BBQIBConVars[2] = AutoExecConfig_CreateConVar("sm_speed_ib2_bbq", "1.02", "Sets ib2 speed of bbq class");
	BBQIBConVars[3] = AutoExecConfig_CreateConVar("sm_speed_ib3_bbq", "1.03", "Sets ib3 speed of bbq class");
	
	/* Infantry boost changes to Main Classes */	
	AssaultIBConVars[1] = AutoExecConfig_CreateConVar("sm_speed_ib1_assault", "1.02", "Sets ib1 speed of assault class");
	AssaultIBConVars[2] = AutoExecConfig_CreateConVar("sm_speed_ib1_assault", "1.04", "Sets ib1 speed of assault class");
	AssaultIBConVars[3] = AutoExecConfig_CreateConVar("sm_speed_ib1_assault", "1.06", "Sets ib1 speed of assault class");
	
	ExoIBConVars[1] = AutoExecConfig_CreateConVar("sm_speed_ib1_exo", "1.02", "Sets ib1 speed of exo class");
	ExoIBConVars[2] = AutoExecConfig_CreateConVar("sm_speed_ib2_exo", "1.04", "Sets ib2 speed of exo class");
	ExoIBConVars[3] = AutoExecConfig_CreateConVar("sm_speed_ib3_exo", "1.06", "Sets ib3 speed of exo class");
	
	StealthIBConVars[1] = AutoExecConfig_CreateConVar("sm_speed_ib1_stealth", "1.02", "Sets ib1 speed of stealth class");
	StealthIBConVars[2] = AutoExecConfig_CreateConVar("sm_speed_ib2_stealth", "1.04", "Sets ib2 speed of stealth class");
	StealthIBConVars[3] = AutoExecConfig_CreateConVar("sm_speed_ib3_stealth", "1.06", "Sets ib3 speed of stealth class");
	
	SupportIBConVars[1] = AutoExecConfig_CreateConVar("sm_speed_ib1_stealth", "1.02", "Sets ib1 speed of support class");
	SupportIBConVars[2] = AutoExecConfig_CreateConVar("sm_speed_ib2_stealth", "1.04", "Sets ib2 speed of support class");
	SupportIBConVars[3] = AutoExecConfig_CreateConVar("sm_speed_ib3_stealth", "1.06", "Sets ib3 speed of support class");	
	
	AutoExecConfig_EC_File();
}

/* Functions that restore varriables to default */
public void OnClientDisconnect(int client) {
	ResetVariables(client);
}
public void ND_OnRoundStart() {
	for (int client = 0; client <= MAXPLAYERS; client++) 
		ResetVariables(client);
}
void ResetVariables(int client)
{
	FirstAssassinSpawn[client] = false;
	FirstBBQSpawn[client] = false;
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
	
	PrintMessageTeam(team, "Movement Speed Increases");
	
	/* Print messages for infantry and bbq speed increases to console */
	PrintSpeedIncrease(team, "Assault Speed Increase", AssaultIBConVars[level].FloatValue);
	PrintSpeedIncrease(team, "Exo Speed Increase", ExoIBConVars[level].FloatValue);
	PrintSpeedIncrease(team, "Stealth Speed Increase", StealthIBConVars[level].FloatValue);
	PrintSpeedIncrease(team, "Support Speed Increase", SupportIBConVars[level].FloatValue);
	PrintSpeedIncrease(team, "BBQ Speed Increase", BBQIBConVars[level].FloatValue);
}

void PrintSpeedIncrease(int team, char[] phrase, float cValue)
{
	int speed = RoundFloat((cValue - 1.0) * 100.0);
	PrintConsoleTeamTI1(team, phrase, speed);
}

void UpdateMovementSpeeds()
{	
	for (int team = TEAM_START; team < TEAM_COUNT; team++) 
	{	
		for (int m = 0; m < view_as<int>(MovementClasses); m++)
		{
			MovementSpeedFloat[team][m] = DEFAULT_SPEED;
		}
		
		UpdateTeamMoveSpeeds(team);
	}
}

void UpdateTeamMoveSpeeds(int team)
{
	MovementSpeedFloat[team][move(SupportBBQ)] = BBQSpeedConVar.FloatValue;
	MovementSpeedFloat[team][move(StealthAssassin)] = AssassinSpeedConVar.FloatValue;
		
	int ibLevel = ND_GetItemResearchLevel(team, Infantry_Boost);	
	if (ibLevel >= 1)
	{
		MovementSpeedFloat[team][move(StealthAssassin)] *= StealthIBConVars[ibLevel].FloatValue;
		MovementSpeedFloat[team][move(StealthClass)] *= StealthIBConVars[ibLevel].FloatValue;
		MovementSpeedFloat[team][move(ExoClass)] *= ExoIBConVars[ibLevel].FloatValue;
		MovementSpeedFloat[team][move(AssaultClass)] *= AssaultIBConVars[ibLevel].FloatValue;
		MovementSpeedFloat[team][move(SupportClass)] *= SupportIBConVars[ibLevel].FloatValue;
		
		// Caculate the new bbq speed. Compound support, base and infantry boost adjustments
		MovementSpeedFloat[team][move(SupportBBQ)] *= BBQIBConVars[ibLevel].FloatValue;
		MovementSpeedFloat[team][move(SupportBBQ)] *= SupportIBConVars[ibLevel].FloatValue;		
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
			FirstAssassinSpawn[client] = false;
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
		
	else if (IsExoClass(mainClass))
		PlayerMoveSpeed[client] = MovementSpeedFloat[team][move(ExoClass)];	
	
	else if (IsAssaultClass(mainClass))
		PlayerMoveSpeed[client] = MovementSpeedFloat[team][move(AssaultClass)];
		
	else if (IsSupportClass(mainClass))
		PlayerMoveSpeed[client] = MovementSpeedFloat[team][move(SupportClass)];
	
	return PlayerMoveSpeed[client] != DEFAULT_SPEED;
}

void NotifyMoveIncrease(int client)
{
	int mainClass = ND_GetMainClass(client);
	int subClass = ND_GetSubClass(client);
	if (!FirstAssassinSpawn[client] && IsStealthAss(mainClass, subClass))
	{
		int aSpeed = RoundFloat((1.0 - AssassinSpeedConVar.FloatValue) * 100.0);
		PrintMessageTI1(client, "Recent Assassin Speed", aSpeed);
		FirstAssassinSpawn[client] = true;
	}
	
	else if (!FirstBBQSpawn[client] && IsSupportBBQ(mainClass, subClass))
	{
		int bSpeed = RoundFloat((1.0 - BBQSpeedConVar.FloatValue) * 100.0);
		PrintMessageTI1(client, "Recent BBQ Speed", bSpeed);
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
