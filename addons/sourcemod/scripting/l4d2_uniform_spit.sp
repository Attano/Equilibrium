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
#include <sdkhooks>
#include <l4d2d_timers>

#define GODFRAME_TICKS  4
#define MAX_TICKS       28
#define TICK_TIME       0.200072

new Handle:hCvarDamagePerTick;
new Handle:hPuddles;

new Float:damagePerTick;

new bool:bLateLoad;

public APLRes:AskPluginLoad2(Handle:plugin, bool:late, String:error[], errMax) 
{
	bLateLoad = late;
	return APLRes_Success;    
}

public Plugin:myinfo = 
{
	name = "L4D2 Uniform Spit",
	author = "Visor",
	description = "Make the spit deal static amounts of DPS under all circumstances",
	version = "1.1",
	url = "https://github.com/Attano/smplugins"
};

public OnPluginStart()
{
	hCvarDamagePerTick = CreateConVar("l4d2_spit_dmg", "-1.0", "Damage per tick the spit inflicts. -1 to skip damage adjustments");

	hPuddles = CreateTrie();

	if (bLateLoad) 
	{
		for (new i = 1; i <= MaxClients; i++) 
		{
			if (IsClientInGame(i)) 
			{
				OnClientPutInServer(i);
			}
		}
	}
}

public OnConfigsExecuted()
{
	damagePerTick = GetConVarFloat(hCvarDamagePerTick);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "insect_swarm"))
	{
		decl String:trieKey[8];
		IndexToKey(entity, trieKey, sizeof(trieKey));

		new count[MaxClients];
		SetTrieArray(hPuddles, trieKey, count, MaxClients);
	}
}

public OnEntityDestroyed(entity)
{
	decl String:trieKey[8];
	IndexToKey(entity, trieKey, sizeof(trieKey));

	decl count[MaxClients];
	if (GetTrieArray(hPuddles, trieKey, count, MaxClients))
	{
		RemoveFromTrie(hPuddles, trieKey);
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damageType, &weapon, Float:damageForce[3], Float:damagePosition[3]) 
{
	if (victim <= 0 || victim > MaxClients || GetClientTeam(victim) != 2 || !IsValidEdict(inflictor))
	{
		return Plugin_Continue;
	}

	decl String:classname[64];
	GetEdictClassname(inflictor, classname, sizeof(classname));
	if (StrEqual(classname, "insect_swarm"))
	{
		decl String:trieKey[8];
		IndexToKey(inflictor, trieKey, sizeof(trieKey));

		decl count[MaxClients];
		if (GetTrieArray(hPuddles, trieKey, count, MaxClients))
		{
			count[victim]++;

			// Check to see if it's a godframed tick
			if (GetPuddleLifetime(inflictor) >= GODFRAME_TICKS * TICK_TIME && count[victim] < GODFRAME_TICKS)
			{
				count[victim] = GODFRAME_TICKS + 1;
			}

			// Update the array with stored tickcounts
			SetTrieArray(hPuddles, trieKey, count, MaxClients);

			// Let's see what do we have here
			if (damagePerTick > -1.0)
			{
				damage = damagePerTick;
			}
			if (GODFRAME_TICKS >= count[victim] || count[victim] > MAX_TICKS)
			{
				damage = 0.0;
			}
			if (count[victim] > MAX_TICKS)
			{
				AcceptEntityInput(inflictor, "Kill");
			}
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;	
}

Float:GetPuddleLifetime(puddle)
{
	return ITimer_GetElapsedTime(IntervalTimer:(GetEntityAddress(puddle) + Address:2968));
}

IndexToKey(index, String:str[], maxlength)
{
	Format(str, maxlength, "%x", index);
}