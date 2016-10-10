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

/* Auto Updater */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_universal_translator/nd_universal_translator.txt"
#include "updater/standard.sp"

#include <sdktools>

#pragma newdecls required
#include <sourcemod>
#include <nd_stocks>
#include <nd_com_eng>

public Plugin myinfo =
{
	name 		= "[ND] Project Communication",
	author 		= "Stickz",
	description = "Breaks Communication Barriers",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

/* Create Defines */
#define LANGUAGE_COUNT 		44
#define MESSAGE_COLOUR		"\x05"
#define TAG_COLOUR		"\x04"
#define CHAT_PREFIX		"\x05[xG]"

/* Include First Abstraction Layer */ 
#include "ndpc/stock_functions.sp"
#include "ndpc/convars.sp"

/* Include Various Plugin Features */
#include "ndpc/features/commander_lang.sp"
#include "ndpc/features/file_logging.sp"
#include "ndpc/features/team_lang.sp"

/* Include Chat Request Segments */
#include "ndpc/requests/requests.sp"
#include "ndpc/requests/build_req.sp"
#include "ndpc/requests/capture_req.sp"
#include "ndpc/requests/research_req.sp"

public void OnPluginStart()
{
	/* Hook needed events */
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("promoted_to_commander", Event_CommanderPromo);
	
	AddUpdaterLibrary(); //auto-updater
	CreateConVars(); //create ConVars (from convars.sp)
	RegComLangCommands(); // for commander_lang.sp
	
	/* Create alaises for various requests */
	createAliasesForBuildings();
	createAliasesForResearch(); 
	
	BuildLogFilePath(); // for logging plugin actions
	
	/* Add translated phrases */
	LoadTranslations("structminigame.phrases");
	LoadTranslations("nd_universal_translator.phrases");
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
	PrintTeamLanguages(); //print client languages at round start
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (client) //is the chat message is triggered by a client?
	{
		//does the chat message contain translatable phrases?
		if (CheckBuildingRequest(client, sArgs) ||  CheckCaptureRequest(client, sArgs))
		{
			/* 
			 * Block the old chat message
			 * And print the new translated message 
			 */
			ReplySource old = SetCmdReplySource(SM_REPLY_TO_CHAT);
			SetCmdReplySource(old);
			return Plugin_Stop; 
		}
	}
	
	return Plugin_Continue;
}
