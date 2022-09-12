enum struct GMConvars
{
	ConVar:gmLevelEighty;
	ConVar:gmGrowthInterval;
	ConVar:gmDecayInterval;
	ConVar:gmDecaySkill;
	ConVar:gmSkillTeirOne;
	ConVar:gmSkillTeirTwo;
	ConVar:gmBaseMulitpler;
	
	ConVar:hpkPositiveBoost;
	ConVar:hpkNegativeDrop;
	ConVar:hpkMiddleTendency;
	ConVar:hpkImbalanceBaseHpk;
	ConVar:hpkImbalanceBaseKdr;
	ConVar:hpkSkillBaseModifer;
	
	ConVar:kdrPositiveDivider;
	ConVar:kdrNegativeBase;
	ConVar:kdrMinSetValue;
	ConVar:kdrImbalanceOffset;
	ConVar:kdrImbalanceBaseHpk;
	ConVar:kdrImbalanceBaseKdr;
	
	ConVar:killRequirement;
	ConVar:deathRequirement;
	ConVar:hsRequirement;
}

GMConvars gc_GameMe;

void GameME_CreateConvars()
{
	/* Create ConVars */
	gc_GameMe.gmLevelEighty		= 	CreateConVar("sm_gameme_startingEighty", "50000", "Skill level for player to be considered level 80");
	gc_GameMe.gmGrowthInterval 		=	CreateConVar("sm_gameme_egi", "20", "Specifies the skill increase at each exponential tick");
	gc_GameMe.gmDecayInterval		=	CreateConVar("sm_gameme_edi", "5", "Specifies the skill decrease at each exponential tick");
	gc_GameMe.gmDecaySkill			= 	CreateConVar("sm_gameme_dc", "5000", "Specifies skill value between each decay tick");	
	gc_GameMe.gmSkillTeirOne		=	CreateConVar("sm_gameme_lmint1", "30000", "Specifies the min value for level min teir 1");	
	gc_GameMe.gmSkillTeirTwo		=	CreateConVar("sm_gameme_lmint2", "10000", "Specifies the min value for level min teir 2");	
	gc_GameMe.gmBaseMulitpler		=	CreateConVar("sm_gameme_expMult", "1.9", "Specifies the multipler between each exponential tick");	
	
	gc_GameMe.hpkPositiveBoost 		=   	CreateConVar("sm_gameme_hpk_boost", "20", "Percentage to increase postive hpks ratios by");
	gc_GameMe.hpkNegativeDrop		= 	CreateConVar("sm_gameme_hpk_drop", "25", "Percentage to decrease negative hpks ratios by");	
	gc_GameMe.hpkMiddleTendency		=	CreateConVar("sm_gameme_hpk_middle", "15", "Specifies what hpk value is used as the average, in calculations.");
	gc_GameMe.hpkImbalanceBaseHpk		=	CreateConVar("sm_gameme_hpk_ibhpk", "15", "Specifies the imbalance hpk value for hpk calculations.");		
	gc_GameMe.hpkImbalanceBaseKdr		=	CreateConVar("sm_gameme_hpk_ibkdr", "1.5", "Specifies the imbalance kdr value for hpk calculations.");
	gc_GameMe.hpkSkillBaseModifer	 	= 	CreateConVar("sm_gameme_hpk_ibsb", "2", "Specifies skill base percent reduction for every hpk point missing from average.");
	
	gc_GameMe.kdrPositiveDivider		= 	CreateConVar("sm_gameme_kdr_posDevider", "20", "Value to devide postive kdrs by");
	gc_GameMe.kdrNegativeBase		= 	CreateConVar("sm_gameme_kdr_negBase", "0.75", "Factor to base negative kdrs off of... lower = more impact, higher = less impact");	
	gc_GameMe.kdrMinSetValue		=	CreateConVar("sm_gameme_kdr_minvalue", "0.65", "Set's the min value for client kdrs to be classifed as");
	gc_GameMe.kdrImbalanceOffset		=	CreateConVar("sm_gameme_kdr_oImbalance", "0.92", "Factor to additionally decrease imbalanced commander kdrs by");
	gc_GameMe.kdrImbalanceBaseHpk		=	CreateConVar("sm_gameme_kdr_ibhpk", "10", "Specifies the imbalance hpk value for kdr calculations.");
	gc_GameMe.kdrImbalanceBaseKdr		=	CreateConVar("sm_gameme_kdr_ibkdr", "1.5", "Specifies the imbalance kdr value for kdr calculations.");
	
	gc_GameMe.killRequirement 		=	CreateConVar("sm_gameme_killReq", "3000", "Specifies how many kills are required to use kdr factors.");
	gc_GameMe.deathRequirement 		=	CreateConVar("sm_gameme_deathReq", "3000", "Specifies how many kills are required to use kdr factors.");
	gc_GameMe.hsRequirement 		=	CreateConVar("sm_gameme_hsReq", "350", "Specifies how many kills are required to use kdr factors.");
}
