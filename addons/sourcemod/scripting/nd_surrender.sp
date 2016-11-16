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
#include <nd_stocks>
#include <nd_redstone>


/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_surrender/nd_surrender.txt"
#include "updater/standard.sp"

enum Bools
{
	enableSurrender,
	hasSurrendered,
	roundHasEnded
};

new voteCount[2],	
	bool:g_Bool[Bools],
	bool:g_hasVotedEmpire[MAXPLAYERS+1] = {false, ... },
	bool:g_hasVotedConsort[MAXPLAYERS+1] = {false, ... },
	Handle:SurrenderDelayTimer = INVALID_HANDLE;

#define TEAM_SPEC			1
#define TEAM_CONSORT		2
#define TEAM_EMPIRE			3

#define SURRENDER_MIN_PLAYERS 4

#define VERSION "1.1.4"

public Plugin:myinfo =
{
	name = "Surrender Feature",
	author = "Stickz",
	description = "Allow alternative methods of surrendering.",
	version = VERSION,
	url = "N/A"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_surrender", CMD_Surrender);
	AddCommandListener(PlayerJoinTeam, "jointeam");
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("timeleft_5s", Event_TimeLimit, EventHookMode_PostNoCopy);
	
	LoadTranslations("nd_surrender.phrases"); //for all chat messages
	LoadTranslations("numbers.phrases"); //for one,two,three etc.
	
	AddUpdaterLibrary(); //add updater support
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	voteCount[0] = 0;
	voteCount[1] = 0;
	
	//if (SurrenderDelayTimer != INVALID_HANDLE)
	//	CloseHandle(SurrenderDelayTimer);

	SurrenderDelayTimer = CreateTimer(480.0, TIMER_surrenderDelay, _, TIMER_FLAG_NO_MAPCHANGE);
	
	g_Bool[enableSurrender] = false;
	g_Bool[hasSurrendered] = false;
	g_Bool[roundHasEnded] = false;
	for (new client = 1; client <= MaxClients; client++)
	{
		g_hasVotedEmpire[client] = false;
		g_hasVotedConsort[client] = false;	
	}
}

public Event_TimeLimit(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_Bool[roundHasEnded])
		roundEnd();
}

public Action:OnClientSayCommand(client, const String:command[], const String:sArgs[])
{
	if (client)
	{
		if (strcmp(sArgs, "surrender", false) == 0 || strcmp(sArgs, "SURRENDER", false) == 0) 
		{
			new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);

			callSurrender(client);
				
			SetCmdReplySource(old);
			return Plugin_Stop;				
		}
	}	
	return Plugin_Continue;
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_Bool[roundHasEnded])
		roundEnd();
}

roundEnd()
{
	if (!g_Bool[roundHasEnded])
	{
		if (!g_Bool[enableSurrender] && SurrenderDelayTimer != INVALID_HANDLE)
			CloseHandle(SurrenderDelayTimer);

		g_Bool[roundHasEnded] = true;
	}
}

/*public OnMapStart()
{
	g_Integer[consortCount] = 0;
	g_Integer[empireCount] = 0;
	CreateTimer(480.0, TIMER_surrenderDelay);
	g_Bool[enableSurrender] = false;
	g_Bool[hasSurrendered] = false;
}*/

public Action:PlayerJoinTeam(client, String:command[], argc)
{
	resetValues(client);	
	return Plugin_Continue;
}

public Action:CMD_Surrender(client, args)
{
	callSurrender(client);
	return Plugin_Handled;
}

public OnClientDisconnect(client)
{
	resetValues(client);
}

public Action:TIMER_surrenderDelay(Handle:timer)
{
	g_Bool[enableSurrender] = true;
	//if (SurrenderDelayTimer != INVALID_HANDLE)
	//	CloseHandle(SurrenderDelayTimer);
}

public Action:TIMER_DisplaySurrender(Handle:timer, any:team)
{
	switch (team)
	{
		case TEAM_CONSORT: PrintToChatAll("\x05%t!", "Consort Surrendered");
		case TEAM_EMPIRE: PrintToChatAll("\x05%t!", "Empire Surrendered");	
	}
}

callSurrender(client)
{
	new team = GetClientTeam(client),
		teamCount = RED_GetTeamCount(team);
	
	if (teamCount < SURRENDER_MIN_PLAYERS)
		PrintToChat(client, "\x05[xG] %t!", "Four Required");

	else if (!g_Bool[enableSurrender])
		PrintToChat(client, "\x05[xG] %t", "Too Soon");
	
	else if (g_Bool[hasSurrendered])
		PrintToChat(client, "\x05[xG] %t!", "Team Surrendered");
	
	else if (team < 2)
		PrintToChat(client, "\x05[xG] %t!", "On Team");
	
	else if (g_hasVotedEmpire[client] || g_hasVotedConsort[client])
		PrintToChat(client, "\x05[xG] %t!", "You Surrendered");
	
	else if (g_Bool[roundHasEnded])
		PrintToChat(client, "\x05[xG] %t!", "Round Ended");

	else
	{
		new teamIDX = team -2,
			Float:teamFloat = teamCount * 0.51;
			
		if (teamFloat < 4.0)
			teamFloat = 4.0;
			
		voteCount[teamIDX]++;		
		
		new Remainder = RoundToCeil(teamFloat) - voteCount[teamIDX];
		
		if (Remainder <= 0)
			endGame(team);
		else
			displayVotes(team, Remainder, client);
		
		switch (team)
		{
			case TEAM_CONSORT: g_hasVotedConsort[client] = true;
			case TEAM_EMPIRE: g_hasVotedEmpire[client] = true;
		}
	}
}

checkQuitSurrender(team)
{
	new Float:teamFloat = ValidTeamCount(team) * 0.51;
		
	new Remainder = RoundToCeil(teamFloat) - voteCount[team -2];
		
	if (Remainder <= 0)
		endGame(team);
}

resetValues(client)
{
	new team;
	
	if (g_hasVotedConsort[client])
	{
		team = TEAM_CONSORT;
		g_hasVotedConsort[client] = false;
	}
	else if (g_hasVotedEmpire[client])
	{
		team = TEAM_EMPIRE;
		g_hasVotedEmpire[client] = false;
	}
	
	if (team > TEAM_SPEC)
	{
		voteCount[team - 2]--;
		if (RED_ClientCount() < SURRENDER_MIN_PLAYERS && !g_Bool[roundHasEnded] && !g_Bool[hasSurrendered])
			checkQuitSurrender(TEAM_CONSORT);
	}
}

endGame(team)
{
	g_Bool[hasSurrendered] = true;
	ServerCommand("mp_roundtime 1");
	
	CreateTimer(0.5, TIMER_DisplaySurrender, team, TIMER_FLAG_NO_MAPCHANGE);	
}

displayVotes(team, Remainder, client)
{	
	decl String:name[64];
	GetClientName(client, name, sizeof(name));
	
	decl String:number[32];
	Format(number, sizeof(number), NumberInEnglish(Remainder));
	
	for (new idx = 1; idx <= MaxClients; idx++)
	{
		if (IsValidClient(idx) && GetClientTeam(idx) == team)
			PrintToChat(idx, "\x05%t", "Typed Surrender", name, number);		
	
		//PrintToChat(idx, "\x05%s typed surrender: %s more required.", name, NumberInEnglish(Remainder));
	}
}
