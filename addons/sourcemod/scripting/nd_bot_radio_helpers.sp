#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <nd_ammo>
#include <nd_classes>

#define PLUGIN_VERSION "1.0.1"

public Plugin myinfo =
{
    name = "[ND] Bot Medic/Engineer Radio Helper",
    author = "databomb",
    description = "Adds bot ability to drop medkits/ammopacks when players radio for support",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/member.php?u=54648"
};

bool g_bMedpackThrown[MAXPLAYERS+1];
bool g_bAmmopackThrown[MAXPLAYERS+1];
int g_iAmmopackRequested[MAXPLAYERS+1];
int  g_iMedpackRequested[MAXPLAYERS+1];
float g_fEquipTime[MAXPLAYERS+1];
float g_fFollowTime[MAXPLAYERS+1];

public OnPluginStart()
{
    UserMsg hSayTextTwo = GetUserMessageId("SayText2");
    if (hSayTextTwo == INVALID_MESSAGE_ID)
    {
        SetFailState("Failed to find user message SayText2");
    }

    HookUserMessage(hSayTextTwo, MessageHook_SayTextTwo);

    // Account for late loading
    for (int iClient = 1; iClient <= MaxClients ; iClient++)
    {
        if (IsClientInGame(iClient) && IsFakeClient(iClient))
        {
            SDKHook(iClient, SDKHook_WeaponCanSwitchTo, OnWeaponCanSwitchTo);
        }
    }
}

public OnClientPutInServer(client)
{
    if (IsFakeClient(client))
    {
        SDKHook(client, SDKHook_WeaponCanSwitchTo, OnWeaponCanSwitchTo);
    }
}

public Action OnWeaponCanSwitchTo(client, weapon)
{
    eNDClass ePlayerClass = ND_GetPlayerClass(client);

    switch (ePlayerClass)
    {
        case eNDClass_SupportMedic:
        {
            if (g_iMedpackRequested[client])
            {
                char sWeaponName[32];
                GetEdictClassname(weapon, sWeaponName, sizeof(sWeaponName));
                if (!StrEqual(sWeaponName, "weapon_medpack"))
                {
                    return Plugin_Handled;
                }
            }
        }
        case eNDClass_SupportEngineer:
        {
            if (g_iAmmopackRequested[client])
            {
                char sWeaponName[32];
                GetEdictClassname(weapon, sWeaponName, sizeof(sWeaponName));
                if (!StrEqual(sWeaponName, "weapon_ammopack"))
                {
                    return Plugin_Handled;
                }
            }
        }
    }

    return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
    if(client && IsClientInGame(client) && IsFakeClient(client) && IsPlayerAlive(client))
    {
        eNDClass ePlayerClass = ND_GetPlayerClass(client);
        char sClassname[64];

        switch (ePlayerClass)
        {
            case eNDClass_SupportMedic:
            {
                if (g_iMedpackRequested[client])
                {
                    int iMedicWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
                    GetEntityClassname(iMedicWeapon, sClassname, sizeof(sClassname));
                    bool bMedpackEquipped = StrEqual(sClassname, "weapon_medpack");

                    // check if we should abort because the target is no longer valid
                    int target = GetClientOfUserId(g_iMedpackRequested[client]);
                    if (!target)
                    {
                        if (bMedpackEquipped)
                        {
                            // change weapon back to primary for bot
                            CreateTimer(1.1, Timer_MedicChangeWeapon, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
                        }
                        // mark request completed
                        g_iMedpackRequested[client] = 0;
                    }

                    if (!bMedpackEquipped)
                    {
                        FakeClientCommand(client, "use weapon_medpack");
                        g_fEquipTime[client] = GetGameTime() + 1.0;
                    }

                    // check if we are facing the target and have medpack equipped
                    if (CanClientSeeTarget(client, target, 0.0, 0.90) && g_fEquipTime[client] < GetGameTime() && !g_bMedpackThrown[client])
                    {
                        // throw medpack
                        buttons |= IN_ATTACK;
                        g_bMedpackThrown[client] = true;
                        // set time to follow-through and keep facing the target
                        g_fFollowTime[client] = GetGameTime() + 1.2;
                    }
                    else if (g_bMedpackThrown[client])
                    {
                        // keep looking towards the target
                        ND_ClientLookAtTarget(client, target);

                        if (g_fFollowTime[client] < GetGameTime())
                        {
                            // medpack request completed
                            g_iMedpackRequested[client] = 0;
                            g_bMedpackThrown[client] = false;
                            // change weapon back to primary for bot
                            CreateTimer(1.1, Timer_MedicChangeWeapon, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
                        }
                    }
                    else
                    {
                        // look towards the target
                        ND_ClientLookAtTarget(client, target);

                        // move closer if we're too far away
                        ND_MoveCloserToTarget(client, target, angles, vel);
                    }
                }
            }
            case eNDClass_SupportEngineer:
            {
                if (g_iAmmopackRequested[client])
                {
                    int iEngineerWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
                    GetEntityClassname(iEngineerWeapon, sClassname, sizeof(sClassname));
                    bool bAmmopackEquipped = StrEqual(sClassname, "weapon_ammopack");

                    int target = GetClientOfUserId(g_iAmmopackRequested[client]);
                    if (!target)
                    {
                        if (bAmmopackEquipped)
                        {
                            // change weapon back to primary for bot
                            CreateTimer(1.1, Timer_EngineerChangeWeapon, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
                        }
                        // supplies request completed
                        g_iAmmopackRequested[client] = 0;
                    }

                    if (!bAmmopackEquipped)
                    {
                        // check if we have ammopack ammo left
                        int iAmmoPacks = ND_GetAmmoByType(client, ND_AMMO_OFFSET_AMMOPACK);
                        if (iAmmoPacks)
                        {
                            FakeClientCommand(client, "use weapon_ammopack");
                            g_fEquipTime[client] = GetGameTime() + 1.0;
                        }
                        else
                        {
                            // cancel the request
                            g_iAmmopackRequested[client] = 0;
                        }
                    }

                    // check if we are facing the target and have ammopack equipped
                    if (CanClientSeeTarget(client, target, 0.0, 0.90) && g_fEquipTime[client] < GetGameTime() && !g_bAmmopackThrown[client])
                    {
                        // throw ammopack
                        buttons |= IN_ATTACK;
                        g_bAmmopackThrown[client] = true;
                        // set time to follow-through and keep facing the target
                        g_fFollowTime[client] = GetGameTime() + 1.2;
                    }
                    else if (g_bAmmopackThrown[client])
                    {
                        // keep looking towards the target
                        ND_ClientLookAtTarget(client, target);

                        if (g_fFollowTime[client] < GetGameTime())
                        {
                            // supplies request completed
                            g_iAmmopackRequested[client] = 0;
                            g_bAmmopackThrown[client] = false;
                            // change weapon back to primary for bot
                            CreateTimer(1.1, Timer_EngineerChangeWeapon, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
                        }
                    }
                    else
                    {
                        // look towards the target
                        ND_ClientLookAtTarget(client, target);

                        // move closer if we're too far away
                        ND_MoveCloserToTarget(client, target, angles, vel);
                    }
                }
            }
        }
    }

    return Plugin_Continue;
}

public Action MessageHook_SayTextTwo(UserMsg hMessageId, BfRead hBitBuffer, const int[] iPlayers, int iTotalPlayers, bool bReliableMessage, bool bInitMessage)
{
    int iClient = BfReadByte(hBitBuffer);
    int iTeam = GetClientTeam(iClient);
    BfReadByte(hBitBuffer);
    char sMessage[128];
    BfReadString(hBitBuffer, sMessage, sizeof(sMessage), true);
    if (StrEqual(sMessage, "ND_Chat_Radio"))
    {
        BfReadString(hBitBuffer, sMessage, sizeof(sMessage), true); // ignore
        BfReadString(hBitBuffer, sMessage, sizeof(sMessage), true); // ignore
        BfReadString(hBitBuffer, sMessage, sizeof(sMessage), true); // param7

        int iHelper = 0;
        if (StrEqual(sMessage, "#radio_medic"))
        {
            // find if team has any medics
            if (ND_GetCountInClass(eNDClass_SupportMedic, iTeam))
            {
                // find if there's a nearby medic
                iHelper = ND_GetNearbyTeammateInClass(iClient, eNDClass_SupportMedic, true);
                // skip if we didn't find anyone nearby or closest medic is already servicing a request
                if (iHelper && !g_iMedpackRequested[iHelper])
                {
                    // find out if the requester can see this medic
                    float fRequesterPosition[3];
                    GetClientEyePosition(iClient, fRequesterPosition);
                    float fMedicPosition[3];
                    GetClientEyePosition(iHelper, fMedicPosition);
                    if (IsPointVisible(fRequesterPosition, fMedicPosition))
                    {
                        g_iMedpackRequested[iHelper] = GetClientUserId(iClient);
                    }
                }
            }
        }
        else if (StrEqual(sMessage, "#radio_requestingsupplies"))
        {
            // find if there are any engineers
            if (ND_GetCountInClass(eNDClass_SupportEngineer, iTeam))
            {
                // find if there's a nearby engineer
                iHelper = ND_GetNearbyTeammateInClass(iClient, eNDClass_SupportEngineer, true);
                // skip if we didn't find anyone nearby or closest engineer is already servicing a request
                if (iHelper && !g_iAmmopackRequested[iHelper])
                {
                    // find out if the requester can see this engineer
                    float fRequesterPosition[3];
                    GetClientEyePosition(iClient, fRequesterPosition);
                    float fEngineerPosition[3];
                    GetClientEyePosition(iHelper, fEngineerPosition);
                    if (IsPointVisible(fRequesterPosition, fEngineerPosition))
                    {
                        g_iAmmopackRequested[iHelper] = GetClientUserId(iClient);
                    }
                }
            }
        }
    }

    return Plugin_Continue;
}

public Action Timer_EngineerChangeWeapon(Handle hTimer, any iUserId)
{
    int iClient = GetClientOfUserId(iUserId);
    if (iClient && IsClientInGame(iClient))
    {
        FakeClientCommand(iClient, "use weapon_shotgun");
    }

    return Plugin_Handled;
}

public Action Timer_MedicChangeWeapon(Handle hTimer, any iUserId)
{
    int iClient = GetClientOfUserId(iUserId);
    if (iClient && IsClientInGame(iClient))
    {
        FakeClientCommand(iClient, "use weapon_mp7");
    }

    return Plugin_Handled;
}

void ND_MoveCloserToTarget(client, target, float angles[3], float vel[3])
{
    float fPlayerPosition[3];
    float fTargetPosition[3];
    GetClientEyePosition(client, fPlayerPosition);
    GetClientEyePosition(target, fTargetPosition);
    float fDistance = GetVectorDistance(fPlayerPosition, fTargetPosition);

    if (fDistance > MAX_NEARBY_DISTANCE)
    {
        // steer the player closer to the target
        float fVector[3];
        MakeVectorFromPoints(fPlayerPosition, fTargetPosition, fVector);
        float fDesiredAngles[3];
        GetVectorAngles(fVector, fDesiredAngles);
        angles[0] = fDesiredAngles[0];
        angles[1] = fDesiredAngles[1];
        vel[0] = 400.0;
        vel[1] = 0.0;
        vel[2] = 0.0;
    }
}

void ND_ClientLookAtTarget(int client, int target)
{
    float fGoalPosition[3];
    GetClientEyePosition(target, fGoalPosition);

    float fPosition[3];
    GetClientEyePosition(client, fPosition);

    // get normalised direction from target to client
    float fVector[3];
    MakeVectorFromPoints(fPosition, fGoalPosition, fVector);
    float fDesiredAngles[3];
    GetVectorAngles(fVector, fDesiredAngles);

    // ease the current direction to the target direction
    fDesiredAngles[0] = AngleNormalize(fDesiredAngles[0]);
    fDesiredAngles[1] = AngleNormalize(fDesiredAngles[1]);
    fDesiredAngles[2] = AngleNormalize(fDesiredAngles[2]);

    TeleportEntity(client, NULL_VECTOR, fDesiredAngles, NULL_VECTOR);
}

bool CanClientSeeTarget(int Viewer, int Target, float fMaxDistance=0.0, float fThreshold=0.70)
{
    // Retrieve view and target eyes position
    float fViewPos[3];
    GetClientEyePosition(Viewer, fViewPos);
    float fViewAng[3];
    GetClientEyeAngles(Viewer, fViewAng);
    float fViewDir[3];
    float fTargetPos[3];
    GetClientEyePosition(Target, fTargetPos);
    float fTargetDir[3];
    float fDistance[3];

    // Calculate view direction
    fViewAng[0] = fViewAng[2] = 0.0;
    GetAngleVectors(fViewAng, fViewDir, NULL_VECTOR, NULL_VECTOR);

    // Calculate distance to viewer to see if it can be seen.
    fDistance[0] = fTargetPos[0] - fViewPos[0];
    fDistance[1] = fTargetPos[1] - fViewPos[1];
    fDistance[2] = 0.0;
    if (fMaxDistance != 0.0)
    {
        if (((fDistance[0] * fDistance[0]) + (fDistance[1] * fDistance[1])) >= (fMaxDistance * fMaxDistance))
        {
            return false;
        }
    }

    // Check dot product. If it's negative, that means the viewer is facing backwards to the target.
    NormalizeVector(fDistance, fTargetDir);
    if (GetVectorDotProduct(fViewDir, fTargetDir) < fThreshold)
    {
        return false;
    }

    return IsThereObstacleBetweenPoints(fViewPos, fTargetPos);
}

bool IsThereObstacleBetweenPoints(float fViewPos[3], float fTargetPos[3])
{
    // check if there are no obstacles in between through raycasting
    Handle hTrace = TR_TraceRayFilterEx(fViewPos, fTargetPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, ClientViewsFilter);
    if (TR_DidHit(hTrace))
    {
        CloseHandle(hTrace);
        return false;
    }

    // visible
    CloseHandle(hTrace);
    return true;
}

public bool ClientViewsFilter(int Entity, int Mask, any Junk)
{
    if (Entity >= 1 && Entity <= MaxClients)
    {
        return false;
    }

    return true;
}

bool IsPointVisible(float start[3], float end[3])
{
	TR_TraceRayFilter(start, end, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterStuff);
	return TR_GetFraction() >= 0.9;
}

public bool TraceEntityFilterStuff(int entity, int mask)
{
	return entity > MaxClients;
}

float fmodf(float number, float denom)
{
    return number - RoundToFloor(number / denom) * denom;
}

float AngleNormalize(float angle)
{
        angle = fmodf(angle, 360.0);
        if (angle > 180)
        {
            angle -= 360;
        }
        if (angle < -180)
        {
            angle += 360;
        }

        return angle;
}
