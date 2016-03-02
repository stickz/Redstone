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

public Plugin:myinfo = 
{
	name 		= "[ND] Disconnect Messages",
	author 		= "stickz",
	description = "N/A",
	version 	= "1.0.1",
	url 		= "N/A"
};

/* Auto Updater */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/master/updater/nd_disconnect/nd_disconnect.txt"
#include "updater/standard.sp"

public OnPluginStart()
{
	HookEvent("player_disconnect", Event_PlayerDisconnected, EventHookMode_Pre);
	LoadTranslations("nd_disconnect.phrases");
}

public Event_PlayerDisconnected(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:steam_id[32];
	GetEventString(event, "networkid", steam_id, sizeof(steam_id));
	
	if (strncmp(steam_id, "STEAM_", 6) == 0)
	{
		new client = GetClientOfUserId(GetEventInt(event,"userid"));		
		
		decl String:clientName[64];
		GetClientName(client, clientName, sizeof(clientName))
		
		decl String:reason[64];
		GetEventString(event, "reason", reason, sizeof(reason));
		
		if(StrContains(reason, "timed out", false) != -1)
			PrintToChatAll("\x05%t", "Lost Connection", clientName);	
	}
}
