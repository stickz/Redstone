#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name 		= "[ND] Resource Engine",
	author 		= "Stickz",
	description = "Creates forwards and natives for resources",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_resource_engine/nd_resource_engine.txt"
#include "updater/standard.sp"

Handle OnPrimeResDepleted;
bool bPrimeDepleted = false;
bool roundStarted = false;
int PrimeEntity = -1;

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);	
	HookEvent("round_win", Event_RoundEnd, EventHookMode_PostNoCopy);
	
	OnPrimeResDepleted = CreateGlobalForward("ND_OnPrimeDepleted", ET_Ignore, Param_Cell);	
	AddUpdaterLibrary(); // Add auto updater feature
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	PrimeEntity = FindEntityByClassname(-1, "nd_info_primary_resource_point");
	CreateTimer(30.0, TIMER_CheckPrimeDepleted, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	bPrimeDepleted = false;
	roundStarted = true;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
	roundStarted = false;
}

public Action TIMER_CheckPrimeDepleted(Handle timer)
{
	// Stop the timer, if the round is not started
	if (!roundStarted)
		return Plugin_Stop;
	
	// Get the current resources prime has left
	int curRes = GetEntProp(PrimeEntity, Prop_Send, "m_iCurrentResources");
	if (curRes <= 0)
	{				
		// When depleted... Fire forward, mark boolean and stop timer
		FirePrimeDepletedForward();
		bPrimeDepleted = true;
		return Plugin_Stop;
	}	
	
	return Plugin_Continue;
}

void FirePrimeDepletedForward()
{
	Action dummy;
	Call_StartForward(OnPrimeResDepleted);
	Call_PushCell(PrimeEntity);
	Call_Finish(dummy);
}

/* Natives */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_IsPrimeDepleted", Native_PrimeDepleted);	
	return APLRes_Success;
}

public int Native_PrimeDepleted(Handle plugin, int numParams) {
	return _:bPrimeDepleted;
}
