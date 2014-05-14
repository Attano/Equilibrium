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
#include <sdkhooks>
#include <l4d2_direct>

#define DISTANCE_PROTECT    0.2
#define DMG_FALL    (1 << 5)

new bool:bPluginActive;

public Plugin:myinfo = 
{
    name = "Warcelona Fix aka Lazy Workaround",
    author = "raecher, alexip, Visor",
    description = "Prevents Survivors from dying during/after ready-up on Warcelona maps.",
    version = "0.3",
    url = "https://github.com/Attano/Equilibrium"
};

public OnMapStart()
{
    decl String:mapname[64];
    GetCurrentMap(mapname, sizeof(mapname));

    bPluginActive = (!strcmp(mapname, "srocchurch") || !strcmp(mapname, "mnac")) ? true : false;
}

public OnClientPutInServer(client)
{
    if (bPluginActive)
        SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientDisconnect(client)
{
    SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
    if (!IsSurvivor(victim))
        return Plugin_Continue;
           
    if (GetDistance(victim) <= DISTANCE_PROTECT && (damagetype & DMG_FALL))
        return Plugin_Handled;

    return Plugin_Continue;
}

GetDistance(client)
{
    new Float:pos[3];
    GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
    new Float:flow = L4D2Direct_GetTerrorNavAreaFlow(L4D2Direct_GetTerrorNavArea(pos));
    return RoundToNearest(flow / L4D2Direct_GetMapMaxFlowDistance());
}

bool:IsSurvivor(client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}