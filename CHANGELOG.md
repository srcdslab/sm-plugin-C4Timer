## Release Notes

## [1.5.1-srcdslab]

### Changed

- srcdslab layout: `addons/sourcemod/scripting/C4Timer.sp` and `addons/sourcemod/translations/C4Timer.phrases.txt`
  (was `plugin.advancedc4timer.txt`). `configs/c4soundslist.cfg`, the `bombtimer` sounds, the cookies and
  `cfg/sourcemod/advancedc4timer.cfg` keep their upstream names.
- The generated `cfg/sourcemod/advancedc4timer.cfg` is no longer shipped (`AutoExecConfig` creates it).
- CI build for SourceMod 1.12 and 1.13 with release archives (plugin, translations, config and sounds),
  translation lint, Dependabot.
- New syntax (`#pragma newdecls required`) and methodmaps (`ConVar`, `Cookie`, `Menu`, `KeyValues`, `Event`).
- The `Bomb:` chat prefix is a translation phrase (`chat countdown`).
- `myinfo` URL points to this repository.

### Added

- Translations: fr, es, de, ru, pt, pl, tr, it, ua, cze, chi, zho for every phrase.

### Fixed

- `sm_c4_timer_announce` was initialised from `sm_c4_timer_enable`.
- The "Terrorist" / "Counter-Terrorist" fallback names (planter or defuser no longer in game) were formatted
  without a language and raised an error; they now use the server language. The "Counter-Terrorist" phrase
  declared a parameter it does not use.
- A player joining in the slot of a player who left kept the previous player's preferences and never loaded
  their own.
- A countdown still running when a new bomb is planted is stopped first.
- `sm_c4timer` from the server console no longer tries to show a menu to client 0.
- Settings menus still on screen are cancelled when the plugin unloads (SourceMod 1.13 x86_64 crashes when a
  plugin is unloaded with one of its menus open).
- Hint and center texts are no longer used as format strings.
- Removed the unused SteamID cache (`GetClientAuthString`).

ConVar names, defaults, the command and the cookies are unchanged.

## [1.5.0] - 2013-04-17 (thetwistedpanda)

- Replaced all instances of `GetMaxClients()` with `MaxClients`.
- Modified / optimized numerous blocks of code.
- Support for plant/defuse by a player no longer in game ("Terrorist" and "Counter-Terrorist" phrases).
- Client preferences stored with ClientPrefs instead of a KeyValues file.

## [1.4.1] (dalto)

- Individual sounds.
