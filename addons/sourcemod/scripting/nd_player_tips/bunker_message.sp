int bunkerEnts[TEAM_COUNT] = { -1, ... };
bool DisplayedMessage[TEAM_COUNT] = { false, ... };

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
	DisplayedMessage[TEAM_EMPIRE] = false;
	DisplayedMessage[TEAM_CONSORT] = false;
}

public Action ND_OnBunkerDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	if (!IsValidEntity(inflictor))
		return Plugin_Continue;
	
	if (IsValidClient(attacker))
	{
		int team = getOtherTeam(GetClientTeam(attacker));
		
		if (!DisplayedMessage[team] && ND_GetBuildingHealth(bunkerEnts[team]) <= 9000)
		{
			PrintMessageTeam(team, "Bunker Health Warning");
			DisplayedMessage[team] = true;
		}
	}
	
	return Plugin_Continue;
}
