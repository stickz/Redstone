#if defined _nd_ammo_included_
  #endinput
#endif

#define _nd_ammo_included_

#define ND_AMMO_OFFSET_HYPOSPRAY        2
#define ND_AMMO_OFFSET_BAG90            4
#define ND_AMMO_OFFSET_ASSAULT_CONSORT  6
#define ND_AMMO_OFFSET_ASSAULT_EMPIRE   7
#define ND_AMMO_OFFSET_MP500            8
#define ND_AMMO_OFFSET_SP5              9
#define ND_AMMO_OFFSET_MP7              10
#define ND_AMMO_OFFSET_SNIPERRIFLE      12
#define ND_AMMO_OFFSET_EXOGAU           14
#define ND_AMMO_OFFSET_FLAMETHROWER     15
#define ND_AMMO_OFFSET_SHOTGUN          16
#define ND_AMMO_OFFSET_GRENADETHROWER   19
#define ND_AMMO_OFFSET_RED              21
#define ND_AMMO_OFFSET_EMP              22
#define ND_AMMO_OFFSET_FRAG             23
#define ND_AMMO_OFFSET_DAISYCUTTER      25
#define ND_AMMO_OFFSET_AMMOPACK         26
#define ND_AMMO_OFFSET_X01SEIGE         27
#define ND_AMMO_OFFSET_POISONGAS        29

// returns the ammo quantity given one of the ND_AMMO_OFFSET values supplied as the type
stock int ND_GetAmmoByType(int client, int type)
{
    if (!client || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client))
    {
        return 0;
    }

    int iAmmoOffset = FindDataMapInfo(client, "m_iAmmo");
    if (iAmmoOffset == -1)
    {
        return 0;
    }

    return GetEntData(client, iAmmoOffset + type*4);
}
