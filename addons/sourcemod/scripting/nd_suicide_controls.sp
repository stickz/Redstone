#include <sourcemod>
#include <sdktools>
#include <autoexecconfig>

#include <nd_print>
#include <nd_rounds>
#include <nd_stocks>
#include <nd_com_eng>
#include <nd_entities>

#define KILL_COMMANDS_SIZE 6

public Plugin myinfo =
{
	name = "[ND] Suicide Controls",
	author = "stickz",
	description = "Restricts the usage of the kill command",
	version = "dummy",
	url = "https://github.com/stickz/Redstone/"	
};

/* Auto-Updater */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_suicide_controls/nd_suicide_controls.txt"
#include "updater/standard.sp"

ConVar cvarSuicideChance;
ConVar cvarSuicideDelayMin;
ConVar cvarSuicideDelayMax;
ConVar cvarSuicideDelayBunker;
ConVar cvarSuicideBunkerDist;

char nd_kill_commands[KILL_COMMANDS_SIZE][] =
{
	"stuck",
	"i'm stuck",
	"im stuck",
	"i am stuck",
	"suicide",
	"die"};
	
public void OnPluginStart()
{
	/* Related to player suicide */
	RegKillCommands(); // Chat commands to suicide
	AddCommandListener(Command_InterceptSuicide, "kill"); // Interrupt for console suicide
	
	CreatePluginConvars(); // Plugin controls for sucide	
		
	AddUpdaterLibrary(); //Auto-Updater
	
	/* Translations for print-outs */
	LoadTranslations("nd_tools.phrases");
	LoadTranslations("numbers.phrases");
}

void CreatePluginConvars()
{
	AutoExecConfig_Setup("nd_suicide");
	
	cvarSuicideChance = AutoExecConfig_CreateConVar("sm_suicide_chance", "25", "Set's chance of using min or max value");
	cvarSuicideDelayMin = AutoExecConfig_CreateConVar("sm_suicide_delay_min", "7", "Set min suicide delay");
	cvarSuicideDelayMax = AutoExecConfig_CreateConVar("sm_suicide_delay_max", "12", "Set max suicide delay");
	cvarSuicideDelayBunker = AutoExecConfig_CreateConVar("sm_suicide_delay_bunker", "5", "Set suicide delay when close to bunker");
	cvarSuicideBunkerDist = AutoExecConfig_CreateConVar("sm_suicide_bunker_dist", "850", "Sets distance away from bunker for faster suicide");
	
	AutoExecConfig_EC_File();
}

void RegKillCommands()
{
	RegConsoleCmd("sm_kill", Command_killme);
	RegConsoleCmd("sm_die", Command_killme);
	RegConsoleCmd("sm_suicide", Command_killme);
	RegConsoleCmd("sm_stuck", Command_killme);	
}

public Action Command_killme(int client, int args)
{   
	commitSucide(client);	
	return Plugin_Handled;        
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (client && GetClientTeam(client) > 1)
	{
		for (int idx = 0; idx < KILL_COMMANDS_SIZE; idx++)
		{
			if (strcmp(sArgs, nd_kill_commands[idx], false) == 0)
			{
				new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);

				commitSucide(client);
					
				SetCmdReplySource(old);
				return Plugin_Stop;
			}
		}
	}
	return Plugin_Continue
}

public Action Command_InterceptSuicide(int client, const char[] command, int args)
{
	if (client && GetClientTeam(client) > 1)
	{	
		commitSucide(client);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

void commitSucide(int client)
{
	if (IsPlayerAlive(client))
	{	
		int delay = 0;
		
		// If the client is close to the bunker, allow a faster sucide
		if (getBunkerDistance(client) <= cvarSuicideBunkerDist.FloatValue)
			delay = cvarSuicideDelayBunker.IntValue;
		
		// Otherwise set suicide delay to a random value default 7-12s
		else
			delay = getRandomSuicideDelay();

		if (delay == 0 || ND_IsCommander(client) || !ND_RoundStarted())
		{
			ForcePlayerSuicide(client);
			return;
		}
		
		PrintToChat(client, "\x05[xG] %t", "Suicide Request", NumberInEnglish(delay));
		CreateTimer(float(delay), TIMER_DelayedSucide, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

float getBunkerDistance(int client)
{
	float clientDistance[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientDistance);
	
	int team = GetClientTeam(client);
	return ND_GetBunkerDistance(team, clientDistance);	
}

int getRandomSuicideDelay()
{
	// Get the min and max values to use for sucide delay
	int min = cvarSuicideDelayMin.IntValue;
	int max = cvarSuicideDelayMax.IntValue;	
	
	// Get the chance of using etheir min or max
	// Generate random number for that chance
	int chance = cvarSuicideChance.IntValue;	
	int rNum = GetRandomInt(1, 100);
	
	// If the chance passes, return min or max
	if (rNum <= chance) // Split in half to decide which one
		return rNum <= chance / 2 ? max : min;

	// Otherwise, return anther random number
	return GetRandomInt(min, max);
}

public Action TIMER_DelayedSucide(Handle timer, any Userid)
{
	// If the client is invalid, return
	int client = GetClientOfUserId(Userid);	
	if (client == INVALID_USERID)
		return Plugin_Handled;
	
	// If the client is alive, kill them
	if (IsPlayerAlive(client))
		ForcePlayerSuicide(client);

	return Plugin_Handled;
}
