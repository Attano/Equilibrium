#include <sourcemod>
#include <sdktools>
#include <left4downtown>

#define FINALE_STAGE_TANK 8

public Plugin:myinfo =
{
    name = "EQ2 Finale Tank Manager",
    author = "Stabby, Visor",
    description = "Blocks all event tanks but the first two.",
    version = "1337",
    url = "https://github.com/Attano/Equilibrium"
};

new iTankCount[2];

public OnMapEnd() 
{
    iTankCount[0] = 0;
    iTankCount[1] = 0;
}

public Action:L4D2_OnChangeFinaleStage(&finaleType, const String:arg[]) 
{
    if (finaleType == FINALE_STAGE_TANK) 
    {
        if (iTankCount[GameRules_GetProp("m_bInSecondHalfOfRound")] >= 2)
            return Plugin_Handled;

        iTankCount[GameRules_GetProp("m_bInSecondHalfOfRound")]++;
    }
    
    return Plugin_Continue;
}