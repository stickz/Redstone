#define STEAMID_SIZE 32

#define DATA_FOLDER "data/com/"
#define TEXT_FILE_PATH "data/com/dep.txt"

void CreateTextFile()
{
	char folderPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, folderPath, PLATFORM_MAX_PATH, DATA_FOLDER);
	if (!DirExists(folderPath, false))
		CreateDirectory(folderPath, 511);
	
	/* Build a path to the text file */
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, TEXT_FILE_PATH);
		
	/* Check if the file does not already exist */
	if (!FileExists(path))
	{
		/* Create the non-existent file */			
		File file = OpenFile(path, "w");
		file.Close();
	}
}

void ReadTextFile()
{
	/* Clear the steamid array */
	g_SteamIDList.Clear();
		
	/* Build the file path based on the array index */		
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, TEXT_FILE_PATH);
		
	/* Open file to with the read letter */
	File file = OpenFile(path, "r");
		
	/* Copy file contents of the steamid */
	char steamid[STEAMID_SIZE];
	while (file.ReadLine(steamid, STEAMID_SIZE))
	{		
		TrimString(steamid);
		g_SteamIDList.PushString(steamid);	
	}
		
	/* Close the file we just opened */
	file.Close();
}

void WriteSteamId(char[] steamid)
{
	/* Build the path to the text file */	
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, TEXT_FILE_PATH);
	
	/* Write steam id contents to text file */
	File file = OpenFile(path, "a");
	TrimString(steamid);
	file.WriteLine(steamid);
	file.Close();	
}

void RemoveSteamId(char[] steamid)
{
	ArrayList steamAuths = new ArrayList(32);
	
	/* Build the file path based on the array index */		
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, TEXT_FILE_PATH);
		
	/* Open file to with the read letter */
	File file = OpenFile(path, "r");
		
	/* Put file contents into an array */
	char fSteamid[STEAMID_SIZE];
	while (file.ReadLine(fSteamid, sizeof(fSteamid)))
	{		
		TrimString(fSteamid);
		steamAuths.PushString(fSteamid);	
	}
	file.Close();
	
	/* Erase the said value from text file */
	int e = steamAuths.FindString(steamid);
	steamAuths.Erase(e);
	
	/* Open file to with the write letter */
	file = OpenFile(path, "w");
	
	/* Write old contents back to text file */
	for (int i = 0; i < steamAuths.Length; i++)
	{
		char toWrite[STEAMID_SIZE];
		steamAuths.GetString(i, toWrite, sizeof(toWrite));
		TrimString(toWrite);		
		file.WriteLine(toWrite);		
	}
	
	file.Close();
	delete steamAuths;
}
