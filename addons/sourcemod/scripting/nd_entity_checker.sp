#include <sourcemod>
#include <sdktools>
#include <nd_struct_eng>
#include <nd_stocks>

public Plugin myinfo =
{
	name = "[ND] Entity Checker",
	author = "Xander",
	description = "Displays info on entity in crosshair.",
	version = "dummy",
	url = "https://github.com/stickz/Redstone"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_entity_checker/nd_entity_checker.txt"
#include "updater/standard.sp"

public OnPluginStart() 
{
	RegAdminCmd("sm_entinfo", sm_entinfo, ADMFLAG_KICK, "Prints info about the target entity");
	RegAdminCmd("sm_entinfoex", sm_entinfoex, ADMFLAG_KICK, "Prints info about the target entity");
	RegAdminCmd("sm_entinfost", sm_entinfost, ADMFLAG_KICK, "Prints info about the target transport gate");
	RegAdminCmd("sm_entinfoall", sm_entinfoall, ADMFLAG_KICK, "Prints a list of all structure entities to console");
	RegAdminCmd("sm_tgemp", sm_tgemp, ADMFLAG_KICK, "Prints a list of all transport gates on empire to console");
	AddUpdaterLibrary(); //auto-updater
}

public Action:sm_entinfo(client, argc)
{
	if (!client)
	{
		ReplyToCommand(client, "Player only.");
		return Plugin_Handled;
	}
	
	int target = GetClientAimTarget(client, false);
		
	if (target < 0)
		ReplyToCommand(client, "Nothing targeted");

	else
	{
		char entity_classname[64];
		char entity_name[64];
		float entity_origin[3];
		float entity_angles[3];
		
		GetEntityClassname(target, entity_classname, 64);
		GetEntPropString(target, Prop_Data, "m_iName", entity_name, 64);
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", entity_origin);
		GetEntPropVector(target, Prop_Send, "m_angRotation", entity_angles);
		
		ReplyToCommand(client, "classname = %s", entity_classname);
		ReplyToCommand(client, "name = %s", entity_name);
		ReplyToCommand(client, "Origin = %f, %f, %f", entity_origin[0], entity_origin[1], entity_origin[2]);
		ReplyToCommand(client, "Angles = %f, %f, %f", entity_angles[0], entity_angles[1], entity_angles[2]);
	}
	
	return Plugin_Handled;
}

public Action:sm_entinfoex(client, argc)
{
	if (!client)
	{
		ReplyToCommand(client, "Player only.");
		return Plugin_Handled;
	}
	
	int target = GetClientAimTarget(client, false);
		
	if (target < 0)
		ReplyToCommand(client, "Nothing targeted");

	else
	{
		char entity_classname[32];
		float entity_origin[3];
		int type;
		
		ND_GetBuildingInfo(target, type, entity_origin, entity_classname);	
		ReplyToCommand(client, "classname = %s", entity_classname);
		ReplyToCommand(client, "Origin = %f, %f, %f", entity_origin[0], entity_origin[1], entity_origin[2]);
	}
	
	return Plugin_Handled;
}

public Action:sm_entinfost(client, argc)
{
	if (!client)
	{
		ReplyToCommand(client, "Player only.");
		return Plugin_Handled;
	}
	
	int target = GetClientAimTarget(client, false);
		
	if (target < 0)
		ReplyToCommand(client, "Nothing targeted");

	else
	{
		char entity_classname[32];
		float entity_origin[3];
		
		ND_GetBuildingInfoType(view_as<int>(ND_Transport_Gate), target, entity_origin, entity_classname);	
		ReplyToCommand(client, "classname = %s", entity_classname);
		ReplyToCommand(client, "Origin = %f, %f, %f", entity_origin[0], entity_origin[1], entity_origin[2]);
	}
	
	return Plugin_Handled;
}

public Action:sm_entinfoall(client, argc)
{
        ArrayList buildings;
        ND_GetBuildInfoArray(buildings);
        
        PrintToConsole(client, "**** Building List ****");
        PrintToConsole(client, "");
        
        for (int i = 0; i < buildings.Length; i++)
        {
                BuildingEntity ent;
                buildings.GetArray(i, ent);
                PrintToConsole(client, "%s", ent.classname);
        }
        
        return Plugin_Handled;
}

public Action:sm_tgemp(client, argc)
{
        ArrayList buildings;
        ND_GetBuildInfoArrayTypeTeam(buildings, view_as<int>(ND_Transport_Gate), TEAM_EMPIRE);
        
        PrintToConsole(client, "**** Empire TG List ****");
        PrintToConsole(client, "");
        
        for (int i = 0; i < buildings.Length; i++)
        {
                BuildingEntity ent;
                buildings.GetArray(i, ent);
                PrintToConsole(client, "%s", ent.classname);
        }
        
        return Plugin_Handled;
}
