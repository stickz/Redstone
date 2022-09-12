void addClientPrefs()
{
	cookie_timelimit_features = RegClientCookie("TimeLimit Features On/Off", "", CookieAccess_Protected);
	new info;
	SetCookieMenuItem(CookieMenuHandler_TimeLimitFeatures, any:info, "TimeLimit Features");
	
	LoadTranslations("common.phrases"); //required for on and off
}

//cookie stuff
public CookieMenuHandler_TimeLimitFeatures(int client, CookieMenuAction action, any:info, char[] buffer, int maxlen)
{
	switch (action)
	{
		case CookieMenuAction_DisplayOption:
		{
			char status[10];
			Format(status, sizeof(status), "%T", option_timelimit_features[client] ? "On" : "Off", client);		
			Format(buffer, maxlen, "%T: %s", "Cookie TimeLimit Features", client, status);		
		}
		
		case CookieMenuAction_SelectOption:
		{
			option_timelimit_features[client] = !option_timelimit_features[client];
			SetClientCookie(client, cookie_timelimit_features, option_timelimit_features[client] ? "On" : "Off");		
			ShowCookieMenu(client);		
		}	
	}
}

public OnClientCookiesCached(int client) {
	option_timelimit_features[client] = GetCookieTimeLimitFeautres(client);
}

bool GetCookieTimeLimitFeautres(int client)
{
	char buffer[10];
	GetClientCookie(client, cookie_timelimit_features, buffer, sizeof(buffer));
	
	return StrEqual(buffer, "On");
}

void cpShowCountDown()
{
	Handle HudText = CreateHudSynchronizer();
	SetHudTextParams(-1.0, 0.4, 1.0, 220, 20, 60, 255);
			
	for (int idx = 1; idx <= MaxClients; idx++)
		if (IsClientInGame(idx) && option_timelimit_features[idx] && !ND_IsCommander(idx))
			ShowSyncHudText(idx, HudText, "%d", g_Integer.countdown);
				
	CloseHandle(HudText);
}