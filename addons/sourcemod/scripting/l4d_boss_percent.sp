/*
	SourcePawn is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved.
	SourceMod is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved.
	Pawn and SMALL are Copyright (C) 1997-2008 ITB CompuPhase.
	Source is Copyright (C) Valve Corporation.
	All trademarks are property of their respective owners.

	This program is free software: you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the
	Free Software Foundation, either version 3 of the License, or (at your
	option) any later version.

	This program is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	General Public License for more details.

	You should have received a copy of the GNU General Public License along
	with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
#pragma semicolon 1

#include <sourcemod>
#include <l4d2_direct>
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util>
#undef REQUIRE_PLUGIN
#include <readyup>

public Plugin:myinfo =
{
	name = "L4D2 Boss Flow Announce (Back to roots edition)",
	author = "ProdigySim, Jahze, Stabby, CircleSquared, CanadaRox, Visor",
	version = "1.6.1",
	description = "Announce boss flow percents!",
	url = "https://github.com/Attano/Equilibrium"
};

new iWitchPercent = 0;
new iTankPercent = 0;

new Handle:g_hVsBossBuffer;
new Handle:hCvarPrintToEveryone;
new Handle:hCvarTankPercent;
new Handle:hCvarWitchPercent;
new bool:readyUpIsAvailable;
new bool:readyFooterAdded;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("UpdateBossPercents", Native_UpdateBossPercents);
	MarkNativeAsOptional("AddStringToReadyFooter");
	RegPluginLibrary("l4d_boss_percent");
	return APLRes_Success;
}

public OnPluginStart()
{
	g_hVsBossBuffer = FindConVar("versus_boss_buffer");

	hCvarPrintToEveryone = CreateConVar("l4d_global_percent", "1", "Display boss percentages to entire team when using commands", FCVAR_PLUGIN);
	hCvarTankPercent = CreateConVar("l4d_tank_percent", "1", "Display Tank flow percentage in chat", FCVAR_PLUGIN);
	hCvarWitchPercent = CreateConVar("l4d_witch_percent", "1", "Display Witch flow percentage in chat", FCVAR_PLUGIN);

	RegConsoleCmd("sm_boss", BossCmd);
	RegConsoleCmd("sm_tank", BossCmd);
	RegConsoleCmd("sm_witch", BossCmd);

	HookEvent("player_left_start_area", LeftStartAreaEvent, EventHookMode_PostNoCopy);
	HookEvent("round_start", RoundStartEvent, EventHookMode_PostNoCopy);
}

public OnAllPluginsLoaded()
{
	readyUpIsAvailable = LibraryExists("readyup");
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "readyup")) readyUpIsAvailable = false;
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "readyup")) readyUpIsAvailable = true;
}

public LeftStartAreaEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!readyUpIsAvailable)
		for (new client = 1; client <= MaxClients; client++)
			if (IsClientConnected(client) && IsClientInGame(client))
				PrintBossPercents(client);
}

public OnRoundIsLive()
{
	for (new client = 1; client <= MaxClients; client++)
		if (IsClientConnected(client) && IsClientInGame(client))
			PrintBossPercents(client);
}

public RoundStartEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	readyFooterAdded = false;

	CreateTimer(5.0, SaveBossFlows);
	CreateTimer(6.0, AddReadyFooter); // workaround for boss equalizer
}

public Native_UpdateBossPercents(Handle:plugin, numParams)
{
	CreateTimer(0.1, SaveBossFlows);
	CreateTimer(0.2, AddReadyFooter);
	return true;
}

public Action:SaveBossFlows(Handle:timer)
{
	if (!InSecondHalfOfRound())
	{
		iWitchPercent = 0;
		iTankPercent = 0;

		if (L4D2Direct_GetVSWitchToSpawnThisRound(0))
		{
			iWitchPercent = RoundToNearest(GetWitchFlow(0)*100.0);
		}
		if (L4D2Direct_GetVSTankToSpawnThisRound(0))
		{
			iTankPercent = RoundToNearest(GetTankFlow(0)*100.0);
		}
	}
	else
	{
		if (iWitchPercent != 0)
		{
			iWitchPercent = RoundToNearest(GetWitchFlow(1)*100.0);
		}
		if (iTankPercent != 0)
		{
			iTankPercent = RoundToNearest(GetTankFlow(1)*100.0);
		}
	}
}

public Action:AddReadyFooter(Handle:timer)
{
	if (readyFooterAdded) return;
	if (readyUpIsAvailable)
	{
		decl String:readyString[65];
		if (iWitchPercent && iTankPercent)
			Format(readyString, sizeof(readyString), "Tank: %d%%, Witch: %d%%", iTankPercent, iWitchPercent);
		else if (iTankPercent)
			Format(readyString, sizeof(readyString), "Tank: %d%%, Witch: None", iTankPercent);
		else if (iWitchPercent)
			Format(readyString, sizeof(readyString), "Tank: None, Witch: %d%%", iWitchPercent);
		else
			Format(readyString, sizeof(readyString), "Tank: None, Witch: None");
		AddStringToReadyFooter(readyString);
		readyFooterAdded = true;
	}
}

stock PrintBossPercents(client)
{
	if(GetConVarBool(hCvarTankPercent))
	{
		if (iTankPercent)
			PrintToChat(client, "\x01Tank spawn: [\x04%d%%\x01]", iTankPercent);
		else
			PrintToChat(client, "\x01Tank spawn: [\x04None\x01]");
	}

	if(GetConVarBool(hCvarWitchPercent))
	{
		if (iWitchPercent)
			PrintToChat(client, "\x01Witch spawn: [\x04%d%%\x01]", iWitchPercent);
		else
			PrintToChat(client, "\x01Witch spawn: [\x04None\x01]");
	}
}

public Action:BossCmd(client, args)
{
	new L4D2_Team:iTeam = L4D2_Team:GetClientTeam(client);
	if (iTeam == L4D2Team_Spectator)
	{
		PrintBossPercents(client);
		return Plugin_Handled;
	}

	if (GetConVarBool(hCvarPrintToEveryone))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && L4D2_Team:GetClientTeam(i) == iTeam)
			{
				PrintBossPercents(i);
			}
		}
	}
	else
	{
		PrintBossPercents(client);
	}

	return Plugin_Handled;
}

stock Float:GetTankFlow(round)
{
	return L4D2Direct_GetVSTankFlowPercent(round) -
		( Float:GetConVarInt(g_hVsBossBuffer) / L4D2Direct_GetMapMaxFlowDistance() );
}

stock Float:GetWitchFlow(round)
{
	return L4D2Direct_GetVSWitchFlowPercent(round) -
		( Float:GetConVarInt(g_hVsBossBuffer) / L4D2Direct_GetMapMaxFlowDistance() );
}