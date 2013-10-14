#pragma semicolon 1

#include <sourcemod>
#include <left4downtown> // min v0.5.7

#define DEBUG   0

public Plugin:myinfo = 
{
    name = "L4D2 No Hunter Deadstops",
    author = "Visor",
    description = "Self-descriptive",
    version = "2.0",
    url = "https://github.com/Attano/Equilibrium"
};

// This blocks most of the deadstops, but not all
public Action:L4D_OnShovedBySurvivor(shover, shovee, const Float:vector[3])
{
    if (!IsSurvivor(shover) || !IsInfected(shovee))
        return Plugin_Continue;

    if (IsHunter(shovee) && IsPlayingDeadstopAnimation(shovee))
    {
    #if DEBUG
        PrintToChatAll("\x01Invoked \x04L4D_OnShovedBySurvivor\x01 on \x03%N\x01", shovee);
    #endif
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

// This takes care of what L4D_OnShovedBySurvivor() has failed to block, mainly high pounces
public Action:L4D2_OnEntityShoved(shover, shovee_ent, weapon, Float:vector[3], bool:bIsHunterDeadstop)
{
    if (!IsSurvivor(shover) || !IsInfected(shovee_ent))
        return Plugin_Continue;

    if (IsHunter(shovee_ent) && (bIsHunterDeadstop || IsPlayingDeadstopAnimation(shovee_ent)))
    {
    #if DEBUG
        PrintToChatAll("\x01Invoked \x04L4D2_OnEntityShoved\x01 on \x03%N\x01 with boolean %s", shovee_ent, (bIsHunterDeadstop ? "true" : "false"));
    #endif
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

stock bool:IsSurvivor(client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

stock bool:IsInfected(client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3;
}

bool:IsHunter(client)  
{
    if (!IsPlayerAlive(client))
        return false;

    if (GetEntProp(client, Prop_Send, "m_zombieClass") != 3)
        return false;

    return true;
}

bool:IsPlayingDeadstopAnimation(hunter)  
{
    new sequence = GetEntProp(hunter, Prop_Send, "m_nSequence");
#if DEBUG
    PrintToChatAll("\x04%N\x01 playing sequence \x04%d", hunter, sequence);
#endif
    return (sequence == 64 || sequence == 67);
}