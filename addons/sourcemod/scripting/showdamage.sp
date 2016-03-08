#include <sourcemod>
#include <clientprefs>

#define PLUGIN_VERSION "1.0.7"

public Plugin:myinfo = 
{
	name = "Show Damage",
	author = "exvel",
	description = "Shows damage in the center of the screen.",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
}

new player_old_health[MAXPLAYERS + 1];
new player_damage[MAXPLAYERS + 1];
new bool:block_timer[MAXPLAYERS + 1] = {false,...};
new String:DamageEventName[16];
new MaxDamage = 10000000;
new bool:option_show_damage[MAXPLAYERS + 1] = {true,...};
new Handle:cookie_show_damage = INVALID_HANDLE;

//CVars' handles
new Handle:cvar_show_damage = INVALID_HANDLE;
new Handle:cvar_show_damage_ff = INVALID_HANDLE;
new Handle:cvar_show_damage_own_dmg = INVALID_HANDLE;
new Handle:cvar_show_damage_text_area = INVALID_HANDLE;

//CVars' varibles
new bool:show_damage = true;
new bool:show_damage_ff = false;
new bool:show_damage_own_dmg = false;
new show_damage_text_area = 1;

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/showdamage/showdamage.txt"
#include "updater/standard.sp"

public OnPluginStart()
{
	CreateConvars(); //plugin controls
	
	AddConVarHooks(); //convar and event hooks
	
	AddUpdaterLibrary(); //auto-updater support
	
	AddClientPrefs(); //client pref support (toggle on/off)
	
	LoadTranslations("showdamage.phrases"); //translation phrase support
	
	AutoExecConfig(true, "showdamage");
		
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

public OnConfigsExecuted()
	GetCVars();

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
	
	switch (show_damage_text_area)
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
	if (!show_damage || !option_show_damage[client_attacker] || client_attacker == 0 || IsFakeClient(client_attacker) || !IsClientInGame(client_attacker) || damage > MaxDamage)
		return;
	
	//If client == 0 than skip this verifying. It can be an infected or something else without client index.
	if (client != 0)
	{
		if (client == client_attacker && !show_damage_own_dmg)
			return;

		else if (GetClientTeam(client) == GetClientTeam(client_attacker) && !show_damage_ff)
			return;
	}
	
	player_damage[client_attacker] += damage;
	
	if (block_timer[client_attacker])
		return;
	
	CreateTimer(0.01, ShowDamage, client_attacker);
	block_timer[client_attacker] = true;
}

public OnCVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
	GetCVars();

GetCVars()
{
	show_damage = GetConVarBool(cvar_show_damage);
	show_damage_ff = GetConVarBool(cvar_show_damage_ff);
	show_damage_own_dmg = GetConVarBool(cvar_show_damage_own_dmg);
	show_damage_text_area = GetConVarInt(cvar_show_damage_text_area);
}

AddConVarHooks()
{
	HookConVarChange(cvar_show_damage, OnCVarChange);
	HookConVarChange(cvar_show_damage_ff, OnCVarChange);
	HookConVarChange(cvar_show_damage_own_dmg, OnCVarChange);
	HookConVarChange(cvar_show_damage_text_area, OnCVarChange);
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
	cvar_show_damage = CreateConVar("sm_show_damage", "1", "Enabled/Disabled show damage functionality, 0 = off/1 = on", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_show_damage_ff = CreateConVar("sm_show_damage_ff", "0", "Show friendly fire damage, 0 = off/1 = on", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_show_damage_own_dmg = CreateConVar("sm_show_damage_own_dmg", "0", "Show your own damage, 0 = off/1 = on", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_show_damage_text_area = CreateConVar("sm_show_damage_text_area", "1", "Defines the area for damage text:\n 1 = in the center of the screen\n 2 = in the hint text area \n 3 = in chat area of screen", FCVAR_PLUGIN, true, 1.0, true, 3.0);
}
