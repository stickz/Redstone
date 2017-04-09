#define WEAPON_NX300_DT -2147481592
#define WEAPON_RED_DT 64

public Action ND_OnRadarDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// If the damage type is a RED, increase the total damage
	if (damagetype == WEAPON_RED_DT)
	{
		damage *= g_Float[red_radar_mult];
		return Plugin_Changed;	
	}
}
	
public Action ND_OnArmouryDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// If the damage type is a RED, increase the total damage	
	if (damagetype == WEAPON_RED_DT)
	{
		damage *= g_Float[red_armoury_mult];
		return Plugin_Changed;	
	}
}

public Action ND_OnPowerPlantDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// If the damage type is a RED, increase the total damage
	if (damagetype == WEAPON_RED_DT)
	{
		damage *= g_Float[red_power_plant_mult];
		return Plugin_Changed;	
	}
}

public Action ND_OnFlamerTurretDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// If the damage type is a RED, increase the total damage
	if (damagetype == WEAPON_RED_DT)
	{
		damage *= g_Float[red_ft_turret_mult];
		return Plugin_Changed;	
	}
}

public Action ND_OnArtilleryDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// If the damage type is a RED, increase the total damage
	if (damagetype == WEAPON_RED_DT)
	{
		damage *= g_Float[red_artillery_mult];
		return Plugin_Changed;
	}
}

public Action ND_OnTransportDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{	
	// If the damage type is a RED, increase the total damage
	if (damagetype == WEAPON_RED_DT)
	{
		damage *= g_Float[red_transport_mult];
		return Plugin_Changed;
	}
}		

public Action ND_OnBunkerDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	// If the damage type is flamethrower, reduce the total damage
	if (damagetype == WEAPON_NX300_DT)
	{
		damage *= g_Float[nx300_bunker_mult];
		return Plugin_Changed;	
	}
	
	// If the damage type is a RED, increase the total damage
	else if (damagetype == WEAPON_RED_DT)
	{
		damage *= g_Float[red_bunker_mult];
		return Plugin_Changed;	
	}
	
	//PrintToChatAll("The damage type is %d.", damagetype);
}

public Action ND_OnAssemblerDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	// If the damage type is a RED, increase the total damage
	if (damagetype == WEAPON_RED_DT)
	{
		damage *= g_Float[red_assembler_mult];
		return Plugin_Changed;	
	}
}
