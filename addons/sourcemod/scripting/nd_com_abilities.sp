#include <sourcemod>
#include <nd_stocks>
#include <nd_maps>
#include <nd_rounds>
#include <nd_redstone>
#include <nd_team_eng>

public Plugin myinfo =
{
	name = "[ND] Commander abilities",
	author = "Stickz",
	description = "Rebalances commander abilities",
	version = "dummy",
	url = "https://github.com/stickz/Redstone"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_com_abilities/nd_com_abilities.txt"
#include "updater/standard.sp"

// L1: 630 damage, L2: 720 damage, L3: 810 damage
int levelDefault[] = { 630, 720, 810 };
int reducedValues[] = { 630, 720, 810 };

bool foundCorner = false;
bool currentState = false;

ConVar cvarNormalCount;
ConVar cvarReducedDamage;

public void OnPluginStart()
{
	cvarNormalCount 	= 	CreateConVar("sm_ability_normal", "10", "Specifies the player count on a team to deal normal commander damage");
	cvarReducedDamage	=	CreateConVar("sm_ability_damage", "85", "Specifies the percent of normal damage, bellow the player threshold");	
	HookConVarChange(cvarReducedDamage, OnDamageChanged);
	
	AddUpdaterLibrary(); // Auto-Updater support
	
	if (ND_RoundStarted())
		ND_OnPreRoundStart();
}

public void ND_OnPreRoundStart()
{
	foundCorner = FoundCornerMap();
	currentState = false;
	SetReducedValues();
	
	// If the map is corner, scale damage; otherwise, set it to default
	if (foundCorner)
		RefreshComDamage();
	else
		SetCommanderDamage(levelDefault);
}

public void ND_OnPlayerTeamChanged(int client, bool valid)
{	
	if (foundCorner && ND_RoundStarted())
		RefreshComDamage();
}

public void OnDamageChanged(ConVar convar, char[] oldValue, char[] newValue) 
{	
	if (ND_RoundStarted())
		ND_OnPreRoundStart();
}

bool FoundCornerMap()
{
	char currentMap[64];
	GetCurrentMap(currentMap, sizeof(currentMap));	
	return ND_CustomMapEquals(currentMap, ND_Corner);
}

void RefreshComDamage()
{
	bool normal = RED_OnTeamCount() >= cvarNormalCount.IntValue;
	
	if (currentState != normal)
	{	
		currentState = normal;
		SetCommanderDamage(normal ? levelDefault : reducedValues);
	}
}

void SetReducedValues()
{
	float mult = cvarReducedDamage.FloatValue / 100.0;
	for (int i = 0; i < 3; i++)
		reducedValues[0] = RoundToNearest(float(levelDefault[0]) * mult);
}

void SetCommanderDamage(int[] values)
{
	ServerCommand("sm_cvar nd_commander_ability_damage_value %d", values[0]);
	ServerCommand("sm_cvar nd_commander_ability_damage_value2 %d", values[1]);
	ServerCommand("sm_cvar nd_commander_ability_damage_value3 %d", values[2]);
}
