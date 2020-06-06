#include <sourcemod>
#include <nd_maps>
#include <nd_print>
#include <nd_stocks>
#include <nd_resources>
#include <nd_res_trickle>

public Plugin myinfo = 
{
	name = "[ND] Resource Fracking",
	author = "Stickz",
	description = "Messages about resource fracking",
	version = "dummy",
	url = "https://github.com/stickz/Redstone/"
}

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_resource_fracking/nd_resource_fracking.txt"
#include "updater/standard.sp"

// Include client prefs support
#include "nd_res_frack/clientprefs.sp"

int primeFrackAmount = RES_MOD_PRIME_FRACKING;

public void OnPluginStart()
{
	LoadTranslations("nd_resource_fracking.phrases");
	AddClientPrefsSupport(); // Required for on/off
	AddUpdaterLibrary(); //auto-updater	
}

public void OnMapStart() 
{
	// Get the current map
	char currentMap[32];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	// Check if the current map is coast or corner
	bool cornerMap = ND_CustomMapEquals(currentMap, ND_Corner);
	bool coastMap = ND_StockMapEquals(currentMap, ND_Coast);
	
	// Set the primary resource fracking amount to 100% on these maps or partial on other maps
	primeFrackAmount = (cornerMap || coastMap) ? RES_MOD_PRIME_EXTRACT : RES_MOD_PRIME_FRACKING;
}

public void ND_OnResFrackStarted(int resType, float delay, int interval, int amount)
{
	if (resType == RESOURCE_PRIME)
		DisplayResFrackMessage("Prime Resource Fracking", primeFrackAmount, RES_MOD_PRIME_TRICKLE, RoundFloat(delay));
	
	else if (resType == RESOURCE_SECONDARY)
		DisplayResFrackMessage("Secondary Resource Fracking", RES_MOD_SECONDARY_FRACKING, RES_MOD_SECONDARY_TRICKLE, RoundFloat(delay));
	
	else if (resType == RESOURCE_TERTIARY)
		DisplayResFrackMessage("Tertiary Resource Fracking", RES_MOD_TERTIARY_FRACKING, RES_MOD_TERTIARY_TRICKLE, RoundFloat(delay));
}

void DisplayResFrackMessage(const char[] phrase, int amount, int trickle, int delay)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && option_res_frack[client])
		{
			PrintToChat(client, "\x03%t.", phrase, amount, trickle, delay);
		}
	}	
}