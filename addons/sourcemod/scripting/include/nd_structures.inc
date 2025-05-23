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

stock char ND_StructDisplayName[ND_StructCount][MAX_STRUCT_DISPLAYNAME] = {
	DISPLAYNAME_BUNKER,
	DISPLAYNAME_MG_TURRET,
	DISPLAYNAME_TRANSPORT,
	DISPLAYNAME_POWER_STATION,
	DISPLAYNAME_REPEATER,
	DISPLAYNAME_RELAY,
	DISPLAYNAME_SUPPLY,
	DISPLAYNAME_ASSEMBLER,
	DISPLAYNAME_ARMORY,
	DISPLAYNAME_ARTILLERY,
	DISPLAYNAME_RADAR,
	DISPLAYNAME_FT_TURRET,
	DISPLAYNAME_SONIC_TURRET,
	DISPLAYNAME_ROCKET_TURRET,
	DISPLAYNAME_WALL,
	DISPLAYNAME_BARRIER
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
	strcopy(name, sizeof(name), ND_StructDisplayName[view_as<int>(structure)]);

	if (uppercase)
	{
		for (int position = 0; position < sizeof(name); position++)
			name[position] = CharToUpper(name[position]);
	}

	return name;
}
