/* Client prefs support */
Handle cookie_set_language = INVALID_HANDLE;
bool option_set_language[MAXPLAYERS + 1] = {true,...};

void AddClientPrefsSupport()
{
	cookie_set_language = RegClientCookie("Set Language On/Off", "", CookieAccess_Protected);
	new info;
	SetCookieMenuItem(CookieMenuHandler_SetLanguage, any:info, "Set Language");
	
	LoadTranslations("common.phrases"); //required for on and off	
}

public CookieMenuHandler_SetLanguage(int client, CookieMenuAction:action, any:info, char[] buffer, int maxlen)
{
	switch (action)
	{
		case CookieMenuAction_DisplayOption:
		{
			char status[10];
			Format(status, sizeof(status), "%T", option_set_language[client] ? "On" : "Off", client);		
			Format(buffer, maxlen, "%T: %s", "Cookie Set Language", client, status);
		}
		
		case CookieMenuAction_SelectOption:
		{
			option_set_language[client] = !option_set_language[client];
			SetClientCookie(client, cookie_set_language, option_set_language[client] ? "On" : "Off");		
			ShowCookieMenu(client);		
		}	
	}
}

public void OnClientCookiesCached(int client) {
	option_set_language[client] = GetCookieSetLanguage(client);
}

bool GetCookieSetLanguage(int client)
{
	char buffer[10];
	GetClientCookie(client, cookie_set_language, buffer, sizeof(buffer));
	
	return !StrEqual(buffer, "Off");
}
