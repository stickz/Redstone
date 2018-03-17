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
