#include <sourcemod>
#include <sdktools>

#define SCOUT_W_MODEL       "models/w_models/weapons/w_sniper_scout.mdl"
#define SCOUT_V_MODEL       "models/v_models/v_snip_scout.mdl"
#define SCOUT_WEAPON_NAME   "weapon_sniper_scout"

public Plugin:myinfo =
{
    name        = "L4D2 Scout Precache",
    author      = "Visor",
    version     = "1.0",
    description = "Precaches the Scout, rendering it available for manipulations"
};

public OnMapStart() 
{
    PrecacheModel(SCOUT_W_MODEL);
    PrecacheModel(SCOUT_V_MODEL);
    
    new index = CreateEntityByName(SCOUT_WEAPON_NAME);
    DispatchSpawn(index);
    RemoveEdict(index);
}