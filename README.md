![GitHub Logo](/bw-assets/bw-logo.png)

# IW5 Bot Warfare XTended
Bot Warfare XTended is an unofficial build of [Bot Warfare](https://github.com/ineedbots/iw5_bot_warfare) 2.3.0 by INeedGames for the [PlutoniumIW5 project](https://plutonium.pw/). It keeps everything Bot Warfare does and makes the bots play and talk more like people.

## Contents
- [Features](#features)
- [Installation](#installation)
- [Documentation](#documentation)
- [Known limitations](#known-limitations)
- [Changelog](#changelog)
- [Credits](#credits)

## Features
- A Waypoint Editor for creating and modifying bot's waypoints of traversing the map. Have a look at [Using the Waypoint editor](/bw-assets/wpedit.md).

- A clean and nice menu, you can edit every bot DVAR within in-game.

- Everything can be customized, ideal for both personal use and dedicated servers. Have a look at [Documentation](#documentation) to see whats possible!

- This mod does not edit ANY stock .gsc files, meaning EVERY other mod is compatible with this mod. Mod doesn't add anything unnecessary, what you see is what you get.

- Adds AI clients to multiplayer games to simulate playing real players. (essentially Combat Training for MW3)
  - Bots move around the maps with native engine input. (all normal maps, most to all custom maps)
  - Bots press all the buttons with native engine input (ads, sprint, jump, etc)
  - Bots play all gamemodes/objectives, they capture flags, plant, defuse bombs, etc. (all gamemodes modes)
  - Bots use all killstreaks. Including AC130 and osprey gunner, etc.
  - Bots target killstreaks, use stingers and other weapons to take out all killstreaks. (even sentry guns)
  - Bots can capture and steal care packages.
  - Bots target equipment, and can even camp TIs.
  - Bots can camp randomly or when about to use the laptop.
  - Bots can follow others on own will.
  - Bots have smooth and realistic aim.
  - Bots respond smartly to their surroundings, they will go to you if you shoot, uav, etc.
  - Bots use all deathstreaks, perks and weapons. (including javelin)
  - Bots difficulty level can be customized and are accurate. (hard is hard, easy is easy, etc.)
  - Bots each all have different classes, traits, and difficulty and remember it all.
  - Bots switch from between primaries and secondaries.
  - Bots can grenade, place claymores and TIs, they even use grenades and tubes in preset map locations.
  - Bots use grenade launchers and shotgun attachments.
  - Bots can melee people and sentry guns.
  - Bots can run!
  - Bots can climb ladders!
  - Bots jump shot and drop shot.
  - Bots detect smoke grenades, stun grenades, flashed and airstrike slows.
  - Bots will remember their class, killstreak, skill and traits, even on multiround based gametypes.
  - Bots can throwback grenades.
  - ... And pretty much everything you expect a Combat Training bot to have

- XTended adds:
  - Bots have personalities (rusher, balanced, cautious, support) that shape how they play and which guns they pick.
  - Bots aim like humans: they overshoot, flinch when hit and aim worse on the move.
  - Bots hear gunfire and explosions, retreat when hurt, hide from air killstreaks and check corners.
  - Bots get cocky after 3 kills in a row and tilted after 3 deaths.
  - Bots counter-pick classes, hold grudges, avenge teammates and learn your camping spots.
  - Bots call out enemies, use voice callouts, play in parties and react to the score and to being last alive.
  - Bots make mistakes: slow turns when surprised, panic spraying, badly timed reloads.
  - Optional adaptive difficulty that keeps you near a target K/D.
  - Bots chat as millennials, zoomers, Gen Alpha or boomers. They rage, bait, talk to each other, react to special kills and reply to you, without flooding the chat.
  - 300 bot names, presets (casual, competitive, chaos, off) and a commented settings file.
  - A new menu look with Realism and Social tabs.
  - Fixes for several bugs in the original bot code.

## Installation
0. Make sure that [PlutoniumIW5](https://plutonium.pw/docs/install/#iw5) is installed, updated and working properly.
1. Extract `BotWarfareXTended-1.0.zip` anywhere on your computer.
2. Run `install.bat`. This copies the mod, `bots.txt` and `xtended.cfg` to your PlutoniumIW5 storage folder (existing `bots.txt` and `xtended.cfg` are kept).
3. Start a map and play! Installing replaces an existing Bot Warfare install.

On Linux, copy the files into `drive_c/users/<you>/AppData/Local/Plutonium/storage/iw5/` in your Wine prefix. To build the zip yourself, run `python ci/build_release.py`.

## Documentation

### Menu Usage
- You can open the menu by pressing the Action Slot 1 key (default 'N', nightvision key).

- You can navigate the options by pressing your movement keys (default WASD), and you can select options by pressing your jump key (default SPACE).

- Pressing the menu button again closes menus.

- The **Realism** and **Social** tabs toggle every XTended feature. **Show bot status** lists what each bot is and what it's doing.

### Presets and settings file
- `bots_real_preset` sets many options at once: `casual`, `competitive`, `chaos`, `off`, or `custom` (set things yourself).
- `xtended.cfg` lists every setting with a comment. Edit it, then type `exec xtended.cfg` in the console.

### DVARs
| Dvar                             | Description                                                                                 | Default Value |
|----------------------------------|---------------------------------------------------------------------------------------------|--------------:|
| bots_main                        | Enable this mod.                                                                            | 1             |
| bots_main_firstIsHost            | The first player to connect will be given host.                                             | 0             |
| bots_main_GUIDs                  | A comma separated list of GUIDs of players who will be given host.                          |               |
| bots_main_waitForHostTime        | How many seconds to wait for the host player to connect before adding bots to the match.    | 10            |
| bots_main_menu                   | Enable the in-game menu for hosts.                                                          | 1             |
| bots_main_debug                  | Enable the in-game waypoint editor at start of the game, or enable bot event prints. <ul><li>`0` - disable</li><li>`1` - for just debug events</li><li>`2` - for every event</li><ul> | 0 |
| bots_main_kickBotsAtEnd          | Kick the bots at the end of a match.                                                        | 0             |
| bots_main_chat                   | The rate bots will chat at, set to 0 to disable.                                            | 1.0           |
| bots_manage_add                  | Amount of bots to add to the game, once bots are added, resets back to `0`.                 | 0             |
| bots_manage_fill                 | Amount of players/bots (look at `bots_manage_fill_mode`) to maintain in the match.          | 0             |
| bots_manage_fill_mode            | `bots_manage_fill` players/bots counting method.<ul><li>`0` - counts both players and bots.</li><li>`1` - only counts bots.</li><li>`2` - exactly `0` but auto adjusts `bots_manage_fill` to map.</li><li>`3` - exactly `1` but auto adjusts `bots_manage_fill` to map.</li><li>`4` - bots are used for balancing teams.</li><li>`5` - exactly `4` but auto adjusts `bots_manage_fill` to map.</li></ul> | 0 |
| bots_manage_fill_watchplayers    | Bots will not be added until one player is in the game                                      | 0             |
| bots_manage_fill_kick            | If the amount of players/bots in the match exceeds `bots_manage_fill`, kick bots until no longer exceeds. | 0 |
| bots_manage_fill_spec            | If when counting players for `bots_manage_fill` should include spectators.                  | 1             |
| bots_team                        | One of `autoassign`, `allies`, `axis`, `spectator`, or `custom`. What team the bots should be on. | autoassign |
| bots_team_amount                 | When `bots_team` is set to `custom`. The amount of bots to be placed on the axis team. The remainder will be placed on the allies team. | 0 |
| bots_team_force                  | If the server should force bots' teams according to the `bots_team` value. When `bots_team` is `autoassign`, unbalanced teams will be balanced. This dvar is ignored when `bots_team` is `custom`. | 0 |
| bots_team_mode                   | When `bots_team_force` is `1` and `bots_team` is `autoassign`, players/bots counting method. <ul><li>`0` - counts both players and bots.</li><li>`1` - only counts bots</li></ul> | 0 |
| bots_skill                       | Bots' difficulty.<ul><li>`0` - Random difficulty for each bot.</li><li>`1` - Easiest difficulty for all bots.</li><li>`2` to `6` - Between easy and hard difficulty for all bots.</li><li>`7` - The hardest difficulty for all bots.</li><li>`8` - custom (look at the `bots_skill_<team>_<difficulty>` dvars)</li><li>`9` - Every difficulty parameter is randomized</li></ul> | 0 |
| bots_skill_axis_hard             | When `bots_skill` is set to `8`, the amount of hard difficulty bots to set on the axis team. | 0            |
| bots_skill_axis_med              | When `bots_skill` is set to `8`, the amount of medium difficulty bots to set on the axis team. The remaining bots on the team will be set to easy difficulty. | 0 |
| bots_skill_allies_hard           | When `bots_skill` is set to `8`, the amount of hard difficulty bots to set on the allies team. | 0          |
| bots_skill_allies_med            | When `bots_skill` is set to `8`, the amount of medium difficulty bots to set on the allies team. The remaining bots on the team will be set to easy difficulty. | 0 |
| bots_skill_min                   | The minimum difficulty level for the bots.                                                     | 1          |
| bots_skill_max                   | The maximum difficulty level for the bots.                                                     | 7          |
| bots_loadout_reasonable          | If the bots should filter bad performing create-a-class selections.                            | 0          |
| bots_loadout_allow_op            | If the bots should be able to use overpowered and annoying create-a-class selections.          | 1          |
| bots_loadout_rank                | What rank to set the bots.<ul><li>`-1` - Average of all players in the match.</li><li>`0` - All random.</li><li>`1` or higher - Sets the bots' rank to this.</li></ul> | -1 |
| bots_loadout_prestige            | What prestige to set the bots.<ul><li>`-1` - Same as host player in the match.</li><li>`-2` - All random.</li><li>`0` or higher - Sets the bots' prestige to this.</li></ul> | -1 |
| bots_play_move                   | If the bots can move.                                                                          | 1          |
| bots_play_knife                  | If the bots can knife.                                                                         | 1          |
| bots_play_fire                   | If the bots can fire.                                                                          | 1          |
| bots_play_nade                   | If the bots can grenade.                                                                       | 1          |
| bots_play_take_carepackages      | If the bots can take carepackages.                                                             | 1          |
| bots_play_obj                    | If the bots can play the objective.                                                            | 1          |
| bots_play_camp                   | If the bots can camp.                                                                          | 1          |
| bots_play_jumpdrop               | If the bots can jump/drop shot.                                                                | 1          |
| bots_play_target_other           | If the bots can target other entities other than players.                                      | 1          |
| bots_play_killstreak             | If the bots can call in killstreaks.                                                           | 1          |
| bots_play_ads                    | If the bots can aim down sights.                                                               | 1          |
| bots_play_aim                    | If the bots can aim.                                                                           | 1          |
| bots_real_traits                 | Bots get a personality (rusher, balanced, cautious, support) that shapes how they play and which guns and killstreaks they pick. Loadouts are picked when a bot joins, so re-add bots after changing this. | 1 |
| bots_real_aim                    | Bots aim like humans: they overshoot new targets, flinch when hit and aim worse while moving.  | 1          |
| bots_real_hearing                | Bots react to gunfire and explosions they hear (suppressors cut the range).                    | 1          |
| bots_real_retreat                | Bots fall back to cover when badly hurt, then heal and reload before re-engaging.              | 1          |
| bots_real_counter                | Bots switch to a counter class after dying repeatedly to the same thing (air, explosives, UAV, snipers, rushers). Needs custom classes (bot rank 4+). | 1 |
| bots_real_mood                   | Bots get cocky after 3 kills in a row and tilted after 3 deaths in a row, which changes how they play. | 1          |
| bots_real_airhide                | Bots take cover under a roof when enemy air killstreaks are up, unless they carry a launcher.  | 1          |
| bots_real_grudge                 | Bots hold a grudge against a player who kills them 3 times and go hunting for them.            | 1          |
| bots_real_hotspots               | Bots learn spots players keep getting kills from, then pre-aim them, nade them or path around them. | 1          |
| bots_real_teamintel              | Bots tell nearby bot teammates where they spotted an enemy; teammates look over or move up.    | 1          |
| bots_real_matchaware             | Bots push when losing late, play safe when winning late, and play slow when last alive in S&D. | 1          |
| bots_real_slipups                | Bots make human mistakes: slow turns when shot from behind, panic spraying, reloading right after kills. | 1          |
| bots_real_chat                   | Bots take time to type, chat in their own style (lowercase, dropped full stops, the odd typo) and reply to players. | 1          |
| bots_real_voice                  | Bots use voice callouts that match what they're doing (enemy spotted, need reinforcements, fall back, follow me, suppressing fire). Team modes only. | 1          |
| bots_real_avenge                 | Bots go after whoever killed a teammate near them.                                             | 1          |
| bots_real_adaptive               | Enemy bots adjust their skill (up to 3 steps either way) to keep human players near `bots_real_adaptive_kd`. Checked every 30 seconds. | 0          |
| bots_real_adaptive_kd            | The K/D adaptive difficulty aims to keep human players at.                                     | 1.2        |
| bots_real_banter                 | Bots talk to each other, react to special kills (knife, headshot, long shot, multikill...), say "you again" and praise the human MVP. | 1          |
| bots_real_parties                | Some bots group up in parties of 2-3 on the same team that follow, avenge and cheer each other. | 1          |
| bots_real_churn                  | Deeply tilted bots sometimes rage quit and a new bot joins later; a bot sometimes leaves at the end of a match. | 1          |
| bots_real_preaim                 | Bots glance at corners and long sightlines while moving.                                       | 1          |
| bots_real_turrets                | Bots stay and fight on mounted turrets instead of hopping off, and sometimes walk over to a free one. | 1          |
| bots_real_rage                   | Percent of a tilted bot's death messages that are rage.                                        | 50         |
| bots_real_bait                   | Percent chance a bot taunts a human player it kills (cocky bots add 25).                       | 30         |
| bots_real_mood_streak            | Kills or deaths in a row before a bot gets cocky or tilted (at least 2).                       | 3          |
| bots_real_preset                 | Applies a group of settings: `off`, `casual`, `competitive`, `chaos`, or `custom` to set things yourself. | custom     |

## Known limitations
- Only tested on Linux (Plutonium under Wine/Proton), not yet on Windows.
- Leaving bots are kicked with `EXE_DISCONNECTED`, which may show as raw text.
- The Plutonium adapter has no file access, so waypoint `.csv` files aren't loaded or saved.
- Mounted turrets are rare on standard MW3 maps.

## Changelog
- XTended 1.0 (based on v2.3.0)
  - Added personalities, human aim, hearing, retreating, moods, counter-picking, hiding from air support, grudges, camping spot memory, team intel, match awareness, slip-ups, avenging, voice callouts, pre-aiming, parties, lobby churn, turret use and adaptive difficulty
  - Added chat generations, raging, baiting, bot-to-bot banter, special-kill lines and replies to players
  - Bot chat is rate limited, bots take time to type, dated chat lines refreshed
  - Added 300 bot names, presets and `xtended.cfg`
  - New menu look with Realism and Social tabs
  - Fixed bots giving up on objectives, crates and turrets over a match
  - Fixed teammates never being alerted when a bot gets shot
  - Fixed thermal scopes letting bots target turrets and equipment through walls
  - Fixed specialist killstreak perk selection
  - Fixed Domination bots heading for flags their team owns
  - Fixed the last bots alive in S&D not playing the objective
  - Damaged waypoint files fall back to the built-in waypoints

- v2.3.0
  - Fixed bots aiming in ac130/chopper being broken at times
  - Bots properly use pred missiles
  - Smoothed bot aim at range
  - Fixed bots_manage_fill_spec players being counted with bots_manage_fill_mode 1 (bot only)
  - Added bots_manage_fill_watchplayers dvar
  - Bots hop off turrets if they get stuck on one
  - Fixed script variable leak with opening and closing the in-game menu

- v2.2.0
  - Bots can now melee lunge
  - Fixed some chat related script runtime errors
  - Fix bots possibly being stuck in sab
  - Major cleanup

- v2.1.0
  - Initial release (sync'd versions with other Bot Warfares)

## Credits
XTended is built on Bot Warfare by INeedGames.

- Plutonium Team - https://plutonium.pw/
- CoD4x Team - https://github.com/callofduty4x/CoD4x_Server
- INeedGames - http://www.moddb.com/mods/bot-warfare
- tinkie101 - https://web.archive.org/web/20120326060712/http://alteriw.net/viewtopic.php?f=72&t=4869
- PeZBot team - http://www.moddb.com/mods/pezbot
- apdonato - https://web.archive.org/web/20240516065610/http://rsebots.blogspot.com/
- Ability
- Salvation
- Xensik - https://github.com/xensik/gsc-tool

### Waypoint Creators
- FragsAreUs - https://github.com/FragsAreUs
- Aesirix - https://github.com/Aesirix
- EpikIzCool - https://github.com/super23
- doa3 - https://github.com/doa3
- ghostwulf - https://github.com/ghostwulf
- LeRutY - https://github.com/LeRutY
- GaryTheNoTrashCougar - https://github.com/GaryTheNoTrashCougar

Feel free to use code, host on other sites, host on servers, mod it and merge mods with it, just give credit where credit is due!
	-INeedGames/INeedBot(s) @ ineedbots@outlook.com
