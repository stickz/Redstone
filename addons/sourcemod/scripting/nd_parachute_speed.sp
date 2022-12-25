#include <sourcemod>
#include <nd_parachute>
#include <nd_rounds>
#include <nd_research_eng>
#include <nd_print>
#include <autoexecconfig>

// Note: Parachute speeds automatically reset on map change
public Plugin myinfo =
{
	name = "[ND] Parachute Speed",
	author = "Stickz",
	description = "Modifies parachute fall speed based on infantry boosts",
	version = "dummy",
	url = "https://github.com/stickz/Redstone/"
};

/* Auto Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_parachute_speed/nd_parachute_speed.txt"
#include "updater/standard.sp"

#define IBLEVELS 4

ConVar ParaSpeedIBConVars[IBLEVELS];

public void OnPluginStart()
{
	LoadTranslations("nd_parachute_speed.phrases");
	
	AutoExecConfig_Setup("nd_parachute_speed");
	
	ParaSpeedIBConVars[1] = AutoExecConfig_CreateConVar("sm_para_speed_ib1", "1.20", "Sets ib1 parachute fall speed for all classes");
	ParaSpeedIBConVars[2] = AutoExecConfig_CreateConVar("sm_para_speed_ib2", "1.40", "Sets ib2 parachute fall speed for all classes");
	ParaSpeedIBConVars[3] = AutoExecConfig_CreateConVar("sm_para_speed_ib3", "1.60", "Sets ib3 parachute fall speed for all classes");
	
	AutoExecConfig_EC_File();
	
	AddUpdaterLibrary(); // Add updater support
}

// Increase the parachute fall speed each time an infantry boost is researched
public void OnInfantryBoostResearched(int team, int level) 
{
	// Calculate the new speed based on the default speed * convar increase
	int defaultSpeed = ND_GetDefaultParaSpeed();
	float cIncrease = ParaSpeedIBConVars[level].FloatValue;
	float newSpeed = float(defaultSpeed) * cIncrease;
	
	// Set the new parachute speed for all the clients
	for (int client = 1; client <= MaxClients; client++) {
		ND_SetParachuteSpeed(client, newSpeed);
	}
	
	// Print a message to the team about the parachute speed increase
	int increase = RoundFloat((cIncrease - 1.0) * 100.0);
	PrintMessageTeamTI1(team, "Parachute Speed Increase", increase);
}

// Reset the parachute fall speed if the round is restarted
public void ND_OnRoundStarted() 
{
	int defaultSpeed = ND_GetDefaultParaSpeed();
	for (int client = 1; client <= MaxClients; client++) {
		ND_SetParachuteSpeed(client, float(defaultSpeed));
	}
}
