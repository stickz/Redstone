#define WEAPON_M95_CNAME "weapon_m95"
#define WEAPON_X01_CNAME "weapon_x01"
#define WEAPON_NX300_CNAME "weapon_nx300"
#define WEAPON_GL_CNAME "grenade_launcher_proj"
#define WEAPON_RED_CNAME "sticky_grenade_ent"
#define WEAPON_ART_CNAME "struct_artillery_explosion"
#define WEAPON_PSG_CNAME "weapon_psg"
#define WEAPON_PALADIN_CNAME "weapon_paladin"

stock char iClass(int &inflictor)
{
	char wepClassName[64];
	GetEntityClassname(inflictor, wepClassName, sizeof(wepClassName));
	return wepClassName;
}

stock bool InflictorIsRED(const char[] wepClassName) {
	return StrEqual(wepClassName, WEAPON_RED_CNAME, true);
}

stock bool InflictorIsGL(const char[] wepClassName) {
	return StrEqual(wepClassName, WEAPON_GL_CNAME, true);
}

stock bool InflcitorIsM95(const char[] wepClassName) {
	return StrEqual(wepClassName, WEAPON_M95_CNAME, true);
}

stock bool InflictorIsArtillery(const char[] wepClassName) {
	return StrEqual(wepClassName, WEAPON_ART_CNAME, true);
}

stock bool InflictorIsNX300(int &inflictor) {
	return StrEqual(iClass(inflictor), WEAPON_NX300_CNAME, true);
}

stock bool ND_WeaponIsSniper(const char[] wepClassName)
{
	return 	StrEqual(wepClassName, WEAPON_PSG_CNAME, true) ||
			StrEqual(wepClassName, WEAPON_PALADIN_CNAME, true);			
}