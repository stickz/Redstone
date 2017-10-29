bool option_mapvote_mesg[MAXPLAYERS + 1] = {false,...};
Handle cookie_mapvote_mesg = INVALID_HANDLE;

void AddClientPrefSupport()
{
	LoadTranslations("common.phrases");
	cookie_mapvote_mesg = RegClientCookie("MapVote Messages On/Off", "", CookieAccess_Protected);
	new info;
	SetCookieMenuItem(CookieMenuHandler_MapVoteMessages, any:info, "MapVote Messages");	
}
 
public CookieMenuHandler_MapVoteMessages(int client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	switch (action)
	{
		case CookieMenuAction_DisplayOption:
		{
			char status[10];
			Format(status, sizeof(status), "%T", option_mapvote_mesg[client]? "On" : "Off", client);	
			Format(buffer, maxlen, "%T: %s", "Cookie MapVote Messages", client, status);	
		}
		
		case CookieMenuAction_SelectOption:
		{
			option_mapvote_mesg[client] = !option_mapvote_mesg[client];		
			SetClientCookie(client, cookie_mapvote_mesg, option_mapvote_mesg[client] ? "On" : "Off");		
			ShowCookieMenu(client);		
		}	
	}
}

public void OnClientCookiesCached(int client) {
	option_mapvote_mesg[client] = GetCookieMapVoteMessages(client);
}

bool GetCookieMapVoteMessages(int client)
{
	char buffer[10];
	GetClientCookie(client, cookie_mapvote_mesg, buffer, sizeof(buffer));
	
	return StrEqual(buffer, "On");
}
