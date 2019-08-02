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
#include <nd_com_eng>

//Version is auto-filled by the travis builder
public Plugin myinfo =
{
	name 		= "[ND] Structure Killings",
	author 		= "databomb edited by stickz",
	description 	= "Provides a mini-game and announcement for structure killing",
	version 	= "recompile",
	url 		= "https://github.com/stickz/Redstone/"
};

/* Auto Updater */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/structminigame/structminigame.txt"
#include "updater/standard.sp"

#define MAX_TEAMS 		4

int StructuresKilled[MAX_TEAMS];
Handle cookie_structure_killings = INVALID_HANDLE;
bool option_structure_killings[MAXPLAYERS + 1] = {true,...}; //off by default

ConVar g_cvarTeamOnly;
ConVar g_CvarUseAdvantage;

public void OnPluginStart()
{
	HookEvent("structure_death", Event_StructDeath);
	g_cvarTeamOnly = CreateConVar("sm_structminigame_teamonly", "1", "Display structure messages to your team other");
	g_CvarUseAdvantage = CreateConVar("sm_structminigame_advantage", "1", "Decide wether or not to use the advantage");
	
	AddClientPrefSupport();

	LoadTranslations("nd_common.phrases");
	LoadTranslations("structminigame.phrases");
	
	AddUpdaterLibrary(); //auto-updater
	
	AutoExecConfig(true, "nd_structminigame");
}

public void OnMapStart() {
	ClearKills();
}

public void CookieMenuHandler_StructureKillings(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	switch (action)
	{
		case CookieMenuAction_DisplayOption:
		{
			char status[10];
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

public void OnClientCookiesCached(client) {
	option_structure_killings[client] = GetCookieStructureKillings(client);
}

bool GetCookieStructureKillings(int client)
{
	char buffer[10];
	GetClientCookie(client, cookie_structure_killings, buffer, sizeof(buffer));
	
	return !StrEqual(buffer, "Off");
} 

ClearKills() {
	for (int idx = 0; idx < MAX_TEAMS; idx++)
		StructuresKilled[idx] = 0;
}

public Action Event_StructDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker")),	
	team = GetClientTeam(attacker), 
	type = event.GetInt("type");
	
	char buildingname[32];
	switch (type) // get building name
	{
		case 0:	Format(buildingname, sizeof(buildingname), "Bunker"); //the Command Bunker
		case 1:	Format(buildingname, sizeof(buildingname), "MG"); //a Machine Gun Turret
		case 2:	Format(buildingname, sizeof(buildingname), "Transport"); //a Transport Gate
		case 3:	Format(buildingname, sizeof(buildingname), "Power"); //a Power Station
		case 4:	Format(buildingname, sizeof(buildingname), "Repeater"); //a Wireless Repeater
		case 5:	Format(buildingname, sizeof(buildingname), "Relay"); //a Relay Tower
		case 6:	Format(buildingname, sizeof(buildingname), "Supply"); //a Supply Station
		case 7:	Format(buildingname, sizeof(buildingname), "Assembler"); //an Assembler
		case 8:	Format(buildingname, sizeof(buildingname), "Armory"); //an Armory
		case 9:	Format(buildingname, sizeof(buildingname), "Artillery"); //an Artillery
		case 10: Format(buildingname, sizeof(buildingname), "Radar"); //a Radar Station
		case 11: Format(buildingname, sizeof(buildingname), "Flame"); //a Flamethrower Turret
		case 12: Format(buildingname, sizeof(buildingname), "Sonic"); //a Sonic Turret
		case 13: Format(buildingname, sizeof(buildingname), "Rocket"); //a Rocket Turret
		case 14: Format(buildingname, sizeof(buildingname), "Wall"); //a Wall
		case 15: Format(buildingname, sizeof(buildingname), "Barrier"); //a Barrier
		//default: Format(buildingname, sizeof(buildingname), "a %d (?)", type); //a %d (?)
	}
	
	StructuresKilled[team]++;
	
	char attackerName[128];
	GetClientName(attacker, attackerName, sizeof(attackerName));
	
	char teamColour[16];
	switch (team)
	{
		case TEAM_CONSORT: Format(teamColour, sizeof(teamColour), "{red}");
		case TEAM_EMPIRE: Format(teamColour, sizeof(teamColour), "{blue}");
	}
	
	bool teamOnly = g_cvarTeamOnly.BoolValue;
	for (int client = 1; client <= MaxClients; client++)
		if (IsValidClient(client) && !option_structure_killings[client] && (!teamOnly || GetClientTeam(client) == team))
		{
			char structure[32];
			Format(structure, sizeof(structure), "%T", buildingname, client);
			
			char message[128];
			Format(message, sizeof(message), "%T", "Building Destoryed", client, teamColour, attackerName, structure);
			
			CPrintToChat(client, message);
		}
	
	
	if (g_CvarUseAdvantage.BoolValue && StructuresKilled[TEAM_EMPIRE] + StructuresKilled[TEAM_CONSORT] >= 20)
	{
		ClearKills();

		char teamTrans[16];
		switch (team)
		{
			case TEAM_CONSORT: Format(teamTrans, sizeof(teamTrans), "Consortium");  
			case TEAM_EMPIRE:  Format(teamTrans, sizeof(teamTrans), "Empire");
		}
		
		char colourGreen[32];
		Format(colourGreen, sizeof(colourGreen), "{lightgreen}");
		
		for (int client = 1; client <= MaxClients; client++)
			if (IsValidClient(client))
			{
				char teamName[32];
				Format(teamName, sizeof(teamName), "%T", teamTrans, client);
				
				char chatMessage[128];
				Format(chatMessage, sizeof(chatMessage), "%T", "Advantage Message", client, teamColour, attackerName, colourGreen, teamColour, teamName, colourGreen);
				CPrintToChat(client, chatMessage);
				
				char centerMessage[64];
				Format(centerMessage, sizeof(centerMessage), "%T", "Advantage Center", client, teamName);
				PrintCenterText(client, centerMessage);
			}		

		for (int idx = 1; idx <= MaxClients; idx++)
		{
			if (GiveAdvantage(idx, team)) {
				SetEntityHealth(idx, GetClientHealth(idx) + 175);
			}
		}
		
		return;
	}
}

bool GiveAdvantage(int client, int team) {
	return IsClientInGame(client) && IsPlayerAlive(client) && !ND_IsCommander(client) && GetClientTeam(client) == team;
}

void AddClientPrefSupport()
{
	cookie_structure_killings = RegClientCookie("Structure Killings On/Off", "", CookieAccess_Protected);
	int info;
	SetCookieMenuItem(CookieMenuHandler_StructureKillings, info, "Structure Killings");
	
	LoadTranslations("common.phrases"); //required for on and off
}
