DirectorOptions <-
{
// This turns off tanks and witches.
ProhibitBosses = true

//LockTempo = true
MobSpawnMinTime = 5
MobSpawnMaxTime = 5
MobMinSize = 10
MobMaxSize = 10
MobMaxPending = 13
SustainPeakMinTime = 2
SustainPeakMaxTime = 2
IntensityRelaxThreshold = 0.90
RelaxMinInterval = 3
RelaxMaxInterval = 3
RelaxMaxFlowTravel = 150
SpecialRespawnInterval = 1.0
PreferredMobDirection = SPAWN_IN_FRONT_OF_SURVIVORS
ZombieSpawnRange = 2000
}

Director.ResetMobTimer()
Director.PlayMegaMobWarningSounds()