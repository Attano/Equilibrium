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

new Handle:hCvarAddonsEclipse;

new bool:bReadyUpIsAvailable;

public Plugin:myinfo =
{
	name = "L4D2 Caster Addons Manager",
	author = "Visor",
	description = "Allows casters to join the server with their addons on",
	version = "1.0",
	url = "https://github.com/Attano/Equilibrium"
};

public OnAllPluginsLoaded()
{
    bReadyUpIsAvailable = LibraryExists("readyup");
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "readyup")) bReadyUpIsAvailable = false;
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "readyup")) bReadyUpIsAvailable = true;
}

public OnConfigsExecuted()
{
    hCvarAddonsEclipse = FindConVar("l4d2_addons_eclipse");
    if (hCvarAddonsEclipse == INVALID_HANDLE || !bReadyUpIsAvailable) 
    {
        SetFailState("'L4D2 Caster Addons Manager' requires at least Left4Downtown2 v0.5.7 and L4D2 Ready Up v6 to work");
    }
    HookConVarChange(hCvarAddonsEclipse, OnAddonsEclipseChanged);
}

public OnAddonsEclipseChanged(Handle:cvar, const String:sOldValue[], const String:sNewValue[]) 
{
    new oldValue = StringToInt(sNewValue);
    new newValue = StringToInt(sOldValue);
    new action = (newValue > 0 && oldValue <= 0) ? 1/* hook */ : ((newValue <= 0 && oldValue > 0) ? -1/* unhook */ : 0/* do nothing */);
    switch (action)
    {
        case 1:
        {
            HookEvent("player_team", OnTeamChange);
        }
        case -1:
        {
            UnhookEvent("player_team", OnTeamChange);
        }
    }
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
        PrintToChat(client, "\x01[\x04Addons Manager\x01] Casters are not allowed into the game with the \x05Addons Disabler\x01 active! Give up your caster status first by typing \x03!notcasting\x01 in chat");
        ChangeClientTeam(client, _:L4D2Team_Spectator);
    }
}