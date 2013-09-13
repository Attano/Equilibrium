#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <left4downtown>
#include <l4d2_direct>
#include <l4d2lib>

#define EQSM_DEBUG	0

/** 
	Bibliography:
	'l4d2_scoremod' by CanadaRox, ProdigySim
	'damage_bonus' by CanadaRox, Stabby
	'l4d2_scoringwip' by ProdigySim
	'srs.scoringsystem' by AtomicStryker
**/

new Handle:hCvarSurvivorBonusMultiplier;
new Handle:hCvarInfectedBonusProportion;
new Handle:hCvarSurvivalBonus;
new Handle:hCvarTieBreaker;

new Float:fMapHealthBonus;
new Float:fHealthBonusMulti;
new Float:fDamageBonusProp;
new Float:fTempHpWorth;
new Float:fPermHpWorth;
new Float:fSurvivorBonus[2];
new Float:fInfectedBonus[2];

new iTeamSize;
new iMapDistance;
new iInfectedCampaignScore;
new iTempHealth[MAXPLAYERS + 1];

new bool:bLateLoad;
new bool:bRoundOver;

public Plugin:myinfo =
{
	name = "L4D2 Equilibrium 2.0 Scoring System",
	author = "Visor",
	description = "Custom scoring system, designed for Equilibrium 2.0",
	version = "1.0",
	url = ""
};

public APLRes:AskPluginLoad2(Handle:plugin, bool:late, String:error[], errMax) 
{
    bLateLoad = late;
    return APLRes_Success;
}

public OnPluginStart()
{
	hCvarSurvivorBonusMultiplier = CreateConVar("eqsm_survivor_bonus_multiplier", "2.0", "Survivor Health Bonus(applies only to permanent health) = this * Map Distance", FCVAR_PLUGIN, true, 0.25);
	hCvarInfectedBonusProportion = CreateConVar("eqsm_infected_bonus_proportion", "400.0", "Infected Damage Bonus(applies only to temporary health) = this / Map Bonus", FCVAR_PLUGIN, true, 0.05);
	hCvarSurvivalBonus = FindConVar("vs_survival_bonus");
	hCvarTieBreaker = FindConVar("vs_tiebreak_bonus");

	HookConVarChange(hCvarSurvivorBonusMultiplier, CvarChanged);
	HookConVarChange(hCvarInfectedBonusProportion, CvarChanged);

	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("door_close", OnDoorClose);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("finale_vehicle_leaving", OnFinaleVehicleLeaving, EventHookMode_PostNoCopy);

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
	fHealthBonusMulti = GetConVarFloat(hCvarSurvivorBonusMultiplier) / 4/* max survivors */ * iTeamSize;
	fDamageBonusProp = GetConVarFloat(hCvarInfectedBonusProportion);
	SetConVarInt(hCvarTieBreaker, 0);

	iMapDistance = L4D2_GetMapValueInt("max_distance", L4D_GetVersusMaxCompletionScore());
	L4D_SetVersusMaxCompletionScore(iMapDistance);

	fMapHealthBonus = iMapDistance * fHealthBonusMulti;
	fPermHpWorth = fMapHealthBonus / iTeamSize / 100;
	fTempHpWorth = fDamageBonusProp / fMapHealthBonus;
	#if EQSM_DEBUG
        PrintToChatAll("\x01Map health bonus: \x05%.1f\x01, perm hp worth: \x03%.1f\x01, temp hp worth: \x03%.1f\x01", fMapHealthBonus, fPermHpWorth, fTempHpWorth);
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
	CreateTimer(1.0, StoreInfectedScore, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:StoreInfectedScore(Handle:timer) 
{
	iInfectedCampaignScore = L4D2Direct_GetVSCampaignScore(GetInfectedTeamIndex());
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
		if (GetSurvivorTempHealth(victim) > 0) PrintToChatAll("\x01\x04%N\x01 has \x05%d\x01 temp HP now(damage: \x03%.1f\x01)", victim, GetSurvivorTempHealth(victim), damage);
    #endif
	iTempHealth[victim] = GetSurvivorTempHealth(victim);
	return Plugin_Continue;
}

// OnTakeDamagePost() does the opposite: it messes up pointer arguments but works fine with the normal ones
// SDKHooks probably treats OTD() args as "by-ref" and OTDP() as normal ones
// Pawn gets confused and we end up with wrong values
public OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype)
{
	if (iTempHealth[victim] < 1 || !IsAnyInfected(attacker) || IsPlayerLedged(victim))
		return;

	#if EQSM_DEBUG
		PrintToChatAll("\x03%N\x01 lost \x05%i\x01 temp HP after being attacked by \x04%N\x01(arg damage: \x03%.1f\x01)", victim, iTempHealth[victim] - (IsPlayerAlive(victim) ? GetSurvivorTempHealth(victim) : 0), attacker, damage);
	#endif
	fInfectedBonus[InSecondHalfOfRound()] += (iTempHealth[victim] - (IsPlayerAlive(victim) ? GetSurvivorTempHealth(victim) : 0)) * fTempHpWorth;
	iTempHealth[victim] = GetSurvivorTempHealth(victim);

	// Workaround for some visually missing SI bonus points? Let's see if this works...
	//if (IsPlayerIncap(victim) || !IsPlayerAlive(victim)) UpdateScores();
}

public OnDoorClose(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetEventBool(event, "checkpoint"))
	{
		UpdateScores();
	}
}

public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsSurvivor(GetClientOfUserId(GetEventInt(event, "userid"))))
	{
		UpdateScores();
	}
}

public OnFinaleVehicleLeaving(Handle:event, const String:name[], bool:dontBroadcast)
{
	UpdateScores();
}

UpdateScores()
{
	if (GameRules_GetProp("m_iSurvivorScore", _, InSecondHalfOfRound()) <= 0) // failsafe
		return;

	/* Survivor bonus */
	new iSurvivalMultiplier = GetUprightSurvivors();
	if (iSurvivalMultiplier > 0 || GetSurvivorBonus() >= 1.0)
	{
		SetConVarInt(hCvarSurvivalBonus, RoundToFloor(GetSurvivorBonus() / iSurvivalMultiplier));
		fSurvivorBonus[InSecondHalfOfRound()] = float(GetConVarInt(hCvarSurvivalBonus) * iSurvivalMultiplier);	// workaround for the discrepancy caused by RoundToFloor()
		#if EQSM_DEBUG
			PrintToChatAll("\x01Survival bonus cvar updated. Value: \x05%i\x01 [total: \x03%f\x01, multiplier: \x05%i\x01]", GetConVarInt(hCvarSurvivalBonus), GetSurvivorBonus(), iSurvivalMultiplier);
		#endif
	}

	/* Infected bonus */
	//new bool:bChangeState = GetInfectedBonus() >= 1.0;
	new iInfectedTeamIndex = GetInfectedTeamIndex();
	new iInfectedNewScore = iInfectedCampaignScore + RoundToFloor(GetInfectedBonus());

	//GameRules_SetProp("m_iCampaignScore", iInfectedNewScore, _, iInfectedTeamIndex, bChangeState);	// Visual campaign score
	L4D2Direct_SetVSCampaignScore(iInfectedTeamIndex, iInfectedNewScore);	// Real(internal) campaign score
	#if EQSM_DEBUG
        PrintToChatAll("\x01Infected bonus data updated. Value: \x05%d\x01 [score: \x03%d\x01]", RoundToFloor(GetInfectedBonus()), iInfectedNewScore);
    #endif
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
				fSurvivorBonus[InSecondHalfOfRound()] += GetSurvivorPermanentHealth(i) * fPermHpWorth;
				#if EQSM_DEBUG
					PrintToChatAll("\x01Adding \x05%N's\x01 bonus contribution: \x05%d\x01 perm HP -> \x03%.1f\x01 bonus; new total: \x05%.1f\x01", i, GetSurvivorPermanentHealth(i), GetSurvivorPermanentHealth(i) * fPermHpWorth, fSurvivorBonus[InSecondHalfOfRound()]);
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
	return GetEntProp(client, Prop_Send, "m_currentReviveCount") > 0 ? 0 : GetEntProp(client, Prop_Send, "m_iHealth");
}