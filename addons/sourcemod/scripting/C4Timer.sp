/*
advancedc4timer.sp

Description:
	Advanced c4 countdown timer.  Based on the original sm c4 timer by sslice.

Versions:
	0.5
		* Initial Release
		
	0.6
		* Restructued most of the code
		* Added user configuration of sounds
		* Added optional announcement
		* Changed timer to go 30, 20, 10, 9.....1
		
	1.0
		* Minor code and naming standards changes
		* Added support for late loading
		
	1.1
		* Added an exit option to the settings menu
		* Changed command to sm_c4timer
		* Made the SoundNames array const
		* Added new hud text
		
	1.1.1
		* Fixed voice countdown bug
		
	1.2
		* Added translations
		* Added name to bomb exploded message
		* Added bomb defused hud message
		
	1.2.1
		* Updated translation files and script to match
		* Changed menu behavior
		
	1.3
		* Changed naming convention to be more in line with base sourcemod
		* Improved timer synchronization
		* Changed from panels to menus
		
	1.4
		* Removed duplicate menu exit
		* Added autoloading of config file
		* Added verbose, flexible bombtimer messages
		* Added the ability to have the voice or text messages start at 10 instead of 30
		
	1.4.1
		* Added individual sounds
		
	1.5.0 - Panduh
		* Replaced all instances of GetMaxClients() with MaxClients.
		* Modified / Optimized numerous blocks of code
		* Added support for extremely rare cases of Plant/Defuse with player no longer in-game.
		* Added two translations, "Terrorist" and "Counter-Terrorist", generics for the above issue.
		* Replaced KV data system with ClientPrefs to greatly improve performance.
		
	1.5.1-srcdslab
		* See CHANGELOG.md
		
*/
		
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define PLUGIN_VERSION "1.5.1-srcdslab"
#define TOTAL_SOUNDS 12

#define TWENTY 0
#define ONE 1
#define TWO 2
#define THREE 3
#define FOUR 4
#define FIVE 5
#define SIX 6
#define SEVEN 7
#define EIGHT 8
#define NINE 9
#define TEN 10
#define THIRTY 11

#define SOUND_AT_TEN 1
#define TEXT_AT_TEN 2

//* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

enum
{
	bHud = 0,
	bChat,
	bCenter,
	bSound,
	Preferences_Count
}

Handle g_hTimer_Countdown = null;
ConVar g_hEnable;
ConVar g_hCvarTimer;
ConVar g_hAnnounce;
ConVar g_hChatDefault;
ConVar g_hSoundDefault;
ConVar g_hHUDDefault;
ConVar g_hCenterDefault;
ConVar g_hAltStart;
Cookie g_cPrefSound;
Cookie g_cPrefChat;
Cookie g_cPrefCenter;
Cookie g_cPrefHud;

float g_fExplosionTime, g_fCounter, g_fCvarTimer;
bool g_bLateLoad, g_bAnnounce, g_bEnable;
int g_iAltSound;
char g_sSoundList[TOTAL_SOUNDS][PLATFORM_MAX_PATH], g_sC4Primer[32];
char g_sHUDDefault[2], g_sSoundDefault[2], g_sChatDefault[2], g_sCenterDefault[2];

int g_Prefs[MAXPLAYERS + 1][Preferences_Count];
bool g_bLoaded[MAXPLAYERS + 1];
Menu g_hSettingsMenu[MAXPLAYERS + 1];

static const char g_sSoundDisplay[TOTAL_SOUNDS][] = {"20", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "30"};

//* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

public Plugin myinfo =
{
	name = "Advanced c4 Countdown Timer",
	author = "dalto, Panda, .Rushaway",
	description = "Plugin that gives a countdown for the C4 explosion in Counter-Strike Source.",
	version = PLUGIN_VERSION,
	url = "https://github.com/srcdslab/sm-plugin-C4Timer"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateLoad = late;

	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("C4Timer.phrases");

	CreateConVar("sm_c4_timer_redux_version", PLUGIN_VERSION, "Advanced c4 Timer Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hEnable = CreateConVar("sm_c4_timer_enable", "1", "Enables / Disables features of this plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_bEnable = g_hEnable.BoolValue;
	g_hEnable.AddChangeHook(OnSettingsChange);

	g_hAnnounce = CreateConVar("sm_c4_timer_announce", "1", "If enabled, clients receive a message 30 seconds after joining concerning this plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_bAnnounce = g_hAnnounce.BoolValue;
	g_hAnnounce.AddChangeHook(OnSettingsChange);

	g_hChatDefault = CreateConVar("sm_c4_timer_chat_default", "0", "Default client setting for chat preference.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hChatDefault.GetString(g_sChatDefault, sizeof(g_sChatDefault));
	g_hChatDefault.AddChangeHook(OnSettingsChange);

	g_hCenterDefault = CreateConVar("sm_c4_timer_center_default", "0", "Default client setting for center preference.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCenterDefault.GetString(g_sCenterDefault, sizeof(g_sCenterDefault));
	g_hCenterDefault.AddChangeHook(OnSettingsChange);

	g_hHUDDefault = CreateConVar("sm_c4_timer_hud_default", "1", "Default client setting for HUD preference.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hHUDDefault.GetString(g_sHUDDefault, sizeof(g_sHUDDefault));
	g_hHUDDefault.AddChangeHook(OnSettingsChange);

	g_hSoundDefault = CreateConVar("sm_c4_timer_sound_default", "1", "Default client setting for sound preference.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hSoundDefault.GetString(g_sSoundDefault, sizeof(g_sSoundDefault));
	g_hSoundDefault.AddChangeHook(OnSettingsChange);

	g_hAltStart = CreateConVar("sm_c4_timer_start_at_ten", "0", "1 voice starts at 10, 2 text starts at 10, 3 both start at 10");
	g_iAltSound = g_hAltStart.IntValue;
	g_hAltStart.AddChangeHook(OnSettingsChange);
	AutoExecConfig(true, "advancedc4timer");

	g_hCvarTimer = FindConVar("mp_c4timer");
	g_fCvarTimer = g_hCvarTimer.FloatValue;
	g_hCvarTimer.AddChangeHook(OnSettingsChange);

	HookEvent("bomb_planted", EventBombPlanted, EventHookMode_Pre);
	HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
	HookEvent("bomb_exploded", EventBombExploded, EventHookMode_PostNoCopy);
	HookEvent("bomb_defused", EventBombDefused, EventHookMode_Post);

	RegConsoleCmd("sm_c4timer", SettingsMenu);

	g_cPrefSound = new Cookie("AdvancedC4Timer_Sound", "Advanced C4 Timer: The client's sound preference.", CookieAccess_Protected);
	g_cPrefChat = new Cookie("AdvancedC4Timer_Chat", "Advanced C4 Timer: The client's chat message preference.", CookieAccess_Protected);
	g_cPrefCenter = new Cookie("AdvancedC4Timer_Center", "Advanced C4 Timer: The client's center message preference.", CookieAccess_Protected);
	g_cPrefHud = new Cookie("AdvancedC4Timer_Hud", "Advanced C4 Timer: The client's hud message preference.", CookieAccess_Protected);

	if(g_bEnable && g_bLateLoad)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				if(!IsFakeClient(i) && !g_bLoaded[i] && AreClientCookiesCached(i))
					LoadClientData(i);
			}
		}

		g_bLateLoad = false;
	}
}

public void OnPluginEnd()
{
	// Close the settings menus still on screen: unloading a plugin while one of its menus is
	// displayed crashes SourceMod 1.13 x86_64 (reproduced on 1.13.0.7491, 2026-11-19).
	for (int i = 1; i <= MaxClients; i++)
	{
		if(g_hSettingsMenu[i] != null)
			g_hSettingsMenu[i].Cancel();
	}
}

public void OnSettingsChange(ConVar cvar, const char[] oldvalue, const char[] newvalue)
{
	if(cvar == g_hEnable)
		g_bEnable = view_as<bool>(StringToInt(newvalue));
	else if(cvar == g_hAnnounce)
		g_bAnnounce = view_as<bool>(StringToInt(newvalue));
	else if(cvar == g_hChatDefault)
		strcopy(g_sChatDefault, sizeof(g_sChatDefault), newvalue);
	else if(cvar == g_hCenterDefault)
		strcopy(g_sCenterDefault, sizeof(g_sCenterDefault), newvalue);
	else if(cvar == g_hHUDDefault)
		strcopy(g_sHUDDefault, sizeof(g_sHUDDefault), newvalue);
	else if(cvar == g_hSoundDefault)
		strcopy(g_sSoundDefault, sizeof(g_sSoundDefault), newvalue);
	else if(cvar == g_hAltStart)
		g_iAltSound = StringToInt(newvalue);
	else if(cvar == g_hCvarTimer)
		g_fCvarTimer = StringToFloat(newvalue);
}

public void OnMapStart()
{
	if(g_bEnable)
	{
		Define_Sounds(true);
	}
}

public void OnClientPostAdminCheck(int client)
{
	if(g_bEnable)
	{
		if(!g_bLoaded[client] && !IsFakeClient(client) && AreClientCookiesCached(client))
			LoadClientData(client);
	}
}

public void OnClientCookiesCached(int client)
{
	if(g_bEnable)
	{
		if(!g_bLoaded[client] && !IsFakeClient(client))
		{
			LoadClientData(client);
		}
	}
}

public void OnClientDisconnect(int client)
{
	// The next player in this slot must load their own preferences
	g_bLoaded[client] = false;
	for (int i = 0; i < Preferences_Count; i++)
		g_Prefs[client][i] = 0;
}

void LoadClientData(int client)
{
	char sCookie[4] = "";
	g_cPrefHud.Get(client, sCookie, sizeof(sCookie));

	if(StrEqual(sCookie, "", false))
	{
		g_cPrefHud.Set(client, g_sHUDDefault);
		g_cPrefChat.Set(client, g_sChatDefault);
		g_cPrefCenter.Set(client, g_sCenterDefault);
		g_cPrefSound.Set(client, g_sSoundDefault);

		g_Prefs[client][bHud] = StringToInt(g_sHUDDefault);
		g_Prefs[client][bChat] = StringToInt(g_sChatDefault);
		g_Prefs[client][bCenter] = StringToInt(g_sCenterDefault);
		g_Prefs[client][bSound] = StringToInt(g_sSoundDefault);
	}
	else
	{
		g_Prefs[client][bHud] = StringToInt(sCookie);

		g_cPrefChat.Get(client, sCookie, sizeof(sCookie));
		g_Prefs[client][bChat] = StringToInt(sCookie);

		g_cPrefCenter.Get(client, sCookie, sizeof(sCookie));
		g_Prefs[client][bCenter] = StringToInt(sCookie);

		g_cPrefSound.Get(client, sCookie, sizeof(sCookie));
		g_Prefs[client][bSound] = StringToInt(sCookie);
	}

	g_bLoaded[client] = true;

	if(g_bAnnounce)
		CreateTimer(30.0, Timer_Announce, GetClientUserId(client));
}

public void EventRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(g_bEnable)
	{
		delete g_hTimer_Countdown;
	}
}

public Action EventBombPlanted(Event event, const char[] name, bool dontBroadcast)
{
	if(g_bEnable)
	{
		g_fCounter = g_fCvarTimer - 1.0;
		g_fExplosionTime = GetEngineTime() + g_fCvarTimer;

		int client = GetClientOfUserId(event.GetInt("userid"));
		if(!client || !IsClientInGame(client))
			Format(g_sC4Primer, sizeof(g_sC4Primer), "%T", "Terrorist", LANG_SERVER);
		else
			GetClientName(client, g_sC4Primer, sizeof(g_sC4Primer));

		delete g_hTimer_Countdown;
		g_hTimer_Countdown = CreateTimer(((g_fExplosionTime - g_fCounter) - GetEngineTime()), TimerCountdown, _, TIMER_REPEAT);
	}

	return Plugin_Continue;
}

public void EventBombDefused(Event event, const char[] name, bool dontBroadcast)
{
	if(g_bEnable)
	{
		delete g_hTimer_Countdown;

		char sC4Defuser[32];
		int client = GetClientOfUserId(event.GetInt("userid"));
		if(!client || !IsClientInGame(client))
			Format(sC4Defuser, sizeof(sC4Defuser), "%T", "Counter-Terrorist", LANG_SERVER);
		else
			GetClientName(client, sC4Defuser, sizeof(sC4Defuser));

		for(int i = 1; i <= MaxClients; i++)
			if(IsClientInGame(i) && !IsFakeClient(i) && g_Prefs[i][bHud])
				PrintHintText(i, "%T", "bomb defused", i, sC4Defuser);
	}
}

public void EventBombExploded(Event event, const char[] name, bool dontBroadcast)
{
	if(g_bEnable)
	{
		delete g_hTimer_Countdown;

		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && g_Prefs[i][bHud])
			{
				PrintHintText(i, "%T", "bomb exploded", i, g_sC4Primer);
			}
		}
	}
}

public Action TimerCountdown(Handle timer, any data)
{
	BombMessage(RoundToFloor(g_fCounter));

	g_fCounter--;
	if(g_fCounter <= 0)
	{
		g_hTimer_Countdown = null;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

void Define_Sounds(bool bPrepare = false)
{
	char sPath[PLATFORM_MAX_PATH];
	KeyValues hKeyValues = new KeyValues("c4SoundsList");
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/c4soundslist.cfg");

	if(!hKeyValues.ImportFromFile(sPath) || !hKeyValues.GotoFirstSubKey())
	{
		delete hKeyValues;
		SetFailState("configs/c4soundslist.cfg not found or not correctly structured");
	}
	else
	{
		for(int i = 0; i < TOTAL_SOUNDS; i++)
		{
			hKeyValues.GetString(g_sSoundDisplay[i], g_sSoundList[i], PLATFORM_MAX_PATH);
			if(bPrepare && !StrEqual(g_sSoundList[i], ""))
			{
				PrecacheSound(g_sSoundList[i], true);
				Format(sPath, PLATFORM_MAX_PATH, "sound/%s", g_sSoundList[i]);
				AddFileToDownloadsTable(sPath);
			}
		}
	}

	delete hKeyValues;
}

void BombMessage(int count)
{
	int soundKey;
	char sBuffer[192];

	switch(count)
	{
		case 1, 2, 3, 4, 5, 6, 7, 8, 9, 10:
			soundKey = count;
		case 20:
			soundKey = TWENTY;
		case 30:
			soundKey = THIRTY;
		default:
			return;
	}

	if(!StrEqual(g_sSoundList[soundKey], ""))
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				Format(sBuffer, sizeof(sBuffer), "countdown %i", count);
				Format(sBuffer, sizeof(sBuffer), "%T", sBuffer, i, count);

				if(g_Prefs[i][bSound] && !(g_iAltSound & SOUND_AT_TEN && (soundKey < 1 || soundKey > 10)))
				{
					EmitSoundToClient(i, g_sSoundList[soundKey]);
				}
				if(!(g_iAltSound & TEXT_AT_TEN && (soundKey < 1 || soundKey > 10)))
				{
					if(g_Prefs[i][bChat])
					{
						PrintToChat(i, "%T", "chat countdown", i, sBuffer);
					}
					if(g_Prefs[i][bCenter])
					{
						PrintCenterText(i, "%s", sBuffer);
					}
					if(g_Prefs[i][bHud])
					{
						PrintHintText(i, "%s", sBuffer);
					}
				}
			}
		}
	}
}

public Action Timer_Announce(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client))
	{
		PrintToChat(client, "%t", "announce");
	}

	return Plugin_Stop;
}

public Action SettingsMenu(int client, int args)
{
	if(!client)
		return Plugin_Handled;

	char sBuffer[128];
	Menu menu = new Menu(SettingsMenuHandler);
	Format(sBuffer, sizeof(sBuffer), "%T", "c4 menu", client);
	menu.SetTitle(sBuffer);
	if(g_Prefs[client][bSound] == 1)
		Format(sBuffer, sizeof(sBuffer), "%T", "disable sound", client);
	else
		Format(sBuffer, sizeof(sBuffer), "%T", "enable sound", client);
	menu.AddItem("menu item", sBuffer);

	if(g_Prefs[client][bChat] == 1)
		Format(sBuffer, sizeof(sBuffer), "%T", "disable chat", client);
	else
		Format(sBuffer, sizeof(sBuffer), "%T", "enable chat", client);
	menu.AddItem("menu item", sBuffer);

	if(g_Prefs[client][bCenter] == 1)
		Format(sBuffer, sizeof(sBuffer), "%T", "disable center", client);
	else
		Format(sBuffer, sizeof(sBuffer), "%T", "enable center", client);
	menu.AddItem("menu item", sBuffer);

	if(g_Prefs[client][bHud] == 1)
		Format(sBuffer, sizeof(sBuffer), "%T", "disable hud", client);
	else
		Format(sBuffer, sizeof(sBuffer), "%T", "enable hud", client);
	menu.AddItem("menu item", sBuffer);

	g_hSettingsMenu[client] = menu;
	menu.Display(client, 30);
	return Plugin_Handled;
}

public int SettingsMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sBuffer[2];
			switch(param2)
			{
				case 0:
				{
					g_Prefs[param1][bSound] = !g_Prefs[param1][bSound];
					IntToString(g_Prefs[param1][bSound], sBuffer, sizeof(sBuffer));
					g_cPrefSound.Set(param1, sBuffer);
				}
				case 1:
				{
					g_Prefs[param1][bChat] = !g_Prefs[param1][bChat];
					IntToString(g_Prefs[param1][bChat], sBuffer, sizeof(sBuffer));
					g_cPrefChat.Set(param1, sBuffer);
				}
				case 2:
				{
					g_Prefs[param1][bCenter] = !g_Prefs[param1][bCenter];
					IntToString(g_Prefs[param1][bCenter], sBuffer, sizeof(sBuffer));
					g_cPrefCenter.Set(param1, sBuffer);
				}
				case 3:
				{
					g_Prefs[param1][bHud] = !g_Prefs[param1][bHud];
					IntToString(g_Prefs[param1][bHud], sBuffer, sizeof(sBuffer));
					g_cPrefHud.Set(param1, sBuffer);
				}
			}

			// Shows a new menu: this one still gets MenuAction_End and is deleted there
			SettingsMenu(param1, 0);
		}
		case MenuAction_End:
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				if(g_hSettingsMenu[i] == menu)
					g_hSettingsMenu[i] = null;
			}
			delete menu;
		}
	}

	return 0;
}
