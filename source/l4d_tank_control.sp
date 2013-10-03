#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util>
#include <l4d2_direct>
#include <left4downtown>

new Handle:hTeamATanks;
new Handle:hTeamBTanks;

new queuedTank;
new String:tankSteamId[32];

new bool:bPrintToEveryone;

public Plugin:myinfo = {
    name = "L4D2 Tank Control",
    author = "Jahze, vintik, Visor",
    version = "1.3",
    description = "Forces each player to play the tank once before resetting the pool."
};

public OnPluginStart() {
    hTeamATanks = CreateArray(32);
    hTeamBTanks = CreateArray(32);
    RegConsoleCmd("sm_boss", BossCmd);
    RegConsoleCmd("sm_tank", BossCmd);
    RegConsoleCmd("sm_witch", BossCmd);
    HookEvent("player_left_start_area", EventHook:LeftStartAreaEvent, EventHookMode_PostNoCopy);
    HookEvent("round_end", EventHook:RoundEnd, EventHookMode_PostNoCopy);
    HookEvent("player_team", OnTeamChange, EventHookMode_PostNoCopy);
}

public OnConfigsExecuted() {
    new Handle:hCvarGlobalPercent = FindConVar("l4d_global_percent");
    if (hCvarGlobalPercent != INVALID_HANDLE) {
        bPrintToEveryone = GetConVarBool(hCvarGlobalPercent);
    }
}

PrintTankPlayer(client = -1) {
    if (!queuedTank)
        return;
    
    new bool:bGlobalPrint = true;
    if (client > -1) {
        if (!IsClientConnected(client) || !IsClientInGame(client))
            return;

        bGlobalPrint = L4D2_Team:GetClientTeam(client) == L4D2Team_Spectator ? false : (!bPrintToEveryone ? false : true);
    }
    
    if (bGlobalPrint)
        PrintToChatAll("\x05%N \x01will become the Tank", queuedTank);
    else
        PrintToChat(client, "\x05%N \x01will become the Tank", queuedTank);
}

public Action:BossCmd(client, args) {
    PrintTankPlayer(client);
    return Plugin_Handled;
}

public RoundEnd() {
    queuedTank = 0;
}

public LeftStartAreaEvent() {
    queuedTank = 0;
    ChooseTank(true);
    PrintTankPlayer();
}

public OnTeamChange(Handle:event, String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (client && client == queuedTank) {
        ChooseTank(true);
        PrintTankPlayer();
    }
}

public OnClientDisconnect(client) {
    if (client && client == queuedTank) {
        ChooseTank(true);
        PrintTankPlayer();
    }
}

public Action:L4D_OnTryOfferingTankBot(tank_index, &bool:enterStatis) {
    if (!IsFakeClient(tank_index)) {
        for (new i=1; i <= MaxClients; i++) {
            if (!IsClientInGame(i))
                continue;
        
            if (!IsInfected(i))
                continue;

            PrintHintText(i, "Rage Meter Refilled");
            PrintToChat(i, "\x01[Tank Control] (\x03%N\x01) \x04Rage Meter Refilled", tank_index);
        }
        SetTankFrustration(tank_index, 100);
        L4D2Direct_SetTankPassedCount(L4D2Direct_GetTankPassedCount() + 1);
        return Plugin_Handled;
    }
    
    if (queuedTank != 0) {
        ForceTankPlayer();
        PushArrayString(InfectedTeamArray(), tankSteamId);
        queuedTank = 0;
    }
    
    return Plugin_Continue;
}

static bool:HasBeenTank(client) {
    decl String:SteamId[32];
    GetClientAuthString(client, SteamId, sizeof(SteamId));
    for (new i = 0; i < GetArraySize(InfectedTeamArray()); ++i)
    {
        decl String:name[32];
        GetArrayString(InfectedTeamArray(), i, name, sizeof(name));
    }
    return (FindStringInArray(InfectedTeamArray(), SteamId) != -1);
}

static ChooseTank(bool:bFirstPass) {
    new Float:fHighestConnectDuration;
    new tankClient = -1;

    for (new i = 1; i <= MaxClients; i++) {
        if (!IsClientConnected(i) || !IsClientInGame(i)) {
            continue;
        }
        
        if (IsFakeClient(i) || !IsInfected(i) || HasBeenTank(i) || i == queuedTank) {
            continue;
        }
        
        if (GetClientTime(i) > fHighestConnectDuration) {
            fHighestConnectDuration = GetClientTime(i);
            tankClient = i;
        }
    }

    if (tankClient == -1) {
        if (bFirstPass) {
            ClearArray(InfectedTeamArray());
            ChooseTank(false);
        }
        else queuedTank = 0;
        return;
    }

    GetClientAuthString(tankClient, tankSteamId, sizeof(tankSteamId));
    queuedTank = tankClient;
}

static ForceTankPlayer() {
    for (new i = 1; i < MaxClients+1; i++) {
        if (!IsClientConnected(i) || !IsClientInGame(i)) {
            continue;
        }
        
        if (IsInfected(i)) {
            if (queuedTank == i) {
                L4D2Direct_SetTankTickets(i, 20000);
            }
            else {
                L4D2Direct_SetTankTickets(i, 0);
            }
        }
    }
}

Handle:InfectedTeamArray() {
    return GameRules_GetProp("m_bAreTeamsFlipped") ? hTeamBTanks : hTeamATanks;
}