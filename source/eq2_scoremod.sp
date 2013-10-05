#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <left4downtown>
#include <l4d2_direct>
#include <l4d2lib>

#define EQSM_DEBUG    0

/** 
    Bibliography:
    'l4d2_scoremod' by CanadaRox, ProdigySim
    'damage_bonus' by CanadaRox, Stabby
    'l4d2_scoringwip' by ProdigySim
    'srs.scoringsystem' by AtomicStryker
**/

new Handle:hCvarHealthBonusMultiplier;
new Handle:hCvarPermanentHealthProportion;
new Handle:hCvarSurvivalBonus;
new Handle:hCvarTieBreaker;

new Float:fMapHealthBonus;
new Float:fMapTempHealthBonus;
new Float:fPermHpWorth;
new Float:fTempHpWorth;
new Float:fSurvivorBonus[2];

new iTeamSize;
new iLostTempHealth[2];
new iTempHealth[MAXPLAYERS + 1];

new bool:bLateLoad;
new bool:bRoundOver;

public Plugin:myinfo =
{
    name = "L4D2 Equilibrium 2.0 Scoring System",
    author = "Visor",
    description = "Custom scoring system, designed for Equilibrium 2.0",
    version = "1.2",
    url = "https://github.com/Attano/Equilibrium"
};

public APLRes:AskPluginLoad2(Handle:plugin, bool:late, String:error[], errMax) 
{
    bLateLoad = late;
    return APLRes_Success;
}

public OnPluginStart()
{
    hCvarHealthBonusMultiplier = CreateConVar("eqsm_health_bonus_multiplier", "2.0", "Total Survivor Health Bonus = this * Map Distance", FCVAR_PLUGIN, true, 0.25);
    hCvarPermanentHealthProportion = CreateConVar("eqsm_permament_health_proportion", "0.75", "Permanent Health Bonus = this * Map Bonus; rest goes for Temporary Health Bonus", FCVAR_PLUGIN);
    hCvarSurvivalBonus = FindConVar("vs_survival_bonus");
    hCvarTieBreaker = FindConVar("vs_tiebreak_bonus");

    HookConVarChange(hCvarHealthBonusMultiplier, CvarChanged);
    HookConVarChange(hCvarPermanentHealthProportion, CvarChanged);

    HookEvent("round_start", EventHook:OnRoundStart, EventHookMode_PostNoCopy);
    HookEvent("player_ledge_grab", OnPlayerLedgeGrab);

    RegConsoleCmd("sm_health", CmdBonus);
    RegConsoleCmd("sm_damage", CmdBonus);
    RegConsoleCmd("sm_bonus", CmdBonus);

    if (bLateLoad) 
    {
        for (new i = 1; i <= MaxClients; i++) 
        {
            if (!IsClientInGame(i))
                continue;

            OnClientPutInServer(i);
        }
    }
}

public OnPluginEnd()
{
    ResetConVar(hCvarSurvivalBonus);
    ResetConVar(hCvarTieBreaker);
}

public OnConfigsExecuted()
{
    iTeamSize = GetConVarInt(FindConVar("survivor_limit"));
    SetConVarInt(hCvarTieBreaker, 0);

    new iMapDistance = L4D2_GetMapValueInt("max_distance", L4D_GetVersusMaxCompletionScore());
    L4D_SetVersusMaxCompletionScore(iMapDistance);

    new Float:fPermHealthProportion = GetConVarFloat(hCvarPermanentHealthProportion);
    new Float:fTempHealthProportion = 1.0 - fPermHealthProportion;
    fMapHealthBonus = iMapDistance * (GetConVarFloat(hCvarHealthBonusMultiplier) / 4/* max survivors */ * iTeamSize);
    fMapTempHealthBonus = iTeamSize * 100/* HP */ / fPermHealthProportion * fTempHealthProportion;
    fPermHpWorth = fMapHealthBonus / iTeamSize / 100 * fPermHealthProportion;
    fTempHpWorth = fMapHealthBonus * fTempHealthProportion / fMapTempHealthBonus; // this should be almost equal to the perm hp worth, but for accuracy we'll keep it separately
    #if EQSM_DEBUG
        PrintToChatAll("\x01Map health bonus: \x05%.1f\x01, temp health bonus: \x05%.1f\x01, perm hp worth: \x03%.1f\x01, temp hp worth: \x03%.1f\x01", fMapHealthBonus, fMapTempHealthBonus, fPermHpWorth, fTempHpWorth);
    #endif
}

public OnMapStart()
{
    OnConfigsExecuted();
    
    iLostTempHealth[0] = 0;
    iLostTempHealth[1] = 0;
}

public CvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
    OnConfigsExecuted();
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}

public OnClientDisconnect(client)
{
    SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    SDKUnhook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}

public OnRoundStart()
{
    for (new i = 0; i < MAXPLAYERS; i++)
    {
        iTempHealth[i] = 0;
    }
}

public Action:L4D_OnFirstSurvivorLeftSafeArea(client)
{
    bRoundOver = false;
}

public Action:CmdBonus(client, args)
{
    new Float:bonus = GetSurvivorBonus();
    ReplyToCommand(client, "\x01[\x04EQSM\x01 | The Road So Far...] R\x03#%i\x01 Survivor Bonus: \x05%d\x01/\x05%d\x01 <\x03%.1f%%\x01>", InSecondHalfOfRound() + 1, RoundToFloor(bonus), RoundToNearest(fMapHealthBonus), CalculatePerformance(bonus));
    return Plugin_Handled;
}

// OnTakeDamage() only provides correct argument values when they're reference pointers
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
    if (!IsSurvivor(victim) || !IsAnyInfected(attacker) || IsPlayerIncap(victim))
        return Plugin_Continue;

    #if EQSM_DEBUG
        if (GetSurvivorTemporaryHealth(victim) > 0) PrintToChatAll("\x01\x04%N\x01 has \x05%d\x01 temp HP now(damage: \x03%.1f\x01)", victim, GetSurvivorTemporaryHealth(victim), damage);
    #endif
    iTempHealth[victim] = GetSurvivorTemporaryHealth(victim);

    return Plugin_Continue;
}

public OnPlayerLedgeGrab(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	iLostTempHealth[InSecondHalfOfRound()] += L4D2Direct_GetPreIncapHealthBuffer(client);
}

public Action:L4D2_OnRevived(client)
{
	iLostTempHealth[InSecondHalfOfRound()] -= GetSurvivorTemporaryHealth(client);
}

// OnTakeDamagePost() does the opposite: it messes up pointer arguments but works fine with the normal ones
// SDKHooks probably treats OTD() args as "by-ref" and OTDP() as normal ones
// Pawn gets confused and we end up with wrong values
public OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype)
{
    if (!IsSurvivor(victim) || !IsAnyInfected(attacker))
        return;
        
    #if EQSM_DEBUG
        PrintToChatAll("\x03%N\x01\x05 lost %i\x01 temp HP after being attacked(arg damage: \x03%.1f\x01)", victim, iTempHealth[victim] - (IsPlayerAlive(victim) ? GetSurvivorTemporaryHealth(victim) : 0), damage);
    #endif
    if (!IsPlayerAlive(victim) || (IsPlayerIncap(victim) && !IsPlayerLedged(victim)))
    {
        iLostTempHealth[InSecondHalfOfRound()] += iTempHealth[victim];
    }
    else if (!IsPlayerLedged(victim))
    {
        iLostTempHealth[InSecondHalfOfRound()] += iTempHealth[victim] ? (iTempHealth[victim] - GetSurvivorTemporaryHealth(victim)) : 0;
    }
    iTempHealth[victim] = IsPlayerIncap(victim) ? 0 : GetSurvivorTemporaryHealth(victim);
}

public Action:L4D2_OnEndVersusModeRound(bool:countSurvivors)
{
    #if EQSM_DEBUG
        PrintToChatAll("CDirector::OnEndVersusModeRound() called. InSecondHalfOfRound(): %d, countSurvivors: %d", InSecondHalfOfRound(), countSurvivors);
    #endif
    if (bRoundOver)
        return Plugin_Continue;

    new iSurvivalMultiplier = GetUprightSurvivors();    // I don't know how reliable countSurvivors is and I'm too lazy to test
    fSurvivorBonus[InSecondHalfOfRound()] = GetSurvivorBonus(iSurvivalMultiplier);
    if (iSurvivalMultiplier > 0 && fSurvivorBonus[InSecondHalfOfRound()] >= 1.0)
    {
        /* Survivor bonus */
        SetConVarInt(hCvarSurvivalBonus, RoundToFloor(fSurvivorBonus[InSecondHalfOfRound()] / iSurvivalMultiplier));
        fSurvivorBonus[InSecondHalfOfRound()] = float(GetConVarInt(hCvarSurvivalBonus) * iSurvivalMultiplier);    // workaround for the discrepancy caused by RoundToFloor()
        #if EQSM_DEBUG
            PrintToChatAll("\x01Survival bonus cvar updated. Value: \x05%i\x01 [multiplier: \x05%i\x01]", GetConVarInt(hCvarSurvivalBonus), iSurvivalMultiplier);
        #endif
    }
    else SetConVarInt(hCvarSurvivalBonus, 0);
    
    // Scores print
    for (new i = 0; i <= InSecondHalfOfRound(); i++)
    {
        PrintToChatAll("\x01[\x04EQSM\x01 | Round \x03%i\x01] Survivor Bonus: \x05%d\x01 <\x03%.1f%%\x01>", (i + 1), RoundToFloor(fSurvivorBonus[i]), CalculatePerformance(fSurvivorBonus[i]));
    }

    bRoundOver = true;
    return Plugin_Continue;
}

GetUprightSurvivors()
{
    new iAliveCount;
    new iSurvivorCount;
    for (new i = 1; i <= MaxClients && iSurvivorCount < iTeamSize; i++)
    {
        if (IsSurvivor(i))
        {
            iSurvivorCount++;
            if (IsPlayerAlive(i) && !IsPlayerIncap(i) && !IsPlayerLedged(i))
            {
                iAliveCount++;
            }
        }
    }
    return iAliveCount;
}

Float:GetSurvivorBonus(countTempHealth = 1)
{
    new Float:fTempHealthBonus = (fMapTempHealthBonus - float(iLostTempHealth[InSecondHalfOfRound()])) * fTempHpWorth;
    new Float:fBonus = fTempHealthBonus > 0.0 && countTempHealth > 0 ? fTempHealthBonus : 0.0;
    #if EQSM_DEBUG
        PrintToChatAll("\x01Adding temp hp bonus: \x05%.1f\x01", fTempHealthBonus);
    #endif

    new iSurvivorCount;
    for (new i = 1; i <= MaxClients && iSurvivorCount < iTeamSize; i++)
    {
        if (IsSurvivor(i))
        {
            iSurvivorCount++;
            if (IsPlayerAlive(i) && !IsPlayerIncap(i) && !IsPlayerLedged(i))
            {
                fBonus += GetSurvivorPermanentHealth(i) * fPermHpWorth;
                #if EQSM_DEBUG
                    PrintToChatAll("\x01Adding \x05%N's\x01 perm hp bonus contribution: \x05%d\x01 perm HP -> \x03%.1f\x01 bonus; new total: \x05%.1f\x01", i, GetSurvivorPermanentHealth(i), GetSurvivorPermanentHealth(i) * fPermHpWorth, fBonus);
                #endif
            }
        }
    }
    
    return fBonus;
}

Float:CalculatePerformance(Float:score)
{
    return score / fMapHealthBonus * 100;
}

/************/
/** Stocks **/
/************/

InSecondHalfOfRound()
{
    return GameRules_GetProp("m_bInSecondHalfOfRound");
}

bool:IsSurvivor(client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

bool:IsAnyInfected(entity)
{
    if (entity > 0 && entity <= MaxClients)
    {
        return IsClientInGame(entity) && GetClientTeam(entity) == 3;
    }
    else if (entity > MaxClients)
    {
        decl String:classname[64];
        GetEdictClassname(entity, classname, sizeof(classname));
        if (StrEqual(classname, "infected") || StrEqual(classname, "witch")) 
        {
            return true;
        }
    }
    return false;
}

bool:IsPlayerIncap(client)
{
    return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

bool:IsPlayerLedged(client)
{
    return bool:(GetEntProp(client, Prop_Send, "m_isHangingFromLedge") | GetEntProp(client, Prop_Send, "m_isFallingFromLedge"));
}

GetSurvivorTemporaryHealth(client)
{
    new temphp = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(FindConVar("pain_pills_decay_rate")))) - 1;
    return (temphp > 0 ? temphp : 0);
}

GetSurvivorPermanentHealth(client)
{
    // Survivors always have minimum 1 permanent hp
    // so that they don't faint in place just like that when all temp hp run out
    // We'll use a workaround for the sake of fair calculations
    // Edit 2: "Incapped HP" are stored in m_iHealth too; we heard you like workarounds, dawg, so we've added a workaround in a workaround
    return GetEntProp(client, Prop_Send, "m_currentReviveCount") > 0 ? 0 : (GetEntProp(client, Prop_Send, "m_iHealth") > 0 ? GetEntProp(client, Prop_Send, "m_iHealth") : 0);
}