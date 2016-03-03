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
#include <nd_stocks>
#include <colors>
#include <clientprefs>

#undef REQUIRE_PLUGIN
#tryinclude <nd_commander>
#define REQUIRE_PLUGIN

#define VERSION "1.0.8"

public Plugin:myinfo =
{
	name = "[ND] Structure Killings",
	author = "databomb edited by stickz",
	description = "Provides a mini-game and announcement for structure killing",
	version = VERSION,
	url = "vintagejailbreak.org"
};

/* Auto Updater */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/master/updater/structminigame/structminigame.txt"
#include "updater/standard.sp"

#define TEAM_EMPIRE		3
#define TEAM_CONSORT		2
#define TEAM_SPEC		1
#define MAX_TEAMS 		4

new const String:nd_lgreen_colour[16] = { "{lightgreen}" };

new const String:nd_team_colour[2][] =
{
	"{blue}",
	"{red}"
};

new StructuresKilled[MAX_TEAMS];
new Handle:cookie_structure_killings = INVALID_HANDLE;
new bool:option_structure_killings[MAXPLAYERS + 1] = {true,...}; //off by default

public OnPluginStart()
{
	HookEvent("structure_death", Event_StructDeath);
	
	cookie_structure_killings = RegClientCookie("Structure Killings On/Off", "", CookieAccess_Protected);
	new info;
	SetCookieMenuItem(CookieMenuHandler_StructureKillings, any:info, "Structure Killings");
	
	LoadTranslations("common.phrases"); //required for on and off
	LoadTranslations("structminigame.phrases");
	
	AddUpdaterLibrary(); //auto-updater
}

public OnMapStart()
{
	ClearKills();
}

public CookieMenuHandler_StructureKillings(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	switch (action)
	{
		case CookieMenuAction_DisplayOption:
		{
			decl String:status[10];
			Format(status, sizeof(status), "%T", !option_structure_killings[client] ? "On" : "Off", client);		
			Format(buffer, maxlen, "%T: %s", "Cookie Structure Killings", client, status);		
		}
		
		case CookieMenuAction_SelectOption:
		{
			option_structure_killings[client] = !option_structure_killings[client];		
			SetClientCookie(client, cookie_structure_killings, !option_structure_killings[client] ? "Off" : "On");
			ShowCookieMenu(client);		
		}	
	}
}

public OnClientCookiesCached(client)
	option_structure_killings[client] = GetCookieStructureKillings(client);

bool:GetCookieStructureKillings(client)
{
	decl String:buffer[10];
	GetClientCookie(client, cookie_structure_killings, buffer, sizeof(buffer));
	
	return !StrEqual(buffer, "Off");
} 

ClearKills()
	for (new idx = 0; idx < MAX_TEAMS; idx++)
		StructuresKilled[idx] = 0;
		
public Event_StructDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker")),	
	team = GetClientTeam(attacker), 
	type = GetEventInt(event, "type");
	
	decl String:buildingname[32];
	switch (type) // get building name
	{
		case 0:	Format(buildingname, sizeof(buildingname), "Command Bunker"); //the Command Bunker
		case 1:	Format(buildingname, sizeof(buildingname), "MG Turret"); //a Machine Gun Turret
		case 2:	Format(buildingname, sizeof(buildingname), "Transport Gate"); //a Transport Gate
		case 3:	Format(buildingname, sizeof(buildingname), "Power Station"); //a Power Station
		case 4:	Format(buildingname, sizeof(buildingname), "Wireless Repeater"); //a Wireless Repeater
		case 5:	Format(buildingname, sizeof(buildingname), "Relay Tower"); //a Relay Tower
		case 6:	Format(buildingname, sizeof(buildingname), "Supply Station"); //a Supply Station
		case 7:	Format(buildingname, sizeof(buildingname), "Assembler"); //an Assembler
		case 8:	Format(buildingname, sizeof(buildingname), "Armory"); //an Armory
		case 9:	Format(buildingname, sizeof(buildingname), "Artillery"); //an Artillery
		case 10: Format(buildingname, sizeof(buildingname), "Radar Station"); //a Radar Station
		case 11: Format(buildingname, sizeof(buildingname), "Flamethrower Turret"); //a Flamethrower Turret
		case 12: Format(buildingname, sizeof(buildingname), "Sonic Turret"); //a Sonic Turret
		case 13: Format(buildingname, sizeof(buildingname), "Rocket Turret"); //a Rocket Turret
		case 14: Format(buildingname, sizeof(buildingname), "Wall"); //a Wall
		case 15: Format(buildingname, sizeof(buildingname), "Barrier"); //a Barrier
		//default: Format(buildingname, sizeof(buildingname), "a %d (?)", type); //a %d (?)
	}
	
	StructuresKilled[team]++;
	
	decl String:attackerName[128];
	GetClientName(attacker, attackerName, sizeof(attackerName));
	
	decl String:teamColour[16];
	switch (team)
	{
		case TEAM_CONSORT: Format(teamColour, sizeof(teamColour), "{red}");
		case TEAM_EMPIRE: Format(teamColour, sizeof(teamColour), "{blue}");
	}

	for (new client = 1; client <= MaxClients; client++)
		if (IsValidClient(client) && !option_structure_killings[client])
		{
			decl String:structure[32];
			Format(structure, sizeof(structure), "%T", buildingname, client);
			
			decl String:message[128];
			Format(message, sizeof(message), "%T", "Building Destoryed", client, teamColour, attackerName, structure);
			
			CPrintToChat(client, message);
		}
	
	
	if (StructuresKilled[TEAM_EMPIRE] + StructuresKilled[TEAM_CONSORT] >= 20)
	{
		ClearKills();

		decl String:teamTrans[16];
		switch (team)
		{
			case TEAM_CONSORT: Format(teamTrans, sizeof(teamTrans), "Consort");  
			case TEAM_EMPIRE:  Format(teamTrans, sizeof(teamTrans), "Empire");
		}
		
		decl String:colourGreen[32];
		Format(colourGreen, sizeof(colourGreen), "{lightgreen}");
		
		for (new client = 1; client <= MaxClients; client++)
			if (IsValidClient(client))
			{
				decl String:teamName[32];
				Format(teamName, sizeof(teamName), "%T", teamTrans, client);
				
				decl String:chatMessage[128];
				Format(chatMessage, sizeof(chatMessage), "%T", "Advantage Message", client, teamColour, attackerName, colourGreen, teamColour, teamName, colourGreen);
				CPrintToChat(client, chatMessage);
				
				decl String:centerMessage[64];
				Format(centerMessage, sizeof(centerMessage), "%T", "Advantage Center", client, teamName);
				PrintCenterText(client, centerMessage);
			}		

		for (new idx = 1; idx <= MaxClients; idx++)
		{
			if (GiveAdvantage(idx, team)) 
			{
				SetEntityHealth(idx, GetClientHealth(idx) + 175);
			}
		}
		
		return;
	}
}

bool:GiveAdvantage(client, team)
{
	return IsClientInGame(client) && IsPlayerAlive(client) && !NDC_IsCommander(client) && GetClientTeam(client) == team;
}
