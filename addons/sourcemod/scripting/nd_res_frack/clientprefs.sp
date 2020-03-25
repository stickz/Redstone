#include <clientprefs>

/* Client prefs support */
Handle cookie_res_frack = INVALID_HANDLE;
bool option_res_frack[MAXPLAYERS + 1] = {true,...};

void AddClientPrefsSupport()
{
	cookie_res_frack = RegClientCookie("Resource Frack On/Off", "", CookieAccess_Protected);
	new info;
	SetCookieMenuItem(CookieMenuHandler_ResourceFrack, any:info, "Resource Frack");
	
	LoadTranslations("common.phrases"); //required for on and off	
}

public CookieMenuHandler_ResourceFrack(int client, CookieMenuAction:action, any:info, char[] buffer, int maxlen)
{
	switch (action)
	{
		case CookieMenuAction_DisplayOption:
		{
			char status[10];
			Format(status, sizeof(status), "%T", option_res_frack[client] ? "On" : "Off", client);
			Format(buffer, maxlen, "%T: %s", "Cookie Resource Frack", client, status);
		}
		
		case CookieMenuAction_SelectOption:
		{
			option_res_frack[client] = !option_res_frack[client];
			SetClientCookie(client, cookie_res_frack, option_res_frack[client] ? "On" : "Off");		
			ShowCookieMenu(client);		
		}	
	}
}

public void OnClientCookiesCached(int client) {
	option_res_frack[client] = GetCookieResFrack(client);
}

bool GetCookieResFrack(int client)
{
	char buffer[10];
	GetClientCookie(client, cookie_res_frack, buffer, sizeof(buffer));
	
	return !StrEqual(buffer, "Off");
}
