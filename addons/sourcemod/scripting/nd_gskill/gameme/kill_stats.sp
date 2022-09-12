/* This function returns a linear kill per death multipler */
float GameME_GetKpdFactor(int client)
{
	/* Reseratively get the client's modified kdr */
	float ClientKdr = GameME_GetModifiedKdr(client, true);

	if (ClientKdr < 1.0)
	{
		float base = gc_GameMe.kdrNegativeBase.FloatValue;
		float divider = 1.0 / (1.0 - base);
		
		return GameME_SkillBase[client] <= 80 ? 1.0 : base + ClientKdr / divider;
	}

	//If the client kdr is greater than one
	return 1.0 + ClientKdr / gc_GameMe.kdrPositiveDivider.FloatValue;
}

/* This function returns an imbalance calculated final kdr 
 * Resersion may cause an infinate loop, handle with care.
 */
float GameME_GetModifiedKdr(int client, bool resertive = false)
{
	float ClientKdr = GameME_KDR[client];
	float kdrMin = gc_GameMe.kdrMinSetValue.FloatValue;
	bool kdrChanged = false;
		
	if (ClientKdr < kdrMin)
	{
		ClientKdr = kdrMin;
		kdrChanged = true;
	}
	
	if (!kdrChanged && GameME_UseHPK_Modifier(client))
	{
		/* Get client hpk. Decide if we're going to use resersion or not */
		float ClientHpk = !resertive ? GameME_HPK[client] : (GameME_GetModifiedHpk(client) * 100.0);
		
		/* Calculate the percent the kdr and hpk is from the floor */
		float percentKdr = ClientKdr / gc_GameMe.kdrImbalanceBaseKdr.FloatValue;
		float percentHpk = ClientHpk / gc_GameMe.kdrImbalanceBaseHpk.FloatValue;		
			
		/* If there's an imbalance between the client kdr and hpk */
		if (percentKdr > percentHpk)
		{
			/* Take the difference off the client's kdr */
			ClientKdr *= percentHpk / percentKdr;
		}	
	}
	
	return ClientKdr;
}

/* This function returns a linear headshot per kill multipler */
float GameME_GetHpkFactor(int client)
{
	/* Reseratively get the client's modified hpk */
	float ClientHpk = GameME_GetModifiedHpk(client, true);
	
	// Turn convars values into a decimal for the calculation
	float negKdrDrop 	= percentToDecimal(gc_GameMe.hpkNegativeDrop.FloatValue);
	float posKdrBoost 	= percentToDecimal(gc_GameMe.hpkPositiveBoost.FloatValue);	
	float hpkMiddle		= 1 - percentToDecimal(gc_GameMe.hpkMiddleTendency.FloatValue);
	
	// Check if the hpk factor is negative. Disable if Skill base is not 80+.
	bool IsNegativeFactor = (hpkMiddle + ClientHpk) < 1;
	if (IsNegativeFactor && GameME_SkillBase[client] <= 80)
		return 1.0;
	
	//multiply total hpk by 15% for positive users
	float hpkMultiplier = IsNegativeFactor ? 1 - negKdrDrop : 1 + posKdrBoost;												
	return hpkMiddle + (ClientHpk * hpkMultiplier);
}

/* This function returns an imbalance calculated final hpk
 * Resersion may cause an infinate loop, handle with care.
 */
float GameME_GetModifiedHpk(int client, bool resertive = false)
{
	float ClientHpk = percentToDecimal(GameME_HPK[client]);
	
	if (GameME_UseKDR_Modifier(client))
	{		
		/* Get client kdr. Decide if we're going to use resersion or not */
		float ClientKdr = !resertive ? GameME_KDR[client] : GameME_GetModifiedKdr(client);
		
		/* Calculate the percent the kdr and hpk is from the floor */
		float percentKdr = ClientKdr / gc_GameMe.hpkImbalanceBaseKdr.FloatValue;
		float percentHpk = ClientHpk / percentToDecimal(gc_GameMe.hpkImbalanceBaseHpk.FloatValue);
			
		/* If there's an imbalance between the client kdr and hpk */
		if (percentHpk > percentKdr)
		{
			/* Take the difference off the client's hpk */
			ClientHpk *= percentKdr / percentHpk;
		}		
	}
	
	return ClientHpk;
}

/* This function returns an imbalance calculated final skill base */
float GameME_GetModifiedSkillBase(int client)
{
	/* Reseratively get the client's modified hpk */
	float ClientHpk = GameME_GetModifiedHpk(client, true);
	float ClientMinHpk = percentToDecimal(gc_GameMe.hpkMiddleTendency.FloatValue);
	
	if (ClientHpk < ClientMinHpk && GameME_UseHPK_Modifier(client) && GameME_SkillBase[client] > 80)
	{
		// calculate the percent taken off for every hpk percent missing
		float ClientHpkMod = (ClientMinHpk - ClientHpk) * gc_GameMe.hpkSkillBaseModifer.FloatValue;
		// Return the skill base times one minus the percent to take it off
		return GameME_SkillBase[client] * (1 - ClientHpkMod);
	}
	
	return GameME_SkillBase[client];
}

bool GameME_UseKDR_Modifier(int client) { //Does the kdr modifier meet requirements to use it?
	return !GameME_KDR_Availible(client) ? false : (GameMe_UseKills(client) || GameME_UseDeaths(client));
}

bool GameME_UseHPK_Modifier(int client) { //Does the hpk modifier meet requirements to use it?
	return !GameME_HPK_Availible(client) ? false : (GameMe_UseKills(client) && GameME_UseHeadShot(client));
}

bool GameMe_UseKills(int client){ //Are the kills within the requirement to use them?
	return GameME_Kills_Availible(client) && GameME_GetClientKills(client) >= gc_GameMe.killRequirement.IntValue;	
}

bool GameME_UseDeaths(int client){ //Are the deaths within the requirement to use them?
	return GameME_Deaths_Availible(client) && GameME_GetClientDeaths(client) >= gc_GameMe.deathRequirement.IntValue;	
}

bool GameME_UseHeadShot(int client){ //Are the headshots within the requirement to use them?
	return GameME_Headshots_Availible(client) && GameME_GetClientHeadshots(client) >= gc_GameMe.hsRequirement.IntValue;
}
