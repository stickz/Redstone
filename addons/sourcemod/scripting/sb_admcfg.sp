// *************************************************************************
//  sb_admcfg is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, per version 3 of the License.
//  
//  sb_admcfg is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//  
//  You should have received a copy of the GNU General Public License
//  along with sb_admcfg. If not, see <http://www.gnu.org/licenses/>.
//
//  This file is based off work covered by the following copyright(s):   
//
//   SourceMod Admin File Reader Plugin
//   Copyright (C) 2004-2008 AlliedModders LLC
//   Licensed under GNU GPL version 3
//   Page: <http://www.sourcemod.net/>
//
//   SourceBans++
//   Copyright (C) 2014-2016 Sarabveer Singh <me@sarabveer.me
//   Licensed under GNU GPL version 3, or later.
//   Page: <https://forums.alliedmods.net/showthread.php?t=263735> - <https://github.com/sbpp/sourcebans-pp>
// *************************************************************************

#pragma semicolon 1

#include <sourcemod>

/* Auto Updater Suport */
#define UPDATE_URL  	"https://github.com/stickz/Redstone/raw/build/updater/sb_admcfg/sb_admcfg.txt"
#include 		"updater/standard.sp"

public Plugin myinfo = 
{
	name = "SourceBans: Admin Config Loader", 
	author = "AlliedModders LLC, Sarabveer(VEER™)", 
	description = "Reads Admin Files", 
	version = "dummy", 
	url = "https://github.com/Sarabveer/SourceBans-Fork"
};

/** Various parsing globals */
bool g_LoggedFileName = false; /* Whether or not the file name has been logged */
int g_ErrorCount = 0; /* Current error count */
int g_IgnoreLevel = 0; /* Nested ignored section count, so users can screw up files safely */
int g_CurrentLine = 0; /* Current line we're on */
char g_Filename[PLATFORM_MAX_PATH]; /* Used for error messages */

#include "sb_admcfg/sb_admin_groups.sp"
#include "sb_admcfg/sb_admin_users.sp"

public void OnPluginStart()
{
	AddUpdaterLibrary(); //auto-updater
}

#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 7
public int OnRebuildAdminCache(AdminCachePart part)
#else
public void OnRebuildAdminCache(AdminCachePart part)
#end
{
	if (part == AdminCache_Groups) 
		ReadGroups();
		
	else if (part == AdminCache_Admins) 
		ReadUsers();
}

void ParseError(const char[] format, any...)
{
	char buffer[512];

	if (!g_LoggedFileName)
	{
		LogError("Error(s) Detected Parsing %s", g_Filename);
		g_LoggedFileName = true;
	}
	
	VFormat(buffer, sizeof(buffer), format, 2);
	
	LogError(" (line %d) %s", g_CurrentLine, buffer);
	
	g_ErrorCount++;
}

void InitGlobalStates()
{
	g_ErrorCount = 0;
	g_IgnoreLevel = 0;
	g_CurrentLine = 0;
	g_LoggedFileName = false;
}
