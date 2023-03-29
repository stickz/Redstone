#include <sourcemod>
#include <nd_structures>
#include <nd_stocks>

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
bool roundStarted = false;

Handle OnStructBuildStarted[ND_StructCount];
Handle OnStructCreated;

enum struct BuildingEntity
{
      int entIndex;
      int type;
      int team;
      char classname[32];
      float vecPos[3];
      
      int initByIndex(int index) {
            this.entIndex = index;
            GetEntityClassname(index, this.classname, sizeof(this.classname));
            GetEntPropVector(index, Prop_Send, "m_vecOrigin", this.vecPos);
            this.type = ND_GetStructIndex(this.classname);
            this.team = GetEntProp(index, Prop_Send, "m_iTeamNum");
            return 0;
      }
}

ArrayList BuildEntStructs;
ArrayList BuildEntStructsTeam[2];
ArrayList BuildEntStructsType[ND_StructCount];
ArrayList BuildEntStructsTypeTeam[ND_StructCount][2];

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
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	
	BuildEntStructs = new ArrayList(sizeof(BuildingEntity));
	
	for (int i = 0; i < view_as<int>(ND_StructCount); i++) {
	          BuildEntStructsType[i] = new ArrayList(sizeof(BuildingEntity));
	          BuildEntStructsTypeTeam[i][0] = new ArrayList(sizeof(BuildingEntity));
	          BuildEntStructsTypeTeam[i][1] = new ArrayList(sizeof(BuildingEntity));
	}
	
	BuildEntStructsTeam[0] = new ArrayList(sizeof(BuildingEntity));
	BuildEntStructsTeam[1] = new ArrayList(sizeof(BuildingEntity));
	
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
        int teamIndex = event.GetInt("team");

	// Ensure the owner team which destroyed the structure is valid
	if (teamIndex != TEAM_EMPIRE && teamIndex != TEAM_CONSORT)
		return Plugin_Continue;

        /* Remove the entity index reference */
        int arrIndex = FindStructureIndex(entIndex);
        if (arrIndex != -1)
                BuildEntStructs.Erase(arrIndex);

        int arrIndexType = FindStructureIndexType(typeIndex, entIndex);       
        if (arrIndexType != -1)
                BuildEntStructsType[typeIndex].Erase(arrIndexType);

        int arrIndexTeam = FindStructureIndexTeam(teamIndex, entIndex);        
        if (arrIndexTeam != -1)
                BuildEntStructsTeam[teamIndex-2].Erase(arrIndexTeam);
                
        int arrIndexTypeTeam = FindStructureIndexTypeTeam(typeIndex, teamIndex, entIndex); 
        if (arrIndexTypeTeam != -1)
                BuildEntStructsTypeTeam[typeIndex][teamIndex-2].Erase(arrIndexTypeTeam);
  
        return Plugin_Continue;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) 
{
	roundStarted = false;
	PerformCleanup();	
	return Plugin_Continue;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	roundStarted = true;
	
	InitStructureByType(STRUCT_BUNKER);
        InitStructureByType(STRUCT_ASSEMBLER);
        InitStructureByType(STRUCT_TRANSPORT);
        InitStructureByType(STRUCT_MG_TURRET);
	
	return Plugin_Continue;
}

void InitStructureByType(const char[] name)
{
   	int loopEntity = INVALID_ENT_REFERENCE;
   	while ((loopEntity = FindEntityByClassname(loopEntity, name)) != INVALID_ENT_REFERENCE)
	{
	         if (!HasEntProp(loopEntity, Prop_Send, "m_vecOrigin") || 
	             !HasEntProp(loopEntity, Prop_Send, "m_iTeamNum"))
	                  continue;
	                  
	         InitBuildEnt(loopEntity);
	}
}

public Action TIMER_InitBuildEntStructs(Handle timer, int entity)
{
	if (!HasEntProp(entity, Prop_Send, "m_vecOrigin") || 
	    !HasEntProp(entity, Prop_Send, "m_iTeamNum"))
	        return Plugin_Handled;	

	InitBuildEnt(entity);	
	return Plugin_Handled;
}

void InitBuildEnt(int entity)
{
	BuildingEntity ent;
	ent.initByIndex(entity);
	BuildEntStructs.PushArray(ent);
	BuildEntStructsTeam[ent.team-2].PushArray(ent);
        BuildEntStructsType[ent.type].PushArray(ent);
        BuildEntStructsTypeTeam[ent.type][ent.team-2].PushArray(ent);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (roundStarted && strncmp(classname, "struct_", 7) == 0)
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

int FindStructureIndexTeam(int team, int entity)
{
        for (int idx = 0; idx < BuildEntStructsType[team-2].Length; idx++)
        {
                BuildingEntity ent;
                BuildEntStructsTeam[team-2].GetArray(idx, ent);
                
                if (ent.entIndex == entity)
                        return idx;
        }        
        return -1;
}


int FindStructureIndexType(int type, int entity)
{
        for (int idx = 0; idx < BuildEntStructsType[type].Length; idx++)
        {
                BuildingEntity ent;
                BuildEntStructsType[type].GetArray(idx, ent);
                
                if (ent.entIndex == entity)
                        return idx;
        }        
        return -1;
}

int FindStructureIndexTypeTeam(int type, int team, int entity)
{
        for (int idx = 0; idx < BuildEntStructsTypeTeam[type][team-2].Length; idx++)
        {
                BuildingEntity ent;
                BuildEntStructsTypeTeam[type][team-2].GetArray(idx, ent);
                
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
	for (int i = 0; i < view_as<int>(ND_StructCount); i++) 
	{
	          BuildEntStructsType[i].Clear();
	          BuildEntStructsTypeTeam[i][0].Clear();
	          BuildEntStructsTypeTeam[i][1].Clear();
	}	
	BuildEntStructsTeam[0].Clear();
	BuildEntStructsTeam[1].Clear();
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
	CreateNative("ND_GetBuildingInfoType", Native_GetBuildingInfoType);
	CreateNative("ND_GetBuildingInfoTeam", Native_GetBuildingInfoTeam);
	
	CreateNative("ND_GetBuildInfoArray", Native_GetBuildInfoArray);
	CreateNative("ND_GetBuildInfoArrayType", Native_GetBuildInfoArrayType);
	CreateNative("ND_GetBuildInfoArrayTeam", Native_GetBuildInfoArrayTeam);
	CreateNative("ND_GetBuildInfoArrayTypeTeam", Native_GetBuildInfoArrayTypeTeam);
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

public int Native_GetBuildingInfoType(Handle plugin, int numParams)
{
	int type = GetNativeCell(1);
	int entity = GetNativeCell(2);
	int array = FindStructureIndexType(type, entity);
	
	if (array != -1)
	{	  
	        BuildingEntity ent;
	        BuildEntStructsType[type].GetArray(array, ent);
	  
	        SetNativeArray(3, ent.vecPos, sizeof(ent.vecPos));
	        SetNativeString(4, ent.classname, sizeof(ent.classname));
	}
	
	return array;
}

public int Native_GetBuildingInfoTeam(Handle plugin, int numParams)
{
	int team = GetNativeCell(1);
	int entity = GetNativeCell(2);
	int array = FindStructureIndexTeam(team, entity);
	
	if (array != -1)
	{	  
	        BuildingEntity ent;
	        BuildEntStructsTeam[team-2].GetArray(array, ent);
	  
	        SetNativeArray(3, ent.vecPos, sizeof(ent.vecPos));
	        SetNativeString(4, ent.classname, sizeof(ent.classname));
	}
	
	return array;
}

public int Native_GetBuildInfoArray(Handle plugin, int numParams)
{
        SetNativeCellRef(1, BuildEntStructs);
        return 0;
}

public int Native_GetBuildInfoArrayType(Handle plugin, int numParams)
{
        int type = GetNativeCell(2);
        SetNativeCellRef(1, BuildEntStructsType[type]);
        return 0;
}

public int Native_GetBuildInfoArrayTeam(Handle plugin, int numParams)
{
        int team = GetNativeCell(2);
        SetNativeCellRef(1, BuildEntStructsTeam[team-2]);
        return 0;
}

public int Native_GetBuildInfoArrayTypeTeam(Handle plugin, int numParams)
{
        int type = GetNativeCell(2);
        int team = GetNativeCell(3);
        SetNativeCellRef(1, BuildEntStructsTypeTeam[type][team-2]);
        return 0;
}

