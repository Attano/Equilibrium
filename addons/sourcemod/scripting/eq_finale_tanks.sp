#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <left4downtown>
#include <l4d2_direct>

#define FINALE_STAGE_TANK 8

new Handle:hFinaleIntroTankMaps;

new tankCount;

new bool:bIntroTank;

public Plugin:myinfo =
{
	name = "EQ2 Finale Tank Manager",
	author = "Visor",
	description = "Either two event tanks or one flow and one event tank",
	version = "2.1",
	url = "https://github.com/Attano/Equilibrium"
};

public OnPluginStart()
{
	HookEvent("round_start", EventHook:OnRoundStart, EventHookMode_PostNoCopy);

	hFinaleIntroTankMaps = CreateTrie();

	RegServerCmd("intro_tank_finale_map", SetFinaleIntroTankMap);
}

public Action:SetFinaleIntroTankMap(args)
{
	decl String:mapname[64];
	GetCmdArg(1, mapname, sizeof(mapname));
	SetTrieValue(hFinaleIntroTankMaps, mapname, true);
}

public OnRoundStart()
{
	CreateTimer(1.0, ProcessTankSpawn);
}

public Action:ProcessTankSpawn(Handle:timer) 
{
	if (L4D2_IsFinalMap() && IsTankAllowed())
	{
		decl String:mapname[64];
		GetCurrentMap(mapname, sizeof(mapname));

		if (!GetTrieValue(hFinaleIntroTankMaps, mapname, bIntroTank))
		{
			bIntroTank = false;
		}
		L4D2Direct_SetVSTankToSpawnThisRound(InSecondHalfOfRound(), bIntroTank);

		tankCount = 0;
	}
}

public Action:L4D2_OnChangeFinaleStage(&finaleType, const String:arg[]) 
{
	if (finaleType == FINALE_STAGE_TANK) 
	{
		tankCount++;
		if (tankCount > 2 || (bIntroTank && tankCount != 2))
			return Plugin_Handled;
	}

	return Plugin_Continue;
}

InSecondHalfOfRound()
{
	return GameRules_GetProp("m_bInSecondHalfOfRound");
}

bool:L4D2_IsFinalMap()
{
	return bool:LoadFromAddress(L4D2Direct_InFinaleMapAddr(), NumberType_Int8);
}

bool:IsTankAllowed()
{
	return GetConVarFloat(FindConVar("versus_tank_chance_finale")) > 0.0;
}

stock Address:L4D2Direct_InFinaleMapAddr()
{
	static Address:pInFinale = Address_Null;
	if (pInFinale == Address_Null)
	{
		new offs = GameConfGetOffset(L4D2Direct_GetGameConf(), "CDirectorVersusMode::m_bInFinaleMap");
		if (offs == -1) return Address_Null;
		pInFinale = L4D2Direct_GetCDirectorVersusMode() + Address:offs;
	}
	return pInFinale;
}