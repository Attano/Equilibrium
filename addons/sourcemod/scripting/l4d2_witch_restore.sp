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
#include <sourcemod>
#include <left4downtown>

new Float:origin[3];
new Float:angles[3];

public Plugin:myinfo =
{
	name = "L4D2 Witch Restore",
	author = "Visor",
	description = "Witch is restored at the same spot if she gets killed by a Tank.",
	version = "1.0",
	url = "https://github.com/Attano/smplugins"
};

public OnPluginStart()
{
	HookEvent("witch_killed", OnWitchKilled, EventHookMode_Pre);
}

public Action:OnWitchKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new witch = GetEventInt(event, "witchid");
	if (IsValidTank(client))
	{
		GetEntPropVector(witch, Prop_Send, "m_vecOrigin", origin);
		GetEntPropVector(witch, Prop_Send, "m_angRotation", angles);
		CreateTimer(3.0, RestoreWitch, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:RestoreWitch(Handle:timer)
{
	L4D2_SpawnWitch(origin, angles);
}

bool:IsValidTank(client)
{
	return (client > 0
		&& client <= MaxClients
		&& IsClientInGame(client)
		&& GetClientTeam(client) == 3
		&& GetEntProp(client, Prop_Send, "m_zombieClass") == 8);
}