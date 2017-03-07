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

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_player_warnings/nd_player_warnings.txt"
#include "updater/standard.sp"

#pragma newdecls required
#include <sourcemod>

#define WARN_TYPE_RESPECT 0
#define WARN_TYPE_ADVERTISE 1
#define WARN_TYPE_SPAWNSELL 2

//Version is auto-filled by the travis builder
public Plugin myinfo =
{
	name 		= "Player Warnings",
	author		= "Stickz",
	description 	= "Allows moderators to warn players in different languages.",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_respect", Cmd_WarnRespect, ADMFLAG_CUSTOM2, "<Name> - Warns a player to be respectful.");
	RegAdminCmd("sm_advertise", Cmd_WarnAdvertise, ADMFLAG_CUSTOM2, "<Name> - Warns a player to stop advertising.");
	RegAdminCmd("sm_spawnsell", Cmd_SpawnSell, ADMFLAG_CUSTOM2, "<Name> - Warns a player that spawn selling isn't allowed.");
	
	LoadTranslations("common.phrases"); //required for FindTarget
	LoadTranslations("nd_player_warnings.phrases");
	
	AddUpdaterLibrary(); //auto-updater
}

public Action Cmd_WarnRespect(int client, int args)
{
	if (!args)
	{
		ReplyToCommand(client, "[xG] Usage: sm_respect <Name|#Userid>");
		return Plugin_Handled;
	}
	
	char arg1[64]
	GetCmdArg(1, arg1, sizeof(arg1));	
	PrintWarning(WARN_TYPE_RESPECT, client, arg1);
	
	return Plugin_Handled;
}

public Action Cmd_WarnAdvertise(int client, int args)
{
	if (!args)
	{
		ReplyToCommand(client, "[xG] Usage: sm_advertise <Name|#Userid>");
		return Plugin_Handled;
	}
	
	char arg1[64]
	GetCmdArg(1, arg1, sizeof(arg1));
	PrintWarning(WARN_TYPE_ADVERTISE, client, arg1);
	
	return Plugin_Handled;
}

public Action Cmd_SpawnSell(int client, int args)
{
	if (!args)
	{
		ReplyToCommand(client, "[xG] Usage: sm_spawnsell <Name|#Userid>");
		return Plugin_Handled;
	}
	
	char arg1[64]
	GetCmdArg(1, arg1, sizeof(arg1));	
	PrintWarning(WARN_TYPE_SPAWNSELL, client, arg1);
	
	return Plugin_Handled;
}

bool TargetFound(int client, int target)
{
	if (target == -1)
	{
		PrintToChat(client, "[xG] Failed to target the player you're trying to warn.");
		return false;
	}
	
	return true;
}

void PrintWarning(int WarnType, int client, const char[] arg)
{
	int target = FindTarget(client, arg, true, true);	
	if (TargetFound(client, target))
		WarnPlayer(WarnType, client, target);
}

void WarnPlayer(int WarnType, int Moderator, int Offender)
{
	/* Get Client Name */	
	char OffenderName[32];
	GetClientName(Offender, OffenderName, sizeof(OffenderName));
	
	switch (WarnType)
	{
		case WARN_TYPE_RESPECT:
		{
			PrintToChat(Offender, "\x05%t!", "Respect"); //Please be respectful of other players on the server
			PrintToChat(Moderator, "\x05%s has been successfully warned to be respectful!", OffenderName);
		}
		case WARN_TYPE_ADVERTISE:
		{
			PrintToChat(Offender, "\x05%t!", "Advertise"); //Please refrain from posting advertisements
			PrintToChat(Moderator, "\x05%s has been successfully warned to stop advertising!", OffenderName);		
		}
		case WARN_TYPE_SPAWNSELL:
		{
			PrintToChat(Offender, "\x05%t!", "Spawn Sell"); //Selling all the spawns is prohibited on this server
			PrintToChat(Moderator, "\x05%s has been successfully warned about spawn selling!", OffenderName);			
		}
	}
}
