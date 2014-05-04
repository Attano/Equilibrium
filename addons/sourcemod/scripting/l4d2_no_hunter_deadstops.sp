#pragma semicolon 1

#include <sourcemod>
#include <left4downtown> // min v0.5.7

#define DEBUG   0

static const deadstopSequences[] = {64, 67, 11, 8};

/**
	The important thing you need to know about this game is that it's retarded.
	You execute a deadstop, then immediately after it gets blocked, another one kicks in -- with a different animation sequence.
	It was a pain in the ass, but I've finally done it.
	
	Farewell M2...
	You will not be missed.
**/

public Plugin:myinfo = 
{
	name = "L4D2 No Hunter Deadstops",
	author = "Visor",
	description = "Self-descriptive",
	version = "3.1",
	url = "https://github.com/Attano/Equilibrium"
};

public Action:L4D_OnShovedBySurvivor(shover, shovee, const Float:vector[3])
{
	if (!IsSurvivor(shover) || !IsInfected(shovee))
		return Plugin_Continue;

	if (IsHunter(shovee) && IsPlayingDeadstopAnimation(shovee)/* && !(GetEntityFlags(shovee) & FL_ONGROUND) */)
	{
	#if DEBUG
		PrintToChatAll("\x01Invoked \x04L4D_OnShovedBySurvivor\x01 on \x03%N\x01", shovee);
	#endif
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:L4D2_OnEntityShoved(shover, shovee_ent, weapon, Float:vector[3], bool:bIsHunterDeadstop)
{
	if (!IsSurvivor(shover) || !IsInfected(shovee_ent))
		return Plugin_Continue;

	if (IsHunter(shovee_ent) && IsPlayingDeadstopAnimation(shovee_ent) && bIsHunterDeadstop)
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

stock bool:IsHunter(client)  
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
	PrintToChatAll("\x04%N\x01 playing sequence \x04%d\x01", hunter, sequence);
#endif
	for (new i = 0; i < sizeof(deadstopSequences); i++)
	{
		if (deadstopSequences[i] == sequence) return true;
	}
	return false;
}