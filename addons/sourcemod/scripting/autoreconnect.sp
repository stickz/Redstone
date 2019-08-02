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
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/autoreconnect/autoreconnect.txt"
#include "updater/standard.sp"

#pragma newdecls required
#include <sourcemod>

public Plugin myinfo =
{
	name = "Auto Reconnect",
	author = "stickz",
	description = "Sends client command retry on server restart",
	version = "recompile",
	url = "https://github.com/stickz/Redstone/"
};

public void OnPluginStart()
{
	RegServerCmd("quit", OnDown);
	RegServerCmd("_restart", OnDown);
	
	AddUpdaterLibrary(); //auto-updater
}

public Action OnDown(int args)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
           		ClientCommand(i, "retry"); // force retry
           	}
        }
}
