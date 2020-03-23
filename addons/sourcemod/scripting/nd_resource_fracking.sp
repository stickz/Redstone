#include <sourcemod>
#include <nd_print>
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

// Include the resource fracking constants
#include "nd_res_trickle/constants.sp"

public void OnPluginStart()
{
	LoadTranslations("nd_resource_fracking.phrases");	
	AddUpdaterLibrary(); //auto-updater
}

public void ND_OnResFrackStarted(int resType, float delay, int interval, int amount)
{
	if (resType == RESOURCE_PRIME)
	{
		if (amount == PRIMARY_FRACKING_AMOUNT_FASTER && interval == PRIMARY_FRACKING_SECONDS_FASTER)
			PrintToChatAll("\x03%t.", "Prime Resource Fracking", RES_PRIME_EXTRACT, RES_PRIME_TRICKLE, RoundFloat(delay));
		
		else if (amount == PRIMARY_FRACKING_AMOUNT && interval == PRIMARY_FRACKING_SECONDS)
		{
			int primeExtractRate = RES_PRIME_TRICKLE + 825;
			PrintToChatAll("\x03%t.", "Prime Resource Fracking", primeExtractRate, RES_PRIME_TRICKLE, RoundFloat(delay));
		}
	}
}