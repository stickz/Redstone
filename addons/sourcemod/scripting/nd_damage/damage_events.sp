#define BLOCK_DAMAGE 0.0

// Notice: gFloat arrays must be assigned to a varriable first, otherwise it will crash the server.
// Notice2: Floats cannot be multipled by each other before the damage assignment.
// They must be multiplied seperately, otherwise it will crash the server crash.
// See Here: https://github.com/alliedmodders/sourcemod/issues/800

// To Do: Do something with these structures later
public Action ND_OnBarrierDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	// If the inflictor or attacker is not valid, exit without updating damage
	if (!IsValidEntity(inflictor) || !IsValidBounds(attacker))
		return Plugin_Continue;
	
	// Increase x01 damage by 50% when less than 25
	if (damagetype == WEAPON_BEAM_DT)
		damage = SetMinX01DamageByMult(damage);
	
	// Get the damage multipler from the base structure methodmap
	float multIB = BaseStructure.GetInfantryBoostMult(attacker, inflictor, damagetype);
	damage *= multIB;
	
	// Get the damage multipler from the barrier methodmap
	float multipler = Barrier.GetDamageMult(attacker, inflictor, damagetype);
	damage *= multipler;
	
	// Return changed to update the damage
	return Plugin_Changed;
}
public Action ND_OnWallDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	// If the inflictor or attacker is not valid, exit without updating damage
	if (!IsValidEntity(inflictor) || !IsValidBounds(attacker))
		return Plugin_Continue;
	
	// Set min wall damage to 35 * 4.23 = 148
	if (damagetype == WEAPON_BEAM_DT && damage < fMinWallDamageX01)
		damage = fMinWallDamageX01;
	
	// Get the damage multipler from the base structure methodmap
	float multIB = BaseStructure.GetInfantryBoostMult(attacker, inflictor, damagetype);
	damage *= multIB;
		
	// Get the damage multipler from the wall methodmap
	float multipler = Wall.GetDamageMult(attacker, inflictor, damagetype);
	damage *= multipler;

	// Return changed to update the damage
	return Plugin_Changed;
}

public Action ND_OnSupplyStationDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// If the inflictor or attacker is not valid, exit without updating damage
	if (!IsValidEntity(inflictor) || !IsValidBounds(attacker))
		return Plugin_Continue;
		
	// Increase x01 damage by 50% when less than 25
	if (damagetype == WEAPON_BEAM_DT)
		damage = SetMinX01DamageByMult(damage);

	// Get the damage multipler from the base structure methodmap
	float multIB = BaseStructure.GetInfantryBoostMult(attacker, inflictor, damagetype);
	damage *= multIB;	
		
	// Get the damage multipler from the supply station methodmap
	float multipler = SupplyStation.GetDamageMult(attacker, inflictor, damagetype);
	damage *= multipler;
	
	// Return changed to update the damage
	return Plugin_Changed;
}

public Action ND_OnRocketTurretDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// If the inflictor or attacker is not valid, exit without updating damage
	if (!IsValidEntity(inflictor) || !IsValidBounds(attacker))
		return Plugin_Continue;
	
	// Increase x01 damage by 50% when less than 25
	if (damagetype == WEAPON_BEAM_DT)
		damage = SetMinX01DamageByMult(damage);
	
	// Get the damage multipler from the base structure methodmap
	float multIB = BaseStructure.GetInfantryBoostMult(attacker, inflictor, damagetype);
	damage *= multIB;
	
	// Get the damage multipler from the rocket turret methodmap
	float multipler = RocketTurret.GetDamageMult(attacker, inflictor, damagetype);
	damage *= multipler;

	// Return changed to update the damage
	return Plugin_Changed;	
}

public Action ND_OnMGTurretDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// If the inflictor or attacker is not valid, exit without updating damage
	if (!IsValidEntity(inflictor) || !IsValidBounds(attacker))
		return Plugin_Continue;
	
	// Increase x01 damage by 50% when less than 25
	if (damagetype == WEAPON_BEAM_DT)
		damage = SetMinX01DamageByMult(damage);
	
	// Get the damage multipler from the base structure methodmap
	float multIB = BaseStructure.GetInfantryBoostMult(attacker, inflictor, damagetype);
	damage *= multIB;
	
	// Get the damage multipler from the mg turret methodmap
	float multiplier = MGTurrent.GetDamageMult(attacker, inflictor, damagetype);
	damage *= multiplier;
	
	// Return changed to update the damage
	return Plugin_Changed;		
}

public Action ND_OnRadarDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// If the inflictor or attacker is not valid, exit without updating damage
	if (!IsValidEntity(inflictor) || !IsValidBounds(attacker))
		return Plugin_Continue;
	
	// Increase x01 damage by 50% when less than 25
	if (damagetype == WEAPON_BEAM_DT)
		damage = SetMinX01DamageByMult(damage);
	
	// Get the damage multipler from the base structure methodmap
	float multIB = BaseStructure.GetInfantryBoostMult(attacker, inflictor, damagetype);
	damage *= multIB;
	
	// Get the damage multipler from the radar methodmap
	float multiplier = Radar.GetDamageMult(attacker, inflictor, damagetype);
	damage *= multiplier;
	
	// Return changed to update the damage
	return Plugin_Changed;	
}
	
public Action ND_OnArmouryDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// If the inflictor or attacker is not valid, exit without updating damage
	if (!IsValidEntity(inflictor) || !IsValidBounds(attacker))
		return Plugin_Continue;
	
	// Increase x01 damage by 50% when less than 25
	if (damagetype == WEAPON_BEAM_DT)
		damage = SetMinX01DamageByMult(damage);
	
	// Get the damage multipler from the base structure methodmap
	float multIB = BaseStructure.GetInfantryBoostMult(attacker, inflictor, damagetype);
	damage *= multIB;
	
	// Get the damage multipler from the armoury methodmap
	float multiplier = Armoury.GetDamageMult(attacker, inflictor, damagetype);
	damage *= multiplier;
	
	// Return changed to update the damage
	return Plugin_Changed;
}

public Action ND_OnPowerPlantDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// If the inflictor or attacker is not valid, exit without updating damage
	if (!IsValidEntity(inflictor) || !IsValidBounds(attacker))
		return Plugin_Continue;
	
	// Increase x01 damage by 50% when less than 25
	if (damagetype == WEAPON_BEAM_DT)
		damage = SetMinX01DamageByMult(damage);
	
	// Get the damage multipler from the base structure methodmap
	float multIB = BaseStructure.GetInfantryBoostMult(attacker, inflictor, damagetype);
	damage *= multIB;
	
	// Get the damage multipler from the armoury methodmap
	float multiplier = PowerPlant.GetDamageMult(attacker, inflictor, damagetype);
	damage *= multiplier;
	
	// Return changed to update the damage
	return Plugin_Changed;
}

public Action ND_OnFlamerTurretDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// If the inflictor or attacker is not valid, exit without updating damage
	if (!IsValidEntity(inflictor) || !IsValidBounds(attacker))
		return Plugin_Continue;
	
	// Increase x01 damage by 50% when less than 25
	if (damagetype == WEAPON_BEAM_DT)
		damage = SetMinX01DamageByMult(damage);
	
	// Get the damage multipler from the base structure methodmap
	float multIB = BaseStructure.GetInfantryBoostMult(attacker, inflictor, damagetype);
	damage *= multIB;
	
	// Get the damage multipler from the flamer turret methodmap
	float multiplier = FlamerTurret.GetDamageMult(attacker, inflictor, damagetype);
	damage *= multiplier;
	
	// Return changed to update the damage
	return Plugin_Changed;
}

public Action ND_OnArtilleryDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// If the inflictor or attacker is not valid, exit without updating damage
	if (!IsValidEntity(inflictor) || !IsValidBounds(attacker))
		return Plugin_Continue;
	
	// Increase x01 damage by 50% when less than 25
	if (damagetype == WEAPON_BEAM_DT)
		damage = SetMinX01DamageByMult(damage);
	
	// Get the damage multipler from the base structure methodmap
	float multIB = BaseStructure.GetInfantryBoostMult(attacker, inflictor, damagetype);
	damage *= multIB;
	
	// Get the damage multipler from the artillery methodmap
	float multiplier = Artillery.GetDamageMult(attacker, inflictor, damagetype);
	damage *= multiplier;
	
	// Return changed to update the damage
	return Plugin_Changed;
}

public Action ND_OnTransportDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// If the inflictor or attacker is not valid, exit without updating damage
	if (!IsValidEntity(inflictor) || !IsValidBounds(attacker))
		return Plugin_Continue;
	
	// Increase x01 damage by 50% when less than 25
	if (damagetype == WEAPON_BEAM_DT)
		damage = SetMinX01DamageByMult(damage);
	
	// Get the damage multipler from the base structure methodmap
	float multIB = BaseStructure.GetInfantryBoostMult(attacker, inflictor, damagetype);
	damage *= multIB;
	
	// Get the damage multipler from the transport gate methodmap
	float multiplier = TransportGate.GetDamageMult(attacker, inflictor, damagetype);
	damage *= multiplier;
	
	// Return changed to update the damage
	return Plugin_Changed;
}		

public Action ND_OnAssemblerDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	// If the inflictor or attacker is not valid, exit without updating damage
	if (!IsValidEntity(inflictor) || !IsValidBounds(attacker))
		return Plugin_Continue;
	
	// Increase x01 damage by 50% when less than 25
	if (damagetype == WEAPON_BEAM_DT)
		damage = SetMinX01DamageByMult(damage);
	
	// Get the damage multipler from the base structure methodmap
	float multIB = BaseStructure.GetInfantryBoostMult(attacker, inflictor, damagetype);
	damage *= multIB;
	
	// Get the damage multipler from the assembler methodmap
	float multiplier = Assembler.GetDamageMult(attacker, inflictor, damagetype);
	damage *= multiplier;
	
	// Return changed to update the damage
	return Plugin_Changed;
}

public Action ND_OnBunkerDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	// Disable bunker damage during warmup round, if convar is enabled
	if (!ND_RoundStarted() && cvarNoWarmupBunkerDamage.BoolValue)
	{
		damage = BLOCK_DAMAGE;
		return Plugin_Changed;
	}
	
	// If the inflictor or attacker is not valid, exit without updating damage
	if (!IsValidEntity(inflictor) || !IsValidBounds(attacker))
		return Plugin_Continue;
	
	// Increase x01 damage by 50% when less than 25
	if (damagetype == WEAPON_BEAM_DT)
		damage = SetMinX01DamageByMult(damage);
	
	// Get the damage multipler from the base structure methodmap
	float multIB = BaseStructure.GetInfantryBoostMult(attacker, inflictor, damagetype);
	damage *= multIB;

	// Get the damage multipler from the assembler methodmap
	float multiplier = Bunker.GetDamageMult(attacker, inflictor, damagetype);
	damage *= multiplier;
	
	// Return changed to update the damage
	return Plugin_Changed;
}

float SetMinX01DamageByMult(float damage) {	
	return damage > iMinThresholdX01 ? damage : damage * fMinIncreaseX01;
}