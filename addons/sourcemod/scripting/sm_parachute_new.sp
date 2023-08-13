#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

//Parachute Model
#define PARACHUTE_MODEL		"parachute_carbon"

//Parachute Textures
#define PARACHUTE_PACK		"pack_carbon"
#define PARACHUTE_TEXTURE	"parachute_carbon"

#define COND_CLOACKED (1<<1)

#define PATH_SIZE 255

int g_iVelocity = -1;

char path_model[256];
char path_pack[256];
char path_texture[256];

ConVar g_fallspeed;
ConVar g_model;

int cl_flags;
float speed[3];

bool inUse[MAXPLAYERS+1];
bool hasModel[MAXPLAYERS+1];
int Parachute_Ent[MAXPLAYERS+1];
float Parachute_FallSpeed[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "[SM] Parachute",
	author = "SWAT_88, Stickz",
	description = "To use your parachute hold the spacebar while falling.",
	version = "dummy",
	url = "http://www.sourcemod.net/"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/sm_parachute_new/sm_parachute_new.txt"
#include "updater/standard.sp"

public void OnPluginStart()
{
	LoadTranslations ("sm_parachute.phrases");

	g_fallspeed = CreateConVar("sm_parachute_fallspeed","50");
	g_model = CreateConVar("sm_parachute_model","1");
	g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	
	InitModel();
	
	HookEvent("player_death", OnPlayerDeath);
	
	g_model.AddChangeHook(CvarChange_Model);
	
	AddUpdaterLibrary(); //auto-updater
}

public void OnConfigsExecuted() {
	for (int client = 1; client <= MaxClients; client++) {
		Parachute_FallSpeed[client] = g_fallspeed.IntValue*(-1.0);
	}
}

public void InitModel()
{
	Format(path_model,PATH_SIZE,"models/parachute/%s",PARACHUTE_MODEL);
	Format(path_pack,PATH_SIZE,"materials/models/parachute/%s",PARACHUTE_PACK);
	Format(path_texture,PATH_SIZE,"materials/models/parachute/%s",PARACHUTE_TEXTURE);
}

public void OnMapStart()
{
	char path[256];
	
	strcopy(path,PATH_SIZE,path_model);
	StrCat(path,PATH_SIZE,".mdl")
	PrecacheModel(path,true);
	AddFileToDownloadsTable(path);

	strcopy(path,PATH_SIZE,path_model);
	StrCat(path,PATH_SIZE,".dx80.vtx")
	AddFileToDownloadsTable(path);

	strcopy(path,PATH_SIZE,path_model);
	StrCat(path,PATH_SIZE,".dx90.vtx")
	AddFileToDownloadsTable(path);

	strcopy(path,PATH_SIZE,path_model);
	StrCat(path,PATH_SIZE,".mdl")
	AddFileToDownloadsTable(path);

	strcopy(path,PATH_SIZE,path_model);
	StrCat(path,PATH_SIZE,".sw.vtx")
	AddFileToDownloadsTable(path);
	
	strcopy(path,PATH_SIZE,path_model);
	StrCat(path,PATH_SIZE,".vvd")
	AddFileToDownloadsTable(path);

	strcopy(path,PATH_SIZE,path_model);
	StrCat(path,PATH_SIZE,".xbox.vtx")
	AddFileToDownloadsTable(path);

	strcopy(path,PATH_SIZE,path_pack);
	StrCat(path,PATH_SIZE,".vmt")
	AddFileToDownloadsTable(path);
	
	strcopy(path,PATH_SIZE,path_pack);
	StrCat(path,PATH_SIZE,".vtf")
	AddFileToDownloadsTable(path);
	
	strcopy(path,PATH_SIZE,path_texture);
	StrCat(path,PATH_SIZE,".vmt")
	AddFileToDownloadsTable(path);
	
	strcopy(path,PATH_SIZE,path_texture);
	StrCat(path,PATH_SIZE,".vtf")
	AddFileToDownloadsTable(path);
}

public void OnEventShutdown()
{
	UnhookEvent("player_death", OnPlayerDeath);
}

public void OnClientPutInServer(int client)
{
	inUse[client] = false;
	hasModel[client] = false;
	Parachute_FallSpeed[client] = g_fallspeed.IntValue*(-1.0);
}

public void OnClientDisconnect(int client)
{
	CloseParachute(client);
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	// End the parachute for the client
	EndPara(GetClientOfUserId(event.GetInt("userid")));	
	return Plugin_Continue;
}

public void StartPara(int client, bool open)
{
	if (g_iVelocity == -1) return;
	
	float velocity[3];
	GetEntDataVector(client, g_iVelocity, velocity);
		
	if(velocity[2] < 0.0)
	{
		velocity[2] = Parachute_FallSpeed[client];			
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
		SetEntDataVector(client, g_iVelocity, velocity);
		SetEntityGravity(client,0.1);
		if(open) OpenParachute(client);
	}
}

public void EndPara(int client)
{
	SetEntityGravity(client,1.0);
	inUse[client]=false;
	CloseParachute(client);	
}

public void OpenParachute(int client)
{
	if(g_model.IntValue == 1)
	{
		char path[256];
		strcopy(path,PATH_SIZE,path_model);
		StrCat(path,PATH_SIZE,".mdl");
		
		Parachute_Ent[client] = CreateEntityByName("prop_dynamic_override");
		DispatchKeyValue(Parachute_Ent[client],"model",path);
		SetEntityMoveType(Parachute_Ent[client], MOVETYPE_VPHYSICS);
		DispatchSpawn(Parachute_Ent[client]);
		
		hasModel[client]=true;
		
		AcceptEntityInput(Parachute_Ent[client], "DisableCollision");
		SetEntProp(Parachute_Ent[client], Prop_Send, "m_noGhostCollision", 1, 1);
		SetEntProp(Parachute_Ent[client], Prop_Data, "m_CollisionGroup", 0x0004);
		
		TeleportParachute(client);
		
		SDKHook(Parachute_Ent[client], SDKHook_SetTransmit, Hook_SetTransmit);
	}
}

public void CloseParachute(int client)
{
	if(hasModel[client] && IsValidEntity(Parachute_Ent[client]))
	{
		SDKUnhook(Parachute_Ent[client], SDKHook_SetTransmit, Hook_SetTransmit);
		AcceptEntityInput(Parachute_Ent[client], "Kill");		
		hasModel[client]=false;	
	}
}

public void CheckClient(int client)
{
	GetEntDataVector(client,g_iVelocity,speed);
	cl_flags = GetEntityFlags(client);
	if(speed[2] >= 0 || (cl_flags & FL_ONGROUND)) EndPara(client);
}

public Action OnPlayerRunCmd(int client, &buttons, &impulse, float vel[3], float angles[3], &weapon)
{	
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		if (IsPlayerAlive(client) && (buttons & IN_USE || buttons & IN_JUMP))
		{
			if (!inUse[client])
			{
				inUse[client] = true;
				StartPara(client,true);
			}
		}
		else if (inUse[client])
		{
			inUse[client] = false;
			EndPara(client);
		}
		CheckClient(client);
	}
	return Plugin_Continue;
}

void TeleportParachute(int client)
{
	if(hasModel[client] && IsValidEntity(Parachute_Ent[client]))
	{
		float Client_Origin[3];
		float Client_Angles[3];
		float Parachute_Angles[3] = {0.0, 0.0, 0.0};
		GetClientAbsOrigin(client,Client_Origin);
		GetClientAbsAngles(client,Client_Angles);
		Parachute_Angles[1] = Client_Angles[1];
		TeleportEntity(Parachute_Ent[client], Client_Origin, Parachute_Angles, NULL_VECTOR);
	}
}

public void CvarChange_Model(ConVar cvar, const char[] oldvalue,  const char[] intvalue){
	if (StringToInt(intvalue) == 0){
		for (int client = 1; client <= MaxClients; client++){
			if (IsClientInGame(client) && IsPlayerAlive(client)){
				CloseParachute(client);
			}
		}
	}
}

public Action Hook_SetTransmit(int entity)
{
	// find parachute owner from entity
	int owner = GetParachuteOwner(entity);
	
	// exit if no owner
	if (owner == -1)
		return Plugin_Continue;
       
	// If the owner is clocked, don't transmit the parachute
	if (GetEntProp(owner, Prop_Send, "m_nPlayerCond") & COND_CLOACKED)
		return Plugin_Handled;
		
	TeleportParachute(owner);
     
	return Plugin_Continue;
}

public int GetParachuteOwner(int entity)
{
	int owner = -1;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && entity == Parachute_Ent[client])
		{
			owner = client;
			break;
		}
	}
	
	return owner;
}

public bool TraceEntityFilter(int entity, int contentsMask) {
	return entity == 0 || entity > MaxClients;
}

/* Natives */
//typedef NativeCall = function int (Handle plugin, int numParams);

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_SetParachuteSpeed", Native_SetParaFallSpeed);
	CreateNative("ND_GetDefaultParaSpeed", Native_GetDefaultParaFallSpeed);		
	return APLRes_Success;
}

public int Native_SetParaFallSpeed(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);	
	float fallSpeed = GetNativeCell(2);	
	Parachute_FallSpeed[client] = fallSpeed;
	return 0;
}

public int Native_GetDefaultParaFallSpeed(Handle plugin, int numParams) {
	return g_fallspeed.IntValue*(-1);
}
