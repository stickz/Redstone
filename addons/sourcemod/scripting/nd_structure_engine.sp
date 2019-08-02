#include <sourcemod>
#include <nd_structures>

// sdk hooks function. Only forward the required function
forward void OnEntityCreated(int entity, const char[] classname);

public Plugin myinfo = 
{
	name 		= "[ND] Structure Engine",
	author 		= "Stickz",
	description 	= "Creates forwards and natives for structure events",
	version 	= "recompile",
	url 		= "https://github.com/stickz/Redstone/"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_structure_engine/nd_structure_engine.txt"
#include "updater/standard.sp"

bool FirstStructurePlaced[2] = { false, ... };

Handle OnStructBuildStarted[ND_Structures];
Handle OnStructCreated;

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
	HookEvent("round_win", Event_RoundEnd, EventHookMode_PostNoCopy);
	AddUpdaterLibrary(); // Add auto updater feature
}

public Action Event_StructureBuildStarted(Event event, const char[] name, bool dontBroadcast) 
{
	// Mark first structure placed
	int team = event.GetInt("team");
	FirstStructurePlaced[team -2] = true;
	
	// Add fire the structure build forward
	FireStructBuildForward(event.GetInt("type"), team);	
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) 
{
	FirstStructurePlaced[0] = false;
	FirstStructurePlaced[1] = false;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (strncmp(classname, "struct_", 7) == 0)
		FireStructCreatedForward(entity, classname);	
}

void FireStructCreatedForward(int entity, const char[] classname)
{
	Action dummy;
	Call_StartForward(OnStructCreated);
	Call_PushCell(entity);
	Call_PushString(classname);
	Call_Finish(dummy);
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
	
	OnStructCreated = CreateGlobalForward("ND_OnStructureCreated", ET_Ignore, Param_Cell, Param_String);	
}

/* Natives */
typedef NativeCall = function int (Handle plugin, int numParams);

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_FirstStructurePlaced", Native_GetFirstStructurePlaced);
	return APLRes_Success;
}

public int Native_GetFirstStructurePlaced(Handle plugin, int numParams)
{
	int team = GetNativeCell(1);
	return FirstStructurePlaced[team -2];
}
