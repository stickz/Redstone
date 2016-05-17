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

//Version is auto-filled by the travis builder
public Plugin:myinfo =
{
	name 		= "[ND] Project Communication",
	author 		= "Stickz",
	description 	= "Breaks Communication Barriers",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

#define LANGUAGE_COUNT 		44
#define STRING_STARTS_WITH 	0
#define IS_WITHIN_STRING	-1

/* Auto Updater */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_project_communication/nd_project_communication.txt"
#include "updater/standard.sp"

#include "nd_project_communication/commander_lang.sp"
#include "nd_project_communication/team_lang.sp"
#include "nd_project_communication/building_requests.sp"
#include "nd_project_communication/capture_requests.sp"

public OnPluginStart()
{
	/* Hook needed events */
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("promoted_to_commander", Event_CommanderPromo);
	
	AddUpdaterLibrary(); //auto-updater
	
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
		if (CheckBuildingRequest(client, sArgs) || CheckCaptureRequest(client, sArgs))
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
