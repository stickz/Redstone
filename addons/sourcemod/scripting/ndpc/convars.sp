/* To add an enable convar update the enum and convarNames char
 * The abstract code will handle the logistics of creating the convar */

enum Convars
{
    	CommanderLang = 0,
    	TeamLang,
	BuildingReqs,
    	CaptureReqs,
     	ResearchReqs,
	RepairReqs,
	TangoReqs,
	SpecTesting
}

char convarNames[CONVAR_COUNT][] = {
	"commander_lang",
	"team_lang",
	"building_reqs",
	"capture_reqs",
	"research_reqs",
	"repair_reqs",
	"tang_reqs",
	"spec_testing"
};

/* That's all, the algorithum is bellow this line which creates the convars
 * And autoexecs them from a cfg file on the gameserver
 */

#define CONVAR_PREFIX "sm_ndpc_"
#define DESCRIPTION_PREFIX "Enable "

ConVar g_Enable[Convars];  

void CreateConVars()
{
	for (int convar = 0; convar < view_as<int>(Convars); convar++)
	{
		char cString[32];
		StrCat(cString, sizeof(cString), CONVAR_PREFIX);
		StrCat(cString, sizeof(cString), convarNames[convar]);
		
		char dString[32];
		StrCat(dString, sizeof(dString), DESCRIPTION_PREFIX);
		StrCat(dString, sizeof(dString), convarNames[convar]);
		
		g_Enable[convar] = CreateConVar(cString, "1", dString, _, true, 0.0, true, 1.0);	
	}
	
	AutoExecConfig(true, "nd_trans_settings");
}
