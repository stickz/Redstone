/* ResPoint struct and functions */
enum struct ResPoint 
{
	int type;
	
	int arrayIndex;
	int entIndex;
	
	int owner;
	int timeOwned;
	
	int firstFrack;
	
	int initialRes;
	int empireRes;
	int consortRes;	
	
	int GetRes() 
	{
		// Add the initial resources
		int resources = this.initialRes;	
		
		// Add the team resources
		switch (this.owner)
		{
			case TEAM_EMPIRE: resources += this.empireRes;
			case TEAM_CONSORT: resources += this.consortRes;
		}
		
		// Return the initial resources plus the team resources
		return resources;			
	}
	
	int GetResTeam(int team)
	{
		// Add the initial resources
		int resources = this.initialRes;	
		
		// Add the team resources
		switch (team)
		{
			case TEAM_EMPIRE: resources += this.empireRes;
			case TEAM_CONSORT: resources += this.consortRes;			
		}
		
		// Return the initial resources plus the team resources
		return resources;
	}
	
	int GetResTeamOnly(int team)
	{
		int resources = 0;
		
		switch (team)
		{
			case TEAM_EMPIRE: resources += this.empireRes;
			case TEAM_CONSORT: resources += this.consortRes;			
		}
		
		return resources;
	}
	
	int SetRes(int team, int amount)
	{
		switch (team)
		{
			case TEAM_EMPIRE: this.empireRes = amount;
			case TEAM_CONSORT: this.consortRes = amount;
			default: this.initialRes = amount;			
		}		
	}
	
	int AddRes(int team, int amount)
	{
		switch (team)
		{
			case TEAM_EMPIRE: this.empireRes += amount;
			case TEAM_CONSORT: this.consortRes += amount;
			default: this.initialRes += amount;			
		}		
	}
	
	int SubtractRes(int amount)
	{
		// If the initial resources is greater than 0, update it
		if (this.initialRes > 0)
		{
			this.initialRes -= amount; // Clamp initial resources at 0
			this.initialRes = Math_Min(this.initialRes, 0);
		}
	
		else // Otherwise, update the team resources
		{
			switch (this.owner)
			{
				case TEAM_EMPIRE: 
				{
					this.empireRes -= amount; // Clamp empire resources at 0
					this.empireRes = Math_Min(this.empireRes, 0);					
				}
				
				case TEAM_CONSORT: 
				{
					this.consortRes -= amount; // Clamp consort resources at 0
					this.consortRes = Math_Min(this.consortRes, 0);
				}
			}
		}
	}
	
	int SubtractResTeam(int team, int amount)
	{
		switch (team)
		{
			case TEAM_EMPIRE: 
			{
				this.empireRes -= amount; // Clamp empire resources at 0
				this.empireRes = Math_Min(this.empireRes, 0);					
			}
				
			case TEAM_CONSORT: 
			{
				this.consortRes -= amount; // Clamp consort resources at 0
				this.consortRes = Math_Min(this.consortRes, 0);
			}
		}		
	}
}
