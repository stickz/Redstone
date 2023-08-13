#include <sourcemod>
#include <autoexecconfig>
#include <sdktools>
#include <sdkhooks>
#include <nd_rounds>
#include <nd_struct_eng>
#include <nd_research_eng>
#include <nd_commander_build>

Handle MGTurretDelayTimer = INVALID_HANDLE;

ConVar cvarMGTurrentDelay;
ConVar cvarMGTurrentMax;

bool MGTurrentBuildAllowed = true;

public Plugin myinfo = 
{
	name = "[ND] Build Restrict",
	author = "stickz",
	description = "Restrict certain buildings at match start",
	version = "dummy",
	url = "https://github.com/stickz/Redstone/"
};

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_build_restrict/nd_build_restrict.txt"
#include "updater/standard.sp"

public void OnPluginStart()
{
	CreatePluginConvars();
	AddUpdaterLibrary(); //auto-updater
}

public void ND_OnRoundStarted() 
{
	MGTurrentBuildAllowed = false;
	MGTurretDelayTimer = CreateTimer(cvarMGTurrentDelay.FloatValue, TIMER_ReleaseMGTurretRestrict, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void ND_OnRoundEnded() 
{
	if (MGTurretDelayTimer != INVALID_HANDLE && IsValidHandle(MGTurretDelayTimer))
	{
		CloseHandle(MGTurretDelayTimer);
		MGTurretDelayTimer = INVALID_HANDLE;
	}
}

public Action TIMER_ReleaseMGTurretRestrict(Handle timer)
{
	MGTurrentBuildAllowed = true;	
	return Plugin_Handled;
}

void CreatePluginConvars()
{
	AutoExecConfig_Setup("nd_build_restrict");
	
	cvarMGTurrentDelay 		= 	AutoExecConfig_CreateConVar("sm_build_restrict_mg_secs", "360", "Number of seconds into the game to release MG turrent restricts");
	cvarMGTurrentMax		=	AutoExecConfig_CreateConVar("sm_build_restrict_mg_max", "3", "Maximum number of mg turrents allowed at match start");
	
	AutoExecConfig_EC_File();
}

public Action ND_OnCommanderBuildStructure(int client, ND_Structures &structure, float position[3])
{
	if (!ND_RoundStarted())
		return Plugin_Continue;
	
	if (!MGTurrentBuildAllowed && structure == ND_MG_Turret)
	{
		int team = GetClientTeam(client);
		if (!ND_ItemHasBeenResearched(team, Advanced_Manufacturing) && ND_GetMGTurretCount(team) > cvarMGTurrentMax.IntValue)
		{
			UTIL_Commander_FailureText(client, "MAXED MG TURRETS IN EARLY GAME");
			return Plugin_Stop;
		}	
	}
	
	return Plugin_Continue;	
}

stock int ND_GetMGTurretCount(int team)
{
	ArrayList buildings;
	ND_GetBuildInfoArrayTypeTeam(buildings, view_as<int>(ND_MG_Turret), team);
	return buildings.Length;
}
