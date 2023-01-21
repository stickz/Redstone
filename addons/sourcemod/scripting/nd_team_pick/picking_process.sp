#include <nd_fskill>
#define NO_PLAYER_SELECTED -1
#define TEAM_PICKING_COMPLETE 0
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

			if (DebugTeamPicking)
			{
				char message[32];
				Format(message, sizeof(message), "the client index is %d", client);
				ConsoleToAdmins(message, "b");
			}

			// If the selected player is valid, do the picking routine
			if (IsValidClient(client, !DebugTeamPicking) && IsValidClient(client))
			{
				SetPickingTeam(); // Decide which team gets the next pick

				// If a player was selected (picked) by the team captain
				if (selectedPlayer != NO_PLAYER_SELECTED)
				{
					// Get their name and display which team they're joining.
					PrintChoosenJoin(client, cur_team_choosing);

					// Set the player's team to the team captain's team.
					ChangeClientTeam(client, cur_team_choosing);

					// Push their steamid to the picked array list
					MarkPlayerPicked(client, cur_team_choosing);
				}

				// If the picking is not done, continue displaying the menu to pick players.
				Menu_PlayerPick(next_comm);
			}

			// If selected item wasn't a player, refresh to pick anther option.
			else if (selectedPlayer != NO_PLAYER_SELECTED)
			{
				// Set the constant picking team first
				SetConstantPickingTeam();

				// The use the picker index to execute it
				PrintMessage(next_comm, "Pick Again");
				Menu_PlayerPick(next_comm);
			}

			// If picking is not done, display menu to opposite team incase a skip was sent
			else
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
			SetPickingTeam(); //SwitchPickingTeam();

			// If the picking is not done, continue displaying the menu to pick players.
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
	if (!IsValidClient(client))
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
	char currentName[60], currentUser[30], skill[8]; int pCount = 0;
	for (int player = 1; player <= MaxClients; player++)
	{
		if (PlayerIsPickable(player))
		{
			// Get their name and attach skill value to it
			GetClientName(player, currentName, sizeof(currentName));
			Format(skill, sizeof(skill), " [%d]", IsFakeClient(player) ? 0 : ND_GetRoundedPSkill(player));
			StrCat(currentName, sizeof(currentName), skill);

			// Convert user id to a string. Add userid and name to menu item.
			IntToString(GetClientUserId(player), currentUser, sizeof(currentUser));
			AddMenuItem(PickingMenu, currentUser, currentName);

			// Increment the pCount, to check for instant completion bellow
			pCount += 1;
		}
	}

	// If there's no players to select, team picking is done
	// Instantly finish things off to avoid un-needed hassle
	if (pCount == TEAM_PICKING_COMPLETE)
	{
		FinishPicking();
		CloseHandle(PickingMenu);
		return;
	}

	if (DebugTeamPicking)
		ConsoleToAdmins("Menu_PlayerPick(): Menu populated", "b");

	// Add the menu item skip and display the menu to the team captain
	AddMenuItem(PickingMenu, "-1", "End/Skip");

	// Close menu before auto-assignment to prevent double picking
	DisplayMenu(PickingMenu, client, GetPickingTimeLimit()-1);

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
	 * Afterwards, rotate between teams picking players 2 at a time
	 */
	if ((picking_index + 1) % 2 == 0)
		SwitchPickingTeam();
	else
		SetConstantPickingTeam();

	// If we're on the first pick, print a message to chat
	if (picking_index == 0)
	{
		int otherTeam = getOtherTeam(cur_team_choosing);
		PrintPickOrderMessage("Got First Pick", cur_team_choosing);
		PrintPickOrderMessage("Got Next Picks", otherTeam);
	}

	// Increment the picking index by 1 each time
	picking_index++;
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
