#include <sourcemod>
#include <nd_structures>

public Plugin myinfo = 
{
	name 		= "[ND] Structure Engine",
	author 		= "Stickz",
	description = "Creates forwards and natives for structure events",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_structure_engine/nd_structure_engine.txt"
#include "updater/standard.sp"

Handle OnStructBuildStarted[ND_Structures];

char fName[ND_Structures][64] = {
	"OnBuildStarted_Bunker",
	"OnBuildStarted_MGTurret",
	"OnBuildStarted_TransportGate",
	"OnBuildStarted_PowerPlant",
	"OnBuildStarted_WirelessRepeater",
	"OnBuildStarted_RelayTower",
	"OnBuildStarted_SupplyStation",
	"OnBuildStarted_Assembler",
	"OnBuildStarted_Armory",
	"OnBuildStarted_Artillery",
	"OnBuildStarted_RadarStation",
	"OnBuildStarted_FlameTurret",
	"OnBuildStarted_SonicTurret",
	"OnBuildStarted_RocketTurret",
	"OnBuildStarted_Wall",
	"OnBuildStarted_Barrier"
};

public void OnPluginStart()
{
	CreateBuildStartForwards(); // Create structure forwards
	HookEvent("commander_start_structure_build", Event_StructureBuildStarted);
	AddUpdaterLibrary(); // Add auto updater feature
}

public Action Event_StructureBuildStarted(Event event, const char[] name, bool dontBroadcast) {
	FireStructBuildForward(event.GetInt("type"), event.GetInt("team"));	
}

void FireStructBuildForward(int type, int team)
{
	Action dummy;
	Call_StartForward(OnStructBuildStarted[type]);
	Call_PushCell(team);
	Call_Finish(dummy);
}

void CreateBuildStartForwards()
{
	for (int idx = 0; idx < view_as<int>(ND_Structures); idx++) {
		OnStructBuildStarted[idx] = CreateGlobalForward(fName[idx], ET_Ignore, Param_Cell);		
	}	
}