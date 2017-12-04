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
	HAX = new ArrayList(4);	
    	AddUpdaterLibrary(); //auto-updater
}

public void ND_OnRoundStarted()
{
    	char currentMap[64];
    	GetCurrentMap(currentMap, sizeof(currentMap));
    
    	HAX.Clear();

    	if (StrEqual(currentMap, ND_StockMaps[ND_Hydro])) 
		HandleHydro();
	else if (StrEqual(currentMap, ND_StockMaps[ND_Coast]))
        	HandleCoast();
    	else if (StrEqual(currentMap, ND_StockMaps[ND_Gate]))
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
    float hax[4] = {0.0, ...};
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

    float hax[4] = {
        0.0,
        -7000.0,    //maxX
        0.0,
        -1000.0     //maxY
    };
    HAX.PushArray(hax);
}

void HandleCoast() 
{
    /*
    - y +
    x
    +

    roof
    x - 5246.656250 52.499198 1615.631225
    w - 5247.633300 -726.002502 1615.631225
    v - 4465.646484 49.810642 1615.631225
    
    -----v
         |
    w----x
    */

    float hax[4] = {0.0, ...};
    hax[0] = 4466.0;    // minX
    hax[1] = 5246.0;    // maxX
    hax[2] = 0.0;       // minY
    hax[3] = 52.0;      // maxY
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
    HAX.PushArray(hax);
}

public void ND_OnStructureCreated(int entity, const char[] classname) {
    if (validMap)
    	CreateTimer(0.1, CheckBorders, entity);
}

public Action CheckBorders(Handle timer, any entity) 
{
    if (!IsValidEdict(entity))
    	return;
    	
    float position[3];
    GetEntPropVector(entity, Prop_Data, "m_vecOrigin", position);
    //PrintToChatAll("placed location %f - %f - %f", position[0], position[1], position[2]);
    float hax[4];
    
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
      			
            #if DEBUG == 1
      	    PrintToChatAll("checking max X hax %f > pos %f?", hax[1], position[0]);
            #endif
      
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
    
    	if (tmpAxisViolated && (tmpAxisCount == tmpAxisViolated))
    	    SDKHooks_TakeDamage(entity, 0, 0, 10000.0);
    }
}
