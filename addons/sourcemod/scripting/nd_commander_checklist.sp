#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <nd_stocks>
#include <nd_com_eng>
#include <nd_entities>
#include <nd_research>
#include <nd_redstone>
#include <nd_rounds>

#define CHECKLIST_ITEM_COUNT    5
#define CHECKLIST_UPDATE_RATE   1.5
#define DEBUG					0

//Handle hudSync;

//ConVar g_enabled;
ConVar g_maxlevel;
ConVar g_hidedone;
char checklistTasks[CHECKLIST_ITEM_COUNT][25] = {"BUILD_FWD_SPAWN","RESEARCH_TACTICS","BUILD_ARMORY","RESEARCH_KITS","CHAT_MSG"};

//Commander checklists for each team. Each checklist has one extra field, for 
//marking whether the comm has seen the thankyou msg after completing all tasks.
bool teamChecklists[TEAM_COUNT][CHECKLIST_ITEM_COUNT+1];

#include "nd_com_check/clientprefs.sp"

public Plugin myinfo =
{
	name = "[ND] Commander Checklist",
	author = "jddunlap, Stickz",
	description = "Shows a commander checklist for new commanders",
	version = "dummy",
   	url = "https://github.com/stickz/Redstone/"
};

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_commander_checklist/nd_commander_checklist.txt"
#include "updater/standard.sp"

public void OnPluginStart()
{	
	//Convars (show it for everyone for now to get some feedback)
	//g_enabled = CreateConVar("sm_comm_checklist_enabled","1");
	g_maxlevel = CreateConVar("sm_comm_checklist_maxlevel", "80");
	g_hidedone = CreateConVar("sm_comm_checklist_hide_done", "1");
	
	//hudSync = CreateHudSynchronizer();

	//basic init
	LoadTranslations ("sm_comm_checklist.phrases");
	
	AddClientPrefSupport(); // clientprefs.sp
	
	//For updating HUD when field tactics and kits are researched
	HookEvent("research_complete",OnResearchCompleted);
	//For updating HUD when armory is built
	HookEvent("commander_start_structure_build",OnStructureBuildStarted);
	//For updating HUD when a forward spawn is built
	HookEvent("transport_gate_created",OnForwardSpawnCreated);
	//For updating HUD when the comm activate chat
	HookEvent("player_say", OnPlayerChat, EventHookMode_Post);
	
	AddUpdaterLibrary(); //auto-updater
}

public void OnMapStart()
{
	//init task arrays
	for (int idx = 2; idx < TEAM_COUNT; idx++)
	{
		for (int idx2 = 0; idx2 < CHECKLIST_ITEM_COUNT+1; idx2++) 
		{
			teamChecklists[idx][idx2]=false;
		}
	}
}

public Action OnPlayerChat(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client)
		return Plugin_Continue;	

	#if DEBUG == 1
		int teamId = GetClientTeam(client);
		PrintToServer("hooked chat, team %d, client %d, comm %d", teamId, client, ND_InCommanderMode(teamId));
	#endif

	if (ND_IsCommander(client) && ND_IsInCommanderMode(client))
	{
		int clientTeam = GetClientTeam(client);
		teamChecklists[clientTeam][4] = true;
		//UpdateCommHud(clientTeam);
	}

	return Plugin_Continue;
}

public Action OnStructureBuildStarted(Event event, const char[] name, bool dontBroadcast)
{
	int structType = event.GetInt("type");
	int teamId = event.GetInt("team");

	#if DEBUG == 1
		PrintToChatAll("Structure build started for team %d: %d", teamId, structType);
	#endif

	//Armory
	if (structType == 8 && !teamChecklists[teamId][2])
	{
		teamChecklists[teamId][2] = true;
		//UpdateCommHud(teamId);
	}
	
	return Plugin_Continue;
}

//structure_built and forward_spawn_created do not fire serverside. 
//transport_gate_created fires serverside but before the entity has an origin -
//so we set a timer for the entity and do our checks there.
public Action OnForwardSpawnCreated(Event event, const char[] name, bool dontBroadcast)
{
	//PrintToChatAll("Forward spawn created for team %d", teamId);
	CreateTimer(1.0, TransportGateTimerCB, event.GetInt("entindex"), TIMER_REPEAT);
	return Plugin_Continue;
}

public Action TransportGateTimerCB(Handle timer, any:entIdx)
{
	if (entIdx < 1)
		return Plugin_Stop;
	
	int teamId = GetEntProp(entIdx, Prop_Send, "m_iTeamNum");

	#if DEBUG == 1
		PrintToChatAll("Forward spawn timer for entity %d and team %d", entIdx, teamId);
	#endif

	if(!teamChecklists[teamId][0]) 
	{
		float pos[3];
		GetEntPropVector(entIdx, Prop_Send, "m_vecOrigin", pos);

		if(pos[0] == 0.0 && pos[1] == 0.0 && pos[2] == 0.0)
		{
			//PrintToChatAll("%d not ready yet", entIdx);
			return Plugin_Continue;
		}

		// Get the bunker location of the current team
		float friendlyBunkerPos[3];
		int friendlyBunker = ND_GetTeamBunkerEntity(teamId);		
		GetEntPropVector(friendlyBunker, Prop_Send, "m_vecOrigin", friendlyBunkerPos);		
		
		// Get the bunker location of the other team
		float otherBunkerPos[3];
		int otherBunker = ND_GetTeamBunkerEntity(getOtherTeam(teamId));
		GetEntPropVector(otherBunker, Prop_Send, "m_vecOrigin", otherBunkerPos);

		// Compare the consort and empire bunker locations and get a distance percentage
		float linePt[3];
		friendlyBunkerPos[2]=0.0;
		otherBunkerPos[2]=0.0;
		pos[2]=0.0;
		pointOn2dLine(friendlyBunkerPos, otherBunkerPos, pos, linePt);
		linePt[2]=0.0;
		float percentAcrossMap = percentageAlongLine(friendlyBunkerPos, otherBunkerPos, linePt);


		/*PrintToChatAll(
			"entindex(%d) Positions: (%f,%f,%f) (%f,%f,%f) (%f,%f,%f) (%f,%f,%f) - [%f,%f]", 
			entIdx,
			friendlyBunkerPos[0],friendlyBunkerPos[1],friendlyBunkerPos[2],
			otherBunkerPos[0],otherBunkerPos[1],otherBunkerPos[2],
			pos[0],pos[1],pos[2],
			linePt[0],linePt[1],linePt[2],
			distanceBetweenPts(friendlyBunkerPos, pos),
			distanceBetweenPts(friendlyBunkerPos, linePt)
		);
		PrintToChatAll("Forward spawn is %f percent across the map", percentAcrossMap);
		*/
		
		// If the forward spawn is 20% across the map, check the item off on the list
		if(percentAcrossMap >= 0.20)
		{
			teamChecklists[teamId][0] = true;
			//UpdateCommHud(teamId);
		}
	}
  	return Plugin_Stop;
}  


public Action OnResearchCompleted(Event event, const char[] name, bool dontBroadcast)
{	
	int researchId = event.GetInt("researchid");
	int teamId = event.GetInt("teamid");

	//PrintToChatAll("Research completed for team %d: %d", teamId, researchId);

	if (researchId == RESEARCH_ADVANCED_KITS)
	{
		teamChecklists[teamId][3] = true;
		//UpdateCommHud(teamId);
	}

	else if (researchId == RESEARCH_FIELD_TACTICS)
	{
		teamChecklists[teamId][1] = true;
		//UpdateCommHud(teamId);
	}

	return Plugin_Continue;
}

// Called when the commander enters or exits rts view
/*public void ND_OnCommanderStateChanged(int team) {
	UpdateCommHud(team);	
}*/

public void ND_OnCommanderPromoted(int client, int team) {
	CreateTimer(CHECKLIST_UPDATE_RATE, DisplayChecklistCommander, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action DisplayChecklistCommander(Handle timer, any:Userid)
{
	if (!ND_RoundStarted())
		return Plugin_Stop;
	
	int client = GetClientOfUserId(Userid);	
	if (client == 0 || !RED_IsValidClient(client)) //invalid userid/client
		return Plugin_Stop;
		
	if (ND_RetreiveLevel(client) > g_maxlevel.IntValue || !ND_IsInCommanderMode(client))
		return Plugin_Continue;
	
	int clientTeam = GetClientTeam(client);	
	if (clientTeam > 1)
	{
		if (ND_GetCommanderOnTeam(clientTeam) == client) //commander troops counts
		{
			ShowCheckList(client, clientTeam);
			return Plugin_Continue;
		}	
	}
	
	return Plugin_Stop;
}

//Updates the commander hud for the specified team.
//Shows or clears hud depending on whether comm is in
//chair and whether he has finished his tasks.
void ShowCheckList(int commander, int team)
{
	if(!teamChecklists[team][CHECKLIST_ITEM_COUNT])
	{
		Handle hudSync = CreateHudSynchronizer();
			
		char message[256]; 
		Format(message, sizeof(message), "%T\n", "COMMANDER_CHECKLIST", commander);

		int checkedItemCount = 0;
		for (int idx = 0; idx < CHECKLIST_ITEM_COUNT; idx++)
		{
			char state[2];
			if(teamChecklists[team][idx])
			{
				state="✔";
				checkedItemCount++;
			} 
			else
				state="✘";
					
			char task[25];
			task = checklistTasks[idx];
			if (!(teamChecklists[team][idx] && g_hidedone.BoolValue)) 
				Format(message, sizeof(message), "%s%s %T\n", message, state, task, commander);	
		}

		if(checkedItemCount >= CHECKLIST_ITEM_COUNT)
		{
			Format(message, sizeof(message), "%T", "COMM_THANKS", commander);
			Format(message, sizeof(message), "%s\n%T", message, "COMM_SUPPORTTROOPS", commander);
			SetHudTextParams(1.0, 0.2, CHECKLIST_UPDATE_RATE, 0, 128, 0, 80);
			teamChecklists[team][CHECKLIST_ITEM_COUNT] = true;
		} 
		else 
			SetHudTextParams(1.0, 0.1, CHECKLIST_UPDATE_RATE, 255, 255, 80, 80);
			
		ShowSyncHudText(commander, hudSync, message);
		CloseHandle(hudSync);
	}	
}

//returns the percentage of the distance pt falls at on the line from pt1 to pt2
float percentageAlongLine(float pt1[3], float pt2[3], float pt[3]) {
	return distanceBetweenPts(pt1,pt)/distanceBetweenPts(pt1,pt2);
}

//gets the distance in game units between the specified points
float distanceBetweenPts(float pt1[3], float pt2[3]) {
	return SquareRoot(Pow(pt1[0]-pt2[0],2.0) + Pow(pt1[1]-pt2[1],2.0) + Pow(pt1[2]-pt2[2],2.0));
}

//Projects the point specified by toProject onto the line specified by line1 and line2.
//Returns the projected point in result. Accepts 3D points for convenience, but only
//uses the x and y dimensions.
public pointOn2dLine(float line1[3], float line2[3], float toProject[3], float result[3])
{
    float m = (line2[1] - line1[1]) / (line2[0] - line1[0]);
    float b = line1[1] - (m * line1[0]);

    float x = (m * toProject[1] + toProject[0] - m * b) / (m * m + 1);
    float y = (m * m * toProject[1] + m * toProject[0] + b) / (m * m + 1);

    result[0]=x;
    result[1]=y;
    result[2]=0.0;
}

stock float min(float x, float y){
	return x <= y ? x : y;
}

stock float max(float x, float y) {
	return x >= y ? x : y;
}
