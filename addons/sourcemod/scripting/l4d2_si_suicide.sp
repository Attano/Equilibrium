#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <colors>

new const infectedProps[] = 
{
	13280,	// smoker
	16004,	// hunter
	16124,	// jockey
	15972	// charger
};

static const String:L4D2SI_Names[][] = 
{
	"None",
	"Smoker",
	"Boomer",
	"Hunter",
	"Spitter",
	"Jockey",
	"Charger",
	"Witch",
	"Tank"
};

public Plugin:myinfo = 
{
	name = "L4D2 SI Suicide",
	author = "Visor",
	description = "Allows the SI to commit a suicide under certain circumstances",
	version = "1.2",
	url = "https://github.com/Attano/Equilibrium"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_kill", CommitSuicideCmd);
	RegConsoleCmd("sm_suicide", CommitSuicideCmd);
}

public Action:CommitSuicideCmd(client, args)
{
	new String:error[256];
	if (!IsInfected(client) || !IsPlayerAlive(client) || IsGhost(client))
	{
		error = "You must be a living, spawned SI in order to use this command.";
	}
	else if (IsVisibleToSurvivors(client))
	{
		error = "You can't commit suicide while being in the range of Survivor visibility.";
	}
	else if (IsAttacking(client))
	{
		error = "You can't commit suicide while attacking a Survivor.";
	}
	else if (GetInfectedClass(client) == 8)
	{
		error = "You want to commit suicide as a Tank? Really?";
	}

	if (error[0] != EOS)
	{
	        CPrintToChat(client, "<{olive}ZombieSuicide{default}> %s", error);
	        return Plugin_Handled;
	}

	ForcePlayerSuicide(client);
	CPrintToChatAll("<{olive}ZombieSuicide{default}> {red}%N{default}[{green}%s{default}] has committed a suicide!", client, L4D2SI_Names[GetInfectedClass(client)-1]);
	return Plugin_Continue;
}

bool:IsSurvivor(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

bool:IsInfected(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3);
}

bool:IsGhost(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isGhost"); 
}

GetInfectedClass(client)
{
	return GetEntProp(client, Prop_Send, "m_zombieClass");
}

bool:IsAttacking(infected)
{
	new client;
	for (new i = 0; i < sizeof(infectedProps); i++)
	{
		client = GetEntDataEnt2(infected, infectedProps[i]);
		if (IsSurvivor(client) && IsPlayerAlive(client))
			return true;
	}
	return false;
}

// from http://code.google.com/p/srsmod/source/browse/src/scripting/srs.despawninfected.sp
stock bool:IsVisibleToSurvivors(entity)
{
	new iSurv;

	for (new i = 1; i < MaxClients && iSurv < 4; i++)
	{
		if (IsSurvivor(i))
		{
			iSurv++;
			if (IsPlayerAlive(i) && IsVisibleTo(i, entity)) 
			{
				return true;
			}
		}
	}

	return false;
}

stock bool:IsVisibleTo(client, entity) // check an entity for being visible to a client
{
	decl Float:vAngles[3], Float:vOrigin[3], Float:vEnt[3], Float:vLookAt[3];
	
	GetClientEyePosition(client,vOrigin); // get both player and zombie position
	
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vEnt);
	
	MakeVectorFromPoints(vOrigin, vEnt, vLookAt); // compute vector from player to zombie
	
	GetVectorAngles(vLookAt, vAngles); // get angles from vector for trace
	
	// execute Trace
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceFilter);
	
	new bool:isVisible = false;
	if (TR_DidHit(trace))
	{
		decl Float:vStart[3];
		TR_GetEndPosition(vStart, trace); // retrieve our trace endpoint
		
		if ((GetVectorDistance(vOrigin, vStart, false) + 75.0) >= GetVectorDistance(vOrigin, vEnt))
		{
			isVisible = true; // if trace ray lenght plus tolerance equal or bigger absolute distance, you hit the targeted zombie
		}
	}
	else
	{
		//Debug_Print("Zombie Despawner Bug: Player-Zombie Trace did not hit anything, WTF");
		isVisible = true;
	}
	CloseHandle(trace);
	return isVisible;
}

public bool:TraceFilter(entity, contentsMask)
{
	if (entity <= MaxClients || !IsValidEntity(entity)) // dont let WORLD, players, or invalid entities be hit
	{
		return false;
	}
	
	decl String:class[128];
	GetEdictClassname(entity, class, sizeof(class)); // Ignore prop_physics since some can be seen through
	
	return !StrEqual(class, "prop_physics", false);
}
