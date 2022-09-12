#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <nd_rounds>
#include <nd_teampick>
#include <nd_spec>
#include <nd_com_eng>
#include <nd_redstone>
#include <autoexecconfig>
#include <nd_shuffle>
#include <nd_rstart>
#include <nd_fskill>
#include <nd_print>

#define TEAMS_EVEN 0
#define EMPIRE_PLUS_ONE 1
#define CONSORT_PLUS_ONE -1

public Plugin myinfo =
{
	name = "[ND] Team Balancer R6",
	author = "Stickz",
	description = "Provides many team balance benefits to ND.",
	version = "recompile",
	url = "https://github.com/stickz/Redstone"
};

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_team_balancer_v6/nd_team_balancer_v6.txt"
#include "updater/standard.sp"

ConVar cvarEnableBalancer;
ConVar cvarMaxTeamPickReplace;

ConVar cvarMinPlaceSkillCount;

ConVar cvarNonAgreeanceLevelOne;
ConVar cvarNonAgreeanceLevelTwo;

ConVar cvarMinPlaceSkillEven;
ConVar cvarMinPlaceSkillOne;

ConVar cvarMinPlacementEvenLevel;
ConVar cvarMinPlacementTwoLevel;

ConVar cvarMinPlacementEvenSkill;
ConVar cvarMinPlacementTwoSkill;

bool bTeamsLocked = false;

public void OnPluginStart()
{
	AddCommandListener(PlayerJoinTeam, "jointeam");
	LoadTranslations("nd_common.phrases");
	LoadTranslations("nd_tbalance.phrases");
	
	CreatePluginConVars(); //plugin convars

	AddUpdaterLibrary(); //auto-update
}

void CreatePluginConVars()
{
	AutoExecConfig_Setup("nd_tbalance2");
	
	cvarEnableBalancer 				= 	AutoExecConfig_CreateConVar("sm_balance", "1", "Team Balancer: 0 to disable, 1 to enable");
	
	cvarMinPlaceSkillCount			=	AutoExecConfig_CreateConVar("sm_balance_mskill_count", "3", "Specifies min amount of players to place by skill");
	
	cvarNonAgreeanceLevelOne 		=	AutoExecConfig_CreateConVar("sm_balance_non_lagree_one", "20", "Specifies the threshold to place one extra if levels don't agree");
	cvarNonAgreeanceLevelTwo 		=	AutoExecConfig_CreateConVar("sm_balance_non_lagree_two", "40", "Specifies the threshold to place two extra if levels don't agree");	
	
	cvarMaxTeamPickReplace			=	AutoExecConfig_CreateConVar("sm_balance_tp_replace", "40", "Maxium skill difference to put player back on picked team");
	
	cvarMinPlaceSkillEven 			=	AutoExecConfig_CreateConVar("sm_balance_mskill_even", "60", "Specifies min player skill to place when teams are even");
	cvarMinPlaceSkillOne 			=	AutoExecConfig_CreateConVar("sm_balance_mskill_one", "80", "Specifies min player skill to place two extra players");
	
	cvarMinPlacementEvenLevel		=	AutoExecConfig_CreateConVar("sm_balance_one_level", "40", "Specifies level difference to place when teams are even");
	cvarMinPlacementTwoLevel		=	AutoExecConfig_CreateConVar("sm_balance_two_level", "80", "Specifies level difference to place two extra players");
	
	cvarMinPlacementEvenSkill		=	AutoExecConfig_CreateConVar("sm_balance_one_skill", "80", "Specifies skill difference to place when teams are even");
	cvarMinPlacementTwoSkill		=	AutoExecConfig_CreateConVar("sm_balance_two_skill", "160", "Specifies skill difference to place two extra players");	
	
	AutoExecConfig_EC_File();
}

public void OnMapStart() {
	bTeamsLocked = false;
}

public void ND_OnTeamsShuffled(bool phase2)
{
	if (phase2)
	{
		bTeamsLocked = true;
		CreateTimer(90.0, TIMER_UnlockTeams, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void ND_OnShuffleAskPlacement(int client) 
{
	// Place the person on a random team if the option is a choice
	if (!DoPlayerJoinTeam(client, true))
	{
		SetClientTeam(client, getRandomTeam());
	}
}

public Action ND_OnPlayerLockSpec(int client, int team)
{
	if (bTeamsLocked)
		return Plugin_Handled;

	return Plugin_Continue;
}

/* Disable team locking after warmup balance */
public Action TIMER_UnlockTeams(Handle timer)
{
	PrintToAdmins("\x05[TB] Team balancer locks disabled!", "a");
	bTeamsLocked = false;
}

public Action PlayerJoinTeam(int client, char[] command, int argc) 
{
	// Use team join action to decide if player can pick their team or not
	return DoPlayerJoinTeam(client, false) ? Plugin_Handled : Plugin_Continue;
}

// Return true to block, return false to not block
bool DoPlayerJoinTeam(int client, bool fake)
{
	// Block this feature if team mode is running during the warmup
	if (!ND_RoundStarted() && (IsTeamPickRunning() || ND_GetTeamPicking()))
		return false;
	
	// If the team balancer is disabled, allow team joining
	if (!cvarEnableBalancer.BoolValue)
		return false;
	
	// If the client is valid 
	if (IsValidClient(client))
	{		
		int team = GetClientTeam(client);
		
		// If the player is locked in spec, block team joining
		if (PlayerIsTeamLocked(client, team))
			return true;

		// if the client is not currently on a team
		if (team < 2)
		{	
			// If the player was placed by team pick, block team joining
			if (!fake && PlaceByTeamPick(client))
				return true;
			
			// If the player was placed by skill, block team joining
			if (PlaceTeamBySkill(client, fake))
				return true;

			// If the player was placed by less players, block team joining
			if (PlacedTeamLessPlayers(client, fake))
				return true;

			// Otherwise, allow the client to choose their team
			return false;	
		}
		
		// Disable direct team switching, to properly balance teams
		PutIntoSpecator(client);	
		return true;
	}
	
	// If the client is not valid, they must be a bot or something
	return false;
}

bool PlacedTeamLessPlayers(int client, bool fake)
{
	// If teams are not even by player count
	int overBalance = getOverBalance();
	if (overBalance != TEAMS_EVEN)
	{
		// Put them on the team with less players		
		int lessPlayers = getLessPlayerTeam(overBalance);
		SetTeamLessPlayers(client, lessPlayers, fake);
		return true;
	}
	
	return false;
}

bool PlaceByTeamPick(int client)
{
	// If we haven't picked teams this map or the player hasn't been picked
	if (!ND_TeamsPickedThisMap() || !ND_PlayerPicked(client))
		return false; // Exit the function and move on
	
	// Get the overbalance and the client's picked team
	int overBalance = getOverBalance();
	int pickedTeam = ND_GetPickedTeam(client);
					
	// If the picked team currently has less players
	if (getLessPlayerTeam(overBalance) == pickedTeam)
	{
		// Put the client back on the picked team
		SetPickedTeam(client, pickedTeam);
		return true;
	}
	
	// If the team count is even and the player was picked on a team
	else if (overBalance == TEAMS_EVEN && pickedTeam != TEAM_SPEC)
	{
		// Get the team difference varriables
		float teamDiff = ND_GetTeamDifference();
		int actualLSTeam = getLeastStackedTeam(teamDiff);
		float pTeamDiff = SetPositiveSkill(teamDiff);
		
		// If the picked team is the least stacked or the team difference is 40 skill or less
		if (actualLSTeam == pickedTeam || pTeamDiff <= cvarMaxTeamPickReplace.FloatValue)
		{
			// Put the client back on the picked team
			SetPickedTeam(client, pickedTeam);
			return true;
		}		
	}
	
	return false;
}

bool PlaceTeamBySkill(int client, bool fake)
{
	// Require three players on a team, to place by skill
	int onTeamCount = RED_OnTeamCount();
	if (onTeamCount < cvarMinPlaceSkillCount.IntValue)
		return false;
	
	// Get the current player skill, clamp it to 80 for now
	float playerSkill = ND_GetPlayerSkillEx(client, 80.0);
	
	// Get the team with less players
	int overBalance = getOverBalance();
	
	// Get the team difference, clamp skill values to 80 for now
	float teamDiffLevel = ND_GetCeilingSD(80.0);
	float pTeamDiffLevel = SetPositiveSkill(teamDiffLevel);
	
	// Get the actual team difference without a clamp
	float teamDiffSkill = ND_GetTeamDifference();
	float pTeamDiffSkill = SetPositiveSkill(teamDiffSkill);
	
	// Get the team with less skill according the team difference
	int actualLSTeamLevel = getLeastStackedTeam(teamDiffLevel);
	int actualLSTeamSkill = getLeastStackedTeam(teamDiffSkill);
	
	// Get if the level and skill team difference agrees
	bool equalLSTeam = actualLSTeamLevel == actualLSTeamSkill;
	
	if (overBalance == TEAMS_EVEN && PutSamePlysLessSkill(playerSkill, pTeamDiffLevel, pTeamDiffSkill, equalLSTeam))
	{
		// Place the player on the least stacked skill team
		SetTeamLessSkill(client, actualLSTeamSkill, fake);
		return true;
	}
	
	// if consort has one more player and less skill
	else if (PutTwoExtraLessSkill(playerSkill, pTeamDiffLevel, pTeamDiffSkill, equalLSTeam))
	{
		// If empire has one more player and less skill
		if (overBalance == EMPIRE_PLUS_ONE && actualLSTeamSkill == TEAM_EMPIRE)
		{
			// Place the player on team empire
			SetTeamLessSkill(client, TEAM_EMPIRE, fake);
			return true;
		}
			
		// if consort has one more player and less skill
		else if (overBalance == CONSORT_PLUS_ONE && actualLSTeamSkill == TEAM_CONSORT)
		{
			// Place the player on team consort
			SetTeamLessSkill(client, TEAM_CONSORT, fake);
			return true;
		}
	}
	
	return false;
}

bool PutSamePlysLessSkill(float pSkill, float pDiffLevel, float pDiffSkill, bool equalLSTeam)
{
	// If the player skill is less than the threshold to place them on a team
	if (pSkill < cvarMinPlaceSkillEven.IntValue)
		return false;
	
	// If the level teamdiff is within the placement threshold
	if (equalLSTeam && pDiffLevel >= cvarMinPlacementEvenLevel.IntValue)
		return true;
	
	// If the skill teamdiff is within the placement threshold
	if (pDiffSkill >= cvarMinPlacementEvenSkill.IntValue)
	{
		// If level & skill diff don't agree and level diff greater than threshold - exit
		if (!equalLSTeam && pDiffLevel > cvarNonAgreeanceLevelOne.IntValue)
			return false;
		
		// Otherwise place the player on the least stacked team by level
		return true;
	}
	
	return false;
}

bool PutTwoExtraLessSkill(float pSkill, float pDiffLevel, float pDiffSkill, bool equalLSTeam)
{
	// If the player skill is less than the threshold to place them on a team
	if (pSkill < cvarMinPlaceSkillOne.IntValue)
		return false;
	
	// If the level teamdiff is within the placement threshold
	if (equalLSTeam && pDiffLevel >= cvarMinPlacementTwoLevel.IntValue)
		return true;
	
	// If the skill teamdiff is within the placement threshold
	if (pDiffSkill >= cvarMinPlacementTwoSkill.IntValue)
	{
		// If level & skill diff don't agree and level diff greater than threshold - exit
		if (!equalLSTeam && pDiffLevel > cvarNonAgreeanceLevelTwo.IntValue)
			return false;
		
		// Otherwise place the player on the least stacked team by level
		return true;
	}
	
	return false;
}

void SetClientTeam(int client, int team)
{
	ChangeClientTeam(client, TEAM_SPEC);
	ChangeClientTeam(client, team);
	
	// Get the name of the client
	char Name[32];
	GetClientName(client, Name, sizeof(Name));
	
	// Format the message with client name, prints to admins
	char Message[64];
	Format(Message, sizeof(Message), "\x05[TB] Placed %s on %s.", Name, ND_GetTeamName(team));
	PrintToAdmins(Message, "b");
}

void SetPickedTeam(int client, int team)
{
	SetClientTeam(client, team);
	PrintMessage(client, "Placed Picked Team"); // Placed back on orginal team
}

void SetTeamLessPlayers(int client, int team, bool fake)
{
	SetClientTeam(client, team);
	
	if (!fake) // Don't display a message about placement if team shuffle moves a player
		PrintMessage(client, "Placed Less Players"); // Placed on team with less players
}
void SetTeamLessSkill(int client, int team, bool fake)
{
	SetClientTeam(client, team);
	
	if (!fake) // Don't display a message about placement if team shuffle moves a player
		PrintMessage(client, "Placed Less Skill"); // Placed on team with less skill
}
void PutIntoSpecator(int client)
{
	ChangeClientTeam(client, TEAM_SPEC);
	PrintMessage(client, "Retry Placement");
}

float SetPositiveSkill(float skill) {
	return skill < 0 ? skill * -1.0 : skill;
}

bool PlayerIsTeamLocked(int client, int team)
{
	if (ND_AdminSpecLock(client))
	{
		PrintMessage(client, "Admin Lock Spectator"); // Server admin locked you into spectator until round end!
		return true;
	}
	
	if (ND_PlySpecLock(client))
	{
		PrintMessage(client, "Revoke Spectator"); // You must revoke spectator! To join type !spec
		return true;	
	}
	
	if (ND_IsCommander(client)) //Fix switching team while commander bug
	{
		PrintMessage(client, "Resign Switch"); // You must resign from commander before switching teams
		return true;
	}
	
	if (bTeamsLocked && getPositiveOverBalance() < 2 && team > 1)
		return true;
	
	return false;
}
