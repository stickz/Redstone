int bunkerEnts[TEAM_COUNT] = { -1, ... };
bool DisplayedMessage[TEAM_COUNT] = { false, ... };
int bunkerWarningHealth[TEAM_COUNT] = { 9000, ... };

void HookBunkerEntity() 
{
	bunkerEnts[TEAM_EMPIRE] = ND_GetTeamBunkerEntity(TEAM_EMPIRE);
	bunkerEnts[TEAM_CONSORT] = ND_GetTeamBunkerEntity(TEAM_CONSORT);	
	SDK_HookEntityDamaged(STRUCT_BUNKER, ND_OnBunkerDamaged);	
}

void UnHookBunkerEntity() 
{
	SDK_UnHookEntityDamaged(STRUCT_BUNKER, ND_OnBunkerDamaged);
	bunkerEnts[TEAM_EMPIRE] = -1;
	bunkerEnts[TEAM_CONSORT] = -1;
	bunkerWarningHealth[TEAM_EMPIRE] = 9000;
	bunkerWarningHealth[TEAM_CONSORT] = 9000;
	DisplayedMessage[TEAM_EMPIRE] = false;
	DisplayedMessage[TEAM_CONSORT] = false;
}

public Action ND_OnBunkerDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	if (!IsValidEntity(inflictor) || !ND_RoundStarted())
		return Plugin_Continue;
	
	if (IsValidClient(attacker))
	{
		int team = getOtherTeam(GetClientTeam(attacker));
		
		if (!DisplayedMessage[team] && ND_GetBuildingHealth(bunkerEnts[team]) <= bunkerWarningHealth[team])
		{
			PrintMessageTeam(team, "Bunker Health Warning");
			DisplayedMessage[team] = true;
		}
	}
	
	return Plugin_Continue;
}

public void OnStructureReinResearched(int team, int level) {
	bunkerWarningHealth[team] += 1000;	
}
