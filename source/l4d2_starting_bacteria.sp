#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <left4downtown>

#define BACTERIA_SND_TIMER		GetRandomFloat(4.0, 6.0)
#define BACTERIA_SND_COOLDOWN	GetRandomInt(8, 14)
#define BACTERIA_SND_COINFLIP	GetRandomInt(0, 100) % 2

new const String:sInfectedNames[][] = {
    "smoker",
    "boomer",
    "hunter",
    "spitter",
    "jockey",
    "charger"
};

new Handle:hTimer;
new Handle:hQueues;

new iSurvivors[4];
new iSurvivorCount;

enum BacteriaInQueue 
{
    BQ_Client,
	BQ_LastPlayback,
    String:BQ_Soundfile1[PLATFORM_MAX_PATH],
    String:BQ_Soundfile2[PLATFORM_MAX_PATH]
};

public Plugin:myinfo = 
{
	name = "L4D2 Round Start Bacteria",
	author = "Visor",
	description = "Brings back Infected spawning music for the first set of spawns",
	version = "2.2",
	url = ""
};

public OnPluginStart()
{
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_team", OnTeamChange, EventHookMode_PostNoCopy);
	HookEvent("player_left_start_area", OnPlayerLeftStartArea, EventHookMode_PostNoCopy);
}

public OnMapStart()
{
	decl String:buffer[PLATFORM_MAX_PATH];
	for (new i = 0; i <= 5; i++)
	{
		Format(buffer, PLATFORM_MAX_PATH, "music/bacteria/%sbacteria.wav", sInfectedNames[i]);
		PrecacheSound(buffer);
		Format(buffer, PLATFORM_MAX_PATH, "music/bacteria/%sbacterias.wav", sInfectedNames[i]);
		PrecacheSound(buffer);
	}
}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	hTimer = CreateTimer(BACTERIA_SND_TIMER, BacteriaTimer, _, TIMER_REPEAT);
	hQueues = CreateArray(_:BacteriaInQueue);
}

public OnTeamChange(Handle:event, String:name[], bool:dontBroadcast)
{
	iSurvivorCount = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i) || !IsClientInGame(i) || GetClientTeam(i) != 2 || IsFakeClient(i) || !IsPlayerAlive(i))
			continue;
		
		iSurvivors[iSurvivorCount] = i;
		iSurvivorCount++;
	}
}

public OnPlayerLeftStartArea(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (hTimer != INVALID_HANDLE)
    {
        KillTimer(hTimer);
        hTimer = INVALID_HANDLE;
    }
	if (hQueues != INVALID_HANDLE)
	{
		ClearArray(hQueues);
	}
}

public L4D_OnEnterGhostState(client)
{
	if (hTimer == INVALID_HANDLE)
		return;

	new zc = GetEntProp(client, Prop_Send, "m_zombieClass");
	if (zc == 8)	// tank on round start/end? highly unlikely, but just in case
		return;

	new index = FindValueInArray(hQueues, client);
	if (index > -1)
	{
		RemoveFromArray(hQueues, index);
	}
	
	decl entry[BacteriaInQueue];
	entry[BQ_Client] = _:client;
	entry[BQ_LastPlayback] = _:0;
	Format(entry[BQ_Soundfile1], PLATFORM_MAX_PATH, "music/bacteria/%sbacteria.wav", sInfectedNames[zc-1]);
	Format(entry[BQ_Soundfile2], PLATFORM_MAX_PATH, "music/bacteria/%sbacterias.wav", sInfectedNames[zc-1]);
	PushArrayArray(hQueues, entry[0]);
}

public Action:BacteriaTimer(Handle:timer)
{
	decl entry[BacteriaInQueue];
	new index = -1;
	new time = -1;
	
	for (new i = 0; i < GetArraySize(hQueues); i++)
	{
		GetArrayArray(hQueues, i, entry[0]);
		if (!IsBacteriaEligible(entry[BQ_Client]))
		{
			RemoveFromArray(hQueues, i);
		}
		else
		{
			if (time < 0 || time > entry[BQ_LastPlayback]) 
			{
				index = i;
				time = entry[BQ_LastPlayback];
			}
		}
	}

	if (index > -1)
	{
		GetArrayArray(hQueues, index, entry[0]);
		if (GetTime() - entry[BQ_LastPlayback] > BACTERIA_SND_COOLDOWN)
		{
			entry[BQ_LastPlayback] = _:GetTime();
			SetArrayArray(hQueues, index, entry[0]);

			if (BACTERIA_SND_COINFLIP)
				EmitSound(iSurvivors, iSurvivorCount, entry[BQ_Soundfile1], _, _, SNDLEVEL_HOME);
			else
				EmitSound(iSurvivors, iSurvivorCount, entry[BQ_Soundfile2], _, _, SNDLEVEL_HOME);
		}
	}
	
	return Plugin_Continue;
}

IsBacteriaEligible(client)
{
	if (!IsClientInGame(client)
	|| GetClientTeam(client) != 3
	|| !IsPlayerAlive(client)
	|| !GetEntProp(client, Prop_Send, "m_isGhost")
	)	return false;
	
	return true;
}