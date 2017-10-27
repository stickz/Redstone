bool option_com_checklist[MAXPLAYERS + 1] = {true,...};
Handle cookie_com_checklist = INVALID_HANDLE;

void AddClientPrefSupport()
{
	LoadTranslations("common.phrases");
	cookie_com_checklist = RegClientCookie("Commander CheckList On/Off", "", CookieAccess_Protected);
	new info;
	SetCookieMenuItem(CookieMenuHandler_CommanderCheckList, any:info, "Commander CheckList");	
}
 
public CookieMenuHandler_CommanderCheckList(int client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	switch (action)
	{
		case CookieMenuAction_DisplayOption:
		{
			char status[10];
			Format(status, sizeof(status), "%T", option_com_checklist[client]? "On" : "Off", client);	
			Format(buffer, maxlen, "%T: %s", "Cookie Commander Checklist", client, status);		
		}
		
		case CookieMenuAction_SelectOption:
		{
			option_com_checklist[client] = !option_com_checklist[client];		
			SetClientCookie(client, cookie_com_checklist, option_com_checklist[client] ? "On" : "Off");		
			ShowCookieMenu(client);		
		}	
	}
}

public void OnClientCookiesCached(int client) {
	option_com_checklist[client] = GetCookieCommanderCheckList(client);
}

bool GetCookieCommanderCheckList(int client)
{
	char buffer[10];
	GetClientCookie(client, cookie_com_checklist, buffer, sizeof(buffer));
	
	return !StrEqual(buffer, "Off");
}
