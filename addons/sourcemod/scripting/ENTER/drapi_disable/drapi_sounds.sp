/*	   <DR.API SOUNDS> (c) by <De Battista Clint - (http://doyou.watch)		 */
/*																			 */
/*					  <DR.API SOUNDS> is licensed under a					 */
/*						  GNU General Public License						 */
/*																			 */
/*		You should have received a copy of the license along with this		 */
/*			  work.	 If not, see <http://www.gnu.org/licenses/>.			 */
//***************************************************************************//
//***************************************************************************//
//*******************************DR.API SOUNDS*******************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION					"1.0"
#define CVARS							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[SOUNDS] -"
#define SNDCHAN_LOL						45
#define MAX_CMDS						100

//***********************************//
//*************INCLUDE***************//
//***********************************//
#include <clientprefs>
#include <sourcemod>
#include <autoexec>
#include <csgocolors>
#include <sdktools>
#include <emitsoundany>


#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_sounds_dev;

Handle CookieSounds;

//Bool
bool B_cvar_active_sounds_dev					= false;

//Strings
char S_Command[MAX_CMDS][64];
char S_Command_sound[MAX_CMDS][64];

//Customs
int max_command;
int AllowPlaySound[MAXPLAYERS+1]				= false;
int C_Play_Sound[MAXPLAYERS+1]					= true;

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API SOUNDS",
	author = "Dr. Api",
	description = "DR.API SOUNDS by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://doyou.watch"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	AutoExecConfig_SetFile("drapi_sounds", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_sounds_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_sounds_dev			= AutoExecConfig_CreateConVar("drapi_active_sounds_dev",			"1",					"Enable/Disable Dev Mod",				DEFAULT_FLAGS,		true, 0.0,		true, 1.0);
	
	HookEvents();
	
	HookEvent("round_start", RoundStart);
	
	RegConsoleCmd("sm_songs", Command_Songs, "Show list songs commands");
	RegAdminCmd("sm_resetsongs", 					Command_ResetSongs, 			ADMFLAG_CHANGEMAP, "");
	
	CookieSounds = RegClientCookie("Funny Sounds", "", CookieAccess_Private);
	int info;
	SetCookieMenuItem(SoundCookieHandler, info, "Funny Sounds");
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if (!AreClientCookiesCached(i))
		{
			continue;
		}

		SetClientCookie(i, CookieSounds, "1");
		OnClientCookiesCached(i);
	}
	
	AutoExecConfig_ExecuteFile();
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEvents()
{
	HookConVarChange(cvar_active_sounds_dev,				Event_CvarChange);
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
	B_cvar_active_sounds_dev					= GetConVarBool(cvar_active_sounds_dev);
}

/***********************************************************/
/******************* WHEN CONFIG EXECUTED ******************/
/***********************************************************/
public void OnConfigsExecuted()
{
	//UpdateState();
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public void OnMapStart()
{
	LoadSettings();
	FakeAndDownloadSound(false, S_Command_sound, max_command);
	HookCommands();
	
	UpdateState();
}

/***********************************************************/
/********************** RELOAD SONGS ***********************/
/***********************************************************/
public Action Command_ResetSongs(int client, int args)
{
	char S_args1[256];
	GetCmdArg(1, S_args1, sizeof(S_args1));
	
	for(int i = 1; i <= MaxClients; i++)
	{
		SetClientCookie(i, CookieSounds, S_args1);
	}
}

/***********************************************************/
/************************ ROUND START **********************/
/***********************************************************/
public void RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	ResetAll();
}

/***********************************************************/
/********************** CALLBACK EMPTY *********************/
/***********************************************************/
public Action Callback_Empty(int client, int args)
{
	return Plugin_Handled;
}

/***********************************************************/
/*********************** HOOK COMMAND **********************/
/***********************************************************/
public Action Hook_Command(int client, const char[] sCommand, int argc)
{
	for(int i = 0; i < max_command; i++)
	{
		if(StrEqual(S_Command[i], sCommand))
		{
			if(IsClientInGame(client))
			{
				if(IsVip(client) || IsAdminEx(client))
				{
					if(AllowPlaySound[client])
					{
						PlaySound(S_Command_sound[i], _, _);
						if(!IsAdminEx(client)) AllowPlaySound[client] = false;
						
						//PrintToDev(B_cvar_active_sounds_dev, "%s Command: %s, Sound: %s", TAG_CHAT, S_Command[i], S_Command_sound[i]);
						return Plugin_Handled;
					}
				}
				else
				{
					CPrintToChat(client, "You must be VIP to use this. type !vip");
				}
			}
		}
	}
	return Plugin_Continue;
}

/***********************************************************/
/*********************** COMMAND SONG **********************/
/***********************************************************/
public Action Command_Songs(int client, int args)
{
	BuildMenuSounds(client);
	return Plugin_Handled;
}

public void SoundCookieHandler(int client, CookieMenuAction action, any info, char [] buffer, int maxlen)
{
	OnClientCookiesCached(client);
	BuildMenuSounds(client);
} 

/***********************************************************/
/**************** CLIENT POST ADMIN CHECK ******************/
/***********************************************************/
public void OnClientPostAdminCheck(int client)
{
	if (!AreClientCookiesCached(client))
	{
		SetClientCookie(client, CookieSounds, "1");
	}
}

/***********************************************************/
/****************** CLIENT COOKIE CACHED *******************/
/***********************************************************/
public void OnClientCookiesCached(int client)
{
	char sValue[8];
	GetClientCookie(client, CookieSounds, sValue, sizeof(sValue));
	
	if(strlen(sValue) > 0) 
	{
		C_Play_Sound[client] = StringToInt(sValue);
	}
	else 
	{
		C_Play_Sound[client] = 0;
	}
} 

/***********************************************************/
/******************** BUILD MENU SOUND *********************/
/***********************************************************/
void BuildMenuSounds(int client)
{
	Menu menu = CreateMenu(MenuSoundsAction);
	
	if(C_Play_Sound[client])
	{
		AddMenuItem(menu, "M_sound_disable", "Sounds: Enable");
	}
	else
	{
		AddMenuItem(menu, "M_sound_enable", "Sounds: Disable");
	}
	
	if(IsVip(client) || IsAdminEx(client))
	{
		for(int i = 0; i < max_command; i++) 
		{
			if(StrEqual(S_Command[i], ""))
			{
				continue;
			}
			
			AddMenuItem(menu, S_Command[i], S_Command[i]);
		}
	}
	else
	{
		AddMenuItem(menu, "M_vip", "Become VIP");
	}
	
	menu.SetTitle("Funny song");
	SetMenuExitBackButton(menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
}

/***********************************************************/
/******************** MENU ACTION SOUND ********************/
/***********************************************************/
public int MenuSoundsAction(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);	
		}
		case MenuAction_Select:
		{
			char menu1[56];
			menu.GetItem(param2, menu1, sizeof(menu1));
			
			if(StrEqual(menu1, "M_sound_disable"))
			{
				C_Play_Sound[param1] = false;
				SetClientCookie(param1, CookieSounds, "0");
				BuildMenuSounds(param1);
			}
			else if(StrEqual(menu1, "M_sound_enable"))
			{	
				C_Play_Sound[param1] = true;
				SetClientCookie(param1, CookieSounds, "1");
				BuildMenuSounds(param1);
			}
			else if(StrEqual(menu1, "M_vip"))
			{	
				FakeClientCommand(param1, "sm_vip");
				BuildMenuSounds(param1);
			}
			
			for(int i = 0; i < max_command; i++) 
			{
				if(StrEqual(S_Command[i], ""))
				{
					continue;
				}
				
				if(StrEqual(menu1, S_Command[i]))
				{
					if(AllowPlaySound[param1])
					{
						PlaySound(S_Command_sound[i], _, _);
						if(!IsAdminEx(param1)) AllowPlaySound[param1] = false;
					}
					BuildMenuSounds(param1);					
				}
				
			}
		}
	}
}

/***********************************************************/
/************************ RESET ALL ************************/
/***********************************************************/
void ResetAll()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{	
			AllowPlaySound[i] = true;
		}
	}
}

/***********************************************************/
/*********************** PLAY SOUND ************************/
/***********************************************************/
stock void PlaySound(char[] sound, int pitch = SNDPITCH_NORMAL, float vol=1.0)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && C_Play_Sound[i])
		{
			EmitSoundToClientAny(i, sound, i, SNDCHAN_LOL, _, _, vol, pitch);
		}
	}
}

/***********************************************************/
/*********************** HOOK COMMANDS *********************/
/***********************************************************/
void HookCommands()
{
	for(int i = 0; i < max_command; i++) 
	{
		if(StrEqual(S_Command[i], ""))
		{
			continue;
		}
		
		RegConsoleCmd(S_Command[i], Callback_Empty);
		AddCommandListener(Hook_Command, S_Command[i]);
		
		//LogMessage("%s AddCommandListener: %s", TAG_CHAT, S_Command[i]);
	}
}

/***********************************************************/
/********************* LOAD FILE SETTING *******************/
/***********************************************************/
public void LoadSettings()
{
	char hc[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, hc, sizeof(hc), "configs/drapi/sounds.cfg");
	
	Handle kv = CreateKeyValues("Sounds");
	FileToKeyValues(kv, hc);
	
	max_command = 0;
	
	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			if(KvGotoFirstSubKey(kv))
			{
				do
				{
					KvGetSectionName(kv, S_Command[max_command], 64);
					//LogMessage("%s Command: %s", TAG_CHAT, S_Command[max_command]);
					
					KvGetString(kv, "sound", S_Command_sound[max_command], 64);
					//LogMessage("%s Sound: %s", TAG_CHAT, S_Command_sound[max_command]);
					
					max_command++;
				}
				while (KvGotoNextKey(kv));
			}
			
			KvGoBack(kv);
			
		}
		while (KvGotoNextKey(kv));
	}
	CloseHandle(kv);
}

/***********************************************************/
/******************** ADD SOUND TO CACHE *******************/
/***********************************************************/
stock void FakePrecacheSound(const char[] szPath)
{
	AddToStringTable( FindStringTable( "soundprecache" ), szPath );
}

/***********************************************************/
/****************** FAKE AND DOWNLOAD SOUND ****************/
/***********************************************************/
stock void FakeAndDownloadSound(bool log, const char[][] stocksound, int num)
{
	for (int i = 0; i < num; i++)
	{
		char FULL_SOUND_PATH[PLATFORM_MAX_PATH];
		Format(FULL_SOUND_PATH, PLATFORM_MAX_PATH, "sound/%s", stocksound[i]);
		AddFileToDownloadsTable(FULL_SOUND_PATH);
		
		char RELATIVE_SOUND_PATH[PLATFORM_MAX_PATH];
		Format(RELATIVE_SOUND_PATH, PLATFORM_MAX_PATH, "*%s", stocksound[i]);
		FakePrecacheSound(RELATIVE_SOUND_PATH);
		
		if(log)
		{
			LogMessage("AddFileToDownloadsTable: %s, FakePrecacheSound: %s", FULL_SOUND_PATH, RELATIVE_SOUND_PATH);
		}
	}
}

/***********************************************************/
/******************** CHECK IF IS A VIP ********************/
/***********************************************************/
stock bool IsVip(int client)
{
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM2 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM3 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM4 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM5 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
	{
		return true;
	}
	return false;
}

/***********************************************************/
/****************** CHECK IF IS AN ADMIN *******************/
/***********************************************************/
stock bool IsAdminEx(int client)
{
	if(GetUserFlagBits(client) & ADMFLAG_CHANGEMAP 
	/*|| GetUserFlagBits(client) & ADMFLAG_RESERVATION*/
	|| GetUserFlagBits(client) & ADMFLAG_GENERIC
	|| GetUserFlagBits(client) & ADMFLAG_KICK
	|| GetUserFlagBits(client) & ADMFLAG_BAN
	|| GetUserFlagBits(client) & ADMFLAG_UNBAN
	|| GetUserFlagBits(client) & ADMFLAG_SLAY
	|| GetUserFlagBits(client) & ADMFLAG_CHANGEMAP
	|| GetUserFlagBits(client) & ADMFLAG_CONVARS
	|| GetUserFlagBits(client) & ADMFLAG_CONFIG
	|| GetUserFlagBits(client) & ADMFLAG_CHAT
	|| GetUserFlagBits(client) & ADMFLAG_VOTE
	|| GetUserFlagBits(client) & ADMFLAG_PASSWORD
	|| GetUserFlagBits(client) & ADMFLAG_RCON
	|| GetUserFlagBits(client) & ADMFLAG_CHEATS
	|| GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		return true;
	}
	return false;
}