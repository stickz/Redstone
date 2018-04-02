/*
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
/GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

/* Auto Updater */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_universal_translator/nd_universal_translator.txt"

#include "updater/standard.sp"

#include <sdktools>
#include <nd_print>

#pragma newdecls required
#include <sourcemod>
#include <nd_stocks>
#include <nd_com_eng>
#include <nd_rounds>

public Plugin myinfo =
{
	name 		= "[ND] Project Communication",
	author 		= "Stickz",
	description 	= "Breaks Communication Barriers",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

/* Create Defines */
#define LANGUAGE_COUNT 		44
#define MESSAGE_COLOUR		"\x01"
#define NAME_COLOUR		"\x05"
#define TAG_COLOUR		"\x04"

/* Include First Abstraction Layer */ 
#include "ndpc/stock_functions.sp"
#include "ndpc/reg_functions.sp"
#include "ndpc/convars.sp"

/* Include Phrase Parsing */
#include "ndpc/phrases/building.sp"
#include "ndpc/phrases/capture.sp"
#include "ndpc/phrases/location.sp"
#include "ndpc/phrases/research.sp"

/* Include Various Plugin Features */
#include "ndpc/features/commander_lang.sp"
#include "ndpc/features/file_logging.sp"
#include "ndpc/features/team_lang.sp"

/* Include Chat Request Segments */
#include "ndpc/requests/build_req.sp"
#include "ndpc/requests/capture_req.sp"
#include "ndpc/requests/repair_req.sp"
#include "ndpc/requests/research_req.sp"
#include "ndpc/requests/tango_req.sp"

public void OnPluginStart()
{
	AddUpdaterLibrary(); //auto-updater
	CreateConVars(); //create ConVars (from convars.sp)
	RegComLangCommands(); // for commander_lang.sp
	RegTeamLangCommands(); // for team_lang.sp
	
	/* Create alaises for various requests */
	createAliasesForBuildings();
	createAliasesForResearch();
	createAliasesForLocations();
	
	BuildLogFilePath(); // for logging plugin actions
	
	/* Add translated phrases */
	LoadTranslations("nd_common.phrases");
	LoadTranslations("structminigame.phrases");
	LoadTranslations("nd_universal_translator.phrases");
}

public void ND_OnRoundStarted() {
	PrintTeamLanguages(); //print client languages at round start
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (client && IsValidClient(client)) //is the chat message is triggered by a client?
	{
		//send player team to each request
		int team = GetClientTeam(client);
		
		//check if players are allowed to spin up requests in spec
		if (!g_Enable[SpecTesting].BoolValue && team < 2)
			return Plugin_Continue;
		
		//send the space count to each request
		int spaces = GetStringSpaceCount(sArgs);
		
		//send player name to each request.
		char pName[64];
		GetClientName(client, pName, sizeof(pName));
		
		//does the chat message contain translatable phrases?
		if (	CheckBuildingRequest(client, team, spaces, pName, sArgs) ||  
			CheckCaptureRequest(client, team, spaces, pName, sArgs) || 
			CheckResearchRequest(client, team, spaces, pName, sArgs) ||
			CheckRepairRequest(client, team, spaces, pName, sArgs) ||
			CheckTangoRequest(client, team, spaces, pName, sArgs))
		{

			return Plugin_Handled; 
		}
	}
	
	return Plugin_Continue;
}
