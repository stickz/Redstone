/*
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

#include <sourcemod>
#include <nd_stocks>
#include <SteamWorks>

#pragma newdecls required

#define GAME_APPID 	17710
#define ND_MAXPLAYERS 	33
#define EXP_NOT_FOUND	-1

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
	author 		= "stickz",
	description 	= "Retrieves a player's exp from steam stats",
	version		= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

int gI_totalPlayerExp[ND_MAXPLAYERS] = {-1, ...};

public void OnClientPutInServer(int iClient)
{
	ResetVarriables(iClient);
	RequestPlayerStats(iClient);
}

public void OnClientDisconnect(int iClient)
{
	ResetVarriables(iClient);
}
 
public void OnPluginStart()
{
	AddUpdaterLibrary(); //auto-updater
}

int GetClientExp(int iClient)
{
	int iAssaultEXP, iExoEXP, iStealthEXP, iSupportEXP;
		
	SteamWorks_GetStatCell(iClient, ASSAULT_EXP, iAssaultEXP);
	SteamWorks_GetStatCell(iClient, EXO_EXP, iExoEXP);
	SteamWorks_GetStatCell(iClient, STEALTH_EXP, iStealthEXP);
	SteamWorks_GetStatCell(iClient, SUPPORT_EXP, iSupportEXP);
	
	return (iAssaultEXP + iExoEXP + iStealthEXP + iSupportEXP);
}
 
void RequestPlayerStats(int iClient)
{
	if (SteamWorks_RequestStats(iClient, GAME_APPID))
	{
		gI_totalPlayerExp[iClient] = GetClientExp(iClient);
	}
}

void ResetVarriables(int iClient)
{
	gI_totalPlayerExp[iClient] = -1;
}

/* Natives */
typedef NativeCall = function int (Handle plugin, int numParams);

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_GetClientEXP", Native_GetClientEXP);
	return APLRes_Success;
}

public int Native_GetClientEXP(Handle plugin, int numParams)
{
	int iClient = GetNativeCell(1);
	
	if (gI_totalPlayerExp[iClient] == EXP_NOT_FOUND)
	{
		RequestPlayerStats(iClient);
	}

	return gI_totalPlayerExp[iClient];
}
