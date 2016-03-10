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
#include <sdktools>

public Plugin:myinfo =
{
	name 		= "[ND] Player Ping",
	author 		= "databomb",
	descriptio	= "Players can use the /ping or bind to sm_ping to send a notification to the commander.",
	version 	= "dummy",
	url 		= "vintagejailbreak.org"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_ping/nd_ping.txt"
#include "updater/standard.sp"

new Handle:gH_Cvar_Type = INVALID_HANDLE;

enum MinimapBlipType
{
	MINIMAP_BLIP_NONE = -1,
	MINIMAP_BLIP_NORMAL = 0,
	MINIMAP_BLIP_URGENT,
	MINIMAP_BLIP_ANGRY,
	MINIMAP_BLIP_PLAYER, // small, white
	MINIMAP_BLIP_ENEMY,  // small, red
}; 

public OnPluginStart()
{
	RegConsoleCmd("sm_ping", Command_Ping);
	gH_Cvar_Type = CreateConVar("sm_ping_type", "3", "The type of map blip to use. Check the source for details.", _, true, 0.0);

	AddUpdaterLibrary(); //auto-updater
}

public Action:Command_Ping(client, args)
{
	if (!client)
	{
		ReplyToCommand(client, "Console disallowed");
		return Plugin_Handled;
	}
	
	if (GetClientTeam(client) <= 1)
	{
		ReplyToCommand(client, "Invalid team");
		return Plugin_Handled;
	}
	
	new Handle:bf = StartMessageAll("MapBlip");
	
	BfWriteByte(bf, GetConVarInt(gH_Cvar_Type));
	new Float:v[3];
	GetClientEyePosition(client, v);
	BfWriteVecCoord(bf, v);
	EndMessage();
	
	ReplyToCommand(client, "Sent a ping to the commander for this location.");
	
	return Plugin_Handled;
}
