#pragma semicolon 1

#include <sourcemod>
#include <left4downtown>

public Plugin:myinfo = 
{
    name = "L4D2 No Hunter Deadstops",
    author = "Visor",
    description = "Self-descriptive",
    version = "1.2",
    url = "https://github.com/Attano/Equilibrium"
};

// IDA revealed that this function is not a reliable place for blocking deadstops
// TODO: Detour CTerrorPlayer::OnShovedByLunge() and CTerrorPlayer::OnLeptOnSurvivor()
// for reliably blocking deadstops on hunters and jockeys 100% of the time
public Action:L4D_OnShovedBySurvivor(shover, shovee, const Float:vector[3])
{
    if (!IsSurvivor(shover) || !IsInfected(shovee))
        return Plugin_Continue;

    if (IsHunter(shovee) && IsPlayingDeadstopAnimation(shovee))
        return Plugin_Handled;

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
    return (sequence == 64 || sequence == 67);
}