void RegTestCommands()
{
	RegAdminCmd("sm_kdrmult", CMD_GetKdrMult, ADMFLAG_GENERIC, "Checks a player's kdr multipler");
	RegAdminCmd("sm_hpkmult", CMD_GetHpkMult, ADMFLAG_GENERIC, "Checks a player's hpk multipler");
		
	RegConsoleCmd("sm_DumpPlayerSkill", CMD_DumpPlayerData);
	RegConsoleCmd("sm_DumpPlayerData", CMD_DumpPlayerData);
	RegConsoleCmd("sm_DumpPlayerBase", CMD_DumpPlayerBase);
}

public Action CMD_GetKdrMult(int client, int args)
{
	char player[64];
	GetCmdArg(1, player, sizeof(player));
	
	int target = FindTarget(client, player, true, true);
	if (target == -1)
	{
		ReplyToCommand(client, "Invalid target.");
		return Plugin_Handled;	
	}	
	
	float kdr = GameME_GetKpdFactor(target) * 100;
	
	char cName[64];
	GetClientName(target, cName, sizeof(cName));
	
	PrintToChat(client, "%s's kdr multipler is %d percent", cName, RoundFloat(kdr));
	
	return Plugin_Handled;
}

public Action CMD_GetHpkMult(int client, int args)
{
	char player[64];
	GetCmdArg(1, player, sizeof(player));
	
	int target = FindTarget(client, player, true, true);
	if (target == -1)
	{
		ReplyToCommand(client, "Invalid target.");
		return Plugin_Handled;	
	}	
	
	float kdr = GameME_GetHpkFactor(target) * 100;
	
	char cName[64];
	GetClientName(target, cName, sizeof(cName));
	
	PrintToChat(client, "%s's hpk multipler is %d percent", cName, RoundFloat(kdr));
	
	return Plugin_Handled;
}

/* Functions for !DumpPlayerData */
public Action CMD_DumpPlayerData(int client, int args)
{
	DumpPlayerData(client);
	return Plugin_Handled;
}

void DumpPlayerData(int player)
{
	PrintSpacer(player); PrintSpacer(player);
	
	PrintToConsole(player, "--> GameMe/SteamWorks Skill Values <--");
	PrintToConsole(player, "Format: Name, GameMe Skill, KDR Ratio, HPK Ratio");
	PrintSpacer(player);
	
	for (int team = 0; team < 4; team++)
	{
		if (RED_GetTeamCount(team) > 0)
		{
			PrintToConsole(player, "Team %s:", ND_GetTeamName(team));
			dumpPlayersOnTeam(team, player);
			PrintSpacer(player);
		}
	}
}

void dumpPlayersOnTeam(int team, int player)
{	
	char Name[32]; char kdr[5]; char hpk[6]; int gmSkill; //int swSkill;
	for (int client; client <= MaxClients; client++)
	{
		if (RED_IsValidClient(client) && GetClientTeam(client) == team)
		{
			GetClientName(client, Name, sizeof(Name));		
			
			FloatToString(trFloat(GameME_KDR[client]), kdr, sizeof(kdr));
			FloatToString(trFloat(GameME_HPK[client]), hpk, sizeof(hpk));
			
			gmSkill = RoundFloat(GameME_FinalSkill[client]);
			
			PrintToConsole(player, "Name: %s, gSkill: %d, KDR: %s, HPK, %s", Name, gmSkill, kdr, hpk);
		}
	}
}

void PrintSpacer(int player) {
	PrintToConsole(player, "");
}

float trFloat(float f) {	
	return (float(RoundFloat(f * 100.0))) / 100.0;
}

/* Functions for !DumpPlayerBase */
public Action CMD_DumpPlayerBase(int client, int args)
{
	DumpPlayerBase(client);
	return Plugin_Handled;
}

void DumpPlayerBase(int player)
{
	PrintSpacer(player); PrintSpacer(player);
	
	PrintToConsole(player, "--> Player Base Skill Values <--");
	PrintToConsole(player, "Format: Name, Reg Base, HPK Base");
	PrintSpacer(player);
	
	for (int team = 0; team < 4; team++)
	{
		if (RED_GetTeamCount(team) > 0)
		{
			PrintToConsole(player, "Team %s:", ND_GetTeamName(team));
			dumpPlayBasesOnTeam(team, player);
			PrintSpacer(player);
		}
	}
}

void dumpPlayBasesOnTeam(int team, int player)
{	
	char Name[32]; int oBase; int nBase;
	for (int client; client <= MaxClients; client++)
	{
		if (RED_IsValidClient(client) && GetClientTeam(client) == team)
		{
			GetClientName(client, Name, sizeof(Name));
			
			oBase = RoundFloat(GameME_SkillBase[client]);
			nBase = RoundFloat(GameME_GetModifiedSkillBase(client));
			
			PrintToConsole(player, "Name: %s, Reg Base: %d, Hpk Base, %d", Name, oBase, nBase);
		}
	}
}
