#include <sourcemod>
#include <clientprefs>
#include <sdktools>

#include <nd_stocks>
#include <nd_com_eng>
#include <nd_rounds>
#include <nd_classes>
#include <nd_redstone>
#include <nd_checklist>

#define BREAKDOWN_UPDATE_RATE 1.5

bool statusChanged = false;
 
enum ClassBreakdown
{
	DirectCombat = 0,
	Snipers,
	AntiStructure,
	Stealth,
	Medic,
	Engineer
}
 
int g_Layout[2][ClassBreakdown];

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_team_breakdown/nd_team_breakdown.txt"
#include "updater/standard.sp"

#include "nd_breakdown/clientprefs.sp"

public Plugin myinfo =
{
	name = "[ND] Team Breakdown",
	author = "databomb, stickz",
	description = "Provides troop count display",
    	version = "dummy",
	url = "https://github.com/stickz/Redstone/"
}

public void OnPluginStart()
{
	AddClientPrefSupport(); // From clientprefs.sp
	LoadTranslations("nd_team_breakdown.phrases");

	//Account for late plugin loading		
	if (ND_RoundStarted())
	{
		startPlugin();
		LateLoadStart();
	}
	
	HookEvent("player_changeclass", Event_ChangeClass);
	
	AddUpdaterLibrary(); //Auto-Updater
}

public void ND_OnRoundStarted() {
	startPlugin();
}

public void ND_OnRoundEndedEX() {
	disableBreakdowns();
}

public Action Event_ChangeClass(Event event, const char[] name, bool dontBroadcast)
{
	if (!statusChanged)
	{	
		int client = GetClientOfUserId(event.GetInt("userid"));
		if (IsClientInGame(client))
			statusChanged = true;
	}
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int userID = event.GetInt("userid");
	int client = GetClientOfUserId(userID);
	
	if (RED_IsValidClient(client) && option_team_breakdown[client] && !ND_IsCommander(client))
		CreateTimer(BREAKDOWN_UPDATE_RATE, DisplayBreakdownsClients, userID, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void ND_OnCommanderPromoted(int client, int team) {
	StartBreakdownTimer(client);
}

void StartBreakdownTimer(int client) {
	CreateTimer(BREAKDOWN_UPDATE_RATE, DisplayBreakdownsCommander, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

void LateLoadStart()
{
	for (int client = 1; client <= MAXPLAYERS; client++) 
	{
		if (RED_IsValidClient(client) && ND_IsCommander(client))
			StartBreakdownTimer(client);	
	}
}

public Action DisplayBreakdownsCommander(Handle timer, any:Userid)
{
	if (!ND_RoundStarted())
		return Plugin_Stop;
	
	int client = GetClientOfUserId(Userid);	
	if (client == 0 || !RED_IsValidClient(client)) //invalid userid/client
		return Plugin_Stop;	
		
	// If the checklist is not done, it's not disabled and the commander is in rts view
	// The displaying the checklist has priority, so delay displaying troop counts
	if ((!ND_CheckListDone(client) && !ND_CheckListOff(client) && ND_InCommanderMode(client)) || !option_team_breakdown[client])
		return Plugin_Continue;
	
	int clientTeam = GetClientTeam(client);	
	if (clientTeam > 1)
	{
		if (ND_GetCommanderOnTeam(clientTeam) == client) //commander troops counts
		{
			ShowTeamBreakdown(client, clientTeam, 1.0, 0.115, 255, 128, 0, 175);
			return Plugin_Continue;
		}	
	}
	return Plugin_Stop;
}

public Action DisplayBreakdownsClients(Handle timer, any:Userid)
{
	if (!ND_RoundStarted())
		return Plugin_Stop;
	
	int client = GetClientOfUserId(Userid);	
	if (client == 0 || !RED_IsValidClient(client)) //invalid userid/client
		return Plugin_Stop;	
	
	int clientTeam = GetClientTeam(client);	
	if (clientTeam > 1)
	{		
		if (!IsPlayerAlive(client)) //player troop counts
		{
			switch (clientTeam)
			{
				case TEAM_CONSORT: ShowTeamBreakdown(client, clientTeam, 1.0, 0.425, 51, 153, 255, 175);	
				case TEAM_EMPIRE: ShowTeamBreakdown(client, clientTeam, 1.0, 0.425, 255, 0, 0, 255);						
			}

			return Plugin_Continue;
		}
	}
	
	return Plugin_Stop;
}

void ShowTeamBreakdown(int client, int clientTeam, float x, float y, int r, int g, int b, int a)
{
	int arrayIdx = clientTeam -2;
	Handle hHudText = CreateHudSynchronizer();
	SetHudTextParams(x, y, BREAKDOWN_UPDATE_RATE, r, g, b, a);
	ShowSyncHudText(client, hHudText, "%t %d\n%t %d\n%t %d\n%t %d\n%t %d\n%t %d",	"Combat",  		g_Layout[arrayIdx][DirectCombat],					
											"Anti-Structure",	g_Layout[arrayIdx][AntiStructure], 	
											"Sniper", 		g_Layout[arrayIdx][Snipers], 	
											"Stealth", 		g_Layout[arrayIdx][Stealth], 	
											"Medic", 		g_Layout[arrayIdx][Medic], 			
											"Engineer", 		g_Layout[arrayIdx][Engineer]);
	CloseHandle(hHudText);
}

public Action UpdateBreakdowns(Handle timer)
{
	if (!ND_RoundStarted())
		return Plugin_Stop;
	
	if (statusChanged)
	{
		// clear breakdown list
		for (int i = 0; i < 2; i++)
			for (int y = 0; y < _:ClassBreakdown; y++)
				g_Layout[i][y] = 0;
	
		// update breakdown list
		for (int client = 1; client <= MaxClients; client++)
			if (RED_IsValidClient(client))
				AddClientClass(client);

		statusChanged = false;
	}
	return Plugin_Continue;
}

void AddClientClass(int client)
{
	int cTeamIDX = GetClientTeam(client) - 2;
	int iClass = GetEntProp(client, Prop_Send, "m_iPlayerClass");
	int iSubClass = GetEntProp(client, Prop_Send, "m_iPlayerSubclass");	
	
	// Switch the main class, then switch it's corresponding sub class
	switch (iClass)
	{
		case mAssault:
		{
			switch (iSubClass)
			{
				case aInfantry: g_Layout[cTeamIDX][DirectCombat]++;
				case aGrenadier: g_Layout[cTeamIDX][AntiStructure]++; 
				case aSniper: g_Layout[cTeamIDX][Snipers]++;
			}
		}
		case mExo:
		{
			switch (iSubClass)
			{
				case eSuppression: g_Layout[cTeamIDX][DirectCombat]++; 
				case eSiege_Kit: g_Layout[cTeamIDX][AntiStructure]++;
			}
		}
		case mStealth:
		{
			g_Layout[cTeamIDX][Stealth]++;
			switch (iSubClass)
			{
				case seAssassin: g_Layout[cTeamIDX][DirectCombat]++; 
				case seSniper: g_Layout[cTeamIDX][Snipers]++;
				case seSabateur: g_Layout[cTeamIDX][AntiStructure]++;
			}
		}
	
		case mSupport:
		{
			switch (iSubClass)
			{
				case suMedic: g_Layout[cTeamIDX][Medic]++; 
				case suEngineer: g_Layout[cTeamIDX][Engineer]++; 
				case suBBQ: g_Layout[cTeamIDX][AntiStructure]++;
			}
		}
	}	
}

void disableBreakdowns() {
	UnhookEvent("player_death", Event_PlayerDeath);
}

void startPlugin()
{
	statusChanged = true;
	CreateTimer(BREAKDOWN_UPDATE_RATE, UpdateBreakdowns, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	HookEvent("player_death", Event_PlayerDeath);
}

/* Native to return values from unit array to other plugins */
public Native_GetUnitCount(Handle:plugin, numParams)
{
	// Cell 1: team index, Cell 2: unit type
	// Return the number of units on a given team	
	return g_Layout[GetNativeCell(1)-2][GetNativeCell(2)];
}

public APLRes:AskPluginLoad2(Handle:myself, bool late, String:error[], err_max)
{
	CreateNative("NDB_GetUnitCount", Native_GetUnitCount);
	return APLRes_Success;
}
