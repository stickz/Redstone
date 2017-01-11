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
#include <clientprefs>
#include <nd_redstone>
#include <nd_stocks>

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_disconnect/nd_disconnect.txt"
#include "updater/standard.sp"

Handle cookie_lost_connection_message = INVALID_HANDLE;
bool option_lost_connection_message[MAXPLAYERS + 1] = {true,...}; //off by default

//Version is auto-filled by the travis builder
public Plugin myinfo = 
{
	name 		= "[ND] Disconnect Messages",
	author 		= "stickz",
	description 	= "Displays a message when a client loses connection",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

public void OnPluginStart()
{
	HookEvent("player_disconnect", Event_PlayerDisconnected, EventHookMode_Pre);
	HookEvent("player_connect_client", Event_PlayerConnect, EventHookMode_Pre);
	LoadTranslations("nd_disconnect.phrases");
	
	AddClientPrefsSupport();
	
	AddUpdaterLibrary(); //auto-updater
}

public Action Event_PlayerDisconnected(Event event, const char[] name, bool dontBroadcast)
{
	char steam_id[32];
	event.GetString("networkid", steam_id, sizeof(steam_id));
	
	if (strncmp(steam_id, "STEAM_", 6) == 0)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));	
		
		if (RED_IsValidClient(client))
		{
			char reason[64];
			GetEventString(event, "reason", reason, sizeof(reason));
			
			if(StrContains(reason, "timed out", false) != -1)
				PrintLostConnection(client);
		}
	}
}

public Action Event_PlayerConnect(Event event, const char[] name, bool dontBroadcast)
{
	char steam_id[32];
	event.GetString("networkid", steam_id, sizeof(steam_id));
	
	if (strncmp(steam_id, "STEAM_", 6) == 0)
	{	
		int client = GetClientOfUserId(event.GetInt("userid"));	
		dontBroadcast = !RED_IsValidCIndex(client);
	}
	
	return Plugin_Continue;
}

void PrintLostConnection(int client)
{
	char clientName[64];
	GetClientName(client, clientName, sizeof(clientName))
	
	for (int idx = 1; idx <= MaxClients; idx++)
	{
		if (IsValidClient(idx) && option_lost_connection_message[idx])
		{
			PrintToChat(idx, "\x05%t", "Lost Connection", clientName);
		}
	}
}

public CookieMenuHandler_LostConnectionMessage(int client, CookieMenuAction:action, any:info, char[] buffer, int maxlen)
{
	switch (action)
	{
		case CookieMenuAction_DisplayOption:
		{
			char status[10];
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

public OnClientCookiesCached(int client)
{
	option_lost_connection_message[client] = GetCookieLostConnectionMessage(client);
}

bool GetCookieLostConnectionMessage(int client)
{
	char buffer[10];
	GetClientCookie(client, cookie_lost_connection_message, buffer, sizeof(buffer));
	
	return !StrEqual(buffer, "Off");
}

void AddClientPrefsSupport()
{
	LoadTranslations("common.phrases"); //required for on and off
	
	cookie_lost_connection_message = RegClientCookie("Lost Connection Message On/Off", "", CookieAccess_Protected);
	int info;
	SetCookieMenuItem(CookieMenuHandler_LostConnectionMessage, info, "Lost Connection Message");
}
