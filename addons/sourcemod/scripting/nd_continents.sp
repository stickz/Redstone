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
#include <geoip>
     
// possible values are:
//AF = Africa
//EU = Europe
//AS = Asia
//NA = North America
//SA = South America
//AU = Australia
//AN = Antarctica
//XX = Unknown

new const 	String:aAfrica[][2] = {"AO","BF","BI","BJ","BW","CD","CF","CG","CI","CM","CV","DJ","DZ","EG","EH","ER","ET","GA","GH","GM","GN","GQ","GW","KE","KM","LR","LS","LY","MA","MG","ML","MR","MU","MW","MZ","NA","NE","NG","RE","RW","SC","SD","SH","SL","SN","SO","ST","SZ","TD","TG","TN","TZ","UG","YT","ZA","ZM","ZW"},
		String:aEurope[][2] = {"AD","AL","AT","AX","BA","BE","BG","BY","CH","CZ","DE","DK","EE","ES","EU","FI","FO","FR","FX","GB","GG","GI","GR","HR","HU","IE","IM","IS","IT","JE","LI","LT","LU","LV","MC","MD","ME","MK","MT","NL","NO","PL","PT","RO","RS","RU","SE","SI","SJ","SK","SM","TR","UA","VA"},
	      	String:aAsia[][2] = {"AE","AF","AM","AP","AZ","BD","BH","BN","BT","CC","CN","CX","CY","GE","HK","ID","IL","IN","IO","IQ","IR","JO","JP","KG","KH","KP","KR","KW","KZ","LA","LB","LK","MM","MN","MO","MV","MY","NP","OM","PH","PK","PS","QA","SA","SG","SY","TH","TJ","TL","TM","TW","UZ","VN","YE"},
		String:aNorthAmerica[][2] = {"AG","AI","AN","AW","BB","BL","BM","BS","BZ","CA","CR","CU","DM","DO","GD","GL","GP","GT","HN","HT","JM","KN","KY","LC","MF","MQ","MS","MX","NI","PA","PM","PR","SV","TC","TT","US","VC","VG","VI"},
		String:aAustralia[][2] = {"AS","AU","CK","FJ","FM","GU","KI","MH","MP","NC","NF","NR","NU","NZ","PF","PG","PN","PW","SB","TK","TO","TV","UM","VU","WF","WS"},
		String:aSouthAmerica[][2] = {"AR","BO","BR","CL","CO","EC","FK","GF","GY","PE","PY","SR","UY","VE"},
		String:aAntarctica[][2] = {"AQ","BV","GS","HM","TF"};

public OnPluginStart()
{
	RegConsoleCmd("sm_locations", CMD_CheckLocations);	
}

public Action:CMD_CheckLocations(client,args)
{
	new counter[8]; //in order of possible values	
	decl String:playerContinent[MAXPLAYERS + 1][2]; 
	
	for (new idx = 0; idx <= MaxClients; idx++)
		if (IsValidClient(idx))
		{
			playerContinent[idx] = getContient(idx);	
			counter[contientTOInteger(playerContinent[idx])]++;
		}
	
	decl String:printOut[128];
	for (new i = 0; i < sizeof(counter); i++)
	{
		if (!isContinentEmpty(counter[i]))
		{
			decl String:contient[16];
			Format(contient, sizeof(contient), " %s: %d", conientIntegerTOName(i), counter[i]);   
			StrCat(printOut, sizeof(printOut), contient);
		}
	}
	
	PrintToChat(client, "\x05[xG] %t: %s", "Player Locations", printOut);
}

public bool:isContinentEmpty(contientNumber)
{
	return contientNumber == 0;
}

String:conientIntegerTOName(value)
{
	decl String:Name[2];
	switch(value)
	{
		case 0: Name = "XX";
		case 1: Name = "EU";
		case 2: Name = "NA";
		case 3: Name = "AS";
		case 4: Name = "SA";
		case 5: Name = "AF";
		case 6: Name = "AN";	
	}
	return Name;
}

contientTOInteger(String:contString[2])
{
	if (StrEqual(contString, "EU"))
		return 1;			
	else if (StrEqual(contString, "NA"))
		return 2;				
	else if (StrEqual(contString, "AU"))
		return 3;				
	else if (StrEqual(contString, "AS"))
		return 4;				
	else if (StrEqual(contString, "SA"))
		return 5;			
	else if (StrEqual(contString, "AF"))
		return 6;				
	else if (StrEqual(contString, "AN"))
		return 7;				
	else
		return 0;
}

String:getContient(client)
{
	decl String:code[2];
	
	decl String:clientIp[16];			
	if(!GetClientIP(client, clientIp, sizeof(clientIp), true)) //failed to get IP of client, do not procede further
	{
		code = "XX";
		return code;
	}
                       
	decl String:countryCode[3];
	if (!GeoipCode2(clientIp, countryCode))  //failed to get Geo Location of client, do not procede further
	{
		code = "XX";
		return code;
	}
        
    //check Europe Array
	for(new i=0;i<sizeof(aEurope)-1;i++)
		if(StrEqual(aEurope[i],countryCode))
		{
			code = "EU";
			return code;
		}
	
	//check North America array
	for(new i=0;i<sizeof(aNorthAmerica)-1;i++)	
		if(StrEqual(aNorthAmerica[i],countryCode))
		{
			code = "NA";
			return code;
		}
	
	//check Australia array
	for(new i=0;i<sizeof(aAustralia)-1;i++)
		if(StrEqual(aAustralia[i],countryCode))                                   
		{
			code = "AU";
			return code;
		}
	
	//check Asia array
	for(new i=0;i<sizeof(aAsia)-1;i++)
		if(StrEqual(aAsia[i],countryCode))
		{
			code = "AS";
			return code;
		}
	
	//check South America array
	for(new i=0;i<sizeof(aSouthAmerica)-1;i++)
		if(StrEqual(aSouthAmerica[i],countryCode))
		{
			code = "SA";
			return code;
		}
	
	//check Africa array
	for(new i=0;i<sizeof(aAfrica)-1;i++)
		if(StrEqual(aAfrica[i],countryCode))
		{
			code = "AF";
			return code;
		}
	
	//check Antarctica array
	for(new i=0;i<sizeof(aAntarctica)-1;i++)
		if(StrEqual(aAntarctica[i],countryCode))
		{
			code = "AN";
			return code;
		}
                   
	// Not found, might be one of the special codes bug we'll just return an unknown!
	code = "XX";
	return code;
}

stock bool:IsValidClient(client, bool:nobots = true)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
        return false;

    return IsClientInGame(client); 
} 
