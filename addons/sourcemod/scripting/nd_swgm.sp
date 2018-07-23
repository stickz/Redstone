#include <SteamWorks>
#include <swgm>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "Steam Works Group Manager",
	author = "Someone, Stickz",
	description = "Additional features for plugins",
	version = "dummy",
	url = "https://github.com/stickz/Redstone/"
};

/* Auto Updater */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_swgm/nd_swgm.txt"
#include "updater/standard.sp"

Handle g_hForward_OnLeaveCheck, g_hForward_OnJoinCheck, g_hTimer = null;
bool g_bInGroup[MAXPLAYERS+1], g_bInGroupOfficer[MAXPLAYERS+1], g_bLeave[MAXPLAYERS+1];
int g_iGroupId, g_iAuthID[MAXPLAYERS+1];
Status g_PlayerStatus[MAXPLAYERS+1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] sError, int err_max)
{
	g_hForward_OnLeaveCheck = CreateGlobalForward("SWGM_OnLeaveGroup", ET_Ignore, Param_Cell);
	g_hForward_OnJoinCheck = CreateGlobalForward("SWGM_OnJoinGroup", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);

	CreateNative("SWGM_InGroup", Native_InGroup);
	CreateNative("SWGM_InGroupOfficer", Native_InGroupOfficer);
	CreateNative("SWGM_GetPlayerStatus", Native_GetPlayerStatus);
	CreateNative("SWGM_CheckPlayer", Native_CheckPlayer);
	CreateNative("SWGM_CheckPlayers", Native_CheckPlayers);

	RegPluginLibrary("SWGM");

	return APLRes_Success;
}

public void OnPluginStart()
{
	ConVar CVAR;

	char sBuffer[14];
	(CVAR = CreateConVar("swgm_groupid",		"25462375",	"Steam Group ID.")).AddChangeHook(OnGroupChange);
	CVAR.GetString(sBuffer, sizeof(sBuffer));
	g_iGroupId = StringToInt(sBuffer);
	
	(CVAR = CreateConVar("swgm_timer",		"60.0",	"Interval beetwen steam group checks.")).AddChangeHook(OnTimeChange);
	if(g_hTimer) KillTimer(g_hTimer); g_hTimer = null;
	g_hTimer = CreateTimer(CVAR.FloatValue, Check_Timer, _, TIMER_REPEAT);
	
	RegAdminCmd("swgm_check", CMD_Check, ADMFLAG_ROOT);
	RegAdminCmd("swgm_list", CMD_List, ADMFLAG_KICK);
	
	for(int i = 1; i <= MaxClients; i++)	if(IsClientInGame(i) && !IsFakeClient(i))
	{
		char sAuth[24];
		GetClientAuthId(i, AuthId_Steam2, sAuth, sizeof(sAuth));
		g_iAuthID[i] = StringToInt(sAuth[10])*2+(sAuth[8]-48);
		SteamWorks_GetUserGroupStatusAuthID(g_iAuthID[i], g_iGroupId);
	}
	
	AutoExecConfig(true, "nd_swgm");
	AddUpdaterLibrary(); //auto-updater
}

public void OnGroupChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	char sBuffer[14];
	convar.GetString(sBuffer, sizeof(sBuffer));
	g_iGroupId = StringToInt(sBuffer);
	for(int i = 1; i <= MaxClients; i++)
	{
		g_bInGroup[i] = false;
		g_bInGroupOfficer[i] = false;
		g_PlayerStatus[i] = UNASSIGNED;
		g_bLeave[i] = false;
	}
	Check();
}

public void OnTimeChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(g_hTimer) KillTimer(g_hTimer); g_hTimer = null;
	g_hTimer = CreateTimer(convar.FloatValue, Check_Timer, _, TIMER_REPEAT);
}

public Action Check_Timer(Handle hTimer)
{
	Check();
	return Plugin_Continue;
}

public Action CMD_Check(int iClient, int args)
{
	Check();
	ReplyToCommand(iClient, "All players checked.");
	return Plugin_Handled;
}

void Check()
{
	for (int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i) && !g_bLeave[i])
	{
		SteamWorks_GetUserGroupStatusAuthID(g_iAuthID[i], g_iGroupId);
	}
}

public Action CMD_List(int iClient, int args)
{
	char sAuth[24];
	int iCount, iCountInGroup, iCountNotInGroup;
	
	PrintToConsole(iClient, "+-----------------------------------------------------------------------------+");
	PrintToConsole(iClient, "=>> Players List:");
	PrintToConsole(iClient, "+-----------------------------------------------------------------------------+");

	for (int i = 1; i <= MaxClients; i++)	if(IsClientInGame(i) && !IsFakeClient(i))
	{
		iCount++;
		GetClientAuthId(i, AuthId_Steam2, sAuth, sizeof(sAuth));

		if(g_bInGroup[i])
		{
			PrintToConsole(iClient, "> %d. %N [%s] ==| In Group |==", iCount, i, sAuth);
			iCountInGroup++;
		}
		else
		{
			PrintToConsole(iClient, "> %d. %N [%s] ==| Not In A Group |==", iCount, i, sAuth);	
			iCountNotInGroup++;
		}
	}
	
	PrintToConsole(iClient, "+-----------------------------------------------------------------------------+");
	PrintToConsole(iClient, "=>> Total in group: %d | Total not in group: %d ", iCountInGroup, iCountNotInGroup);
	PrintToConsole(iClient, "+-----------------------------------------------------------------------------+");

	if(GetCmdReplySource() == SM_REPLY_TO_CHAT)
		PrintToChat(iClient, "[SWGM] Check console for result!");
	
	return Plugin_Handled;
}

public void OnClientDisconnect(int iClient)
{
	g_bInGroup[iClient] = false;
	g_bInGroupOfficer[iClient] = false;
	g_bLeave[iClient] = false;
	g_iAuthID[iClient] = 0;
	g_PlayerStatus[iClient] = UNASSIGNED;
}


public void OnClientPutInServer(int iClient)
{
	g_PlayerStatus[iClient] = NO_GROUP;
	if(IsClientInGame(iClient) && !IsFakeClient(iClient))
	{
		char sAuth[24];
		GetClientAuthId(iClient, AuthId_Steam2, sAuth, sizeof(sAuth));
		g_iAuthID[iClient] = StringToInt(sAuth[10])*2+(sAuth[8]-48);
		SteamWorks_GetUserGroupStatusAuthID(g_iAuthID[iClient], g_iGroupId);
	}
}

public int SteamWorks_OnClientGroupStatus(int iAuth, int iGroupID, bool isMember, bool isOfficer)
{
	static int iClient;
	if(iGroupID == g_iGroupId && (iClient = GetUserFromAuthID(iAuth)) > 0)
	{
		if(g_bInGroup[iClient] && !g_bLeave[iClient] && !isMember)
		{
			g_bInGroup[iClient] = false;
			g_bLeave[iClient] = true;
			Forward_OnLeaveCheck(iClient);
			if(g_bInGroupOfficer[iClient] && !isOfficer) g_bInGroupOfficer[iClient] = false;
			g_PlayerStatus[iClient] = LEAVER;
		}
		else if(!g_bInGroup[iClient] && !g_bLeave[iClient] && isMember)
		{
			g_bInGroup[iClient] = true;
			
			if(isOfficer)
			{
				g_bInGroupOfficer[iClient] = true;	
				g_PlayerStatus[iClient] = OFFICER;
			}
			else	g_PlayerStatus[iClient] = MEMBER;
			Forward_OnJoinCheck(iClient, isOfficer);
		}
	}
}

public int GetUserFromAuthID(int iAuth)
{
	for (int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i))
    {
		if(g_iAuthID[i] == iAuth)
		{
			return i;
		}
	}
	return -1;
}

public int Native_InGroup(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	
	char sError[64];
	if (!CheckClient(iClient, sError, sizeof(sError)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, sError);
	}
	
	return g_bInGroup[iClient];
}

public int Native_InGroupOfficer(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	
	char sError[64];
	if (!CheckClient(iClient, sError, sizeof(sError)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, sError);
	}
	
	return g_bInGroupOfficer[iClient];
}

public int Native_GetPlayerStatus(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	
	char sError[64];
	if (!CheckClient(iClient, sError, sizeof(sError)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, sError);
	}

	return view_as<int>(g_PlayerStatus[iClient]);
}

public int Native_CheckPlayer(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	
	char sError[64];
	if (!CheckClient(iClient, sError, sizeof(sError)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, sError);
	}
	
	SteamWorks_GetUserGroupStatusAuthID(g_iAuthID[iClient], g_iGroupId);
}

public int Native_CheckPlayers(Handle hPlugin, int iNumParams)
{
	Check();
}

void Forward_OnLeaveCheck(int iClient)
{
	Call_StartForward(g_hForward_OnLeaveCheck);
	Call_PushCell(iClient);
	Call_Finish();
}

void Forward_OnJoinCheck(int iClient, bool Officer)
{
	Call_StartForward(g_hForward_OnJoinCheck);
	Call_PushCell(iClient);
	Call_PushCell(Officer);
	Call_Finish();
}

bool CheckClient(int iClient, char[] sError, int iLength)
{
	if (iClient < 1 || iClient > MaxClients)
	{
		FormatEx(sError, iLength, "iClient index %i is invalid", iClient);
		return false;
	}
	else if (!IsClientInGame(iClient))
	{
		FormatEx(sError, iLength, "iClient index %i is not in game", iClient);
		return false;
	}
	else if (IsFakeClient(iClient))
	{
		FormatEx(sError, iLength, "iClient index %i is a bot", iClient);
		return false;
	}
	
	sError[0] = '\0';

	return true;
}
