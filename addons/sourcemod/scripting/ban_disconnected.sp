#include <sourcemod>
#include <adminmenu>
#include <sdktools>

#define STORED_ENTRIES 100

//Version is auto-filled by the travis builder
public Plugin myinfo = 
{
	name        = "Ban disconnected players",
	author      = "mad_hamster, stickz",
	description = "Lets you ban players that recently disconnected",
	version     = "dummy",
	url         = "http://pro-css.co.il"
};

Handle hTopMenu = INVALID_HANDLE;

static char disconnected_player_names   [STORED_ENTRIES][32];
static char disconnected_player_authids	[STORED_ENTRIES][32];
static int  disconnected_player_times   [STORED_ENTRIES];

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/ban_disconnected/ban_disconnected.txt"
#include "updater/standard.sp"

public void OnPluginStart() 
{
	RegAdminCmd("sm_bandisconnected", BanDisconnected, ADMFLAG_BAN);
	HookEvent("player_disconnect", OnEventPlayerDisconnect);
	
	Handle topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
		OnAdminMenuReady(topmenu);
	
	AddUpdaterLibrary(); //auto-updater
}

public Action OnEventPlayerDisconnect(Event event, const char[] name, bool dontBroadcast) {
	char steam_id[32];
	event.GetString("networkid", steam_id, sizeof(steam_id));

	// Ignore if authid does not start with STEAM_ (possibly bot), or is identical to the last
	// disconnected steam id, but only if it occured at the same second (duplicate event)
	// Note: We can't resolve the client index from the event's userid and check IsFakeClient(),
	//       since the client may have disconnected already under some HL2 games.
	if (   strncmp(steam_id, "STEAM_", 6) == 0
	    && (   queue_get_size() == 0
	        || (   strcmp(steam_id, disconnected_player_authids[queue_translate_pos(queue_get_size()-1)]) != 0
	            || disconnected_player_times[queue_translate_pos(queue_get_size()-1)] != GetTime())))
	{
		int pos = queue_push();
		strcopy(disconnected_player_authids[pos], sizeof(disconnected_player_authids[]), steam_id);
		event.GetString("name", disconnected_player_names[pos], sizeof(disconnected_player_names[]));
		disconnected_player_times[pos] = GetTime();
	}
	return Plugin_Continue;
}

public Action BanDisconnected(int client, int args) {
	if (args < 2 || args > 3)
		ReplyToCommand(client, "[SM] Usage: sm_bandisconnected <\"steamid\"> <minutes|0> [\"reason\"]");
	else {
		char steamid[20], minutes[10], reason[256];
		GetCmdArg(1, steamid, sizeof(steamid));
		GetCmdArg(2, minutes, sizeof(minutes));
		GetCmdArg(3, reason,  sizeof(reason));
		CheckAndPerformBan(client, steamid, StringToInt(minutes), reason);
	}

	return Plugin_Handled;
}

void CheckAndPerformBan(int client, const char[] steamid, int minutes, const char[] reason) {
	new AdminId:source_aid = GetUserAdmin(client), AdminId:target_aid;
	if (   (target_aid = FindAdminByIdentity(AUTHMETHOD_STEAM, steamid)) == INVALID_ADMIN_ID
		|| CanAdminTarget(source_aid, target_aid))
	{
		// Ugly hack: Sourcemod doesn't provide means to run a client command with elevated permissions,
		// so we briefly grant the admin the root flag
		bool has_root_flag = GetAdminFlag(source_aid, Admin_Root);
		SetAdminFlag(source_aid, Admin_Root, true);
		FakeClientCommand(client, "sm_addban %d \"%s\" %s", minutes, steamid, reason);
		SetAdminFlag(source_aid, Admin_Root, has_root_flag);
	}
	else ReplyToCommand(client, "[sm_bandisconnected] You can't ban an admin with higher immunity than yourself");
}


///////////////////////////////////////////////////////////////////////////////
// Menu madness
///////////////////////////////////////////////////////////////////////////////

public OnAdminMenuReady(Handle topmenu) {
	if (topmenu != hTopMenu) {
		hTopMenu = topmenu;
		new TopMenuObject:player_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);
		if (player_commands != INVALID_TOPMENUOBJECT)
			AddToTopMenu(hTopMenu, "sm_bandisconnected", TopMenuObject_Item, AdminMenu_Ban,
				player_commands, "sm_bandisconnected", ADMFLAG_BAN);
	}
}

public AdminMenu_Ban(Handle topmenu, TopMenuAction:action, TopMenuObject:object_id, param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Ban disconnected player");
	else if (action == TopMenuAction_SelectOption)
		DisplayBanTargetMenu(param);
}

void DisplayBanTargetMenu(int client) 
{
	Menu menu = new Menu(MenuHandler_BanPlayerList);
	menu.SetTitle("Ban disconnected player");
	menu.ExitBackButton = true;
	
	for (int i = queue_get_size() - 1; i >= 0; --i) 
	{
		int pos = queue_translate_pos(i);
		char client_info[100];
		int delta = GetTime() - disconnected_player_times[pos];
		Format(client_info, sizeof(client_info), "%s (%s) (%dd:%02dh:%02dm:%02ds ago)",
			disconnected_player_names[pos],
			disconnected_player_authids[pos],
			(delta / (60*60*24)),
			(delta % (60*60*24)) / (60*60),
			(delta % (60*60)) / 60,
			(delta % 60));
			
		menu.AddItem(disconnected_player_authids[pos], client_info);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_BanPlayerList(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
				DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
		case MenuAction_Select:
		{
			char state_[128];
			menu.GetItem(param2, state_, sizeof(state_));
			DisplayBanTimeMenu(param1, state_);
		}
	}
}

void AddMenuItemWithState(Menu menu, const char[] state_, const char[] addstate, const char[] display) 
{
	char newstate[128];
	Format(newstate, sizeof(newstate), "%s\n%s", state_, addstate);
	menu.AddItem(newstate, display);
}

void DisplayBanTimeMenu(client, const char[] state_) 
{
	Menu menu = new Menu(MenuHandler_BanTimeList);
	menu.SetTitle("Ban disconnected player");
	menu.ExitBackButton = true;
	
	AddMenuItemWithState(menu, state_, "0", "Permanent");
	AddMenuItemWithState(menu, state_, "10", "10 Minutes");
	AddMenuItemWithState(menu, state_, "30", "30 Minutes");
	AddMenuItemWithState(menu, state_, "60", "1 Hour");
	AddMenuItemWithState(menu, state_, "240", "4 Hours");
	AddMenuItemWithState(menu, state_, "1440", "1 Day");
	AddMenuItemWithState(menu, state_, "10080", "1 Week");
	AddMenuItemWithState(menu, state_, "20160", "2 Weeks");
	AddMenuItemWithState(menu, state_, "30240", "3 Weeks");
	AddMenuItemWithState(menu, state_, "43200", "1 Month");
	AddMenuItemWithState(menu, state_, "129600", "3 Months");
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_BanTimeList(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
				DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
		case MenuAction_Select:
		{
			char state_[128];
			menu.GetItem(param2, state_, sizeof(state_));
			DisplayBanReasonMenu(param1, state_);
		}
	}
}

void DisplayBanReasonMenu(client, const char[] state_) 
{
	Menu menu = new Menu(MenuHandler_BanReasonList);
	menu.SetTitle("Ban reason");
	menu.ExitBackButton = true;
	
	AddMenuItemWithState(menu, state_, "Abusive", "Abusive");
	AddMenuItemWithState(menu, state_, "Racism", "Racism");
	AddMenuItemWithState(menu, state_, "General cheating/exploits", "General cheating/exploits");
	AddMenuItemWithState(menu, state_, "Wallhack", "Wallhack");
	AddMenuItemWithState(menu, state_, "Aimbot", "Aimbot");
	AddMenuItemWithState(menu, state_, "Speedhacking", "Speedhacking");
	AddMenuItemWithState(menu, state_, "Mic spamming", "Mic spamming");
	AddMenuItemWithState(menu, state_, "Admin disrepect", "Admin disrepect");
	AddMenuItemWithState(menu, state_, "Camping", "Camping");
	AddMenuItemWithState(menu, state_, "Team killing", "Team killing");
	AddMenuItemWithState(menu, state_, "Unacceptable Spray", "Unacceptable Spray");
	AddMenuItemWithState(menu, state_, "Breaking Server Rules", "Breaking Server Rules");
	AddMenuItemWithState(menu, state_, "Other", "Other");
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_BanReasonList(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
				DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
		case MenuAction_Select:
		{
			char state_[128], state_parts[4][32];
			menu.GetItem(param2, state_, sizeof(state_));
			
			if (ExplodeString(state_, "\n", state_parts, sizeof(state_parts), sizeof(state_parts[])) != 3)
				SetFailState("Bug in menu handlers");
			else 
				CheckAndPerformBan(param1, state_parts[0], StringToInt(state_parts[1]), state_parts[2]);
		}
	}
}

///////////////////////////////////////////////////////////////////////////////
// A very simple fixed-size queue yielding offsets into cyclic array(s)
///////////////////////////////////////////////////////////////////////////////

static int queue_max_size = STORED_ENTRIES;
static int queue_size     = 0;
static int queue_start    = 0;

int queue_get_size()   { return queue_size; }
//queue_is_full()    { return queue_size == queue_max_size; }
//queue_is_empty()   { return queue_size == 0; }
//queue_space_left() { return queue_max_size - queue_size; }

// Given a logical position within the queue between 0 (queue front; oldest item)
// and queue_size-1 (queue back; newest item), returns the translated position
// in the cyclic array.

int queue_translate_pos(pos) {
	pos += queue_start;
	if (pos >= queue_max_size)
		return pos - queue_max_size;
	else return pos;
}


// Adds an item to the queue, possibly popping the oldest item to make room if
// the queue is full. Returns the translated position of the new item in the
// cyclic array.

int queue_push() {
	if (queue_size == queue_max_size)
		queue_pop();
	return queue_translate_pos(queue_size++);
}


// Removes an item from the queue, assuming it is non-empty. If it is empty, it
// will stop the plugin execution!

int queue_pop() {
	if (queue_size == 0) {
		SetFailState("Can't pop from an empty queue!");
		return -1;
	}
	else {
		new pos = queue_start;
		queue_start = queue_translate_pos(1);
		--queue_size;
		return pos;
	}
}
