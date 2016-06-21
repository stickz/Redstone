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

//Version is auto-filled by the travis builder
public Plugin myinfo = 
{
	name 		= "[ND] Translation Updater",
	author 		= "stickz",
	description 	= "A simple dummy for updating server translations",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
}

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_translation_updater/nd_translation_updater.txt"
#include "updater/standard.sp"

public void OnPluginStart()
{
	AddUpdaterLibrary(); //auto-updater
}

public Updater_OnPluginUpdated()
{
	PrintToChatAll("\x05[xG] Server translations updated from github!");
}
