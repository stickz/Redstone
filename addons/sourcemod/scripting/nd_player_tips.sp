#include <sourcemod>
#include <clientprefs>
#include <nd_stocks>
#include <nd_print>

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

public void OnPluginStart()
{
	LoadTranslations("nd_player_tips.phrases");
	
	HookResourceEvents(); // For break capture message
	
	AddClientPrefsSupport(); // Add client prefs support
	AddUpdaterLibrary(); // Add updater support
}

