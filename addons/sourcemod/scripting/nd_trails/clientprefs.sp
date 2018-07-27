#define TRAIL_COMMANDER 1
#define TRAIL_PLAYER 	2
#define TRAIL_SPECTATE	3

bool option_trails[4][MAXPLAYERS + 1];
Handle cookie_trails[4] = {INVALID_HANDLE, ...};

void AddClientPrefSupport()
{
	LoadTranslations("common.phrases");
	cookie_trails[TRAIL_COMMANDER] = RegClientCookie("Commander Trails On/Off", "", CookieAccess_Protected);
	cookie_trails[TRAIL_PLAYER] = RegClientCookie("Player Trails On/Off", "", CookieAccess_Protected);
	cookie_trails[TRAIL_SPECTATE] = RegClientCookie("Spectator Trails On/Off", "", CookieAccess_Protected);
	
	new info;
	SetCookieMenuItem(CookieMenuHandler_Trails, any:info, "Grenade Trails");	
}
 
public CookieMenuHandler_Trails(int client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (!SWGM_IsInGroup(client, true))
		PrintMessage(client, "Steam Group Usage");
		
	else if (action != CookieMenuAction_DisplayOption)
	{
		Menu TrailMenu = new Menu(GrenadeTrailsMenu);
		TrailMenu.SetTitle("Grenade Trails Settings");
		
		/* Display the trail type and On/Off beside name */
		char TrailName[3][] = {
			"Commander Trails",
			"Player Trails",
			"Spectator Trails"		
		};		
		for (int i = 1; i <= 3; i++)
		{
			char status[10];
			Format(status, sizeof(status), "%T", option_trails[i][client] ? "On" : "Off", client);
			TrailMenu.AddItem(i, "%s: %s", TrailName[i], status);
		}
		
		// Set back button to enabled and display the menu forever
		TrailMenu.ExitBackButton = true;
		TrailMenu.Display(client, MENU_TIME_FOREVER);
	}
}

public int GrenadeTrailsMenu(Menu menu, MenuAction action, int client, int choice)
{
	/* Get the trail integer selected */
	char trailChoice[4];
	menu.GetItem(choice, trailChoice, sizeof(trailChoice));
	int tI = StringToInt(trailChoice);
	
	switch(action)
	{
		case MenuAction_Select:
		{
			option_trails[tI][client] = !option_trails[tI][client];

			if (option_trails[tI][client])
			{
				PrintToChat(client, "Trail Option Enabled");
				SetClientCookie(client, cookie_trails[tI], "On");
			}

			else if (option_trails[tI][client])
			{
				PrintToChat(client, "Trial Option Disabled");
				SetClientCookie(client, cookie_trails[tI], "Off");				
			}
		}
		
		case MenuAction_Cancel: ShowCookieMenu(client);
		case MenuAction_End: delete menu;
	}
}

// Disable trails, if the client leaves the steam group
public void SWGM_OnLeaveGroup(int client) {
	DisableTrails(client);
}

public void OnClientCookiesCached(int client) 
{
	if (SWGM_IsInGroup(client, true))
		DisableTrails(client);
	else
	{	
		for (int i = 1; i <=3; i++) {
			option_trails[i][client] = GetCookieTrails(client, cookie_trails[i]);
		}
	}
}

bool GetCookieTrails(int client, Handle &cTrails)
{
	char buffer[10];
	GetClientCookie(client, cTrails, buffer, sizeof(buffer));
	
	return !StrEqual(buffer, "Off") && SWGM_IsInGroup(client, true);
}

void DisableTrails(int client) {
	for (int i = 1; i <=3; i++) {
		option_trails[i][client] = false;
	}
}
