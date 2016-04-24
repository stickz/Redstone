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

//Version is auto-filled by the travis builder
public Plugin:myinfo = 
{
	name 		= "Show Damage",
	author 		= "exvel, stickz",
	description 	= "Shows damage in the center of the screen.",
	version 	= "dummy",
	url 		= "www.sourcemod.net"
}

new player_damage[MAXPLAYERS + 1];
new bool:block_timer[MAXPLAYERS + 1] = {false,...};
new String:DamageEventName[16];
new MaxDamage = 10000000;
new bool:option_show_damage[MAXPLAYERS + 1] = {true,...};
new Handle:cookie_show_damage = INVALID_HANDLE;

//CVars' handles
ConVar gcvar_enabled;
ConVar gcvar_ff;
ConVar gcvar_own_dmg;
ConVar gcvar_text_area;

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/showdamage/showdamage.txt"
#include "updater/standard.sp"

public OnPluginStart()
{
	CreateConvars(); //plugin controls
	
	AddUpdaterLibrary(); //auto-updater support
	
	AddClientPrefs(); //client pref support (toggle on/off)
	
	LoadTranslations("showdamage.phrases"); //translation phrase support
	
	AutoExecConfig(true, "showdamage");
		
	SetupEvents(); //add needed event hooks and damage things
}

public CookieMenuHandler_ShowDamage(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_DisplayOption)
	{
		decl String:status[10];
		Format(status, sizeof(status), "%T", option_show_damage[client] ? "On" : "Off", client);
		Format(buffer, maxlen, "%T: %s", "Cookie Show Damage", client, status);
	}
	// CookieMenuAction_SelectOption
	else
	{
		option_show_damage[client] = !option_show_damage[client];
		SetClientCookie(client, cookie_show_damage, option_show_damage[client] ? "On" : "Off");
		ShowCookieMenu(client);
	}
}

public OnClientCookiesCached(client)
	option_show_damage[client] = GetCookieShowDamage(client);

bool:GetCookieShowDamage(client)
{
	decl String:buffer[10];
	GetClientCookie(client, cookie_show_damage, buffer, sizeof(buffer));
	
	return !StrEqual(buffer, "Off");
}

public OnClientConnected(client)
	block_timer[client] = false;

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	block_timer[client] = false;
	
	return Plugin_Continue;
}

public Action:ShowDamage(Handle:timer, any:client)
{
	block_timer[client] = false;
	
	if (player_damage[client] <= 0 || !client || !IsClientInGame(client))
		return;
	
	switch (gcvar_text_area.IntValue)
	{
		case 1:	PrintCenterText(client, "%t", "CenterText Damage Text", player_damage[client]);
		case 2:	PrintHintText(client, "%t", "HintText Damage Text", player_damage[client]);
		case 3:	PrintToChat(client, "%t", "Chat Damage Text", player_damage[client]);
	}
	
	player_damage[client] = 0;
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client_attacker = GetClientOfUserId(GetEventInt(event, "attacker")),
	client = GetClientOfUserId(GetEventInt(event, "userid")),
	damage = GetEventInt(event, DamageEventName);
	
	CalcDamage(client, client_attacker, damage);
	return Plugin_Continue;
}

public Action:Event_InfectedHurt(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client_attacker = GetClientOfUserId(GetEventInt(event, "attacker")),
	damage = GetEventInt(event, "amount");
	CalcDamage(0, client_attacker, damage);
	return Plugin_Continue;
}

CalcDamage(client, client_attacker, damage)
{
	if (!gcvar_enabled.BoolValue || !option_show_damage[client_attacker] || client_attacker == 0 || IsFakeClient(client_attacker) || !IsClientInGame(client_attacker) || damage > MaxDamage)
		return;
	
	//If client == 0 than skip this verifying. It can be an infected or something else without client index.
	if (client != 0)
	{
		if (client == client_attacker && !gcvar_own_dmg.BoolValue)
			return;

		else if (GetClientTeam(client) == GetClientTeam(client_attacker) && !gcvar_ff.BoolValue)
			return;
	}
	
	player_damage[client_attacker] += damage;
	
	if (block_timer[client_attacker])
		return;
	
	CreateTimer(0.01, ShowDamage, client_attacker);
	block_timer[client_attacker] = true;
}

AddClientPrefs()
{
	LoadTranslations("common.phrases");
	
	cookie_show_damage = RegClientCookie("Show Damage On/Off", "", CookieAccess_Protected);
	new info;
	SetCookieMenuItem(CookieMenuHandler_ShowDamage, any:info, "Show Damage");
}

CreateConvars()
{
	gcvar_enabled = CreateConVar("sm_show_damage", "1", "Enabled/Disabled show damage functionality, 0 = off/1 = on", _, true, 0.0, true, 1.0);
	gcvar_ff = CreateConVar("sm_show_damage_ff", "0", "Show friendly fire damage, 0 = off/1 = on", _, true, 0.0, true, 1.0);
	gcvar_own_dmg = CreateConVar("sm_show_damage_own_dmg", "0", "Show your own damage, 0 = off/1 = on", _, true, 0.0, true, 1.0);
	gcvar_text_area = CreateConVar("sm_show_damage_text_area", "1", "Defines the area for damage text:\n 1 = in the center of the screen\n 2 = in the hint text area \n 3 = in chat area of screen", _, true, 1.0, true, 3.0);
}

SetupEvents()
{
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	
	decl String:gameName[80];
	GetGameFolderName(gameName, 80);
	
	if (StrEqual(gameName, "left4dead") || StrEqual(gameName, "left4dead2"))
	{
		HookEvent("infected_hurt", Event_InfectedHurt, EventHookMode_Post);
		MaxDamage = 2000;
	}
	
	DamageEventName = StrEqual(gameName, "dod") || StrEqual(gameName, "hidden") 
			? "damage"
			: "dmg_health";
}
