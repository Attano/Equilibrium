#include <sourcemod>
#include <left4downtown>

/** 
    Requires at least L4DT2 v0.5.6 to work 
    Get the binary from https://github.com/Attano/Left4Downtown2 
**/

public Plugin:myinfo = 
{
    name = "Advanced Bot Pop Stop",
    author = "Visor",
    description = "Blocks any healing items from being used by bots. They can still pick them up.",
    version = "2.0",
    url = "https://github.com/Attano/Equilibrium"
};

/* 
This is a detour of SurvivorBot::UseHealingItems(Action<SurvivorBot> *), thus it only triggers for bots
'L4D2_OnBotUseHealingItems' would have been a more appropriate name for it, but for compatibility's sake I'll leave it as it is 
*/
public Action:L4D2_OnUseHealingItems(client)
{
    // No connection nor fake client checks are required
    return Plugin_Handled;
}