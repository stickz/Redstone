bool option_trails[MAXPLAYERS + 1] = {true,...};
Handle cookie_trails = INVALID_HANDLE;

void AddClientPrefSupport()
{
	LoadTranslations("common.phrases");
	cookie_trails = RegClientCookie("Trails On/Off", "", CookieAccess_Protected);
	new info;
	SetCookieMenuItem(CookieMenuHandler_Trails, any:info, "Grenade Trails");	
}
 
public CookieMenuHandler_Trails(int client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	switch (action)
	{
		case CookieMenuAction_DisplayOption:
		{
			char status[10];
			Format(status, sizeof(status), "%T", option_trails[client] ? "On" : "Off", client);	
			Format(buffer, maxlen, "%T: %s", "Cookie Trails", client, status);		
		}
		
		case CookieMenuAction_SelectOption:
		{
			if (!option_trails[client] && !SWGM_IsInGroup(client, true))
				PrintMessage(client, "Steam Group Usage");
			else
			{
				option_trails[client] = !option_trails[client];		
				SetClientCookie(client, cookie_trails, option_trails[client] ? "On" : "Off");			
			}
		
			ShowCookieMenu(client);		
		}	
	}
}

public void OnClientCookiesCached(int client) {
	option_trails[client] = GetCookieTrails(client);
}

bool GetCookieTrails(int client)
{
	char buffer[10];
	GetClientCookie(client, cookie_trails, buffer, sizeof(buffer));
	
	return !StrEqual(buffer, "Off") && SWGM_IsInGroup(client, true);
}
