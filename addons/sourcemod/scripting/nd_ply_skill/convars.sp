enum convars
{
	ConVar:LevelEightyExp
};
ConVar g_Cvar[convars];

void CreatePluginConvars()
{
	g_Cvar[LevelEightyExp] = CreateConVar("sm_pskill_eightyexp", "450000", "specifies the exp required to be considered level eighty");
}