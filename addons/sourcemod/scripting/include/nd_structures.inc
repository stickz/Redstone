#if defined _nd_structures_included
  #endinput
#endif
#define _nd_structures_included

#include <nd_stocks>

enum ND_Structures {
	Command_Bunker,
	MG_Turret,
	Transport_Gate,
	Power_Plant,
	Wireless_Repeater,
	Relay_Tower,
	Supply_Station,
	Assembler,
	Armory,
	Artillery,
	Radar_Station,
	FT_Turret,
	Sonic_Turret,
	Rocket_Turret,
	Wall,
	Barrier
}

#define STRUCT_BUNKER "struct_command_bunker"
#define STRUCT_ASSEMBLER "struct_assembler"
#define STRUCT_TRANSPORT "struct_transport_gate"
#define STRUCT_ARTILLERY "struct_artillery_explosion"
#define STRUCT_SONIC_TURRET "struct_sonic_turret"
#define STRUCT_FT_TURRET "struct_flamethrower_turret"
#define STRUCT_POWER_STATION "struct_power_station"
#define STRUCT_ARMOURY "struct_armoury"
#define STRUCT_RADAR "struct_radar"
#define STRUCT_MG_TURRET "struct_machinegun_turret"
#define STRUCT_ROCKET_TURRET "struct_rocket_turret"
#define STRUCT_SUPPLY "struct_support_station"
#define STRUCT_RELAY "struct_power_relay"
#define STRUCT_REPEATER "struct_fusion_reactor"
#define STRUCT_WALL "struct_wall"
#define STRUCT_BARRIER "struct_barrier"

stock bool ND_IsStructRelay(const char[] classname) {
	return StrEqual(classname, STRUCT_RELAY, true) || StrEqual(classname, STRUCT_REPEATER, true);
}

stock char GetRelayTowerName(int team)
{
	char name[32];
	
	switch (team)
	{
		case TEAM_CONSORT: Format(name, sizeof(name), STRUCT_REPEATER);
		case TEAM_EMPIRE: Format(name, sizeof(name), STRUCT_RELAY);
	}
	
	return name;
}