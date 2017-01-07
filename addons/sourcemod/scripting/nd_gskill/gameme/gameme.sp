/* This module turns data from https://xenogamers.com/rank/players/nd
 * Into something useful that can be used for team balance
 * The "points" value is cruved into an exponential equation
 */

#include <nd_gameme>

#define SKILL_NOT_FOUND -1

Handle GameME_SkillReady_Forward;

int GameME_Skill[MAXPLAYERS+1] = {-1, ...};

float GameME_SkillBase[MAXPLAYERS+1] = {-1.0, ...};
float GameME_FinalSkill[MAXPLAYERS+1] = {-1.0, ...};
float GameME_KDR[MAXPLAYERS+1] = {-1.0, ...};
float GameME_HPK[MAXPLAYERS+1] = {-1.0, ...};

float percentToDecimal(float percent) {
	return percent / 100.0;
}

public void GameME_OnClientDataQueried(int client, int skill, float kdr, float hpk)
{
	#if _DEBUG
	PrintToServer("GameME_OnClientDataQueried() forwarded to nd_skill");
	#endif
	
	//Set skill varriable
	GameME_CalculateSkill(client, skill);
	
	//Set kdr and hpk varriables
	GameME_Skill[client] = skill;
	GameME_KDR[client] = kdr;
	GameME_HPK[client] = hpk;
	
	//Use kdr & hpk modifiers to skill where applicable
	GameME_AddInSkillModifiers(client);
		
	//Fire a forward when gameme skill calcuations are complete
	GameME_FireSkillReadyForward(client);
}


void GameME_InitializeFeatures()
{
	/* Add change hooks for all the convars */
	GameME_AddConvarChangeHooks();
	
	/* Create Forwards */
	GameME_SkillReady_Forward = CreateGlobalForward("GameME_OnSkillCalculated", ET_Ignore, Param_Cell, Param_Float);
}

GameME_AddConvarChangeHooks()
{
	/* GameME points base specific convars */
	gc_GameMe[gmLevelEighty].AddChangeHook(GameME_RefireSRForwards);
	gc_GameMe[gmGrowthInterval].AddChangeHook(GameME_RefireSRForwards);
	gc_GameMe[gmDecayInterval].AddChangeHook(GameME_RefireSRForwards);
	gc_GameMe[gmDecaySkill].AddChangeHook(GameME_RefireSRForwards);
	gc_GameMe[gmSkillTeirOne].AddChangeHook(GameME_RefireSRForwards);
	gc_GameMe[gmSkillTeirTwo].AddChangeHook(GameME_RefireSRForwards);
	gc_GameMe[gmBaseMulitpler].AddChangeHook(GameME_RefireSRForwards);
	
	/* GameMe hpk convars */
	gc_GameMe[hpkPositiveBoost].AddChangeHook(GameME_RefireSRForwards);
	gc_GameMe[hpkNegativeDrop].AddChangeHook(GameME_RefireSRForwards);
	gc_GameMe[hpkMiddleTendency].AddChangeHook(GameME_RefireSRForwards);
	gc_GameMe[hpkImbalanceBaseHpk].AddChangeHook(GameME_RefireSRForwards);
	gc_GameMe[hpkImbalanceBaseKdr].AddChangeHook(GameME_RefireSRForwards);
	
	/* GameMe kdr convars */
	gc_GameMe[kdrPositiveDivider].AddChangeHook(GameME_RefireSRForwards);
	gc_GameMe[kdrNegativeBase].AddChangeHook(GameME_RefireSRForwards);
	gc_GameMe[kdrMinSetValue].AddChangeHook(GameME_RefireSRForwards);
	gc_GameMe[kdrImbalanceOffset].AddChangeHook(GameME_RefireSRForwards);
	gc_GameMe[kdrImbalanceBaseHpk].AddChangeHook(GameME_RefireSRForwards);
	gc_GameMe[kdrImbalanceBaseKdr].AddChangeHook(GameME_RefireSRForwards);
	
	/* GameMe use convars */
	gc_GameMe[killRequirement].AddChangeHook(GameME_RefireSRForwards);
	gc_GameMe[deathRequirement].AddChangeHook(GameME_RefireSRForwards);
	gc_GameMe[hsRequirement].AddChangeHook(GameME_RefireSRForwards);
}

public void GameME_RefireSRForwards(ConVar convar, const char[] oldValue, const char[] newValue)
{
	for (int client=1; client<=MaxClients; client++) 
	{
		if (IsValidClient(client))
			GameMe_RefreshSkill(client);
	}
}

void GameMe_RefreshSkill(int client)
{
	GameME_CalculateSkill(client, GameME_Skill[client]);
	GameME_AddInSkillModifiers(client)
	GameME_FireSkillReadyForward(client);	
}

void GameMe_RecalculateSkill()
{
	for (int client=1; client<=MaxClients; client++) 
	{
		if (IsValidClient(client) && GameME_SkillAvailible(client))
		{
			GameME_CalculateSkill(client, GameME_GetClientSkill(client));
				
			if (GameME_KDR_Availible(client))
				GameME_KDR[client] = GameME_GetClientKDR(client);

			if (GameME_HPK_Availible(client))
				GameME_HPK[client] = GameME_GetClientHPK(client);
				
			GameME_AddInSkillModifiers(client)
			GameME_FireSkillReadyForward(client);				
		}
	}	
}

void GameME_FireSkillReadyForward(int client)
{
	Action dummy;
	Call_StartForward(GameME_SkillReady_Forward);
	Call_PushCell(client);
	Call_PushFloat(GameME_FinalSkill[client]);
	Call_Finish(dummy);	
}

void GameME_ResetVariables(int client)
{
	GameME_SkillBase[client] = -1.0;
	GameME_FinalSkill[client] = -1.0;
	GameME_KDR[client] = -1.0;
	GameME_HPK[client] = -1.0;	
	GameME_Skill[client] = -1;
}

void GameME_CalculateSkill(int client, int skill)
{
	int levelEighty = gc_GameMe[gmLevelEighty].IntValue;
	
	// Are we going to use the expontential growth equation ontop of the client level?
	if (skill > levelEighty)
	{
		float multipler = gc_GameMe[gmBaseMulitpler].FloatValue;		
		float growth = gc_GameMe[gmGrowthInterval].FloatValue;	
		GameME_SkillBase[client] = MAX_INGAME_LEVEL + EXP_CalculateSkill(skill, levelEighty, multipler, growth);
	}
	
	// We're going to tack expontential decay equation onto the client's level
	// To Do: Calculate percentage client is to each interval
	else if (skill != SKILL_NOT_FOUND)
	{
		int t2 = gc_GameMe[gmSkillTeirTwo].IntValue;
		if (skill >= t2)
		{			
			int t1 = gc_GameMe[gmSkillTeirOne].IntValue;			
			if (skill >= t1)
				GameME_SetDecaySkill(client, skill, t1, 20);			
			else
				GameME_SetDecaySkill(client, skill, t2, 45);	
		}
	}	
}

/* This function creates a floor for the client's in-game level
 * If their level is less than the floor, it will be bumped up
 * Helps tackle level resets for clients with minimal data
 */
void GameME_SetDecaySkill(int client, int skill, int teir, int base)
{
	float skillDecay	= gc_GameMe[gmDecayInterval].FloatValue;
	int skillInterval 	= gc_GameMe[gmDecaySkill].IntValue;
	
	/* To Do: Don't use for loop intervals to exponentially decay skill
	 * An equation would be better, but how can this relationally be done?
	 */
	int min; float subtract;
	for (int i = 2; i >=0; i--)
	{
		min = teir + (skillInterval * i);
		if (skill > min)
		{
			subtract = base - (skillDecay * (i + 1));
			GameME_SkillBase[client] = MAX_INGAME_LEVEL;
			GameME_SkillBase[client] -= subtract;
			break;			
		}		
	}	
}

void GameME_AddInSkillModifiers(int client)
{
	// Set final skill varriable to the exponential base
	GameME_FinalSkill[client] = GameME_SkillBase[client];
	
	// Modify the base - based on the client's kdr ratio
	if (GameME_UseKDR_Modifier(client))
		GameME_FinalSkill[client] *= GameME_GetKpdFactor(client);
	
	// Stack any hpk modifications ontop of base & kdr to account for imbalances
	if (GameME_UseHPK_Modifier(client))
		GameME_FinalSkill[client] *= GameME_GetHpkFactor(client);	
}
