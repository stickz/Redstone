#if defined _nd_strct_eng_included
  #endinput
#endif
#define _nd_struct_eng_included

#include <nd_structures>

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

native int ND_GetBuildingInfo(int entity, int &type, float[] vecPos, char[] classname);
native int ND_GetBuildingInfoType(int type, int entity, float[] vecPos, char[] classname);
native int ND_GetBuildingInfoTeam(int team, int entity, float[] vecPos, char[] classname);

native void ND_GetBuildInfoArray(ArrayList &buildings);
native void ND_GetBuildInfoArrayType(ArrayList &buildings, int type);
native void ND_GetBuildInfoArrayTeam(ArrayList &buildings, int team);
native void ND_GetBuildInfoArrayTypeTeam(ArrayList &buildings, int type, int team);

// Check if the team has placed their first structure
native bool ND_FirstStructurePlaced(int team);

#define ND_FSP_AVAILIBLE() (GetFeatureStatus(FeatureType_Native, "ND_FirstStructurePlaced") == FeatureStatus_Available)
stock bool ND_TeamPlacedStructure(int iTeam, bool bDefault) {
	return !ND_FSP_AVAILIBLE() ? bDefault :  ND_FirstStructurePlaced(iTeam);
}

// Fires when a structure is fully created. Less overhead than OnEntityCreated()
forward void ND_OnStructureCreated(int entity, const char[] classname);

/* Create structure build started forwards */
forward void OnBuildStarted_Bunker(int team);
forward void OnBuildStarted_MGTurret(int team);
forward void OnBuildStarted_TransportGate(int team);
forward void OnBuildStarted_PowerPlant(int team);
forward void OnBuildStarted_WirelessRepeater(int team);
forward void OnBuildStarted_RelayTower(int team);
forward void OnBuildStarted_SupplyStation(int team);
forward void OnBuildStarted_Assembler(int team);
forward void OnBuildStarted_Armory(int team);
forward void OnBuildStarted_Artillery(int team);
forward void OnBuildStarted_RadarStation(int team);
forward void OnBuildStarted_FlameTurret(int team);
forward void OnBuildStarted_SonicTurret(int team);
forward void OnBuildStarted_RocketTurret(int team);
forward void OnBuildStarted_Wall(int team);
forward void OnBuildStarted_Barrier(int team);
