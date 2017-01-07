/* This function returns a linear kill per death multipler */
float GameME_GetKpdFactor(int client)
{
	float ClientKdr = GameME_KDR[client];	
	float kdrMin = gc_GameMe[kdrMinSetValue].FloatValue;
	bool kdrChanged = false
		
	if (ClientKdr < kdrMin)
	{
		ClientKdr = kdrMin;
		kdrChanged = true;
	}
	
	if (!kdrChanged && GameME_UseHPK_Modifier(client))
	{		
		/* If the client kdr is greater than the min check floor */
		float minKdr = gc_GameMe[kdrImbalanceBaseKdr].FloatValue;
		if (ClientKdr > minKdr)
		{
			/* Calculate the percent the kdr and hpk is from the floor */
			float percentKdr = ClientKdr / minKdr;
			float percentHpk = GameME_HPK[client] / gc_GameMe[kdrImbalanceBaseHpk].FloatValue;		
			
			/* If there's an imbalance between the client kdr and hpk */
			if (percentKdr > percentHpk)
			{
				/* Take the difference off the client's kdr */
				ClientKdr *= percentHpk / percentKdr;
			}
		}	
	}
	
	if (ClientKdr < 1.0)
	{
		float base = gc_GameMe[kdrNegativeBase].FloatValue;
		float divider = 1.0 / (1.0 - base);
		
		return base + ClientKdr / divider;
	}
	
	//If the client kdr is greater than one
	return 1.0 + ClientKdr / gc_GameMe[kdrPositiveDivider].FloatValue;
}

/* This function returns a linear headshot per kill multipler */
float GameME_GetHpkFactor(int client)
{
	float ClientHpk = GameME_HPK[client] / 100.0;
	
	if (GameME_UseKDR_Modifier(client))
	{		
		/* If the client hpk is greater than the min check floor */
		float minHpk = gc_GameMe[hpkImbalanceBaseHpk].FloatValue / 100.0;		
		if (ClientHpk > minHpk)
		{
			/* Calculate the percent the kdr and hpk is from the floor */
			float percentKdr = GameME_KDR[client] / gc_GameMe[hpkImbalanceBaseKdr].FloatValue;
			float percentHpk = ClientHpk / minHpk;
			
			/* If there's an imbalance between the client kdr and hpk */
			if (percentHpk > percentKdr)
			{
				/* Take the difference off the client's hpk */
				ClientHpk *= percentKdr / percentHpk;
			}		
		}
	}
	
	//turn convars values into a decimal for the calculation
	float negKdrDrop 	= percentToDecimal(gc_GameMe[hpkNegativeDrop].FloatValue);
	float posKdrBoost 	= percentToDecimal(gc_GameMe[hpkPositiveBoost].FloatValue);	
	float hpkMiddle		= 1 - percentToDecimal(gc_GameMe[hpkMiddleTendency].FloatValue);
	
	//multiply total hpk by 15% for positive users
	float hpkMultiplier = (hpkMiddle + ClientHpk) < 1 ? 1 - negKdrDrop : 1 + posKdrBoost;												
	return hpkMiddle + (ClientHpk * hpkMultiplier);
}

bool GameME_UseKDR_Modifier(int client) { //Does the kdr modifier meet requirements to use it?
	return !GameME_KDR_Availible(client) ? false : (GameMe_UseKills(client) || GameME_UseDeaths(client));
}

bool GameME_UseHPK_Modifier(int client) { //Does the hpk modifier meet requirements to use it?
	return !GameME_HPK_Availible(client) ? false : (GameMe_UseKills(client) && GameME_UseHeadShot(client));
}

bool GameMe_UseKills(int client){ //Are the kills within the requirement to use them?
	return GameME_Kills_Availible(client) && GameME_GetClientKills(client) >= gc_GameMe[killRequirement].IntValue;	
}

bool GameME_UseDeaths(int client){ //Are the deaths within the requirement to use them?
	return GameME_Deaths_Availible(client) && GameME_GetClientDeaths(client) >= gc_GameMe[deathRequirement].IntValue;	
}

bool GameME_UseHeadShot(int client){ //Are the headshots within the requirement to use them?
	return GameME_Headshots_Availible(client) && GameME_GetClientHeadshots(client) >= gc_GameMe[hsRequirement].IntValue;
}
