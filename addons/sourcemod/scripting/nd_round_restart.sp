#include <sourcemod>
#include <nd_stocks>
#include <nd_redstone>
#include <nd_warmup>
#include <nd_rounds>
#include <nd_print>

#define RESTART_COMMANDS_SIZE 	3

char nd_restart_commands[RESTART_COMMANDS_SIZE][] = 
{
	"restart",
	"restart map",
	"restart match"
};

/* For auto updater support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_round_restart/nd_round_restart.txt"
#include "updater/standard.sp"  

public Plugin myinfo =
{
	name = "[ND] Round Restart ",
	author = "Stickz",
	description = "Allows player to vote to restart the round",
	version = "recompile",
	url = "https://github.com/stickz/Redstone"
}

int voteCount;
bool timeout = false;
bool passed = false;
bool g_hasVoted[MAXPLAYERS+1] = {false, ... };

ConVar cvarMinPlayers;
ConVar cvarTimeWindow;
ConVar cvarPercentPass;
ConVar cvarPercentPassEX;
ConVar cvarRestartDelay;
  
public void OnPluginStart() 
{
	RegConsoleCmd("sm_restart", CMD_RestartTheRound);
	
	LoadPluginTranslations(); // load translations
	CreatePluginConvars(); // create convars
	
	AddUpdaterLibrary(); //auto-updater
	
	// Late loading support for plugin
	if (ND_RoundStarted())
		StartRestartTimeout();
}

public void ND_OnRoundStarted()
{
	voteCount = 0;
	timeout = false;
	passed = false;
	
	for (int client = 1; client <= MaxClients; client++) {
		g_hasVoted[client] = false;	
	}
	
	StartRestartTimeout();
}

public void OnClientDisconnected(int client) {
	resetValues(client);
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (client)
	{
		for (int idx = 0; idx < RESTART_COMMANDS_SIZE; idx++)
		{
			if (strcmp(sArgs, nd_restart_commands[idx], false) == 0) 
			{
				callRestartTheRound(client);
				return Plugin_Handled;
			}		
		}	
	}
	
	return Plugin_Continue;
}

public Action CMD_RestartTheRound(int client, int args)
{
	callRestartTheRound(client);
	return Plugin_Handled;
}

public Action TIMER_TimeoutRestart(Handle timer) {
	timeout = true;
}

void StartRestartTimeout()
{
	float seconds = cvarTimeWindow.FloatValue * 60;
	CreateTimer(seconds, TIMER_TimeoutRestart, _, TIMER_FLAG_NO_MAPCHANGE);	
}

void LoadPluginTranslations()
{
	LoadTranslations("numbers.phrases");
	LoadTranslations("nd_common.phrases");
	LoadTranslations("nd_round_restart.phrases");
}

void CreatePluginConvars()
{
	cvarMinPlayers		= 	CreateConVar("sm_restart_minp", "6", "Set's the min players to pass restart regardless of player count.");
	cvarTimeWindow		= 	CreateConVar("sm_restart_time", "8", "Set's how many minutes after round start, to restart with a lower threshold");
	cvarPercentPass		= 	CreateConVar("sm_restart_percent", "40", "Set's percent to restart the round before the timeout");
	cvarPercentPassEX 	= 	CreateConVar("sm_restart_percentex", "51", "Set's percent to restart the round after the timeout"); 
	cvarRestartDelay	=	CreateConVar("sm_restart_delay", "4.5", "Specifies how many seconds to wait before restarting round on pass"); 

	AutoExecConfig(true, "nd_round_restart");
}

void resetValues(int client)
{
	if (g_hasVoted[client])
	{
		g_hasVoted[client] = false;
		checkForPass();
	}	
}

void callRestartTheRound(int client)
{
	if (!ND_WarmupCompleted() && !ND_RoundStarted())
		PrintMessage(client, "Round Start Usage");
	
	else if (ND_RoundEnded())
		PrintMessage(client, "Round End Usage");
	
	else if (g_hasVoted[client])
		PrintMessage(client, "Already Voted");
	
	else if (passed)
		PrintMessage(client, "Restart Passed");

	else
	{
		voteCount++;		
		g_hasVoted[client] = true;
		checkForPass(true, client);		
	}	
}

void checkForPass(bool display = false, int client = -1) 
{
	// Get the percentage required to pass the vote, based on the timeout feature
	float passPercent = timeout ? cvarPercentPassEX.FloatValue : cvarPercentPass.FloatValue;
	
	// Get the number of players required to pass the vote
	float countFloat = ND_GetClientCount() * (passPercent / 100.0);
	
	// Get the min & max number of players required to pass the vote
	int maxPass = RoundToNearest(countFloat);
	int minPass = cvarMinPlayers.IntValue;
	
	// Set the number of required vote required to the pass the vote
	int reqVotes = maxPass > minPass ? maxPass : minPass;
	
	// Get the remaining number of votes required to pass the restart
	int remainder = reqVotes - voteCount;
	
	// If there's no votes left, do the restart - it's passed
	if (remainder <= 0)
		prepRoundRestart();
	
	// else if display the vote, then show how many votes are left
	else if (display)
		displayVotes(remainder, client);
}

void displayVotes(int Remainder, int client)
{	
	char name[64];
	GetClientName(client, name, sizeof(name));
	
	PrintToChatAll("\x05%t", "Typed Restart Match", name, NumberInEnglish(Remainder));
}

void prepRoundRestart()
{
	// Signal to the plugin the vote has passed
	passed = true;
	
	// Create a delay before restarting, to notify players what is happening
	CreateTimer(cvarRestartDelay.FloatValue, TIMER_RestartRoundNow, _, TIMER_FLAG_NO_MAPCHANGE);
	
	// Tell everyone the round is restarting shortly
	PrintToChatAll("%s %t.", PREFIX, "Restarting Now"); //Restart Successful: The round will restart in five seconds.
}

public Action TIMER_RestartRoundNow(Handle timer)
{
	// If the round is not started, then proceed to the next map instead
	if (!ND_RoundStarted())
		return Plugin_Continue;
			
	// Tell the round engine to restart, without a warmup round
	else
	{
		ND_RestartRound(false);
		return Plugin_Stop;
	}
}

/* Natives */
//typedef NativeCall = function int (Handle plugin, int numParams);

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_GetRestartStatus", Native_GetRtvStatus);
	CreateNative("ND_ToogleRestartStatus", Native_ToogleRtvStatus);
	return APLRes_Success;
}

public int Native_GetRtvStatus(Handle plugin, int numParams) {
	return timeout;
}

public int Native_ToogleRtvStatus(Handle plugin, int numParams) {
	timeout = GetNativeCell(1);
}
