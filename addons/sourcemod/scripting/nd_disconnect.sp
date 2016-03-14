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
#include <clientprefs>

new Handle:cookie_lost_connection_message = INVALID_HANDLE;
new bool:option_lost_connection_message[MAXPLAYERS + 1] = {true,...}; //off by default

//Version is auto-filled by the travis builder
public Plugin:myinfo = 
{
	name 		= "[ND] Disconnect Messages",
	author 		= "stickz",
	description = "N/A",
	version 	= "dummy",
	url 		= "N/A"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_disconnect/nd_disconnect.txt"
#include "updater/standard.sp"

public OnPluginStart()
{
	HookEvent("player_disconnect", Event_PlayerDisconnected, EventHookMode_Pre);
	LoadTranslations("nd_disconnect.phrases");
	
	AddClientPrefsSupport();
	
	AddUpdaterLibrary(); //auto-updater
}

public Event_PlayerDisconnected(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:steam_id[32];
	GetEventString(event, "networkid", steam_id, sizeof(steam_id));
	
	if (strncmp(steam_id, "STEAM_", 6) == 0)
	{
		new client = GetClientOfUserId(GetEventInt(event,"userid"));		
		
		decl String:reason[64];
		GetEventString(event, "reason", reason, sizeof(reason));
		
		if(StrContains(reason, "timed out", false) != -1)
			PrintLostConnection(client);	
	}
}

PrintLostConnection(client)
{
	decl String:clientName[64];
	GetClientName(client, clientName, sizeof(clientName))
	
	for (new idx = 1; idx <= MaxClients; idx++)
	{
		if (IsValidClient(idx) && option_lost_connection_message(idx))
		{
			PrintToChat(idx, "\x05%t", "Lost Connection", clientName);
		}
	}
}

public CookieMenuHandler_LostConnectionMessage(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	switch (action)
	{
		case CookieMenuAction_DisplayOption:
		{
			decl String:status[10];
			Format(status, sizeof(status), "%T", option_lost_connection_message[client] ? "On" : "Off", client);		
			Format(buffer, maxlen, "%T: %s", "Cookie Lost Connect", client, status);		
		}
		
		case CookieMenuAction_SelectOption:
		{
			option_lost_connection_message[client] = !option_lost_connection_message[client];
			SetClientCookie(client, cookie_lost_connection_message, option_lost_connection_message[client] ? "On" : "Off");		
			ShowCookieMenu(client);		
		}	
	}
}

public OnClientCookiesCached(client)
	option_lost_connection_message[client] = GetCookieLostConnectionMessage(client);

bool:GetCookieLostConnectionMessage(client)
{
	decl String:buffer[10];
	GetClientCookie(client, cookie_lost_connection_message, buffer, sizeof(buffer));
	
	return !StrEqual(buffer, "Off");
}

AddClientPrefsSupport()
{
	LoadTranslations("common.phrases"); //required for on and off
	
	cookie_lost_connection_message = RegClientCookie("Lost Connection Message On/Off", "", CookieAccess_Protected);
	new info;
	SetCookieMenuItem(CookieMenuHandler_LostConnectionMessage, any:info, "Lost Connection Message");
}
