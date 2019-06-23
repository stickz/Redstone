/* Client prefs support */
Handle cookie_player_tips = INVALID_HANDLE;
bool option_player_tips[MAXPLAYERS + 1] = {true,...};

void AddClientPrefsSupport()
{
	cookie_player_tips = RegClientCookie("Player Tips On/Off", "", CookieAccess_Protected);
	new info;
	SetCookieMenuItem(CookieMenuHandler_PlayerTips, any:info, "Player Tips");
	
	LoadTranslations("common.phrases"); //required for on and off	
}

public CookieMenuHandler_PlayerTips(int client, CookieMenuAction:action, any:info, char[] buffer, int maxlen)
{
	switch (action)
	{
		case CookieMenuAction_DisplayOption:
		{
			char status[10];
			Format(status, sizeof(status), "%T", option_player_tips[client] ? "On" : "Off", client);		
			Format(buffer, maxlen, "%T: %s", "Cookie Player Tips", client, status);
		}
		
		case CookieMenuAction_SelectOption:
		{
			option_player_tips[client] = !option_player_tips[client];
			SetClientCookie(client, cookie_player_tips, option_player_tips[client] ? "On" : "Off");		
			ShowCookieMenu(client);		
		}	
	}
}

public void OnClientCookiesCached(int client) {
	option_player_tips[client] = GetCookiePlayerTips(client);
}

bool GetCookiePlayerTips(int client)
{
	char buffer[10];
	GetClientCookie(client, cookie_player_tips, buffer, sizeof(buffer));
	
	return !StrEqual(buffer, "Off");
}
