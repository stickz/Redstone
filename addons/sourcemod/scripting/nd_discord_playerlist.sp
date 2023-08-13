#include <sdktools>
#include <nd_stocks>
#include <nd_team_eng>

#define BOT_PREFIX "[BOT] "

Handle SaveTeamsTimer;
bool SavingTeams;
Handle DatabaseHandle;
char PlayerNames[MAXPLAYERS + 1][MAX_NAME_LENGTH];

/* Auto Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_discord_playerlist/nd_discord_playerlist.txt"
#include "updater/standard.sp"

public Plugin myinfo =
{
    name        = "[ND] Discord Player List",
    author      = "zookatron",
    description = "Provides player list information to Discord",
    version     = "dummy",
    url         = "https://github.com/stickz/Redstone/"
};

public void OnPluginStart()
{
    if (!SQL_CheckConfig("discord"))
    {
        SetFailState("Could not find configuration for \"discord\" database");
    }

    SQL_TConnect(OnDatabaseConnected, "discord");
    AddUpdaterLibrary(); // Add auto updater feature
    RefreshPlayerNames(); // Load player names
}

void RefreshPlayerNames()
{
    char clientName[MAX_NAME_LENGTH];
    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsValidClient(client, false))
        {
            GetClientName(client, clientName, MAX_NAME_LENGTH);
            FormatEx(PlayerNames[client], MAX_NAME_LENGTH, "%s%s", (IsFakeClient(client) ? BOT_PREFIX : ""), clientName);
        }
    }
}

public void ND_OnPlayerTeamChanged(int client, bool valid)
{
    SaveTeams();
}

public void OnClientPutInServer(int client)
{
    char clientName[MAX_NAME_LENGTH];
    GetClientName(client, clientName, MAX_NAME_LENGTH);
    FormatEx(PlayerNames[client], MAX_NAME_LENGTH, "%s%s", (IsFakeClient(client) ? BOT_PREFIX : ""), clientName);

    SaveTeams();
}

public void OnClientDisconnect_Post(int client)
{
    PlayerNames[client][0] = '\0';
    SaveTeams();
}

public OnDatabaseConnected(Handle owner, Handle handle, const char[] error, any data)
{
    if (!IsValidHandle(handle))
    {
        SetFailState("Unable to connect to \"discord\" database: %s", error);
    }

    DatabaseHandle = handle;
    SQL_SetCharset(DatabaseHandle, "utf8mb4");

    char query[1024];
    FormatEx(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `players` (`id` bigint NOT NULL AUTO_INCREMENT, `name` varchar(128) NOT NULL, `team` varchar(128) NOT NULL, PRIMARY KEY (`id`))");
    SQL_TQuery(DatabaseHandle, Setup_Step1_CreateTable, query, _, DBPrio_Low);
}

void Setup_Step1_CreateTable(Handle owner, Handle handle, const char[] error, any data)
{
    if (!IsValidHandle(handle))
    {
        SetFailState("Unable to create \"players\" table in \"discord\" database: %s", error);
    }
}

void SaveTeams()
{
    if (IsValidHandle(SaveTeamsTimer))
        delete SaveTeamsTimer;

    SaveTeamsTimer = CreateTimer(1.0, Timer_SaveTeams, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_SaveTeams(Handle timer)
{
    if(SavingTeams) {
        SaveTeamsTimer = CreateTimer(1.0, Timer_SaveTeams, _, TIMER_FLAG_NO_MAPCHANGE);
        return Plugin_Continue;
    }
    SaveTeamsTimer = null;

    if(!IsValidHandle(DatabaseHandle)) {
        LogAction(0, -1, "Database not connected");
        return Plugin_Continue;
    }

    SavingTeams = true;

    char query[1024];
    FormatEx(query, sizeof(query), "TRUNCATE TABLE players");
    SQL_TQuery(DatabaseHandle, SaveTeams_Step1_RemovePlayers, query, _, DBPrio_Low);

    return Plugin_Continue;
}

void SaveTeams_Step1_RemovePlayers(Handle owner, Handle handle, const char[] error, any data)
{
    if (!IsValidHandle(handle))
    {
        LogAction(0, -1, "Removing players failed: %s", error);
        SavingTeams = false;
        return;
    }

    int[] consortium = new int[MAXPLAYERS + 1];
    int numConsortium = 0;
    int[] empire = new int[MAXPLAYERS + 1];
    int numEmpire = 0;
    int[] spectator = new int[MAXPLAYERS + 1];
    int numSpectator = 0;
    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsValidClient(client, false))
        {
            int team = GetClientTeam(client);
            if (team == TEAM_CONSORT)
            {
                consortium[numConsortium] = client;
                numConsortium++;
            }
            else if(team == TEAM_EMPIRE)
            {
                empire[numEmpire] = client;
                numEmpire++;
            }
            else
            {
                spectator[numSpectator] = client;
                numSpectator++;
            }
        }
    }

    // We're done if we have no players to add
    if(numConsortium + numEmpire + numSpectator == 0) {
        SavingTeams = false;
        return;
    }

    char query[3072];
    char queryvalues[3072];
    char queryPart[256];
    char escapedName[MAX_NAME_LENGTH * 2 + 1];

    for (int player = 0; player < numConsortium; player++)
    {
        SQL_EscapeString(DatabaseHandle, PlayerNames[consortium[player]], escapedName, sizeof(escapedName));
        FormatEx(queryPart, sizeof(queryPart), ", ('%s', '%s')", escapedName, "consortium");
        StrCat(queryvalues, sizeof(queryvalues), queryPart);
    }

    for (int player = 0; player < numEmpire; player++)
    {
        SQL_EscapeString(DatabaseHandle, PlayerNames[empire[player]], escapedName, sizeof(escapedName));
        FormatEx(queryPart, sizeof(queryPart), ", ('%s', '%s')", escapedName, "empire");
        StrCat(queryvalues, sizeof(queryvalues), queryPart);
    }

    for (int player = 0; player < numSpectator; player++)
    {
        SQL_EscapeString(DatabaseHandle, PlayerNames[spectator[player]], escapedName, sizeof(escapedName));
        FormatEx(queryPart, sizeof(queryPart), ", ('%s', '%s')", escapedName, "spectator");
        StrCat(queryvalues, sizeof(queryvalues), queryPart);
    }

    ReplaceStringEx(queryvalues, sizeof(queryvalues), ", (", "("); // Remove the first comma and space
    FormatEx(query, sizeof(query), "INSERT INTO players (name, team) VALUES %s", queryvalues);
    SQL_TQuery(DatabaseHandle, SaveTeams_Step2_AddPlayers, query, _, DBPrio_Low);
}

void SaveTeams_Step2_AddPlayers(Handle owner, Handle handle, const char[] error, any data)
{
    if (!IsValidHandle(handle))
    {
        LogAction(0, -1, "Adding players failed: %s", error);
        SavingTeams = false;
        return;
    }

    // Teams saved successfully
    SavingTeams = false;
}
