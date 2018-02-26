#include <sourcemod>
#include <nd_stocks>
#include <nd_struct_eng>
#include <nd_rounds>

public Plugin myinfo = 
{
	name 		= "[ND] Turret Counter",
	author 		= "Stickz",
	description 	= "Counts the number of turrets on the battlefield",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_turret_engine/nd_turret_engine.txt"
#include "updater/standard.sp"

/* Variable management */
int totalTurrets = 0;
int turretCount[TEAM_COUNT] = { 0, ... };

public void ND_OnRoundStarted() {
	resetVars();
}
public void OnMapEnd() {
	resetVars();
}
void resetVars()
{
	totalTurrets = 2;
	
	for (int team = 0; team < TEAM_COUNT; team++)
		turretCount[team] = 1;
}
void increment(int team) 
{
	totalTurrets++;
	turretCount[team]++;
}
void deincrement(Event ev, const char[] teamName)
{
	totalTurrets--;
	turretCount[ev.GetInt(teamName)]--;
}
void DoStructureRemoved(Event ev, const char[] teamName)
{
	switch (ev.GetInt("type"))
	{
		case view_as<int>(MG_Turret):		deincrement(ev, teamName);
		case view_as<int>(FT_Turret):		deincrement(ev, teamName);
		case view_as<int>(Sonic_Turret):	deincrement(ev, teamName);
		case view_as<int>(Rocket_Turret):	deincrement(ev, teamName);
	}
}

/* Event Management */
public void OnPluginStart() 
{
	HookEvent("structure_sold", Event_BuildingSold);
	HookEvent("structure_death", Event_BuildingDeath);
	AddUpdaterLibrary();
}

public Action Event_BuildingDeath(Event event, const char[] name, bool dontBroadcast) {
	DoStructureRemoved(event, "team");
}
public Action Event_BuildingSold(Event event, const char[] name, bool dontBroadcast) {
	DoStructureRemoved(event, "ownerteam");
}

/* Increment turret count when one is built */
public void OnBuildStarted_MGTurret(int team) {
	increment(team);
}
public void OnBuildStarted_FlameTurret(int team) {
	increment(team);
}
public void OnBuildStarted_SonicTurret(int team) {
	increment(team);
}
public void OnBuildStarted_RocketTurret(int team) {
	increment(team);
}

/* Native Management */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_GetTurretCount", Native_GetTurretCount);
	CreateNative("ND_GetTeamTurretCount", Native_GetTeamTurretCount);	
	return APLRes_Success;
}
public int Native_GetTurretCount(Handle plugin, int numParams) {
	return totalTurrets;
}
public int Native_GetTeamTurretCount(Handle plugin, int numParams){
	// Return the turret count for the inputted team
	return turretCount[GetNativeCell(1)];
}
