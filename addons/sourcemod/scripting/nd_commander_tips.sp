#include <sourcemod>
#include <clientprefs>
#include <nd_stocks>
#include <nd_com_eng>
#include <nd_redstone>
#include <nd_rounds>

public Plugin myinfo =
{
	name = "[ND] Commander Tips",
	author = "Stickz, Adam, Amir",
	description = "Creates triggered tips for players",
	version = "dummy",
	url = "https://github.com/stickz/Redstone/"
};

/* Auto Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_commander_tips/nd_commander_tips.txt"
#include "updater/standard.sp"

#include "nd_com_tips/clientprefs.sp"
#include "nd_com_tips/commander_tips.sp"

#define TIP_DURATION 75.0

public void OnPluginStart()
{
	LoadTranslations("nd_commander_tips.phrases");
	
	AddClientPrefsSupport(); // For client prefs on/off
	AddUpdaterLibrary(); // Add updater support
}

public void ND_OnCommanderPromoted(int client, int team)
{
	if (option_commander_tips[client])
	{
		CreateTimer(TIP_DURATION, TIMER_DisplayCommanderTip, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}	
}

public Action TIMER_DisplayCommanderTip(Handle timer, any:Userid)
{
	// If the round is done, stop sending tips
	if (!ND_RoundStarted())
		return Plugin_Stop;
	
	// If the client is no longer valid, stop sendng tips
	int client = GetClientOfUserId(Userid);	
	if (client == 0 || !RED_IsValidClient(client)) //invalid userid/client
		return Plugin_Stop;	
		
	// If the client has turned off tips, stop sending them
	if (!option_commander_tips[client])
		return Plugin_Stop;	
		
	// If all the tips have been sent, stop sending tips
	int clientTeam = GetClientTeam(client);	
	if (teamCounter[clientTeam] > COMMANDER_TIPS_COUNT - 1)
		return Plugin_Stop;
	
	// Otherwise, send the next tip in the string list	
	int curTip = teamCounter[clientTeam];
	PrintToChat(client, "\x05(Commander Tip) \x03%t", nd_commander_tips[curTip]);
	teamCounter[clientTeam]++; // client team counter for next tip
	return Plugin_Continue;
}

public void ND_OnRoundStarted() 
{
	teamCounter[TEAM_EMPIRE] = 0;
	teamCounter[TEAM_CONSORT] = 0;
}
