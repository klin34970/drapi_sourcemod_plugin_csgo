/*    <DR.API JOIN SOUNDS> (c) by <De Battista Clint - (http://doyou.watch)  */
/*                                                                           */
/*                  <DR.API JOIN SOUNDS> is licensed under a                 */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//****************************DR.API JOIN SOUNDS*****************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0.1"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[JOIN SOUNDS] -"
#define MAX_SOUNDS						15
#define	SNDCHAN_JOIN					101

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <autoexec>
#include <csgocolors>
#include <emitsoundany>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_join_sounds_dev;

Handle cvar_join_sounds_join_admin_tchat;
Handle cvar_join_sounds_join_vip_tchat;
Handle cvar_join_sounds_join_admin_sound;
Handle cvar_join_sounds_join_vip_sound;

Handle cvar_join_sounds_leave_admin_tchat;
Handle cvar_join_sounds_leave_vip_tchat;
Handle cvar_join_sounds_leave_admin_sound;
Handle cvar_join_sounds_leave_vip_sound;

Handle CookieJoinAdminTchat;
Handle CookieJoinVipTchat;
Handle CookieJoinAdminSound;
Handle CookieJoinVipSound;

Handle CookieLeaveAdminTchat;
Handle CookieLeaveVipTchat;
Handle CookieLeaveAdminSound;
Handle CookieLeaveVipSound;

//Bool
bool B_active_join_sounds_dev					= false;

bool B_join_sounds_join_admin_tchat				= false;
bool B_join_sounds_join_vip_tchat				= false;
bool B_join_sounds_join_admin_sound				= false;
bool B_join_sounds_join_vip_sound				= false;

bool B_join_sounds_leave_admin_tchat			= false;
bool B_join_sounds_leave_vip_tchat				= false;
bool B_join_sounds_leave_admin_sound			= false;
bool B_join_sounds_leave_vip_sound				= false;

//Strings
char S_soundadminjoin[MAX_SOUNDS][PLATFORM_MAX_PATH];
char S_soundvipjoin[MAX_SOUNDS][PLATFORM_MAX_PATH];

char S_soundadminleave[MAX_SOUNDS][PLATFORM_MAX_PATH];
char S_soundvipleave[MAX_SOUNDS][PLATFORM_MAX_PATH];

//Customs
int max_sounds_admin_join;
int max_sounds_vip_join;

int max_sounds_admin_leave;
int max_sounds_vip_leave;

int C_show_join_admin_tchat[MAXPLAYERS + 1];
int C_show_join_vip_tchat[MAXPLAYERS + 1];
int C_show_join_admin_sound[MAXPLAYERS + 1];
int C_show_join_vip_sound[MAXPLAYERS + 1];

int C_show_leave_admin_tchat[MAXPLAYERS + 1];
int C_show_leave_vip_tchat[MAXPLAYERS + 1];
int C_show_leave_admin_sound[MAXPLAYERS + 1];
int C_show_leave_vip_sound[MAXPLAYERS + 1];

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API JOIN SOUNDS",
	author = "Dr. Api",
	description = "DR.API JOIN SOUNDS by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://zombie4ever.eu"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	LoadTranslations("drapi/drapi_join_sounds.phrases");
	AutoExecConfig_SetFile("drapi_join_sounds", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_join_sounds_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_join_sounds_dev				= AutoExecConfig_CreateConVar("drapi_active_join_sounds_dev", 				"0", 					"Enable/Disable Dev Mod", 						DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	cvar_join_sounds_join_admin_tchat		= AutoExecConfig_CreateConVar("drapi_join_sounds_join_admin_tchat", 		"1", 					"Enable/Disable Admin message join", 		DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	cvar_join_sounds_join_vip_tchat			= AutoExecConfig_CreateConVar("drapi_join_sounds_join_vip_tchat", 			"1", 					"Enable/Disable Vip message join", 			DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);	
	cvar_join_sounds_join_admin_sound		= AutoExecConfig_CreateConVar("drapi_join_sounds_join_admin_sound", 		"1", 					"Enable/Disable Admin sound join", 			DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	cvar_join_sounds_join_vip_sound			= AutoExecConfig_CreateConVar("drapi_join_sounds_join_vip_sound", 			"1", 					"Enable/Disable Admin sound join", 			DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	cvar_join_sounds_leave_admin_tchat		= AutoExecConfig_CreateConVar("drapi_join_sounds_leave_admin_tchat", 		"1", 					"Enable/Disable Admin message leave", 		DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	cvar_join_sounds_leave_vip_tchat		= AutoExecConfig_CreateConVar("drapi_join_sounds_leave_vip_tchat", 			"1", 					"Enable/Disable Vip message leave", 		DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	cvar_join_sounds_leave_admin_sound		= AutoExecConfig_CreateConVar("drapi_join_sounds_leave_admin_sound", 		"1", 					"Enable/Disable Admin sound leave", 		DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	cvar_join_sounds_leave_vip_sound		= AutoExecConfig_CreateConVar("drapi_join_sounds_leave_vip_sound", 			"1", 					"Enable/Disable Vip sound leave", 			DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	HookEvents();
	
	AutoExecConfig_ExecuteFile();
	
	//RegAdminCmd("sm_jadmin", Command_JoinAdmin, ADMFLAG_CHANGEMAP, "");
	//RegAdminCmd("sm_ladmin", Command_LeaveAdmin, ADMFLAG_CHANGEMAP, "");
	
	//RegAdminCmd("sm_jvip", Command_JoinAdmin, ADMFLAG_CUSTOM1, "");
	//RegAdminCmd("sm_lvip", Command_LeaveAdmin, ADMFLAG_CUSTOM1, "");
	
	RegConsoleCmd("sm_js", Command_JoinSounds, "Menu client preferences");
	
	CookieJoinAdminTchat 	= RegClientCookie("CookieJoinAdminTchat", "", CookieAccess_Private);
	CookieJoinVipTchat		= RegClientCookie("CookieJoinVipTchat", "", CookieAccess_Private);
	CookieJoinAdminSound	= RegClientCookie("CookieJoinAdminSound", "", CookieAccess_Private);
	CookieJoinVipSound		= RegClientCookie("CookieJoinVipSound", "", CookieAccess_Private);

	CookieLeaveAdminTchat	= RegClientCookie("CookieLeaveAdminTchat", "", CookieAccess_Private);
	CookieLeaveVipTchat		= RegClientCookie("CookieLeaveVipTchat", "", CookieAccess_Private);
	CookieLeaveAdminSound	= RegClientCookie("CookieLeaveAdminSound", "", CookieAccess_Private);
	CookieLeaveVipSound		= RegClientCookie("CookieLeaveVipSound", "", CookieAccess_Private);
	
	int info;
	SetCookieMenuItem(JoinSoundsCookieHandler, info, "Join Sounds");
	
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
	CreateTimer(2.0, Timer_JoinSoundAndMessage, client);
	
}

public Action Timer_JoinSoundAndMessage(Handle timer, any client)
{
	JoinSoundAndMessage(client);
}

/***********************************************************/
/***************** WHEN CLIENT DISCONNECT ******************/
/***********************************************************/
public void OnClientDisconnect(int client)
{
	LeaveSoundAndMessage(client);
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEvents()
{
	HookConVarChange(cvar_active_join_sounds_dev, 				Event_CvarChange);
	
	HookConVarChange(cvar_join_sounds_join_admin_tchat, 		Event_CvarChange);
	HookConVarChange(cvar_join_sounds_join_vip_tchat, 			Event_CvarChange);
	HookConVarChange(cvar_join_sounds_join_admin_sound, 		Event_CvarChange);
	HookConVarChange(cvar_join_sounds_join_vip_sound, 			Event_CvarChange);
	
	HookConVarChange(cvar_join_sounds_leave_admin_tchat, 		Event_CvarChange);
	HookConVarChange(cvar_join_sounds_leave_vip_tchat, 			Event_CvarChange);
	HookConVarChange(cvar_join_sounds_leave_admin_sound, 		Event_CvarChange);
	HookConVarChange(cvar_join_sounds_leave_vip_sound, 			Event_CvarChange);
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
	B_active_join_sounds_dev 					= GetConVarBool(cvar_active_join_sounds_dev);
	
	B_join_sounds_join_admin_tchat 				= GetConVarBool(cvar_join_sounds_join_admin_tchat);
	B_join_sounds_join_vip_tchat 				= GetConVarBool(cvar_join_sounds_join_vip_tchat);
	B_join_sounds_join_admin_sound 				= GetConVarBool(cvar_join_sounds_join_admin_sound);
	B_join_sounds_join_vip_sound 				= GetConVarBool(cvar_join_sounds_join_vip_sound);
	
	B_join_sounds_leave_admin_tchat 			= GetConVarBool(cvar_join_sounds_leave_admin_tchat);
	B_join_sounds_leave_vip_tchat 				= GetConVarBool(cvar_join_sounds_leave_vip_tchat);
	B_join_sounds_leave_admin_sound 			= GetConVarBool(cvar_join_sounds_leave_admin_sound);
	B_join_sounds_leave_vip_sound 				= GetConVarBool(cvar_join_sounds_leave_vip_sound);
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
/******************** CMD SOUND ADMIN **********************/
/***********************************************************/
public Action Command_JoinAdmin(int client, int args)
{
	JoinSoundAndMessage(client);
	return Plugin_Handled;
}

/***********************************************************/
/******************** CMD SOUND ADMIN **********************/
/***********************************************************/
public Action Command_LeaveAdmin(int client, int args)
{
	LeaveSoundAndMessage(client);
	return Plugin_Handled;
}

/***********************************************************/
/********************* CMD JOIN SOUND **********************/
/***********************************************************/
public Action Command_JoinSounds(int client, int args)
{
	BuildMenuJoinSounds(client);
	return Plugin_Handled;
}

/***********************************************************/
/**************** ON CLIENT COOKIE CACHED ******************/
/***********************************************************/
public void OnClientCookiesCached(int client)
{
	CookiesJoin(client);
	CookiesLeave(client);
	
}

/***********************************************************/
/********************** MENU SETTINGS **********************/
/***********************************************************/
public void JoinSoundsCookieHandler(int client, CookieMenuAction action, any info, char [] buffer, int maxlen)
{
	BuildMenuJoinSounds(client);
} 

/***********************************************************/
/***************** BUILD MENU JOIN SOUNDS ******************/
/***********************************************************/
void BuildMenuJoinSounds(int client)
{
	char title[40], tchat[40], sounds[40];
	
	Menu menu = CreateMenu(MenuJoinSoundsAction);
	
	Format(tchat, sizeof(tchat), "%T", "MenuJoinSounds_TCHAT_MENU_TITLE", client);
	AddMenuItem(menu, "M_tchat", tchat);
	
	Format(sounds, sizeof(sounds), "%T", "MenuJoinSounds_SOUNDS_MENU_TITLE", client);
	AddMenuItem(menu, "M_sounds", sounds);
	
	Format(title, sizeof(title), "%T", "MenuJoinSounds_TITLE", client);
	menu.SetTitle(title);
	SetMenuExitBackButton(menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
}

/***********************************************************/
/**************** MENU ACTION JOIN SOUNDS ******************/
/***********************************************************/
public int MenuJoinSoundsAction(Menu menu, MenuAction action, int param1, int param2)
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
			
			if(StrEqual(menu1, "M_tchat"))
			{
				BuildMenuJoinSoundsTchat(param1);
			}
			else if(StrEqual(menu1, "M_sounds"))
			{
				BuildMenuJoinSoundsSound(param1);
			}
		}
	}
}

/***********************************************************/
/************** BUILD MENU JOIN SOUNDS TCHAT ***************/
/***********************************************************/
void BuildMenuJoinSoundsTchat(int client)
{
	char title[40], join_admin[40], join_vip[40], leave_admin[40], leave_vip[40], status_join_admin[40], status_join_vip[40], status_leave_admin[40], status_leave_vip[40];
	
	Menu menu = CreateMenu(MenuJoinSoundsTchatAction);
	
	Format(status_join_admin, sizeof(status_join_admin), "%T", (C_show_join_admin_tchat[client]) ? "Enabled" : "Disabled", client);
	Format(join_admin, sizeof(join_admin), "%T", "MenuJoinSoundsTchat_ADMIN_JOIN_MENU_TITLE", client, status_join_admin);
	AddMenuItem(menu, "M_tchat_join_admin", join_admin);
	
	Format(status_join_vip, sizeof(status_join_vip), "%T", (C_show_join_vip_tchat[client]) ? "Enabled" : "Disabled", client);
	Format(join_vip, sizeof(join_vip), "%T", "MenuJoinSoundsTchat_VIP_JOIN_MENU_TITLE", client, status_join_vip);
	AddMenuItem(menu, "M_tchat_join_vip", join_vip);
	
	Format(status_leave_admin, sizeof(status_leave_admin), "%T", (C_show_leave_admin_tchat[client]) ? "Enabled" : "Disabled", client);
	Format(leave_admin, sizeof(leave_admin), "%T", "MenuJoinSoundsTchat_ADMIN_LEAVE_MENU_TITLE", client, status_leave_admin);
	AddMenuItem(menu, "M_tchat_leave_admin", leave_admin);
	
	Format(status_leave_vip, sizeof(status_leave_vip), "%T", (C_show_leave_vip_tchat[client]) ? "Enabled" : "Disabled", client);
	Format(leave_vip, sizeof(leave_vip), "%T", "MenuJoinSoundsTchat_VIP_LEAVE_MENU_TITLE", client, status_leave_vip);
	AddMenuItem(menu, "M_tchat_leave_vip", leave_vip);
	
	
	Format(title, sizeof(title), "%T", "MenuJoinSoundsTchat_TITLE", client);
	menu.SetTitle(title);
	SetMenuExitBackButton(menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
}

/***********************************************************/
/************* MENU ACTION JOIN SOUNDS TCHAT ***************/
/***********************************************************/
public int MenuJoinSoundsTchatAction(Menu menu, MenuAction action, int param1, int param2)
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
				BuildMenuJoinSounds(param1);
			}
		}
		case MenuAction_Select:
		{
			char menu1[56];
			menu.GetItem(param2, menu1, sizeof(menu1));
			
			if(StrEqual(menu1, "M_tchat_join_admin"))
			{
				C_show_join_admin_tchat[param1] = !C_show_join_admin_tchat[param1];
				SetClientCookie(param1, CookieJoinAdminTchat, (C_show_join_admin_tchat[param1]) ? "1" : "0");
			}
			else if(StrEqual(menu1, "M_tchat_join_vip"))
			{	
				C_show_join_vip_tchat[param1] = !C_show_join_vip_tchat[param1];
				SetClientCookie(param1, CookieJoinVipTchat, (C_show_join_vip_tchat[param1]) ? "1" : "0");
			}
			else if(StrEqual(menu1, "M_tchat_leave_admin"))
			{
				C_show_leave_admin_tchat[param1] = !C_show_leave_admin_tchat[param1];
				SetClientCookie(param1, CookieLeaveAdminTchat, (C_show_leave_admin_tchat[param1]) ? "1" : "0");
			}
			else if(StrEqual(menu1, "M_tchat_leave_vip"))
			{
				C_show_leave_vip_tchat[param1] = !C_show_leave_vip_tchat[param1];
				SetClientCookie(param1, CookieLeaveVipTchat, (C_show_leave_vip_tchat[param1]) ? "1" : "0");
			}
			BuildMenuJoinSoundsTchat(param1);
		}
	}
}

/***********************************************************/
/************** BUILD MENU JOIN SOUNDS SOUND ***************/
/***********************************************************/
void BuildMenuJoinSoundsSound(int client)
{
	char title[40], join_admin[40], join_vip[40], leave_admin[40], leave_vip[40], status_join_admin[40], status_join_vip[40], status_leave_admin[40], status_leave_vip[40];
	
	Menu menu = CreateMenu(MenuJoinSoundsSoundAction);
	
	Format(status_join_admin, sizeof(status_join_admin), "%T", (C_show_join_admin_sound[client]) ? "Enabled" : "Disabled", client);
	Format(join_admin, sizeof(join_admin), "%T", "MenuJoinSoundsSound_ADMIN_JOIN_MENU_TITLE", client, status_join_admin);
	AddMenuItem(menu, "M_sound_join_admin", join_admin);
	
	Format(status_join_vip, sizeof(status_join_vip), "%T", (C_show_join_vip_sound[client]) ? "Enabled" : "Disabled", client);
	Format(join_vip, sizeof(join_vip), "%T", "MenuJoinSoundsSound_VIP_JOIN_MENU_TITLE", client, status_join_vip);
	AddMenuItem(menu, "M_sound_join_vip", join_vip);
	
	Format(status_leave_admin, sizeof(status_leave_admin), "%T", (C_show_leave_admin_sound[client]) ? "Enabled" : "Disabled", client);
	Format(leave_admin, sizeof(leave_admin), "%T", "MenuJoinSoundsSound_ADMIN_LEAVE_MENU_TITLE", client, status_leave_admin);
	AddMenuItem(menu, "M_sound_leave_admin", leave_admin);
	
	Format(status_leave_vip, sizeof(status_leave_vip), "%T", (C_show_leave_vip_sound[client]) ? "Enabled" : "Disabled", client);
	Format(leave_vip, sizeof(leave_vip), "%T", "MenuJoinSoundsSound_VIP_LEAVE_MENU_TITLE", client, status_leave_vip);
	AddMenuItem(menu, "M_sound_leave_vip", leave_vip);
	
	
	Format(title, sizeof(title), "%T", "MenuJoinSoundsSound_TITLE", client);
	menu.SetTitle(title);
	SetMenuExitBackButton(menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
}

/***********************************************************/
/************* MENU ACTION JOIN SOUNDS SOUND ***************/
/***********************************************************/
public int MenuJoinSoundsSoundAction(Menu menu, MenuAction action, int param1, int param2)
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
				BuildMenuJoinSounds(param1);
			}
		}
		case MenuAction_Select:
		{
			char menu1[56];
			menu.GetItem(param2, menu1, sizeof(menu1));
			
			if(StrEqual(menu1, "M_sound_join_admin"))
			{
				C_show_join_admin_sound[param1] = !C_show_join_admin_sound[param1];
				SetClientCookie(param1, CookieJoinAdminSound, (C_show_join_admin_sound[param1]) ? "1" : "0");
			}
			else if(StrEqual(menu1, "M_sound_join_vip"))
			{	
				C_show_join_vip_sound[param1] = !C_show_join_vip_sound[param1];
				SetClientCookie(param1, CookieJoinVipSound, (C_show_join_vip_sound[param1]) ? "1" : "0");
			}
			else if(StrEqual(menu1, "M_sound_leave_admin"))
			{
				C_show_leave_admin_sound[param1] = !C_show_leave_admin_sound[param1];
				SetClientCookie(param1, CookieLeaveAdminSound, (C_show_leave_admin_sound[param1]) ? "1" : "0");
			}
			else if(StrEqual(menu1, "M_sound_leave_vip"))
			{
				C_show_leave_vip_sound[param1] = !C_show_leave_vip_sound[param1];
				SetClientCookie(param1, CookieLeaveVipSound, (C_show_leave_vip_sound[param1]) ? "1" : "0");
			}
			BuildMenuJoinSoundsSound(param1);
		}
	}
}




/***********************************************************/
/********************** LOAD SETTINGS **********************/
/***********************************************************/
public void LoadSettings()
{
	char hc[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, hc, sizeof(hc), "configs/drapi/join_sounds.cfg");
	
	Handle kv = CreateKeyValues("Sounds");
	FileToKeyValues(kv, hc);
	
	max_sounds_admin_join 		= 1;
	max_sounds_vip_join 		= 1;	
	max_sounds_admin_leave 		= 1;
	max_sounds_vip_leave 		= 1;
	
	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			if(KvJumpToKey(kv, "AdminJoin"))
			{
				for(int i = 1; i <= MAX_SOUNDS; ++i)
				{
					char key[64];
					IntToString(i, key, 64);
					
					if(KvGetString(kv, key, S_soundadminjoin[i], PLATFORM_MAX_PATH) && strlen(S_soundadminjoin[i]))
					{
						char FULL_SOUND_PATH[PLATFORM_MAX_PATH];
						Format(FULL_SOUND_PATH, PLATFORM_MAX_PATH, "sound/%s", S_soundadminjoin[i]);
						AddFileToDownloadsTable(FULL_SOUND_PATH);
						
						char RELATIVE_SOUND_PATH[PLATFORM_MAX_PATH];
						Format(RELATIVE_SOUND_PATH, PLATFORM_MAX_PATH, "*%s", S_soundadminjoin[i]);
						FakePrecacheSound(RELATIVE_SOUND_PATH);
						
						if(B_active_join_sounds_dev)
						{
							LogMessage("ADMINJOIN - [%i] - AddFileToDownloadsTable: %s, FakePrecacheSound: %s", i, FULL_SOUND_PATH, RELATIVE_SOUND_PATH);
						}
						
						max_sounds_admin_join++;
					}
					else
					{
						break;
					}
					
				}
				KvGoBack(kv);
			}
			
			if(KvJumpToKey(kv, "AdminLeave"))
			{
				for(int i = 1; i <= MAX_SOUNDS; ++i)
				{
					char key[64];
					IntToString(i, key, 64);
					
					if(KvGetString(kv, key, S_soundadminleave[i], PLATFORM_MAX_PATH) && strlen(S_soundadminleave[i]))
					{
						char FULL_SOUND_PATH[PLATFORM_MAX_PATH];
						Format(FULL_SOUND_PATH, PLATFORM_MAX_PATH, "sound/%s", S_soundadminleave[i]);
						AddFileToDownloadsTable(FULL_SOUND_PATH);
						
						char RELATIVE_SOUND_PATH[PLATFORM_MAX_PATH];
						Format(RELATIVE_SOUND_PATH, PLATFORM_MAX_PATH, "*%s", S_soundadminleave[i]);
						FakePrecacheSound(RELATIVE_SOUND_PATH);
						
						if(B_active_join_sounds_dev)
						{
							LogMessage("ADMINLEAVE - [%i] - AddFileToDownloadsTable: %s, FakePrecacheSound: %s", i, FULL_SOUND_PATH, RELATIVE_SOUND_PATH);
						}
						
						max_sounds_admin_leave++;
					}
					else
					{
						break;
					}
					
				}
				KvGoBack(kv);
			}
			
			if(KvJumpToKey(kv, "VipJoin"))
			{
				for(int i = 1; i <= MAX_SOUNDS; ++i)
				{
					char key[64];
					IntToString(i, key, 64);
					
					if(KvGetString(kv, key, S_soundvipjoin[i], 64) && strlen(S_soundvipjoin[i]))
					{
						char FULL_SOUND_PATH[PLATFORM_MAX_PATH];
						Format(FULL_SOUND_PATH, PLATFORM_MAX_PATH, "sound/%s", S_soundvipjoin[i]);
						AddFileToDownloadsTable(FULL_SOUND_PATH);
						
						char RELATIVE_SOUND_PATH[PLATFORM_MAX_PATH];
						Format(RELATIVE_SOUND_PATH, PLATFORM_MAX_PATH, "*%s", S_soundvipjoin[i]);
						FakePrecacheSound(RELATIVE_SOUND_PATH);
						
						if(B_active_join_sounds_dev)
						{
							LogMessage("VIPJOIN - [%i] - AddFileToDownloadsTable: %s, FakePrecacheSound: %s", i, FULL_SOUND_PATH, RELATIVE_SOUND_PATH);
						}
						
						max_sounds_vip_join++;
					}
					else
					{
						break;
					}
					
				}
				KvGoBack(kv);
			}
			
			if(KvJumpToKey(kv, "VipLeave"))
			{
				for(int i = 1; i <= MAX_SOUNDS; ++i)
				{
					char key[64];
					IntToString(i, key, 64);
					
					if(KvGetString(kv, key, S_soundvipleave[i], 64) && strlen(S_soundvipleave[i]))
					{
						char FULL_SOUND_PATH[PLATFORM_MAX_PATH];
						Format(FULL_SOUND_PATH, PLATFORM_MAX_PATH, "sound/%s", S_soundvipleave[i]);
						AddFileToDownloadsTable(FULL_SOUND_PATH);
						
						char RELATIVE_SOUND_PATH[PLATFORM_MAX_PATH];
						Format(RELATIVE_SOUND_PATH, PLATFORM_MAX_PATH, "*%s", S_soundvipleave[i]);
						FakePrecacheSound(RELATIVE_SOUND_PATH);
						
						if(B_active_join_sounds_dev)
						{
							LogMessage("VIPLEAVE - [%i] - AddFileToDownloadsTable: %s, FakePrecacheSound: %s", i, FULL_SOUND_PATH, RELATIVE_SOUND_PATH);
						}
						
						max_sounds_vip_leave++;
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
/************************ COOKIES JOIN *********************/
/***********************************************************/
void CookiesJoin(int client)
{
	char value[16];
	
	GetClientCookie(client, CookieJoinAdminTchat, value, sizeof(value));
	if(strlen(value) > 0) 
	{
		C_show_join_admin_tchat[client] = StringToInt(value);
	}
	else 
	{
		C_show_join_admin_tchat[client] = 1;
	}
   
	GetClientCookie(client, CookieJoinVipTchat, value, sizeof(value));
	if(strlen(value) > 0) 
	{
		C_show_join_vip_tchat[client] = StringToInt(value);
	}
	else 
	{
		C_show_join_vip_tchat[client] = 1;
	}
	
	GetClientCookie(client, CookieJoinAdminSound, value, sizeof(value));
	if(strlen(value) > 0) 
	{
		C_show_join_admin_sound[client] = StringToInt(value);
	}
	else 
	{
		C_show_join_admin_sound[client] = 1;
	}
	
	GetClientCookie(client, CookieJoinVipSound, value, sizeof(value));
	if(strlen(value) > 0) 
	{
		C_show_join_vip_sound[client] = StringToInt(value);
	}
	else 
	{
		C_show_join_vip_sound[client] = 1;
	}
}

/***********************************************************/
/************************ COOKIES JOIN *********************/
/***********************************************************/
void CookiesLeave(int client)
{
	char value[16];
	
	GetClientCookie(client, CookieLeaveAdminTchat, value, sizeof(value));
	if(strlen(value) > 0) 
	{
		C_show_leave_admin_tchat[client] = StringToInt(value);
	}
	else 
	{
		C_show_leave_admin_tchat[client] = 1;
	}
   
	GetClientCookie(client, CookieLeaveVipTchat, value, sizeof(value));
	if(strlen(value) > 0) 
	{
		C_show_leave_vip_tchat[client] = StringToInt(value);
	}
	else 
	{
		C_show_leave_vip_tchat[client] = 1;
	}
	
	GetClientCookie(client, CookieLeaveAdminSound, value, sizeof(value));
	if(strlen(value) > 0) 
	{
		C_show_leave_admin_sound[client] = StringToInt(value);
	}
	else 
	{
		C_show_leave_admin_sound[client] = 1;
	}
	
	GetClientCookie(client, CookieLeaveVipSound, value, sizeof(value));
	if(strlen(value) > 0) 
	{
		C_show_leave_vip_sound[client] = StringToInt(value);
	}
	else 
	{
		C_show_leave_vip_sound[client] = 1;
	}
}

/***********************************************************/
/******************* JOIN SOUND AND MESSAGE ****************/
/***********************************************************/
void JoinSoundAndMessage(int client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			if(IsAdminEx(client))
			{
				if(B_join_sounds_join_admin_sound && C_show_join_admin_sound[i])
				{
					if(max_sounds_admin_join > 1)
					{
						int num = GetRandomInt(1, max_sounds_admin_join - 1);
						EmitSoundToClientAny(i, S_soundadminjoin[num], i, SNDCHAN_JOIN, _, _, 1.0, _);
					}
				}
				
				if(B_join_sounds_join_admin_tchat && C_show_join_admin_tchat[i])
				{
					CPrintToChat(i, "%t", "Admin joined", client);
				}
			}	
			else if(IsVip(client))
			{
				if(B_join_sounds_join_vip_sound && C_show_join_vip_sound[i])
				{
					if(max_sounds_vip_join > 1)
					{
						int num = GetRandomInt(1, max_sounds_vip_join - 1);
						EmitSoundToClientAny(i, S_soundvipjoin[num], i, SNDCHAN_JOIN, _, _, 1.0, _);
					}
				}
				
				if(B_join_sounds_join_vip_tchat && C_show_join_vip_tchat[i])
				{
					CPrintToChat(i, "%t", "Vip joined", client);
				}
			}			
		}
	}
}

/***********************************************************/
/****************** LEAVE SOUND AND MESSAGE ****************/
/***********************************************************/
void LeaveSoundAndMessage(int client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			if(IsAdminEx(client))
			{
				if(B_join_sounds_leave_admin_sound && C_show_leave_admin_sound[i])
				{
					if(max_sounds_admin_leave > 1)
					{
						int num = GetRandomInt(1, max_sounds_admin_leave - 1);
						EmitSoundToClientAny(i, S_soundadminleave[num], i, SNDCHAN_JOIN, _, _, 1.0, _);
					}
				}
				
				if(B_join_sounds_leave_admin_tchat && C_show_leave_admin_tchat[i])
				{
					CPrintToChat(i, "%t", "Admin left", client);
				}
			}	
			else if(IsVip(client))
			{
				if(B_join_sounds_leave_vip_sound && C_show_leave_vip_sound[i])
				{
					if(max_sounds_vip_leave > 1)
					{
						int num = GetRandomInt(1, max_sounds_vip_leave - 1);
						EmitSoundToClientAny(i, S_soundvipleave[num], i, SNDCHAN_JOIN, _, _, 1.0, _);
					}
				}
				
				if(B_join_sounds_leave_vip_tchat && C_show_leave_vip_tchat[i])
				{
					CPrintToChat(i, "%t", "Vip left", client);
				}
			}			
		}
	}
}

/***********************************************************/
/******************** ADD SOUND TO CACHE *******************/
/***********************************************************/
stock void FakePrecacheSound(const char[] szPath)
{
	AddToStringTable( FindStringTable( "soundprecache" ), szPath );
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