# sm-plugin-C4Timer

### Bomb countdown timer for Counter-Strike: Source.

srcdslab port of **Advanced C4 Timer (Redux) 1.5.0** by thetwistedpanda, itself an optimization of dalto's Advanced C4 Timer ([AlliedModders thread](https://forums.alliedmods.net/showthread.php?t=213711)).

While the bomb is planted, every player gets the countdown at 30, 20 and 10 to 1 seconds before the explosion as a voice sound, a hint box (HUD), a center message and/or a chat message, each one toggled per player with `!c4timer` and saved with client preferences (cookies). When the bomb explodes or is defused, a hint box names the planter or the defuser.

## Requirements

- Counter-Strike: Source
- SourceMod 1.12 or newer, with the `clientprefs` extension (bundled with SourceMod) to remember player choices

## Installation

Download `sm-plugin-C4Timer-<version>-sm1.12.tar.gz` or `-sm1.13.tar.gz` from the [releases](https://github.com/srcdslab/sm-plugin-C4Timer/releases) and extract it in `cstrike/`:

```
addons/sourcemod/plugins/C4Timer.smx
addons/sourcemod/translations/C4Timer.phrases.txt
addons/sourcemod/configs/c4soundslist.cfg
sound/bombtimer/1sec.mp3 ... 10sec.mp3, 20sec.mp3, 30sec.mp3
```

The `sound/bombtimer/*.mp3` files (about 170 KB) are not stock CS:S sounds: they come with the plugin and are added to the downloads table, so put them on the FastDL host too (`sound/bombtimer/`, optionally bzip2-compressed).

## Sounds

`addons/sourcemod/configs/c4soundslist.cfg` maps each second (`1` to `10`, `20`, `30`) to a sound path relative to `sound/`. The plugin fails to load if the file is missing.

**A second with no sound has no text either**: hint, center and chat messages are only sent for the seconds listed in this file (upstream behaviour).

To use stock sounds only (nothing to download), the HL2 sounds mounted by every CS:S client can be used instead, for example the metro police voice:

```
"c4SoundsList"
{
	"c4"
	{
		"1"		"npc/metropolice/vo/one.wav"
		"2"		"npc/metropolice/vo/two.wav"
		"3"		"npc/metropolice/vo/three.wav"
		"4"		"npc/metropolice/vo/four.wav"
		"5"		"npc/metropolice/vo/five.wav"
		"6"		"npc/metropolice/vo/six.wav"
		"7"		"npc/metropolice/vo/seven.wav"
		"8"		"npc/metropolice/vo/eight.wav"
		"9"		"npc/metropolice/vo/nine.wav"
		"10"	"npc/metropolice/vo/ten.wav"
		"20"	"npc/metropolice/vo/twenty.wav"
		"30"	"npc/metropolice/vo/thirty.wav"
	}
}
```

## Commands

| Command | Description |
|---|---|
| `sm_c4timer` (`!c4timer`) | Menu to toggle the sound, chat, center and HUD countdown for yourself. |

## ConVars

| ConVar | Default | Description |
|---|---|---|
| `sm_c4_timer_enable` | `1` | Enables / disables the plugin. |
| `sm_c4_timer_announce` | `1` | Tell players about `!c4timer` 30 seconds after they join. |
| `sm_c4_timer_sound_default` | `1` | Default sound preference for new players. |
| `sm_c4_timer_hud_default` | `1` | Default HUD (hint box) preference for new players. |
| `sm_c4_timer_center_default` | `0` | Default center message preference for new players. |
| `sm_c4_timer_chat_default` | `0` | Default chat message preference for new players. |
| `sm_c4_timer_start_at_ten` | `0` | `1` voice starts at 10, `2` text starts at 10, `3` both start at 10. |
| `sm_c4_timer_redux_version` | | Plugin version (public, shown in the server rules). |

The countdown follows `mp_c4timer`. The config file is `cfg/sourcemod/advancedc4timer.cfg` (created on first load, same name as upstream). Default preferences only apply to players who have no saved preference yet.

## Credits

- [thetwistedpanda](https://forums.alliedmods.net/member.php?u=41467) (Panda): Advanced C4 Timer Redux 1.5.0.
- dalto: Advanced C4 Timer 0.5 - 1.4.1 and the bundled `bombtimer` sounds ([thread](https://forums.alliedmods.net/showthread.php?p=511312)).
- sslice: the original SourceMod c4 timer.

The first commit of this repository is the unmodified 1.5.0 package (without its precompiled `.smx`). See [CHANGELOG.md](CHANGELOG.md) for the srcdslab changes.
