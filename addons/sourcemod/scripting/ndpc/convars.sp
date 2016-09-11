enum
{
      CommanderLang,
      TeamLang,
      BuildingReqs,
      CaptureReqs,
      convars
}

ConVar g_Enable[convars];  

void CreateConVars()
{
	g_Enable[CommanderLang] = CreateConVar("sm_ndpc_commanderlang", "1", "Enable commander lang", _, true, 0.0, true, 1.0);
	g_Enable[TeamLang] 	= CreateConVar("sm_ndpc_teamlang", "1", "Enable team lang", _, true, 0.0, true, 1.0);
	g_Enable[BuildingReqs] 	= CreateConVar("sm_ndpc_buildingreqs", "1", "Enable building requests", _, true, 0.0, true, 1.0);
	g_Enable[CaptureReqs] 	= CreateConVar("sm_ndpc_capturereqs", "1", "Enable capture requests", _, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "nd_trans_settings");
}
