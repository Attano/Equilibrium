#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <left4downtown>

new iDistance;
new witchIndex;

new bool:bTankPointsFrozen;
new bool:bWitchPointsFrozen;

public Plugin:myinfo = 
{
	name = "L4D2 No Boss Rush",
	author = "Visor; originally by Jahze, vintik",
	version = "2.1",
	description = "Stops distance points accumulating whilst the Tank or Witch are alive",
	url = "https://github.com/Attano/Equilibrium"
};

public OnPluginStart()
{
	HookEvent("round_start", EventHook:OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("tank_spawn", EventHook:OnTankSpawn, EventHookMode_PostNoCopy);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("witch_spawn", OnWitchSpawn);
	HookEvent("witch_killed", EventHook:OnWitchKilled, EventHookMode_PostNoCopy);
}

public OnRoundStart()
{
	if (InSecondHalfOfRound())
	{
		UnFreezePoints();
	}
}

/* Tank */

public OnTankSpawn()
{
	if (!bTankPointsFrozen && !bWitchPointsFrozen)
	{
		PrintToChatAll("\x01[\x04NoBossRush\x01] Tank spawned. Freezing distance points!");
		bTankPointsFrozen = true;
		FreezePoints();
	}
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsTank(client))
	{
		CreateTimer(0.1, CheckForTanksDelay, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public OnClientDisconnect(client) 
{
	if (IsTank(client))
	{
		CreateTimer(0.1, CheckForTanksDelay, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:CheckForTanksDelay(Handle:timer) 
{
	if (FindTank() == -1)
	{
		if (bTankPointsFrozen) 
		{
			PrintToChatAll("\x01[\x04NoBossRush\x01] Tank is dead. Unfreezing distance points!");
			bTankPointsFrozen = false;
			UnFreezePoints();
		}
	}
}

/* Witch */

public Action:OnWitchSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!bTankPointsFrozen && !bWitchPointsFrozen)
	{
		witchIndex = GetEventInt(event, "witchid");
		PrintToChatAll("\x01[\x04NoBossRush\x01] Witch spawned. Freezing distance points!");
		bWitchPointsFrozen = true;
		FreezePoints();
	}
}

public OnWitchKilled()
{
	if (bWitchPointsFrozen)
	{
		PrintToChatAll("\x01[\x04NoBossRush\x01] Witch is dead. Unfreezing distance points!");
		bWitchPointsFrozen = false;
		UnFreezePoints();
		witchIndex = -1;
	}
}

public OnEntityDestroyed(entity)
{
	if (entity == witchIndex)
	{
		OnWitchKilled();
	}
}

/* Shared */

FreezePoints() 
{
	iDistance = L4D_GetVersusMaxCompletionScore();
	L4D_SetVersusMaxCompletionScore(0);
}

UnFreezePoints() 
{
	L4D_SetVersusMaxCompletionScore(iDistance);
}

FindTank() 
{
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (IsTank(i) && IsPlayerAlive(i)) 
		{
			return i;
		}
	}
	return -1;
}

bool:IsTank(client)
{
	if (client <= 0 || !IsClientInGame(client) || GetClientTeam(client) != 3)
		return false;

	if (GetEntProp(client, Prop_Send, "m_zombieClass") != 8)
		return false;

	return true;
}

InSecondHalfOfRound()
{
	return GameRules_GetProp("m_bInSecondHalfOfRound");
}