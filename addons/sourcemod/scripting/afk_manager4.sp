#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <nd_rounds>

#pragma semicolon 1

#undef REQUIRE_PLUGIN
#tryinclude <colors>
#define REQUIRE_PLUGIN

//Auto Updater Suport
#define UPDATE_URL	"https://github.com/stickz/Redstone/raw/build/updater/afk_manager4/translations/afk_manager.phrases.txt"
#include 		"updater/standard.sp"

// Defines
#define AFK_WARNING_INTERVAL		5
#define AFK_CHECK_INTERVAL		1.0

#if !defined MAX_MESSAGE_LENGTH
	#define MAX_MESSAGE_LENGTH	250
#endif

#define SECONDS_IN_DAY			86400

#define ND_TRANSPORT_GATE 		2
#define ND_TRANSPORT_NAME 		"struct_transport_gate"

#define LOG_FOLDER			"logs"
#define LOG_PREFIX			"afkm_"
#define LOG_EXT				"log"

// ConVar Defines
#define CONVAR_ENABLED			0
#define CONVAR_PREFIXSHORT		1
#define CONVAR_PREFIXCOLORS		2
#define CONVAR_LOG_WARNINGS		3
#define CONVAR_TIMETOMOVE		4
#define CONVAR_TIMETOKICK		5
#define CONVAR_EXCLUDEDEAD		6
#define CONVAR_SIZE			7

// Arrays
char AFKM_LogFile[PLATFORM_MAX_PATH]; // Log File
//Handle g_FWD_hPlugins 		=	INVALID_HANDLE; // Forward Plugin Handles
Handle g_hAFKTimer[MAXPLAYERS+1] 	=	{INVALID_HANDLE, ...}; // AFK Timers
int g_iAFKTime[MAXPLAYERS+1] 		=	{-1, ...}; // Initial Time of AFK
int g_iSpawnTime[MAXPLAYERS+1] 		=	{-1, ...}; // Time of Spawn
int iButtons[MAXPLAYERS+1] 		=	{0, ...}; // Bitsum of buttons pressed
int g_iPlayerTeam[MAXPLAYERS+1] 	=	{-1, ...}; // Player Team
int iPlayerAttacker[MAXPLAYERS+1] 	=	{-1, ...}; // Player Attacker
int iObserverMode[MAXPLAYERS+1] 	=	{-1, ...}; // Observer Mode
int iObserverTarget[MAXPLAYERS+1] 	=	{-1, ...}; // Observer Target
//int iMouse[MAXPLAYERS+1][2]; // X = Vertical, Y = Horizontal
bool bPlayerAFK[MAXPLAYERS+1] 		=	{true, ...}; // Player AFK Status
bool bPlayerDeath[MAXPLAYERS+1] 	=	{false, ...};
float fEyeAngles[MAXPLAYERS+1][3]; // X = Vertical, Y = Height, Z = Horizontal

bool bCvarIsHooked[CONVAR_SIZE] =	{false, ...}; // Console Variable Hook Status

// Global Variables
// Console Related Variables
bool g_bEnabled 		=	false;
char g_sPrefix[] 		=	"AFK Manager";
#if defined _colors_included
bool g_bPrefixColors 		=	false;
#endif
bool g_bLogWarnings 		=	false;
bool g_bExcludeDead 		=	false;
int g_iTimeToMove 		=	-1;
int g_iTimeToKick 		=	-1;

// Status Variables
bool bMovePlayers 		=	true;
bool bKickPlayers 		=	true;
bool g_bWaitRound 		=	true;

// Spectator Related Variables
#define g_iSpec_Team 1
#define g_iSpec_FLMode 6

// Forwards
Handle g_FWD_hOnAFKEvent 	=	INVALID_HANDLE;
Handle g_FWD_hOnClientAFK	=	INVALID_HANDLE;
Handle g_FWD_hOnClientBack 	=	INVALID_HANDLE;

// AFK Manager Console Variables
ConVar hCvarEnabled;
ConVar hCvarPrefixShort;
#if defined _colors_included
ConVar hCvarPrefixColor;
#endif
ConVar hCvarLogWarnings;
ConVar hCvarLogMoves;
ConVar hCvarLogKicks;
ConVar hCvarLogDays;
ConVar hCvarMinPlayersMove;
ConVar hCvarMinPlayersKick;
ConVar hCvarAdminsImmune;
ConVar hCvarAdminsFlag;
ConVar hCvarMoveSpec;
ConVar hCvarTimeToMove;
ConVar hCvarWarnTimeToMove;
ConVar hCvarKickPlayers;
ConVar hCvarTimeToKick;
ConVar hCvarWarnTimeToKick;
ConVar hCvarSpawnTime;
ConVar hCvarWarnSpawnTime;
ConVar hCvarExcludeDead;

// Plugin Information
public Plugin myinfo =
{
    name = "[ND] AFK Manager",
    author = "Rothgar, Stickz",
    description = "Takes action on AFK players",
    version = "dummy",
    url = "https://github.com/stickz/Redstone/"
};

// API
void API_Init()
{
	CreateNative("AFKM_IsClientAFK", Native_IsClientAFK);
	CreateNative("AFKM_GetClientAFKTime", Native_GetClientAFKTime);
	g_FWD_hOnAFKEvent = CreateGlobalForward("AFKM_OnAFKEvent", ET_Event, Param_String, Param_Cell);
	g_FWD_hOnClientAFK = CreateGlobalForward("AFKM_OnClientAFK", ET_Ignore, Param_Cell);
	g_FWD_hOnClientBack = CreateGlobalForward("AFKM_OnClientBack", ET_Ignore, Param_Cell);
}

// Natives
public int Native_IsClientAFK(Handle plugin, int numParams) // native bool AFKM_IsClientAFK(int client);
{
	// bPlayerAFK[client], No redundant error catching.
	// Call IsValidClient() before the native.
	return bPlayerAFK[GetNativeCell(1)];
}

public int Native_GetClientAFKTime(Handle plugin, int numParams) // native int AFKM_GetClientAFKTime(int client);
{
	// No redundant error catching. Call IsValidClient() before the native
	int client = GetNativeCell(1);
	return g_iAFKTime[client] == -1 ? g_iAFKTime[client] : (GetTime() - g_iAFKTime[client]);
}

// Forwards
void Forward_OnClientAFK(int client) // forward void AFKM_OnClientAFK(int client);
{
	Call_StartForward(g_FWD_hOnClientAFK); // Start Forward
	Call_PushCell(client);
	Call_Finish();
}

void Forward_OnClientBack(int client) // forward void AFKM_OnClientBack(int client);
{
	Call_StartForward(g_FWD_hOnClientBack); // Start Forward
	Call_PushCell(client);
	Call_Finish();
}

Action Forward_OnAFKEvent(const char[] name, int client) // forward Action AFKM_OnAFKEvent(const char[] name, int client);
{
	Action result;

	Call_StartForward(g_FWD_hOnAFKEvent); // Start Forward
	Call_PushString(name);
	Call_PushCell(client);
	Call_Finish(result);

	return result;
}


// Log Functions
void BuildLogFilePath() // Build Log File System Path
{
	char sLogPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sLogPath, sizeof(sLogPath), LOG_FOLDER);

	if ( !DirExists(sLogPath) ) // Check if SourceMod Log Folder Exists Otherwise Create One
		CreateDirectory(sLogPath, 511);

	char cTime[64];
	FormatTime(cTime, sizeof(cTime), "%Y%m%d");

	char sLogFile[PLATFORM_MAX_PATH];
	sLogFile = AFKM_LogFile;

	BuildPath(Path_SM, AFKM_LogFile, sizeof(AFKM_LogFile), "%s/%s%s.%s", LOG_FOLDER, LOG_PREFIX, cTime, LOG_EXT);

	if (!StrEqual(AFKM_LogFile, sLogFile))
		LogAction(0, -1, "[AFK Manager] Log File: %s", AFKM_LogFile);
}

void PurgeOldLogs() // Purge Old Log Files
{
	char sLogPath[PLATFORM_MAX_PATH];
	char buffer[256];
	Handle hDirectory = INVALID_HANDLE;
	FileType type = FileType_Unknown;

	BuildPath(Path_SM, sLogPath, sizeof(sLogPath), LOG_FOLDER);

	if ( DirExists(sLogPath) )
	{
		hDirectory = OpenDirectory(sLogPath);
		if (hDirectory != INVALID_HANDLE)
		{
			int iTimeOffset = GetTime() - ((SECONDS_IN_DAY * hCvarLogDays.IntValue) + 30);
			while ( ReadDirEntry(hDirectory, buffer, sizeof(buffer), type) )
			{
				if (type == FileType_File)
				{
					if (StrContains(buffer, LOG_PREFIX, false) != -1)
					{
						char file[PLATFORM_MAX_PATH];
						Format(file, sizeof(file), "%s/%s", sLogPath, buffer);

						if ( GetFileTime(file, FileTime_LastChange) < iTimeOffset ) // Log file is old
							if (DeleteFile(file))
								LogAction(0, -1, "[AFK Manager] Deleted Old Log File: %s", file);
					}
				}
			}
		}
	}

	if (hDirectory != INVALID_HANDLE)
	{
		CloseHandle(hDirectory);
		hDirectory = INVALID_HANDLE;
	}
}

// Chat Functions
void AFK_PrintToChat(int client, const char[] sMessage, any:...)
{
	int iStart = client;
	int iEnd = MaxClients;

	if (client > 0)
		iEnd = client;
	else
		iStart = 1;

	char sBuffer[MAX_MESSAGE_LENGTH];

	for (int i = iStart; i <= iEnd; i++)
	{
		if (IsClientInGame(i))
		{
			SetGlobalTransTarget(i);
			VFormat(sBuffer, sizeof(sBuffer), sMessage, 3);
#if defined _colors_included
			if (g_bPrefixColors)
				CPrintToChat(i, "{olive}[{green}%s{olive}] {default}%s", g_sPrefix, sBuffer);
			else
				PrintToChat(i, "[%s] %s", g_sPrefix, sBuffer);
#else
			PrintToChat(i, "[%s] %s", g_sPrefix, sBuffer);
#endif
		}
	}
}


// General Functions
char ActionToString(Action action)
{
	char Action_Name[32];
	switch (action)
	{
		case Plugin_Continue:
			Action_Name = "Plugin_Continue";
		case Plugin_Changed:
			Action_Name = "Plugin_Changed";
		case Plugin_Handled:
			Action_Name = "Plugin_Handled";
		case Plugin_Stop:
			Action_Name = "Plugin_Stop";
		default:
			Action_Name = "Plugin_Error";
	}
	return Action_Name;
}

void ResetAttacker(int index)
{
	iPlayerAttacker[index] = -1;
}

void ResetSpawn(int index)
{
	g_iSpawnTime[index] =	-1;
}

void ResetObserver(int index)
{
	iObserverMode[index] = -1;
	iObserverTarget[index] = -1;
}

void ResetPlayer(int index, bool FullReset = true) // Player Resetting
{
	ResetSpawn(index);
	bPlayerAFK[index] = true;

	if (FullReset)
	{
		g_iAFKTime[index] = -1;
		g_iPlayerTeam[index] = -1;
		ResetAttacker(index);
		ResetObserver(index);
	}
	else
		g_iAFKTime[index] = GetTime();
}

void SetClientAFK(int client, bool Reset = true)
{
	if (Reset)
		ResetPlayer(client, false);
	else
		bPlayerAFK[client] = true;

	Forward_OnClientAFK(client);
}

void InitializePlayer(int index) // Player Initialization
{
	if (IsValidClient(index))
	{
		if (g_hAFKTimer[index] != INVALID_HANDLE) // Check Timers and Destroy Them?
		{
			CloseHandle(g_hAFKTimer[index]);
			g_hAFKTimer[index] = INVALID_HANDLE;
		}

		// Check Admin immunity
		bool FullImmunity = false;

		if (hCvarAdminsImmune.IntValue == 1)
			if (CheckAdminImmunity(index))
				FullImmunity = true;
		if (!FullImmunity)
		{
			g_iAFKTime[index] = GetTime();

			g_iPlayerTeam[index] = GetClientTeam(index);
			g_hAFKTimer[index] = CreateTimer(AFK_CHECK_INTERVAL, Timer_CheckPlayer, index, TIMER_REPEAT); // Create AFK Timer
		}
	}
}

void UnInitializePlayer(int index) // Player UnInitialization
{
	if (g_hAFKTimer[index] != INVALID_HANDLE) // Check for timers and destroy them?
	{
		CloseHandle(g_hAFKTimer[index]);
		g_hAFKTimer[index] = INVALID_HANDLE;
	}
	ResetPlayer(index);
}

int AFK_GetClientCount(bool inGameOnly = true)
{
	int clients = 0;
	for (int i = 1; i <= GetMaxClients(); i++)	
		if( ( ( inGameOnly ) ? IsClientInGame(i) : IsClientConnected(i) ) && !IsClientSourceTV(i) && !IsFakeClient(i) )
			clients++;
	return clients;
}

void CheckMinPlayers()
{
	int MoveMinPlayers = hCvarMinPlayersMove.IntValue;
	int KickMinPlayers = hCvarMinPlayersKick.IntValue;

	int players = AFK_GetClientCount();

	if (players >= MoveMinPlayers)
	{
		if (!bMovePlayers)
			if (g_bLogWarnings)
				LogToFile(AFKM_LogFile, "Player count for AFK Move minimum has been reached, feature is now enabled: sm_afk_move_min_players = %i Current Players = %i", MoveMinPlayers, players);
		bMovePlayers = true;
	}
	else
	{
		if (bMovePlayers)
			if (g_bLogWarnings)
				LogToFile(AFKM_LogFile, "Player count for AFK Move minimum is below requirements, feature is now disabled: sm_afk_move_min_players = %i Current Players = %i", MoveMinPlayers, players);
		bMovePlayers = false;
	}

	if (players >= KickMinPlayers)
	{
		if (!bKickPlayers)
			if (g_bLogWarnings)
				LogToFile(AFKM_LogFile, "Player count for AFK Kick minimum has been reached, feature is now enabled: sm_afk_kick_min_players = %i Current Players = %i", KickMinPlayers, players);
		bKickPlayers = true;
	}
	else
	{
		if (bKickPlayers)
			if (g_bLogWarnings)
				LogToFile(AFKM_LogFile, "Player count for AFK Kick minimum is below requirements, feature is now disabled: sm_afk_kick_min_players = %i Current Players = %i", KickMinPlayers, players);
		bKickPlayers = false;
	}
}

// Cvar Hooks
public void CvarChange_Status(ConVar cvar, const char[] oldvalue, const char[] newvalue) // Hook ConVar Status
{
	if (!StrEqual(oldvalue, newvalue))
	{
		if (cvar == hCvarTimeToMove)
			g_iTimeToMove = StringToInt(newvalue);
		else if (cvar == hCvarTimeToKick)
			g_iTimeToKick = StringToInt(newvalue);
		else if (StringToInt(newvalue) == 1)
		{
			if (cvar == hCvarEnabled)
				EnablePlugin();
			else if (cvar == hCvarLogWarnings)
				g_bLogWarnings = true;
			else if (cvar == hCvarPrefixShort)
				g_sPrefix = "AFK";
			else if (cvar == hCvarExcludeDead)
				g_bExcludeDead = true;
#if defined _colors_included
			else if (cvar == hCvarPrefixColor)
				g_bPrefixColors = true;
#endif
		}
		else if (StringToInt(newvalue) == 0)
		{
			if (cvar == hCvarEnabled)
				DisablePlugin();
			else if (cvar == hCvarLogWarnings)
				g_bLogWarnings = false;
			else if (cvar == hCvarPrefixShort)
				g_sPrefix = "AFK Manager";
			else if (cvar == hCvarExcludeDead)
				g_bExcludeDead = false;
#if defined _colors_included
			else if (cvar == hCvarPrefixColor)
				g_bPrefixColors = false;
#endif
		}
	}
}

void HookEvents() // Event Hook Registrations
{
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeathPost, EventHookMode_Post);
	
	//Add hooks for Nuclear Dawn
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("structure_death", Event_StructDeath);
}

void HookConVars() // ConVar Hook Registrations
{
	if (!bCvarIsHooked[CONVAR_ENABLED])
	{
		hCvarEnabled.AddChangeHook(CvarChange_Status); // Hook Enabled Variable
		bCvarIsHooked[CONVAR_ENABLED] = true;
	}
	
	if (!bCvarIsHooked[CONVAR_PREFIXSHORT])
	{
		hCvarPrefixShort.AddChangeHook(CvarChange_Status); // Hook Short Prefix Variable
		bCvarIsHooked[CONVAR_PREFIXSHORT] = true;

		if (hCvarPrefixShort.BoolValue)
			g_sPrefix = "AFK";
	}
#if defined _colors_included
	if (!bCvarIsHooked[CONVAR_PREFIXCOLORS])
	{
		hCvarPrefixColor.AddChangeHook(CvarChange_Status); // Hook Color Prefix Variable
		bCvarIsHooked[CONVAR_PREFIXCOLORS] = true;

		if (hCvarPrefixColor.BoolValue)
			g_bPrefixColors = true;
	}
#endif
	if (!bCvarIsHooked[CONVAR_LOG_WARNINGS])
	{
		hCvarLogWarnings.AddChangeHook(CvarChange_Status); // Hook Warnings Variable
		bCvarIsHooked[CONVAR_LOG_WARNINGS] = true;

		if (hCvarLogWarnings.BoolValue)
			g_bLogWarnings = true;
	}
	if (!bCvarIsHooked[CONVAR_TIMETOMOVE])
	{
		hCvarTimeToMove.AddChangeHook(CvarChange_Status); // Hook TimeToMove Variable
		bCvarIsHooked[CONVAR_TIMETOMOVE] = true;

		g_iTimeToMove = hCvarTimeToMove.IntValue;
	}
	if (!bCvarIsHooked[CONVAR_TIMETOKICK])
	{
		hCvarTimeToKick.AddChangeHook(CvarChange_Status); // Hook TimeToKick Variable
		bCvarIsHooked[CONVAR_TIMETOKICK] = true;

		g_iTimeToKick = hCvarTimeToKick.IntValue;
	}
	if (!bCvarIsHooked[CONVAR_EXCLUDEDEAD])
	{
		hCvarExcludeDead.AddChangeHook(CvarChange_Status); // Hook Exclude Dead Variable
		bCvarIsHooked[CONVAR_EXCLUDEDEAD] = true;

		if (hCvarExcludeDead.BoolValue)
			g_bExcludeDead = true;
	}
}

void RegisterCvars() // Cvar Registrations
{
	hCvarEnabled = CreateConVar("sm_afk_enable", "1", "Is the AFK Manager enabled or disabled? [0 = FALSE, 1 = TRUE, DEFAULT: 1]", FCVAR_NONE, true, 0.0, true, 1.0);
	hCvarPrefixShort = CreateConVar("sm_afk_prefix_short", "0", "Should the AFK Manager use a short prefix? [0 = FALSE, 1 = TRUE, DEFAULT: 0]", FCVAR_NONE, true, 0.0, true, 1.0);
#if defined _colors_included
	hCvarPrefixColor = CreateConVar("sm_afk_prefix_color", "1", "Should the AFK Manager use color for the prefix tag? [0 = DISABLED, 1 = ENABLED, DEFAULT: 1]", FCVAR_NONE, true, 0.0, true, 1.0);
#endif
	hCvarLogWarnings = CreateConVar("sm_afk_log_warnings", "1", "Should the AFK Manager log plugin warning messages. [0 = FALSE, 1 = TRUE, DEFAULT: 1]", FCVAR_NONE, true, 0.0, true, 1.0);
	hCvarLogMoves = CreateConVar("sm_afk_log_moves", "1", "Should the AFK Manager log client moves. [0 = FALSE, 1 = TRUE, DEFAULT: 1]", FCVAR_NONE, true, 0.0, true, 1.0);
	hCvarLogKicks = CreateConVar("sm_afk_log_kicks", "1", "Should the AFK Manager log client kicks. [0 = FALSE, 1 = TRUE, DEFAULT: 1]", FCVAR_NONE, true, 0.0, true, 1.0);
	hCvarLogDays = CreateConVar("sm_afk_log_days", "0", "How many days should we keep AFK Manager log files. [0 = INFINITE, DEFAULT: 0]");
	hCvarMinPlayersMove = CreateConVar("sm_afk_move_min_players", "4", "Minimum number of connected clients required for AFK move to be enabled. [DEFAULT: 4]");
	hCvarMinPlayersKick = CreateConVar("sm_afk_kick_min_players", "6", "Minimum number of connected clients required for AFK kick to be enabled. [DEFAULT: 6]");
	hCvarAdminsImmune = CreateConVar("sm_afk_admins_immune", "1", "Should admins be immune to the AFK Manager? [0 = DISABLED, 1 = COMPLETE IMMUNITY, 2 = KICK IMMUNITY, 3 = MOVE IMMUNITY]");
	hCvarAdminsFlag = CreateConVar("sm_afk_admins_flag", "", "Admin Flag for immunity? Leave Blank for any flag.");
	hCvarMoveSpec = CreateConVar("sm_afk_move_spec", "1", "Should the AFK Manager move AFK clients to spectator team? [0 = FALSE, 1 = TRUE, DEFAULT: 1]", FCVAR_NONE, true, 0.0, true, 1.0);
	hCvarTimeToMove = CreateConVar("sm_afk_move_time", "60.0", "Time in seconds (total) client must be AFK before being moved to spectator. [0 = DISABLED, DEFAULT: 60.0 seconds]");
	hCvarWarnTimeToMove = CreateConVar("sm_afk_move_warn_time", "30.0", "Time in seconds remaining, player should be warned before being moved for AFK. [DEFAULT: 30.0 seconds]");
	hCvarKickPlayers = CreateConVar("sm_afk_kick_players", "1", "Should the AFK Manager kick AFK clients? [0 = DISABLED, 1 = KICK ALL, 2 = ALL EXCEPT SPECTATORS, 3 = SPECTATORS ONLY]");
	hCvarTimeToKick = CreateConVar("sm_afk_kick_time", "120.0", "Time in seconds (total) client must be AFK before being kicked. [0 = DISABLED, DEFAULT: 120.0 seconds]");
	hCvarWarnTimeToKick = CreateConVar("sm_afk_kick_warn_time", "30.0", "Time in seconds remaining, player should be warned before being kicked for AFK. [DEFAULT: 30.0 seconds]");
	hCvarSpawnTime = CreateConVar("sm_afk_spawn_time", "20.0", "Time in seconds (total) that player should have moved from their spawn position. [0 = DISABLED, DEFAULT: 20.0 seconds]");
	hCvarWarnSpawnTime = CreateConVar("sm_afk_spawn_warn_time", "15.0", "Time in seconds remaining, player should be warned for being AFK in spawn. [DEFAULT: 15.0 seconds]");
	hCvarExcludeDead = CreateConVar("sm_afk_exclude_dead", "0", "Should the AFK Manager exclude checking dead players? [0 = FALSE, 1 = TRUE, DEFAULT: 0]", FCVAR_NONE, true, 0.0, true, 1.0);
}

void EnablePlugin() // Enable Plugin Function
{
	g_bEnabled = true;

	for(int i = 1; i <= MaxClients; i++) // Reset timers for all players
		InitializePlayer(i);

	CheckMinPlayers(); // Check we have enough minimum players
}

void DisablePlugin() // Disable Plugin Function
{
	g_bEnabled = false;

	for(int i = 1; i <= MaxClients; i++) // Stop timers for all players
		UnInitializePlayer(i);
}

// SourceMod Events
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	API_Init(); // Initialize API
	RegPluginLibrary("afkmanager"); // Register Plugin
#if defined _colors_included
    MarkNativeAsOptional("GetUserMessageType");
#endif
	MarkNativeAsOptional("GetEngineVersion");
	return APLRes_Success;
}

public void OnPluginStart() // AFK Manager Plugin has started
{
	BuildLogFilePath();

	LoadTranslations("common.phrases");
	LoadTranslations("afk_manager.phrases");

	RegisterCvars(); // Register Cvars
	SetConVarInt(hCvarLogWarnings, 0);
	SetConVarInt(hCvarEnabled, 0);

	HookConVars(); // Hook ConVars
	HookEvents(); // Hook Events

	AutoExecConfig(true, "afk_manager");

	if (hCvarLogDays != INVALID_HANDLE)
		if (hCvarLogDays.IntValue > 0)
			PurgeOldLogs(); // Purge Old Log Files

	if (ND_RoundStarted()) // Account for Late Loading
		g_bWaitRound = false;
		
	AddUpdaterLibrary(); //auto-updater
}

public void OnMapStart()
{
	BuildLogFilePath();

	if (hCvarLogDays != INVALID_HANDLE)
		if (hCvarLogDays.IntValue > 0)
			PurgeOldLogs(); // Purge Old Log Files

	AutoExecConfig(true, "afk_manager"); // Execute Config
}

public void OnClientPutInServer(int client) // Client has joined server
{
	if (g_bEnabled)
	{
		InitializePlayer(client);

		CheckMinPlayers(); // Increment Player Count
	}
}

public void OnClientDisconnect_Post(int client) // Client has left server
{
	if (g_bEnabled)
	{
		UnInitializePlayer(client); // UnInitializePlayer since they are leaving the server.

		CheckMinPlayers();
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (g_bEnabled)
	{
		if (IsClientSourceTV(client) || IsFakeClient(client)) // Ignore Source TV & Bots
			return Plugin_Continue;

		if (cmdnum <= 0) // NULL Commands?
			return Plugin_Handled;

		if (g_hAFKTimer[client] != INVALID_HANDLE)
		{
			//if ((iButtons[client] != buttons) || ( (iMouse[client][0] != mouse[0]) || (iMouse[client][1] != mouse[1]) ))
			if ( (iButtons[client] != buttons) || ( (angles[0] != fEyeAngles[client][0]) || (angles[1] != fEyeAngles[client][1]) || (angles[2] != fEyeAngles[client][2]) ) )
			{
				if (IsClientObserver(client))
				{
					if (iObserverMode[client] == -1) // Player has an Invalid Observer Mode
					{
						iButtons[client] = buttons;
						fEyeAngles[client] = angles;
						return Plugin_Continue;
					}
					else if (iObserverMode[client] != 4) // Check Observer Mode in case it has changed
						iObserverMode[client] = GetEntProp(client, Prop_Send, "m_iObserverMode");

					if ((iObserverMode[client] == 4) && (iButtons[client] == buttons))
					{
						fEyeAngles[client] = angles;
						return Plugin_Continue;
					}

					if ( (iButtons[client] == buttons) && ( (FloatAbs(FloatSub(angles[0],fEyeAngles[client][0])) < 2.0) && (FloatAbs(FloatSub(angles[1],fEyeAngles[client][1])) < 2.0) && (FloatAbs(FloatSub(angles[2],fEyeAngles[client][2])) < 2.0) ) )
					{
						fEyeAngles[client] = angles;
						return Plugin_Continue;
					}
				}

				iButtons[client] = buttons;
				fEyeAngles[client] = angles;
				//iMouse[client] = mouse;
				if (bPlayerDeath[client])
					bPlayerDeath[client] = false;
				else
					if (bPlayerAFK[client])
					{
						Forward_OnClientBack(client);
						bPlayerAFK[client] = false;
					}
				//ResetPlayer(client, false);
			}
		}
	}
	return Plugin_Continue;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs) // Player Chat
{
	if (g_bEnabled)
		if (g_hAFKTimer[client] != INVALID_HANDLE)
			ResetPlayer(client, false); // Reset timer once player has said something in chat.
	return Plugin_Continue;
}


// Game Events
public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bEnabled)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));

		if (client > 0) // Check the client is not console/world?
			if (IsValidClient(client))
			{
				if (g_hAFKTimer[client] != INVALID_HANDLE)
				{
					g_iPlayerTeam[client] = event.GetInt("team");

					if (g_iPlayerTeam[client] != g_iSpec_Team)
					{
						ResetObserver(client);
						ResetPlayer(client, false);
					}
				}
			}
	}
	return Plugin_Continue;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bEnabled)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));

		if (client > 0) // Check the client is not console/world?
			if (IsValidClient(client)) // Check client is not a bot or otherwise fake player.
			{
				if (g_hAFKTimer[client] != INVALID_HANDLE)
				{
					if (g_iPlayerTeam[client] == 0) // Unassigned Team? Fires in CSTRIKE?
						return Plugin_Continue;

					if (!IsClientObserver(client)) // Client is not an Observer/Spectator?
						if (IsPlayerAlive(client)) // Fix for Valve causing Unassigned to not be detected as an Observer in CSS?
							if (GetClientHealth(client) > 0) // Fix for Valve causing Unassigned to be alive?
							{
								ResetAttacker(client);
								ResetObserver(client);

								if (hCvarSpawnTime.FloatValue > 0.0) // Check if Spawn AFK is enabled.
								{
									g_iSpawnTime[client] = GetTime();
								}
							}
				}
			}
	}
	return Plugin_Continue;
}

public Action Event_PlayerDeathPost(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bEnabled)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));

		if (client > 0) // Check the client is not console/world?
			if (IsValidClient(client)) // Check client is not a bot or otherwise fake player.
			{
				if (g_hAFKTimer[client] != INVALID_HANDLE)
				{
					iPlayerAttacker[client] = GetClientOfUserId(event.GetInt("attacker"));

					GetClientEyeAngles(client, fEyeAngles[client]);
					ResetSpawn(client);
					bPlayerDeath[client] = true;

					if (IsClientObserver(client))
					{
						iObserverMode[client] = GetEntProp(client, Prop_Send, "m_iObserverMode");
						iObserverTarget[client] = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
					}
				}
			}
	}
	return Plugin_Continue;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bWaitRound = false; // Un-Pause Plugin on Map Start
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bWaitRound = true; // Pause Plugin During Map Transitions?
}

//Look for if a team has any transport gates left, if not pause the plugin
public Action Event_StructDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (event.GetInt("type") == ND_TRANSPORT_GATE)
	{
		int 	client = GetClientOfUserId(event.GetInt("attacker")),	
			team = getOtherTeam(GetClientTeam(client));
		
		if (ND_HasNoTransportGates(team))
			g_bWaitRound = true; // Pause Plugin When all Transport Gates Die
	}
}

bool ND_HasNoTransportGates(team)
{
	// loop through all entities finding transport gates
	new loopEntity = INVALID_ENT_REFERENCE;
	while ((loopEntity = FindEntityByClassname(loopEntity, ND_TRANSPORT_NAME)) != INVALID_ENT_REFERENCE)
	{
		if (GetEntProp(loopEntity, Prop_Send, "m_iTeamNum") == team) //if the owner equals the team arg
		{
			return false;	
		}	
	}
	
	return true;
}

// Timers
public Action Timer_CheckPlayer(Handle Timer, int client) // General AFK Timers
{
	if(g_bEnabled) // Is the AFK Manager Enabled
	{
		if (GetEntityFlags(client) & FL_FROZEN) // Ignore FROZEN Clients
		{
			g_iAFKTime[client]++;
			return Plugin_Continue;
		}

		if (IsClientObserver(client))
		{
			int m_iObserverMode = GetEntProp(client, Prop_Send, "m_iObserverMode");

			if (iObserverMode[client] == -1) // Invalid Observer Mode
			{
				iObserverMode[client] = m_iObserverMode;
				GetClientEyeAngles(client, fEyeAngles[client]);
				g_iAFKTime[client]++;
				return Plugin_Continue;
			}
			else if (iObserverMode[client] != m_iObserverMode) // Player changed Observer Mode
			{
				iObserverMode[client] = m_iObserverMode;

				if (iObserverMode[client] != g_iSpec_FLMode)
				{
					int m_hObserverTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");

					if ((iObserverTarget[client] == client) || (iObserverTarget[client] == iPlayerAttacker[client])) // Death Cam?
					{
						iObserverTarget[client] = m_hObserverTarget;
						return Plugin_Continue;
					}
					
					iObserverTarget[client] = m_hObserverTarget;
				}
				
				SetClientAFK(client);
				return Plugin_Continue;
			}
			else if (iObserverMode[client] != g_iSpec_FLMode)
			{
				int m_hObserverTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");

				if (iObserverTarget[client] != m_hObserverTarget) // Player changed Observer Mode
				{
					// if the previous target is invalid, themselve or has died
					if (!IsValidClient(iObserverTarget[client], false) ||  iObserverTarget[client] == client || !IsPlayerAlive(iObserverTarget[client]))
						iObserverTarget[client] = m_hObserverTarget;
					else
					{
						iObserverTarget[client] = m_hObserverTarget;
						SetClientAFK(client);
						return Plugin_Continue;
					}
				}
			}
		}
		

		int Time = GetTime();
		if (!bPlayerAFK[client]) // Player Marked as not AFK?
		{
			bool playerHasSpawned = g_iSpawnTime[client] > 0 && (Time - g_iSpawnTime[client]) < 2;
			bool isDeathCam = !IsPlayerAlive(client) && iObserverTarget[client] == client;
			
			//if the player has spawned or is a death cam they're not afk; otherwise they are afk.
			SetClientAFK(client, !(playerHasSpawned || isDeathCam));
			return Plugin_Continue;
		}

		if (SkipAfkCheck(client))
		{
			g_iAFKTime[client]++;
			return Plugin_Continue;
		}

		int AdminsImmune = hCvarAdminsImmune.IntValue;

		int AFKSpawnTimeleft = -1;
		int AFKSpawnTime, cvarSpawnTime;

		if ((g_iSpawnTime[client] > 0) && (!IsPlayerAlive(client))) // Check Spawn Time and Player Alive
			ResetSpawn(client);

		if (g_iSpawnTime[client] > 0)
		{
			cvarSpawnTime = hCvarSpawnTime.IntValue;

			if (cvarSpawnTime > 0)
			{
				AFKSpawnTime = Time - g_iSpawnTime[client];
				AFKSpawnTimeleft = cvarSpawnTime - AFKSpawnTime;
			}
		}

		int AFKTime = g_iAFKTime[client] >= 0 ? Time - g_iAFKTime[client] : 0;
		if (g_iPlayerTeam[client] != g_iSpec_Team) // Check we are not on the Spectator team
		{
			if (hCvarMoveSpec.BoolValue)
			{
				if (bMovePlayers == true)
				{
					if ( (AdminsImmune == 0) || (AdminsImmune == 2) || (!CheckAdminImmunity(client)) ) // Check Admin Immunity
					{
						if (g_iTimeToMove > 0)
						{
							int AFKMoveTimeleft = g_iTimeToMove - AFKTime;

							if (AFKMoveTimeleft >= 0)
							{
								if (AFKSpawnTimeleft >= 0)
									if (AFKSpawnTimeleft < AFKMoveTimeleft) // Spawn time left is less than total AFK time left
									{
										if (AFKSpawnTime >= cvarSpawnTime) // Take Action on AFK Spawn Player
										{
											ResetSpawn(client);
											return MoveAFKClient(client);
										}
										else if (AFKSpawnTime%AFK_WARNING_INTERVAL == 0) // Warn AFK Spawn Player
										{
											if ((cvarSpawnTime - AFKSpawnTime) <= hCvarWarnSpawnTime.IntValue)
												AFK_PrintToChat(client, "%t", "Spawn_Move_Warning", AFKSpawnTimeleft);
										}
										return Plugin_Continue;
									}

								if (AFKTime >= g_iTimeToMove) // Take Action on AFK Player
									return MoveAFKClient(client);

								else if (AFKTime%AFK_WARNING_INTERVAL == 0) // Warn AFK Player
								{
									if ((g_iTimeToMove - AFKTime) <= hCvarWarnTimeToMove.IntValue)
										AFK_PrintToChat(client, "%t", "Move_Warning", AFKMoveTimeleft);
									return Plugin_Continue;
								}
								return Plugin_Continue; // Fix for AFK Spawn Kick Notifications
							}
						}
					}
				}
			}
		}

		int KickPlayers = hCvarKickPlayers.IntValue;
		
		if (KickPlayers > 0)
			if (bKickPlayers == true)
			{
				if ((KickPlayers == 2) && (g_iPlayerTeam[client] == g_iSpec_Team)) // Kicking is set to exclude spectators. Player is on the spectator team. Spectators should not be kicked.
					return Plugin_Continue;
				else
				{
					if ( (AdminsImmune == 0) || (AdminsImmune == 3) || (!CheckAdminImmunity(client)) ) // Check Admin Immunity
					{
						if (g_iTimeToKick > 0)
						{
							int AFKKickTimeleft = g_iTimeToKick - AFKTime;

							if (AFKKickTimeleft >= 0)
							{
								if (AFKSpawnTimeleft >= 0)
									if (AFKSpawnTimeleft < AFKKickTimeleft) // Spawn time left is less than total AFK time left
									{
										if (AFKSpawnTime >= cvarSpawnTime) // Take Action on AFK Spawn Player
											return KickAFKClient(client);
										else if (AFKSpawnTime%AFK_WARNING_INTERVAL == 0) // Warn AFK Spawn Player
										{
											if ((cvarSpawnTime - AFKSpawnTime) <= hCvarWarnSpawnTime.IntValue)
												AFK_PrintToChat(client, "%t", "Spawn_Kick_Warning", AFKSpawnTimeleft);
											return Plugin_Continue;
										}
									}

								if (AFKTime >= g_iTimeToKick) // Take Action on AFK Player
									return KickAFKClient(client);
								else if (AFKTime%AFK_WARNING_INTERVAL == 0) // Warn AFK Player
								{
									if ((g_iTimeToKick - AFKTime) <= hCvarWarnTimeToKick.IntValue)
										AFK_PrintToChat(client, "%t", "Kick_Warning", AFKKickTimeleft);
									return Plugin_Continue;
								}
							}
							else
								return KickAFKClient(client);
						}
					}
				}
			}
	}

	//g_hAFKTimer[client] = INVALID_HANDLE;
	return Plugin_Continue;
}
// Helper Function for above
bool SkipAfkCheck(int client)
{
	// Make sure player is on a team and not dead
	if ((g_iPlayerTeam[client] != 0) && (g_iPlayerTeam[client] != g_iSpec_Team))
		return !IsPlayerAlive(client) && (g_bExcludeDead);
		
	// Are we waiting for the round to start
	// Do we have enough players to start taking action
	return g_bWaitRound || ((bMovePlayers == false) && (bKickPlayers == false));
}

// Move/Kick Functions
Action MoveAFKClient(int client) // Move AFK Client to Spectator Team
{
	Action ForwardResult = Plugin_Continue;

	ForwardResult = g_iSpawnTime[client] != -1 	? Forward_OnAFKEvent("afk_spawn_move", client) 
						  	: Forward_OnAFKEvent("afk_move", client);

	if (ForwardResult != Plugin_Continue)
	{
		if (g_bLogWarnings)
		{
			char Action_Name[32];
			Action_Name = ActionToString(ForwardResult);
			LogToFile(AFKM_LogFile, "AFK Manager Event: MoveAFKClient has been requested to: %s by an external plugin this action will affect the event outcome.", Action_Name);
		}
		return ForwardResult;
	}

	char f_Name[MAX_NAME_LENGTH];
	GetClientName(client, f_Name, sizeof(f_Name));

	if (hCvarLogMoves.BoolValue)
		LogToFile(AFKM_LogFile, "%T", "Move_Log", LANG_SERVER, client);

	ChangeClientTeam(client, g_iSpec_Team); // Move AFK Player to Spectator

	return Plugin_Continue; // Check This?
}

Action KickAFKClient(int client) // Kick AFK Client
{
	Action ForwardResult = Forward_OnAFKEvent("afk_kick", client);

	if (ForwardResult != Plugin_Continue)
	{
		if (g_bLogWarnings)
		{
			char Action_Name[32];
			Action_Name = ActionToString(ForwardResult);
			LogToFile(AFKM_LogFile, "AFK Manager Event: KickAFKClient has been requested to: %s by an external plugin this action will affect the event outcome.", Action_Name);
		}
		return ForwardResult;
	}

	char f_Name[MAX_NAME_LENGTH];
	GetClientName(client, f_Name, sizeof(f_Name));

	if (hCvarLogKicks.BoolValue)
		LogToFile(AFKM_LogFile, "%T", "Kick_Log", LANG_SERVER, client);

	KickClient(client, "[%s] %t", g_sPrefix, "Kick_Message");
	return Plugin_Continue;
}

bool CheckAdminImmunity(int client) // Check Admin Immunity
{
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));

	AdminId admin = GetUserAdmin(client);

	if(admin != INVALID_ADMIN_ID) // Check if player is an admin
	{
		char flags[8];
		AdminFlag flag;

		hCvarAdminsFlag.GetString(flags, sizeof(flags));
		
		// Are we checking for specific admin flags?
		// If so, Is the admin flag valid with the correct immunity?
		return StrEqual(flags, "", false) || (FindFlagByChar(flags[0], flag) && GetAdminFlag(admin, flag));
	}
	return false;
}
