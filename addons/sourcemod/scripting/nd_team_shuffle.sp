#include <sourcemod>
#include <sdktools>
#include <nd_fskill>
#include <nd_stats>
#include <nd_rounds>
#include <nd_stocks>
#include <nd_redstone>
#include <nd_aweight>
#include <nd_entities>
#include <nd_print>
#include <nd_afk>
#include <autoexecconfig>

/* Notice to plugin contributors: please create a new native and void,
 * When modifying the sorting or placement algorithum to allow for proper testing.
 */

#define MAX_SKILL 225
#define DEBUG 1

public Plugin myinfo =
{
	name 		= "[ND] Team Shuffle",
	author 		= "Stickz",
	description 	= "Shuffles teams using a sorting algorithm, against player skill",
	version 	= "recompile",
	url 		= "https://github.com/stickz/Redstone"
};

/* Auto Updater */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_team_shuffle/nd_team_shuffle.txt"
#include "updater/standard.sp"

#define LOW_PLYS	0
#define HIGH_PLYS	1

ArrayList balancedPlayers;
Handle g_OnTeamsShuffled_Forward;
Handle g_OnAskPlacement_Forward;

ConVar gcLevelEighty;
ConVar gcShuffleThresholdLevel[2];
ConVar gcShuffleThresholdSkill[2];
ConVar gcShuffleThresholdHighPlys;
ConVar gcShuffleEveryOther;

public void OnPluginStart() 
{
	balancedPlayers = new ArrayList(MaxClients+1);
	
	g_OnTeamsShuffled_Forward = CreateGlobalForward("ND_OnTeamsShuffled", ET_Ignore, Param_Cell);
	g_OnAskPlacement_Forward = CreateGlobalForward("ND_OnShuffleAskPlacement", ET_Ignore, Param_Cell);
	
	LoadTranslations("nd_team_shuffle.phrases");
	
	CreateConVars();
	
	AddUpdaterLibrary(); //auto-updater
}

void CreateConVars()
{
	AutoExecConfig_Setup("nd_team_shuffle");
	
	gcLevelEighty 						= 	AutoExecConfig_CreateConVar("sm_ts_eightyExp", "450000", "Specifies the amount of exp to be considered level 80");
	
	gcShuffleThresholdHighPlys			=	AutoExecConfig_CreateConVar("sm_ts_threshold_plys", "16", "Specifies number of players for high skill threshold");
	
	gcShuffleThresholdLevel[LOW_PLYS] 	= 	AutoExecConfig_CreateConVar("sm_ts_threshold_level_low", "40", "Specifies the level difference to shuffle teams");
	gcShuffleThresholdLevel[HIGH_PLYS] 	= 	AutoExecConfig_CreateConVar("sm_ts_threshold_level_high", "60", "Specifies the level difference to shuffle teams");
	
	gcShuffleThresholdSkill[LOW_PLYS]	=	AutoExecConfig_CreateConVar("sm_ts_threshold_skill_low", "60", "Specifies the skill difference to shuffle teams");
	gcShuffleThresholdSkill[HIGH_PLYS]	=	AutoExecConfig_CreateConVar("sm_ts_threshold_skill_high", "80", "Specifies the skill difference to shuffle teams");
	
	gcShuffleEveryOther					= 	AutoExecConfig_CreateConVar("sm_ts_every_other", "20", "Specifies the skill difference to shuffle every other player");
	
	AutoExecConfig_EC_File();	
}

public Action TIMER_CheckBalanceTeams(Handle timer)
{
	if (RunTeamShuffle())	
		BalanceTeams();
	
	return Plugin_Handled;
}

bool RunTeamShuffle()
{
	// Get the skill difference & ceiling 80 skill difference percent between teams
	// If they both are less than the shuffle threshold, start without shuffling
	int skillDiffPer = ND_GetSkillDiffPercent();
	int skillDiffPerEx = ND_GetSkillDiffPercentEx(80.0);
	
	// Decide wether we're using the high player count thresholds or the low player count thresholds
	int plys = RED_ValidClientCount() >= gcShuffleThresholdHighPlys.IntValue ? HIGH_PLYS : LOW_PLYS;
	
	// Find the shuffle thresholds for the level difference and skill difference based on player count
	int shuffleThresholdLevel = gcShuffleThresholdLevel[plys].IntValue;
	int shuffleThresholdSkill = gcShuffleThresholdSkill[plys].IntValue;
	
	if (skillDiffPer < shuffleThresholdSkill && skillDiffPerEx < shuffleThresholdLevel)
	{
		//PrintMessageAllTB("Shuffle Threshold Not Reached");
		FireTeamsShuffledForward(false); // Fire teams shuffle forward and start round		
		return false;
	}	
	
	return true;
}

// Pull players not afk out of spectator by firing the ask placement forward
void PullSpectators()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (RED_IsValidClient(client) && !ND_IsCheckedAFK(client) && GetClientTeam(client) <= TEAM_SPEC)
		{
			FireAskPlacementForward(client);
		}
	}	
}

void BalanceTeams()
{
	balancedPlayers.Clear(); //Whipe the list of previous balanced players
	
	/* Store the clients we're balancing into an array */
	ArrayList players = new ArrayList(4, MaxClients+1);	
	bool roundStarted = ND_RoundStarted();
	
	// Get whether to shuffle every other or in groups of two
	bool shuffleEveryOther = DoShuffleEveryOther(roundStarted);
	
	#if DEBUG == 1
	// Format the message top 2 player skill diff and shuffle every other value	
	char Message[64];
	Format(	Message, sizeof(Message), "\x05[TB] Shuffle Every Other: %s!", shuffleEveryOther ? "true" : "false");
	PrintToAdmins(Message, "b");
	#endif
	
	// declare vars for for-loop
	int client = 1;
	players.Set(0, -1);
	
	// declare vars for while loop
	int counter = MAX_SKILL;
	int team = getRandomTeam();
	int index = 0;
	
	for (; client <= MaxClients; client++) 
	{ 
		if (IsValidClientEx(client))
		{		
			int skill = GetFinalSkill(client, roundStarted);
			players.Set(client, skill);
		}
	}
	
	while (counter > -1)
	{
		client = players.FindValue(counter);
		
		if (client == -1)
		{
			counter--;
			continue;
		}
			
		else if (IsValidClient(client))
		{
			/* Decide which team is next, using one of the two algorithums */
			/* 1) Shuffle Every Other: Best player team x, next team y, next team x etc. */
			/* 2) Shuffle Groups of Two: Best player on team x, next two team y, next two team x etc. */
			if (shuffleEveryOther || (index + 1) % 2 == 0)
				team = getOtherTeam(team);
			
			/* Post-Increment the index for the team varriable */
			index++;
			
			/* Set player team and mark balanced */
			SetClientTeam(client, team);
			MarkBalanced(client);
		}		

		/* Whipe the player from the arraylist */			
		players.Set(client, -1);
	}
	
	delete players;
	FireTeamsShuffledForward(true);
}

int GetTopTwoSkillDiff(bool roundStarted)
{
	int first = 0;
	int second = 0;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		// If the client is valid AND (The round is not started OR the client is on a team)
		if (RED_IsValidClient(client) && (!roundStarted || IsReadyForBalance(client, roundStarted)))
		{		
			int skill = GetSkillLevel(client);
			
			if (skill > first)
			{
				second = first;
				first = skill;
			}
			
			else if (skill > second)
			{
				second = skill;
			}	
		}
	}
	
	return first - second;
}

bool DoShuffleEveryOther(bool roundStarted)
{
	int threshold = gcShuffleEveryOther.IntValue;
	
	if (!roundStarted)
	{
		// Get top 2 skill difference with and without unassigned players
		int top2SkillDiff = GetTopTwoSkillDiff(true);
		int top2SkillDiffEx = GetTopTwoSkillDiff(false);
		
		// If etheir of the skill difference is within the threshold, shuffle every other
		return top2SkillDiff <= threshold || top2SkillDiffEx <= threshold;
	}
	
	// Otherwise if the round is started, get the skill difference without unassigned players
	return GetTopTwoSkillDiff(roundStarted) <= threshold;
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

void FireTeamsShuffledForward(bool phase2)
{
	Action dummy;
	Call_StartForward(g_OnTeamsShuffled_Forward);
	Call_PushCell(phase2);
	Call_Finish(dummy);
	
	/* Start round after call is finished */
	StartRound();
}

void FireAskPlacementForward(int client)
{
	Action dummy;
	Call_StartForward(g_OnAskPlacement_Forward);
	Call_PushCell(client);
	Call_Finish(dummy);
}

void StartRound()
{
	if (!ND_RoundStarted())
		ServerCommand("mp_minplayers 1");
}

bool IsReadyForBalance(int client, bool roundStarted)
{
	int team = GetClientTeam(client);
	
	// If the round is started, only shuffle players not afk or ones that changed their team
	if (!roundStarted)
		return !ND_IsCheckedAFK(client) || team != TEAM_UNASSIGNED;
	
	// If the round is not started, only shuffle players currenly on a team
	return team > TEAM_SPEC;
}

int GetSkillLevel(int client)
{
	int level = ND_RetreiveLevel(client);
	int sFloor = ND_GetSkillFloor(client);
	
	/* Load all skill floored clients before they spawn */
	if (sFloor >= 80)
		level = 80;
	
	/* Load all level 80 clients before they spawn */
	else if (ND_EXPAvailible(client) && ND_GetClientEXP(client) >= gcLevelEighty.IntValue)
		level = 80;
	
	return ND_GPS_AVAILBLE() ? ND_GetRoundedPSkill(client) : level;
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
	
	// Make the nd afk natives optional
	MarkNativeAsOptional("ND_IsPlayerMarkedAFK");
	MarkNativeAsOptional("ND_IsPlayerCheckedAFK");
	return APLRes_Success;
}

public Native_WarmupTeamBalance(Handle plugin, int numParms)
{
	bool force = GetNativeCell(1);
	
	if (force)
		BalanceTeams();
	
	else
	{
		// Pull all clients out of spectator using asynchronous forwards.
		PullSpectators();
		
		// Check and balance teams afterwards to avoid a race condition.
		CreateTimer(3.0, TIMER_CheckBalanceTeams, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	
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
