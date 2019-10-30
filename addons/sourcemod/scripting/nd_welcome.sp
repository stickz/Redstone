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

Handle cookie_welcome_message = INVALID_HANDLE;
bool option_welcome_message[MAXPLAYERS + 1] = {true,...}; //off by default

public Plugin myinfo =
{
	name 		= "[ND] Welcome Features",
	author 		= "Stickz",
	description 	= "Display a welcome message",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

/* Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_welcome/nd_welcome.txt"
#include "updater/standard.sp"

public void OnPluginStart() 
{	
	LoadTranslations("nd_welcome.phrases");
	
	AddClientPrefsSupport();
	
	AddUpdaterLibrary(); //Add updater support if included
}

public void OnClientPutInServer(int client) {
	CreateTimer(5.0, Timer_WelcomeMessage, client);
}

public Action Timer_WelcomeMessage(Handle timer, int client) 
{
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client) && option_welcome_message[client])
		PrintToChat(client, "\x04%t", "Welcome", client);
		
	return Plugin_Handled;
}

public int CookieMenuHandler_WelcomeMessage(int client, CookieMenuAction:action, any:info, char[] buffer, int maxlen)
{
	switch (action)
	{
		case CookieMenuAction_DisplayOption:
		{
			char status[10];
			Format(status, sizeof(status), "%T", option_welcome_message[client] ? "On" : "Off", client);		
			Format(buffer, maxlen, "%T: %s", "Cookie Welcome Message", client, status);		
		}
		
		case CookieMenuAction_SelectOption:
		{
			option_welcome_message[client] = !option_welcome_message[client];
			SetClientCookie(client, cookie_welcome_message, option_welcome_message[client] ? "On" : "Off");		
			ShowCookieMenu(client);		
		}	
	}
}

public void OnClientCookiesCached(int client) {
	option_welcome_message[client] = GetCookieWelcomeMessage(client);
}

bool GetCookieWelcomeMessage(int client)
{
	char buffer[10];
	GetClientCookie(client, cookie_welcome_message, buffer, sizeof(buffer));
	
	return !StrEqual(buffer, "Off");
}

AddClientPrefsSupport()
{
	LoadTranslations("common.phrases"); //required for on and off
	
	cookie_welcome_message = RegClientCookie("Welcome Message On/Off", "", CookieAccess_Protected);
	new info;
	SetCookieMenuItem(CookieMenuHandler_WelcomeMessage, any:info, "Welcome Message");
}
