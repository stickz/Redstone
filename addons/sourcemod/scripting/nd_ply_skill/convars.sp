#include <autoexecconfig>

enum convars
{
	ConVar LevelEightyExp;
	ConVar MaxCommanderSkill;
}
convars g_Cvar;

void CreatePluginConvars()
{
	AutoExecConfig_Setup("nd_final_skill");
	
	g_Cvar.LevelEightyExp 		= 	AutoExecConfig_CreateConVar("sm_pskill_eightyexp", "450000", "specifies the exp required to be considered level eighty");
	g_Cvar.MaxCommanderSkill 	=	AutoExecConfig_CreateConVar("sm_pskill_max_com_skill", "160", "Specifies the maximum value to record for commander skill");
	
	AutoExecConfig_EC_File();
}