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

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_continents/nd_continents.txt"
#include "updater/standard.sp"

#pragma newdecls required
#include <sourcemod>
#include <geoip2>
#include <nd_redstone>
     
// possible values are:
//AF = Africa
//EU = Europe
//AS = Asia
//NA = North America
//SA = South America
//AU = Australia
//AN = Antarctica
//XX = Unknown

char	aAfrica[][2] = {"AO","BF","BI","BJ","BW","CD","CF","CG","CI","CM","CV","DJ","DZ","EG","EH","ER","ET","GA","GH","GM","GN","GQ","GW","KE","KM","LR","LS","LY","MA","MG","ML","MR","MU","MW","MZ","NA","NE","NG","RE","RW","SC","SD","SH","SL","SN","SO","ST","SZ","TD","TG","TN","TZ","UG","YT","ZA","ZM","ZW"},
	aEurope[][2] = {"AD","AL","AT","AX","BA","BE","BG","BY","CH","CZ","DE","DK","EE","ES","EU","FI","FO","FR","FX","GB","GG","GI","GR","HR","HU","IE","IM","IS","IT","JE","LI","LT","LU","LV","MC","MD","ME","MK","MT","NL","NO","PL","PT","RO","RS","RU","SE","SI","SJ","SK","SM","TR","UA","VA"},
	aAsia[][2] = {"AE","AF","AM","AP","AZ","BD","BH","BN","BT","CC","CN","CX","CY","GE","HK","ID","IL","IN","IO","IQ","IR","JO","JP","KG","KH","KP","KR","KW","KZ","LA","LB","LK","MM","MN","MO","MV","MY","NP","OM","PH","PK","PS","QA","SA","SG","SY","TH","TJ","TL","TM","TW","UZ","VN","YE"},
	aNorthAmerica[][2] = {"AG","AI","AN","AW","BB","BL","BM","BS","BZ","CA","CR","CU","DM","DO","GD","GL","GP","GT","HN","HT","JM","KN","KY","LC","MF","MQ","MS","MX","NI","PA","PM","PR","SV","TC","TT","US","VC","VG","VI"},
	aAustralia[][2] = {"AS","AU","CK","FJ","FM","GU","KI","MH","MP","NC","NF","NR","NU","NZ","PF","PG","PN","PW","SB","TK","TO","TV","UM","VU","WF","WS"},
	aSouthAmerica[][2] = {"AR","BO","BR","CL","CO","EC","FK","GF","GY","PE","PY","SR","UY","VE"},
	aAntarctica[][2] = {"AQ","BV","GS","HM","TF"};

public Plugin myinfo =
{
	name 		= "[ND] Continents",
	author 		= "Stickz",
	description 	= "Show a player's continent based on their IP.",
	version		= "dummy",
	url		= "https://github.com/stickz/Redstone/"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_locations", CMD_CheckLocations);
	LoadTranslations("nd_continents.phrases");
	
	AddUpdaterLibrary(); //auto-updater
}

public Action CMD_CheckLocations(int client, int args)
{
	int counter[8]; //in order of possible values	
	char playerContinent[MAXPLAYERS + 1][2]; 
	
	for (int idx = 0; idx <= MaxClients; idx++)
		if (RED_IsValidClient(idx))
		{
			playerContinent[idx] = getContient(idx);	
			counter[contientTOInteger(playerContinent[idx])]++;
		}
	
	char printOut[128];
	for (int i = 0; i < sizeof(counter); i++)
	{
		if (!isContinentEmpty(counter[i]))
		{
			char contient[16];
			Format(contient, sizeof(contient), " %s: %d", conientIntegerTOName(i), counter[i]);   
			StrCat(printOut, sizeof(printOut), contient);
		}
	}
	
	PrintToChat(client, "\x05[xG] %t", "Player Locations", printOut);
}

public bool isContinentEmpty(int contientNumber)
{
	return contientNumber == 0;
}

char conientIntegerTOName(int value)
{
	char Name[2];
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

int contientTOInteger(char contString[2])
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
		
	return 0;
}

char getContient(int client)
{
	char code[2];
	
	char clientIp[16];			
	if(!GetClientIP(client, clientIp, sizeof(clientIp), true)) //failed to get IP of client, do not procede further
	{
		code = "XX";
		return code;
	}
                       
	char countryCode[3];
	if (!GeoipCode2(clientIp, countryCode))  //failed to get Geo Location of client, do not procede further
	{
		code = "XX";
		return code;
	}
        
    //check Europe Array
	for(int i=0;i<sizeof(aEurope)-1;i++)
		if(StrEqual(aEurope[i],countryCode))
		{
			code = "EU";
			return code;
		}
	
	//check North America array
	for(int i=0;i<sizeof(aNorthAmerica)-1;i++)	
		if(StrEqual(aNorthAmerica[i],countryCode))
		{
			code = "NA";
			return code;
		}
	
	//check Australia array
	for(int i=0;i<sizeof(aAustralia)-1;i++)
		if(StrEqual(aAustralia[i],countryCode))                                   
		{
			code = "AU";
			return code;
		}
	
	//check Asia array
	for(int i=0;i<sizeof(aAsia)-1;i++)
		if(StrEqual(aAsia[i],countryCode))
		{
			code = "AS";
			return code;
		}
	
	//check South America array
	for(int i=0;i<sizeof(aSouthAmerica)-1;i++)
		if(StrEqual(aSouthAmerica[i],countryCode))
		{
			code = "SA";
			return code;
		}
	
	//check Africa array
	for(int i=0;i<sizeof(aAfrica)-1;i++)
		if(StrEqual(aAfrica[i],countryCode))
		{
			code = "AF";
			return code;
		}
	
	//check Antarctica array
	for(int i=0;i<sizeof(aAntarctica)-1;i++)
		if(StrEqual(aAntarctica[i],countryCode))
		{
			code = "AN";
			return code;
		}
                   
	// Not found, might be one of the special codes bug we'll just return an unknown!
	code = "XX";
	return code;
}
