#define WEAPON_FLAME_DT -2147481592
#define WEAPON_BEAM_DT 0
#define WEAPON_BULLET_DT 2
#define WEAPON_EXPLO_DT 64

methodmap BaseHelper
{
	public static float BBQ_InfantryBoostMult(int ibLevel)
	{
		float mult = 1.0;
		
		switch(ibLevel)
		{
			case 1: mult = gFloat_Other[nx300_ib1_base_mult];
			case 2: mult = gFloat_Other[nx300_ib2_base_mult];
			case 3: mult = gFloat_Other[nx300_ib3_base_mult];	
		}
		
		return mult;
	}

	public static float GL_InfantryBoostMult(int ibLevel)
	{
		float mult = 1.0;
		
		switch(ibLevel)
		{
			case 1: mult = gFloat_GL[gl_ib1_base_mult];
			case 2: mult = gFloat_GL[gl_ib2_base_mult];
			case 3: mult = gFloat_GL[gl_ib3_base_mult];	
		}
		
		return mult;
	}

	public static float Siege_InfantryBoostMult(int ibLevel)
	{
		float mult = 1.0;
		
		switch (ibLevel)
		{
			case 0: mult = gFloat_Siege[siege_ib0_base_mult];
			case 1: mult = gFloat_Siege[siege_ib1_base_mult];
			case 2: mult = gFloat_Siege[siege_ib2_base_mult];
			case 3:	mult = gFloat_Siege[siege_ib3_base_mult];		
		}
		
		return mult;
	}
	
	public static float RED_InfantryBoostMult(int ibLevel)
	{
		float mult = 1.0;
		
		switch (ibLevel)
		{
			case 1: mult = gFloat_Red[red_ib1_base_mult];
			case 2: mult = gFloat_Red[red_ib2_base_mult];
			case 3:	mult = gFloat_Red[red_ib3_base_mult];
		}
		
		return mult;		
	}
	
	public static float Artillery_StructureReinMult(int srLevel)
	{
		float mult = 1.0;	
		
		switch(srLevel)
		{
			case 1: mult = gFloat_Other[artillery_ib1_base_mult];
			case 2: mult = gFloat_Other[artillery_ib2_base_mult];
			case 3: mult = gFloat_Other[artillery_ib3_base_mult];	
		}
		
		return mult;
	}

	public static float FastLookUpIBMult(int &attacker, ibMults mult)
	{
		int team = GetClientTeam(attacker);
		return InfantryBoostMults[team-2][mult];
	}

	public static float FastLookupArtilleryMult(int &attacker)
	{
		int oTeam = getOtherTeam(GetClientTeam(attacker));
		return ArtillerySRMult[oTeam-2];
	}	
}

methodmap BaseStructure
{
	public static float GetInfantryBoostMult(int &attacker, int &inflictor, int &damagetype)
	{
		float mult = 1.0;
		
		// Apply infantry boost x01 damage mult
		if (damagetype == WEAPON_BEAM_DT)
			mult = BaseHelper.FastLookUpIBMult(attacker, ibMultSIEGE);
		
		// Apply infantry boost nx300 damage mult
		else if (InflictorIsNX300(inflictor))
			mult = BaseHelper.FastLookUpIBMult(attacker, ibMultBBQ);
		
		// Check if damage type is explosive to eliminate iterations		
		else if (damagetype == WEAPON_EXPLO_DT)
		{
			char className[64];
			GetEntityClassname(inflictor, className, sizeof(className));
			
			// Apply structure reinforcement artillery protection
			if (InflictorIsArtillery(className))
				mult = BaseHelper.FastLookupArtilleryMult(attacker);
				
			// Apply infantry boost gl damage mult
			else if (InflictorIsGL(className))
				mult = BaseHelper.FastLookUpIBMult(attacker, ibMultGL);
				
			// Apply infantry boost m95 damage mult
			else if (InflcitorIsM95(className))
				mult = BaseHelper.FastLookUpIBMult(attacker, ibMultSIEGE);

			// Apply infantry boost red base damage mult
			else if (InflictorIsRED(className))
				mult = BaseHelper.FastLookUpIBMult(attacker, ibMultRED);
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
			mult = gFloat_Red[red_barrier_mult];
		
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
			mult = gFloat_Red[red_wall_mult];
		
		return mult;
	}	
}

methodmap SupplyStation
{
	public static float GetDamageMult(int &attacker, int &inflictor, int &damagetype)
	{
		float mult = 1.0;
		
		// Apply bullet base damage mult
		if (damagetype == WEAPON_BULLET_DT)
			mult = gFloat_Bullet[bullet_supply_station_mult];
		
		// Apply red base damage mult
		else if (damagetype == WEAPON_EXPLO_DT && InflictorIsRED(iClass(inflictor)))
			mult = gFloat_Red[red_supply_mult];
		
		return mult;
	}	
}

methodmap RocketTurret
{
	public static float GetDamageMult(int &attacker, int &inflictor, int &damagetype)
	{
		float mult = 1.0;
		
		// Apply bullet base damage mult
		if (damagetype == WEAPON_BULLET_DT)
			mult = gFloat_Bullet[bullet_rocket_turret_mult];
		
		return mult;
	}	
}

methodmap MGTurrent
{
	public static float GetDamageMult(int &attacker, int &inflictor, int &damagetype)
	{
		float mult = 1.0;
		
		// Apply bullet base damage mult
		if (damagetype == WEAPON_BULLET_DT)
			mult = gFloat_Bullet[bullet_mg_turret_mult];		
	
		return mult;		
	}	
}

methodmap Radar
{
	public static float GetDamageMult(int &attacker, int &inflictor, int &damagetype)
	{
		float mult = 1.0;
		
		// Apply bullet base damage mult
		if (damagetype == WEAPON_BULLET_DT)
			mult = gFloat_Bullet[bullet_radar_mult];
		
		return mult;
	}	
}

methodmap Armoury
{
	public static float GetDamageMult(int &attacker, int &inflictor, int &damagetype)
	{
		float mult = 1.0;
		
		// Apply bullet base damage mult
		if (damagetype == WEAPON_BULLET_DT)
			mult = gFloat_Bullet[bullet_armoury_mult];
		
		return mult;
	}	
}

methodmap PowerPlant
{
	public static float GetDamageMult(int &attacker, int &inflictor, int &damagetype)
	{
		float mult = 1.0;
				
		// Apply bullet base damage mult
		if (damagetype == WEAPON_BULLET_DT)
			mult = gFloat_Bullet[bullet_power_plant_mult];
		
		return mult;
	}
}

methodmap FlamerTurret
{
	public static float GetDamageMult(int &attacker, int &inflictor, int &damagetype)
	{
		float mult = 1.0;
		
		switch (damagetype)
		{
			case WEAPON_EXPLO_DT:
			{
				char className[64];
				GetEntityClassname(inflictor, className, sizeof(className));
				
				// Apply base gl damage mult
				if (InflictorIsGL(className))
					mult = gFloat_GL[gl_ft_turret_mult];
				
				// Apply red base damage mult
				else if (InflictorIsRED(className))
					mult = gFloat_Red[red_ft_turret_mult];
			}
			
			// Apply bullet base damage mult
			case WEAPON_BULLET_DT: mult = gFloat_Bullet[bullet_ft_turret_mult];
		}
		
		return mult;
	}	
}

methodmap Artillery
{
	public static float GetDamageMult(int &attacker, int &inflictor, int &damagetype)
	{
		float mult = 1.0;
		
		// Apply bullet base damage mult
		if (damagetype == WEAPON_BULLET_DT)
			mult = gFloat_Bullet[bullet_artillery_mult];

		// Apply red base damage mult
		else if (damagetype == WEAPON_EXPLO_DT && InflictorIsRED(iClass(inflictor)))
			mult = gFloat_Red[red_artillery_mult];
		
		return mult;
	}
}

methodmap TransportGate
{
	public static float GetDamageMult(int &attacker, int &inflictor, int &damagetype)
	{
		float mult = 1.0;
		
		switch (damagetype)
		{
			// Apply x01 base damage mult
			case WEAPON_BEAM_DT: mult = gFloat_Siege[siege_transport_mult];
			
			case WEAPON_EXPLO_DT:
			{
				char className[64];
				GetEntityClassname(inflictor, className, sizeof(className));				
				
				// Apply base gl damage mult
				if (InflictorIsGL(className))
					mult = gFloat_GL[gl_transport_mult];
				
				// Apply base m95 damage mult
				else if (InflcitorIsM95(className))
					mult = gFloat_Siege[siege_transport_mult];
				
				// Apply red base damage mult
				else if (InflictorIsRED(className))
					mult = gFloat_Red[red_transport_mult];
			}
			
			// Apply bullet base damage mult
			case WEAPON_BULLET_DT: mult = gFloat_Bullet[bullet_transport_mult];
		}
		
		return mult;	
	}	
}

methodmap Assembler
{
	public static float GetDamageMult(int &attacker, int &inflictor, int &damagetype)
	{
		float mult = 1.0;
		
		switch (damagetype)
		{
			case WEAPON_EXPLO_DT:	 
			{ 
				char className[64];
				GetEntityClassname(inflictor, className, sizeof(className));
				
				// Apply base gl damage mult
				if (InflictorIsGL(className))
					mult = gFloat_GL[gl_assembler_mult];
				
				// Apply red base damage mult
				else if (InflictorIsRED(className))
					mult = gFloat_Red[red_assembler_mult];
			}
			
			// Apply bullet base damage mult
			case WEAPON_BULLET_DT: mult = gFloat_Bullet[bullet_assembler_mult];
		}
		
		return mult;
	}	
}

methodmap Bunker
{
	public static float GetDamageMult(int &attacker, int &inflictor, int &damagetype)
	{
		float mult = 1.0;
		
		// Apply base x01 damage mult
		if (damagetype == WEAPON_BEAM_DT)
			mult = gFloat_Siege[siege_bunker_mult];
		
		// Check if damage type is explosive to eliminate iterations
		else if (damagetype == WEAPON_EXPLO_DT)
		{
			char className[64];
			GetEntityClassname(inflictor, className, sizeof(className));
				
			// Apply base gl damage mult
			if (InflictorIsGL(className))
				mult = gFloat_GL[gl_bunker_mult];					
				
			// Apply base m95 damage mult
			else if (InflcitorIsM95(className))
				mult = gFloat_Siege[siege_bunker_mult];
				
			// Apply red base damage mult
			else if (InflictorIsRED(className))
				mult = gFloat_Red[red_bunker_mult];			
		}
		
		// Apply the bunker damage reduction mult
		else if (InflictorIsNX300(inflictor))
			mult = gFloat_Other[nx300_bunker_mult];
		
		return mult;
	}
}