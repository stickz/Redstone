#define SCORE_BASED_MULTIPLIER 100.0
#define MIN_ADJUSTMENT_CLIENT_COUNT 6
#define LOW_SPM_ADJUST_REGARDLESS 1000
#define REQUIRED_MINS_FOR_ADJUSTMENT 5
#define ROOKIE_ADJUST_AT_MINUTE 15
#define BOMBER_ADJUST_AT_MINUTE 6
#define VETERAN_IS_BOMBING 1.5
#define ROOKIE_SKILL_ADJUSTMENT 1.25

int	connectionTime[MAXPLAYERS+1] = {-1, ...};
int	scorePerMinute[MAXPLAYERS+1] = {-1, ...};
int	previousTeam[MAXPLAYERS+1] = {-1, ...};
float newPlayerSkill[MAXPLAYERS+1] = {-1.0, ...};

/*Update Score per Minute Data */
public Action TIMER_updateSPM(Handle timer)
{
	UpdateSPM();
	
	if (g_Bool[adjustedRookie])
	{
		g_Bool[tdChange] = true;
		g_Bool[adjustedRookie] = false;
	}
	
	return Plugin_Continue;
}

void startSPMTimer() {
	CreateTimer(60.0, TIMER_updateSPM, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	
}

void UpdateSPM()
{
	int clientScore;
	int	spmAverage[2];
	int cTeamM2;
	float SPM;
	float cSkill;
	bool useAdjustment[2];

	useAdjustment[CONSORT_aIDX] = getTeamCountByMinutes(TEAM_CONSORT, REQUIRED_MINS_FOR_ADJUSTMENT) >= MIN_ADJUSTMENT_CLIENT_COUNT;
	useAdjustment[EMPIRE_aIDX] = getTeamCountByMinutes(TEAM_EMPIRE, REQUIRED_MINS_FOR_ADJUSTMENT) >= MIN_ADJUSTMENT_CLIENT_COUNT;

	spmAverage[CONSORT_aIDX] = getSPMaverage(TEAM_CONSORT);
	spmAverage[EMPIRE_aIDX] = getSPMaverage(TEAM_EMPIRE);		
	
	RED_LOOP_CLIENTS(client)
	{
		if (isOnTeam(client) && !ND_IsCommander(client))
		{
			connectionTime[client]++;
			if (connectionTime[client] >= 1)
			{
				/* Update client's score per minute each minute */
				clientScore = ND_RetrieveScore(client);
				SPM = (float(clientScore) / float(connectionTime[client])) * SCORE_BASED_MULTIPLIER;
				scorePerMinute[client] = RoundFloat(SPM);
				cSkill = GetSkillLevel(client);
				
				
				/* Check if a rookie needs to be adjusted */
				if (cSkill <= lastAverage / ROOKIE_SKILL_ADJUSTMENT && !g_isSkilledRookie[client])
				{
					cTeamM2 = GetClientTeam(client) -2;
					if (connectionTime[client] >= ROOKIE_ADJUST_AT_MINUTE && useAdjustment[cTeamM2])
					{
						if (scorePerMinute[client] >= spmAverage[cTeamM2])
						{
							g_isSkilledRookie[client] = true;			
							g_Bool[adjustedRookie] = true;
							
							#if _DEBUG
							PrintToAdmins("debug: adjusted skill level of a rookie", "a");
							#endif
						}
					}
				}
				
				/* Check if a veteran needs to be adjusted */
				else if (cSkill > lastAverage * ROOKIE_SKILL_ADJUSTMENT)
				{
					cTeamM2 = GetClientTeam(client) -2;
					
					if (connectionTime[client] >= ROOKIE_ADJUST_AT_MINUTE && (useAdjustment[cTeamM2] || scorePerMinute[client] < LOW_SPM_ADJUST_REGARDLESS)){
						if (scorePerMinute[client] <= spmAverage[cTeamM2] / VETERAN_IS_BOMBING)
						{
							MakeVetSkillAdjust(client);
							newPlayerSkill[client] = lastAverage;
						}
					}

					else if (connectionTime[client] >= BOMBER_ADJUST_AT_MINUTE && scorePerMinute[client] < LOW_SPM_ADJUST_REGARDLESS){
						if (cSkill > lastAverage * ROOKIE_SKILL_ADJUSTMENT)
						{
							MakeVetSkillAdjust(client);
							
							// Calulate the average score multiplier, if it's negative make it positive
							float avgScore = float(scorePerMinute[client]) / float(spmAverage[cTeamM2]);
							newPlayerSkill[client] = lastAverage * Math_Abs(avgScore);
						}
					}
				}
			}
		}
	}
}

void MakeVetSkillAdjust(int client)
{
	g_isWeakVeteran[client] = true;		
	g_Bool[adjustedRookie] = true;
	#if _DEBUG
	PrintToAdmins("debug: adjusted skill level of a veteran", "a");
	#endif	
}

int getTeamCountByMinutes(int team, int mins)
{
	int count;
	RED_LOOP_CLIENTS(client)
	{
		if (previousTeam[client] == team && connectionTime[client] >= mins)
			count++;
	}
	return count;
}

int getSPMaverage(int team)
{
	int score, count;
	RED_LOOP_CLIENTS(client)
	{
		if (previousTeam[client] == team)
			if (scorePerMinute[client] != -1)
			{
				score += scorePerMinute[client];
				count++;
			}
	}
	return count > 0 ? score / count : -1;
}