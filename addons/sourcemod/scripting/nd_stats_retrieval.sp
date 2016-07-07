#include <sourcemod>
#include <nd_stocks>
#include <SteamWorks>

#define GAME_APPID 17710
#define ND_MAXPLAYERS 33

#define ASSAULT_EXP 	"Assault.accum.experience"
#define EXO_EXP		"Exo.accum.experience"
#define STEALTH_EXP	"Stealth.accum.experience"
#define SUPPORT_EXP	"Support.accum.experience"

/* Auto-Updater Support */
#define UPDATE_URL  	"https://github.com/stickz/Redstone/raw/build/updater/nd_stats_retrieval/nd_stats_retrieval.txt"
#include 		"updater/standard.sp"

public Plugin myinfo =
{
	name 		= "[ND] Stats Retrieval",
	author 		= "SM9, Stickz",
	description 	= "Retrieves a player's exp from steam stats",
	version		= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

int gI_totalPlayerExp[ND_MAXPLAYERS] = {-1, ...};

public OnClientPutInServer()
{
	CacheClientStats();
}
 
public void OnPluginStart()
{
	AddUpdaterLibrary(); //auto-updater
} 
 
public void CachePlayerStats(int iClient)
{
	if (SteamWorks_RequestStats(iClient, GAME_APPID))
	{
		int iAssaultEXP, iExoEXP, iStealthEXP, iSupportEXP;
		
		SteamWorks_GetStatCell(iClient, ASSAULT_EXP, iAssaultEXP);
		SteamWorks_GetStatCell(iClient, EXO_EXP, iExoEXP);
		SteamWorks_GetStatCell(iClient, STEALTH_EXP, iStealthEXP);
		SteamWorks_GetStatCell(iClient, SUPPORT_EXP, iSupportEXP);
		
		gI_totalPlayerExp[iClient] = iAssaultEXP + iExoEXP + iStealthEXP + iSupportEXP;
	}
}

/* Natives */
functag NativeCall public(Handle:plugin, numParams);

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("ND_GetClientEXP", Native_GetClientEXP);
	return APLRes_Success;
}

public int Native_GetClientEXP(Handle:plugin, numParams)
{
	//aka gI_totalPlayerExp[client], but shorter
	return gI_totalPlayerExp[GetNativeCell(1)];
}
