/*
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <nd_rounds>
#include <nd_maps>
#include <nd_struct_eng>

#define DEBUG 0

bool validMap = false;

ArrayList HAX = null;

int tmpAxisCount;
int tmpAxisViolated;

//Version is auto-filled by the travis builder
public Plugin myinfo = 
{
	name 		= "[ND] Off Map Buildings Fixes",
	author 		= "yed_, stickz",
    	description 	= "Prevents building things in glitched locations",
    	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
}

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_offmap_fixes/nd_offmap_fixes.txt"
#include "updater/standard.sp"

public void OnPluginStart() 
{
	HAX = new ArrayList(6);	
    	AddUpdaterLibrary(); //auto-updater

	// Add late loading support
	if (ND_RoundStarted())
		ND_OnRoundStarted();
}

public void ND_OnRoundStarted()
{
    	char currentMap[64];
    	GetCurrentMap(currentMap, sizeof(currentMap));
    
    	HAX.Clear();

    	if (StrEqual(currentMap, ND_StockMaps[ND_Hydro], false)) 
		HandleHydro();
	else if (StrEqual(currentMap, ND_StockMaps[ND_Coast], false))
        	HandleCoast();
    	else if (StrEqual(currentMap, ND_StockMaps[ND_Gate], false))
        	HandleGate();
  	  	
    	validMap = GetArraySize(HAX) > 0;
}

public void ND_OnRoundEnded() {
	validMap = false;
}

public void OnMapEnd() {
    	validMap = false;
}

void HandleGate() 
{
    /*
    +
    y
    - x +

    this one handles the spot close to prime

    a - 3668.344726 1132.599365 0.000000
    b - 4004.024658 1103.116699 154.177978
    c - 4627.127929 1161.775512 -63.968750
    d - 4634.593750 944.216247 -63.968750

       |
      d|
      cba
       |
       |
    */
    float hax[6] = {0.0, ...};
    hax[0] = 4000.0; //minX
    HAX.PushArray(hax);
}

void HandleHydro() 
{
    /*
    -
    y
    + x -

    this one disable building from east secondary to Cons base

    */

    float hax[6] = {
        0.0,
        -7000.0,    //maxX
        0.0,
        -1000.0     //maxY
    };
    HAX.PushArray(hax);
    
    // this disables building off cons base 
    
    float hax[6] = {0.0, ...};
    hax[0] = -5215.0;    // minX
    hax[1] = -4200.0;    // maxX
    hax[2] = -6590.0;       // minY
    hax[3] = -4125.0;      // maxY
    hax[4] = 0.0;       // minZ
    hax[5] = 0.0;       // maxZ
    HAX.PushArray(hax);
}

void HandleCoast()
{
	/*
    - y +
    x
    +

    roof
    x - 5246.656250 59.499198 1615.631225
    w - 5247.633300 -726.002502 1615.631225
    v - 4465.646484 49.810642 1615.631225
    
    -----v
         |
    w----x
    */

	float hax[6] = {0.0, ...};
	hax[0] = 4466.0;    // minX
	hax[1] = 5246.0;    // maxX
	hax[2] = 0.0;       // minY
	hax[3] = 62.0;      // maxY
	hax[4] = 0.0;       // minZ
	hax[5] = 0.0;       // maxZ
	HAX.PushArray(hax);

    /*
    east secondary
    b - 5217.833984 6646.136230 95.915893
    c - 3518.860351 6597.848144 49.899757

     c ------
     |    
     |
     b ------

    - y +
    x
    +
    */

	hax[0] = 3518.0;    // minX
	hax[1] = 5217.0;    // maxX
	hax[2] = 6597.0;    // minY
	hax[3] = 0.0;       // maxY
	hax[4] = 0.0;       // minZ
	hax[5] = 0.0;       // maxZ
	HAX.PushArray(hax);
	
	/* 
	Car showcase 
	e - -1353.12 2051.90 2.43
	f - -1353.12 2561.27 2.43
	g - -2932.30 2051.90 2.43
	h - -2932.30 2561.27 2.43
	
	e --- f
	|	  |
	|	  |
	h --- g
	*/
	hax[0] = -2933.0;   // minX
	hax[1] = -1354.0;   // maxX
	hax[2] = 2052.0;    // minY
	hax[3] = 2562.0;    // maxY
	hax[4] = 0.0;       // minZ
	hax[5] = 0.0;       // maxZ
	HAX.PushArray(hax);
	
	
	/* 
	Watch Tower
	i - 5604.85 6513.77 886.00
	j - 5312.30 6513.77 886.00
	k - 5604.85 6870.38 886.00
	l - 5312.30 6870.38 886.00
	*/
	hax[0] = 5313.0;    // minX
	hax[1] = 5605.0;    // maxX
	hax[2] = 6514.0;    // minY
	hax[3] = 6871.0;    // maxY
	hax[4] = 0.0;       // minZ
	hax[5] = 0.0;       // maxZ
	HAX.PushArray(hax);
	
	/* North-West Tertiary #1
	m - -3649.70 1654.13 166.66
	n -  0.0 2000 0.0
	*/
	hax[0] = -0.0; 	    // minX
	hax[1] = -3649.70;  // maxX
	hax[2] = 0.0; 	    // minY
	hax[3] = 2000.0;    // maxY
	hax[4] = 0.0;       // minZ
	hax[5] = 0.0;       // maxZ
	HAX.PushArray(hax);
	
	/* North-West Tertiary #2
	o - 0.0 -1190 0.0
	p - -550.0 0.0 0.0
	*/
	hax[0] = -0.0;      // minX
	hax[1] = -550.00;   // maxX
	hax[2] = 0.0; 	    // minY
	hax[3] = -1190.0; 	// maxY
	hax[4] = 0.0;       // minZ
	hax[5] = 0.0;       // maxZ
	HAX.PushArray(hax);
	
	/* Prime
	q - 2006.44 1172.47 689.73
	r - 4350.16 1172.47 689.73
	s - 2006.44 915.85 689.73
	t - 4350.16 915.85 689.73
	*/	
	hax[0] = 2007.0;    // minX
	hax[1] = 4351.0;    // maxX
	hax[2] = 916.0;     // minY
	hax[3] = 1173.0;    // maxY
	hax[4] = 150.0;       // minZ
	hax[5] = 0.0;     // maxZ
	HAX.PushArray(hax);	
	
	/* Behind bus
	u - 5490.87 3189.10 -1.0
	v - 5490.87 2278.26 -1.0
	w - 5685.81 3189.10 -1.0
	x - 5685.81 2278.26 -1.0
	*/
	hax[0] = 5491.0;   	// minX
	hax[1] = 5686.0;   	// maxX
	hax[2] = 2279.0;   	// minY
	hax[3] = 3190.0;   	// maxY
	hax[4] = 0.0;      	// minZ
	hax[5] = 50.0;     	// maxZ
	HAX.PushArray(hax);
}

public void ND_OnStructureCreated(int entity, const char[] classname) {
    if (validMap)
        CreateTimer(0.1, CheckBorders, entity);
}

public Action CheckBorders(Handle timer, any entity) 
{
    if (!IsValidEdict(entity))
        return Plugin_Handled;

    float position[3];
    GetEntPropVector(entity, Prop_Data, "m_vecOrigin", position);
    //PrintToChatAll("placed location %f - %f - %f", position[0], position[1], position[2]);
    float hax[6];

    for (int i = 0; i < GetArraySize(HAX); i++)
    {
        tmpAxisCount = 0;
        tmpAxisViolated = 0;

        // minX
        HAX.GetArray(i, hax);
        if (hax[0] != 0.0)
        {
      	    tmpAxisCount++;

            if (hax[0] < position[0])
                tmpAxisViolated++;
        }

        // maxX
        if (hax[1] != 0.0)
        {
      	    tmpAxisCount++;

            if (hax[1] > position[0])
      	        tmpAxisViolated++;
        }

        if (hax[2] != 0.0)
        {
      	    tmpAxisCount++;

      	    if (hax[2] < position[1])
      	        tmpAxisViolated++;
        }

        if (hax[3] != 0.0)
        {
      	    tmpAxisCount++;

            if (hax[3] > position[1])
                tmpAxisViolated++;
        }

        if (hax[4] != 0.0)
        {
            tmpAxisCount++;

            if (hax[4] < position[2])
                tmpAxisViolated++;
        }

        if (hax[5] != 0.0)
        {
            tmpAxisCount++;

            if (hax[5] > position[2])
                tmpAxisViolated++;
        }

        if (tmpAxisViolated && (tmpAxisCount == tmpAxisViolated))
            SDKHooks_TakeDamage(entity, 0, 0, 10000.0);
    }

    return Plugin_Handled;
}
