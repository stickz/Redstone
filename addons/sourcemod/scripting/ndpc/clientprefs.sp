/* 
 * Fully abstract setting creation 
 * Simply bump the option count and fill out array values,
 * To add a new settings option.The code will automatically adapt
 */
#define OPTION_COUNT 3

new const String:ndpcCookieName[OPTION_COUNT][] = {
	"NDPC AutoTranslate On/Off",
	"NDPC CommanderLang On/Off",
	"NDPC TeamLang On/Off"
};
new const String:ndpcMenuTrans[OPTION_COUNT][] = {
	"MenuPhrase_AutoTranslate",
	"MenuPhrase_CommanderLang",
	"MenuPhrase_TeamLang"
};
new const String:ndpcMenuDisplay[OPTION_COUNT][] = {
	"Auto-Translate Phrases",
	"Commander Lang Display",
	"Team Lang Display"
};

/* Do not edit bellow this line unless you know what you're doing */
#include <clientprefs>
#include <menus>

new Handle:ndpcSettingsMenu = INVALID_HANDLE;
new Handle:cookie_show_option[OPTION_COUNT] = {INVALID_HANDLE, ...};
new bool:ndpc_option[OPTION_COUNT][MAXPLAYERS + 1];

AddClientPrefsSupport()
{
	/* Create the settings menu to control toggle features */
	CreateNDPCSettingsMenu(ndpcSettingsMenu);
	
	/* Create the client cookies to store the information */
	for (new i = 0; i < OPTION_COUNT; i++)	{
		cookie_show_option[i] = RegClientCookie(ndpcCookieName[i], "", CookieAccess_Protected);
	}
}

public OnAllPluginsLoaded()
{
	/* Add custom menu handler to !settings menu */
	if (LibraryExists("clientprefs")) {
		SetCookieMenuItem(NDPCSettingsMenu, 0, "NDPC Settings");
	}
}

public OnClientCookiesCached(client)
{
	/* Update all the settings booleans the client */
	for (new i = 0; i < OPTION_COUNT; i++)	{
		ndpc_option[i][client] = GetCookieStatus(client, cookie_show_option[i]);
	}
}

bool:GetCookieStatus(client, Handle:cookie)
{
	decl String:buffer[10];
	GetClientCookie(client, cookie, buffer, sizeof(buffer));
	
	return !StrEqual(buffer, "Off");
}

public NDPCSettingsMenu(client, CookieMenuAction: action, any:info, String:buffer[], maxlen)
{
	/* Redirect the client from the !settings menu to the custom menu */
	if (action == CookieMenuAction_SelectOption) {
		DisplayMenu(ndpcSettingsMenu, client, MENU_TIME_FOREVER);
	}
}

/* Create the custom menu for this plugin */
public CreateNDPCSettingsMenu(&Handle: MenuHandle)
{
	MenuHandle = CreateMenu(ndpcSettingsHandler, MenuAction_DisplayItem | MenuAction_Select | MenuAction_Cancel);
	
	SetMenuTitle(MenuHandle, "NDPC - Settings Menu");
	
	for (new i = 0; i < OPTION_COUNT; i++)	{
		AddMenuItem(MenuHandle, ndpcMenuTrans[i], ndpcMenuDisplay[i]);
	}
}

/* Handle display and selected in the custom menu */
public ndpcSettingsHandler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_DisplayItem:
		{
			new client = param1, index = param2;
			
			decl String:status[10];
			Format(status, sizeof(status), "%T", ndpc_option[index][client] ? "On" : "Off", client);
			
			decl String:info[64];
			GetMenuItem(menu, index, info, sizeof(info), _, "", 0);
			
			decl String: buffer[255];
			Format(buffer, sizeof(buffer), "%T", info, client, status);
			
			return RedrawMenuItem(buffer);
		}
		
		case MenuAction_Select:
		{
			new client = param1, index = param2;
			
			ndpc_option[index][client] = !ndpc_option[index][client];
			SetClientCookie(client, cookie_show_option[index], ndpc_option[index][client] ? "On" : "Off");
			
			DisplayMenu(ndpcSettingsMenu, client, MENU_TIME_FOREVER);
		}
	}
}
