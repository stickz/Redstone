#include <sourcemod>
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
	
	g_Cvar[enableWarmupBalance] 	=	CreateConVar("sm_warmup_balance", "1", "Warmup Balancer: 0 to disable, 1 to enable");
	g_Cvar[minPlayersForBalance]	=	CreateConVar("sm_warmup_bmin", "6", "Sets minium number of players for warmup balance");
	
	AutoExecConfig(true, "nd_rstart"); // store convars
	
	AddUpdaterLibrary(); //auto-updater
}

public void OnMapEnd() {
	ClearCountDownHandle(); // for countdown.sp
}

void StartRound(bool teampick = false)
{
	if (teampick)
	{
		PrintToChatAll("\x05Join the RedstoneND steam group!");
		ServerCommand("mp_minplayers 1");
	}	
}
