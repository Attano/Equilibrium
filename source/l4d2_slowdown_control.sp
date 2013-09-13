#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>

new Handle:hCvarSlowdownSi;
new Handle:hCvarSlowdownTank;
new Handle:hCvarSlowdownTankLit;

new Float:fSlowdownSi;
new Float:fSlowdownTank;
new Float:fSlowdownTankLit;

public Plugin:myinfo = {
    name        = "L4D2 SI Slowdown Control",
    author      = "Visor; originally by Jahze",
    version     = "1.3",
    description = "Manages the slowdown for special infected"
};

public OnPluginStart() {
	hCvarSlowdownSi = CreateConVar("l4d2_slowdown_si", "0.0", "Slowdown from gunfire for SI(-1:default slowdown; 0:no slowdown; >0: velocity multiplier)", FCVAR_PLUGIN);
	hCvarSlowdownTank = CreateConVar("l4d2_slowdown_tank", "0.0", "Slowdown from gunfire for Tank(-1:default slowdown; 0:no slowdown; >0: velocity multiplier)", FCVAR_PLUGIN); 
	hCvarSlowdownTankLit = CreateConVar("l4d2_slowdown_lit_tank", "0.0", "Slowdown from gunfire for an ignited Tank(-1:default slowdown; 0:no slowdown; >0: velocity multiplier)", FCVAR_PLUGIN);

	UpdateCvars();

	HookConVarChange(hCvarSlowdownSi, CvarChanged);
	HookConVarChange(hCvarSlowdownTank, CvarChanged);
	HookConVarChange(hCvarSlowdownTankLit, CvarChanged);
}

UpdateCvars() {
	fSlowdownSi = GetConVarFloat(hCvarSlowdownSi) == 0.0 ? 1.0 : GetConVarFloat(hCvarSlowdownSi);
	fSlowdownTank = GetConVarFloat(hCvarSlowdownTank) == 0.0 ? 1.0 : GetConVarFloat(hCvarSlowdownTank);
	fSlowdownTankLit = GetConVarFloat(hCvarSlowdownTankLit) == 0.0 ? 1.0 : GetConVarFloat(hCvarSlowdownTankLit);
}

public OnClientPutInServer(client) {
    SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}

public OnClientDisconnect(client) {
    SDKUnhook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}

public Action:OnTakeDamagePost(victim, &attacker, &inflictor, &Float:damage, &damageType, &weapon, Float:damageForce[3], Float:damagePosition[3]) {
	new Float:fVelocityModifier = GetVelocityModifierFor(victim);
	if (fVelocityModifier != -1.0) {
		SetEntPropFloat(victim, Prop_Send, "m_flVelocityModifier", fVelocityModifier);
	}
}

Float:GetVelocityModifierFor(client) {
	if (!IsClientInGame(client) || GetClientTeam(client) != 3 )
		return -1.0;

	new zombieclass = GetEntProp(client, Prop_Send, "m_zombieClass");
	if (zombieclass == 8) 
	{
		if ((GetEntityFlags(client) & FL_ONFIRE) && fSlowdownTankLit > 0.0)
			return fSlowdownTankLit;
			
		if (fSlowdownTank > 0.0)
			return fSlowdownTank;
	}
	else 
	{	
		if (fSlowdownSi > 0.0)
			return fSlowdownSi;
	}
	
	return -1.0;
}

public CvarChanged(Handle:cvar, const String:oldValue[], const String:newValue[]) {
	UpdateCvars();
}