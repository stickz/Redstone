#include <sourcemod>
#include <nd_stocks>
#include <nd_spec>
#include <nd_redstone>
#include <nd_fskill>
#include <nd_teampick>
#include <nd_shuffle>
#include <nd_print>
#include <nd_rstart>
#include <nd_rounds>
#include <nd_com_eng>
#include <autoexecconfig>
#include <smlib/math>

#define TEAMS_EVEN 0
#define EMPIRE_PLUS_ONE 1
#define CONSORT_PLUS_ONE -1

public Plugin myinfo =
{
	name = "[ND] Team Balancer R5",
	author = "Stickz",
	description = "Provides many team balance benefits to ND.",
	version = "recompile",
	url = "https://github.com/stickz/Redstone"
};

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_team_balancer_v5/nd_team_balancer_v5.txt"
#include "updater/standard.sp"

ConVar cvarEnableBalancer;
ConVar cvarMaxTeamPickReplace;

ConVar cvarMaxPlysStrictPlace;
ConVar cvarMinPlaceSkillCount;

ConVar cvarMinPlaceSkillEven;
ConVar cvarMinPlaceSkillOne;

ConVar cvarMinPlacementEven;
ConVar cvarMinPlacementTwo;
ConVar cvarMinPlacementTwoStrict;

ConVar cvarMinCommanderOffsetLow;
ConVar cvarMinCommanderOffsetHigh
ConVar cvarPercentCommanderOffsetLow;
ConVar cvarPercentCommanderOffsetHigh;
ConVar cvarMaxSkillCommanderOffset;

bool bTeamsLocked = false;

public void OnPluginStart()
{
	AddCommandListener(PlayerJoinTeam, "jointeam");
	LoadTranslations("nd_common.phrases");
	LoadTranslations("nd_tbalance.phrases"); 
	
	CreatePluginConVars(); //plugin convars

	AddUpdaterLibrary(); //auto-updater
}

void CreatePluginConVars()
{
	AutoExecConfig_Setup("nd_tbalance");
	
	cvarEnableBalancer 				= 	AutoExecConfig_CreateConVar("sm_balance", "1", "Team Balancer: 0 to disable, 1 to enable");
	
	cvarMaxTeamPickReplace			=	AutoExecConfig_CreateConVar("sm_balance_tp_replace", "40", "Maxium skill difference to put player back on picked team");
	
	cvarMaxPlysStrictPlace			=	AutoExecConfig_CreateConVar("sm_balance_strict_count", "8", "Specifies max players for strict placement");
	cvarMinPlaceSkillCount			=	AutoExecConfig_CreateConVar("sm_balance_mskill_count", "3", "Specifies min amount of players to place by skill");
		
	cvarMinPlaceSkillEven 			=	AutoExecConfig_CreateConVar("sm_balance_mskill_even", "60", "Specifies min player skill to place when teams are even");
	cvarMinPlaceSkillOne 			=	AutoExecConfig_CreateConVar("sm_balance_mskill_one", "90", "Specifies min player skill to place two extra players");
	
	cvarMinPlacementEven			=	AutoExecConfig_CreateConVar("sm_balance_one", "80", "Specifies team difference to place when teams are even");
	cvarMinPlacementTwo				=	AutoExecConfig_CreateConVar("sm_balance_two", "160", "Specifies team difference to place two extra players");
	cvarMinPlacementTwoStrict 		=	AutoExecConfig_CreateConVar("sm_balance_two_strict", "120", "Specifies team difference to place two extra players strictly");
	
	cvarMinCommanderOffsetLow		=	AutoExecConfig_CreateConVar("sm_balance_offset_low_min", "60", "Specifies the minimum commander skill difference to enable low offsets");
	cvarMinCommanderOffsetHigh		=	AutoExecConfig_CreateConVar("sm_balance_offset_high_min", "100", "Specifies the minimum commander skill difference to enable high offsets");
	cvarPercentCommanderOffsetLow	=	AutoExecConfig_CreateConVar("sm_balance_offset_low_percent", "50", "Specifies the percentage of the skill difference to use as the low offset");
	cvarPercentCommanderOffsetHigh	=	AutoExecConfig_CreateConVar("sm_balance_offset_high_percent", "75", "Specifies the percentage of the skill difference to use as the high offset");
	cvarMaxSkillCommanderOffset		=	AutoExecConfig_CreateConVar("sm_balance_offset_max_skill", "90", "Specifies the maximum commander skill to enable commander offsets");
	
	AutoExecConfig_EC_File();
}

public void OnMapStart() {
	bTeamsLocked = false;
}

// Print a message to admins if a player disconnects during team locks
public void OnClientDisconnect(int client)
{
	if (bTeamsLocked && !IsFakeClient(client))
	{
		// Get the name of the client
		char Name[32];
		GetClientName(client, Name, sizeof(Name));
		
		// Format the message with client name, prints to admins
		char Message[64];
		Format(Message, sizeof(Message), "\x05[TB] %s disconnected during team locks!", Name);
		PrintToAdmins(Message, "b");
	}
}

// Use team join action to decide if player can pick their team or not
public Action PlayerJoinTeam(int client, char[] command, int argc) 
{
	// Block this feature if team mode is running during the warmup
	if (!ND_RoundStarted() && IsTeamPickRunning())
		return Plugin_Continue;
	
	// If the team balancer is disabled, allow team joining
	if (!cvarEnableBalancer.BoolValue)
		return Plugin_Continue;
	
	// If the client is valid 
	if (IsValidClient(client))
	{		
		int team = GetClientTeam(client);
		// If the player is locked in spec, block team joining
		if (PlayerIsTeamLocked(client, team))
			return Plugin_Handled;
		
		// if the client is not currently on a team
		if (team < 2)
		{		
			// If the player was placed by team pick, block team joining
			if (PlaceByTeamPick(client))
				return Plugin_Handled;			

			// If the player was placed by skill, block team joining
			if (PlaceTeamBySkill(client))
				return Plugin_Handled;
			
			// If the player was placed by less players, block team joining
			if (PlacedTeamLessPlayers(client))
				return Plugin_Handled;
			
			// Otherwise, allow the client to choose their team
			return Plugin_Continue;
		}
		
		// Disable direct team switching, to properly balance teams
		PutIntoSpecator(client);	
		return Plugin_Handled;
	}	
	
	// If the client is not valid, they must be a bot or something
	return Plugin_Continue;
}

public void ND_OnTeamsShuffled()
{
	bTeamsLocked = true;
	CreateTimer(90.0, TIMER_UnlockTeams, _, TIMER_FLAG_NO_MAPCHANGE);
}

/* Disable team locking after warmup balance */
public Action TIMER_UnlockTeams(Handle timer)
{
	PrintToAdmins("\x05[TB] Team balancer locks disabled!", "a");
	bTeamsLocked = false;
}

bool PlaceTeamBySkill(int client)
{
	// Require three players on a team, to place by skill
	int onTeamCount = RED_OnTeamCount();
	if (onTeamCount < cvarMinPlaceSkillCount.IntValue)
		return false;
	
	// Get the current player skill
	float playerSkill = ND_GetPlayerSkill(client);
	
	// Get the team with less players
	int overBalance = getOverBalance();
	
	// Get the actual & ceiling skill difference
	float teamDiff = ND_GetTeamDifference();
	float cTeamDiff = ND_GetCeilingSD(80.0);
	
	// Get the commander offset skill difference
	float oTeamDiff = GetCommanderOffsetSD(teamDiff);
		
	// Get the team with less skill according to the actual, ceiling and commander offset team difference
	int actualLSTeam = getLeastStackedTeam(teamDiff);
	int ceilLSTTeam = getLeastStackedTeam(cTeamDiff);
	int offsetLSTTeam = getLeastStackedTeam(oTeamDiff);
	
	// Check if team difference methods agree on the team with less skill
	bool equalCeilLST = actualLSTeam == ceilLSTTeam; // actual and ceiling team difference
	bool equalOffsetLST = actualLSTeam == offsetLSTTeam; // actual and offset team difference
			
	// Convert the team difference to a positive number before working with it
	float pTeamDiff = SetPositiveSkill(teamDiff);
	float cpTeamDiff = SetPositiveSkill(cTeamDiff);
	float opTeamDiff = SetPositiveSkill(oTeamDiff);
		
	// If both teams have the same number of players and the conditions for team placement are meant
	if (overBalance == TEAMS_EVEN && PutSamePlysLessSkill(playerSkill, pTeamDiff, opTeamDiff, equalOffsetLST))
	{
		// Place the player on the least stacked skill team
		SetTeamLessSkill(client, actualLSTeam);
		return true;		
	}
	
	// If one team has an extra player and the conditions for team placement are meant
	else if (PutTwoExtraLessSkill(playerSkill, pTeamDiff, cpTeamDiff, opTeamDiff, onTeamCount, equalCeilLST, equalOffsetLST))
	{
		// If empire has one more player and less skill
		if (overBalance == EMPIRE_PLUS_ONE && actualLSTeam == TEAM_EMPIRE)
		{
			// Place the player on team empire
			SetTeamLessSkill(client, TEAM_EMPIRE);
			return true;
		}
			
		// if consort has one more player and less skill
		else if (overBalance == CONSORT_PLUS_ONE && actualLSTeam == TEAM_CONSORT)
		{
			// Place the player on team consort
			SetTeamLessSkill(client, TEAM_CONSORT);
			return true;				
		}			
	}

	return false;
}

bool PutSamePlysLessSkill(float pSkill, float pDiff, float opDiff, bool equalOffsetLST)
{
	// If the actual and offset team difference don't agree on the least stacked team
	if (!equalOffsetLST)
		return false;
	
	// If the player skill is less than the threshold to place them on a team
	if (pSkill < cvarMinPlaceSkillEven.IntValue)
		return false;
	
	// If the actual or commander offset teamdiff is within the placement threshold
	int placementThreshold = cvarMinPlacementEven.IntValue;
	if (pDiff >= placementThreshold || opDiff >= placementThreshold)
		return true;
	
	// Otherwise don't place the player on a team
	return false;	
}

bool PutTwoExtraLessSkill(float pSkill, float pDiff, float cpDiff, float opDiff, int tCount, bool equalCeilLST, bool equalOffsetLST)
{
	// If the actual and offset team difference don't agree on the least stacked team
	if (!equalOffsetLST)
		return false;
	
	// If the player skill is less than the threshold to place them on a team
	if (pSkill < cvarMinPlaceSkillOne.IntValue)
		return false;

	// If the actual or commander offset teamdiff is within the placement threshold
	int placementThreshold = cvarMinPlacementTwo.IntValue;
	if (pDiff >= placementThreshold || opDiff >= placementThreshold)
		return true;
	
	// If the actual & ceil teamdiff both agree on the least stacked team
	// If less than 10 players are on a team and the strict skill difference is 80 or higher
	if (equalCeilLST && tCount <= cvarMaxPlysStrictPlace.IntValue && cpDiff >= cvarMinPlacementTwoStrict.IntValue)
		return true;
	
	// Otherwise don't place the player on a team	
	return false;
}

float GetCommanderOffsetSD(float teamDiff)
{
	// If both teams don't have a commander, return the regular teamdiff
	if (!ND_TeamsHaveCommanders())
		return teamDiff;
	
	// Get the consort and empire commander - client indexs
	int consortCom = ND_GetCommanderOnTeam(TEAM_CONSORT);
	int empireCom = ND_GetCommanderOnTeam(TEAM_EMPIRE)
	
	// Get the consort and empire commander skill levels
	float consortSkill = ND_GetPlayerSkill(consortCom);
	float empireSkill = ND_GetPlayerSkill(empireCom);
	
	// If both commanders are above the skill threshold to enable offsets, disable them
	float maxOffsetSkillValue = cvarMaxSkillCommanderOffset.FloatValue;
	if (consortSkill > maxOffsetSkillValue && empireSkill > maxOffsetSkillValue)
		return teamDiff;
		
	// Calculate the skill difference between the consort commander and empire commander
	float skillDiff = consortSkill - empireSkill;
	
	// If the positive value of the skill difference is within the threshold, enable commander offsets
	float pSkillDiff = Math_Abs(skillDiff);
	
	// Use the higher commander offsets if within the high threshold
	if (pSkillDiff >= cvarMinCommanderOffsetHigh.FloatValue)
	{
		// Calculate the offset by multiplying the skill difference by the offset percent convar
		float highOffset = skillDiff * (cvarPercentCommanderOffsetHigh.FloatValue / 100.0);
		
		// Add the offset to the team difference and return it
		return teamDiff + highOffset;		
	}
	
	// Use the lower commander offsets if within the low threshold
	else if (pSkillDiff >= cvarMinCommanderOffsetLow.FloatValue)
	{
		// Calculate the offset by multiplying the skill difference by the offset percent convar
		float lowOffset = skillDiff * (cvarPercentCommanderOffsetLow.FloatValue / 100.0);
		
		// Add the offset to the team difference and return it
		return teamDiff + lowOffset;
	}
	
	// Return the regular team difference if not within the offset threshold 
	return teamDiff;
}

float SetPositiveSkill(float skill) {
	return skill < 0 ? skill * -1.0 : skill;
}

bool PlacedTeamLessPlayers(int client)
{
	// If teams are not even by player count
	int overBalance = getOverBalance();
	if (overBalance != TEAMS_EVEN)
	{
		// Put them on the team with less players		
		int lessPlayers = getLessPlayerTeam(overBalance);
		SetTeamLessPlayers(client, lessPlayers);
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

void SetPickedTeam(int client, int team)
{
	SetClientTeam(client, team);
	PrintMessage(client, "Placed Picked Team"); // Placed back on orginal team
}

void SetTeamLessPlayers(int client, int team)
{
	SetClientTeam(client, team);	
	PrintMessage(client, "Placed Less Players"); // Placed on team with less players
}
void SetTeamLessSkill(int client, int team)
{
	SetClientTeam(client, team);	
	PrintMessage(client, "Placed Less Skill"); // Placed on team with less skill
}
void PutIntoSpecator(int client)
{
	ChangeClientTeam(client, TEAM_SPEC);
	PrintMessage(client, "Retry Placement");
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
