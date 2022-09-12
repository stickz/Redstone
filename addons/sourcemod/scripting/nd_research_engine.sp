#include <sourcemod>
#include <sdktools>
#include <nd_research>
#include <nd_stocks>

public Plugin myinfo = 
{
	name 		= "[ND] Research Engine",
	author 		= "Stickz",
	description 	= "Creates forwards and natives for researching",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_research_engine/nd_research_engine.txt"
#include "updater/standard.sp"

// Hold the research completed forwards in an array
Handle OnResearchCompleted[ND_ResearchItemsSize];

// Hold the research levels in an array
int researchLevel[TEAM_COUNT][ND_ResearchItemsSize];

public void OnPluginStart()
{
	CreateResearchForwards(); // Create Research Forwards
	HookEvents(); // Hook required game events	
	AddUpdaterLibrary(); // Add auto updater feature
}

public void OnMapEnd() {
	ResetResearchTech();
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
	ResetResearchTech();
}

public Action Event_ResearchCompleted(Event event, const char[] name, bool dontBroadcast)
{
	int researchId = event.GetInt("researchid");
	int teamId = event.GetInt("teamid");

	// Organized by category. Actual Integer values will varry.
	switch(researchId)
	{
		// Armoury Research Commander Abilities
		case view_as<int>(Commander_Abilities): 	FireMultiTeirResearch(item(Commander_Abilities), teamId, 1);
		case view_as<int>(Commander_Abilities_Two):	FireMultiTeirResearch(item(Commander_Abilities), teamId, 2);
		case view_as<int>(Commander_Abilities_Three):	FireMultiTeirResearch(item(Commander_Abilities), teamId, 3);
		
		// Armoury Research Infantry_Boost
		case view_as<int>(Infantry_Boost):		FireMultiTeirResearch(item(Infantry_Boost), teamId, 1);
		case view_as<int>(Infantry_Boost_Two):		FireMultiTeirResearch(item(Infantry_Boost), teamId, 2);
		case view_as<int>(Infantry_Boost_Three):	FireMultiTeirResearch(item(Infantry_Boost), teamId, 3);
		
		// Armoury Research Structure_Reinforcement
		case view_as<int>(Structure_Reinforcement):		FireMultiTeirResearch(item(Structure_Reinforcement), teamId, 1);
		case view_as<int>(Structure_Reinforcement_Two):		FireMultiTeirResearch(item(Structure_Reinforcement), teamId, 2);
		case view_as<int>(Structure_Reinforcement_Three):	FireMultiTeirResearch(item(Structure_Reinforcement), teamId, 3);

		// Shortcut for remaining armoury and bunker research
		default: FireSingleTeirResearch(researchId, teamId);
	}
}

void ResetResearchTech()
{
	for (int tech = 0; tech < view_as<int>(ND_ResearchItemsSize); tech++)
	{
		for (int team = 0; team < TEAM_COUNT; team++)
		{
			researchLevel[team][tech] = RESEARCH_INCOMPLETE;
		}
	}
}

void HookEvents()
{
	HookEvent("research_complete", Event_ResearchCompleted, EventHookMode_Post);
	HookEvent("round_win", Event_RoundEnd, EventHookMode_PostNoCopy);	
}

void CreateResearchForwards()
{
	// Single level research only sends team as a cell
	OnResearchCompleted[item(Field_Tactics)] = CreateGlobalForward("OnFieldTacticsResearched", ET_Ignore, Param_Cell);
	OnResearchCompleted[item(Power_Modulation)] = CreateGlobalForward("OnPowerModResearched", ET_Ignore, Param_Cell);
	OnResearchCompleted[item(Advanced_Kits)] = CreateGlobalForward("OnAdvancedKitsResearched", ET_Ignore, Param_Cell);
	OnResearchCompleted[item(Advanced_Manufacturing)] = CreateGlobalForward("OnAdvancedManufacturingResearched", ET_Ignore, Param_Cell);
	
	// Multiple level research sends team and level as a cell
	OnResearchCompleted[item(Commander_Abilities)] = CreateGlobalForward("OnCommanderAbilitiesResearched", ET_Ignore, Param_Cell, Param_Cell);
	OnResearchCompleted[item(Infantry_Boost)] = CreateGlobalForward("OnInfantryBoostResearched", ET_Ignore, Param_Cell, Param_Cell);
	OnResearchCompleted[item(Structure_Reinforcement)] = CreateGlobalForward("OnStructureReinResearched", ET_Ignore, Param_Cell, Param_Cell);	
}

void FireSingleTeirResearch(int item, int team)
{
	// Fire the research forward
	Action dummy;
	Call_StartForward(OnResearchCompleted[item]);
	Call_PushCell(team);
	Call_Finish(dummy);
	
	// Mark the item as researched for natives
	researchLevel[team][item] = RESEARCH_COMPLETE;
}

void FireMultiTeirResearch(int item, int team, int level)
{
	// Fire the research forward
	Action dummy;
	Call_StartForward(OnResearchCompleted[item]);
	Call_PushCell(team);
	Call_PushCell(level);
	Call_Finish(dummy);
	
	// Mark the item research level for natives
	researchLevel[team][item] = level;
}

/* Natives */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_ItemHasBeenResearched", Native_GetItemResearched);
	CreateNative("ND_GetItemResearchLevel", Native_GetItemResearchLevel);	
	return APLRes_Success;
}

public int Native_GetItemResearched(Handle plugin, int numParams) 
{
	// Return if the research level for the team, and research item is completed
	return _:researchLevel[GetNativeCell(1)][item(GetNativeCell(2))] >= RESEARCH_COMPLETE;
}

public int Native_GetItemResearchLevel(Handle plugin, int numParams)
{
	// Return the research level for the team, and research item
	return researchLevel[GetNativeCell(1)][item(GetNativeCell(2))];
}
