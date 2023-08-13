#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = 
{
	name            = "[ND] Tick Engine",
	author          = "Stickz",
	description     = "Creates forwards for ticking and movement",
	version         = "dummy",
	url             = "https://github.com/stickz/Redstone/"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_tick_engine/nd_tick_engine.txt"
#include "updater/standard.sp"

GlobalForward OnRunCmdFakeClient;
GlobalForward OnRunCmdRealClient;

public void OnPluginStart()
{
        CreateRunForwards();
        AddUpdaterLibrary(); // Add auto updater feature
}

void CreateRunForwards()
{
        OnRunCmdFakeClient = CreateGlobalForward("ND_OnFakeClientRunCmd", ET_Ignore, Param_Cell, Param_CellByRef, Param_CellByRef, Param_Array, Param_Array,
                                                 Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_Array);
	                                             
        OnRunCmdRealClient = CreateGlobalForward("ND_OnRealClientRunCmd", ET_Ignore, Param_Cell, Param_CellByRef, Param_CellByRef, Param_Array, Param_Array,
                                                 Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_Array);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
        if (client)
        {
                bool fake = IsFakeClient(client);
                FireRunForward(fake, client, buttons, impulse, vel, angles, weapon, subtype, cmdnum, tickcount, seed, mouse);
                return Plugin_Continue;
        }
        
        return Plugin_Continue;
}

void FireRunForward(bool fake, int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
        Action dummy;
        Call_StartForward(fake ? OnRunCmdFakeClient: OnRunCmdRealClient);
        Call_PushCell(client);
        Call_PushCellRef(buttons);
        Call_PushCellRef(impulse);
        Call_PushArrayEx(vel, sizeof(vel), SM_PARAM_COPYBACK);
        Call_PushArrayEx(angles, sizeof(angles), SM_PARAM_COPYBACK);
        Call_PushCellRef(weapon);
        Call_PushCellRef(subtype);
        Call_PushCellRef(cmdnum);
        Call_PushCellRef(tickcount);
        Call_PushCellRef(seed);
        Call_PushArrayEx(mouse, sizeof(mouse), SM_PARAM_COPYBACK);
        Call_Finish(dummy);
}
