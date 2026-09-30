==============================================================
   BOT WARFARE XTENDED 1.0  -  for PlutoniumIW5 (MW3)
==============================================================
Bot Warfare XTended adds playable AI to Modern Warfare 3 multiplayer,
with bots that play more like people: personalities, moods, grudges,
human aim, hearing, teamwork and the occasional mistake.

XTended is an unofficial build on top of Bot Warfare 2.3.0 by INeedGames.
The original project is at https://github.com/ineedbots/iw5_bot_warfare

## Installation
0. Make sure that PlutoniumIW5 is installed, updated and working properly.
1. Extract all the files from this archive to anywhere on your computer.
2. Run 'install.bat'. This copies z_svr_bots.iwd to %LOCALAPPDATA%\Plutonium\storage\iw5\
   If you already had Bot Warfare installed, this replaces it (same file name).
3. Start PlutoniumIW5 and load a map. You'll get a "Welcome to Bot Warfare XTended" message,
   and the menu's footer shows "Bot Warfare XTended 1.0".

To uninstall, delete z_svr_bots.iwd from %LOCALAPPDATA%\Plutonium\storage\iw5\
To go back to the official version, install the official release again.

## Menu Usage
- Open the menu with the Action Slot 1 key (default 'N', nightvision key).
- Navigate with your movement keys (default WASD), select with your jump key (default SPACE).
- Pressing the menu button again closes menus.
- The "Realism" tab has a Preset selector and the behaviour toggles, the "Social" tab
  has the chat and social toggles.

## Realism features
Each one is on by default and has its own dvar (1 = on, 0 = off):
- bots_real_traits  - Bots get a personality: rusher, balanced, cautious or support.
                      It shapes how they move and fight, and which guns they pick:
                      rushers favor SMGs and shotguns, cautious bots snipers and ARs,
                      support bots LMGs and ARs (and usually support killstreaks).
                      Loadouts are chosen when a bot joins, so re-add bots after toggling.
- bots_real_aim     - Bots overshoot new targets, flinch when hit, and aim worse while moving or after sprinting.
- bots_real_hearing - Bots react to gunfire and explosions they hear. Suppressors cut the range.
- bots_real_retreat - Bots fall back to cover when badly hurt, then heal and reload.
- bots_real_counter - After dying repeatedly to the same thing, bots switch to a counter class
                      on their next spawn: Blind Eye and a launcher vs air support, Sitrep and
                      Blast Shield vs explosives, Assassin vs UAVs, and a different gun vs snipers
                      or rushers. Bots need rank 4+ for custom classes.
- bots_real_mood    - 3 kills without dying makes a bot cocky (pushes more, retreats later).
                      3 deaths without a kill makes it tilted (plays slower, camps, retreats early).
- bots_real_airhide - Bots take cover under a roof while enemy air killstreaks are up,
                      unless they carry a launcher. Rushers and cocky bots sometimes risk it.
- bots_real_grudge  - A player who kills a bot 3 times becomes its nemesis. The bot goes
                      hunting for them and settles the score when it gets the kill.
- bots_real_hotspots   - Bots remember spots players keep getting kills from (3 kills from about
                         the same place). They pre-aim them, nade them, or path around them.
                         Rushers and cocky bots run straight through. Spots are forgotten after
                         3 minutes without a kill.
- bots_real_teamintel  - When a bot spots an enemy, bot teammates nearby look that way, and some
                         move up to help. Team modes only.
- bots_real_matchaware - In the last 2 minutes, the losing side pushes and the winning side plays
                         safe; in objective modes they focus the objective. The last bot alive in
                         S&D plays slow and careful.
- bots_real_slipups    - Bots make human mistakes: turning slowly when shot from behind, panic
                         spraying at low health up close, reloading right after a kill.
                         Easier bots slip up more.
- bots_real_chat       - Bots take a moment to type, and type in their own style: rushers in
                         lowercase, cautious bots properly, tilted bots with the odd typo.
                         They also reply when you type gg, hi, nice shot, trash talk or their name.
- bots_real_voice      - Bots use the game's voice callouts when it fits: enemy spotted, need
                         reinforcements, fall back, follow me, suppressing fire. Team modes only.
- bots_real_avenge     - Bots that see a teammate die nearby go after the killer.
- bots_real_adaptive   - OFF by default. Every 30 seconds the bots you play against get a bit
                         better or worse depending on how your last 30 seconds went, to keep you
                         near bots_real_adaptive_kd (default 1.2). Your bot teammates aren't changed.
- bots_real_banter     - Bots talk to each other ("ok boomer"), react to special kills (knife,
                         headshot, long shot, multikill, streak ender, revenge), say "you again"
                         and praise the human MVP at the end.
- bots_real_parties    - Some bots group up in parties of 2-3 that follow, avenge and cheer each other.
- bots_real_churn      - Deeply tilted bots sometimes rage quit and someone new joins later;
                         a bot sometimes says goodbye at the end of a match.
- bots_real_preaim     - Bots glance at corners and long sightlines while moving.
- bots_real_turrets    - Bots stay and fight on mounted turrets instead of hopping off.

## Presets and settings file
- bots_real_preset: casual, competitive, chaos, off, or custom (default, set things yourself).
  Pick it in the Realism tab. Flipping any single toggle switches back to custom.
- Rage, bait and mood tuning: bots_real_rage (50), bots_real_bait (30), bots_real_mood_streak (3).
- Settings reset when the game restarts. The installer puts xtended.cfg in your Plutonium storage
  folder with every setting and a comment for each. Edit it, then type "exec xtended.cfg" in the
  console, or add +exec xtended.cfg to your launch options.

Bot chat is also rate limited so bots don't flood the chat: one bot message every
1.5 seconds, at most one per bot every 6 seconds, and no line repeated within a minute.
'bots_main_chat' still scales how chatty they are (0 turns bot chat off).

## Bot names
The installer also puts a bots.txt with 300 gamer-style names in your Plutonium
storage folder (%LOCALAPPDATA%\Plutonium\storage\iw5\bots.txt). Plutonium names bots
from that file, one name per line. Edit it to use your own names. If you already had
a bots.txt, the installer leaves it alone.

Realism > "Show bot status" lists every bot's personality, skill and what it's doing
(camping, retreating, checking a noise, playing the objective...), plus their mood and any grudge.
The full list is in the console (~).
Set 'bots_main_debug 2' in the console to see every bot event as it happens.

## Changelog
- XTended 1.0 (based on Bot Warfare 2.3.0)
 - New menu look: dark translucent bars, orange highlights, ON/OFF toggles
 - Bot chat is rate limited, bots take time to type and type in their own style
 - Ships a bots.txt with 300 human-looking bot names
 - Menu animations: the cursor glides between options and the menu fades in
 - Refreshed ~100 dated chat lines and dropped the random chat colors
 - Added ~355 newer chat lines for kills, deaths, wins, losses and match starts
 - Bots talk like a millennial, zoomer, Gen Alpha or boomer, with their own lines and typing style
 - Bots talk to each other, react to special kills, remember who keeps killing them and praise the MVP
 - Added pre-aiming, parties, lobby churn and mounted turret use
 - Added presets, a Social tab in the menu and a commented xtended.cfg settings file
 - Tilted bots rage and bots bait the human players they kill, in their era's voice
 - Added voice callouts, avenging teammates, chat replies and optional adaptive difficulty
 - Added personality traits, human-like aim, hearing and retreating (see above)
 - Added team chat callouts when bots retreat or hear something
 - Bots pick weapons and killstreaks that fit their personality
 - Added "Show bot status" to the Realism menu
 - Added counter-picking, cocky/tilted moods, hiding from air support and grudges
 - Added camping spot memory, team callouts, score/last-alive awareness and human slip-ups
 - The last bot alive in S&D goes to plant or guard a site right away instead of waiting
 - Personality, mood and match state no longer stack into bots that camp forever or flee at full health
 - Tilt wears off after 2 minutes; retreating and hiding never block the objective
 - Objective modes: bots chase noises, callouts and grudges less so they stay on the objective
 - Grudge hunts go to where the nemesis last got the bot, not their live position
 - About half of S&D defenders now set up on a bomb site from the start of the round
 - Fixed bots slowly giving up on objectives, crates and turrets (bot counts drifting, "unreachable" lasting all match)
 - Retreating and hiding from air now pick the nearest good spot
 - Bots no longer nade camping spots with a teammate standing there
 - A damaged waypoint .csv falls back to the built-in waypoints instead of breaking the bots
 - Fixed thermal-scoped bots targeting script objects through walls
 - Fixed bots not alerting nearby teammates when they get shot
 - Fixed specialist killstreak perk selection
 - Fixed domination bots sometimes heading for a flag their team already owns
 - Includes upstream changes made after the 2.3.0 release (camping changes, menu fix)

## Credits
- Plutonium Team - https://plutonium.pw/
- CoD4x Team - https://github.com/callofduty4x/CoD4x_Server
- INeedGames - http://www.moddb.com/mods/bot-warfare
- tinkie101 - https://web.archive.org/web/20120326060712/http://alteriw.net/viewtopic.php?f=72&t=4869
- PeZBot team - http://www.moddb.com/mods/pezbot
- apdonato - http://rsebots.blogspot.ca/
- Ability
- Salvation

## Waypoint Creators
- FragsAreUs - https://github.com/FragsAreUs
- Aesirix - https://github.com/Aesirix
- EpikIzCool - https://github.com/super23
- doa3 - https://github.com/doa3
- ghostwulf - https://github.com/ghostwulf
- LeRutY - https://github.com/LeRutY
- GaryTheNoTrashCougar - https://github.com/GaryTheNoTrashCougar
