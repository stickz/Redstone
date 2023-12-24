#define SP_MAP_SIZE 4
#define CP_MAP_SIZE 1
#define UP_MAP_SIZE 4
#define SL_MAP_SIZE 4
#define CL_MAP_SIZE 3

/* 
 * Global varriables must be derived from constants;
 * So there's tons of messy things here .
 * But the code is very abstract and it works.
 */


// Large stock maps
int ndsLarge[SL_MAP_SIZE] = {
	view_as<int>(ND_Clocktower),
	view_as<int>(ND_Downtown),
	view_as<int>(ND_Gate),
	view_as<int>(ND_Oilfield)
}

// Large custom maps
int ndcLarge[CL_MAP_SIZE] = {
	view_as<int>(ND_Roadwork),
	view_as<int>(ND_Rock),
	view_as<int>(ND_Nuclear)
}

int GetRecentLargeMapCount()
{
	int checkPrev =	GetLargeExcludeCount();					
	int lrgMapCount = 0;
	
	// For all the last stock maps
	for (int idx = 0; idx < SL_MAP_SIZE; idx++) {
		// If you've been played within the last so many maps
		if (g_MapInputList.FindString(ND_StockMaps[ndsLarge[idx]]) >= checkPrev)
			lrgMapCount++; // Increment the large map count by one
	}
	
	// For all of the large custom maps
	for (int idx2 = 0; idx2 < CL_MAP_SIZE; idx2++) {
		// If you've been played within the last so many maps
		if (g_MapInputList.FindString(ND_CustomMaps[ndcLarge[idx2]]) >= checkPrev)
			lrgMapCount++;	// Increment the large map count by one	
	}
	
	return lrgMapCount;
}

int GetLargeExcludeCount()
{
	int storedMapCount = g_MapInputList.Length;
	int checkPreviousNum = cvarRecentLrgMapCheck.IntValue;
	
	// Since #50 is the most recent map, we need to reverse the math	
	return 			storedMapCount > checkPreviousNum 
				? 	storedMapCount - checkPreviousNum
				: 	storedMapCount;	
}