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

#include <sdktools>

/* Auto Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_ping/nd_ping.txt"
#include "updater/standard.sp"

#pragma newdecls required
#include <sourcemod>
#include <nd_print>

//Version is auto-filled by the travis builder
public Plugin myinfo =
{
	name 		= "[ND] Player Ping",
	author 		= "databomb",
	description	= "Players can use the /ping or bind to sm_ping to send a notification to the commander.",
	version 	= "recompile",
	url 		= "vintagejailbreak.org"
};

ConVar gH_Cvar_Type;

enum MinimapBlipType
{
	MINIMAP_BLIP_NONE = -1,
	MINIMAP_BLIP_NORMAL = 0,
	MINIMAP_BLIP_URGENT,
	MINIMAP_BLIP_ANGRY,
	MINIMAP_BLIP_PLAYER, // small, white
	MINIMAP_BLIP_ENEMY,  // small, red
}; 

public void OnPluginStart()
{
	RegConsoleCmd("sm_ping", Command_Ping);
	gH_Cvar_Type = CreateConVar("sm_ping_type", "3", "The type of map blip to use. Check the source for details.", _, true, 0.0);

	AddUpdaterLibrary(); //auto-updater
	
	LoadTranslations("nd_common.phrases");
}

public Action Command_Ping(int client, int args)
{
	if (!client)
	{
		ReplyToCommand(client, "Console disallowed");
		return Plugin_Handled;
	}
	
	if (GetClientTeam(client) <= 1)
	{
		PrintMessage(client, "On Team");
		return Plugin_Handled;
	}
	
	Handle bf = StartMessageAll("MapBlip");
	
	BfWriteByte(bf, gH_Cvar_Type.IntValue);
	
	float v[3];
	GetClientEyePosition(client, v);
	BfWriteVecCoord(bf, v);
	
	EndMessage();
	
	ReplyToCommand(client, "Sent a ping to the commander for this location.");
	
	return Plugin_Handled;
}
