#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <gameme>

#define _DEBUG 		0
#define _eNATIVES 	1

#define QUERY_TYPE_ONCLIENTPUTINSERVER	1

ConVar queryMinTime;

enum plyInts {
	pSkill,
	pRank,
	pKills,
	pDeaths,
	pHeadshots
};
int playerInt[plyInts][MAXPLAYERS + 1];

enum plyFloats {
	pKDR,
	pHPK
}
float playerFloat[plyFloats][MAXPLAYERS + 1];

enum plyBools {
	pAuthorized,
	pQueried
}
bool playerBool[plyBools][MAXPLAYERS + 1];

Handle g_OnClientDataQueried;

#include "nd_gameme/natives.sp"
#include "nd_gameme/commands.sp"

public Plugin myinfo = 
{
	name 		= 	"[ND] GameMe Extras",
	author 		= 	"Stickz",
	description = 	"Creates natives and forwards for retrieving player statistics",
	version 	= 	"dummy",
	url 		=  	"https://github.com/stickz/Redstone"
};

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_gameme_extras/nd_gameme_extras.txt"
#include "updater/standard.sp"

public void OnPluginStart()
{
	queryMinTime	=	CreateConVar("sm_gameme_qtime", "3", "Specifies how many seconds to allow for the query to complete");
	
	g_OnClientDataQueried = CreateGlobalForward("GameME_OnClientDataQueried", ET_Ignore, Param_Cell, Param_Cell, Param_Float, Param_Float);	
	
	AutoExecConfig(true, "nd_gameme_extras");
	
	RegisterCommands();
	
	LoadTranslations("common.phrases");
	AddUpdaterLibrary(); //auto-updater
}

public void OnClientAuthorized(int client) {
	ResetVarriables(client, true);
}

public void OnClientPutInServer(int client)
{
	#if _DEBUG
	if (!IsFakeClient(client))
		PrintToServer("A player has put in");
	#endif
	
	QueryPlayerData(client);
}

void QueryPlayerData(int client)
{
	if (IsQueryable(client))
	{
		QueryClientData(client);
		
		float time = queryMinTime.FloatValue;
		int userid = GetClientUserId(client);
		
		CreateTimer(time, Timer_FireDataQueriedForward, userid, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_FireDataQueriedForward(Handle:timer, any userid)
{
	int client = GetClientOfUserId(userid);	
	if (client == INVALID_USERID)
		return Plugin_Handled;	
	
	Action dummy;
	Call_StartForward(g_OnClientDataQueried);
	Call_PushCell(client);
	Call_PushCell(playerInt[pSkill][client]);
	Call_PushFloat(playerFloat[pKDR][client]);
	Call_PushFloat(playerFloat[pHPK][client]);
	Call_Finish(dummy);	
	
	return Plugin_Handled;
}

public void OnClientDisconnect(int client) {
	ResetVarriables(client);
}

void ResetVarriables(int client, bool authorized = false)
{
	playerInt[pSkill][client] = 0;
	playerInt[pRank][client] = 0;
	playerInt[pKills][client] = 0;
	playerInt[pDeaths][client] = 0;
	playerInt[pHeadshots][client] = 0;
			
	playerFloat[pKDR][client] = 0.0;
	playerFloat[pHPK][client] = 0.0;
	
	playerBool[pAuthorized][client] = authorized;
	playerBool[pQueried][client] = false;
}

void QueryClientData(int client) {
	QueryGameMEStats("playerinfo", client, QueryGameMEStatsCallback, QUERY_TYPE_ONCLIENTPUTINSERVER);
}

public QueryGameMEStatsCallback(int command, int payload, int client, &Handle: datapack)
{
	if ((client > 0) && (command == RAW_MESSAGE_CALLBACK_PLAYER)) {

		Handle data = CloneHandle(datapack);
		ResetPack(data);
		
		// total values
		int rank            = ReadPackCell(data);
		int players       	= ReadPackCell(data); 
		int skill           = ReadPackCell(data);
		int kills           = ReadPackCell(data);	
		int deaths          = ReadPackCell(data);
		float kpd      		= ReadPackFloat(data);
		int suicides        = ReadPackCell(data);
		int headshots       = ReadPackCell(data);
		float hpk      		= ReadPackFloat(data);
		float accuracy 		= ReadPackFloat(data);		

		CloseHandle(data);

		// only write this message to gameserver log if client has connected
		if (payload == QUERY_TYPE_ONCLIENTPUTINSERVER) {
			playerInt[pSkill][client] = skill;
			playerInt[pRank][client] = rank;
			playerInt[pKills][client] = kills;
			playerInt[pDeaths][client] = deaths;
			playerInt[pHeadshots][client] = headshots;
			
			float kdr = float(kills) / float(deaths);			
			playerFloat[pKDR][client] = kdr;
			
			playerFloat[pHPK][client] = hpk;

			playerBool[pQueried][client] = true;
			
			#if _DEBUG
			PrintDebugMessage(client);			
			#endif
			
			#if _DEBUG
			PrintToServer("Reached end of website query");
			#endif
		}		
	}
}

stock void PrintDebugMessage(int client)
{
	char Name[64];
	GetClientName(client, Name, sizeof(Name)); 
	
	int rank = playerInt[pRank][client];
	int kdr = RoundFloat(playerFloat[pKDR][client]);
			
	char Message[64];
	Format(Message, sizeof(Message), "%s queried. rank: %d, kdr: %d", Name, rank, kdr);
			
	PrintToServer(Message);
	PrintToAdmins(Message, "a");
}

stock bool IsQueryable(int client) {
	return client > 0 && !IsFakeClient(client);
}