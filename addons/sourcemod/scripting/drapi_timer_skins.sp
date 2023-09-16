/*   <DR.API TIMER SKINS> (c) by <De Battista Clint - (http://doyou.watch)   */
/*                                                                           */
/*                  <DR.API TIMER SKINS> is licensed under a                 */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//****************************DR.API TIMER SKINS*****************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[TIMER SKINS] -"
#define MAX_SKINSSECTION				10
#define MAX_SKINS						1000
//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <autoexec>
#include <timer>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_timer_skins_dev;

Handle CookieSkins;

//Bool
bool B_active_timer_skins_dev											= false;

//Strings
char S_modelsectionname[MAX_SKINSSECTION][64];
char S_modelname[MAX_SKINSSECTION][MAX_SKINS][64];
char S_modelpath[MAX_SKINSSECTION][MAX_SKINS][PLATFORM_MAX_PATH];

//Customs
int max_skinssection 													= 0;
int max_skin[MAX_SKINSSECTION] 											= 0;

//Informations plugin
public Plugin myinfo =
{
	name = "[TIMER] DR.API TIMER SKINS",
	author = "Dr. Api",
	description = "DR.API TIMER SKINS by Dr. Api",
	version = PL_VERSION,
	url = "http://zombie4ever.eu"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	LoadTranslations("drapi/drapi_timer_skins.phrases");
	AutoExecConfig_SetFile("drapi_timer_skins", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_timer_skins_version", PL_VERSION, "Version", CVARS);
	
	cvar_active_timer_skins_dev			= AutoExecConfig_CreateConVar("drapi_active_timer_skins_dev", 			"0", 					"Enable/Disable Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	HookEventsCvars();
	
	AutoExecConfig_ExecuteFile();
	
	CookieSkins		= RegClientCookie("Skins", "", CookieAccess_Private);
	int info;
	SetCookieMenuItem(SkinsCookieHandler, info, "Skins");
	
	HookEvent("player_spawn", 	Event_PlayerSpawn);
	
	RegConsoleCmd("sm_skin", Command_BuildMenuSkins);
	RegConsoleCmd("sm_skins", Command_BuildMenuSkins);
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEventsCvars()
{
	HookConVarChange(cvar_active_timer_skins_dev, 				Event_CvarChange);
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
	B_active_timer_skins_dev 					= GetConVarBool(cvar_active_timer_skins_dev);
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public void OnMapStart()
{
	LoadSettings();
	UpdateState();
}

/***********************************************************/
/******************* WHEN PLAYER SPAWN *********************/
/***********************************************************/
public void Event_PlayerSpawn(Handle event, char[] name, bool dontBroadcast)
{
	int client 				= GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsClientInGame(client) && IsPlayerAlive(client) &&  GetClientTeam(client) > 1)
	{
		CreateTimer(2.0, Timer_SetSkin, GetClientUserId(client));
	}
}

/***********************************************************/
/********************* TIMER SETSKIN ***********************/
/***********************************************************/
public Action Timer_SetSkin(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	
	if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client) &&  GetClientTeam(client) > 1)
	{
		if(!IsFakeClient(client))
		{
			char model[PLATFORM_MAX_PATH];
			GetClientCookie(client, CookieSkins, model, sizeof(model));
			if(strlen(model))
			{
				SetSkin(client, model);
			}
		}
		else
		{
			SetSkin(client, "models/player/valet/valet_fix.mdl");
		}
	}
}

/***********************************************************/
/********************** MENU SETTINGS **********************/
/***********************************************************/
public void SkinsCookieHandler(int client, CookieMenuAction action, any info, char [] buffer, int maxlen)
{
	BuildMenuSkins(client);
} 

/***********************************************************/
/********************** MENU SPRITES ***********************/
/***********************************************************/
public Action Command_BuildMenuSkins(int client, int args)
{
	BuildMenuSkins(client);
}

/***********************************************************/
/******************** BUILD MENU SKINS *********************/
/***********************************************************/
void BuildMenuSkins(int client)
{
	char title[40], sectionname[40];
	Menu menu = CreateMenu(MenuSkinsAction);
	
	for(int section = 0; section <= max_skinssection-1; ++section)
	{
		Format(sectionname, sizeof(sectionname), "%T", S_modelsectionname[section], client);
		AddMenuItem(menu, S_modelsectionname[section], sectionname);
	}
	
	Format(title, sizeof(title), "%T", "MenuSkins_TITLE", client);
	menu.SetTitle(title);
	SetMenuExitBackButton(menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
}

/***********************************************************/
/****************** MENU ACTION SKINS **********************/
/***********************************************************/
public int MenuSkinsAction(Menu menu, MenuAction action, int param1, int param2)
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
			
			for(int section = 0; section <= max_skinssection-1; ++section)
			{
				if(StrEqual(menu1, S_modelsectionname[section]))
				{
					BuildMenuSkinsBySection(param1, section);
				}
			}
		}
	}
}

/***********************************************************/
/************** BUILD MENU SKINS BY SECTION ****************/
/***********************************************************/
void BuildMenuSkinsBySection(int client, int section)
{
	char title[40];
	Menu menu = CreateMenu(MenuSkinsBySectionAction);
	
	for(int skin = 0; skin <= max_skin[section]; ++skin)
	{
		AddMenuItem(menu, S_modelpath[section][skin], S_modelname[section][skin]);
	}
	
	Format(title, sizeof(title), "%T", "MenuSkinsBySection_TITLE", client);
	menu.SetTitle(title);
	SetMenuExitBackButton(menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
}

/***********************************************************/
/************ MENU ACTION SKINS BY SECTION *****************/
/***********************************************************/
public int MenuSkinsBySectionAction(Menu menu, MenuAction action, int param1, int param2)
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
				BuildMenuSkins(param1);
			}
		}
		case MenuAction_Select:
		{
			char menu1[PLATFORM_MAX_PATH];
			menu.GetItem(param2, menu1, sizeof(menu1));
			SetSkin(param1, menu1);
			BuildMenuSkins(param1);
			
			SetClientCookie(param1, CookieSkins, menu1);
		}
	}
}

/***********************************************************/
/*********************** SET SKIN **************************/
/***********************************************************/
void SetSkin(int client, char[] path)
{
	if(FileExists(path))
	{
		if(IsModelPrecached(path))
		{
			if(IsClientInGame(client) && GetClientTeam(client) > 1)
			{
				SetEntityModel(client, path);
			}
		}
		else
		{
			PrecacheModel(path, true);
			if(IsModelPrecached(path))
			{
				SetEntityModel(client, path);
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
	BuildPath(Path_SM, hc, sizeof(hc), "configs/drapi/timer_skins.cfg");
	
	Handle kv = CreateKeyValues("Skins");
	FileToKeyValues(kv, hc);
	
	max_skinssection 					= 0;
	max_skin[max_skinssection]			= 0;
	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			if(KvGetSectionName(kv, S_modelsectionname[max_skinssection], 64) && strlen(S_modelsectionname[max_skinssection]))
			{
				//LogMessage("[SECTION%i] NAME: %s", max_skinssection, S_modelsectionname[max_skinssection]);
				
				for(int skin = 0; skin <= MAX_SKINS; ++skin)
				{
					char name[64];
					Format(name, 64, "%i-name", skin);
					
					char path[64];
					Format(path, 64, "%i-path", skin);
					
					if((KvGetString(kv, name, S_modelname[max_skinssection][skin], 64) && strlen(S_modelname[max_skinssection][skin])) 
					&& (KvGetString(kv, path, S_modelpath[max_skinssection][skin], PLATFORM_MAX_PATH) && strlen(S_modelpath[max_skinssection][skin]))
					)
					{
						//LogMessage("[SECTION%i][%i] NAME: %s", max_skinssection, skin, S_modelname[max_skinssection][skin]);
						//LogMessage("[SECTION%i][%i] PATH: %s", max_skinssection, skin, S_modelpath[max_skinssection][skin]);
						PrecacheModel(S_modelpath[max_skinssection][skin], true);
						max_skin[max_skinssection] = skin;
					}
					else
					{
						break;
					}
				}
				
				max_skinssection++;	
			}
			else
			{
				break;
			}

		}
		while (KvGotoNextKey(kv));
	}
	CloseHandle(kv);
	
}