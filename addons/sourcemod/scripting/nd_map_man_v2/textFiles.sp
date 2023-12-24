#define MAP_SIZE 32

#define TEXT_FILE_PATH_NORM "data/lastmaps.txt"
#define TEXT_FILE_PATH_EVENT "data/lastmaps_event.txt"

bool teamPickMode = false;

void CreateTextFile()
{
    /* Build a path to the text file */
	char path1[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path1, PLATFORM_MAX_PATH, TEXT_FILE_PATH_NORM);
	
	char path2[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path2, PLATFORM_MAX_PATH, TEXT_FILE_PATH_EVENT);	

    /* Check if the file does not already exist */
	if (!FileExists(path1))
	{
        /* Create the non-existent file */            
        File file = OpenFile(path1, "w");
    	file.Close()   
    }
	
	/* Check if the file does not already exist */
	if (!FileExists(path2))
    {
        /* Create the non-existent file */            
        File file = OpenFile(path2, "w");
    	file.Close()   
    }
}

void ReadTextFile()
{
    /* Clear the last map exclude array */
    g_PreviousMapList.Clear();
        
    /* Build the file path to the previous maps */        
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, PLATFORM_MAX_PATH, !teamPickMode  	? TEXT_FILE_PATH_NORM
																: TEXT_FILE_PATH_EVENT);
        
    /* Open file to with the read letter */
    File file = OpenFile(path, "r");
    
    /* Buffer to store file content */
    char map[MAP_SIZE];
    
    while (!file.EndOfFile() && file.ReadLine(map, MAP_SIZE))
    {
    	/* Push the map string into previous map list */
		TrimString(map);
	 	g_PreviousMapList.PushString(map);
    }
    
    /* Close the handle to the file we just opened */
    file.Close();
}

void WriteTextFile()
{
    /* Build the file path based on the array index */        
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, PLATFORM_MAX_PATH, !teamPickMode	? TEXT_FILE_PATH_NORM
																: TEXT_FILE_PATH_EVENT);
        
    /* Delete the file */
    DeleteFile(path);
        
    /* Create a new file with the same name for writing */
    File file = OpenFile(path, "w");
    
    /* Buffer to store the last map in */
    char lastMap[MAP_SIZE];
    
    for (int idx = 0; idx < g_PreviousMapList.Length; idx++)
    {
    	/* Get the previous map string */
    	g_PreviousMapList.GetString(idx, lastMap, MAP_SIZE);
    	
    	/* Trim the previous map string (to remove whitespaces) */
    	TrimString(lastMap);
    	
    	/* Write the previous map string to text file */
    	file.WriteLine(lastMap);
    }

    /* Close the handle to the file we just created */
    file.Close();
}