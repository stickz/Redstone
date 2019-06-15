#define WEAPON_FLAME_DT -2147481592
#define WEAPON_BEAM_DT 0
#define WEAPON_BULLET_DT 2
#define WEAPON_EXPLO_DT 64

#define BLOCK_DAMAGE 0

/* Check name constants after damage type */
#define WEAPON_M95_CNAME "weapon_m95"
#define WEAPON_X01_CNAME "weapon_x01"
#define WEAPON_NX300_CNAME "weapon_nx300"
#define WEAPON_GL_CNAME "grenade_launcher_proj"
#define WEAPON_RED_CNAME "sticky_grenade_ent"
#define WEAPON_ART_CNAME "struct_artillery_explosion"

// Notice: gFloat arrays must be assigned to a varriable first, other it will crash the server.
// See Here: https://github.com/alliedmodders/sourcemod/issues/800

// To Do: Do something with these structures later
public Action ND_OnBarrierDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	if (!IsValidEntity(inflictor))
		return Plugin_Continue;
		
	switch (damagetype)
	{
		case WEAPON_FLAME_DT:
		{
			if (InflictorIsNX300(inflictor))
			{
				float multIB = BBQ_InfantryBoostMult(attacker);
				damage *= multIB;
				return Plugin_Changed;
			}
		}
		
		case WEAPON_EXPLO_DT:
		{
			if (InflictorIsArtillery(iClass(inflictor)))
			{
				float multiplier = Artillery_StructureReinMult(attacker);
				damage *= multiplier;
				return Plugin_Changed;
			}
		}
	}

	return Plugin_Continue;
}
public Action ND_OnWallDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	if (!IsValidEntity(inflictor))
		return Plugin_Continue;
		
	switch (damagetype)
	{
		case WEAPON_FLAME_DT:
		{
			if (InflictorIsNX300(inflictor))
			{
				float multIB = BBQ_InfantryBoostMult(attacker);
				damage *= multIB;
				return Plugin_Changed;
			}
		}
		
		case WEAPON_EXPLO_DT:
		{
			if (InflictorIsArtillery(iClass(inflictor)))
			{
				float multiplier = Artillery_StructureReinMult(attacker);
				damage *= multiplier;
				return Plugin_Changed;
			}
		}
	}

	return Plugin_Continue;
}

public Action ND_OnSupplyStationDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!IsValidEntity(inflictor))
		return Plugin_Continue;
		
	switch (damagetype)
	{
		case WEAPON_FLAME_DT:
		{
			if (InflictorIsNX300(inflictor))
			{
				float multIB = BBQ_InfantryBoostMult(attacker);
				damage *= multIB;
				return Plugin_Changed;
			}
		}
		
		case WEAPON_EXPLO_DT:
		{
			if (InflictorIsArtillery(iClass(inflictor)))
			{
				float multiplier = Artillery_StructureReinMult(attacker);
				damage *= multiplier;
				return Plugin_Changed;
			}
		}
		
		case WEAPON_BULLET_DT:
		{
			float multiplier = gFloat_Bullet[bullet_supply_station_mult];
			damage *= multiplier;
			return Plugin_Changed;		
		}
	}
	
	return Plugin_Continue;	
}

public Action ND_OnRocketTurretDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!IsValidEntity(inflictor))
		return Plugin_Continue;
	
	switch (damagetype)
	{
		case WEAPON_FLAME_DT:
		{
			if (InflictorIsNX300(inflictor))
			{
				float multIB = BBQ_InfantryBoostMult(attacker);
				damage *= multIB;
				return Plugin_Changed;
			}
		}
		
		case WEAPON_EXPLO_DT:
		{
			if (InflictorIsArtillery(iClass(inflictor)))
			{
				float multiplier = Artillery_StructureReinMult(attacker);
				damage *= multiplier;
				return Plugin_Changed;
			}
		}
		
		case WEAPON_BULLET_DT:
		{
			float multiplier = gFloat_Bullet[bullet_rocket_turret_mult];
			damage *= multiplier;
			return Plugin_Changed;		
		}	
	}

	return Plugin_Continue;	
}

public Action ND_OnMGTurretDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!IsValidEntity(inflictor))
		return Plugin_Continue;
	
	switch (damagetype)
	{	
		case WEAPON_FLAME_DT:
		{
			if (InflictorIsNX300(inflictor))
			{
				float multIB = BBQ_InfantryBoostMult(attacker);
				damage *= multIB;
				return Plugin_Changed;
			}
		}
		
		case WEAPON_EXPLO_DT:
		{
			if (InflictorIsArtillery(iClass(inflictor)))
			{
				float multiplier = Artillery_StructureReinMult(attacker);
				damage *= multiplier;
				return Plugin_Changed;
			}
		}
	
		case WEAPON_BULLET_DT:
		{
			float multiplier = gFloat_Bullet[bullet_mg_turret_mult];
			damage *= multiplier;
			return Plugin_Changed;		
		}
	}
	
	return Plugin_Continue;	
}

public Action ND_OnRadarDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!IsValidEntity(inflictor))
		return Plugin_Continue;
	
	switch (damagetype)
	{
		case WEAPON_EXPLO_DT:
		{		
			char className[64];
			GetEntityClassname(inflictor, className, sizeof(className));
			
			if (InflictorIsRED(className))
			{			
				float multiplier = gFloat_Red[red_radar_mult];
				damage *= multiplier;
				return Plugin_Changed;
			}			
			else if (InflictorIsArtillery(className))
			{
				float multiplier = Artillery_StructureReinMult(attacker);
				damage *= multiplier;
				return Plugin_Changed;
			}
		}
		
		case WEAPON_FLAME_DT:
		{
			if (InflictorIsNX300(inflictor))
			{
				float multIB = BBQ_InfantryBoostMult(attacker);
				damage *= multIB;
				return Plugin_Changed;
			}
		}
		
		case WEAPON_BULLET_DT:
		{
			float multiplier = gFloat_Bullet[bullet_radar_mult];
			damage *= multiplier;
			return Plugin_Changed;			
		}		
	}
	
	return Plugin_Continue;
}
	
public Action ND_OnArmouryDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!IsValidEntity(inflictor))
		return Plugin_Continue;
	
	switch (damagetype)
	{
		case WEAPON_EXPLO_DT:
		{
			char className[64];
			GetEntityClassname(inflictor, className, sizeof(className));
			
			if (InflictorIsRED(className))
			{
				float multiplier = gFloat_Red[red_armoury_mult];
				damage *= multiplier;
				return Plugin_Changed;
			}
			else if (InflictorIsArtillery(className))
			{
				float multiplier = Artillery_StructureReinMult(attacker);
				damage *= multiplier;
				return Plugin_Changed;
			}
		}
		
		case WEAPON_FLAME_DT:
		{
			if (InflictorIsNX300(inflictor))
			{
				float multIB = BBQ_InfantryBoostMult(attacker);
				damage *= multIB;
				return Plugin_Changed;
			}
		}
		
		case WEAPON_BULLET_DT:
		{
			float multiplier = gFloat_Bullet[bullet_armoury_mult];
			damage *= multiplier;
			return Plugin_Changed;			
		}		
	}
	
	return Plugin_Continue;
}

public Action ND_OnPowerPlantDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!IsValidEntity(inflictor))
		return Plugin_Continue;
	
	switch(damagetype)
	{
		case WEAPON_EXPLO_DT:
		{
			char className[64];
			GetEntityClassname(inflictor, className, sizeof(className));
			
			if (InflictorIsRED(className))
			{
				float multiplier = gFloat_Red[red_power_plant_mult];
				damage *= multiplier;
				return Plugin_Changed;
			}
			else if (InflictorIsArtillery(className))
			{
				float multiplier = Artillery_StructureReinMult(attacker);
				damage *= multiplier;
				return Plugin_Changed;
			}
		}
		
		case WEAPON_FLAME_DT:
		{
			if (InflictorIsNX300(inflictor))
			{
				float multIB = BBQ_InfantryBoostMult(attacker);
				damage *= multIB;
				return Plugin_Changed;
			}
		}
		
		case WEAPON_BULLET_DT:
		{
			float multiplier = gFloat_Bullet[bullet_power_plant_mult];
			damage *= multiplier;
			return Plugin_Changed;			
		}		
	}
	
	return Plugin_Continue;
}

public Action ND_OnFlamerTurretDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!IsValidEntity(inflictor))
		return Plugin_Continue;
	
	switch (damagetype)
	{
		case WEAPON_BEAM_DT:
		{
			float multiplier = gFloat_Siege[siege_ft_turret_mult];
			damage *= multiplier;
			return Plugin_Changed;
		}
		
		case WEAPON_FLAME_DT:
		{
			if (InflictorIsNX300(inflictor))
			{
				float multIB = BBQ_InfantryBoostMult(attacker);
				damage *= multIB;
				return Plugin_Changed;
			}
		}
		
		case WEAPON_EXPLO_DT:
		{
			char className[64];
			GetEntityClassname(inflictor, className, sizeof(className));
			
			if (InflictorIsRED(className))
			{
				float multiplier = gFloat_Red[red_ft_turret_mult];
				damage *= multiplier;
				return Plugin_Changed;
			}
			else if (InflictorIsGL(className))
			{
				float multiplier = gFloat_GL[gl_ft_turret_mult];
				damage *= multiplier;
				return Plugin_Changed;
			}
			else if (InflcitorIsM95(className))
			{
				float multiplier = gFloat_Siege[siege_ft_turret_mult];
				damage *= multiplier;
				return Plugin_Changed;
			}			
			else if (InflictorIsArtillery(className))
			{
				float multiplier = Artillery_StructureReinMult(attacker);
				damage *= multiplier;
				return Plugin_Changed;
			}
		}
		
		case WEAPON_BULLET_DT:
		{
			float multiplier = gFloat_Bullet[bullet_ft_turret_mult];
			damage *= multiplier;
			return Plugin_Changed;			
		}		
	}
	
	return Plugin_Continue;	
}

public Action ND_OnArtilleryDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!IsValidEntity(inflictor))
		return Plugin_Continue;
	
	switch (damagetype)
	{
		case WEAPON_EXPLO_DT:
		{
			char className[64];
			GetEntityClassname(inflictor, className, sizeof(className));
			
			if (InflictorIsRED(className))
			{
				float multiplier = gFloat_Red[red_artillery_mult];
				damage *= multiplier;
				return Plugin_Changed;
			}
			else if (InflictorIsArtillery(className))
			{
				float multiplier = Artillery_StructureReinMult(attacker);
				damage *= multiplier;
				return Plugin_Changed;
			}
		}
		
		case WEAPON_FLAME_DT:
		{
			if (InflictorIsNX300(inflictor))
			{
				float multIB = BBQ_InfantryBoostMult(attacker);
				damage *= multIB;
				return Plugin_Changed;
			}
		}
		
		case WEAPON_BULLET_DT: 
		{
			float multiplier = gFloat_Bullet[bullet_artillery_mult];
			damage *= multiplier;
			return Plugin_Changed;			
		}		
	}
	
	return Plugin_Continue;
}

public Action ND_OnTransportDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!IsValidEntity(inflictor))
		return Plugin_Continue;
	
	switch (damagetype)
	{
		case WEAPON_BEAM_DT:
		{
			float multiplier = gFloat_Siege[siege_transport_mult];
			damage *= multiplier;
			return Plugin_Changed;
		}
		
		case WEAPON_FLAME_DT:
		{
			if (InflictorIsNX300(inflictor))
			{
				float multIB = BBQ_InfantryBoostMult(attacker);
				damage *= multIB;
				return Plugin_Changed;
			}
		}
		
		case WEAPON_EXPLO_DT:
		{
			char className[64];
			GetEntityClassname(inflictor, className, sizeof(className));
			
			if (InflictorIsRED(className))
			{
				float multiplier = gFloat_Red[red_transport_mult];
				damage *= multiplier;
				return Plugin_Changed;
			}
			else if (InflictorIsGL(className))
			{
				float multiplier = gFloat_GL[gl_transport_mult];
				damage *= multiplier;
				return Plugin_Changed;
			}
			else if (InflcitorIsM95(className))
			{
				float multiplier = gFloat_Siege[siege_transport_mult];
				damage *= multiplier;
				return Plugin_Changed;
			}
			else if (InflictorIsArtillery(className))
			{
				float multiplier = Artillery_StructureReinMult(attacker);
				damage *= multiplier;
				return Plugin_Changed;
			}
		}
		
		case WEAPON_BULLET_DT: 
		{
			float multiplier = gFloat_Bullet[bullet_transport_mult];
			damage *= multiplier;
			return Plugin_Changed;
		}		
	}
	
	return Plugin_Continue;
}		

public Action ND_OnAssemblerDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	if (!IsValidEntity(inflictor))
		return Plugin_Continue;
	
	switch (damagetype)
	{
		case WEAPON_BEAM_DT:
		{
			float multiplier = gFloat_Siege[siege_assembler_mult];
			damage *= multiplier;
			return Plugin_Changed;
		}
		
		case WEAPON_FLAME_DT:
		{
			if (InflictorIsNX300(inflictor))
			{
				float multIB = BBQ_InfantryBoostMult(attacker);
				damage *= multIB;
				return Plugin_Changed;
			}
		}
		
		case WEAPON_EXPLO_DT:	 
		{ 
			char className[64];
			GetEntityClassname(inflictor, className, sizeof(className));
			
			if (InflictorIsRED(className))
			{
				float multiplier = gFloat_Red[red_assembler_mult];
				damage *= multiplier; 
				return Plugin_Changed;
			}
			else if (InflictorIsGL(className))
			{				
				float multiplier = gFloat_GL[gl_assembler_mult];
				damage *= multiplier; 
				return Plugin_Changed;
			}
			else if (InflcitorIsM95(className))
			{
				float multiplier = gFloat_Siege[siege_assembler_mult];
				damage *= multiplier;
				return Plugin_Changed;
			}
			else if (InflictorIsArtillery(className))
			{
				float multiplier = Artillery_StructureReinMult(attacker);
				damage *= multiplier;
				return Plugin_Changed;
			}
		}
		
		case WEAPON_BULLET_DT:
		{
			float multiplier = gFloat_Bullet[bullet_assembler_mult];
			damage *= multiplier; 
			return Plugin_Changed;
		}		
	}
	
	return Plugin_Continue;
}

public Action ND_OnBunkerDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	// Disable bunker damage during warmup round, if convar is enabled
	if (!ND_RoundStarted() && cvarNoWarmupBunkerDamage.BoolValue)
	{
		damage = BLOCK_DAMAGE;
		return Plugin_Changed;
	}
	
	if (!IsValidEntity(inflictor))
		return Plugin_Continue;

	switch (damagetype)
	{
		case WEAPON_BEAM_DT:
		{
			float multiplier = gFloat_Siege[siege_bunker_mult];
			damage *= multiplier;
			return Plugin_Changed;
		}
		
		case WEAPON_FLAME_DT:
		{ 
			if (InflictorIsNX300(inflictor))
			{			
				// Apply the infantry boost damage mult
				float multIB = BBQ_InfantryBoostMult(attacker);
				damage *= multIB;
				
				// Apply the bunker damage reduction mult
				float multiplier = gFloat_Other[nx300_bunker_mult];
				damage *= multiplier;
				return Plugin_Changed;
			}
		}
		
		case WEAPON_EXPLO_DT:
		{ 
			char className[64];
			GetEntityClassname(inflictor, className, sizeof(className));
			
			if (InflictorIsRED(className))
			{
				float multiplier = gFloat_Red[red_bunker_mult]; 
				damage *= multiplier;
				return Plugin_Changed;
			}			
			else if (InflictorIsGL(className))
			{
				float multiplier = gFloat_GL[gl_bunker_mult];
				damage *= multiplier;
				return Plugin_Changed;
			}
			else if (InflcitorIsM95(className))
			{
				float multiplier = gFloat_Siege[siege_bunker_mult];
				damage *= multiplier;
				return Plugin_Changed;
			}
			else if (InflictorIsArtillery(className))
			{
				float multiplier = Artillery_StructureReinMult(attacker);
				damage *= multiplier;
				return Plugin_Changed;
			}
		}
		
		case WEAPON_BULLET_DT:	
		{ 
			float multiplier = gFloat_Bullet[bullet_bunker_mult];
			damage *= multiplier;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

bool InflictorIsRED(const char[] className) {
	return StrEqual(className, WEAPON_RED_CNAME, true);
}

bool InflictorIsGL(const char[] className) {
	return StrEqual(className, WEAPON_GL_CNAME, true);
}

bool InflcitorIsM95(const char[] className) {
	return StrEqual(className, WEAPON_M95_CNAME, true);
}

bool InflictorIsArtillery(const char[] className) {
	return StrEqual(className, WEAPON_ART_CNAME, true);
}

bool InflictorIsNX300(int &inflictor) {
	return StrEqual(iClass(inflictor), WEAPON_NX300_CNAME, true);
}

float BBQ_InfantryBoostMult(int &attacker)
{
	float mult = 1.0;	
	
	switch(GetAttackerTeamIB(attacker))
	{
		case 1: mult = gFloat_Other[nx300_ib1_base_mult];
		case 2: mult = gFloat_Other[nx300_ib2_base_mult];
		case 3: mult = gFloat_Other[nx300_ib3_base_mult];	
	}
	
	return mult;
}

int GetAttackerTeamIB(int &attacker) 
{
	int team = GetClientTeam(attacker);
	return InfantryBoostLevel[team-2];
}

float Artillery_StructureReinMult(int &attacker)
{
	float mult = 1.0;	
	
	switch(GetDefenderTeamSR(attacker))
	{
		case 1: mult = gFloat_Other[artillery_ib1_base_mult];
		case 2: mult = gFloat_Other[artillery_ib2_base_mult];
		case 3: mult = gFloat_Other[artillery_ib3_base_mult];	
	}
	
	return mult;
}

int GetDefenderTeamSR(int &attacker) 
{
	int oTeam = getOtherTeam(GetClientTeam(attacker));
	return StructureReinLevel[oTeam-2];
}

char iClass(int &inflictor)
{
	char className[64];
	GetEntityClassname(inflictor, className, sizeof(className));
	return className;			
}
