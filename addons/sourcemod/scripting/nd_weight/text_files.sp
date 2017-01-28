#define STEAMID_SIZE 32

#define TEXT_FILE_COUNT 5
char nd_text_file[TEXT_FILE_COUNT][] = {
	"data/skill/w80.txt",
	"data/skill/w100.txt",
	"data/skill/w120.txt",
	"data/skill/w140.txt",
	"data/skill/w160.txt"
};

void CreateTextFiles()
{
	/* For the number of previousily stored maps */
	for (int idx = 0; idx < TEXT_FILE_COUNT; idx++)
	{
		/* Build a path to the text file */
		char path[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, path, PLATFORM_MAX_PATH, nd_text_file[idx]);
		
		/* Check if the file does not already exist */
		if (!FileExists(path))
		{
			/* Create the non-existent file */			
			File file = OpenFile(path, "w");
			file.Close();
		}
	}	
}

void ReadTextFiles()
{
	/* Clear the last map exclude array */
	g_PlayerSkillFloors.Clear();
	g_SteamIDList.Clear();
		
	/* For the number of previousily stored maps */
	for (int idx = 0; idx < TEXT_FILE_COUNT; idx++)
	{
		/* Build the file path based on the array index */		
		char path[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, path, PLATFORM_MAX_PATH, nd_text_file[idx]);
		
		/* Open file to with the read letter */
		File file = OpenFile(path, "r");
		
		/* Copy file contents of the steamid */
		char steamid[STEAMID_SIZE];
		while (file.ReadLine(steamid, sizeof(steamid)))
		{		
			TrimString(steamid);
			
			/* Move the steamid to an adt array */
			int skillValue = 80 + (idx * 20);
			g_SteamIDList.PushString(steamid);	
			g_PlayerSkillFloors.Push(skillValue);
		}
		
		/* Close the file we just opened */
		file.Close();
	}
}

void WriteSteamID(char[] steamid, int fileIDX)
{
	/* Build the path to the text file */	
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, nd_text_file[fileIDX]);
	
	/* Write steam id contents to text file */
	File file = OpenFile(path, "a");
	TrimString(steamid);
	file.WriteLine(steamid);
	file.Close();	
}

void RemoveSteamIdFromFile(char[] steamid, int fileIDX)
{
	ArrayList steamAuths = new ArrayList(32);
	steamAuths.Clear();
	
	/* Build the file path based on the array index */		
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, nd_text_file[fileIDX]);
		
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
}
