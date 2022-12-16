#if defined _nd_maps_included_
  #endinput
#endif
#define _nd_maps_included_

#define ND_MAX_MAP_SIZE 32

/* Custom Maps */
enum ND_CustomMapCount: {
	ND_Rock,
	ND_Mars,
	ND_Roadwork,
	ND_Sandbrick,
	ND_Nuclear,
	ND_Corner,
	ND_Submarine,
	ND_MetroImp,
	ND_Port,
	ND_DowntownDyn,
	ND_LostHorizons,
	CustomMapSize
}
stock int cm(ND_CustomMapCount map) {
	return view_as<int>(map);
}

stock char ND_CustomMaps[CustomMapSize][ND_MAX_MAP_SIZE] = 
{
	"rockv19",
	"mars_102",
	"roadwork_w01",
	"sandbrick_03",
	"nuclear_forest02",
	"corner_intermediate_04",
	"nd_submarine",
	"metro_imp3",
	"port",
	"downtown_dyn_v0",
	"nd_lost_horizons"
};

stock bool ND_IsCustomMap(char[] mapName)
{
	for (int m = 0; m < view_as<int>(CustomMapSize); m++)
	{
		if (StrEqual(ND_CustomMaps[m], mapName, false))
			return true;	
	}
	
	return false;
}

stock bool ND_CustomMapEquals(const char[] currentMap, ND_CustomMapCount searchMap) {
	return StrEqual(currentMap, ND_CustomMaps[view_as<int>(searchMap)], false);
}

/* Stock Maps */

enum ND_StockMapCount: {
	ND_Hydro,
	ND_Oasis,
	ND_Silo,
	ND_Metro,
	ND_Coast,
	ND_Gate,
	ND_Oilfield,
	ND_Downtown,
	ND_Clocktower,
	SK_Metro,
	StockMapSize
}
stock int sm(ND_StockMapCount map) {
	return view_as<int>(map);
}

stock char ND_StockMaps[StockMapSize][ND_MAX_MAP_SIZE] = {
	"hydro",
	"oasis",
	"silo",
	"metro",
	"coast",
	"gate",
	"oilfield",
	"downtown",
	"clocktower",
	"sk_metro"
};

stock bool ND_IsStockMap(char[] mapName)
{
	for (int m = 0; m < view_as<int>(StockMapSize); m++)
	{
		if (StrEqual(ND_StockMaps[m], mapName, false))
			return true;	
	}
	
	return false;
}

stock bool ND_StockMapEquals(const char[] currentMap, ND_StockMapCount searchMap) {
	return StrEqual(currentMap, ND_StockMaps[view_as<int>(searchMap)], false);
}

stock bool ND_MapEqualsAnyMetro(const char[] currentMap)
{
	return 	StrEqual(currentMap, ND_StockMaps[sm(ND_Metro)], false) ||
		StrEqual(currentMap, ND_CustomMaps[cm(ND_MetroImp)], false);
}

stock bool ND_CurrentMapIsCorner()
{
	char currentMap[32];
	GetCurrentMap(currentMap, sizeof(currentMap));
	return ND_CustomMapEquals(currentMap, ND_Corner);
}

stock bool ND_IsLargeResMap()
{
	char currentMap[32];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	if (ND_StockMapEquals(currentMap, ND_Downtown))
		return true;
	else if (ND_StockMapEquals(currentMap, ND_Gate))
		return true;
	else if (ND_StockMapEquals(currentMap, ND_Oilfield))
		return true;
	
	return false;
}

stock bool ND_IsMediumResMap()
{
	char currentMap[32];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	if (ND_CustomMapEquals(currentMap, ND_Roadwork))
		return true;
	else if (ND_StockMapEquals(currentMap, ND_Clocktower))
		return true;
		
	return false;
}

stock bool ND_IsServerHostMap()
{
	char currentMap[32];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	if (ND_StockMapEquals(currentMap, ND_Hydro))
		return true;
	else if (ND_StockMapEquals(currentMap, ND_Metro))
		return true;
	else if (ND_StockMapEquals(currentMap, ND_Silo))
		return true;
		
	return false;
}

stock bool ND_ExtendedTimeLimitMap(const char[] currentMap)
{
	if (ND_CustomMapEquals(currentMap, ND_Roadwork))
		return true;
	else if ( ND_CustomMapEquals(currentMap, ND_Corner))
		return true;
	else if (ND_StockMapEquals(currentMap, ND_Silo))
		return true;
	
	return false;
}

stock bool ND_IsAutoCycleMap(const char[] currentMap)
{
	if (ND_CustomMapEquals(currentMap, ND_Sandbrick))
		return true;
	else if (ND_CustomMapEquals(currentMap, ND_Submarine))
		return true;
	else if (ND_CustomMapEquals(currentMap, ND_Nuclear))
		return true;
	else if (ND_CustomMapEquals(currentMap, ND_Mars))
		return true;
	else if (ND_CustomMapEquals(currentMap, ND_Rock))
		return true;
	
	return false;
}

stock bool ND_IsInstantRTVMap(const char[] currentMap)
{
	if (ND_CustomMapEquals(currentMap, ND_Mars))
		return true;
	else if (ND_CustomMapEquals(currentMap, ND_Sandbrick))
		return true;
	else if (ND_CustomMapEquals(currentMap, ND_Nuclear))
		return true;
	else if (ND_CustomMapEquals(currentMap, ND_Submarine))
		return true;
	else if (ND_CustomMapEquals(currentMap, ND_Rock))
		return true;
	else if (ND_CustomMapEquals(currentMap, ND_Roadwork))
		return true;
	else if (ND_CustomMapEquals(currentMap, ND_Corner))
		return true;
		
	else if (ND_StockMapEquals(currentMap, ND_Oilfield))
		return true;
	else if (ND_StockMapEquals(currentMap, ND_Gate))
		return true;
	else if (ND_StockMapEquals(currentMap, ND_Downtown))
		return true;
	else if (ND_StockMapEquals(currentMap, ND_Clocktower))
		return true;
		
	return false;
}

stock bool ND_IsUnpopularRTVMap(const char[] currentMap)
{
	if (ND_CustomMapEquals(currentMap, ND_Mars))
		return true;
	else if (ND_CustomMapEquals(currentMap, ND_Sandbrick))
		return true;
	else if (ND_CustomMapEquals(currentMap, ND_Nuclear))
		return true;
	else if (ND_CustomMapEquals(currentMap, ND_Submarine))
		return true;
	else if (ND_CustomMapEquals(currentMap, ND_Rock))
		return true;
		
	else if (ND_StockMapEquals(currentMap, ND_Oilfield))
		return true;
	else if (ND_StockMapEquals(currentMap, ND_Gate))
		return true;
	else if (ND_StockMapEquals(currentMap, ND_Downtown))
		return true;
		
	return false;
}
