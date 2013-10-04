#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <l4d2_direct>

#define ZC_SPITTER       4
#define ZC_TANK          8

new Handle:hGameConfig;
new Handle:hSdkUpdateGhostClass;
new Handle:hCvarSpitterLimit;

new iCvarSpitterLimit;

new bool:bSwapAvailable[MAXPLAYERS + 1];
new bool:bTankAlive = false;

public Plugin:myinfo =
{
    name = "L4D2 Spitter Manager",
    author = "Visor",
    description = "Excludes any Spitters from the Infected team whilst the Tank is alive",
    version = "2.3",
    url = "https://github.com/Attano/Equilibrium"
}

public OnPluginStart() 
{
    // Game config
    hGameConfig = LoadGameConfigFile("l4d2_spitter_manager");
    if (hGameConfig == INVALID_HANDLE)
        SetFailState("Could not load gamedata file");

    // CTerrorPlayer::CullZombie(void)
    StartPrepSDKCall(SDKCall_Player);
    if (!PrepSDKCall_SetFromConf(hGameConfig, SDKConf_Signature, "CTerrorPlayer::CullZombie"))
        SetFailState("Could not load CTerrorPlayer::CullZombie signature");

    hSdkUpdateGhostClass = EndPrepSDKCall();
    if (hSdkUpdateGhostClass == INVALID_HANDLE)
        SetFailState("Could not initialize CTerrorPlayer::CullZombie() function");

    // Other shit
    hCvarSpitterLimit = FindConVar("z_versus_spitter_limit");
    iCvarSpitterLimit = GetConVarInt(hCvarSpitterLimit);
    HookConVarChange(hCvarSpitterLimit, SpitterLimitChange);

    HookEvent("tank_spawn", OnTankSpawn);
    HookEvent("player_bot_replace", OnBotConnected);
    HookEvent("player_death", OnPlayerDeath);
}

public OnPluginEnd() 
{
    ResetConVar(hCvarSpitterLimit);
}

public SpitterLimitChange(Handle:cvar, const String:oldValue[], const String:newValue[]) 
{
    if (StringToInt(newValue) > 0)
    {
        iCvarSpitterLimit = GetConVarInt(hCvarSpitterLimit);
    }
}

public OnRoundStart() 
{
    AllowSpitters();
}

public Action:OnTankSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{
    if (!bTankAlive)
    {
        ProhibitSpitters();
    }
}

public OnClientDisconnect(client) 
{
    if (IsTank(client)) 
    {
        CreateTimer(0.1, CheckForTanksDelay, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action:OnBotConnected(Handle:event, const String: name[], bool:dontBroadcast) 
{
    if (IsTank(GetClientOfUserId(GetEventInt(event, "bot")))) 
    {
        CreateTimer(0.1, CheckForTanksDelay, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{
    if (IsTank(GetClientOfUserId(GetEventInt(event, "userid")))) 
    {
        CreateTimer(0.1, CheckForTanksDelay, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action:CheckForTanksDelay(Handle:timer) 
{
    if (FindTank() < 0) 
    {
        AllowSpitters();
    }
}

static ProhibitSpitters() 
{
    SetConVarInt(hCvarSpitterLimit, 0);

    // Find and OFFER[v2.1] to replace any active spitters with a different class
    for (new i = 1; i <= MaxClients; i++) 
    {
        if (!IsClientInGame(i))
            continue;

        if (!IsPlayerEligible(i) || IsDesignatedTank(i))
            continue;
        
        bSwapAvailable[i] = true;
        PrintHintText(i, "Press R(reload) to switch your class");
        PrintToChat(i, "\x01Press \x04R\x01(\x03reload\x01) to change your SI class");
    }
    
    bTankAlive = true;
}

static AllowSpitters() 
{
    SetConVarInt(hCvarSpitterLimit, iCvarSpitterLimit);
    bTankAlive = false;
    
    for (new i = 1; i <= MaxClients; i++) 
    {
        bSwapAvailable[i] = false;
    }
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if (!bTankAlive)
        return Plugin_Continue;
    
    if (!IsClientInGame(client) || IsFakeClient(client) || !bSwapAvailable[client])
        return Plugin_Continue;
    
    if (!IsPlayerEligible(client))
        return Plugin_Continue;
    
    if (buttons & IN_RELOAD) 
    {
        L4D2_UpdateGhostClass(client);
        bSwapAvailable[client] = false;
    }
    
    return Plugin_Continue;
}

IsPlayerEligible(client) 
{
    if (GetInfectedClass(client) != ZC_SPITTER
    || GetEntProp(client, Prop_Send, "m_isGhost") != 1
    ) return false;
    
    return true;
}

FindTank() 
{
    for (new i = 1; i <= MaxClients; i++) 
    {
        if (IsTank(i) && IsPlayerAlive(i))
            return i;
    }
    
    return -1;
}

bool:IsTank(client) 
{
    if (client <= 0 || !IsClientInGame(client))
        return false;
    
    if (GetInfectedClass(client) != ZC_TANK)
        return false;
    
    return true;
}

GetInfectedClass(client) 
{
    if (GetClientTeam(client) != 3)
        return -1;
    
    return GetEntProp(client, Prop_Send, "m_zombieClass");
}

bool:IsDesignatedTank(client)
{
    new Address:pSelectedTankPlayerId = L4D2Direct_GetCDirector() + Address:GameConfGetOffset(hGameConfig, "CDirector::m_iSelectedTankPlayerId");
    return client == LoadFromAddress(pSelectedTankPlayerId, NumberType_Int32) ? true: false;
}

L4D2_UpdateGhostClass(client) 
{
    SDKCall(hSdkUpdateGhostClass, client);
}