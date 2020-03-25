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
	AssaultGrenadier,
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
ConVar GrenadierIBConVars[IBLEVELS];
ConVar AssassinIBConVars[IBLEVELS];

ConVar AssassinSpeedConVar;

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
	
	AssassinSpeedConVar = AutoExecConfig_CreateConVar("sm_speed_assassin", "1.03", "Sets speed of stealth assassin class");
	
	/* Infantry boost changes to Assassin class */
	AssassinIBConVars[1] = AutoExecConfig_CreateConVar("sm_speed_ib1_assassin", "1.01", "Sets ib1 speed of assassin class");
	AssassinIBConVars[2] = AutoExecConfig_CreateConVar("sm_speed_ib2_assassin", "1.02", "Sets ib2 speed of assassin class");
	AssassinIBConVars[3] = AutoExecConfig_CreateConVar("sm_speed_ib3_assassin", "1.03", "Sets ib3 speed of assassin class");
	
	/* Infantry boost changes to Grenadier class */
	GrenadierIBConVars[1] = AutoExecConfig_CreateConVar("sm_speed_ib1_gren", "1.01", "Sets ib1 speed of grenadier class");
	GrenadierIBConVars[2] = AutoExecConfig_CreateConVar("sm_speed_ib2_gren", "1.02", "Sets ib2 speed of grenadier class");
	GrenadierIBConVars[3] = AutoExecConfig_CreateConVar("sm_speed_ib3_gren", "1.03", "Sets ib3 speed of grenadier class");
	
	/* Base & Infantry boost changes to BBQ class */
	BBQIBConVars[1] = AutoExecConfig_CreateConVar("sm_speed_ib1_bbq", "1.02", "Sets ib1 speed of bbq class");
	BBQIBConVars[2] = AutoExecConfig_CreateConVar("sm_speed_ib2_bbq", "1.04", "Sets ib2 speed of bbq class");
	BBQIBConVars[3] = AutoExecConfig_CreateConVar("sm_speed_ib3_bbq", "1.06", "Sets ib3 speed of bbq class");
	
	/* Infantry boost changes to Main Classes */	
	AssaultIBConVars[1] = AutoExecConfig_CreateConVar("sm_speed_ib1_assault", "1.02", "Sets ib1 speed of assault class");
	AssaultIBConVars[2] = AutoExecConfig_CreateConVar("sm_speed_ib2_assault", "1.04", "Sets ib1 speed of assault class");
	AssaultIBConVars[3] = AutoExecConfig_CreateConVar("sm_speed_ib3_assault", "1.06", "Sets ib1 speed of assault class");
	
	ExoIBConVars[1] = AutoExecConfig_CreateConVar("sm_speed_ib1_exo", "1.02", "Sets ib1 speed of exo class");
	ExoIBConVars[2] = AutoExecConfig_CreateConVar("sm_speed_ib2_exo", "1.04", "Sets ib2 speed of exo class");
	ExoIBConVars[3] = AutoExecConfig_CreateConVar("sm_speed_ib3_exo", "1.06", "Sets ib3 speed of exo class");
	
	StealthIBConVars[1] = AutoExecConfig_CreateConVar("sm_speed_ib1_stealth", "1.02", "Sets ib1 speed of stealth class");
	StealthIBConVars[2] = AutoExecConfig_CreateConVar("sm_speed_ib2_stealth", "1.04", "Sets ib2 speed of stealth class");
	StealthIBConVars[3] = AutoExecConfig_CreateConVar("sm_speed_ib3_stealth", "1.06", "Sets ib3 speed of stealth class");
	
	SupportIBConVars[1] = AutoExecConfig_CreateConVar("sm_speed_ib1_support", "1.02", "Sets ib1 speed of support class");
	SupportIBConVars[2] = AutoExecConfig_CreateConVar("sm_speed_ib2_support", "1.04", "Sets ib2 speed of support class");
	SupportIBConVars[3] = AutoExecConfig_CreateConVar("sm_speed_ib3_support", "1.06", "Sets ib3 speed of support class");	
	
	AutoExecConfig_EC_File();
}

/* Functions that restore varriables to default */
public void OnClientDisconnect(int client) {
	ResetVariables(client);
}
public void ND_OnRoundStart() 
{
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
	UpdateAllMovementSpeeds();
}
/*public void OnConvarChanged(ConVar convar, char[] oldValue, char[] newValue) {
	UpdateAllMovementSpeeds();
}*/
public void OnPluginEnd() {
	UpdateAllMovementSpeeds();
}
public void OnInfantryBoostResearched(int team, int level) 
{
	UpdateTeamMovementSpeeds(team);
	
	// Print a message to chat about movement speed increases
	PrintMessageTeam(team, "Movement Speed Increases");	
	
	/* Display console values for movement speed increases */
	PrintTeamSpacer(team); // Print spacer in console
	PrintConsoleTeam(team, "Movement Header Console"); // Add movement speed header	
	PrintMainClassSpeeds(team, level); // Add main class values
	PrintSubClassSpeeds(team, level); // Add sub class values
	PrintTeamSpacer(team); // Print spacer in console
}

void PrintMainClassSpeeds(int team, int level)
{
	int assault = CalcDisplaySpeed(AssaultIBConVars[level].FloatValue);
	int exo = CalcDisplaySpeed(ExoIBConVars[level].FloatValue);
	int stealth = CalcDisplaySpeed(StealthIBConVars[level].FloatValue);
	int support = CalcDisplaySpeed(SupportIBConVars[level].FloatValue);
	
	for (int m = 1; m <= MaxClients; m++)
	{
		if (IsClientInGame(m) && GetClientTeam(m) == team)
		{			
			PrintToConsole(m, "%t", "Main Speed Increase", assault, exo, stealth, support);
		}
	}
}

void PrintSubClassSpeeds(int team, int level)
{
	int assassin = CalcDisplaySpeed(AssassinIBConVars[level].FloatValue);
	int bbq = CalcDisplaySpeed(BBQIBConVars[level].FloatValue);
	int grenadier = CalcDisplaySpeed(GrenadierIBConVars[level].FloatValue);
	
	for (int s = 1; s <= MaxClients; s++)
	{
		if (IsClientInGame(s) && GetClientTeam(s) == team)
		{			
			PrintToConsole(s, "%t", "Sub Speed Increase", assassin, bbq, grenadier);
		}
	}
}

int CalcDisplaySpeed(float cValue) {
	return RoundFloat((cValue - 1.0) * 100.0);
}

void PrintTeamSpacer(int team) 
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == team)
		{
			PrintToConsole(client, "");
		}
	}
}

void UpdateAllMovementSpeeds()
{	
	for (int team = TEAM_START; team < TEAM_COUNT; team++) 
	{	
		UpdateTeamMovementSpeeds(team);
	}
}

void UpdateTeamMovementSpeeds(int team)
{
	for (int m = 0; m < view_as<int>(MovementClasses); m++)
	{
		MovementSpeedFloat[team][m] = DEFAULT_SPEED;
	}
	
	ApplyTeamMoveSpeeds(team);
}

void ApplyTeamMoveSpeeds(int team)
{
	// Calculate base movement speed increase for stealth assassin
	MovementSpeedFloat[team][move(StealthAssassin)] = AssassinSpeedConVar.FloatValue;
		
	int ibLevel = ND_GetItemResearchLevel(team, Infantry_Boost);	
	if (ibLevel >= 1)
	{		
		// Calculate new speed for assassin. Compound stealth, base and infantry boost adjustments
		MovementSpeedFloat[team][move(StealthAssassin)] *= AssassinIBConVars[ibLevel].FloatValue;
		MovementSpeedFloat[team][move(StealthAssassin)] *= StealthIBConVars[ibLevel].FloatValue;
		
		// Caculate new bbq speed. Compound support, base and infantry boost adjustments
		MovementSpeedFloat[team][move(SupportBBQ)] *= BBQIBConVars[ibLevel].FloatValue;
		MovementSpeedFloat[team][move(SupportBBQ)] *= SupportIBConVars[ibLevel].FloatValue;
		
		// Caculate new grenadier speed. Compound assault and grenadier infantry boost adjustments
		MovementSpeedFloat[team][move(AssaultGrenadier)] *= GrenadierIBConVars[ibLevel].FloatValue;
		MovementSpeedFloat[team][move(AssaultGrenadier)] *= AssaultIBConVars[ibLevel].FloatValue;
		
		// Calculate the new base speed for all classes, which don't have invidual adjustments
		MovementSpeedFloat[team][move(StealthClass)] *= StealthIBConVars[ibLevel].FloatValue;
		MovementSpeedFloat[team][move(ExoClass)] *= ExoIBConVars[ibLevel].FloatValue;
		MovementSpeedFloat[team][move(AssaultClass)] *= AssaultIBConVars[ibLevel].FloatValue;
		MovementSpeedFloat[team][move(SupportClass)] *= SupportIBConVars[ibLevel].FloatValue;
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
	
	switch (mainClass)
	{
		case MAIN_CLASS_ASSAULT:
		{
			if (subClass == ASSAULT_CLASS_GRENADIER)
				PlayerMoveSpeed[client] = MovementSpeedFloat[team][move(AssaultGrenadier)];
			else
				PlayerMoveSpeed[client] = MovementSpeedFloat[team][move(AssaultClass)];		
		}		
		
		case MAIN_CLASS_EXO: { PlayerMoveSpeed[client] = MovementSpeedFloat[team][move(ExoClass)]; }		
	
		case MAIN_CLASS_STEALTH:
		{
			if (subClass == STEALTH_CLASS_ASSASSIN)
				PlayerMoveSpeed[client] = MovementSpeedFloat[team][move(StealthAssassin)];
			else
				PlayerMoveSpeed[client] = MovementSpeedFloat[team][move(SupportClass)];	
		}
				
		case MAIN_CLASS_SUPPORT:
		{
			if (subClass == SUPPORT_CLASS_BBQ)
				PlayerMoveSpeed[client] = MovementSpeedFloat[team][move(SupportBBQ)];
			else
				PlayerMoveSpeed[client] = MovementSpeedFloat[team][move(SupportClass)];	
		}
	}
	
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
