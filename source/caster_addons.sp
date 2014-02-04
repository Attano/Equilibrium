#pragma semicolon 1

#include <sourcemod>
#include <left4downtown> // min v0.5.7
#include <readyup>
#include <colors>

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
	version = "1.0.1",
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
        CreateTimer(0.1, CasterCheck, client, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action:CasterCheck(Handle:timer, any:client)
{
    if (IsClientCaster(client))
    {
        CPrintToChat(client, "{blue}[{default}Cast{blue}]{default}: Unregister from Casting before Playing first.");
        CPrintToChat(client, "{blue}[{default}Cast{blue}]{default}: Use {olive}!notcasting");
        ChangeClientTeam(client, _:L4D2Team_Spectator);
    }
}