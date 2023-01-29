#if defined _nd_classes_included_
  #endinput
#endif

#define _nd_classes_included_

/* Main and Subclass constants for the following prop ents
 * "m_iPlayerClass"
 * "m_iPlayerSubclass"
 * "m_iDesiredPlayerClass"
 * m_iDesiredPlayerSubclass"
 */

#define MAIN_CLASS_ASSAULT 	0
#define MAIN_CLASS_EXO 		1
#define MAIN_CLASS_STEALTH	2
#define	MAIN_CLASS_SUPPORT	3

#define ASSAULT_CLASS_INFANTRY	0
#define ASSAULT_CLASS_GRENADIER	1
#define	ASSAULT_CLASS_SNIPER	2

#define EXO_CLASS_SUPRESSION	0
#define EXO_CLASS_SEIGE_KIT		1

#define	STEALTH_CLASS_ASSASSIN	0
#define	STEALTH_CLASS_SNIPER	1
#define STEALTH_CLASS_SABATEUR 	2

#define SUPPORT_CLASS_MEDIC		0
#define SUPPORT_CLASS_ENGINEER	1
#define SUPPORT_CLASS_BBQ		2

#define ASSAULT_HEALTH			200
#define EXO_HEALTH				600
#define STEALTH_HEALTH			100
#define SUPPORT_HEALTH			150

#define MAX_NEARBY_DISTANCE     300.0
#define ALL_TEAMS               -1

enum ND_MainClasses
{
	mAssault,
	mExo,
	mStealth,
	mSupport
}

enum ND_aSubClasses
{
	aInfantry,
	aGrenadier,
	aSniper
}

enum ND_eSubClasses
{
	eSuppression,
	eSiege_Kit
}

enum ND_seSubClasses
{
	seAssassin,
	seSniper,
	seSabateur
}

enum ND_suSubClasses
{
	suMedic,
	suEngineer,
	suBBQ
}

enum eNDClass
{
    eNDClass_AssaultInfantry = 0,
    eNDClass_AssaultGrenadier,
    eNDClass_AssaultSniper,
    eNDClass_ExoSuppression,
    eNDClass_ExoSiege,
    eNDClass_StealthAssassin,
    eNDClass_StealthSniper,
    eNDClass_StealthSabateur,
    eNDClass_SupportMedic,
    eNDClass_SupportEngineer,
    eNDClass_SupportBBQ,
    eNDClass_Count
}

/* Sub class checker stock functions */
stock bool IsStealthClass(int class) {
	return class == MAIN_CLASS_STEALTH;
}
stock bool IsExoClass(int class) {
	return class == MAIN_CLASS_EXO;
}
stock bool IsAssaultClass(int class) {
	return class == MAIN_CLASS_ASSAULT;
}
stock bool IsSupportClass(int class) {
	return class == MAIN_CLASS_SUPPORT;
}

stock bool IsSniperClass(int class, int subClass)
{
	return 	   (class == MAIN_CLASS_ASSAULT && subClass == ASSAULT_CLASS_SNIPER)
	        || (class == MAIN_CLASS_STEALTH && subClass == STEALTH_CLASS_SNIPER)
}
stock bool IsExoSeigeKit(int class, int subClass) {
	return class == MAIN_CLASS_EXO && subClass == EXO_CLASS_SEIGE_KIT;
}
stock bool IsSupportBBQ(int class, int subClass) {
	return class == MAIN_CLASS_SUPPORT && subClass == SUPPORT_CLASS_BBQ;
}
stock bool IsStealthSab(int class, int subClass) {
	return class == MAIN_CLASS_STEALTH && subClass == STEALTH_CLASS_SABATEUR;
}
stock bool IsStealthAss(int class, int subClass) {
	return class == MAIN_CLASS_STEALTH && subClass == STEALTH_CLASS_ASSASSIN;
}
stock bool IsSupportMedic(int class, int subClass) {
	return class == MAIN_CLASS_SUPPORT && subClass == SUPPORT_CLASS_MEDIC;
}

/* Various other class functions */

stock int ND_GetMainClass(int client) {
	return GetEntProp(client, Prop_Send, "m_iPlayerClass");
}
stock int ND_GetSubClass(int client) {
	return GetEntProp(client, Prop_Send, "m_iPlayerSubclass");
}

stock eNDClass ND_GetPlayerClass(int client)
{
    int classtype = ND_GetMainClass(client);
    int subclass  = ND_GetSubClass(client);
    switch (classtype)
    {
        case MAIN_CLASS_ASSAULT:
        {
            switch (subclass)
            {
                case ASSAULT_CLASS_INFANTRY:
                {
                    return eNDClass_AssaultInfantry;
                }
                case ASSAULT_CLASS_GRENADIER:
                {
                    return eNDClass_AssaultGrenadier;
                }
                case ASSAULT_CLASS_SNIPER:
                {
                    return eNDClass_AssaultSniper;
                }
            }
        }
        case MAIN_CLASS_EXO:
        {
            switch (subclass)
            {
                case EXO_CLASS_SUPRESSION:
                {
                    return eNDClass_ExoSuppression;
                }
                case EXO_CLASS_SEIGE_KIT:
                {
                    return eNDClass_ExoSiege;
                }
            }
        }
        case MAIN_CLASS_STEALTH:
        {
            switch (subclass)
            {
                case STEALTH_CLASS_ASSASSIN:
                {
                    return eNDClass_StealthAssassin;
                }
                case STEALTH_CLASS_SNIPER:
                {
                    return eNDClass_StealthSniper;
                }
                case STEALTH_CLASS_SABATEUR:
                {
                    return eNDClass_StealthSabateur;
                }
            }
        }
        case MAIN_CLASS_SUPPORT:
        {
            switch (subclass)
            {
                case SUPPORT_CLASS_MEDIC:
                {
                    return eNDClass_SupportMedic;
                }
                case SUPPORT_CLASS_ENGINEER:
                {
                    return eNDClass_SupportEngineer;
                }
                case SUPPORT_CLASS_BBQ:
                {
                    return eNDClass_SupportBBQ;
                }
            }
        }
    }

    return eNDClass_Count;
}

stock void ResetClass(int client, int mainClass, int subClass, int gizmo = -1)
{
	FakeClientCommand(client, "joinclass %d %d", mainClass, subClass);

	SetEntProp(client, Prop_Send, "m_iPlayerClass", mainClass);
	SetEntProp(client, Prop_Send, "m_iPlayerSubclass", subClass);
	SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", mainClass);
	SetEntProp(client, Prop_Send, "m_iDesiredPlayerSubclass", subClass);

	if (gizmo != -1)
		SetEntProp(client, Prop_Send, "m_iDesiredGizmo", gizmo);
}

stock int ND_GetMaxHealth(int client)
{
	int health = 0;

	switch (ND_GetMainClass(client))
	{
		case MAIN_CLASS_ASSAULT: health = ASSAULT_HEALTH;
		case MAIN_CLASS_EXO: health = EXO_HEALTH;
		case MAIN_CLASS_STEALTH: health = STEALTH_HEALTH;
		case MAIN_CLASS_SUPPORT: health = SUPPORT_HEALTH;
	}

	return health;
}

stock int ND_GetNearbyTeammateInClass(int client, eNDClass class)
{
    float fClientPosition[3];
    GetClientEyePosition(client, fClientPosition);
    float fMedicPosition[3];
    float fClosestDistance = MAX_NEARBY_DISTANCE;
    float fDistance;
    int iClosestInClass = 0;

    for (int index = 1; index <= MaxClients; index++)
    {
        if (index == client || !IsClientInGame(index) || !IsPlayerAlive(index) || (GetClientTeam(index) != GetClientTeam(client)) || (ND_GetPlayerClass(index) != class))
        {
            continue;
        }
        GetClientEyePosition(index, fMedicPosition);
        fDistance = GetVectorDistance(fClientPosition, fMedicPosition);

        if (fDistance < fClosestDistance)
        {
            iClosestInClass = index;
            fClosestDistance = fDistance;
        }
    }

    return iClosestInClass;
}

stock int ND_GetCountInClass(eNDClass class, int team = ALL_TEAMS)
{
    int number = 0;
    for (int index = 1; index <= MaxClients; index++)
    {
        if (IsClientInGame(index) && IsPlayerAlive(index) && ND_GetPlayerClass(index) == class)
        {
            if (team == ALL_TEAMS)
            {
                number++;
            }
            else if (GetClientTeam(index) == team)
            {
                number++;
            }
        }
    }
    return number;
}
