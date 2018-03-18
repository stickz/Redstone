#include <nd_fskill>
#define NO_PLAYER_SELECTED -1
//Handle PickingMenu = INVALID_HANDLE;

int cur_team_choosing = TEAM_CONSORT;
int next_comm;

/* Functions for handling the team pick process */
public Handle_PickPlayerMenu(Handle:menu, MenuAction:action, param1, param2) 
{
	if (DebugTeamPicking)
		ConsoleToAdmins("Handle_PickPlayerMenu(): Started", "b");
	
	switch (action)
	{
		// If the action by the team captain was selecting a player.
		case MenuAction_Select:
		{
			if (DebugTeamPicking)
				ConsoleToAdmins("Handle_PickPlayerMenu(): MenuAction_Select", "b");
			
			char selectedItem[32]
			GetMenuItem(menu, param2, selectedItem, sizeof(selectedItem));	
			
			int selectedPlayer = StringToInt(selectedItem);
			int client = GetClientOfUserId(selectedPlayer);				
		
			last_choice[cur_team_choosing - 2] = selectedPlayer;
			
			if (DebugTeamPicking)
			{
				char message[32];
				Format(message, sizeof(message), "the client index is %d", client);
				ConsoleToAdmins(message, "b");
			}

			// If the selected player is valid, do the picking routine
			if (IsValidClient(client, !DebugTeamPicking) && RED_IsValidCIndex(client))
			{			
				SetPickingTeam(); // Decide which team gets the next pick
				
				// If a player was selected (picked) by the team captain
				if (selectedPlayer != NO_PLAYER_SELECTED) 
				{
					// Get their name and display which team they're joining.
					PrintChoosenJoin(client, cur_team_choosing);

					// Set the player's team to the team captain's team.
					ChangeClientTeam(client, cur_team_choosing);
					
					// Send the team picking menu to the next captain
					Menu_PlayerPick(next_comm);
				}
				
				// If the picking is not done, continue displaying the menu to pick players.
				else if (!PickingComplete())
					Menu_PlayerPick(next_comm);
			}
			
			// If selected item was a player, refresh to pick anther option.
			else if (selectedPlayer != NO_PLAYER_SELECTED)
			{
				PrintMessage(client, "Pick Again");
				SetConstantPickingTeam();
				Menu_PlayerPick(next_comm);
			}
			
			// If picking is not done, display menu to opposite team incase a skip was sent
			else if (!PickingComplete())
			{
				SetPickingTeam(); // Decide which team gets the next pick
				Menu_PlayerPick(next_comm);
			}
		}
		
		// If the action by the team captain was canceling their selection.
		case MenuAction_Cancel:
		{
			if (DebugTeamPicking)
				ConsoleToAdmins("Handle_PickPlayerMenu(): MenuAction_Cancel", "b");
			
			// Switch to the other team and set their last choice to canceled
			SetPickingTeam();
			//SwitchPickingTeam();			
			
			if (!lastTimerEnded || noChoiceFound)
				last_choice[cur_team_choosing - 2] = NO_PLAYER_SELECTED;

			// If the picking is not done, continue displaying the menu to pick players.
			if (!PickingComplete())
				CreateTimer(3.0, TIMER_DelayNextPick, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	if (DebugTeamPicking)
		ConsoleToAdmins("Handle_PickPlayerMenu(): Finished", "b");
}

void PrintChoosenJoin(int player, int team)
{
	char name[64];
	GetClientName(player, name, sizeof(name));
	
	char teamName[32];
	Format(teamName, sizeof(teamName), ND_GetTeamName(team));
	
	for (int client = 1; client <= MaxClients; client++) 
	{
		if (IsClientInGame(client))
		{
			PrintToChat(client, "%t", "Choosen Join", name, teamName);
		}
	}
}

public Action TIMER_DelayNextPick(Handle timer)
{
	Menu_PlayerPick(next_comm);
	return Plugin_Handled;
}

public void Menu_PlayerPick(int client)
{	
	if (DebugTeamPicking)
		ConsoleToAdmins("Menu_PlayerPick(): Started", "b");
	
	// If the team captain left the server, terminate the picking and force restart
	// To Do: Allow reassigning the team captain, to continue picking where left off
	if (!RED_IsValidClient(client))
	{
		FinishPicking(true);
		PrintMessageAll("Team Captain Left");
		return;
	}
	
	if (DebugTeamPicking)
		ConsoleToAdmins("Menu_PlayerPick(): Client is valid", "b");
	
	// Otherwise, build the menu object that will be used to pick players.	
	// Set the current team choosing
	int clientTeam = GetClientTeam(client);
	cur_team_choosing = clientTeam;	

	// Initialize menu object. Set menu title and exit button properties
	Handle PickingMenu = CreateMenu(Handle_PickPlayerMenu);
	SetMenuTitle(PickingMenu, "Choose next person to add to %s", ND_GetTeamName(clientTeam));
	SetMenuExitButton(PickingMenu, false);

	if (DebugTeamPicking)
		ConsoleToAdmins("Menu_PlayerPick(): Initial menu created", "b");

	// Precast varriables and loop through all the players on the server
	char currentName[60], currentUser[30], skill[8];
	for (int player = 0; player <= MaxClients; player++) 
	{
		if (PlayerIsPickable(player))
		{
			// Get their name and attach skill value to it
			GetClientName(player, currentName, sizeof(currentName));
			Format(skill, sizeof(skill), " [%d]", 	IsFakeClient(player) ? 0 : 
													ND_GetRoundedPSkill(player));			
			StrCat(currentName, sizeof(currentName), skill);
			
			// Convert user id to a string. Add userid and name to menu item.
			IntToString(GetClientUserId(player), currentUser, sizeof(currentUser));			
			AddMenuItem(PickingMenu, currentUser, currentName);			
		}
	}
	
	if (DebugTeamPicking)
		ConsoleToAdmins("Menu_PlayerPick(): Menu populated", "b");

	// Add the menu item skip and display the menu to the team captain
	AddMenuItem(PickingMenu, "-1", "End/Skip");
	DisplayMenu(PickingMenu, client, GetPickingTimeLimit());
	
	// Reset the team picking timer for the next commander
	// Let the timer know if it's the first two picks
	ResetPickTimer(client);
	
	if (DebugTeamPicking)
		ConsoleToAdmins("Menu_PlayerPick(): finished", "b");
}

/* Helper functions for handling the team pick process */
void SetConstantPickingTeam() {
	next_comm = cur_team_choosing == TEAM_CONSORT ? team_captain[CONSORT_aIDX] : team_captain[EMPIRE_aIDX];
}
void SwitchPickingTeam()
{	
	switch (cur_team_choosing)
	{
		case TEAM_CONSORT: next_comm = team_captain[EMPIRE_aIDX];		
		case TEAM_EMPIRE: next_comm = team_captain[CONSORT_aIDX];
	}
}
void SetPickingTeam()
{
	/* Switch Algorithum! 
	 * One team gets to pick the first player.
	 * The next team gets to pick the two in a row.
	 * Afterwards, take turns picking one player at a time.
	 */
	if (checkPlacement)
	{
		if (firstPlace)
		{
			firstPlace = false;				
			SwitchPickingTeam();

			int otherTeam = getOtherTeam(cur_team_choosing);
			PrintPickOrderMessage("Got First Pick", cur_team_choosing);
			PrintPickOrderMessage("Got Next Picks", otherTeam);
		}

		else if (doublePlace)
		{
			doublePlace = false;
			checkPlacement = false;

			SetConstantPickingTeam();
		}
	}
	else
		SwitchPickingTeam();
}

void PrintPickOrderMessage(char[] phrase, int team)
{
	char teamName[32];
	Format(teamName, sizeof(teamName), ND_GetTeamName(team));
	
	for (int client = 1; client <= MaxClients; client++) 
	{
		if (IsClientInGame(client))
		{		
			PrintToChat(client, "\x05[xG] %t", phrase, teamName);
		}
	}	
}

bool PickingComplete()
{
	if (	last_choice[CONSORT_aIDX] == NO_PLAYER_SELECTED && 	
		last_choice[EMPIRE_aIDX] == NO_PLAYER_SELECTED)
	{
		FinishPicking();			
		return true;
	}
	
	return false;
}
void FinishPicking(bool forced = false)
{
	g_bEnabled = false;
	g_bPickStarted = false;

	if (!forced)
	{
		g_bPickedThisMap = true;
		PrintMessageAllEx("Picking Completed");
	}
}
