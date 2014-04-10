#include <sourcemod>
#include <left4downtown>

// TODO LIST:
//
// - Need to confirm that events trigger as they should, regarding Car Alarms.
//
new CarAlarmActive;

new Handle:WhiteListedMapsTrie;

public Plugin:myinfo = 
{
    name = "Horde Manager",
    author = "Sir",
    description = "Become a master of the horde",
    version = "1.0",
    url = "<- URL ->"
}

public OnPluginStart()
{
    WhiteListedMapsTrie = WhitelistedMaps();
    
    HookEvent("triggered_car_alarm", Event_CarHorde);
    HookEvent("panic_event_finished", Event_CarHordeStop);
    
    HookEvent("round_start", Event_RoundStart);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (CarAlarmActive != 0) CarAlarmActive = 0;
}

public Action:Event_CarHorde(Handle:event, const String:name[], bool:dontBroadcast)
{
    CarAlarmActive++;
}

public Action:Event_CarHordeStop(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (CarAlarmActive > 0) CarAlarmActive--;
    if (CarAlarmActive < 0) CarAlarmActive = 0;
}

public Action:L4D_OnSpawnMob(&amount)
{
    /////////////////////////////////////
    // - Called on Event Hordes.
    // - Called on Panic Event Hordes.
    // - Called on Natural Hordes.
    // - Called on Onslaught (Mini-finale or finale Scripts)
    
    // - Not Called on Boomer Hordes.
    // - Not Called on z_spawn mob.
    ////////////////////////////////////
    
    // Is Tank Alive and are no Car Alarms triggered?
    if (TankUp() && CarAlarmActive == 0)
    {
        //Check if Map is Whitelisted.
        new String:Map[64];
        new bool:WhiteListMap = false;
        GetCurrentMap(Map, sizeof(Map));
        
        GetTrieValue(WhiteListedMapsTrie, Map, WhiteListMap);
        
        //If Map is not Whitelisted, Deny Horde Spawn.
        if (!WhiteListMap) return Plugin_Handled;
    }
    //Horde Spawn allowed
    return Plugin_Continue;
}

bool:TankUp()
{
    for (new t = 1; t <= MaxClients; t++)
    {
        if (!IsClientInGame(t) 
            || GetClientTeam(t) != 3 
        || !IsPlayerAlive(t) 
        || GetEntProp(t, Prop_Send, "m_zombieClass") != 8)
        continue;
        
        return true; // Found tank, return
    }
    return false;
}

Handle:WhitelistedMaps()
{
    new Handle: trie = CreateTrie();
    
    //Normal Maps
    SetTrieValue(trie, "c10m2_drainage", true);
    SetTrieValue(trie, "c9m1_alleys", true);
    SetTrieValue(trie, "c2m4_barns", true); // Fixes Horde not Spawning during the Event while Tank is up.
    
    //Finales
    SetTrieValue(trie, "c1m4_atrium", true);
    SetTrieValue(trie, "c2m5_concert", true);
    SetTrieValue(trie, "c3m4_plantation", true);
    SetTrieValue(trie, "c4m5_milltown_escape", true);
    SetTrieValue(trie, "c5m5_bridge", true);
    SetTrieValue(trie, "c6m3_port", true);
    SetTrieValue(trie, "c7m3_port", true);
    SetTrieValue(trie, "c8m5_rooftop", true);
    SetTrieValue(trie, "c9m2_lots", true);
    SetTrieValue(trie, "c10m5_houseboat", true);
    SetTrieValue(trie, "c11m5_runway", true);
    SetTrieValue(trie, "c12m5_cornfield", true);
    SetTrieValue(trie, "c13m4_cutthroatcreek", true);
    
    return trie;  
}