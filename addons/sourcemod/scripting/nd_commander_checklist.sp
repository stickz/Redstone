#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <nd_stocks>
#include <nd_com_eng>
#include <nd_entities>
#include <nd_research_eng>
#include <nd_struct_eng>
#include <nd_redstone>
#include <nd_rounds>

#define DEBUG			0

//Handle hudSync;

//ConVar g_enabled;
//ConVar g_maxskill;
ConVar g_hidedone;
ConVar g_updaterate;
ConVar g_afterdisplay;

#define CHECKLIST_ITEM_COUNT    5
#define CHECKLIST_NUM_TIERS	3
char checklistTasks[CHECKLIST_NUM_TIERS][CHECKLIST_ITEM_COUNT][25] = { 
	{"BUILD_FWD_SPAWN","RESEARCH_TACTICS","BUILD_ARMORY","RESEARCH_KITS","CHAT_MSG"},
	{"BUILD_POWER", "BUILD_SUPPLY", "BUILD_TWO_SPAWN", "RESEARCH_ADV_MAN", "RESEARCH_SR"},
	{"RESEARCH_MOD", "BUILD_RADAR", "RESEARCH_COM_ABB2", "BUILD_WALL", "RESEARCH_SR2"}
};
bool teamChecklists[CHECKLIST_NUM_TIERS][TEAM_COUNT][CHECKLIST_ITEM_COUNT+1];

int forwardSpawnCount = 0;
bool checkListCompleted[MAXPLAYERS+1] = {false, ...};

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
	//g_maxskill 	= CreateConVar("sm_comm_checklist_maxlevel", "80");
	g_hidedone 	= CreateConVar("sm_comm_checklist_hide_done", "1");
	g_updaterate 	= CreateConVar("sm_comm_checklist_updaterate", "1.5");
	g_afterdisplay	= CreateConVar("sm_comm_checklist_afterdisplay", "5");
	
	LoadTranslations("nd_commander_checklist.phrases");	
	AddClientPrefSupport(); // clientprefs.sp
	
	//For updating HUD when a forward spawn is built
	HookEvent("transport_gate_created",OnForwardSpawnCreated);
	//For updating HUD when the comm activate chat
	HookEvent("player_say", OnPlayerChat, EventHookMode_Post);
	
	if (ND_RoundStarted())
	{
		ResetVarriables();
		LateLoadStart();
	}
	
	AddUpdaterLibrary(); //auto-updater
}

public void OnMapStart() {
	ResetVarriables();
}

public void ND_OnRoundStarted() {
	ResetVarriables();
}

void LateLoadStart()
{
	for (int client = 1; client <= MAXPLAYERS; client++) 
	{
		if (RED_IsValidClient(client) && ND_IsCommander(client))
			StartTaskTimer(client);	
	}
}

void ResetVarriables()
{
	//init task arrays
	for (int idx = 2; idx < TEAM_COUNT; idx++)
	{
		for (int idx2 = 0; idx2 < CHECKLIST_ITEM_COUNT+1; idx2++)
		{
			for (int idx3 = 0; idx3 < CHECKLIST_NUM_TIERS; idx3++)
			{
				teamChecklists[idx3][idx][idx2] = false;
			}
		}
	}
	
	for (int client = 1; client <= MAXPLAYERS; client++) {
		checkListCompleted[client] = false;			
	}
	
	forwardSpawnCount = 0;
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

	// When the commander chats, check the item off in the list
	if (ND_IsCommander(client) && ND_HasEnteredCommanderMode(client))
		teamChecklists[0][GetClientTeam(client)][4] = true;

	return Plugin_Continue;
}

/* Engine items for checklists */
public void OnAdvancedKitsResearched(int team) {
	teamChecklists[0][team][3] = true;
}
public void OnFieldTacticsResearched(int team) {
	teamChecklists[0][team][1] = true;
}
public void OnBuildStarted_Armory(int team) {
	teamChecklists[0][team][2] = true;
}
public void OnBuildStarted_PowerPlant(int team) {
	teamChecklists[1][team][0] = true;
}
public void OnBuildStarted_SupplyStation(int team) {
	teamChecklists[1][team][1] = true;
}
public void OnAdvancedManufacturingResearched(int team) {
	teamChecklists[1][team][3] = true;
}
public void OnStructureReinResearched(int team, int level) {
	if (level == 1 || level == 2)
		teamChecklists[level][team][4] = true;
}
public void OnPowerModResearched(int team) {
	teamChecklists[2][team][0] = true;
}
public void OnBuildStarted_RadarStation(int team) {
	teamChecklists[2][team][1] = true;
}
public void OnCommanderAbilitiesResearched(int team, int level) {
	if (level == 2)
		teamChecklists[2][team][2] = true;
}
public void OnBuildStarted_Wall(int team) {
	teamChecklists[2][team][3] = true;
}

//structure_built and forward_spawn_created do not fire serverside. 
//transport_gate_created fires serverside but before the entity has an origin -
//so we set a timer for the entity and do our checks there.
public Action OnForwardSpawnCreated(Event event, const char[] name, bool dontBroadcast)
{
	// Don't fire for spawns created when the map first starts
	if (!ND_RoundStarted())
		return Plugin_Continue;
	
	//PrintToChatAll("Forward spawn created for team %d", teamId);
	CreateTimer(1.0, TransportGateTimerCB, event.GetInt("entindex"), TIMER_REPEAT);
	return Plugin_Continue;
}

public Action TransportGateTimerCB(Handle timer, any:entIdx)
{
	// Exit if the entity index isn't valid
	if (!IsValidEntity(entIdx))
		return Plugin_Stop;
	
	// Exit if the entity doesn't have a team number
	if (!HasEntProp(entIdx, Prop_Send, "m_iTeamNum"))
		return Plugin_Stop;
	
	// Exit if the entity doesn't have a vector origin
	if (!HasEntProp(entIdx, Prop_Send, "m_vecOrigin"))
		return Plugin_Stop;
	
	int teamId = GetEntProp(entIdx, Prop_Send, "m_iTeamNum");

	#if DEBUG == 1
		PrintToChatAll("Forward spawn timer for entity %d and team %d", entIdx, teamId);
	#endif

	if(!teamChecklists[0][teamId][0] || !teamChecklists[1][teamId][2]) 
	{
		float pos[3];
		GetEntPropVector(entIdx, Prop_Send, "m_vecOrigin", pos);

		// The transport isn't constructed yet, if cords are null
		if(pos[0] == 0.0 && pos[1] == 0.0 && pos[2] == 0.0)
			return Plugin_Continue;

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

		#if DEBUG == 1
			PrintToChatAll(
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
		#endif
		
		// If the forward spawn is 20% across the map, check the item off on the list
		if (percentAcrossMap >= 0.20)
		{		
			if (!teamChecklists[0][teamId][0])
				teamChecklists[0][teamId][0] = true;
			
			if (++forwardSpawnCount >= 3)
				teamChecklists[1][teamId][2] = true;
		}
	}
  	return Plugin_Stop;
}  

public void ND_OnCommanderPromoted(int client, int team) {
	StartTaskTimer(client);
}

void StartTaskTimer(int client)
{
	if (!checkListCompleted[client])
		CreateTimer(g_updaterate.FloatValue, DisplayChecklistCommander, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	
}

public Action DisplayChecklistCommander(Handle timer, any:Userid)
{
	if (!ND_RoundStarted()) // Stop the checklist when the round ends
		return Plugin_Stop;

	// If the client is invalid or no longer commander, stop the timer	
	int client = GetClientOfUserId(Userid);
	if (!RED_IsValidClient(client) || !ND_IsCommander(client))
		return Plugin_Stop;
	
	// If the client is in commander mode, with the checklist option enabled
	if (ND_IsInCommanderMode(client) && option_com_checklist[client])
	{	
		if (checkListCompleted[client])
			return Plugin_Stop;
		
		ShowCheckList(client);
		return Plugin_Continue;
	}	

	return Plugin_Continue;
}

//Updates the commander hud for the specified team.
//Shows or clears hud depending on whether comm is in
//chair and whether he has finished his tasks.
void ShowCheckList(int commander)
{
	int team = GetClientTeam(commander);	
	for (int i = 0; i < CHECKLIST_NUM_TIERS; i++)
	{
		if(!teamChecklists[i][team][CHECKLIST_ITEM_COUNT])
		{
			Handle hudSync = CreateHudSynchronizer();
			ShowSyncHudText(commander, hudSync, GetCheckListMessage(i, team, commander));
			CloseHandle(hudSync);
			break;
		}
	}
}

char[] GetCheckListMessage(int array, int team, int commander)
{
	char message[256]; 
	Format(message, sizeof(message), "%T\n", "COMMANDER_CHECKLIST", commander);

	int checkedItemCount = 0;
	for (int idx = 0; idx < CHECKLIST_ITEM_COUNT; idx++)
	{
		char state[4];
		if(teamChecklists[array][team][idx])
		{
			state="✔";
			checkedItemCount++;
		} 
		else
			state="✘";
					
		char task[25];
		task = checklistTasks[array][idx];
		if (!(teamChecklists[array][team][idx] && g_hidedone.BoolValue)) 
			Format(message, sizeof(message), "%s%s %T\n", message, state, task, commander);	
	}
	
	if(checkedItemCount >= CHECKLIST_ITEM_COUNT)
	{
		teamChecklists[array][team][CHECKLIST_ITEM_COUNT] = true;
		
		if (array == CHECKLIST_NUM_TIERS - 1)
		{
			Format(message, sizeof(message), "%T", "COMM_THANKS", commander);
			Format(message, sizeof(message), "%s\n%T", message, "COMM_SUPPORTTROOPS", commander);
			SetHudTextParams(1.0, 0.2, g_afterdisplay.FloatValue, 0, 128, 0, 80);
			CreateTimer(	g_afterdisplay.FloatValue, Timer_CheckListCompleted, 
					GetClientUserId(commander), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else
		SetHudTextParams(1.0, 0.1, g_updaterate.FloatValue, 255, 255, 80, 80);	
	
	return message;
}

public Action Timer_CheckListCompleted(Handle timer, any:userid)
{
	if (userid == INVALID_USERID)
		return Plugin_Handled;
	
	// Set the client's checklist completed status to true
	checkListCompleted[GetClientOfUserId(userid)] = true;
	return Plugin_Handled;
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

stock float min(float x, float y) {
	return x <= y ? x : y;
}

stock float max(float x, float y) {
	return x >= y ? x : y;
}

/* Natives */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_CheckListComplete", Native_GetCheckListComplete);
	CreateNative("ND_CheckListDisabled", Native_GetCheckListDisabled);
	return APLRes_Success;
}

public int Native_GetCheckListComplete(Handle plugin, int numParams) 
{
	// Retrieve the team parameter
	int client = GetNativeCell(1);
	
	// If the client is invalid, return false
	if (!RED_IsValidClient(client))
		return _:false;
	
	// Otherwise, return if the checklist is completed
	return _:checkListCompleted[client];
}

public int Native_GetCheckListDisabled(Handle plugin, int numParams) 
{
	// Retrieve the team parameter
	int client = GetNativeCell(1);
	
	// If the client is invalid, return false
	if (!RED_IsValidClient(client))
		return _:false;
	
	// Otherwise, return if the checklist is disabled	
	return _:(!option_com_checklist[client]);
}
