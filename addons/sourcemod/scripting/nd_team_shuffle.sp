#include <sourcemod>
#include <sdktools>
#include <nd_gskill>
#include <nd_stats>
#include <nd_rounds>
#include <nd_stocks>
#include <nd_redstone>
#include <nd_aweight>
#include <nd_entities>

/* Notice to plugin contributors: please create a new native and void,
 * When modifying the sorting or placement algorithum to allow for proper testing.
 */

#define MAX_SKILL 225

public Plugin myinfo =
{
	name 		= "[ND] Team Shuffle",
	author 		= "Stickz",
	description 	= "Shuffles teams using a sorting algorithm, against player skill",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone"
};

/* Auto Updater */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_team_shuffle/nd_team_shuffle.txt"
#include "updater/standard.sp"

ArrayList balancedPlayers;
Handle g_OnTeamsShuffled_Forward;

ConVar gcLevelEighty;

public void OnPluginStart() 
{
	balancedPlayers = new ArrayList(MaxClients+1);
	g_OnTeamsShuffled_Forward = CreateGlobalForward("ND_OnTeamsShuffled", ET_Ignore);
	
	gcLevelEighty = CreateConVar("sm_ts_eightyExp", "450000", "Specifies the amount of exp to be considered level 80");	
	AutoExecConfig(true, "nd_team_shuffle");
	
	AddUpdaterLibrary(); //auto-updater
}

void BalanceTeams()
{
	balancedPlayers.Clear(); //Whipe the list of previous balanced players
	
	/* Store the clients we're balancing into an array */
	ArrayList players = new ArrayList(4, MaxClients+1);	
	bool roundStarted = ND_RoundStarted();
	
	int client = 1;
	players.Set(0, -1);
	
	int skill = 0;
	for (; client <= MaxClients; client++) { 
		skill = GetFinalSkill(client, roundStarted);
		players.Set(client, skill);
	}
	
	int counter = MAX_SKILL;
	int team = getRandomTeam();
	
	bool doublePlace = true;
	bool firstPlace = true;
	bool checkPlacement = true;	
	
	while (counter > -1)
	{
		client = players.FindValue(counter);
		
		if (client == -1)
			counter--;
			
		else
		{
			/* Set player team and mark balanced */
			SetClientTeam(client, team);
			MarkBalanced(client);
			
			/* Decide which team is next, using this messy algorithum */
			/* Best player on team x, next two team y, then every other on opposite teams */
			if (checkPlacement)
			{		
				if (firstPlace)
				{
					firstPlace = false;
					team = getOtherTeam(team);
				}
				else if (doublePlace)
				{
					doublePlace = false;
					checkPlacement = false;
				}
			}
			else			
				team = getOtherTeam(team);
			
			/* Whipe the player from the arraylist */			
			players.Set(client, -1);			
		}		
	}
	
	FireTeamsShuffledForward();
}

void SetClientTeam(int client, int team)
{
	ChangeClientTeam(client, TEAM_SPEC); //change to spectator first to prevent loss of stats	
	ChangeClientTeam(client, team); 
}

void MarkBalanced(int client)
{
	char sSteamID[22];
	GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof(sSteamID)); 
	balancedPlayers.PushString(sSteamID);
}

void FireTeamsShuffledForward()
{
	Action dummy;
	Call_StartForward(g_OnTeamsShuffled_Forward);
	Call_Finish(dummy);
	
	/* Start round after call is finished */
	if (!ND_RoundStarted())
		ServerCommand("mp_minplayers 1");
}

bool IsReadyForBalance(int client, bool roundStarted)
{
	int team = GetClientTeam(client);
	
	//If checking for spec is removed after round start, we must add a check for server bots
	return !roundStarted ? team != TEAM_UNASSIGNED : team > TEAM_SPEC;	
}

int GetSkillLevel(int client)
{
	int level = ND_RetreiveLevel(client);
	int sFloor = ND_GetSkillFloor(client);
	
	/* Load all skill floored clients before they spawn */
	if (sFloor >= 80)
		level = sFloor;
	
	/* Load all level 80 clients before they spawn */
	else if (ND_EXPAvailible(client) && ND_GetClientEXP(client) >= gcLevelEighty.IntValue)
		level = 80;
	
	if (GM_GFS_LOADED())
	{
		float pSkill = GameME_GetFinalSkill(client);		
		return level > pSkill ? level : RoundFloat(pSkill);
	}
	
	return level;
}

int GetFinalSkill(int client, bool roundStarted) 
{
	if (!RED_IsValidClient(client) || !IsReadyForBalance(client, roundStarted))
		return -1;
	
	return GetSkillLevel(client);	
}

/* Natives */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("WB2_BalanceTeams", Native_WarmupTeamBalance);
	CreateNative("WB2_GetBalanceData", Native_GetBalancerData);
	
	MarkNativeAsOptional("GameME_GetFinalSkill");
	MarkNativeAsOptional("SteamWorks_GetFinalSkill");
	return APLRes_Success;
}

public Native_WarmupTeamBalance(Handle plugin, int numParms)
{
	BalanceTeams();
	return;
}

public Native_GetBalancerData(Handle plugin, int numParms)
{
	DataPack data = CreateDataPack();
	
	for (int i = 0; i < balancedPlayers.Length; i++)
	{
		char steamID[22];
		balancedPlayers.GetString(i, steamID, sizeof(steamID));		
		data.WriteString(steamID);		
	}
	
	return _:view_as<Handle>(data);
}
