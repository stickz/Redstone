bool option_show_damage[MAXPLAYERS + 1] = {true, ...};
bool option_show_thermal[MAXPLAYERS + 1] = {false, ...};

Handle cookie_show_damage = INVALID_HANDLE;
Handle cookie_show_thermal = INVALID_HANDLE;

public int CookieMenuHandler_ShowDamage(int client, CookieMenuAction:action, any:info, char[] buffer, int maxlen)
{
	if (action == CookieMenuAction_DisplayOption)
	{
		char status[10];
		Format(status, sizeof(status), "%T", option_show_damage[client] ? "On" : "Off", client);
		Format(buffer, maxlen, "%T: %s", "Cookie Show Damage", client, status);
	}
	// CookieMenuAction_SelectOption
	else
	{
		option_show_damage[client] = !option_show_damage[client];
		SetClientCookie(client, cookie_show_damage, option_show_damage[client] ? "On" : "Off");
		ShowCookieMenu(client);
	}
}

public int CookieMenuHandler_ShowThermal(int client, CookieMenuAction:action, any:info, char[] buffer, int maxlen)
{
	if (action == CookieMenuAction_DisplayOption)
	{
		char status[10];
		Format(status, sizeof(status), "%T", option_show_thermal[client] ? "On" : "Off", client);
		Format(buffer, maxlen, "%T: %s", "Cookie Thermal Damage", client, status);
	}
	// CookieMenuAction_SelectOption
	else
	{
		option_show_thermal[client] = !option_show_thermal[client];
		SetClientCookie(client, cookie_show_thermal, option_show_thermal[client] ? "On" : "Off");
		ShowCookieMenu(client);
	}
}

public void OnClientCookiesCached(int client)
{
	option_show_damage[client] = GetCookieShowDamage(client);
	option_show_thermal[client] = GetCookieShowThermal(client);
}

void AddClientPrefs()
{
	LoadTranslations("common.phrases");
	
	cookie_show_damage = RegClientCookie("Show Damage On/Off", "", CookieAccess_Protected);
	cookie_show_thermal = RegClientCookie("Thermal Damage On/Off", "", CookieAccess_Protected);
	
	int info;
	SetCookieMenuItem(CookieMenuHandler_ShowDamage, info, "Show Damage");
	SetCookieMenuItem(CookieMenuHandler_ShowThermal, info, "Thermal Damage");
}

bool GetCookieShowDamage(int client)
{
	char buffer[10];
	GetClientCookie(client, cookie_show_damage, buffer, sizeof(buffer));
	
	return !StrEqual(buffer, "Off");
}

bool GetCookieShowThermal(int client)
{
	char buffer[10];
	GetClientCookie(client, cookie_show_thermal, buffer, sizeof(buffer));
	
	return StrEqual(buffer, "On");
}