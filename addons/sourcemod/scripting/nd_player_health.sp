#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <nd_maps>
#include <nd_print>
#include <nd_stocks>
#include <nd_classes>
#include <nd_structures>
#include <nd_research_eng>

//Version is auto-filled by the travis builder
public Plugin myinfo = 
{
	name 		= "[ND] Player Health",
	author 		= "stickz",
	description	= "Changes damage taken for certain classes",
    version 	= "recompile",
	url 		= "https://github.com/stickz/Redstone/"
}

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_player_health/nd_player_health.txt"
#include "updater/standard.sp"

#define IBLEVELS 4
#define DEFAULT_EXO_DAMAGE_MULT 0.8
#define DEFAULT_DAMAGE_MULT 1.0

#include "nd_health/convars.sp"

bool HookedDamage[MAXPLAYERS+1] = {false, ...};

bool cornerMap = false;

float ExoDamageMult[TEAM_COUNT] = { DEFAULT_EXO_DAMAGE_MULT, ... };
float ExoRocketDamageMult[TEAM_COUNT] = { DEFAULT_DAMAGE_MULT, ... };
float ExoArtilleryDamageMult[TEAM_COUNT] = { DEFAULT_DAMAGE_MULT, ... };

float AssaultDamageMult[TEAM_COUNT] = { DEFAULT_DAMAGE_MULT, ... };
float StealthDamageMult[TEAM_COUNT] = { DEFAULT_DAMAGE_MULT, ... };
float SupportDamageMult[TEAM_COUNT] = { DEFAULT_DAMAGE_MULT, ... };

public void OnPluginStart() 
{
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_PostNoCopy);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_PostNoCopy);
	
	LoadTranslations("nd_player_health.phrases");
	
	CreatePluginConVars(); // convars.sp
	AddUpdaterLibrary(); //auto-updater
}

public void OnMapStart()
{
	// Check if the corner map is corner to enable rocket turret protection
	cornerMap = ND_CurrentMapIsCorner();
}

/* Functions that restore varriables to default */
public void OnClientDisconnect(int client) {
	ResetVariables(client);
}
public void ND_OnRoundStart() 
{
	for (int client = 0; client <= MAXPLAYERS; client++) 
		ResetVariables(client);
	
	
	float defaultExoMult = cvarExoDamageMult[0].FloatValue;
	for (int team = 2; team < TEAM_COUNT; team++)
	{
		ExoDamageMult[team] = defaultExoMult;
		ExoRocketDamageMult[team] = defaultExoMult;
		ExoArtilleryDamageMult[team] = defaultExoMult;
		AssaultDamageMult[team] = cvarAssaultDamageMult[0].FloatValue;
		StealthDamageMult[team] = cvarStealthDamageMult[0].FloatValue;
		SupportDamageMult[team] = cvarSupportDamageMult[0].FloatValue;		
	}
}
void ResetVariables(int client) {
	HookedDamage[client] = false;
}

/* Armor increase logic */
public void OnInfantryBoostResearched(int team, int level) 
{
	UpdateDamageMultipliers(team, level);
	
	// Print a message to chat about until Armor increases
	PrintMessageTeam(team, "Armor Increases");
	
	/* Display console values for armor increases */
	PrintTeamSpacer(team); // Print spacer in console
	PrintConsoleTeam(team, "Armor Header Console"); // Add armor header
	PrintArmorIncreases(team, level); // Add Armor increase values
	PrintTeamSpacer(team); // Print spacer in console
}

void UpdateDamageMultipliers(int team, int level)
{
	ExoDamageMult[team] 	= cvarExoDamageMult[level].FloatValue;
	AssaultDamageMult[team] = cvarAssaultDamageMult[level].FloatValue;
	StealthDamageMult[team] = cvarStealthDamageMult[level].FloatValue;
	SupportDamageMult[team] = cvarSupportDamageMult[level].FloatValue;	
	
	// If the current map is corner, change the rocket turret and artillery damage mults for exos
	if (cornerMap)
	{
		ExoRocketDamageMult[team] = cvarExoRocketDamageMult[level].FloatValue;
		ExoArtilleryDamageMult[team] = cvarExoArtilleryDamageMult[level].FloatValue;		
	}
	// Otherwise, set these values to the base exo damage multiplier, so they stay the same
	else
	{
		ExoRocketDamageMult[team] = ExoDamageMult[team];
		ExoArtilleryDamageMult[team] = ExoDamageMult[team];		
	}
}

void PrintTeamSpacer(int team)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == team)
		{
			PrintToConsole(client, "");
		}
	}
}
void PrintArmorIncreases(int team, int level)
{
	int exo = CalcDisplayArmorExo(cvarExoDamageMult[level].FloatValue);
	int assault = CalcDisplayArmor(cvarAssaultDamageMult[level].FloatValue);
	int stealth = CalcDisplayArmor(cvarStealthDamageMult[level].FloatValue);
	int support = CalcDisplayArmor(cvarSupportDamageMult[level].FloatValue);
	
	for (int m = 1; m <= MaxClients; m++)
	{
		if (IsClientInGame(m) && GetClientTeam(m) == team)
		{			
			PrintToConsole(m, "%t", "Armor Increase", assault, exo, stealth, support);			
		}
	}
	
	// If the map is corner, display the rocket turret exo protection values
	if (cornerMap)
	{
		int rocketTurret = CalcDisplayProtectExo(level, cvarExoRocketDamageMult[level].FloatValue);
		int artilery = CalcDisplayProtectExo(level, cvarExoArtilleryDamageMult[level].FloatValue);
		
		for (int c = 1; c <= MaxClients; c++)
		{
			if (IsClientInGame(c) && GetClientTeam(c) == team)
			{
				PrintToConsole(c, "%t", "RT Exo Protection", rocketTurret);
				PrintToConsole(c, "%t", "Artillery Exo Protect", artilery);	
			}	
		}
	}	
}

int CalcDisplayProtectExo(int level, float pValue)
{
	float defValue = 1.0 - DEFAULT_EXO_DAMAGE_MULT
	float exoValue = DEFAULT_EXO_DAMAGE_MULT - cvarExoDamageMult[level].FloatValue;
	return RoundFloat((1.0 - pValue - defValue - exoValue) * 100.0);
}

int CalcDisplayArmorExo(float cValue) 
{
	float defValue = 1.0 - DEFAULT_EXO_DAMAGE_MULT;	
	return RoundFloat((1.0 - cValue - defValue) * 100.0);
}
int CalcDisplayArmor(float cValue) {
	return RoundFloat((1.0 - cValue) * 100);
}

/* Event hooks */
public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));	
	
	if (!HookedDamage[client])
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
		HookedDamage[client] = true;	
	}
	
	return Plugin_Continue;	
}
public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));	
	
	if (HookedDamage[client])
	{
		SDKUnhook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
		HookedDamage[client] = false;
	}

	return Plugin_Continue;
}
public Action OnPlayerTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	// If the inflictor or attacker entity is invalid, we must stop the checks
	if (!IsValidEntity(inflictor) || !IsValidBounds(attacker))
		return Plugin_Continue;
	
	// Get the team of the victim
	int team = GetClientTeam(victim);
	
	// Get the inflictor weapon class
	char className[64];
	GetEntityClassname(inflictor, className, sizeof(className));
	
	// Get the main class of the victim
	int mainClass = ND_GetMainClass(victim);
	
	// Get if the client's main class is an exo
	bool IsClientExoClass = IsExoClass(mainClass);
	
	// If the structure is a rocket turret, apply the damage fix
	if (StrEqual(className, STRUCT_ROCKET_TURRET, false))
	{
		float maxRDamage = GetRocketMaxDamage(team);
		damage = maxRDamage;
		
		// If the client is exo apply the rocket turret damage protection
		// Currently only applies to corner map, otherwise damage will match exo mult
		if (IsClientExoClass)
		{
			float multExoRT = ExoRocketDamageMult[team];
			damage *= multExoRT;
			return Plugin_Changed;			
		}		
	}
	
	// If the client is an exo, apply the 20% health rescaling
	// Also apply 5% armor (damage resistance) per infantry boost level
	if (IsClientExoClass)
	{
		// Do not apply armor to exos for machine gun turrets
		if (StrEqual(className, STRUCT_MG_TURRET, false))
		{
			damage *= DEFAULT_EXO_DAMAGE_MULT;
			return Plugin_Changed;
		}	
		
		// If the client is exo apply the artillery damage protection
		// Currently only applies to corner map, otherwise damage will match exo mult
		else if (StrEqual(className, STRUCT_ARTILLERY, false))
		{
			float multExoArtillery = ExoArtilleryDamageMult[team];
			damage *= multExoArtillery;
			return Plugin_Changed;
		}
		
		// Otherwise, apply the base exo damage protection for all other damage sources
		float multExo = ExoDamageMult[team];
		damage *= multExo;		
		return Plugin_Changed;
	}	
	
	// If the client is assault apply 1% 3% 5% infantry boost armor
	else if (IsAssaultClass(mainClass))
	{
		float multAssault = AssaultDamageMult[team];
		damage *= multAssault;
		return Plugin_Changed;		
	}
	
	// If the client is stealth apply 1% 3% 5% infantry boost armor
	else if (IsStealthClass(mainClass))
	{
		float multStealth = StealthDamageMult[team];
		damage *= multStealth;
		return Plugin_Changed;		
	}
	
	// If the client is support apply 1% 3% 5% infantry boost armor
	else if (IsSupportClass(mainClass))
	{
		float multSupport = SupportDamageMult[team];
		damage *= multSupport;
		return Plugin_Changed;		
	}
	
	return Plugin_Continue;
}

float GetRocketMaxDamage(int team)
{	
	if (team == TEAM_EMPIRE || team == TEAM_CONSORT)
		return RocketTurretDamage[team-2].FloatValue;
		
	return 0.0;
}