#include <nd_weapons>

#define WEAPON_EXPLO_DT 64

methodmap BaseHelper
{
	public static float RED_InfantryBoostMult(int ibLevel)
	{
		float mult = 1.0;
		
		switch (ibLevel)
		{
			case 0: mult = gFloat_RedMult[red_ib0_base_mult];
			case 1: mult = gFloat_RedMult[red_ib1_base_mult];
			case 2: mult = gFloat_RedMult[red_ib2_base_mult];
			case 3:	mult = gFloat_RedMult[red_ib3_base_mult];
		}
		
		return mult;		
	}
	
	public static float RED_InfantryBoostCooldown(int ibLevel)
	{
		float cd = 135.0;
		
		switch (ibLevel)
		{
			case 0: cd = gFloat_RedCooldown[red_ib0_base_mult];
			case 1: cd = gFloat_RedCooldown[red_ib1_base_mult];
			case 2: cd = gFloat_RedCooldown[red_ib2_base_mult];
			case 3:	cd = gFloat_RedCooldown[red_ib3_base_mult];
		}

		return cd;		
	}
	
	public static float LookAndSetIBMult(int &attacker)
	{
		// If there are no charges left for reds, return normal damage
		if (IBRedChargesLeft[attacker] == 0)
			return 1.0;
		
		// Get the attacker's team
		int team = GetClientTeam(attacker);
		
		// Deincrement the red charge count by one
		DecreaseRedCharges(attacker, team);
		
		// Return the Infantry Boost damage multiplier
		return InfantryBoostRedMults[team-2];
	}	
}

methodmap BaseStructure
{
	public static float GetInfantryBoostMult(int &attacker, int &inflictor, int &damagetype)
	{
		float mult = 1.0;
		
		// Check if damage type is explosive to eliminate iterations		
		if (damagetype == WEAPON_EXPLO_DT)
		{
			char className[64];
			GetEntityClassname(inflictor, className, sizeof(className));
			
			// Apply infantry boost red base damage mult
			if (InflictorIsRED(className))
				mult = BaseHelper.LookAndSetIBMult(attacker);
		}
		
		return mult;
	}	
}

methodmap Barrier
{
	public static float GetDamageMult(int &attacker, int &inflictor, int &damagetype)
	{
		float mult = 1.0;
		
		// Apply red base damage mult
		if (damagetype == WEAPON_EXPLO_DT && InflictorIsRED(iClass(inflictor)))
			mult = gFloat_RedMult[red_barrier_mult];
		
		return mult;
	}
}

methodmap Wall
{
	public static float GetDamageMult(int &attacker, int &inflictor, int &damagetype)
	{
		float mult = 1.0;
		
		// Apply red base damage mult
		if (damagetype == WEAPON_EXPLO_DT && InflictorIsRED(iClass(inflictor)))
			mult = gFloat_RedMult[red_wall_mult];
		
		return mult;
	}	
}

methodmap FlamerTurret
{
	public static float GetDamageMult(int &attacker, int &inflictor, int &damagetype)
	{
		float mult = 1.0;
		
		if (damagetype == WEAPON_EXPLO_DT && InflictorIsRED(iClass(inflictor)))
			mult = gFloat_RedMult[red_ft_turret_mult];
			
		return mult;
	}	
}

methodmap TransportGate
{
	public static float GetDamageMult(int &attacker, int &inflictor, int &damagetype)
	{
		float mult = 1.0;
		
		if (damagetype == WEAPON_EXPLO_DT && InflictorIsRED(iClass(inflictor)))
			mult = gFloat_RedMult[red_transport_mult];

		return mult;
	}	
}

methodmap Bunker
{
	public static float GetDamageMult(int &attacker, int &inflictor, int &damagetype)
	{
		float mult = 1.0;
		
		if (damagetype == WEAPON_EXPLO_DT && InflictorIsRED(iClass(inflictor)))
			mult = gFloat_RedMult[red_bunker_mult];
		
		return mult;
	}
}