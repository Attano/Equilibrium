/*
	SourcePawn is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved.
	SourceMod is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved.
	Pawn and SMALL are Copyright (C) 1997-2008 ITB CompuPhase.
	Source is Copyright (C) Valve Corporation.
	All trademarks are property of their respective owners.

	This program is free software: you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the
	Free Software Foundation, either version 3 of the License, or (at your
	option) any later version.

	This program is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	General Public License for more details.

	You should have received a copy of the GNU General Public License along
	with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new Float:block_square[4];

new Handle:hSpitBlockSquares;

new bool:lateLoad;

public Plugin:myinfo =
{
	name = "L4D2 Spit Blocker",
	author = "ProdigySim + Estoopi + Jacob, Visor (:D)",
	description = "Blocks spit damage on various maps",
	version = "2.0",
	url = "https://github.com/Attano/Equilibrium"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	lateLoad=late;
	return APLRes_Success;
}

public OnPluginStart()
{
	RegServerCmd("spit_block_square", AddSpitBlockSquare);
	hSpitBlockSquares = CreateTrie();

	if(lateLoad)
	{
		for(new cl=1; cl <= MaxClients; cl++)
		{
			if(IsClientInGame(cl))
			{
				SDKHook(cl, SDKHook_OnTakeDamage, stop_spit_dmg);
			}
		}
	}
}

public Action:AddSpitBlockSquare(args)
{
	decl String:mapname[64];
	GetCmdArg(1, mapname, sizeof(mapname));

	new Float:square[4];
	decl String:buf[32];
	for (new i = 0; i < 4; i++)
	{
		GetCmdArg(2 + i, buf, sizeof(buf));
		square[i] = StringToFloat(buf);
	}
	SetTrieArray(hSpitBlockSquares, mapname, square, 4);
	OnMapStart();
}

public OnMapStart()
{
	decl String:mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	if (!GetTrieArray(hSpitBlockSquares, mapname, block_square, 4))
	{
		block_square[0] = 0.0;
		block_square[1] = 0.0;
		block_square[2] = 0.0;
		block_square[3] = 0.0;
	}
}

public OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, stop_spit_dmg);
}

public Action:stop_spit_dmg(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(victim <= 0 || victim > MaxClients) return Plugin_Continue;
	if(!IsValidEdict(inflictor)) return Plugin_Continue;
	decl String:sInflictor[64];
	GetEdictClassname(inflictor, sInflictor, sizeof(sInflictor));
	if(StrEqual(sInflictor, "insect_swarm"))
	{
		decl Float:origin[3];
		GetClientAbsOrigin(victim, origin);
		if(isPointIn2DBox(origin[0], origin[1], block_square[0], block_square[1], block_square[2], block_square[3]))
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;	
}

// Is x0,y0 in the box defined by x1,y1 and x2,y2
stock bool:isPointIn2DBox(Float:x0, Float:y0, Float:x1, Float:y1, Float:x2, Float:y2)
{
	if(x1 > x2)
	{
		if(y1 > y2)
		{
			return x0 <= x1 && x0 >= x2 && y0 <= y1 && y0 >= y2;
		}
		else
		{
			return x0 <= x1 && x0 >= x2 && y0 >= y1 && y0 <= y2;
		}
	}
	else
	{
		if(y1 > y2)
		{
			return x0 >= x1 && x0 <= x2 && y0 <= y1 && y0 >= y2;
		}
		else
		{
			return x0 >= x1 && x0 <= x2 && y0 >= y1 && y0 <= y2;
		}
	}
}