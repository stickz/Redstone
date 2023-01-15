#if defined _nd_structures_included
  #endinput
#endif
#define _nd_structures_included

#include <sdktools>
#include <nd_stocks>

enum ND_Structures: {
	ND_Command_Bunker,
	ND_MG_Turret,
	ND_Transport_Gate,
	ND_Power_Plant,
	ND_Wireless_Repeater,
	ND_Relay_Tower,
	ND_Supply_Station,
	ND_Assembler,
	ND_Armory,
	ND_Artillery,
	ND_Radar_Station,
	ND_FT_Turret,
	ND_Sonic_Turret,
	ND_Rocket_Turret,
	ND_Wall,
	ND_Barrier,
	ND_StructCount
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

#define MAX_STRUCT_DISPLAYNAME 22
#define DISPLAYNAME_BUNKER "Command Bunker"
#define DISPLAYNAME_MG_TURRET "Machine Gun Turret"
#define DISPLAYNAME_TRANSPORT "Transport Gate"
#define DISPLAYNAME_POWER_STATION "Power Station"
#define DISPLAYNAME_REPEATER "Wireless Repeater"
#define DISPLAYNAME_RELAY "Relay Tower"
#define DISPLAYNAME_SUPPLY "Supply Station"
#define DISPLAYNAME_ASSEMBLER "Assembler"
#define DISPLAYNAME_ARMORY "Armory"
#define DISPLAYNAME_ARTILLERY "Artillery"
#define DISPLAYNAME_RADAR "Radar Station"
#define DISPLAYNAME_FT_TURRET "Flamethrower Turret"
#define DISPLAYNAME_SONIC_TURRET "Sonic Turret"
#define DISPLAYNAME_ROCKET_TURRET "Rocket Turret"
#define DISPLAYNAME_WALL "Wall"
#define DISPLAYNAME_BARRIER "Barrier"

stock char ND_StructName[ND_StructCount][32] = {
	STRUCT_BUNKER,
	STRUCT_MG_TURRET,
	STRUCT_TRANSPORT,
	STRUCT_POWER_STATION,
	STRUCT_REPEATER,
	STRUCT_RELAY,
	STRUCT_SUPPLY,
	STRUCT_ASSEMBLER,
	STRUCT_ARMOURY,
	STRUCT_ARTILLERY,
	STRUCT_RADAR,
	STRUCT_FT_TURRET,
	STRUCT_SONIC_TURRET,
	STRUCT_ROCKET_TURRET,
	STRUCT_WALL,
	STRUCT_BARRIER
};

stock int ND_GetStructIndex(const char[] classname)
{
	for (int i = 0; i < view_as<int>(ND_StructCount); i++)
	{
		if (StrEqual(classname, ND_StructName[i], true))
			return i;
	}
	return -1;
}

stock bool ND_IsStructRelay(const char[] classname) {
	return StrEqual(classname, STRUCT_RELAY, true) || StrEqual(classname, STRUCT_REPEATER, true);
}

stock bool ND_IsStructFlameTurret(const char[] classname) {
	return StrEqual(classname, STRUCT_SONIC_TURRET, true) || StrEqual(classname, STRUCT_FT_TURRET, true);
}

stock char[] GetRelayTowerName(int team)
{
	char name[32];

	switch (team)
	{
		case TEAM_CONSORT: Format(name, sizeof(name), STRUCT_REPEATER);
		case TEAM_EMPIRE: Format(name, sizeof(name), STRUCT_RELAY);
	}

	return name;
}

stock char[] GetStructureDisplayName(ND_Structures structure, bool uppercase=false)
{
	if (structure >= ND_StructCount || structure < ND_Command_Bunker)
	{
		ThrowError("Invalid structure specified to GetStructureDisplayName");
	}

	char name[MAX_STRUCT_DISPLAYNAME];
	switch (structure)
	{
		case ND_Command_Bunker: Format(name, sizeof(name), DISPLAYNAME_BUNKER);
		case ND_MG_Turret: Format(name, sizeof(name), DISPLAYNAME_MG_TURRET);
		case ND_Transport_Gate: Format(name, sizeof(name), DISPLAYNAME_TRANSPORT);
		case ND_Power_Plant: Format(name, sizeof(name), DISPLAYNAME_POWER_STATION);
		case ND_Wireless_Repeater: Format(name, sizeof(name), DISPLAYNAME_REPEATER);
		case ND_Relay_Tower: Format(name, sizeof(name), DISPLAYNAME_RELAY);
		case ND_Supply_Station: Format(name, sizeof(name), DISPLAYNAME_SUPPLY);
		case ND_Assembler: Format(name, sizeof(name), DISPLAYNAME_ASSEMBLER);
		case ND_Armory: Format(name, sizeof(name), DISPLAYNAME_ARMORY);
		case ND_Artillery: Format(name, sizeof(name), DISPLAYNAME_ARTILLERY);
		case ND_Radar_Station: Format(name, sizeof(name), DISPLAYNAME_RADAR);
		case ND_FT_Turret: Format(name, sizeof(name), DISPLAYNAME_FT_TURRET);
		case ND_Sonic_Turret: Format(name, sizeof(name), DISPLAYNAME_SONIC_TURRET);
		case ND_Rocket_Turret: Format(name, sizeof(name), DISPLAYNAME_ROCKET_TURRET);
		case ND_Wall: Format(name, sizeof(name), DISPLAYNAME_WALL);
		case ND_Barrier: Format(name, sizeof(name), DISPLAYNAME_BARRIER);
	}

	if (uppercase)
	{
		for (int position = 0; position < sizeof(name); position++)
			name[position] = CharToUpper(name[position]);
	}

	return name;
}
