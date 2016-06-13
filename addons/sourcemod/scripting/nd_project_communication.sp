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
#include <nd_commander>
#include <nd_stocks>
#include <sdktools>

//Version is auto-filled by the travis builder
public Plugin:myinfo =
{
	name 		= "[ND] Project Communication",
	author 		= "Stickz",
	description 	= "Breaks Communication Barriers",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

/* Create Defines */
#define LANGUAGE_COUNT 		44
#define MESSAGE_COLOUR		"\x05"
#define TAG_COLOUR		"\x04"
#define CHAT_PREFIX		"\x05[xG]"

/* Auto Updater */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_project_communication/nd_project_communication.txt"
#include "updater/standard.sp"

/* Include Plugin Segments */
#include "ndpc/convars.sp"
#include "ndpc/stock_functions.sp"
#include "ndpc/commander_lang.sp"
#include "ndpc/team_lang.sp"
#include "ndpc/building_requests.sp"
#include "ndpc/capture_requests.sp"

public OnPluginStart()
{
	/* Hook needed events */
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("promoted_to_commander", Event_CommanderPromo);
	
	AddUpdaterLibrary(); //auto-updater
	CreateConVars(); //create ConVars (from convars.sp)
	RegComLangCommands(); // for commander_lang.sp
	
	/* Add translated phrases */
	LoadTranslations("structminigame.phrases");
	LoadTranslations("nd_project_communication.phrases");
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	PrintTeamLanguages(); //print client languages at round start
}

public Action:OnClientSayCommand(client, const String:command[], const String:sArgs[])
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
			new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);
			SetCmdReplySource(old);
			return Plugin_Stop; 
		}
	}
	
	return Plugin_Continue;
}
