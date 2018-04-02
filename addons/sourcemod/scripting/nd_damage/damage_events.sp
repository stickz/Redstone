#define WEAPON_NX300_DT -2147481592
#define WEAPON_EXPLO_DT 64
#define WEAPON_BULLET_DT 2
#define BLOCK_DAMAGE 0

#define WEAPON_GL_CNAME "grenade_launcher_proj"
#define WEAPON_RED_CNAME "sticky_grenade_ent"

public Action ND_OnSupplyStationDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (IsValidEntity(inflictor) && damagetype == WEAPON_BULLET_DT)
	{
		damage *= g_Float[bullet_supply_station_mult];
		return Plugin_Changed;
	}
	
	return Plugin_Continue;	
}

public Action ND_OnRocketTurretDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (IsValidEntity(inflictor) && damagetype == WEAPON_BULLET_DT)
	{
		damage *= g_Float[bullet_rocket_turret_mult];
		return Plugin_Changed;
	}
	
	return Plugin_Continue;	
}

public Action ND_OnMGTurretDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (IsValidEntity(inflictor) && damagetype == WEAPON_BULLET_DT)
	{
		damage *= g_Float[bullet_mg_turret_mult];
		return Plugin_Changed;
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
			if (InflictorIsRED(iClass(inflictor)))
			{			
				damage *= g_Float[red_radar_mult];
				return Plugin_Changed;
			}
		}
		
		case WEAPON_BULLET_DT:
		{
			damage *= g_Float[bullet_radar_mult];
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
			if (InflictorIsRED(iClass(inflictor)))
			{
				damage *= g_Float[red_armoury_mult];
				return Plugin_Changed;
			}
		}
		
		case WEAPON_BULLET_DT:
		{
			damage *= g_Float[bullet_armoury_mult];
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
			if (InflictorIsRED(iClass(inflictor)))
			{
				damage *= g_Float[red_power_plant_mult];
				return Plugin_Changed;
			}
		}
		
		case WEAPON_BULLET_DT:
		{
			damage *= g_Float[bullet_power_plant_mult];
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
		case WEAPON_EXPLO_DT:
		{
			if (InflictorIsRED(iClass(inflictor)))
			{
				damage *= g_Float[red_ft_turret_mult];
				return Plugin_Changed;
			}
		}
		
		case WEAPON_BULLET_DT:
		{
			damage *= g_Float[bullet_ft_turret_mult];
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
			if (InflictorIsRED(iClass(inflictor)))
			{
				damage *= g_Float[red_artillery_mult];
				return Plugin_Changed;
			}
		}
		
		case WEAPON_BULLET_DT: 
		{
			damage *= g_Float[bullet_artillery_mult];
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
		case WEAPON_EXPLO_DT:
		{
			char className[64];
			GetEntityClassname(inflictor, className, sizeof(className));
			
			if (InflictorIsRED(className))
			{
				damage *= g_Float[red_transport_mult];
				return Plugin_Changed;
			}
			else if (InflictorIsGL(className))
				return Plugin_Continue;
		}
		
		case WEAPON_BULLET_DT: 
		{
			damage *= g_Float[bullet_transport_mult];
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
		case WEAPON_EXPLO_DT:	 
		{ 
			char className[64];
			GetEntityClassname(inflictor, className, sizeof(className));
			
			if (InflictorIsRED(className))
			{
				damage *= g_Float[red_assembler_mult]; 
				return Plugin_Changed;
			}
			else if (InflictorIsGL(className))
				return Plugin_Continue;
		}
		
		case WEAPON_BULLET_DT:
		{
			damage *= g_Float[bullet_assembler_mult]; 
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
		case WEAPON_NX300_DT:
		{ 
			damage *= g_Float[nx300_bunker_mult]; 	
			return Plugin_Changed; 
		}
		
		case WEAPON_EXPLO_DT:
		{ 
			char className[64];
			GetEntityClassname(inflictor, className, sizeof(className));
			
			if (InflictorIsRED(className))
			{
				damage *= g_Float[red_bunker_mult];
				return Plugin_Changed;
			}			
			else if (InflictorIsGL(className))
				return Plugin_Continue;
		}
		
		case WEAPON_BULLET_DT:	
		{ 
			damage *= g_Float[bullet_bunker_mult];	
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

char iClass(int &inflictor)
{
	char className[64];
	GetEntityClassname(inflictor, className, sizeof(className));
	return className;			
}
