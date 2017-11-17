int GetMapPlayerCount(const char[] checkMap)
{
	if (ND_IsLargeMap(checkMap))
		return GetSlotCount(28, 32, 32);
		
	else if (ND_IsMediumMap(checkMap))
		return GetSlotCount(26, 28, 30);
		
	else if (ND_IsTinyMap(checkMap))
		return GetSlotCount(22, 24, 26);

	/* metro, silo, oasis, coast, hydro */
	else 
		return GetSlotCount(24, 26, 28);
}

bool ND_IsLargeMap(const char[] checkMap)
{
	return ND_StockMapEquals(checkMap, ND_Oilfield)
		|| ND_CustomMapEquals(checkMap, ND_Rock)
		|| ND_StockMapEquals(checkMap, ND_Gate) 		
		|| ND_StockMapEquals(checkMap, ND_Downtown);
}

bool ND_IsMediumMap(const char[] checkMap)
{
	return ND_StockMapEquals(checkMap, ND_Clocktower)
		|| ND_CustomMapEquals(checkMap, ND_Roadwork)
		|| ND_CustomMapEquals(checkMap, ND_Nuclear);	
}

bool ND_IsTinyMap(const char[] checkMap)
{
	return ND_CustomMapEquals(checkMap, ND_Corner)
		|| ND_CustomMapEquals(checkMap, ND_Mars)
		|| ND_CustomMapEquals(checkMap, ND_Sandbrick)
		|| ND_CustomMapEquals(checkMap, ND_Port);	
}

int GetSlotCount(int min, int med, int max)
{
	if (!ND_GEA_AVAILBLE() || !eSkillBasedSlots())
		return max;	
		
	float avSkill = ND_GetEnhancedAverage();
	
	int hSkill = g_Cvar[HighSkill].IntValue;
	int lSkill  = g_Cvar[LowSkill].IntValue;	
	
	return 	avSkill < lSkill  ? max : 
			avSkill < hSkill  ? med 
					          : min;
}

bool eSkillBasedSlots() {
	return ND_GetClientCount() > g_Cvar[MinPlayServerSlots].IntValue;
}