/*
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

#include <sourcemod>
#include <sdktools>
#include <adminmenu>

public Plugin myinfo =
{
	name = "[ND] Commander Actions",
	author = "Xander, Stickz",
	description = "A plugin that allows setting and demoting a commander",
	version = "dummy",
	url = "https://github.com/stickz/Redstone/"
}

Handle hAdminMenu = INVALID_HANDLE;

/* Auto Updater Suport */
#define UPDATE_URL  	"https://github.com/stickz/Redstone/raw/build/updater/nd_commander_actions/nd_commander_actions.txt"
#include 		"updater/standard.sp"

public void OnPluginStart()
{
	RegAdminCmd("sm_promote", Cmd_SetCommander, ADMFLAG_CUSTOM1, "<Name|#UserID> - Promote a player to commander.");
	RegAdminCmd("sm_forcedemote", Cmd_Demote, ADMFLAG_CUSTOM1, "<ct | emp> - Remove a team's commander.");	
	
	LoadTranslations("common.phrases"); //required for FindTarget	
	
	Handle topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
		OnAdminMenuReady(topmenu);
		
	AddUpdaterLibrary(); //auto-updater
}

public void OnLibraryRemoved(char[] name)
{
	if (StrEqual(name, "adminmenu"))
		hAdminMenu = INVALID_HANDLE;
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hAdminMenu)
		return;
	
	hAdminMenu = topmenu;
	
	new TopMenuObject:CMCategory = AddToTopMenu(topmenu, "Commander Actions", TopMenuObject_Category, CategoryHandler, INVALID_TOPMENUOBJECT);
	AddToTopMenu(topmenu, "Set Commander", TopMenuObject_Item, CMHandleSETCommander, CMCategory, "sm_setcommander", ADMFLAG_CUSTOM1);
	AddToTopMenu(topmenu, "Demote Commander", TopMenuObject_Item, CMHandleDEMOTECommander, CMCategory, "sm_demotecommander", ADMFLAG_CUSTOM1);
}

public Action Cmd_SetCommander(int client, int args)
{
	if (!args)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setcommander <Name|#Userid>");
		return Plugin_Handled;
	}
	
	char playerName[64]
	GetCmdArg(1, playerName, sizeof(playerName));
	
	int target = FindTarget(client, playerName, true, true);
	
	if (target == -1)
	{
		ReplyToCommand(client, "[SM] Player not found by name segment %s", playerName);
		return Plugin_Handled;
	}
	
	PerformPromote(client, target);
	return Plugin_Handled;
}

public Action Cmd_Demote(int client, int args)
{
	if (!args)
	{
		ReplyToCommand(client, "[SM] Usage: sm_demotecommander <ct | emp>");
		return Plugin_Handled;
	}
	
	int target = -1;
	
	char teamName[64];
	GetCmdArg(1, teamName, sizeof(teamName));
	
	if (StrEqual(teamName, "ct", false))
		target = GameRules_GetPropEnt("m_hCommanders", 0);
	
	else if (StrEqual(teamName, "emp", false))
		target = GameRules_GetPropEnt("m_hCommanders", 1);
	
	else
	{
		ReplyToCommand(client, "[SM] Unknown argument: %s. Usage: sm_demotecommander <ct | emp>", arg1);
		return Plugin_Handled;
	}	
	
	if (target == -1)
		ReplyToCommand(client, "[SM] No commander on team %s", teamName);
	
	else
		PerformDemote(client, target);
	
	return Plugin_Handled;
}

void PerformPromote(int client, int target)
{
	ServerCommand("_promote_to_commander %d", target);
	LogAction(client, target, "\"%L\" promoted \"%L\" to commander.", client, target);
	ShowActivity2(client, "[SM] ", "Promoted %N to commander.", target);
}

void PerformDemote(int client, int target) 
{
	if (target == -1)
		return;
	
	LogAction(client, target, "\"%L\" demoted \"%L\" from commander.", client, target);
	FakeClientCommand(target, "startmutiny");
	FakeClientCommand(target, "rtsview");
	ShowActivity2(client, "[SM] ", "Demoted %N from commander.",target);
}
	
//=========MENU HANDLERS====================================================

public CategoryHandler(Handle:topmenu, 
				TopMenuAction:action,
				TopMenuObject:object_id,
				param,
				String:buffer[],
				maxlength)
{
	if (action == TopMenuAction_DisplayTitle)
	{
		Format(buffer, maxlength, "Commander Actions:");
	}
	
	else if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Commander Actions");
	}
}

// Set Commander Menu Handlers
public CMHandleSETCommander(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Set");
	
	else if (action == TopMenuAction_SelectOption)
	{
		Handle menu = CreateMenu(Handle_SetCommander_SelectTeam);
		SetMenuTitle(menu, "Select a Team:");
		AddMenuItem(menu, "2", "Consortium");
		AddMenuItem(menu, "3", "Empire");
		DisplayMenu(menu, param, MENU_TIME_FOREVER);
	}
}

public Handle_SetCommander_SelectTeam(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:item[8]
		GetMenuItem(menu, param2, item, sizeof(item));
		Display_SetCommander_TeamList(param1, StringToInt(item));
	}
	
	else if (action == MenuAction_End)
		CloseHandle(menu);
}

void Display_SetCommander_TeamList(int client, int SelectedTeam)
{
	char UserID[8];
	char Name[64];
	
	Handle menu = CreateMenu(Handle_SetCommander_ClientSelection);
	SetMenuTitle(menu, "Select A Player:");
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if (GetClientTeam(i) == SelectedTeam && CanUserTarget(client, i))
			{
				IntToString(GetClientUserId(i), UserID, sizeof(UserID));
				GetClientName(i, Name, sizeof(Name));
				AddMenuItem(menu, UserID, Name);
			}
		}
	}

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public Handle_SetCommander_ClientSelection(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		char item[8];
		GetMenuItem(menu, param2, item, sizeof(item));
		int target = StringToInt(item);
		target = GetClientOfUserId(target);
	
		if (target)
			PerformPromote(param1, target)
		
		else
			PrintToChat(param1, "[SM] That player is no longer available.");
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
}

// Demote Commander Menu Handlers
public CMHandleDEMOTECommander(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Demote");
	
	else if (action == TopMenuAction_SelectOption)
	{
		Handle menu = CreateMenu(Handle_DemoteCommander_SelectTeam);
		SetMenuTitle(menu, "Demote Which Commander?");
		
		if (GameRules_GetPropEnt("m_hCommanders", 0) == -1)
			AddMenuItem(menu, "", "Consortium", ITEMDRAW_DISABLED);
		
		else
			AddMenuItem(menu, "0", "Consortium");
				
		if (GameRules_GetPropEnt("m_hCommanders", 1) == -1)
			AddMenuItem(menu, "1", "Empire", ITEMDRAW_DISABLED);
		
		else
			AddMenuItem(menu, "1", "Empire");
		
		DisplayMenu(menu, param, MENU_TIME_FOREVER);
	}
}

public Handle_DemoteCommander_SelectTeam(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:item[8];
		GetMenuItem(menu, param2, item, sizeof(item));
		new target = GameRules_GetPropEnt("m_hCommanders", StringToInt(item));
		
		if (target == -1)
			return;
		
		if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] You cannon target this client.");
			return;
		}
		
		PerformDemote(param1, GameRules_GetPropEnt("m_hCommanders", StringToInt(item)));
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
}
