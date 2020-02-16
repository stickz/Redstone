#define WEAPON_FLAME_DT -2147481592
#define WEAPON_BEAM_DT 0
#define WEAPON_BULLET_DT 2
#define WEAPON_EXPLO_DT 64

#define BLOCK_DAMAGE 0

// Notice: gFloat arrays must be assigned to a varriable first, other it will crash the server.
// See Here: https://github.com/alliedmodders/sourcemod/issues/800

// To Do: Do something with these structures later
public Action ND_OnBarrierDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	if (!IsValidEntity(inflictor))
		return Plugin_Continue;
		
	switch (damagetype)
	{
		case WEAPON_BEAM_DT:
		{
			// Increase x01 damage by 50% when less than 25
			damage = SetMinX01DamageByMult(damage);
			
			// Apply infantry boost x01 damage mult
			float multIB = Siege_InfantryBoostMult(attacker);
			damage *= multIB;
			
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
			
			if (InflictorIsArtillery(className))
			{
				float multiplier = Artillery_StructureReinMult(attacker);
				damage *= multiplier;
				return Plugin_Changed;
			}
			
			else if (InflictorIsGL(className))
			{
				float multIB = GL_InfantryBoostMult(attacker);
				damage *= multIB;
				return Plugin_Changed;
			}
			else if (InflcitorIsM95(className))
			{
				// Apply infantry boost m95 damage mult
				float multIB = Siege_InfantryBoostMult(attacker);
				damage *= multIB;
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
		case WEAPON_BEAM_DT:
		{
			// Set min wall damage to 35 * 4.23 = 148
			if (damage < fMinWallDamageX01)
			{
				damage = fMinWallDamageX01;
				return Plugin_Changed;
			}
			
			// Apply infantry boost x01 damage mult
			float multIB = Siege_InfantryBoostMult(attacker);
			damage *= multIB;
			
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
			
			if (InflictorIsArtillery(className))
			{
				float multiplier = Artillery_StructureReinMult(attacker);
				damage *= multiplier;
				return Plugin_Changed;
			}
			else if (InflictorIsGL(className))
			{
				float multIB = GL_InfantryBoostMult(attacker);
				damage *= multIB;
				return Plugin_Changed;
			}
			else if (InflcitorIsM95(className))
			{
				// Apply infantry boost m95 damage mult
				float multIB = Siege_InfantryBoostMult(attacker);
				damage *= multIB;
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
		case WEAPON_BEAM_DT:
		{
			// Increase x01 damage by 50% when less than 25
			damage = SetMinX01DamageByMult(damage);
			
			// Apply infantry boost x01 damage mult
			float multIB = Siege_InfantryBoostMult(attacker);
			damage *= multIB;
			
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
			
			if (InflictorIsArtillery(className))
			{
				float multiplier = Artillery_StructureReinMult(attacker);
				damage *= multiplier;
				return Plugin_Changed;
			}
			else if (InflictorIsGL(className))
			{
				float multIB = GL_InfantryBoostMult(attacker);
				damage *= multIB;
				return Plugin_Changed;
			}
			else if (InflcitorIsM95(className))
			{
				// Apply infantry boost m95 damage mult
				float multIB = Siege_InfantryBoostMult(attacker);
				damage *= multIB;
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
		case WEAPON_BEAM_DT:
		{
			// Increase x01 damage by 50% when less than 25
			damage = SetMinX01DamageByMult(damage);
			
			// Apply infantry boost x01 damage mult
			float multIB = Siege_InfantryBoostMult(attacker);
			damage *= multIB;
			
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
			
			if (InflictorIsArtillery(className))
			{
				float multiplier = Artillery_StructureReinMult(attacker);
				damage *= multiplier;
				return Plugin_Changed;
			}
			else if (InflictorIsGL(className))
			{
				float multIB = GL_InfantryBoostMult(attacker);
				damage *= multIB;
				return Plugin_Changed;
			}
			else if (InflcitorIsM95(className))
			{
				// Apply infantry boost m95 damage mult
				float multIB = Siege_InfantryBoostMult(attacker);
				damage *= multIB;
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
		case WEAPON_BEAM_DT:
		{
			// Increase x01 damage by 50% when less than 25
			damage = SetMinX01DamageByMult(damage);
			
			// Apply infantry boost x01 damage mult
			float multIB = Siege_InfantryBoostMult(attacker);
			damage *= multIB;
			
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
			
			if (InflictorIsArtillery(className))
			{
				float multiplier = Artillery_StructureReinMult(attacker);
				damage *= multiplier;
				return Plugin_Changed;
			}
			else if (InflictorIsGL(className))
			{
				float multIB = GL_InfantryBoostMult(attacker);
				damage *= multIB;
				return Plugin_Changed;
			}
			else if (InflcitorIsM95(className))
			{
				// Apply infantry boost m95 damage mult
				float multIB = Siege_InfantryBoostMult(attacker);
				damage *= multIB;
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
		case WEAPON_BEAM_DT:
		{
			// Increase x01 damage by 50% when less than 25
			damage = SetMinX01DamageByMult(damage);
			
			// Apply infantry boost x01 damage mult
			float multIB = Siege_InfantryBoostMult(attacker);
			damage *= multIB;
			
			return Plugin_Changed;
		}
		
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
			else if (InflictorIsGL(className))
			{
				float multIB = GL_InfantryBoostMult(attacker);
				damage *= multIB;
				return Plugin_Changed;
			}
			else if (InflcitorIsM95(className))
			{
				// Apply infantry boost m95 damage mult
				float multIB = Siege_InfantryBoostMult(attacker);
				damage *= multIB;
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
		case WEAPON_BEAM_DT:
		{
			// Increase x01 damage by 50% when less than 25
			damage = SetMinX01DamageByMult(damage);
			
			// Apply infantry boost x01 damage mult
			float multIB = Siege_InfantryBoostMult(attacker);
			damage *= multIB;
			
			return Plugin_Changed;
		}
		
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
			else if (InflictorIsGL(className))
			{
				float multIB = GL_InfantryBoostMult(attacker);
				damage *= multIB;
				return Plugin_Changed;
			}
			else if (InflcitorIsM95(className))
			{
				// Apply infantry boost m95 damage mult
				float multIB = Siege_InfantryBoostMult(attacker);
				damage *= multIB;
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
		case WEAPON_BEAM_DT:
		{
			// Increase x01 damage by 50% when less than 25
			damage = SetMinX01DamageByMult(damage);
			
			// Apply infantry boost x01 damage mult
			float multIB = Siege_InfantryBoostMult(attacker);
			damage *= multIB;
			
			return Plugin_Changed;
		}
		
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
			else if (InflictorIsGL(className))
			{
				float multIB = GL_InfantryBoostMult(attacker);
				damage *= multIB;
				return Plugin_Changed;
			}
			else if (InflcitorIsM95(className))
			{
				// Apply infantry boost m95 damage mult
				float multIB = Siege_InfantryBoostMult(attacker);
				damage *= multIB;
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
			// Increase x01 damage by 50% when less than 25
			damage = SetMinX01DamageByMult(damage);
			
			// Apply infantry boost x01 damage mult
			float multIB = Siege_InfantryBoostMult(attacker);
			damage *= multIB;
			
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
				float multIB = GL_InfantryBoostMult(attacker);
				damage *= multIB;
				
				float multiplier = gFloat_GL[gl_ft_turret_mult];
				damage *= multiplier;
				return Plugin_Changed;
			}
			else if (InflcitorIsM95(className))
			{
				// Apply infantry boost m95 damage mult
				float multIB = Siege_InfantryBoostMult(attacker);
				damage *= multIB;
				
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
		case WEAPON_BEAM_DT:
		{
			// Increase x01 damage by 50% when less than 25
			damage = SetMinX01DamageByMult(damage);
			
			// Apply infantry boost x01 damage mult
			float multIB = Siege_InfantryBoostMult(attacker);
			damage *= multIB;
			
			return Plugin_Changed;
		}
		
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
			else if (InflictorIsGL(className))
			{
				float multIB = GL_InfantryBoostMult(attacker);
				damage *= multIB;
				return Plugin_Changed;
			}
			else if (InflcitorIsM95(className))
			{
				// Apply infantry boost m95 damage mult
				float multIB = Siege_InfantryBoostMult(attacker);
				damage *= multIB;
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
			// Increase x01 damage by 50% when less than 25
			damage = SetMinX01DamageByMult(damage);
			
			// Apply infantry boost x01 damage mult
			float multIB = Siege_InfantryBoostMult(attacker);
			damage *= multIB;
			
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
				float multIB = GL_InfantryBoostMult(attacker);
				damage *= multIB;
				
				float multiplier = gFloat_GL[gl_transport_mult];
				damage *= multiplier;
				return Plugin_Changed;
			}
			else if (InflcitorIsM95(className))
			{
				// Apply infantry boost m95 damage mult
				float multIB = Siege_InfantryBoostMult(attacker);
				damage *= multIB;
				
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
			// Increase x01 damage by 50% when less than 25
			damage = SetMinX01DamageByMult(damage);
			
			// Apply infantry boost x01 damage mult
			float multIB = Siege_InfantryBoostMult(attacker);
			damage *= multIB;
			
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
				float multIB = GL_InfantryBoostMult(attacker);
				damage *= multIB;
				
				float multiplier = gFloat_GL[gl_assembler_mult];
				damage *= multiplier; 
				return Plugin_Changed;
			}
			else if (InflcitorIsM95(className))
			{
				// Apply infantry boost m95 damage mult
				float multIB = Siege_InfantryBoostMult(attacker);
				damage *= multIB;
				
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
			// Increase x01 damage by 50% when less than 25
			damage = SetMinX01DamageByMult(damage);
			
			// Apply infantry boost x01 damage mult
			float multIB = Siege_InfantryBoostMult(attacker);
			damage *= multIB;
			
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
				float multIB = GL_InfantryBoostMult(attacker);
				damage *= multIB;
				
				float multiplier = gFloat_GL[gl_bunker_mult];
				damage *= multiplier;
				return Plugin_Changed;
			}
			else if (InflcitorIsM95(className))
			{
				// Apply infantry boost m95 damage mult
				float multIB = Siege_InfantryBoostMult(attacker);
				damage *= multIB;
				
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

float GL_InfantryBoostMult(int &attacker)
{
	float mult = 1.0;
	
	switch(GetAttackerTeamIB(attacker))
	{
		case 1: mult = gFloat_Other[gl_ib1_base_mult];
		case 2: mult = gFloat_Other[gl_ib2_base_mult];
		case 3: mult = gFloat_Other[gl_ib3_base_mult];	
	}
	
	return mult;
}

float Siege_InfantryBoostMult(int &attacker)
{
	float mult = 1.0;
	
	switch (GetAttackerTeamIB(attacker))
	{
		case 0: mult = gFloat_Siege[siege_ib0_base_mult];
		case 1: mult = gFloat_Siege[siege_ib1_base_mult];
		case 2: mult = gFloat_Siege[siege_ib2_base_mult];
		case 3:	mult = gFloat_Siege[siege_ib3_base_mult];		
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

float SetMinX01DamageByMult(float damage) {	
	return damage > iMinThresholdX01 ? damage : damage * fMinIncreaseX01;
}

int GetDefenderTeamSR(int &attacker) 
{
	int oTeam = getOtherTeam(GetClientTeam(attacker));
	return StructureReinLevel[oTeam-2];
}