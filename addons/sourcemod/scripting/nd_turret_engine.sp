#include <sourcemod>
#include <nd_stocks>
#include <nd_structures>
#include <nd_rounds>

public Plugin myinfo = 
{
	name 		= "[ND] Turret Engine",
	author 		= "Stickz",
	description 	= "Creates forwards and natives for turret events",
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
void increment(Event ev) 
{
	totalTurrets++;
	turretCount[ev.GetInt("team")]++;
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
	HookEvent("commander_start_structure_build", Event_StructBuildStarted);
	AddUpdaterLibrary();
}
public Action Event_StructBuildStarted(Event event, const char[] name, bool dontBroadcast)
{
	switch (event.GetInt("type"))
	{
		case view_as<int>(MG_Turret): 		increment(event);
		case view_as<int>(FT_Turret):	 	increment(event);	
		case view_as<int>(Sonic_Turret):	increment(event);
		case view_as<int>(Rocket_Turret):	increment(event);
	}
}
public Action Event_BuildingDeath(Event event, const char[] name, bool dontBroadcast) {
	DoStructureRemoved(event, "team");
}

public Action Event_BuildingSold(Event event, const char[] name, bool dontBroadcast) {
	DoStructureRemoved(event, "ownerteam");
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
