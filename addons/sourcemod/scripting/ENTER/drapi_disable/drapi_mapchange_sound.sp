/* <DR.API MAPCHANGE SOUND> (c) by <De Battista Clint - (http://doyou.watch) */
/*                                                                           */
/*                 <DR.API MAPCHANGE SOUND> is licensed under a              */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//**************************DR.API MAPCHANGE SOUND***************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0.3"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[MAPCHANGE SOUND] -"
#define MAX_SOUNDS						15

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <autoexec>
#include <csgocolors>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_mapchange_sound_dev;

Handle cvar_mapchange_sound_timer;

Handle CookieMapChangeSound;

//Bool
bool B_active_mapchange_sound_dev					= false;

//Strings
char S_mapchange_sound_timer[32];

char S_soundmapchangeurl[MAX_SOUNDS][PLATFORM_MAX_PATH];
char S_soundmapchangetitle[MAX_SOUNDS][PLATFORM_MAX_PATH];

//Customs
int max_sounds_map_change;
int sounds_map;

int C_MapSoundEnt[2048];
int C_show_mapchange_sound[MAXPLAYERS + 1];
//Informations plugin
public Plugin myinfo =
{
	name = "DR.API MAPCHANGE SOUND",
	author = "Dr. Api",
	description = "DR.API MAPCHANGE SOUND by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://zombie4ever.eu"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	LoadTranslations("drapi/drapi_mapchange_sounds.phrases");
	AutoExecConfig_SetFile("drapi_mapchange_sound", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_mapchange_sound_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_mapchange_sound_dev			= AutoExecConfig_CreateConVar("drapi_active_mapchange_sound_dev", 			"0", 			"Enable/Disable Dev Mod", 																												DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	cvar_mapchange_sound_timer				= AutoExecConfig_CreateConVar("drapi_mapchange_sound_timer", 				"panel", 		"panel=will play at the last seconde before mapchange, otherwise choose a time number less than mp_match_restart_delay", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	HookEvent("cs_win_panel_match", Event_CsWinPanelMatch);
	HookEvent("round_start", 		Event_RoundStart);
	
	HookEvents();
	
	AutoExecConfig_ExecuteFile();
	
	RegAdminCmd("sm_pms", Command_PlayMapchangeSounds, ADMFLAG_CHANGEMAP, "Menu client preferences");
	
	RegConsoleCmd("sm_ms", Command_MapchangeSounds, "Menu client preferences");
	
	CookieMapChangeSound 	= RegClientCookie("CookieMapChangeSound", "", CookieAccess_Private);
	
	int info;
	SetCookieMenuItem(MapchangeSoundsCookieHandler, info, "Mapchange Sounds");
	
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if(IsClientInGame(i)) 
			{
				if(AreClientCookiesCached(i))
				{
					OnClientCookiesCached(i);
				}
			}
		}
		i++;
	}
}

/***********************************************************/
/**************** WHEN CLIENT PUT IN SERVER ****************/
/***********************************************************/
public void OnClientPostAdminCheck(int client)
{
	LoadUrl(client, "");	
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEvents()
{
	HookConVarChange(cvar_active_mapchange_sound_dev, 				Event_CvarChange);
	
	HookConVarChange(cvar_mapchange_sound_timer, 					Event_CvarChange);
}

/***********************************************************/
/******************** WHEN CVARS CHANGE ********************/
/***********************************************************/
public void Event_CvarChange(Handle cvar, const char[] oldValue, const char[] newValue)
{
	UpdateState();
}

/***********************************************************/
/*********************** UPDATE STATE **********************/
/***********************************************************/
void UpdateState()
{
	B_active_mapchange_sound_dev 					= GetConVarBool(cvar_active_mapchange_sound_dev);
	
	GetConVarString(cvar_mapchange_sound_timer, S_mapchange_sound_timer, sizeof(S_mapchange_sound_timer));
}

/***********************************************************/
/******************* WHEN CONFIG EXECUTED ******************/
/***********************************************************/
public void OnConfigsExecuted()
{
	LoadSettings();
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public void OnMapStart()
{
	
	UpdateState();
}

/***********************************************************/
/****************** CMD MAPCHANGE SOUND ********************/
/***********************************************************/
public Action Command_MapchangeSounds(int client, int args)
{
	BuildMenuMapchangeSounds(client);
	return Plugin_Handled;
}

/***********************************************************/
/******************* CMD MAPCHANGE SOUND *******************/
/***********************************************************/
public Action Command_PlayMapchangeSounds(int client, int args)
{
	if(max_sounds_map_change > 1)
	{
		int num = GetRandomInt(1, max_sounds_map_change - 1);
		PlaySound(num);
		ShowTheTitleSong(num);
	}
	return Plugin_Handled;
}

/***********************************************************/
/**************** ON CLIENT COOKIE CACHED ******************/
/***********************************************************/
public void OnClientCookiesCached(int client)
{
	char value[16];
	
	GetClientCookie(client, CookieMapChangeSound, value, sizeof(value));
	if(strlen(value) > 0) 
	{
		C_show_mapchange_sound[client] = StringToInt(value);
	}
	else 
	{
		C_show_mapchange_sound[client] = 1;
	}
}
/***********************************************************/
/******************** WHEN ROUND START *********************/
/***********************************************************/
public void Event_RoundStart(Handle event, char[] name, bool dontBroadcast)
{	
		sounds_map = 0;
		char S_sound[PLATFORM_MAX_PATH];
		int entity = INVALID_ENT_REFERENCE;
		
		while((entity = FindEntityByClassname(entity, "ambient_generic")) != INVALID_ENT_REFERENCE)
		{
			GetEntPropString(entity, Prop_Data, "m_iszSound", S_sound, sizeof(S_sound));
			
			int len = strlen(S_sound);
			if (len > 4 && (StrEqual(S_sound[len-3], "mp3") || StrEqual(S_sound[len-3], "wav")))
			{
				C_MapSoundEnt[sounds_map++] = EntIndexToEntRef(entity);
			}
		}
}

/***********************************************************/
/************** WHEN WIN PANEL MATCH POPUP *****************/
/***********************************************************/
public void Event_CsWinPanelMatch(Handle event, char[] name, bool dontBroadcast)
{
	if(max_sounds_map_change > 1)
	{
		float time;
		if(StrEqual(S_mapchange_sound_timer, "panel", false))
		{
			time = GetConVarFloat(FindConVar("mp_match_restart_delay")) - 1;
		}
		else
		{
			time = StringToFloat(S_mapchange_sound_timer);

		}
		
		int num = GetRandomInt(1, max_sounds_map_change - 1);
		CreateTimer(time, Timer_PlaySound, num);
		ShowTheTitleSong(num);
	}
	
	
}

/***********************************************************/
/******************* TIMER PLAY SOUND **********************/
/***********************************************************/
public Action Timer_PlaySound(Handle timer, any num)
{
	PlaySound(num);
}

/***********************************************************/
/********************** MENU SETTINGS **********************/
/***********************************************************/
public void MapchangeSoundsCookieHandler(int client, CookieMenuAction action, any info, char [] buffer, int maxlen)
{
	BuildMenuMapchangeSounds(client);
}

/***********************************************************/
/*************** BUILD MENU MAPCHANGE SOUNDS ***************/
/***********************************************************/
void BuildMenuMapchangeSounds(int client)
{
	char title[40], mapchange_sound[40], status_mapchange_sound[40];
	
	Menu menu = CreateMenu(MenuMapchangeSoundsAction);
	
	Format(status_mapchange_sound, sizeof(status_mapchange_sound), "%T", (C_show_mapchange_sound[client]) ? "Enabled" : "Disabled", client);
	Format(mapchange_sound, sizeof(mapchange_sound), "%T", "MenuMapchangeSounds_MAPCHANGE_MENU_TITLE", client, status_mapchange_sound);
	AddMenuItem(menu, "M_mapchange_sound", mapchange_sound);
	
	Format(title, sizeof(title), "%T", "MenuMapchangeSounds_TITLE", client);
	menu.SetTitle(title);
	SetMenuExitBackButton(menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
}

/***********************************************************/
/************** MENU ACTION MAPCHANGE SOUNDS ***************/
/***********************************************************/
public int MenuMapchangeSoundsAction(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);	
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{	
				FakeClientCommand(param1, "sm_settings");
			}
		}
		case MenuAction_Select:
		{
			char menu1[56];
			menu.GetItem(param2, menu1, sizeof(menu1));
			
			if(StrEqual(menu1, "M_mapchange_sound"))
			{
				C_show_mapchange_sound[param1] = !C_show_mapchange_sound[param1];
				SetClientCookie(param1, CookieMapChangeSound, (C_show_mapchange_sound[param1]) ? "1" : "0");
			}
			BuildMenuMapchangeSounds(param1);
		}
	}
}

/***********************************************************/
/********************* PLAY SOUND **************************/
/***********************************************************/
void PlaySound(int num)
{
	StopMapMusic();
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(Client_IsIngame(i) && C_show_mapchange_sound[i])
		{
			ClientCommand(i, "playgamesound Music.StopAllMusic");
			ClientCommand(i, "play *");	
			LoadUrl(i, S_soundmapchangeurl[num]);
		}
	}
}

/***********************************************************/
/**************** PRINT THE TITLE SONG *********************/
/***********************************************************/
void ShowTheTitleSong(int num)
{
	if(S_soundmapchangetitle[num][0])
	{
		for(int i = 1; i <= MaxClients; ++i)
		{
			if(Client_IsIngame(i) && C_show_mapchange_sound[i])
			{
				CPrintToChat(i, "%t", "Title song", S_soundmapchangetitle[num]);
			}
		}
	}
}

/***********************************************************/
/*********************** LOAD URL **************************/
/***********************************************************/
void LoadUrl(int client, char[] url)
{
	Handle kv = CreateKeyValues("data");
	
	KvSetString(kv, "title", "Loading Music");
	KvSetNum(kv, "type", MOTDPANEL_TYPE_URL);
	KvSetString(kv, "msg", url);
	
	ShowVGUIPanel(client, "info", kv, false);
	CloseHandle(kv);
}

/***********************************************************/
/******************** STOP MAP MUSIC ***********************/
/***********************************************************/
void StopMapMusic()
{
	char S_sound[PLATFORM_MAX_PATH];
	int entity = INVALID_ENT_REFERENCE;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!Client_IsIngame(i))
		{ 
			continue; 
		}
		
		for(int sounds = 0; sounds < sounds_map; sounds++)
		{
			entity = EntRefToEntIndex(C_MapSoundEnt[sounds]);
			if(entity != INVALID_ENT_REFERENCE)
			{
				GetEntPropString(entity, Prop_Data, "m_iszSound", S_sound, sizeof(S_sound));
				EmitSoundToClient(i, S_sound, entity, SNDCHAN_STATIC, SNDLEVEL_NONE, SND_STOP, 0.0, SNDPITCH_NORMAL, _, _, _, true);
			}
		}
	}
}

/***********************************************************/
/********************** LOAD SETTINGS **********************/
/***********************************************************/
public void LoadSettings()
{
	char hc[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, hc, sizeof(hc), "configs/drapi/mapchange_sounds.cfg");
	
	Handle kv = CreateKeyValues("Sounds");
	FileToKeyValues(kv, hc);
	
	max_sounds_map_change 		= 1;
	
	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			if(KvJumpToKey(kv, "Mapchange"))
			{
				char S_info[MAX_SOUNDS][PLATFORM_MAX_PATH];
				for(int i = 1; i <= MAX_SOUNDS; ++i)
				{
					char key[64];
					IntToString(i, key, 64);
					
					if(KvGetString(kv, key, S_info[i], PLATFORM_MAX_PATH) && strlen(S_info[i]))
					{
						char explode[2][PLATFORM_MAX_PATH];
						ExplodeString(S_info[i], " | ", explode, 2, PLATFORM_MAX_PATH, true);
						
						S_soundmapchangeurl[i] 		= explode[0];
						S_soundmapchangetitle[i] 	= explode[1];
						
						if(B_active_mapchange_sound_dev)
						{
							LogMessage("%s INFO: %s", TAG_CHAT, S_info[i]);
							LogMessage("%s URL: %s", TAG_CHAT, S_soundmapchangeurl[i]);
							LogMessage("%s TITLE: %s", TAG_CHAT, S_soundmapchangetitle[i]);
						}
						
						max_sounds_map_change++;
					}
					else
					{
						break;
					}
					
				}
				KvGoBack(kv);
			}
		}
		while (KvGotoNextKey(kv));
	}
	CloseHandle(kv);
	
}

/***********************************************************/
/********************* IS VALID CLIENT *********************/
/***********************************************************/
stock bool Client_IsValid(int client, bool checkConnected=true)
{
	if (client > 4096) 
	{
		client = EntRefToEntIndex(client);
	}

	if (client < 1 || client > MaxClients) 
	{
		return false;
	}

	if (checkConnected && !IsClientConnected(client)) 
	{
		return false;
	}
	
	return true;
}

/***********************************************************/
/******************** IS CLIENT IN GAME ********************/
/***********************************************************/
stock bool Client_IsIngame(int client)
{
	if (!Client_IsValid(client, false)) 
	{
		return false;
	}

	return IsClientInGame(client);
} 