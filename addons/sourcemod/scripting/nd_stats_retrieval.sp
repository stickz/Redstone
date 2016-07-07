#include <sourcemod>
#include <nd_stocks>
#include <SteamWorks>

/****************************************************************************************************
DEFINES
*****************************************************************************************************/
//#define LoopValidClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsValidClient(%1))
#define ND_APPID "17710"

/****************************************************************************************************
ETIQUETTE.
*****************************************************************************************************/
//#pragma newdecls required
#pragma semicolon 1

/****************************************************************************************************
CONVARS
*****************************************************************************************************/
ConVar SteamAuthKey;

/****************************************************************************************************
Auto-Updater Support
*****************************************************************************************************/
#define UPDATE_URL  	"https://github.com/stickz/Redstone/raw/build/updater/nd_stats_retrieval/nd_stats_retrieval.txt"
#include 		"updater/standard.sp"

/****************************************************************************************************
Plugin Info 
*****************************************************************************************************/
public Plugin myinfo =
{
	name 		= "[ND] Stats Retrieval",
	author 		= "SM9, Stickz",
	description 	= "Retrieves a player's exp from steam stats",
	version		= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};
 
public void OnPluginStart()
{
	RegAdminCmd("sm_GetStatsInfo", CMD_GetStatsInfo, ADMFLAG_KICK, "Get's a players stats info");	
	RegAdminCmd("sm_GetStatsInfoDeux", CMD_GetStatsInfoDeux, ADMFLAG_KICK, "Get's a players stats info deux");
	
	SteamAuthKey = CreateConVar("sm_steam_auth_key", "INSERT_WEB_AUTH_KEY", "Set's a steam auth key for retreiving information");
	
	AddUpdaterLibrary(); //auto-updater
} 
 
public Action CMD_GetStatsInfo(int iClient, int iArgs)
{
	RequestPlayerStats(iClient);
	return Plugin_Handled;
} 

public Action CMD_GetStatsInfoDeux(int iClient, int iArgs)
{
	RequestPlayerStatsDeux(iClient);
	return Plugin_Handled;
}

public void RequestPlayerStatsDeux(int iClient)
{
	if (SteamWorks_RequestStats(iClient, ND_APPID))
	{
		int iAssaultEXP, iExoEXP, iStealthEXP, iSupportEXP;
		
		SteamWorks_GetStatCell(iClient, "Assault.accum.experience", iAssaultEXP);
		SteamWorks_GetStatCell(iClient, "Exo.accum.experience", iExoEXP);
		SteamWorks_GetStatCell(iClient, "Stealth.accum.experience", iStealthEXP);
		SteamWorks_GetStatCell(iClient, "Support.accum.experience", iSupportEXP);
		
		PrintToChat(iClient, "Exp: %d, %d, %d, %d", iAssaultEXP, iExoEXP, iStealthEXP, iSupportEXP);
	}
	else 
		PrintToChat(iClient, "Failed to request client stats");
	
	return Plugin_Handled;
}

public void RequestPlayerStats(int iClient)
{
	Handle hRequest = SteamWorks_CreateHTTPRequest(view_as<EHTTPMethod>(k_EHTTPMethodGET), "https://api.steampowered.com/ISteamUserStats/GetUserStatsForGame/v1/");
	
	char chSteamId64[64];	
	GetClientAuthId(iClient, AuthId_SteamID64, chSteamId64, sizeof(chSteamId64));
	
	char authKey[33];
	SteamAuthKey.GetString(authKey, sizeof(authKey));	
	
	SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, "key", authKey);
	SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, "steamid", chSteamId64);
	SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, "format", "vdf");
	SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, "appid", ND_APPID);
	
	SteamWorks_SetHTTPRequestNetworkActivityTimeout(hRequest, 5);
	SteamWorks_SetHTTPCallbacks(hRequest, StatsRequestComplete);
	
	SteamWorks_SetHTTPRequestContextValue(hRequest, GetClientUserId(iClient));
	SteamWorks_SendHTTPRequest(hRequest);
}
 
public int StatsRequestComplete(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, any iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if (!IsValidClient(iClient) || !bRequestSuccessful || eStatusCode != view_as<EHTTPStatusCode>(k_EHTTPStatusCode200OK)) {
		CloseHandle(hRequest);
		return;
	}
	
	int iBodySize;
	
	if (SteamWorks_GetHTTPResponseBodySize(hRequest, iBodySize)) {
		if (iBodySize <= 0) {
			CloseHandle(hRequest);
			return;
		}
	} else {
		CloseHandle(hRequest);
		return;
	}
	
	char[] chBody = new char[iBodySize + 1]; SteamWorks_GetHTTPResponseBodyData(hRequest, chBody, iBodySize);
	
	Handle hKv = CreateKeyValues("playerstats");
	
	if (!StringToKeyValues(hKv, chBody)) {
		CloseHandle(hRequest); 
		CloseHandle(hKv);
		return;
	}
	
	if(!KvJumpToKey(hKv, "stats")) {
		CloseHandle(hRequest); 
		CloseHandle(hKv);
		return;
	}
	
	int iAssaultEXP = KvGetNum(hKv, "Assault.accum.experience");
	int iExoEXP = KvGetNum(hKv, "Exo.accum.experience");
	int iStealthEXP = KvGetNum(hKv, "Stealth.accum.experience");
	int iSupportEXP = KvGetNum(hKv, "Support.accum.experience");
	
	PrintToChat(iClient, "Exp: %d, %d, %d, %d", iAssaultEXP, iExoEXP, iStealthEXP, iSupportEXP);
	
	CloseHandle(hRequest);
	CloseHandle(hKv);
}
