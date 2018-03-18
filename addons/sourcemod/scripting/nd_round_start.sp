#include <sourcemod>
#include <nd_stocks>
#include <nd_rounds>
#include <nd_warmup>
#include <nd_shuffle>
 
public Plugin myinfo =
{
	name = "[ND] Round Start ",
	author = "Xander, Stickz",
	description = "Starts the round when triggered",
	version = "dummy",
	url = "https://github.com/stickz/Redstone"
}

enum Convars
{
	ConVar:enableWarmupBalance,
	ConVar:minPlayersForBalance
};
ConVar g_Cvar[Convars];

/* Include different modules of plug-in */
#include "nd_rstart/countdown.sp"
#include "nd_rstart/nextpick.sp"
#include "nd_rstart/start.sp"
#include "nd_rstart/natives.sp"

/* For auto updater support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_round_start/nd_round_start.txt"
#include "updater/standard.sp"
  
public void OnPluginStart() 
{
	RegCommandsCountDown(); // for countdown.sp
	RegNextPickCommand(); // for nextpick.sp
	
	CreatePluginConvars(); // for convars
	
	// Too lazy to seperate "Balancer Off" phrase
	LoadTranslations("nd_warmup.phrases");
	
	AddUpdaterLibrary(); //auto-updater
}

public void OnMapStart() 
{
	SetVarDefaults();
	
	ServerCommand("bot_quota 0"); //Make sure bots are disabled
}

public void OnMapEnd()
{
	ClearCountDownHandle(); // for countdown.sp
	
	InitiateRoundEnd();
}

public void ND_OnRoundEnded() {
	InitiateRoundEnd();	
}

void InitiateRoundEnd()
{
	ServerCommand("mp_minplayers 32");
	ServerCommand("sm_cvar sv_alltalk 1");
}

void SetVarDefaults() {
	currentlyPicking = false;
}

void CreatePluginConvars()
{
	g_Cvar[enableWarmupBalance] 	=	CreateConVar("sm_warmup_balance", "1", "Warmup Balancer: 0 to disable, 1 to enable");
	g_Cvar[minPlayersForBalance]	=	CreateConVar("sm_warmup_bmin", "6", "Sets minium number of players for warmup balance");
	
	AutoExecConfig(true, "nd_rstart"); // store convars
}

void StartRound(bool teampick = false, bool balance = false)
{
	if (teampick)
		PrintToChatAll("\x05Join the RedstoneND steam group!");

	else if (!balance)
		PrintToChatAll("\x05[TB] %t", "Balancer Off");
		
	ServerCommand("mp_minplayers 1");
}
