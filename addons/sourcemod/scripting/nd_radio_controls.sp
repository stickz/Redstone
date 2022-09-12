#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <sourcecomms>
#include <nd_rounds>

public Plugin:myinfo = 
{
	name = "[ND] Radio Control",
	author = "databomb, stickz",
	description = "Blocks default sounds and prevents radio spam",
	version = "dummy",
	url = "https://github.com/stickz/Redstone/"
}

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_radio_controls/nd_radio_controls.txt"
#include "updater/standard.sp"

int enemySpottedCount;
int enemySpottedTolerance = 15;
bool enemySpottedDisabled = false;

int last_radio_use[MAXPLAYERS+1];
int note[MAXPLAYERS+1];

enum struct convars
{
	 ConVar block;
	 ConVar block_time;
	 ConVar block_all;
	 ConVar block_notify;
}

convars cvar_radio_spam;
bool g_IsRadioBlocked[MAXPLAYERS+1] = {false, ... };

public OnPluginStart()
{
	cvar_radio_spam.block		 	= CreateConVar("sm_radio_spam_block", "1", "0 = disabled, 1 = enabled Radio Spam Block functionality", _, true, 0.0, true, 1.0);
	cvar_radio_spam.block_time 		= CreateConVar("sm_radio_spam_block_time", "5", "Time in seconds between radio messages", _, true, 1.0, true, 60.0);
	cvar_radio_spam.block_all 		= CreateConVar("sm_radio_spam_block_all", "0", "0 = disabled, 1 = block all radio messages", _, true, 0.0, true, 1.0);
	cvar_radio_spam.block_notify 	= CreateConVar("sm_radio_spam_block_notify", "1", "0 = disabled, 1 = show a chat message to the player when his radio spam blocked", _, true, 0.0, true, 1.0);
	
	for (new i = 0; i < MaxClients; i++)
	{
		last_radio_use[i] = -1;
	}
	
	AddCommandListener(RestrictRadio, "vocalize");
	
	HookUserMessage(GetUserMessageId("SendAudio"), Message_SendAudio, true);
	RegAdminCmd("sm_radioblock", Command_RadioBlock, ADMFLAG_KICK, "Blocks client from using radio");
	
	LoadTranslations("nd_radio_controls.phrases");
	
	AddUpdaterLibrary(); //auto-updater
}

public void ND_OnRoundStarted() {
	CreateTimer(900.0, TIMER_ResetEnemySpottedCount, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action TIMER_ResetEnemySpottedCount(Handle timer)
{
	if (!enemySpottedDisabled)
	{
		enemySpottedCount = enemySpottedCount > 10 ? 5 : 0;
		return Plugin_Continue;
	}
	else
		return Plugin_Handled;
}

public void OnMapEnd()
{
	enemySpottedCount = 0;
	enemySpottedTolerance = 15;
	enemySpottedDisabled = false;
}

public Action Command_RadioBlock(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_radioblock <player>");
		return Plugin_Handled;
	}
	
	char arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	int	target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client, 
			target_list, 
			MAXPLAYERS, 
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i++)
	{
		int target = target_list[i];
		PerformRadioBlock(target);
	}
	return Plugin_Handled;
}

void PerformRadioBlock(int target) {
	g_IsRadioBlocked[target] = !g_IsRadioBlocked[target];
}

public void OnClientDisconnect(client) {
	g_IsRadioBlocked[client] = false;
}

public Action Message_SendAudio(UserMsg:msg_hd, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	char sUserMessage[400];
	BfReadString(bf, sUserMessage, sizeof(sUserMessage));
	
	if (StrContains(sUserMessage, "potte") != -1)
	{
		enemySpottedCount++;
		
		if (isSilencedClientPresent())
			return Plugin_Handled;
		
		if (enemySpottedCount >= enemySpottedTolerance)
		{
			if (!enemySpottedDisabled)
				enemySpottedDisabled = true;		
		}			
	}
	
	return Plugin_Continue;		
}

public Action RestrictRadio(int client, const char[] command, int args)
{
	if (IsSourceCommSilenced(client))
		return Plugin_Handled;
	
	if (g_IsRadioBlocked[client])
		return Plugin_Handled;
	
	if (cvar_radio_spam.block.BoolValue)
		return Plugin_Continue;
	
	bool notify = cvar_radio_spam.block_notify.BoolValue;
	
	if(cvar_radio_spam.block_all.BoolValue)
	{		
		if (notify)
			PrintToChat(client, "\x05[xG] %t", "Radio Disabled");

		return Plugin_Handled;		
	}
	
	if (last_radio_use[client] == -1)
	{
		last_radio_use[client] = GetTime();
		return Plugin_Continue;
	}
	
	int time = GetTime() - last_radio_use[client];
	int blockTime = cvar_radio_spam.block_time.IntValue;
	if ( time >= blockTime )
	{
		last_radio_use[client] = GetTime();
		return Plugin_Continue;
	}
	
	int wait_time = blockTime - time;
		
	if ( (note[client] != wait_time) && notify)
	{
		new wTime = wait_time <= 1 ? 1 : wait_time;
		PrintToChat(client, "\x05[xG] %t", "Radio Wait", wTime);
	}
		//PrintToChat(client, "\x05[xG] Please wait %d seconds before the next message.", wait_time <= 1 ? 1 : wait_time);
	
	note[client] = wait_time;
	return Plugin_Handled;
}

bool isSilencedClientPresent()
{
	if (!SOURCECOMMS_LOADED())
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && g_IsRadioBlocked[i])
				return true;
		}
		
		return false;
	}
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && (IsSourceCommSilenced(client) || g_IsRadioBlocked[client]))
			return true;	
	}
	
	return false;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("SourceComms_SetClientMute");
	MarkNativeAsOptional("SourceComms_SetClientGag");
	MarkNativeAsOptional("SourceComms_GetClientMuteType");
	MarkNativeAsOptional("SourceComms_GetClientGagType");

	return APLRes_Success;	
}