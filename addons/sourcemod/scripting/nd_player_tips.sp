#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <nd_stocks>
#include <nd_print>
#include <nd_rounds>
#include <nd_entities>
#include <nd_structures>
#include <nd_breakdown>
#include <nd_classes>
#include <nd_redstone>
#include <nd_resources>

public Plugin myinfo =
{
	name = "[ND] Player Tips",
	author = "Stickz, Adam, Gallo",
	description = "Creates triggered tips for players",
	version = "dummy",
	url = "https://github.com/stickz/Redstone/"
};

/* Auto Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_player_tips/nd_player_tips.txt"
#include "updater/standard.sp"

#include "nd_player_tips/clientprefs.sp"
#include "nd_player_tips/resource_capture.sp"
#include "nd_player_tips/bunker_message.sp"
#include "nd_player_tips/health_message.sp"

public void OnPluginStart()
{
	LoadTranslations("nd_player_tips.phrases");
	
	HookResourceEvents(); // For break capture message
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	
	AddClientPrefsSupport(); // Add client prefs support
	AddUpdaterLibrary(); // Add updater support
}

public void ND_OnRoundStarted() {
	HookBunkerEntity(); //For bunker health warnings	
	ResetDisplayedHealth(); // For player health warnings
}

public void ND_OnRoundEndedEX() {
	UnHookBunkerEntity(); //For bunker health warnings
}
