#include <sourcemod>
#include <nd_shuffle>
#include <nd_print>
#include <nd_stocks>
#include <clientprefs>
#include <nd_swgm>

public Plugin myinfo =
{
	name = "[ND] Server Advertisements",
	author = "Stickz",
	description = "Creates server advertisements, with option to disable",
	version = "dummy",
	url = "https://github.com/stickz/Redstone"
};

/* For auto updater support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_advertise/nd_advertise.txt"
#include "updater/standard.sp"

/* Client-prefs variables */
bool option_adverts[MAXPLAYERS + 1] = {true,...};
Handle cookie_adverts = INVALID_HANDLE;

public void OnPluginStart()
{
	LoadTranslations("nd_advertise.phrases");
	LoadTranslations("nd_common.phrases");
	AddUpdaterLibrary(); //auto-updater
	AddClientPrefSupport(); // client prefs
}

public void ND_OnRoundStarted() {
	CreateTimer(30.0, TIMER_AdvertiseEventsSG, _, TIMER_FLAG_NO_MAPCHANGE);	
	CreateTimer(60.0, TIMER_AdvertiseFeatureSG, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(90.0, TIMER_AdvertiseDisableSG, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action TIMER_AdvertiseEventsSG(Handle timer)
{
	// Join the RedstoneND steam group. We host community teampick events
	PrintSteamGroupAdvert("Join RedstoneND Events");	
	return Plugin_Handled;
}

public Action TIMER_AdvertiseFeatureSG(Handle timer)
{
	// Join the RedstoneND steam group. For access to exclusive server features
	PrintSteamGroupAdvert("Join RedstoneND Features");
	return Plugin_Handled;
}

public Action TIMER_AdvertiseDisableSG(Handle timer)
{
	// Join the RedstoneND steam group. To disable server advertisements
	PrintSteamGroupAdvert("Join RedstoneND Advertise");
	return Plugin_Handled;
}

void PrintSteamGroupAdvert(const char[] phrase)
{
	for (int client = 1; client <= MaxClients; client++) {
		if (IsValidClient(client) && option_adverts[client] && !SWGM_IsInGroup(client, false)) {
			PrintMessageEx(client, phrase);
		}
	}
}

/*void PrintServerAdvert(const char[] phrase)
{
	for (int client = 1; client <= MaxClients; client++) {
		if (IsValidClient(client) && option_adverts[client]) {
			PrintMessageEx(client, phrase);
		}
	}
}*/

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	// Mark team shuffle natives as optional
	MarkNativeAsOptional("WB2_BalanceTeams");
	MarkNativeAsOptional("WB2_GetBalanceData");
	return APLRes_Success;
}

/* Client-prefs support to disable server advertisements */
void AddClientPrefSupport()
{
	LoadTranslations("common.phrases");
	cookie_adverts = RegClientCookie("Server Adverts On/Off", "", CookieAccess_Protected);
	new info;
	SetCookieMenuItem(CookieMenuHandler_ServerAverts, any:info, "Server Adverts");	
}
 
public CookieMenuHandler_ServerAverts(int client, CookieMenuAction:action, any:info, char[] buffer, int maxlen)
{
	switch (action)
	{
		case CookieMenuAction_DisplayOption:
		{
			char status[10];
			Format(status, sizeof(status), "%T", option_adverts[client]? "On" : "Off", client);	
			Format(buffer, maxlen, "%T: %s", "Cookie Server Adverts", client, status);
		}
		
		case CookieMenuAction_SelectOption:
		{
			if (option_adverts[client] && !SWGM_IsInGroup(client, true))
				PrintMessage(client, "Steam Group Usage");
			else
				option_adverts[client] = !option_adverts[client];			

			SetClientCookie(client, cookie_adverts, option_adverts[client] ? "On" : "Off");		
			ShowCookieMenu(client);		
		}
	}
}

// Enable advertisments, if the client leaves the steam group
public void SWGM_OnLeaveGroup(int client) {
	option_adverts[client] = true;
}

public void OnClientCookiesCached(int client) {
	option_adverts[client] = GetCookieAdverts(client);
}

bool GetCookieAdverts(int client)
{
	char buffer[10];
	GetClientCookie(client, cookie_adverts, buffer, sizeof(buffer));
	
	if (IsValidClient(client) && !SWGM_IsInGroup(client, true))
		return true;
	
	return !StrEqual(buffer, "Off");
}
