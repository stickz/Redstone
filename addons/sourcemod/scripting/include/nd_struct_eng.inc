#if defined _nd_strct_eng_included
  #endinput
#endif
#define _nd_struct_eng_included

#include <nd_structures>

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
