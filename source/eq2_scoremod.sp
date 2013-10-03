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

new Handle:hCvarSurvivorBonusMultiplier;
new Handle:hCvarInfectedBonusProportionPermHp;
new Handle:hCvarInfectedBonusProportionTempHp;
new Handle:hCvarSurvivalBonus;
new Handle:hCvarTieBreaker;

new Float:fMapHealthBonus;
new Float:fSurvPermHpWorth;
new Float:fInfPermHpWorth;
new Float:fTempHpWorth;
new Float:fSurvivorBonus[2];
new Float:fInfectedBonus[2];

new iTeamSize;
new iMapDistance;
new iPermHealth[MAXPLAYERS + 1];
new iTempHealth[MAXPLAYERS + 1];

new bool:bLateLoad;
new bool:bRoundOver;

public Plugin:myinfo =
{
    name = "L4D2 Equilibrium 2.0 Scoring System",
    author = "Visor",
    description = "Custom scoring system, designed for Equilibrium 2.0",
    version = "1.1",
    url = "https://github.com/Attano/Equilibrium"
};

public APLRes:AskPluginLoad2(Handle:plugin, bool:late, String:error[], errMax) 
{
    bLateLoad = late;
    return APLRes_Success;
}

public OnPluginStart()
{
    hCvarSurvivorBonusMultiplier = CreateConVar("eqsm_survivor_bonus_multiplier", "2.0", "Survivor Health Bonus(applies only to permanent health) = this * Map Distance", FCVAR_PLUGIN, true, 0.25);
    hCvarInfectedBonusProportionPermHp = CreateConVar("eqsm_infected_bonus_proportion_perm_hp", "0.25", "Infected Damage Bonus(for permanent health) = Map Bonus / 100 * this", FCVAR_PLUGIN);
    hCvarInfectedBonusProportionTempHp = CreateConVar("eqsm_infected_bonus_proportion_temp_hp", "0.1", "Infected Damage Bonus(for temporary health) = Map Bonus / 100 * this", FCVAR_PLUGIN);
    hCvarSurvivalBonus = FindConVar("vs_survival_bonus");
    hCvarTieBreaker = FindConVar("vs_tiebreak_bonus");

    HookConVarChange(hCvarSurvivorBonusMultiplier, CvarChanged);
    HookConVarChange(hCvarInfectedBonusProportionPermHp, CvarChanged);
    HookConVarChange(hCvarInfectedBonusProportionTempHp, CvarChanged);

    HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);

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

    iMapDistance = L4D2_GetMapValueInt("max_distance", L4D_GetVersusMaxCompletionScore());
    L4D_SetVersusMaxCompletionScore(iMapDistance);

    fMapHealthBonus = iMapDistance * (GetConVarFloat(hCvarSurvivorBonusMultiplier) / 4/* max survivors */ * iTeamSize);
    fSurvPermHpWorth = fMapHealthBonus / iTeamSize / 100;
    fInfPermHpWorth = fMapHealthBonus / 100 * GetConVarFloat(hCvarInfectedBonusProportionPermHp);
    fTempHpWorth = fMapHealthBonus / 100 * GetConVarFloat(hCvarInfectedBonusProportionTempHp);
    #if EQSM_DEBUG
        PrintToChatAll("\x01Map health bonus: \x05%.1f\x01, surv perm hp worth: \x03%.1f\x01, inf perm hp worth: \x03%.1f\x01, temp hp worth: \x03%.1f\x01", fMapHealthBonus, fSurvPermHpWorth, fInfPermHpWorth, fTempHpWorth);
    #endif
}

public OnMapStart()
{
    OnConfigsExecuted();
    
    fInfectedBonus[0] = 0.0;
    fInfectedBonus[1] = 0.0;
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

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new i = 0; i < MAXPLAYERS; i++)
    {
        iTempHealth[i] = 0;
    }

    bRoundOver = false;
}

public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (bRoundOver == false)
    {
        for (new i = 0; i <= InSecondHalfOfRound(); i++)
        {
            PrintToChatAll("\x01[\x04EQSM\x01 | Round \x03%i\x01] Survivor Bonus: \x05%d\x01 <\x03%.1f%%\x01> | Infected Bonus: \x05%d\x01", (i + 1), RoundToFloor(fSurvivorBonus[i]), CalculatePerformance(fSurvivorBonus[i]), RoundToFloor(fInfectedBonus[i]));
        }
    }

    bRoundOver = true;
}

public Action:CmdBonus(client, args)
{
    ReplyToCommand(client, "\x01[\x04EQSM\x01 | The Road So Far...] R\x03#%i\x01 SB: \x05%d\x01/\x05%d\x01 | IB: \x05%d\x01", InSecondHalfOfRound() + 1, RoundToFloor(GetSurvivorBonus()), RoundToNearest(fMapHealthBonus), RoundToFloor(GetInfectedBonus()));
    return Plugin_Handled;
}

// OnTakeDamage() only provides correct argument values when they're reference pointers
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
    if (!IsSurvivor(victim) || !IsAnyInfected(attacker) || IsPlayerIncap(victim))
        return Plugin_Continue;

    #if EQSM_DEBUG
        if (GetSurvivorPermanentHealth(victim) + GetSurvivorTempHealth(victim) > 0) PrintToChatAll("\x01\x04%N\x01 has \x05%d\x01 temp HP now and \x05%d\x01 perm HP(damage: \x03%.1f\x01)", victim, GetSurvivorTempHealth(victim), GetSurvivorPermanentHealth(victim), damage);
    #endif
    iPermHealth[victim] = GetSurvivorPermanentHealth(victim);
    iTempHealth[victim] = GetSurvivorTempHealth(victim);

    return Plugin_Continue;
}

// OnTakeDamagePost() does the opposite: it messes up pointer arguments but works fine with the normal ones
// SDKHooks probably treats OTD() args as "by-ref" and OTDP() as normal ones
// Pawn gets confused and we end up with wrong values
public OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype)
{
    if (iPermHealth[victim] + iTempHealth[victim] < 1 || !IsAnyInfected(attacker) || IsPlayerIncap(victim) || IsPlayerLedged(victim))
        return;

    #if EQSM_DEBUG
        PrintToChatAll("\x03%N\x01 lost \x05%i\x01 perm HP and \x05%i\x01 temp HP after being attacked(arg damage: \x03%.1f\x01)", victim, iPermHealth[victim] - (IsPlayerAlive(victim) ? GetSurvivorPermanentHealth(victim) : 0), iTempHealth[victim] - (IsPlayerAlive(victim) ? GetSurvivorTempHealth(victim) : 0), damage);
    #endif
    fInfectedBonus[InSecondHalfOfRound()] += (iPermHealth[victim] - (IsPlayerAlive(victim) ? GetSurvivorPermanentHealth(victim) : 0)) * fInfPermHpWorth;
    fInfectedBonus[InSecondHalfOfRound()] += (iTempHealth[victim] - (IsPlayerAlive(victim) ? GetSurvivorTempHealth(victim) : 0)) * fTempHpWorth;
    
    iPermHealth[victim] = GetSurvivorPermanentHealth(victim);
    iTempHealth[victim] = GetSurvivorTempHealth(victim);
}

public Action:L4D2_OnEndVersusModeRound(bool:countSurvivors)
{
    #if EQSM_DEBUG
        PrintToChatAll("CDirector::OnEndVersusModeRound() called. InSecondHalfOfRound(): %d, countSurvivors: %d", InSecondHalfOfRound(), countSurvivors);
    #endif

    new iSurvivalMultiplier = GetUprightSurvivors();    // I don't know how reliable countSurvivors is and I'm too lazy to test
    if (iSurvivalMultiplier > 0 || GetSurvivorBonus() >= 1.0)
    {
        /* Survivor bonus */
        SetConVarInt(hCvarSurvivalBonus, RoundToFloor(GetSurvivorBonus() / iSurvivalMultiplier));
        fSurvivorBonus[InSecondHalfOfRound()] = float(GetConVarInt(hCvarSurvivalBonus) * iSurvivalMultiplier);    // workaround for the discrepancy caused by RoundToFloor()
        #if EQSM_DEBUG
            PrintToChatAll("\x01Survival bonus cvar updated. Value: \x05%i\x01 [multiplier: \x05%i\x01]", GetConVarInt(hCvarSurvivalBonus), iSurvivalMultiplier);
        #endif
    }
    
    /* Infected bonus */
    new iInfectedNewScore = L4D2Direct_GetVSCampaignScore(GetInfectedTeamIndex()) + RoundToFloor(GetInfectedBonus());
    L4D2Direct_SetVSCampaignScore(GetInfectedTeamIndex(), iInfectedNewScore);    // Real(internal) campaign score
    #if EQSM_DEBUG
        PrintToChatAll("\x01Infected bonus data updated. Value: \x05%d\x01 [score: \x03%d\x01]", RoundToFloor(GetInfectedBonus()), iInfectedNewScore);
    #endif

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

Float:GetSurvivorBonus()
{
    fSurvivorBonus[InSecondHalfOfRound()] = 0.0;

    new iSurvivorCount;
    for (new i = 1; i <= MaxClients && iSurvivorCount < iTeamSize; i++)
    {
        if (IsSurvivor(i))
        {
            iSurvivorCount++;
            if (IsPlayerAlive(i) && !IsPlayerIncap(i) && !IsPlayerLedged(i))
            {
                fSurvivorBonus[InSecondHalfOfRound()] += GetSurvivorPermanentHealth(i) * fSurvPermHpWorth;
                #if EQSM_DEBUG
                    PrintToChatAll("\x01Adding \x05%N's\x01 bonus contribution: \x05%d\x01 perm HP -> \x03%.1f\x01 bonus; new total: \x05%.1f\x01", i, GetSurvivorPermanentHealth(i), GetSurvivorPermanentHealth(i) * fSurvPermHpWorth, fSurvivorBonus[InSecondHalfOfRound()]);
                #endif
            }
        }
    }
    
    return fSurvivorBonus[InSecondHalfOfRound()];
}

Float:GetInfectedBonus()
{
    return fInfectedBonus[InSecondHalfOfRound()];
}

Float:CalculatePerformance(Float:score)
{
    return score / fMapHealthBonus * 100;
}

/************/
/** Stocks **/
/************/

stock InSecondHalfOfRound()
{
    return GameRules_GetProp("m_bInSecondHalfOfRound");
}

stock GetInfectedTeamIndex()
{
    return GameRules_GetProp("m_bAreTeamsFlipped") ? 0 : 1;
}

stock bool:IsSurvivor(client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

stock bool:IsAnyInfected(entity)
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

stock bool:IsPlayerIncap(client)
{
    return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

stock bool:IsPlayerLedged(client)
{
    return bool:(GetEntProp(client, Prop_Send, "m_isHangingFromLedge") | GetEntProp(client, Prop_Send, "m_isFallingFromLedge"));
}

stock GetSurvivorTempHealth(client)
{
    new temphp = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(FindConVar("pain_pills_decay_rate")))) - 1;
    return (temphp > 0 ? temphp : 0);
}

stock GetSurvivorPermanentHealth(client)
{
    // Survivors always have minimum 1 permanent hp
    // so that they don't faint in place just like that when all temp hp run out
    // We'll use a workaround for the sake of fair calculations
    // Edit 2: "Incapped HP" are stored in m_iHealth too; we heard you like workarounds, dawg, so we've added a workaround in a workaround
    return GetEntProp(client, Prop_Send, "m_currentReviveCount") > 0 ? 0 : (GetEntProp(client, Prop_Send, "m_iHealth") > 0 ? GetEntProp(client, Prop_Send, "m_iHealth") : 0);
}