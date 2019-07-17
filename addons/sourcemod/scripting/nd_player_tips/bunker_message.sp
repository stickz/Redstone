bool DisplayedMessage[TEAM_COUNT] = { false, ... };
int bunkerWarningHealth[TEAM_COUNT] = { 9000, ... };

void HookBunkerEntity() {
	SDK_HookEntityDamaged(STRUCT_BUNKER, ND_OnBunkerDamaged);	
}

void UnHookBunkerEntity() 
{
	SDK_UnHookEntityDamaged(STRUCT_BUNKER, ND_OnBunkerDamaged);
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
		int bunker = ND_GetTeamBunkerEntity(team);
		
		if (!DisplayedMessage[team] && ND_GetBuildingHealth(bunker) <= bunkerWarningHealth[team])
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
