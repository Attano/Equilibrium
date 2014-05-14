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
#include <left4downtown> // min v0.5.7
#include <readyup>

enum L4D2Team
{
	L4D2Team_None = 0,
	L4D2Team_Spectator,
	L4D2Team_Survivor,
	L4D2Team_Infected
};

public Plugin:myinfo =
{
	name = "L4D2 Caster Addons Manager",
	author = "Visor",
	description = "Allows casters to join the server with their addons on",
	version = "1.2",
	url = "https://github.com/Attano/Equilibrium"
};

public OnPluginStart()
{
	HookEvent("player_team", OnTeamChange);
}

public Action:L4D2_OnClientDisableAddons(const String:SteamID[])
{
	return IsIDCaster(SteamID) ? Plugin_Handled : Plugin_Continue;
}

public OnTeamChange(Handle:event, String:name[], bool:dontBroadcast)
{
	if (L4D2Team:GetEventInt(event, "team") != L4D2Team_Spectator)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		CreateTimer(1.0, CasterCheck, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:CasterCheck(Handle:timer, any:client)
{
	if (client && IsClientInGame(client) && L4D2Team:GetClientTeam(client) != L4D2Team_Spectator && IsClientCaster(client))
	{
		PrintToChat(client, "\x01<\x05Cast\x01> Unregister from casting first before playing.");
		PrintToChat(client, "\x01<\x05Cast\x01> Use \x04!notcasting");
		ChangeClientTeam(client, _:L4D2Team_Spectator);
	}
}