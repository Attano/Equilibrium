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
//<<<<<<<<<<<<<<<<<<<<< TICKRATE FIXES >>>>>>>>>>>>>>>>>>
//// ------- Fast Pistols ---------
// ***************************** 
//Cvars
new Handle:g_hPistolDelayDualies = INVALID_HANDLE;
new Handle:g_hPistolDelaySingle = INVALID_HANDLE;
new Handle:g_hPistolDelayIncapped = INVALID_HANDLE;

//Floats
new Float:g_fNextAttack[MAXPLAYERS + 1];
new Float:g_fPistolDelayDualies = 0.1;
new Float:g_fPistolDelaySingle = 0.2;
new Float:g_fPistolDelayIncapped = 0.3;

new Float:tickInterval;
new Float:tickRRate;

//Cvar Check & Adjust
new Handle: g_hCvarGravity       = INVALID_HANDLE;

#include <sourcemod>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "Tickrate Fixes",
	author = "Sir, Griffin",
	description = "Fixes a handful of silly Tickrate bugs",
	version = "1.0",
	url = "Nawl."
}

public OnPluginStart()
{
	//Is Server 40+ Tick?
    tickInterval = GetTickInterval();
    if(0.0 < tickInterval) tickRRate = 1.0/tickInterval;
    if(tickRRate >= 40)
    {
        //Hook Pistols
        for (new client = 1; client <= MaxClients; client++)
        {
            if (!IsClientInGame(client)) continue;
            SDKHook(client, SDKHook_PostThinkPost, Hook_OnPostThinkPost);
        }
        g_hPistolDelayDualies = CreateConVar("l4d_pistol_delay_dualies", "0.1", "Minimum time (in seconds) between dual pistol shots",
        FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY, true, 0.0, true, 5.0);
        g_hPistolDelaySingle = CreateConVar("l4d_pistol_delay_single", "0.2", "Minimum time (in seconds) between single pistol shots",
        FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY, true, 0.0, true, 5.0);
        g_hPistolDelayIncapped = CreateConVar("l4d_pistol_delay_incapped", "0.3", "Minimum time (in seconds) between pistol shots while incapped",
        FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY, true, 0.0, true, 5.0);
        
        UpdatePistolDelays();
        
        HookConVarChange(g_hPistolDelayDualies, Cvar_PistolDelay);
        HookConVarChange(g_hPistolDelaySingle, Cvar_PistolDelay);
        HookConVarChange(g_hPistolDelayIncapped, Cvar_PistolDelay);
        HookEvent("weapon_fire", Event_WeaponFire);
        
        //Gravity
        g_hCvarGravity = FindConVar("sv_gravity");
        if (GetConVarInt(g_hCvarGravity) != 750) SetConVarInt(g_hCvarGravity, 750);
    }
	//We don't need you on this 30T Server
	else ServerCommand("sm plugins unload TickrateFixes.smx");
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_PreThink, Hook_OnPostThinkPost);
    g_fNextAttack[client] = 0.0;
}

public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_PreThink, Hook_OnPostThinkPost);
}

public Cvar_PistolDelay(Handle:convar, const String:oldValue[], const String:newValue[])
{
    UpdatePistolDelays();
}

UpdatePistolDelays()
{
    g_fPistolDelayDualies = GetConVarFloat(g_hPistolDelayDualies);
    if (g_fPistolDelayDualies < 0.0) g_fPistolDelayDualies = 0.0;
    else if (g_fPistolDelayDualies > 5.0) g_fPistolDelayDualies = 5.0;
    
    g_fPistolDelaySingle = GetConVarFloat(g_hPistolDelaySingle);
    if (g_fPistolDelaySingle < 0.0) g_fPistolDelaySingle = 0.0;
    else if (g_fPistolDelaySingle > 5.0) g_fPistolDelaySingle = 5.0;
    
    g_fPistolDelayIncapped = GetConVarFloat(g_hPistolDelayIncapped);
    if (g_fPistolDelayIncapped < 0.0) g_fPistolDelayIncapped = 0.0;
    else if (g_fPistolDelayIncapped > 5.0) g_fPistolDelayIncapped = 5.0;
}

public Hook_OnPostThinkPost(client)
{
    // Human survivors only
    if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != 2) return;
    new activeweapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (!IsValidEdict(activeweapon)) return;
    decl String:weaponname[64];
    GetEdictClassname(activeweapon, weaponname, sizeof(weaponname));
    if (strcmp(weaponname, "weapon_pistol") != 0) return;
    
    new Float:old_value = GetEntPropFloat(activeweapon, Prop_Send, "m_flNextPrimaryAttack");
    new Float:new_value = g_fNextAttack[client];
    
    // Never accidentally speed up fire rate
    if (new_value > old_value)
    {
        // PrintToChatAll("Readjusting delay: Old=%f, New=%f", old_value, new_value);
        SetEntPropFloat(activeweapon, Prop_Send, "m_flNextPrimaryAttack", new_value);
    }
}

public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != 2) return;
    new activeweapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (!IsValidEdict(activeweapon)) return;
    decl String:weaponname[64];
    GetEdictClassname(activeweapon, weaponname, sizeof(weaponname));
    if (strcmp(weaponname, "weapon_pistol") != 0) return;
    // new dualies = GetEntProp(activeweapon, Prop_Send, "m_hasDualWeapons");
    if (GetEntProp(client, Prop_Send, "m_isIncapacitated"))
    {
        g_fNextAttack[client] = GetGameTime() + g_fPistolDelayIncapped;
    }
    // What is the difference between m_isDualWielding and m_hasDualWeapons ?
    else if (GetEntProp(activeweapon, Prop_Send, "m_isDualWielding"))
    {
        g_fNextAttack[client] = GetGameTime() + g_fPistolDelayDualies;
    }
    else
    {
        g_fNextAttack[client] = GetGameTime() + g_fPistolDelaySingle;
    }
}
