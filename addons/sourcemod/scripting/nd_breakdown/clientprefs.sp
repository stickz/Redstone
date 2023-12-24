bool option_team_breakdown[MAXPLAYERS + 1] = {true,...};
Handle cookie_team_breakdown = INVALID_HANDLE;

void AddClientPrefSupport()
{
	LoadTranslations("common.phrases");
	cookie_team_breakdown = RegClientCookie("Team Breakdown On/Off", "", CookieAccess_Protected);
	new info;
	SetCookieMenuItem(CookieMenuHandler_TeamBreakdown, any:info, "Troop Counts");	
}
 
public CookieMenuHandler_TeamBreakdown(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	switch (action)
	{
		case CookieMenuAction_DisplayOption:
		{
			char status[10];
			Format(status, sizeof(status), "%T", option_team_breakdown[client]? "On" : "Off", client);	
			Format(buffer, maxlen, "%T: %s", "Cookie Team Breakdown", client, status);		
		}
		
		case CookieMenuAction_SelectOption:
		{
			option_team_breakdown[client] = !option_team_breakdown[client];		
			SetClientCookie(client, cookie_team_breakdown, option_team_breakdown[client] ? "On" : "Off");		
			ShowCookieMenu(client);		
		}	
	}
}

public OnClientCookiesCached(client)
{
	option_team_breakdown[client] = GetCookieTeamBreakdown(client);
}

bool GetCookieTeamBreakdown(client)
{
	char buffer[10];
	GetClientCookie(client, cookie_team_breakdown, buffer, sizeof(buffer));
	
	return StrEqual(buffer, "On");
}
