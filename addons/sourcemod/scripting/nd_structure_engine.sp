#include <sourcemod>
#include <nd_structures>

// sdk hooks function. Only forward the required function
forward void OnEntityCreated(int entity, const char[] classname);

public Plugin myinfo = 
{
	name 		= "[ND] Structure Engine",
	author 		= "Stickz",
	description 	= "Creates forwards and natives for structure events",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};


#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_structure_engine/nd_structure_engine.txt"
#include "updater/standard.sp"

bool FirstStructurePlaced[2] = { false, ... };

Handle OnStructBuildStarted[ND_StructCount];
Handle OnStructCreated;

enum struct BuildingEntity
{
      int entIndex;
      int type;
      char classname[32];
      float vecPos[3];
      
      int initByIndex(int index) {
            this.entIndex = index;
            GetEntityClassname(index, this.classname, sizeof(this.classname));
            GetEntPropVector(index, Prop_Send, "m_vecOrigin", this.vecPos);
            this.type = ND_GetStructIndex(this.classname);
            return 0;
      }
}

ArrayList BuildEntStructs;
ArrayList BuildEntStructsEx[ND_StructCount];

char fName[ND_StructCount][64] = {
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
	HookEvent("structure_death", Event_StructureDeath);
	HookEvent("round_win", Event_RoundEnd, EventHookMode_PostNoCopy);
	
	BuildEntStructs = new ArrayList(sizeof(BuildingEntity));
	
	for (int i = 0; i < view_as<int>(ND_StructCount); i++) {
	          BuildEntStructsEx[i] = new ArrayList(sizeof(BuildingEntity));
	}
	
	AddUpdaterLibrary(); // Add auto updater feature
}

public void OnMapEnd() {
        PerformCleanup();
}

public Action Event_StructureBuildStarted(Event event, const char[] name, bool dontBroadcast) 
{
	// Mark first structure placed
	int team = event.GetInt("team");
	FirstStructurePlaced[team -2] = true;
	
	// Add fire the structure build forward
	FireStructBuildForward(event.GetInt("type"), team);
	return Plugin_Continue;
}

public Action Event_StructureDeath(Event event, const char[] name, bool dontBroadcast)
{
        int entIndex = event.GetInt("entindex");
        int typeIndex = event.GetInt("type");
        int arrIndex = FindStructureIndex(entIndex);
        int arrIndexEx = FindStructureIndexEx(typeIndex, entIndex);
        
        // Remove the entity index reference
        if (arrIndex != -1)
                BuildEntStructs.Erase(arrIndex);
                
        if (arrIndexEx != -1)
                BuildEntStructsEx[typeIndex].Erase(arrIndexEx);
  
        return Plugin_Continue;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) 
{
	PerformCleanup();	
	return Plugin_Continue;
}

public Action TIMER_InitBuildEntStructs(Handle timer, int entity)
{
	if (!HasEntProp(entity, Prop_Send, "m_vecOrigin"))
	        return Plugin_Handled;
	
	BuildingEntity ent;
	ent.initByIndex(entity);
	BuildEntStructs.PushArray(ent);
	BuildEntStructsEx[ent.type].PushArray(ent);
	return Plugin_Handled;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (strncmp(classname, "struct_", 7) == 0)
	{
	        FireStructCreatedForward(entity, classname);
		CreateTimer(0.1, TIMER_InitBuildEntStructs, entity, TIMER_FLAG_NO_MAPCHANGE);
	}
}

int FindStructureIndex(int entity)
{
        for (int idx = 0; idx < BuildEntStructs.Length; idx++)
        {
                BuildingEntity ent;
                BuildEntStructs.GetArray(idx, ent);
                
                if (ent.entIndex == entity)
                        return idx;
        }        
        return -1;
}

int FindStructureIndexEx(int type, int entity)
{
        for (int idx = 0; idx < BuildEntStructsEx[type].Length; idx++)
        {
                BuildingEntity ent;
                BuildEntStructsEx[type].GetArray(idx, ent);
                
                if (ent.entIndex == entity)
                        return idx;
        }        
        return -1;
}

void PerformCleanup()
{
      	FirstStructurePlaced[0] = false;
	FirstStructurePlaced[1] = false;
	BuildEntStructs.Clear();
	for (int i = 0; i < view_as<int>(ND_StructCount); i++) {
	          BuildEntStructsEx[i].Clear();
	}
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
	for (int idx = 0; idx < view_as<int>(ND_StructCount); idx++) {
		OnStructBuildStarted[idx] = CreateGlobalForward(fName[idx], ET_Ignore, Param_Cell);		
	}
	
	OnStructCreated = CreateGlobalForward("ND_OnStructureCreated", ET_Ignore, Param_Cell, Param_String);	
}

/* Natives */
//typedef NativeCall = function int (Handle plugin, int numParams);

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_FirstStructurePlaced", Native_GetFirstStructurePlaced);
	CreateNative("ND_GetBuildingInfo", Native_GetBuildingInfo);
	CreateNative("ND_GetBuildingInfoEx", Native_GetBuildingInfoEx);
	return APLRes_Success;
}

public int Native_GetFirstStructurePlaced(Handle plugin, int numParams)
{
	int team = GetNativeCell(1);
	return FirstStructurePlaced[team -2];
}

public int Native_GetBuildingInfo(Handle plugin, int numParams)
{
	int entity = GetNativeCell(1);	
	int array = FindStructureIndex(entity);
	
	if (array != -1)
	{	  
	        BuildingEntity ent;
	        BuildEntStructs.GetArray(array, ent);
	  
	        SetNativeCellRef(2, ent.type);
	        SetNativeArray(3, ent.vecPos, sizeof(ent.vecPos));
	        SetNativeString(4, ent.classname, sizeof(ent.classname));
	}
	
	return array;
}

public int Native_GetBuildingInfoEx(Handle plugin, int numParams)
{
	int type = GetNativeCell(1);
	int entity = GetNativeCell(2);
	int array = FindStructureIndexEx(type, entity);
	
	if (array != -1)
	{	  
	        BuildingEntity ent;
	        BuildEntStructsEx[type].GetArray(array, ent);
	  
	        SetNativeArray(3, ent.vecPos, sizeof(ent.vecPos));
	        SetNativeString(4, ent.classname, sizeof(ent.classname));
	}
	
	return array;
}
