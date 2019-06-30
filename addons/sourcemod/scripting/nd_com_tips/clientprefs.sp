/* Client prefs support */
Handle cookie_commander_tips = INVALID_HANDLE;
bool option_commander_tips[MAXPLAYERS + 1] = {true,...};

void AddClientPrefsSupport()
{
	cookie_commander_tips = RegClientCookie("Commander Tips On/Off", "", CookieAccess_Protected);
	new info;
	SetCookieMenuItem(CookieMenuHandler_CommanderTips, any:info, "Commander Tips");
	
	LoadTranslations("common.phrases"); //required for on and off	
}

public CookieMenuHandler_CommanderTips(int client, CookieMenuAction:action, any:info, char[] buffer, int maxlen)
{
	switch (action)
	{
		case CookieMenuAction_DisplayOption:
		{
			char status[10];
			Format(status, sizeof(status), "%T", option_commander_tips[client] ? "On" : "Off", client);		
			Format(buffer, maxlen, "%T: %s", "Cookie Commander Tips", client, status);
		}
		
		case CookieMenuAction_SelectOption:
		{
			option_commander_tips[client] = !option_commander_tips[client];
			SetClientCookie(client, cookie_commander_tips, option_commander_tips[client] ? "On" : "Off");		
			ShowCookieMenu(client);		
		}	
	}
}

public void OnClientCookiesCached(int client) {
	option_commander_tips[client] = GetCookieCommanderTips(client);
}

bool GetCookieCommanderTips(int client)
{
	char buffer[10];
	GetClientCookie(client, cookie_commander_tips, buffer, sizeof(buffer));
	
	return !StrEqual(buffer, "Off");
}
