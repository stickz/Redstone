#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <nd_stocks>
#include <nd_redstone>
#include <nd_resources>
#include <nd_res_trickle>
#include <nd_stype>

//#define DEBUG //Enable plugin debugging mode

/*
* NOTES (for unfinished stuff):
* TODO: mention maybe helpers too
* To get all those (from the same team) who participated in the capture don't reset on resource_end_capture, only on resource_captured and maybe reset when the other team starts capturing
* or maybe just move them to another list of participants and remove them from the main
*/

// menu integration
Handle cookie_resmsg = INVALID_HANDLE;
bool option_resmsg[MAXPLAYERS + 1] = {false,...};

// resource information
const MAX_RESOURCES = 30;
int resCount = 0;
int resEnts[MAX_RESOURCES] = {0, ...};
bool resCaps[MAX_RESOURCES][MAXPLAYERS + 1];
int resVals[RESOURCE_COUNT][2];

// reference points and distances
float refCenter[3];
float refBase[TEAM_COUNT][3];

#define CENTRAL_DISTANCE 2000.0 // TODO: set according to map size - for metro cca 2000 so that the west secondary is not considered central but cca 3000 for maps like downtown
#define BASE_DISTANCE 2500.0

#define RES_VAL_EXTARCT 		0
#define RES_VAL_TRICKLE			1

public Plugin myinfo = 
{
	name = "[ND] Resource Messages",
	author = "Vaskrist, Stickz",
	description = "Messages about resource capturing",
	version = "recompile",
	url = "https://github.com/stickz/Redstone/"
}

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_resource_messages/nd_resource_messages.txt"
#include "updater/standard.sp"

public void OnPluginStart()
{
	// menu integration + messages
	LoadTranslations("resourcemessages.phrases"); //basic translation support is a must for Redstone
	LoadTranslations("common.phrases"); //required for on and off
	
	// client prefs stuff
	cookie_resmsg = RegClientCookie("Resource Messages On/Off", "", CookieAccess_Protected); 
	new info;
	SetCookieMenuItem(CookieMenuHandler_resmsg, any:info, "Resource Messages");
	
	// resource capture handling
	HookEvent("resource_start_capture", Event_ResourceStartCapture, EventHookMode_Post);
	HookEvent("resource_end_capture", Event_ResourceEndCapture, EventHookMode_Post);
	HookEvent("resource_captured", Event_ResourceCaptured, EventHookMode_Post);
	
	AddUpdaterLibrary(); //auto-updater
}

public void OnMapStart()
{
	// get reference points for area computations
	GetLocationForClass("nd_info_primary_resource_point", refCenter);
	GetLocationForClass("nd_info_command_bunker_ct", refBase[TEAM_CONSORT]);
	GetLocationForClass("nd_info_command_bunker_emp", refBase[TEAM_EMPIRE]);
	
	// reset all capturing and resource info
	resCount = 0;
	for (int resIndex = 0; resIndex < MAX_RESOURCES; resIndex++)
	{
		resEnts[resIndex] = 0;
		ClearCapturers(resIndex);
	}
}

public void OnConfigsExecuted()
{
	int serverType = ND_GetServerTypeEx(ND_SType_Vanilla);
	if (serverType >= SERVER_TYPE_VANILLA)
	{
		resVals[RESOURCE_PRIME][RES_VAL_EXTARCT] = RES_PRIME_EXTRACT;
		resVals[RESOURCE_PRIME][RES_VAL_TRICKLE] = RES_PRIME_TRICKLE;
		
		resVals[RESOURCE_SECONDARY][RES_VAL_EXTARCT] = RES_SECONDARY_EXTRACT;
		resVals[RESOURCE_SECONDARY][RES_VAL_TRICKLE] = RES_SECONDARY_TRICKLE;
		
		resVals[RESOURCE_TERTIARY][RES_VAL_EXTARCT] = RES_TERTIARY_EXTRACT;
		resVals[RESOURCE_TERTIARY][RES_VAL_TRICKLE] = RES_TERTIARY_TRICKLE;
	}
	
	else
	{
		resVals[RESOURCE_PRIME][RES_VAL_EXTARCT] = RES_MOD_PRIME_EXTRACT;
		resVals[RESOURCE_PRIME][RES_VAL_TRICKLE] = RES_MOD_PRIME_TRICKLE;
		
		resVals[RESOURCE_SECONDARY][RES_VAL_EXTARCT] = RES_MOD_SECONDARY_EXTRACT;
		resVals[RESOURCE_SECONDARY][RES_VAL_TRICKLE] = RES_MOD_SECONDARY_TRICKLE;
		
		resVals[RESOURCE_TERTIARY][RES_VAL_EXTARCT] = RES_MOD_TERTIARY_EXTRACT;
		resVals[RESOURCE_TERTIARY][RES_VAL_TRICKLE] = RES_MOD_TERTIARY_TRICKLE;		
	}	
}

// ======== EVENT HANDLING ========
public Action Event_ResourceStartCapture(Event event, const char[] name, bool dontBroadcast)
{
	int entindex = event.GetInt("entindex");	
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (IsValidClient(client))
	{
		// add userid to the list for entindex
		int resIndex = GetResIndex(entindex);
		AddCapturer(resIndex, client);
	}
	
#if defined DEBUG
	ShoutEntityLoc(entindex);
#endif
}

public Action Event_ResourceEndCapture(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int resIndex = GetResIndex(event.GetInt("entindex"));
	
	// remove user from the list of players capturing the resource 
	// (TODO: move him to helpers)
	RemoveCapturer(resIndex, client);
}

public Action Event_ResourceCaptured(Event event, const char[] name, bool dontBroadcast)
{
	int entindex = event.GetInt("entindex");
	int team = event.GetInt("team");
	
	if (team != TEAM_EMPIRE && team != TEAM_CONSORT) return;
	
	// convert values for local use
	int resIndex = GetResIndex(entindex);
	
	// get all people who were capturing
	char capsNames[MAXPLAYERS+1][64];
	int capsCount = GetCapturerNames(resCaps[resIndex], team, capsNames);
	
	// send a message to all the people in the team
	if (capsCount > 0)
	{
		// Get event type
		int type = event.GetInt("type");
		
		// prepare message
		char nameString[MAXPLAYERS*64];
		ImplodeStrings(capsNames, capsCount, ",", nameString, sizeof(nameString));
		
		// get area/direction of the resource 
		float pos[3];
		GetEntPropVector(entindex, Prop_Send, "m_vecOrigin", pos);
		char direction[3];
		direction = GetDirection(pos, team, type);
		
		// get basic resource captured key
		char resTeamPhrase[32];
		char resCapPhrase[32];
		char resTrickPhrase[32];
		
		// get resource extract rates and resources left before trickle
		int resEVals[3];
		resEVals[1] = GetEntProp(entindex, Prop_Send, "m_iCurrentResources");
		resEVals[0] = resVals[type][RES_VAL_EXTARCT];
		resEVals[2] = resVals[type][RES_VAL_TRICKLE];
		switch (type)
		{
			case RESOURCE_PRIME: 
			{
				resTeamPhrase 	= "Primary Resource Captured";
				resCapPhrase	= "Captured Resource Primary";
				resTrickPhrase	= "Trickled Resource Primary";
				
				// Get team resources of primary if availible
				if (ND_RES_PGET_AVAILABLE())
				{
					int trickleResPrime = ND_GetPrimaryResources(team);
					if (trickleResPrime != -1)
						resEVals[1] = trickleResPrime;
				}
			}			
			case RESOURCE_SECONDARY:
			{
				resTeamPhrase 	= "Secondary Resource Captured";
				resCapPhrase	= "Captured Resource Secondary";
				resTrickPhrase	= "Trickled Resource Secondary";
				
				// Get team resources of secondary if availible
				if (ND_RES_SGET_AVAILABLE())
				{
					int trickleResSec = ND_GetSecondaryResources(entindex, team);
					if (trickleResSec != -1)
						resEVals[1] = trickleResSec;
				}
			}
			case RESOURCE_TERTIARY: 
			{
				resTeamPhrase 	= "Tertiary Resource Captured";
				resCapPhrase	= "Captured Resource Tertiary";
				resTrickPhrase	= "Trickled Resource Tertiary";
				
				// Get the team resources of the tertiary if availible
				if (ND_RES_TGET_AVAILABLE())
				{				
					int trickleResTert = ND_GetTertiaryResources(entindex, team);
					if (trickleResTert != -1)
						resEVals[1] = trickleResTert;
				}
			}
		}		
		
		// translate area
		char areaKey[32];
		Format(areaKey, sizeof(areaKey), "Map Area %s", direction);
		
		RED_LOOP_CLIENTS(client)
		{
			if (option_resmsg[client] && GetClientTeam(client) == team)
			{
				// translate area
				char area[48];
				Format(area, sizeof(area), "%T", areaKey, client);
				
				// translate message
				char message[512];				
				if (resCaps[resIndex][client])
				{
					// If the resource point is trickling, display the trickle phrase
					if (resEVals[1] > 0 && resEVals[1] < 300000)					
						Format(	message, sizeof(message), "\x03%T", resCapPhrase, client, resEVals[0], resEVals[1], resEVals[2]);

					// Otherwise display the trickle complete or trickle disabled phrase
					else
					{
						int res = resEVals[1] > 300000 ? resEVals[0] : resEVals[2];
						Format(	message, sizeof(message), "\x03%T", resTrickPhrase, client, res);
					}
				}
				else				
					Format(message, sizeof(message), "\x03%T", resTeamPhrase, client, nameString, area);
				
				// show it to the user
				PrintToChat(client, message);			
			}		
		}
	}
	
	// drop all info on that resource
	ClearCapturers(resIndex);
}

// ======== COOKIE HANDLING + MENU ========
/// Cookie menu handler
public CookieMenuHandler_resmsg(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_DisplayOption)
	{
		char status[10];
		Format(status, sizeof(status), "%T", option_resmsg[client] ? "On" : "Off", client);		
		Format(buffer, maxlen, "%T: %s", "Cookie Resource Messages", client, status);
	}
	// CookieMenuAction_SelectOption
	else
	{
		option_resmsg[client] = !option_resmsg[client];
		SetClientCookie(client, cookie_resmsg, option_resmsg[client] ? "On" : "Off"); 		
		ShowCookieMenu(client);
	}
}

/// Cookie caching in array
public void OnClientCookiesCached(client) {
	option_resmsg[client] = GetCookie_resmsg(client);
}

/// Reading cookies with default being Off
bool GetCookie_resmsg(client)
{
	char buffer[10];
	GetClientCookie(client, cookie_resmsg, buffer, sizeof(buffer));
	
	// if not explicitly set to "Off" use "On" by default
	return !StrEqual(buffer, "Off");
}

// ======== LOCAL FUNCTIONS ========
/// Returns the index of the resource in the static field resEnts or -1 if there are more resources than the constant 
int GetResIndex(int entIndex)
{
	// iterate through the resource array and return the index
	for (int resIndex = 0; resIndex < MAX_RESOURCES; resIndex++)
	{
		if (resEnts[resIndex] == entIndex)
			return resIndex;
	}
	
	// if there is no such resource, just add a new one and 
	if (resCount < MAX_RESOURCES)
	{
		int resIndex = resCount;
		resCount++;
		
		resEnts[resIndex] = entIndex;
		ClearCapturers(resIndex);
		return resIndex;
	}
	
	return -1;
}


/// Clears the flags of capturing players for the resource
void ClearCapturers(int resIndex)
{
	// clear capturers for the resource
	for (int client = 1; client <= MAXPLAYERS; client++) {
		resCaps[resIndex][client] = false;
	}
}

/// Adds a capturer to the resource
void AddCapturer(int resIndex, int client) {
	resCaps[resIndex][client] = true;
}

/// Adds a capturer from the resource
void RemoveCapturer(int resIndex, int client) {
	resCaps[resIndex][client] = false;
}

/// fills the names array and returns capturer count from the team
int GetCapturerNames(bool[] clients, int team, char names[MAXPLAYERS+1][64])
{
	int capCount = 0;
	// clear capturers for the resource
	for (int client = 1; client <= MAXPLAYERS; client++)
	{
		if (clients[client] && GetClientTeam(client) == team)
		{
			char name[64];
			GetClientName(client, name, sizeof(name));
			names[capCount] = name;
			
			capCount++;
		}
	}
	
	return capCount;
}

/// Checks if the position is closer to the teams base than the global constant
bool IsCloseToBase(float pos[3], int team) {
	return IsCloseTo(pos, refBase[team], BASE_DISTANCE);
}

/// Checks if the position is closer to the reference point than the specified distance
bool IsCloseTo(float pos[3], float ref[3], float dist) {
	return GetVectorDistance(pos, ref) < dist;
}

/// Returns cardinal directions (N, NW, ... ) or own base, enemy base, central area (OB, EB, CE) according to the position and team
String:GetDirection(float pos[3], int team, int type)
{
	char direction[3];
	
	// for primary there is no direction
	if (type == 0) return direction;
	
	float rel[3];
	SubtractVectors(pos, refCenter, rel);
	
	if (IsCloseToBase(pos, team)) { direction = "OB"; return direction; }
	if (IsCloseToBase(pos, getOtherTeam(team))) { direction = "EB"; return direction; }
	if (type == 2 && GetVectorLength(pos) < CENTRAL_DISTANCE) { direction = "CE"; return direction; }
	
	int ns = 0, we = 0;
	float R = 60.0, W = -180.0, N = -90.0, E = 0.0, S = 90.0;
	
	float angle = RadToDeg(ArcTangent2(rel[0],rel[1]));
	if ( IsInBounds(angle, N-R,  N+R)) ns = 1;
	if ( IsInBounds(angle, S-R,  S+R)) ns = 2;
	if (!IsInBounds(angle, W+R, -W-R)) we = 1;
	if ( IsInBounds(angle, E-R,  E+R)) we = 2;
	
	int comb = ns * 3 + we;
	switch(comb) {
		case 1: direction = "W";
		case 2: direction = "E";
		case 3: direction = "N";
		case 4: direction = "NW";
		case 5: direction = "NE";
		case 6: direction = "S";
		case 7: direction = "SW";
		case 8: direction = "SE";
	}
	
	return direction;
}

/// Checks if the value is inside the bounds
bool IsInBounds(float value, float lower, float upper) {
	return lower < value && value < upper;
}

/// Fills passed vector with m_vecOrigin of first entity found by class
GetLocationForClass(char[] class, float pos[3])
{
	int entindex = FindEntityByClassname(-1, class);
	if (entindex != -1)
		GetEntPropVector(entindex, Prop_Send, "m_vecOrigin", pos);
}

// ======== DEBUG ========
/// prints entity and its coords plus direction and distance from center
#if defined DEBUG
void ShoutEntityLoc(int entindex)
{
	float pos[3];
	GetEntPropVector(entindex, Prop_Send, "m_vecOrigin", pos);
	
	float rel[3];
	SubtractVectors(pos, refCenter, rel);
	
	char clsname[64];
	GetEntityClassname(entindex, clsname, sizeof(clsname));
	
	float angle = RadToDeg(ArcTangent2(rel[0],rel[1]));
	float dist = GetVectorLength(rel);
	
	PrintToServer("Entity [%s] found at [X,Y,Z]=[%f,%f,%f] angle: %f, distance: %f", clsname, rel[0], rel[1], rel[2], angle, dist);
}
#endif

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	/* Mark resource trickle natives as optional */
	MarkNativeAsOptional("ND_AddTertiaryResources");
	MarkNativeAsOptional("ND_SetTertiaryResources");
	MarkNativeAsOptional("ND_GetTertiaryResources");
	
	MarkNativeAsOptional("ND_AddSecondaryResources");
	MarkNativeAsOptional("ND_SetSecondaryResources");
	MarkNativeAsOptional("ND_GetSecondaryResources");
	
	MarkNativeAsOptional("ND_AddPrimaryResources");
	MarkNativeAsOptional("ND_SetPrimaryResources");
	MarkNativeAsOptional("ND_GetPrimaryResources");
	
	// Mark server type native as optional
	MarkNativeAsOptional("ND_GetServerType");
	
	return APLRes_Success;	
}
