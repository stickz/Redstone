#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <nd_balancer>
#include <nd_commands>
#include <nd_spec>

#undef REQUIRE_PLUGIN
#include <afk_manager>
#define REQUIRE_PLUGIN

public Plugin myinfo = 
{
	name 		= "[ND] Team Engine",
	author 		= "Stickz",
	description = "Creates and wraps team join events",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_team_engine/nd_team_engine.txt"
#include "updater/standard.sp"

Handle hPlayerTeamChanged;

public void OnPluginStart() 
{
	hPlayerTeamChanged = CreateGlobalForward("ND_OnPlayerTeamChanged", ET_Ignore, Param_Cell, Param_Cell);
	
	AddCommandListener(PlayerJoinTeam, "jointeam");
	AddUpdaterLibrary();	
}

public Action PlayerJoinTeam(int client, char[] command, int argc) 
{
	TeamChanged(client, IsValidClient(client));
	return Plugin_Continue;
}

public void TB_OnTeamPlacement(int client, int team) {
	TeamChanged(client, IsValidClient(client));
}

public void ND_OnClientTeamSet(int client, int team) {
	TeamChanged(client, IsValidClient(client));
}

public void AFKM_OnClientAFK(int client) {
	TeamChanged(client, IsValidClient(client));
}

public void ND_OnPlayerLockSpecPost(int client, int team) {
	TeamChanged(client, IsValidClient(client));
}

public void OnClientDisconnect_Post(int client) {
	TeamChanged(client, true);
}

void TeamChanged(int client, bool valid)
{
	Action dummy;
	Call_StartForward(hPlayerTeamChanged);
	Call_PushCell(client);
	Call_PushCell(valid);
	Call_Finish(dummy);	
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("ND_PlayerSpecLocked");
	RegPluginLibrary("afkmanager");
	return APLRes_Success;
}