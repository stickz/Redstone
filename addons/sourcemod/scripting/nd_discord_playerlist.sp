ConVar PlayerListFilePath;
Handle SaveTeamsTimer;

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
    PlayerListFilePath = CreateConVar("sm_discord_playerlist_filepath", "", "File path where the player list will be saved");
    AutoExecConfig(true, "discord_playerlist");

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

void SaveTeams()
{
    delete SaveTeamsTimer;
    SaveTeamsTimer = CreateTimer(1.0, Timer_SaveTeams);
}

public Action Timer_SaveTeams(Handle timer)
{
    SaveTeamsTimer = null;
    char FilePath[PLATFORM_MAX_PATH];
    PlayerListFilePath.GetString(FilePath, sizeof(FilePath));
    if(strlen(FilePath) == 0) {
        return Plugin_Continue;
    }

    char FinalFilePath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, FinalFilePath, sizeof(FinalFilePath), FilePath);
    File file = OpenFile(FinalFilePath, "w+");

    if(!IsValidHandle(file)) {
        LogAction(0, -1, "Invalid file path provided: %s", FinalFilePath);
        return Plugin_Continue;
    }

    char name[MAX_NAME_LENGTH];
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

    file.WriteLine("Consortium:");
    for (int player = 0; player < numConsortium; player++)
    {
        GetClientName(consortium[player], name, sizeof(name));
        file.WriteLine("%s", name);
    }

    file.WriteLine("Empire:");
    for (int player = 0; player < numEmpire; player++)
    {
        GetClientName(empire[player], name, sizeof(name));
        file.WriteLine("%s", name);
    }

    file.WriteLine("Spectator:");
    for (int player = 0; player < numSpectator; player++)
    {
        GetClientName(spectator[player], name, sizeof(name));
        file.WriteLine("%s", name);
    }

    file.Close();

    return Plugin_Continue;
}
