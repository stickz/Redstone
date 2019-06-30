#include <sourcemod>

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
bool bPrimeDepleted;

public void OnPluginStart()
{
	HookEvent("resource_extract", Event_ResourceExtract, EventHookMode_PostNoCopy);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	
	OnPrimeResDepleted = CreateGlobalForward("ND_OnPrimeDepleted", ET_Ignore, Param_Cell);
	
	AddUpdaterLibrary(); // Add auto updater feature
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
	bPrimeDepleted = false;
}

public Action Event_ResourceExtract(Event event, const char[] name, bool dontBroadcast)
{
	if (!bPrimeDepleted)
	{
		int entity = event.GetInt("entindex");
		
		char resName[64];
		GetEntityClassname(entity, resName, sizeof(resName));
		
		if (StrEqual(resName, "nd_info_primary_resource_point", true))
		{
			int curRes = GetEntProp(entity, Prop_Send, "m_iCurrentResources");			
			if (curRes <= 0)
			{				
				FirePrimeDepletedForward(entity);
				bPrimeDepleted = true;
			}		
		}
	}
}

void FirePrimeDepletedForward(int entity)
{
	Action dummy;
	Call_StartForward(OnPrimeResDepleted);
	Call_PushCell(entity);
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