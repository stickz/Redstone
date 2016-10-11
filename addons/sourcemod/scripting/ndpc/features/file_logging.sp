// Logging stuff for plugin
char NDPC_LogFile[PLATFORM_MAX_PATH]; 
#define LOG_FOLDER			"logs"
#define LOG_PREFIX			"ndpc_"
#define LOG_EXT				"log"

// Log Functions
void BuildLogFilePath() // Build Log File System Path
{
	char sLogPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sLogPath, sizeof(sLogPath), LOG_FOLDER);

	if ( !DirExists(sLogPath) ) // Check if SourceMod Log Folder Exists Otherwise Create One
		CreateDirectory(sLogPath, 511);

	char cTime[64];
	FormatTime(cTime, sizeof(cTime), "%Y%m");
	
	char sLogFile[PLATFORM_MAX_PATH];
	sLogFile = NDPC_LogFile;

	BuildPath(Path_SM, NDPC_LogFile, sizeof(NDPC_LogFile), "%s/%s%s.%s", LOG_FOLDER, LOG_PREFIX, cTime, LOG_EXT);
	
	if (!StrEqual(NDPC_LogFile, sLogFile))
		LogAction(0, -1, "[NDPC] Log File: %s", NDPC_LogFile);
}

void NoTranslationFound(int client, const char[] sArgs)
{
	CPrintToChat(client, "%s%t %s%t.", TAG_COLOUR, "Translate Tag", MESSAGE_COLOUR, "No Translate Keyword");
	
	char toLog[32];
	Format(toLog, sizeof(toLog), "[Not a Keyword] %s", sArgs);
	
	LogToFileEx(NDPC_LogFile, "%s", toLog);
}
