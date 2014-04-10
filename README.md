#![EQ](http://31.186.250.11/tmp/eq.png)
**Equilibrium** is a competitive configuration for Left 4 Dead 2 which was initiated as a major revolutionary step after *Confogl Fresh*. Its intention is to provide competitive yet challenging play, where play-facilitating mechanics which existed in Confogl Fresh(and still exist in Pro Mod) are no longer present. Thus there is a greater requirement to use better input and tactical thought in order to succeed in EQ, reinforcing the viewpoint that teams and players should be tested thoroughly in their skill and teamwork, and made to earn their points and victories in a truly 'competitive' sense.

###[ Info ]
**Current version:**      2.1  
**EQ2.x Developer:**      ![RO](http://31.186.250.11/tmp/ro_flag.png) Visor   
**Pre-EQ2.0 Developer:**  ![UK](http://31.186.250.11/tmp/uk_flag.png) Jahze (inactive) [ [legacy repo](http://github.com/Jahze/Equilibrium) / [legacy changelog](http://github.com/Jahze/Equilibrium/blob/master/CHANGELOG.txt) ]  
**Ideas:**                Jahze, ![UK](http://31.186.250.11/tmp/uk_flag.png) Dragon, Visor, ![UK](http://31.186.250.11/tmp/uk_flag.png) Battle  
**EQ Plugins:**           Visor, Jahze, ![NL](http://31.186.250.11/tmp/nl_flag.png) Sir  
**Base plugins:**         CanadaRox, ProdigySim, Tabun, Vintik, Stabby, Blade, CircleSquared, Jacob, Grego, purpletreefactory, epilimic, Arti, Raecher, Xan, Griffin  
**Stripper:**             Tabun, NF, EsToOpi, Jacob, Blade, Stabby, CircleSquared

###[ Changelog ]

####April 10, 2014

#####Major release: Equilibrium 2.1
######*This release has been tested and is 100% compatible with ProMod 3.6*

> **4v4 EQ 2.1**

> - Refined the scoring system. Health Bonus will now depend on the number of Survivors alive, same as Damage Bonus.
> - Updated the **!bonus** command (mirrors: *!health*, *!damage*)

>Command | 1st Round Output | 2nd Round Output  
>--- | ---  | ---  
>!bonus | [EQSM :: R#1] Bonus: 556 &lt;69.5%&gt; [HB: 73% I DB: 58%] | [EQSM :: R#1] Bonus: 420 &lt;52.5%&gt;<br/>[EQSM :: R#2] Bonus: 556 &lt;69.5%&gt; [HB: 73% I DB: 58%]  
>!bonus full | [EQSM :: R#1] Bonus: 556 &lt;69.5%> [HB: 439 &lt;73.1%> I DB: 117 &lt;58.5%&gt;] | [EQSM :: R#1] Bonus: 420/800 &lt;52.5%&gt; [4/4]<br/>[EQSM :: R#2] Bonus: 556 &lt;69.5%&gt; [HB: 439 &lt;73.1%&gt; I DB: 117 &lt;58.5%&gt;]  
>!bonus lite | [EQSM :: R#1] Bonus: 556 &lt;69.5%&gt; | *Same as 1st round*  

> - Jockeys can now be skeeted with shotguns. The blast must inflict no less than 60% damage out of the Jockey's total health. This value constitutes **195 HP**.
> - Fixed survivor M2 functionality against hunters. The chance of a deadstop has now been completely eliminated. Also M2 will function properly on hunters who have capped survivors.
> - Silent Hunter wallkicks are now blocked.
> - Removed melee weapons limit per team.
> - Charger scratches will now deal only 6 dmg to capped victims.
> - Equalized spitter damage and acid lifetime.
> - Increased godframes for all SI classes by **0.1s**.
> - Fixed second team having different SI spawns on round start.
> - Mapinfo tweaked: a couple of custom distance/bonus edits.
> - Replaced `Survivor MVP` with the new `L4D2 Play Stats`.
> - Per numerous requests, replaced audial bacteria sounds for initial spawns with chat prints.
> - Player becoming the Tank will not have his SI bot killed if he managed to cap someone.
> - Fixed the bug where Jockey and Charger would sometimes ride/carry the same Survivor at the same time.
> - If a Tank kills a Witch she will respawn in the same spot shortly after.
> - Added plugins related to various modern features and bugfixes, which are present in Pro Mod but weren't present in EQ2.0
> - Added the `Hyper-V HUD Manager`. It will provide different, better Spec & Tank HUDs.
> - Replaced `L4D2 Spitter Manager` with `L4D2 No Spitter During Tank` due to the former's buggy nature.
> - Updated `Caster Addons` plugin to function properly after map transitions.
> - Reworked `L4D2 Drop Secondary` plugin, removed error spam and made it more reliable.
> - Removed the deprecated `Boss Spawns Equalizer`
> - Removed the deprecated `L4D2 Logger`.
> - Removed useless VScripts for L4D1 maps. 

> **3v3 EQ 2.1**  
> *All 4v4 changes, except:*

> - Only Hunters, Smokers, Jockeys and Chargers
> - Maximum of 1 SMG / 1 Scout / 1 Deagle per team
> - Tanks that go AI are slayed instantly
> - Distance points freeze upon Tank / Witch spawning. This is to discourage rushing.
> - Survivors who managed to chip their attacker before getting capped will now be able to see how much damage they've managed to inflict.

> **2v2 EQ 2.1**  
> *All 4v4 and 3v3 changes, except:*

> - Only Hunters, Jockeys and Chargers

> **1v1 EQ 2.1**

> - Only Hunters and Jockeys
> - A successful cap deals 24 dmg
> - **Scout** spawns are encountered much more often, as opposed to 4v4/3v3/2v2
> - Damage reporter will also print the attacker's SI class
> - Removed Promod taunts, with the exception of one

> **EQ Retro 2.1**

> - Limit of hunters has been increased from 3 to 4
> - Spawn intervals have been increased from 16 to 18 seconds
> - Fixed some custom campaigns having usable static melee spawns. Now any encountered melees will be blocked from being picked up.

> New config: **JaegerMod**

> - Core used: hybrid between **ProMod 3.5.4/3.6** and **EQ 2.0/2.1**
> - EQ2.1 Scoring System
> - EQ2.1 Stripper map changes
> - 5 M2s
> - Jockey replaced with a second Hunter
> - Quadcaps possible
> - Tank hittables deal only 48 dmg
> - Completely removed deadstops on Hunters
> - Blocked Hunter wallkicks
> - Completely removed Spitter godframes
> - Lowered the Survivor immunity time against fresh spit(technically not part of the godframe system)
> - The Spitter now deals 48 dmg per spit / 8 per second
> - Tweaked Charger punches to inflict only 6 dmg to capped victims. Punches to non-restrained Survivors still deal 10 dmg.
> - Witches removed completely
> - No Scout
> - No Holdout/Witch bonuses
> - No Tank slowdown
> - Max of 2 SMG per team
> - No melee limit
> - No intro Tanks on finales
> - Completely removed friendly staggers among SI. Boomer pops and Charger wall impacts in close proximity to other SI will not stumble them nor their capped victims.
> - Tank can't kill other SI or inflict any kind of damage to them
> - SI can use **!kill** or **!suicide** to commit a suicide. This function is unavailable to SI in range of Survivor visibility, as well as SI with capped targets.
> - Pills take effect instantly
> - Chipped cappers will report back to their victims of the damage they've managed to inflict
> - Blocked BunnyHop for Survivors and all SI
> - Fixed `L4D2 Hittable Control` to properly detect hittable alarmed cars

> **Major repositorium overhaul**

> - Repo has been restructured to respect Valve/Sourcemod canonic standards
> - Regular text changelog replaced with a git Markdown readme
> - Readme now contains much more information

####October 16, 2013

> **Warcelona Modifications**

> Plaza Espana (Map 2)
> - Added an Ammo Spawn after the Barricade.
> - Fixed Dynamic Pathing at the end Saferoom (Fencing)

> Mnac (Map 4/Finale)
> - Fixed Weapon Spawns in the Saferoom, all 3 weapons are available.
> - Fixed Dynamic Pathing, set a static route.

> *For the Stripper:Source pros, I'm aware the method I used is sloppy, laziness at its best :) ~Sir*

####October 14, 2013

> **EQ #2 CUP - WEEK 2 FINAL RELEASE**

> - Added EQ Retro 2.0 config
> - Left4Downtown2 updated with new stuff (v0.5.7)
> - Brought back the manageable Addons Disabler. Casters can stream with HUDs once again. Added the corresponding plugin into the config (L4DT2 v0.5.7 is a dependency)
> - Removed hunter deadstops once and for all (L4DT2 v0.5.7 is a dependency)
> - Updated the Scoremod. Now it shows HB/DB separately. Plus added a new command: !mapinfo
> - Restored the old Bot Pop Stop. The new one was causing issues.

####October 6, 2013

> **EQ #2 CUP - WEEK 1 FINAL RELEASE**

> - Updated all Customogl files
> - Added a fix for the Warcelona Survivor death issue
> - Removed static shotgun spread (has some critical issues atm)
> - Updated the Tank slowdown modifier

####October 3, 2013

> **NOTE:** *Warcelona campaign issues fixes and Global Boss Coordinates Equalizer are still work in progress. Check later for updates.*  
> **NOTE:** *3v3 and 2v2 configs are still being worked on. Please do not install them, for now.*

> - Fixed identation issues in all files
> - Added missing l4d2_spitter_manager
> - Added static shotgun spread into the config, with its files and the updated Left4Downtown2 extension. It is NOT the same as the one in Jahze's repo, so update it! It is required for water slowdown and stagger fix plugins.  

>Shotgun type | Pellets | Damage | Scatter  
>--- | --- | --- | ---
>Chrome | 15 | 17 | 3.0
>Pump* | 17 | 15 | 3.5  
>*Pump shotgun is less accurate than chrome*
> - Slowdown Control plugin has been revised. Now it's using EQ2.0's custom Left4Downtown2 extension as a dependency to handle water slowdown for the Survivors and the Tank. Confogl's own slowdown is turned off, since the new function is much less consuming on higher tickrates.
> - Added a plugin to remove friendly charger staggers. No more ruined caps!
> - Added a plugin to remove hunter deadstops. Ground hunters can still be shoved though.
> - Improved the Tank Lottery algorithm. Now substitutes will be placed at the back of the tank lottery queue. This way, players that have joined the game earlier will remain 100% eligible for becoming a tank.
> - All finales now have only two event tanks. Distance-based tanks, as well as those that accompany the rescue vehicles, will be blocked.
> - Added an improved Bot Pop Stop plugin. It relies on the latest Left4Downtown2 extension. Instead of taking the pills away from bots, it blocks them from using them altogether.
> - Revised, fixed and improved the EQ2 Scoremod system.

####September 13, 2013

> **Bringing stuff up to speed(*main 4v4 cfg only - for now*)**

> - Completely reorganized the cvars. Native and SM cvars should not be mixed, unless it is vital for a better perception.
> - Replaced l4d2_nospitterduringtank with l4d2_spitter_manager
> - Added Texture Manager Blocker plugin
> - Replaced l4d2_si_slowdown with l4d2_slowdown_control. Also more intuitive cvars.
> - Added an optimized version of Riot Cop Headshot plugin
> - Moved the witch enrage/FF-related code from l4d_witch_damage_announce into l4d2_si_ffblock
> - Added the Drop Secondary plugin. Dead Survivors drop their melee weapons.
> - Added the Tank Pain Fade plugin. Red screen fades for Tanks getting melee owned from behind.
> - Added the Undo Survivor Friendly-Fire plugin. Removed a ton of unrelated stuff, still looks like a mess. But works.
> - Added the Scout Precache plugin. Weapon Limits will handle what was once done by l4d_sniper.
> - Added the Weapon Attributes plugin for some Scout tweaks.
> - Replaced Scoremod with EQ2.0 Scoremod. Details on the forums.
> - Added melee limits. 3 per team will stay as the default value for EQ2.0 4v4 for now.
> - Added the Starting Bacteria plugin. First set of spawns for each team will be vocalized via the oldschool "bacteria" sounds. Only Survivors are able to hear them though.

> **Stripper**

> - Added the latest set of map changes from ProMod/Customogl 3.3.3.
> - Removed inaccessible pills in a room next to the panic event on DK4.
> - Blocked elevator walls on HR2-3. SI can no longer scratch through them.

####September 6, 2013

> **Quick update**

> - Replaced witch_damage_announce with l4d_witch_damage_announce (Added Source+SMX)
> - Added Modified Unsilent Jockey.
> - Added Modified Spec Stays Spec

####September 5, 2013  
> **Initial commit**

> - 2v2,3v3,4v4 Config Basics prepared.
> - EQ 2.0 "Start-up" Plugins uploaded along with Source.
> - Stripper Files: Finished (for now)

> **Update**

> - Added this Changelog.txt
> - Added PlannedFeatures.txt
> - Added Missing source+plugin for l4d2_melee_fix
> - Added Missing Gamedata for Notankautoaim
> - Removed useless Plugin (Already!)