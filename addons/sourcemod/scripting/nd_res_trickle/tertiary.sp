/* Tertiary struct and functions */
enum struct Tertiary 
{
	int arrayIndex;
	int entIndex;
	
	int owner;
	
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
			this.initialRes -= amount;
	
		else // Otherwise, update the team resources
		{
			switch (this.owner)
			{
				case TEAM_EMPIRE: this.empireRes -= amount;
				case TEAM_CONSORT: this.consortRes -= amount;
			}	
		}	
	}
}
