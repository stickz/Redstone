#define COND_CLOACKED 	(1<<1)
#define COND_LOCKDOWN 	(1<<2)
#define COND_HYPOSPRAY 	(1<<10)
#define NOT_CAPTURING 	-1

int EntIndexCaping[MAXPLAYERS+1] = { NOT_CAPTURING, ... };
int DisplayedPrimeCapMsg[TEAM_COUNT] = { false, ... };

void HookResourceEvents() {
	HookEvent("resource_start_capture", Event_ResourceStartCapture, EventHookMode_Post);
	HookEvent("resource_end_capture", Event_ResourceEndCapture, EventHookMode_Post);
	HookEvent("resource_captured", Event_ResourceCaptured, EventHookMode_Post);	
	HookEvent("resource_break_capture", Event_ResourceBreakCapture, EventHookMode_Post);

	DisplayedPrimeCapMsg[TEAM_EMPIRE] = false;
	DisplayedPrimeCapMsg[TEAM_CONSORT] = false;
}

public Action Event_ResourceStartCapture(Event event, const char[] name, bool dontBroadcast)
{
	int entindex = event.GetInt("entindex");
	int client = GetClientOfUserId(event.GetInt("userid"));
	EntIndexCaping[client] = entindex;
	return Plugin_Continue;
}

public Action Event_ResourceEndCapture(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	//EntIndexCaping[client] = NOT_CAPTURING;
	return Plugin_Continue;
}

public Action Event_ResourceCaptured(Event event, const char[] name, bool dontBroadcast)
{
	int entindex = event.GetInt("entindex");
	
	int type = event.GetInt("type");
	if (type == RESOURCE_PRIME)
	{		
		int team = event.GetInt("team");
		int otherTeam = getOtherTeam(team);
		
		if (otherTeam == TEAM_EMPIRE || otherTeam == TEAM_CONSORT)
			DisplayPrimeCapMsg(otherTeam);
	}
	
	RemoveCaptureStatus(entindex);
	return Plugin_Continue;
}

public Action Event_ResourceBreakCapture(Event event, const char[] name, bool dontBroadcast)
{
	int entindex = event.GetInt("entindex");
	CheckCloackStatus(entindex);
	RemoveCaptureStatus(entindex);
	return Plugin_Continue;
}

void CheckCloackStatus(int entity)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && option_player_tips[client] && EntIndexCaping[client] == entity)
		{
			if (GetEntProp(client, Prop_Send, "m_nPlayerCond") & COND_CLOACKED)
				PrintMessage(client, "Stealth Capture");		

			else if (GetEntProp(client, Prop_Send, "m_nPlayerCond") & COND_LOCKDOWN)
				PrintMessage(client, "Lockdown Capture");
			
			else if (GetEntProp(client, Prop_Send, "m_nPlayerCond") & COND_HYPOSPRAY)
				DisplayMedicHypoMessage(entity);
		}
	}
}

void DisplayMedicHypoMessage(int entity)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && option_player_tips[client] && EntIndexCaping[client] == entity)
		{
			int mainClass = ND_GetMainClass(client);
			int subClass = ND_GetSubClass(client);
			
			if (IsSupportMedic(mainClass, subClass))
				PrintMessage(client, "Hypospray Capture");
		}
	}	
}

void DisplayPrimeCapMsg(int team)
{
	if (!DisplayedPrimeCapMsg[team])
	{
		DisplayedPrimeCapMsg[team] = true;
		
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsValidClient(client) && GetClientTeam(client) == team && option_player_tips[client])
			{
				PrintMessage(client, "Lost Prime");
			}
		}	
	}
}

void RemoveCaptureStatus(int entity)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (EntIndexCaping[client] == entity)
			EntIndexCaping[client] = NOT_CAPTURING;
	}
}
