#include <sourcemod>

public Plugin myinfo =
{
    name = "[ND] Server Type",
    author = "Stickz",
    description = "Server type wrapper for stable and beta servers",
    version = "dummy",
    url = "https://github.com/stickz/Redstone"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_server_type/nd_server_type.txt"
#include "updater/standard.sp"

ConVar cvarServerType;

public void OnPluginStart()
{
	cvarServerType = CreateConVar("sm_server_type", "1", "0 = disable, 1 = stable, 2 = beta, 3 = alpha");
	AddUpdaterLibrary(); //auto-updater
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_GetServerType", Native_GetServerType);
	return APLRes_Success;
}

public int Native_GetServerType(Handle plugin, int numParams) {
	return cvarServerType.IntValue;
}