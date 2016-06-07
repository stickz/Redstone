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
#include <nd_stocks>
#include <sdktools>
#include <sdkhooks>

#define COMMAND_BUNKER 0

public OnPluginStart()
{
	HookEvent("structure_death", Event_StructDeath);
	HookEvent("structure_damage_sparse", Event_BunkerDamage);
}

public Event_StructDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetEventInt(event, "type") == COMMAND_BUNKER)
	{
		new client = GetClientOfUserId(GetEventInt(event, "attacker")),	
		team = getOtherTeam(GetClientTeam(client));			
		RemoveTransportGates(team);
	}
}

public Event_BunkerDamage(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetEventBool(event, "bunker"))
	{
		new bunkerIDX = GetEventInt(event, "entindex");
		new health = GetEntProp(bunkerIDX, Prop_Send, "m_iHealth");
		
		if (health < 1500)
		{
			new team = GetEventInt(event, "ownerteam");
			RemoveTransportGates(team);
		}
	}
}

RemoveTransportGates(team)
{
	// loop through all entities finding transport gates
	new loopEntity = INVALID_ENT_REFERENCE;
	while ((loopEntity = FindEntityByClassname(loopEntity, "struct_transport_gate")) != INVALID_ENT_REFERENCE)
	{
		if (GetEntProp(loopEntity, Prop_Send, "m_iTeamNum") == team)
		{
			SDKHooks_TakeDamage(loopEntity, 0, 0, 10000.0);
			//AcceptEntityInput(loopEntity, "Kill");		
		}	
	}
}
