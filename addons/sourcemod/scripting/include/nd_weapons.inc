#define WEAPON_M95_CNAME "weapon_m95"
#define WEAPON_X01_CNAME "weapon_x01"
#define WEAPON_NX300_CNAME "weapon_nx300"
#define WEAPON_GL_CNAME "grenade_launcher_proj"
#define WEAPON_RED_CNAME "sticky_grenade_ent"
#define WEAPON_ART_CNAME "struct_artillery_explosion"

stock char iClass(int &inflictor)
{
	char className[64];
	GetEntityClassname(inflictor, className, sizeof(className));
	return className;
}

stock bool InflictorIsRED(const char[] className) {
	return StrEqual(className, WEAPON_RED_CNAME, true);
}

stock bool InflictorIsGL(const char[] className) {
	return StrEqual(className, WEAPON_GL_CNAME, true);
}

stock bool InflcitorIsM95(const char[] className) {
	return StrEqual(className, WEAPON_M95_CNAME, true);
}

stock bool InflictorIsArtillery(const char[] className) {
	return StrEqual(className, WEAPON_ART_CNAME, true);
}

stock bool InflictorIsNX300(int &inflictor) {
	return StrEqual(iClass(inflictor), WEAPON_NX300_CNAME, true);
}