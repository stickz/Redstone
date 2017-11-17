#if defined _nd_maps_included_
  #endinput
#endif
#define _nd_maps_included_

#define ND_MAX_MAP_SIZE 32

/* Custom Maps */
enum ND_CustomMapCount {
	ND_Rock,
	ND_Mars,
	ND_Roadwork,
	ND_Sandbrick,
	ND_Nuclear,
	ND_Corner,
	ND_Submarine,
	ND_MetroImp,
	ND_Port
}

stock char ND_CustomMaps[ND_CustomMapCount][ND_MAX_MAP_SIZE] = 
{
	"rockv19",
	"mars_102",
	"roadwork_w01",
	"sandbrick_03",
	"nuclear_forest02",
	"corner_intermediate_04",
	"nd_submarine",
	"metro_imp2",
	"port"
};

stock bool ND_IsCustomMap(char[] mapName)
{
	for (int m = 0; m < view_as<int>(ND_CustomMapCount); m++)
	{
		if (StrEqual(ND_CustomMaps[m], mapName, false))
			return true;	
	}
	
	return false;
}

stock bool ND_CustomMapEquals(const char[] currentMap, ND_CustomMapCount:searchMap) {
	return StrEqual(currentMap, ND_CustomMaps[view_as<int>(searchMap)], false);
}

/* Stock Maps */

enum ND_StockMapCount {
	ND_Hydro,
	ND_Oasis,
	ND_Silo,
	ND_Metro,
	ND_Coast,
	ND_Gate,
	ND_Oilfield,
	ND_Downtown,
	ND_Clocktower
}

stock char ND_StockMaps[ND_StockMapCount][ND_MAX_MAP_SIZE] = {
	"hydro",
	"oasis",
	"silo",
	"metro",
	"coast",
	"gate",
	"oilfield",
	"downtown",
	"clocktower"
};

stock bool ND_IsStockMap(char[] mapName)
{
	for (int m = 0; m < view_as<int>(ND_StockMapCount); m++)
	{
		if (StrEqual(ND_StockMaps[m], mapName, false))
			return true;	
	}
	
	return false;
}

stock bool ND_StockMapEquals(const char[] currentMap, ND_StockMapCount:searchMap) {
	return StrEqual(currentMap, ND_StockMaps[view_as<int>(searchMap)], false);
}