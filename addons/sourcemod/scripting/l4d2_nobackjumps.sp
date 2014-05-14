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
#include <dhooks>

new Handle:hCLunge_ActivateAbility;

new Float:fSuspectedBackjump[MAXPLAYERS + 1];

public Plugin:myinfo =
{
    name        = "L4D2 No Backjump",
    author      = "Visor",
    description = "Gah",
    version     = "1.2",
    url         = "https://github.com/Attano/Equilibrium"
}

public OnPluginStart()
{
    new Handle:gameConf = LoadGameConfigFile("l4d2_nobackjumps"); 
    new LungeActivateAbilityOffset = GameConfGetOffset(gameConf, "CLunge_ActivateAbility");
    
    hCLunge_ActivateAbility = DHookCreate(LungeActivateAbilityOffset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, CLunge_ActivateAbility);
    DHookAddEntityListener(ListenType_Created, OnEntityCreated);

    HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
    HookEvent("player_jump", OnPlayerJump);
}

public OnEntityCreated(entity, const String:classname[])
{
    if (StrEqual(classname, "ability_lunge"))
        DHookEntity(hCLunge_ActivateAbility, false, entity); 
}

public OnRoundStart(Handle:event, const String:name[], bool:bDontBroadcast)
{
    for (new i = 1; i <= MaxClients; i++)
        fSuspectedBackjump[i] = 0.0;
}

public Action:OnPlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if (IsHunter(client) && !IsGhost(client) && IsOutwardJump(client))
        fSuspectedBackjump[client] = GetGameTime();
}

public MRESReturn:CLunge_ActivateAbility(ability, Handle:hParams)
{
    new client = GetEntPropEnt(ability, Prop_Send, "m_owner");
    if (fSuspectedBackjump[client] + 1.5 > GetGameTime())
    {
        //PrintToChat(client, "\x01[SM] No \x03backjumps\x01, sorry");
        return MRES_Supercede;
    }
    
    return MRES_Ignored;
}

bool:IsOutwardJump(client) {
    return GetEntProp(client, Prop_Send, "m_isAttemptingToPounce") == 0 && !(GetEntityFlags(client) & FL_ONGROUND);
}

bool:IsHunter(client)  {
    if (client < 1 || client > MaxClients) return false;
    if (!IsClientInGame(client) || !IsPlayerAlive(client)) return false;
    if (GetClientTeam(client) != 3 || GetEntProp(client, Prop_Send, "m_zombieClass") != 3) return false;

    return true;
}

bool:IsGhost(client) {
    return GetEntProp(client, Prop_Send, "m_isGhost") == 1;
}