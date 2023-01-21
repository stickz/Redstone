Handle SaveTeamsTimer;
bool SavingTeams;
Handle DatabaseHandle;

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
        return;
    }

    SQL_TConnect(OnDatabaseConnected, "discord");

    HookEvent("player_team", Event_PlayerTeam);
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    SaveTeams();
    return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
    SaveTeams();
}

public void OnClientDisconnect_Post(int client)
{
    SaveTeams();
}

public OnDatabaseConnected(Handle owner, Handle handle, const char[] error, any:data)
{
    if (!IsValidHandle(handle))
    {
        SetFailState("Unable to connect to \"discord\" database: %s", error);
        return;
    }

    DatabaseHandle = handle;

    char query[1024];
    FormatEx(query, sizeof(query), "SELECT * FROM players;");
    SQL_TQuery(DatabaseHandle, Setup_Step1_CheckTable, query);
}

void Setup_Step1_CheckTable(Handle owner, Handle handle, const char[] error, any:data)
{
    // Create the table if it doesn't exist
    if (error[0] != '\0')
    {
        char query[1024];
        FormatEx(query, sizeof(query), "CREATE TABLE `players` (`id` bigint NOT NULL AUTO_INCREMENT, `name` varchar(128) NOT NULL, `team` varchar(128) NOT NULL, PRIMARY KEY (`id`));");
        SQL_TQuery(DatabaseHandle, Setup_Step2_CreateTable, query);
    }
}

void Setup_Step2_CreateTable(Handle owner, Handle handle, const char[] error, any:data)
{
    if (error[0] != '\0')
    {
        SetFailState("Unable to create \"players\" table in \"discord\" database: %s", error);
    }
}

void SaveTeams()
{
    delete SaveTeamsTimer;
    SaveTeamsTimer = CreateTimer(1.0, Timer_SaveTeams);
}

public Action Timer_SaveTeams(Handle timer)
{
    if(SavingTeams) {
        SaveTeamsTimer = CreateTimer(1.0, Timer_SaveTeams);
        return Plugin_Continue;
    }
    SaveTeamsTimer = null;

    if(!IsValidHandle(DatabaseHandle)) {
        LogAction(0, -1, "Database not connected");
        return Plugin_Continue;
    }

    SavingTeams = true;

    char query[1024];
    FormatEx(query, sizeof(query), "TRUNCATE TABLE players;");
    SQL_TQuery(DatabaseHandle, SaveTeams_Step1_RemovePlayers, query);

    return Plugin_Continue;
}

void SaveTeams_Step1_RemovePlayers(Handle owner, Handle handle, const char[] error, any:data)
{
    if (error[0] != '\0')
    {
        LogAction(0, -1, "Removing players failed: %s", error);
        SavingTeams = false;
        return;
    }

    int[] consortium = new int[MaxClients];
    int numConsortium = 0;
    int[] empire = new int[MaxClients];
    int numEmpire = 0;
    int[] spectator = new int[MaxClients];
    int numSpectator = 0;
    for (int client = 1; client <= GetClientCount(); client++)
    {
        if (IsClientConnected(client))
        {
            if (GetClientTeam(client) == 2)
            {
                consortium[numConsortium] = client;
                numConsortium++;
            }
            else if(GetClientTeam(client) == 3)
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

    char query[10000];
    char queryvalues[10000];
    char[][] queryparts = new char[numConsortium + numEmpire + numSpectator][1024];
    int part = 0;
    char name[MAX_NAME_LENGTH];
    char escapedName[MAX_NAME_LENGTH];

    for (int player = 0; player < numConsortium; player++)
    {
        GetClientName(consortium[player], name, sizeof(name));
        SQL_EscapeString(DatabaseHandle, name, escapedName, sizeof(escapedName));
        FormatEx(queryparts[part++], 1024, "('%s', '%s')", escapedName, "consortium");
    }

    for (int player = 0; player < numEmpire; player++)
    {
        GetClientName(empire[player], name, sizeof(name));
        SQL_EscapeString(DatabaseHandle, name, escapedName, sizeof(escapedName));
        FormatEx(queryparts[part++], 1024, "('%s', '%s')", escapedName, "empire");
    }

    for (int player = 0; player < numSpectator; player++)
    {
        GetClientName(spectator[player], name, sizeof(name));
        SQL_EscapeString(DatabaseHandle, name, escapedName, sizeof(escapedName));
        FormatEx(queryparts[part++], 1024, "('%s', '%s')", escapedName, "spectator");
    }

    ImplodeStrings(queryparts, numConsortium + numEmpire + numSpectator, ", ", queryvalues, sizeof(queryvalues));
    FormatEx(query, sizeof(query), "INSERT INTO players (name, team) VALUES %s;", queryvalues);
    SQL_TQuery(DatabaseHandle, SaveTeams_Step2_AddPlayers, query);
}

void SaveTeams_Step2_AddPlayers(Handle owner, Handle handle, const char[] error, any:data)
{
    if (error[0] != '\0')
    {
        LogAction(0, -1, "Adding players failed: %s", error);
        SavingTeams = false;
        return;
    }

    // Teams saved successfully
    SavingTeams = false;
}
