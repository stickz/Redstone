#include <sourcemod>
#include <sdktools>
#include <nd_stocks>

#define INVALID_USERID 		0

#define COLOUR_DEFAULT 		255
#define COLOUR_NONE 		0

ConVar cvarSpawnProtect;
ConVar cvarSpawnProtectTime;
ConVar cvarBlueStrength;
ConVar cvarRedStrength;
ConVar cvarBlueTransparency;
ConVar cvarRedTransparency;

public Plugin myinfo =
{
    name = "[ND] Spawn Colours",
    author = "Stickz",
    description = "Colour spawn protected player entities",
    version = "dummy",
	url = "https://github.com/stickz/Redstone/"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_spawn_colours/nd_spawn_colours.txt"
#include "updater/standard.sp"

public void OnPluginStart()
{
	//LoadTranslations("nd_spawn_colours.phrases");
   
	HookEvent("player_spawn", PlayerSpawn);
    
	cvarSpawnProtect = CreateConVar("sm_spawn_colours", "1", "Enable or disable spawn protection"); 
	
	cvarSpawnProtectTime = CreateConVar("sm_spawn_protect_time", "3", "Set the time of Spawn protection");
	cvarSpawnProtectTime.AddChangeHook(onSpawnProtectTimeChange);
	
	cvarBlueStrength = CreateConVar("sm_spawn_bluestrength", "255", "Enable or disable spawn protection"); 
	cvarBlueTransparency = CreateConVar("sm_spawn_transparency", "225", "Enable or disable spawn protection");
	
	cvarRedStrength = CreateConVar("sm_spawn_redStrength", "255", "Enable or disable spawn protection");	
	cvarRedTransparency = CreateConVar("sm_spawn_transparency", "175", "Enable or disable spawn protection"); 

	AutoExecConfig(true, "nd_spawn_colours");
	AddUpdaterLibrary(); //auto-updater
}

public void onSpawnProtectTimeChange(ConVar convar, char[] oldValue, char[] newValue) {
	ResetSpawnProtection(convar.IntValue);
}

public void OnConfigsExecuted() {
	ResetSpawnProtection(cvarSpawnProtectTime.IntValue);
}

public Action PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);    
	
	if (!IsValidClient(client, false))
		return Plugin_Continue;	
		
	if (cvarSpawnProtect.BoolValue)
	{		
		switch (GetClientTeam(client))
		{
			case TEAM_EMPIRE:
			{
				PrepColour(client, userid);
				SetEntityRenderColor(client, cvarRedStrength.IntValue, COLOUR_NONE, COLOUR_NONE, cvarRedTransparency.IntValue);
			}
			
			case TEAM_CONSORT:
			{
				PrepColour(client, userid);
				SetEntityRenderColor(client, COLOUR_NONE, COLOUR_NONE, cvarBlueStrength.IntValue, cvarBlueTransparency.IntValue);			
			}
		}
	} 
	
	return Plugin_Continue;	
}

void PrepColour(int client, int userid)
{
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	CreateTimer(cvarSpawnProtectTime.FloatValue, TIMER_DisableProtection, userid, TIMER_FLAG_NO_MAPCHANGE);
}

public Action TIMER_DisableProtection(Handle timer, any:userid)
{
	if (userid == INVALID_USERID)
		return Plugin_Handled;
	
	int client = GetClientOfUserId(userid);	
	SetEntityRenderColor(client, COLOUR_DEFAULT, COLOUR_DEFAULT, COLOUR_DEFAULT, COLOUR_DEFAULT);            
	//PrintCenterText(client, "%t", "Spawn Protect lifted");
	
	return Plugin_Handled;
}

void ResetSpawnProtection(int value)
{
	/* Set spawn protection time accordingly to the cvar value */		
	if (value < 0)
		value = 0;

	else if (value > 3)
		value = 3;
	
	//Set spawn protection time accordingly to the cvar value
	ServerCommand("mp_spawnprotection %d", value);
}