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

public Plugin:myinfo = 
{
    name = "Fix Melee Weapons",
    author = "Sir",
    description = "Fix those darn Melee Weapons not applying correct damage values",
    version = "1.0",
    url = "https://github.com/SirPlease/SirCoding"
}

public OnPluginStart()
{
    //Player Hurt is more fun to play with than SDK_Hook OnTakeDamage or OnTakeDamagePost.
    HookEvent("player_hurt", PlayerHurt);
}

public Action:PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
    new String:weapon[64];
    GetEventString(event, "weapon", weapon, sizeof(weapon));
    
    new victim = GetClientOfUserId(GetEventInt(event, "userid"));
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    new health = GetEventInt(event, "health");
    
    if (StrEqual(weapon, "melee") && IsSi(victim))
    {
        new class = GetEntProp(victim, Prop_Send, "m_zombieClass");
        
        //Testing showed that only the L4D1 SI; Hunter, Smoker and Boomer have issues with correct Melee Damage values being applied, check for Spitter and Jockey anyway!
        if(class <= 5 && health > 0)
        {
            //Award damage to Attacker accordingly.
            SDKHooks_TakeDamage(victim, 0, attacker, float(health));
        }    
    }
}	

bool:IsSi(client) 
{
    if (IsClientConnected(client)
    && IsClientInGame(client)
    && GetClientTeam(client) == 3) 
    {
        return true;
    }
    
    return false;
}