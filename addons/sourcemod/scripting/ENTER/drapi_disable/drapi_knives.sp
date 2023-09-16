/*      <DR.API KNIVES> (c) by <De Battista Clint - (http://doyou.watch)     */
/*                                                                           */
/*                     <DR.API KNIVES> is licensed under a                   */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//*******************************DR.API KNIVES*******************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.3.6"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[KNIVES] -"
#define MSG_LENGTH 						192
#define STORAGE_COOKIE					1
#define STORAGE_SQL						2

//***********************************//
//*************INCLUDE***************//
//***********************************//

#include <autoexec>
#include <clientprefs>
#include <csgocolors>
#include <cstrike>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#undef REQUIRE_PLUGIN
//#include <zombiereloaded>


#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_knives_dev;
Handle cvar_knives_ct_default;
Handle cvar_knives_t_default;

Handle cvar_knives_storage_mode;
Handle cvar_knives_access_mode;
Handle cvar_knives_give_mode;
Handle cvar_knives_check_knife_mode;

Handle Cookie_CTknife;
Handle Cookie_Tknife;

Handle hOnBuildMenuKnivesFirstPosition;
Handle hOnBuildMenuKnivesLastPosition;
Handle hOnBuildMenuKnivesAction;

Handle hOnBuildMenuKnivesCTFirstPosition;
Handle hOnBuildMenuKnivesCTLastPosition;
Handle hOnBuildMenuKnivesCTAction;

Handle hOnBuildMenuKnivesTFirstPosition;
Handle hOnBuildMenuKnivesTLastPosition;
Handle hOnBuildMenuKnivesTAction;

//Bool
bool B_active_knives_dev					= false;

//Customs
int C_knives_ct_default;
int C_knives_t_default;
int C_knives_storage_mode;
int C_knives_access_mode;
int C_knives_give_mode;
int C_knives_check_knife_mode;

int C_CTknife[MAXPLAYERS+1];
int C_Tknife[MAXPLAYERS+1];

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API KNIVES (zombie4ever.eu)",
	author = "Dr. Api",
	description = "DR.API KNIVES by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://zombie4ever.eu"
}

/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	LoadTranslations("drapi/drapi_knives.phrases");
	AutoExecConfig_SetFile("drapi_knives", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_knives_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_knives_dev			= AutoExecConfig_CreateConVar("drapi_active_knives_dev", 			"0", 					"Enable/Disable Dev Mod", 																			DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	cvar_knives_ct_default			= AutoExecConfig_CreateConVar("drapi_knives_ct_default", 			"512", 					"Default knife for CT", 																			DEFAULT_FLAGS);
	cvar_knives_t_default			= AutoExecConfig_CreateConVar("drapi_knives_t_default", 			"512", 					"Default knife for T", 																				DEFAULT_FLAGS);
	
	cvar_knives_storage_mode		= AutoExecConfig_CreateConVar("drapi_knives_storage_mode", 			"2", 					"0=Disable / 1=Cookie / 2=SQL", 																	DEFAULT_FLAGS);
	
	cvar_knives_access_mode			= AutoExecConfig_CreateConVar("drapi_knives_access_mode", 			"0", 					"0=All / 1=VIP / 2=ADMIN", 																			DEFAULT_FLAGS);
	
	cvar_knives_give_mode			= AutoExecConfig_CreateConVar("drapi_knives_give_mode", 			"1", 					"0=Don't give the knife / 1=Give the knife", 														DEFAULT_FLAGS);
	
	cvar_knives_check_knife_mode	= AutoExecConfig_CreateConVar("drapi_knives_check_knife_mode", 		"1", 					"Check the knife before giving away. SUCCESS if knife doesn't have a name", 						DEFAULT_FLAGS);
	
	HookEvents();
	
	AutoExecConfig_ExecuteFile();
	
	RegServerCmd("sm_create_knives_tables", 	Command_CreateTables);
	
	RegAdminCmd("sm_windex", 					Command_WeaponsIndex, 	ADMFLAG_CHANGEMAP, "");
	RegAdminCmd("sm_drop", 						Command_Drop, 			ADMFLAG_CHANGEMAP, "");
	
	AddCommandListener(Event_Say, "say");
	AddCommandListener(Event_Say, "say_team");
	
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if(IsClientInGame(i)) 
			{
				if(C_knives_storage_mode == STORAGE_COOKIE)
				{
					if(AreClientCookiesCached(i))
					{
						OnClientCookiesCached(i);
					}
				}
				SDKHook(i, SDKHook_WeaponEquip, OnPostWeaponEquip);
			}
		}
		i++;
	}
	
	hOnBuildMenuKnivesFirstPosition 		= CreateGlobalForward("OnBuildMenuKnivesFirstPosition", 	ET_Ignore, Param_Any);
	hOnBuildMenuKnivesLastPosition 			= CreateGlobalForward("OnBuildMenuKnivesLastPosition", 		ET_Ignore, Param_Any);
	hOnBuildMenuKnivesAction 				= CreateGlobalForward("OnBuildMenuKnivesAction", 			ET_Ignore, Param_Any, Param_Cell, Param_Cell);
	
	hOnBuildMenuKnivesCTFirstPosition 		= CreateGlobalForward("OnBuildMenuKnivesCTFirstPosition", 	ET_Ignore, Param_Any);
	hOnBuildMenuKnivesCTLastPosition 		= CreateGlobalForward("OnBuildMenuKnivesCTLastPosition", 	ET_Ignore, Param_Any);
	hOnBuildMenuKnivesCTAction 				= CreateGlobalForward("OnBuildMenuKnivesCTAction", 			ET_Ignore, Param_Any, Param_Cell, Param_Cell);
	
	hOnBuildMenuKnivesTFirstPosition 		= CreateGlobalForward("OnBuildMenuKnivesTFirstPosition", 	ET_Ignore, Param_Any);
	hOnBuildMenuKnivesTLastPosition 		= CreateGlobalForward("OnBuildMenuKnivesTLastPosition", 	ET_Ignore, Param_Any);
	hOnBuildMenuKnivesTAction 				= CreateGlobalForward("OnBuildMenuKnivesTAction", 			ET_Ignore, Param_Any, Param_Cell, Param_Cell);
}

/***********************************************************/
/************************ PLUGIN END ***********************/
/***********************************************************/
public void OnPluginEnd()
{
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			SDKUnhook(i, SDKHook_WeaponEquip, OnPostWeaponEquip);
		}
		i++;
	}
}

/***********************************************************/
/**************** WHEN CLIENT PUT IN SERVER ****************/
/***********************************************************/
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponEquip, OnPostWeaponEquip);
}

/***********************************************************/
/************** WHEN CLIENT POST ADMIN CHECK ***************/
/***********************************************************/
public void OnClientPostAdminCheck(int client)
{
	if(C_knives_storage_mode == STORAGE_SQL)
	{
		SQL_LoadPrefClients(client);
	}
}

/***********************************************************/
/***************** WHEN CLIENT DISCONNECT ******************/
/***********************************************************/
public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_WeaponEquip, OnPostWeaponEquip);
}

/***********************************************************/
/**************** ON CLIENT COOKIE CACHED ******************/
/***********************************************************/
public void OnClientCookiesCached(int client)
{
	if(C_knives_storage_mode == STORAGE_COOKIE)
	{
        char value[16];
		
        GetClientCookie(client, Cookie_CTknife, value, sizeof(value));
        if(strlen(value) > 0) 
		{
			C_CTknife[client] = StringToInt(value);
		}
        else 
		{
			C_CTknife[client] = 0;
		}
       
        GetClientCookie(client, Cookie_Tknife, value, sizeof(value));
        if(strlen(value) > 0) 
		{
			C_Tknife[client] = StringToInt(value);
		}
        else 
		{
			C_Tknife[client] = 0;
		}
	}
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEvents()
{
	HookConVarChange(cvar_active_knives_dev, 				Event_CvarChange);
	
	HookConVarChange(cvar_knives_ct_default, 				Event_CvarChange);
	HookConVarChange(cvar_knives_t_default, 				Event_CvarChange);
	
	HookConVarChange(cvar_knives_storage_mode, 				Event_CvarChange);
	
	HookConVarChange(cvar_knives_access_mode, 				Event_CvarChange);
	
	HookConVarChange(cvar_knives_give_mode, 				Event_CvarChange);
	
	HookConVarChange(cvar_knives_check_knife_mode, 			Event_CvarChange);
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
	B_active_knives_dev 						= GetConVarBool(cvar_active_knives_dev);
	
	C_knives_ct_default 						= GetConVarInt(cvar_knives_ct_default);
	C_knives_t_default 							= GetConVarInt(cvar_knives_t_default);
	
	C_knives_storage_mode 						= GetConVarInt(cvar_knives_storage_mode);
	
	C_knives_access_mode 						= GetConVarInt(cvar_knives_access_mode);
	
	C_knives_give_mode 							= GetConVarInt(cvar_knives_give_mode);
	
	C_knives_check_knife_mode 					= GetConVarInt(cvar_knives_check_knife_mode);
	
	if(C_knives_storage_mode == STORAGE_COOKIE)
	{
		Cookie_CTknife 					= RegClientCookie("Cookie_CTknife", "", CookieAccess_Private);
		Cookie_Tknife 					= RegClientCookie("Cookie_Tknife", "", CookieAccess_Private);
		
		int info;
		SetCookieMenuItem(KnivesCookieHandler, info, "Knives");
	}
	else if(C_knives_storage_mode == STORAGE_SQL)
	{
		SQL_LoadPrefAllClients();
	}
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
	UpdateState();
}

/***********************************************************/
/***************** ON POST WEAPON EQUIP ********************/
/***********************************************************/
public Action OnPostWeaponEquip(int client, int weapon)
{
	if(C_knives_access_mode == 0
	|| C_knives_access_mode == 1 && (IsVip(client) || IsAdminEx(client))
	|| C_knives_access_mode == 2 && IsAdminEx(client))
	{
		//IsFakeClient will not give knifes to bot, like that when you takeover a bot the knife will not drop
		char S_classname[64];
		if(IsFakeClient(client) || !GetEdictClassname(weapon, S_classname, sizeof(S_classname)) || StrContains(S_classname, "weapon_knife", false) != 0)
		{
			return;
		}
		
		/* Will check if the knife have a name aka "targetname". Usefull for minigames maps */
		if(C_knives_check_knife_mode)
		{
			char name[64];
			GetEntPropString(weapon, Prop_Data, "m_iName", name, sizeof(name));
			if(name[0])
			{
				CPrintToChat(client, "%t", "Knife Named", name);
				return;
			}
		}
			
		if(/*ZR_IsClientZombie(client)*/ GetClientTeam(client) == CS_TEAM_T)
		{
			if(C_Tknife[client] < 1)
			{
				int weaponindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
				
				if(weaponindex == 42 || weaponindex == 59)
				{					
					SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", C_knives_t_default);
				}
			}
			else 
			{
				SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", C_Tknife[client]);
			}	   
		}
		else if(/*ZR_IsClientHuman(client)*/ GetClientTeam(client) == CS_TEAM_CT)
		{
			if(C_CTknife[client] < 1)
			{
				int weaponindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
				
				if(weaponindex == 42 || weaponindex == 59)
				{					
					SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", C_knives_ct_default);
				}
			}
			else 
			{
				SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", C_CTknife[client]);
			}	   
		}
	}
}

/***********************************************************/
/*********************** EVENT SAY *************************/
/***********************************************************/
public Action Event_Say(int client, const char[] command, int args)
{

	if(C_knives_access_mode == 0
	|| C_knives_access_mode == 1 && (IsVip(client) || IsAdminEx(client))
	|| C_knives_access_mode == 2 && IsAdminEx(client))
	{
	
		char text[PLATFORM_MAX_PATH];
		GetCmdArgString(text, sizeof(text));
		
		StripQuotes(text);
		TrimString(text);
		if(!text[0])
		{
			return Plugin_Handled;
		}
		
		//MENU KNIVES GENERAL
		char knife[PLATFORM_MAX_PATH];
		Format(knife, sizeof(knife), "%t", "Knife Menu Command", client);
		
		char explode[20][PLATFORM_MAX_PATH];
		ExplodeString(knife, ", ", explode, sizeof explode, sizeof(explode));

		for(int cmd = 0; cmd < sizeof explode; cmd++)
		{
			char style1[PLATFORM_MAX_PATH], style2[PLATFORM_MAX_PATH];
			Format(style1, sizeof(style1), "!%s", explode[cmd]);
			Format(style2, sizeof(style2), "/%s", explode[cmd]);
			
			if(StrEqual(text, explode[cmd], false) || StrEqual(text, style1, false) && style1[1] || StrEqual(text, style2, false) && style2[1])
			{
				BuildMenuKnives(client);
				return Plugin_Handled;
			}
		}
		
		//MENU KNIVES CT
		char ct_knife[PLATFORM_MAX_PATH];
		Format(ct_knife, sizeof(ct_knife), "%t", "Knife Menu Command CT", client);
		
		char ct_explode[20][PLATFORM_MAX_PATH];
		ExplodeString(ct_knife, ", ", ct_explode, sizeof ct_explode, sizeof(ct_explode));

		for(int cmd = 0; cmd < sizeof ct_explode; cmd++)
		{
			char style1[PLATFORM_MAX_PATH], style2[PLATFORM_MAX_PATH];
			Format(style1, sizeof(style1), "!%s", ct_explode[cmd]);
			Format(style2, sizeof(style2), "/%s", ct_explode[cmd]);
			
			if(StrEqual(text, ct_explode[cmd], false) || StrEqual(text, style1, false) && style1[1] || StrEqual(text, style2, false) && style2[1])
			{
				BuildMenuKnivesCT(client);
				return Plugin_Handled;
			}
		}
		
		//MENU KNIVES T
		char t_knife[PLATFORM_MAX_PATH];
		Format(t_knife, sizeof(t_knife), "%t", "Knife Menu Command T", client);
		
		char t_explode[20][PLATFORM_MAX_PATH];
		ExplodeString(t_knife, ", ", t_explode, sizeof t_explode, sizeof(t_explode));

		for(int cmd = 0; cmd < sizeof t_explode; cmd++)
		{
			char style1[PLATFORM_MAX_PATH], style2[PLATFORM_MAX_PATH];
			Format(style1, sizeof(style1), "!%s", t_explode[cmd]);
			Format(style2, sizeof(style2), "/%s", t_explode[cmd]);
			
			if(StrEqual(text, t_explode[cmd], false) || StrEqual(text, style1, false) && style1[1] || StrEqual(text, style2, false) && style2[1])
			{
				BuildMenuKnivesT(client);
				return Plugin_Handled;
			}
		}
		
		GiveKnifeSayExplode(client, 	"Knife Menu Command Bayonet", 		"MenuKnives_BAYONET_MENU_TITLE", 	500, 	text);
		GiveKnifeSayExplode(client, 	"Knife Menu Command Flip", 			"MenuKnives_FLIP_MENU_TITLE", 		505, 	text);
		GiveKnifeSayExplode(client, 	"Knife Menu Command Gut", 			"MenuKnives_GUT_MENU_TITLE", 		506, 	text);
		GiveKnifeSayExplode(client, 	"Knife Menu Command Karambit", 		"MenuKnives_KARAMBIT_MENU_TITLE", 	507, 	text);
		GiveKnifeSayExplode(client, 	"Knife Menu Command M9Bayonet", 	"MenuKnives_M9BAYONET_MENU_TITLE", 	508, 	text);
		GiveKnifeSayExplode(client, 	"Knife Menu Command Huntsman", 		"MenuKnives_HUNTSMAN_MENU_TITLE", 	509, 	text);
		GiveKnifeSayExplode(client, 	"Knife Menu Command Falchion", 		"MenuKnives_FALCHION_MENU_TITLE", 	512, 	text);
		GiveKnifeSayExplode(client, 	"Knife Menu Command Butterfly", 	"MenuKnives_BUTTERFLY_MENU_TITLE", 	515, 	text);
	}
	return Plugin_Continue;
}
/***********************************************************/
/********************* GET WEAPON INDEX ********************/
/***********************************************************/
public Action Command_WeaponsIndex(int client, int args)
{
	int weapon 				= GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	int index 				= GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	
	PrintToChat(client, "index: %i", index);
	return Plugin_Handled;
}

/***********************************************************/
/********************* GET WEAPON INDEX ********************/
/***********************************************************/
public Action Command_Drop(int client, int args)
{
	int weapon 				= GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	
	DispatchKeyValue(weapon, "targetname", "putin");
	CS_DropWeapon(client, weapon, true, false);
	return Plugin_Handled;
}

/***********************************************************/
/********************* CMD MENU KNIVES *********************/
/***********************************************************/
public Action Command_BuildMenuKnives(int client, int args)
{
	BuildMenuKnives(client);
}

/***********************************************************/
/******************** CMD MENU KNIVES CT *******************/
/***********************************************************/
public Action Command_BuildMenuKnivesCT(int client, int args)
{
	BuildMenuKnivesCT(client);
}

/***********************************************************/
/******************** CMD MENU KNIVES T ********************/
/***********************************************************/
public Action Command_BuildMenuKnivesT(int client, int args)
{
	BuildMenuKnivesT(client);
}

/***********************************************************/
/********************** MENU SETTINGS **********************/
/***********************************************************/
public void KnivesCookieHandler(int client, CookieMenuAction action, any info, char [] buffer, int maxlen)
{
	BuildMenuKnives(client);
} 

/***********************************************************/
/******************* BUILD MENU KNIVES *********************/
/***********************************************************/
void BuildMenuKnives(int client)
{
	char title[40], ct[40], t[40];
	Menu menu = CreateMenu(MenuKnivesAction);
	
	Call_StartForward(hOnBuildMenuKnivesFirstPosition);
	Call_PushCell(menu);
	Call_Finish();
	
	Format(ct, sizeof(ct), "%T", "MenuKnives_CT_MENU_TITLE", client);
	AddMenuItem(menu, "M_CT", ct);
	
	Format(t, sizeof(t), "%T", "MenuKnives_T_MENU_TITLE", client);
	AddMenuItem(menu, "M_T", t);
	
	
	Call_StartForward(hOnBuildMenuKnivesLastPosition);
	Call_PushCell(menu);
	Call_Finish();
	
	Format(title, sizeof(title), "%T", "MenuKnives_TITLE", client);
	menu.SetTitle(title);
	SetMenuExitBackButton(menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
}

/***********************************************************/
/****************** MENU KNIVES ACTIONS ********************/
/***********************************************************/
public int MenuKnivesAction(Menu menu, MenuAction action, int param1, int param2)
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
			Call_StartForward(hOnBuildMenuKnivesAction);
			Call_PushCell(menu);
			Call_PushCell(param1);
			Call_PushCell(param2);
			Call_Finish();
			
			char menu1[56];
			menu.GetItem(param2, menu1, sizeof(menu1));
			
			if(StrEqual(menu1, "M_CT"))
			{
				BuildMenuKnivesCT(param1);
			}
			else if(StrEqual(menu1, "M_T"))
			{
				BuildMenuKnivesT(param1);
			}
		}
	}
}

/***********************************************************/
/******************* BUILD MENU KNIVES *********************/
/***********************************************************/
void BuildMenuKnivesCT(int client)
{
	char title[40], defaultknife[40], huntsman[40], karambit[40], gut[40], flip[40], m9bayonet[40], bayonet[40], falchion[40], butterfly[40];
	
	Menu menu = CreateMenu(MenuKnivesCTAction);
	
	Call_StartForward(hOnBuildMenuKnivesCTFirstPosition);
	Call_PushCell(menu);
	Call_Finish();
	
	Format(defaultknife, sizeof(defaultknife), "%T", "MenuKnives_DEFAULT_MENU_TITLE", client);
	AddMenuItem(menu, "0", defaultknife);
	
	Format(bayonet, sizeof(bayonet), "%T", "MenuKnives_BAYONET_MENU_TITLE", client);
	AddMenuItem(menu, "500", bayonet);
	
	Format(flip, sizeof(flip), "%T", "MenuKnives_FLIP_MENU_TITLE", client);
	AddMenuItem(menu, "505", flip);
	
	Format(gut, sizeof(gut), "%T", "MenuKnives_GUT_MENU_TITLE", client);
	AddMenuItem(menu, "506", gut);
	
	Format(karambit, sizeof(karambit), "%T", "MenuKnives_KARAMBIT_MENU_TITLE", client);
	AddMenuItem(menu, "507", karambit);
	
	Format(m9bayonet, sizeof(m9bayonet), "%T", "MenuKnives_M9BAYONET_MENU_TITLE", client);
	AddMenuItem(menu, "508", m9bayonet);
	
	Format(huntsman, sizeof(huntsman), "%T", "MenuKnives_HUNTSMAN_MENU_TITLE", client);
	AddMenuItem(menu, "509", huntsman);
	
	Format(falchion, sizeof(falchion), "%T", "MenuKnives_FALCHION_MENU_TITLE", client);
	AddMenuItem(menu, "512", falchion);
	
	Format(butterfly, sizeof(butterfly), "%T", "MenuKnives_BUTTERFLY_MENU_TITLE", client);
	AddMenuItem(menu, "515", butterfly);
	
	Call_StartForward(hOnBuildMenuKnivesCTLastPosition);
	Call_PushCell(menu);
	Call_Finish();
	
	Format(title, sizeof(title), "%T", "MenuKnivesCT_TITLE", client);
	menu.SetTitle(title);
	SetMenuExitBackButton(menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
}

/***********************************************************/
/****************** MENU KNIVES ACTIONS ********************/
/***********************************************************/
public int MenuKnivesCTAction(Menu menu, MenuAction action, int param1, int param2)
{
	if(C_knives_access_mode == 0
	|| C_knives_access_mode == 1 && (IsVip(param1) || IsAdminEx(param1))
	|| C_knives_access_mode == 2 && IsAdminEx(param1))
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
					BuildMenuKnives(param1);
				}		
			}
			case MenuAction_Select:
			{
				Call_StartForward(hOnBuildMenuKnivesCTAction);
				Call_PushCell(menu);
				Call_PushCell(param1);
				Call_PushCell(param2);
				Call_Finish();
					
				char item[56], weaponname[32];
				menu.GetItem(param2, item, sizeof(item));
				
				if(StrEqual(item, "0")
				|| StrEqual(item, "500")
				|| StrEqual(item, "505")
				|| StrEqual(item, "506")
				|| StrEqual(item, "507")
				|| StrEqual(item, "508")
				|| StrEqual(item, "509")
				|| StrEqual(item, "512")
				|| StrEqual(item, "515")
				)
				{
					int weaponindex 	= StringToInt(item);
					
					C_CTknife[param1]	= weaponindex;
					
					if(C_knives_storage_mode == STORAGE_COOKIE)
					{
						SetClientCookie(param1, Cookie_CTknife, item);
					}
					else if(C_knives_storage_mode == STORAGE_SQL)
					{
						if(IsClientAuthorized(param1))
						{
							Database db = Connect();
							if (db != null)
							{
								char steamId[64];
								GetClientAuthId(param1, AuthId_Steam2, steamId, sizeof(steamId));
								
								char strQuery[256];
								Format(strQuery, sizeof(strQuery), "SELECT knife_ct FROM knives_client_prefs WHERE auth = '%s'", steamId);
								SQL_TQuery(db, SQLQuery_KNIFE_CT, strQuery, GetClientUserId(param1), DBPrio_High);
							}
						}
					}
					
					if(StrEqual(item, "0"))
					{
						Format(weaponname, sizeof(weaponname), "%T", "MenuKnives_DEFAULT_MENU_TITLE", param1);
					}
					else if(StrEqual(item, "500"))
					{
						Format(weaponname, sizeof(weaponname), "%T", "MenuKnives_BAYONET_MENU_TITLE", param1);
					}
					else if(StrEqual(item, "505"))
					{
						Format(weaponname, sizeof(weaponname), "%T", "MenuKnives_FLIP_MENU_TITLE", param1);
					}
					else if(StrEqual(item, "506"))
					{
						Format(weaponname, sizeof(weaponname), "%T", "MenuKnives_GUT_MENU_TITLE", param1);
					}
					else if(StrEqual(item, "507"))
					{
						Format(weaponname, sizeof(weaponname), "%T", "MenuKnives_KARAMBIT_MENU_TITLE", param1);
					}
					else if(StrEqual(item, "508"))
					{
						Format(weaponname, sizeof(weaponname), "%T", "MenuKnives_M9BAYONET_MENU_TITLE", param1);
					}
					else if(StrEqual(item, "509"))
					{
						Format(weaponname, sizeof(weaponname), "%T", "MenuKnives_HUNTSMAN_MENU_TITLE", param1);
					}
					else if(StrEqual(item, "512"))
					{
						Format(weaponname, sizeof(weaponname), "%T", "MenuKnives_FALCHION_MENU_TITLE", param1);
					}
					else if(StrEqual(item, "515"))
					{
						Format(weaponname, sizeof(weaponname), "%T", "MenuKnives_BUTTERFLY_MENU_TITLE", param1);
					}
					
					int weapon 	= GetPlayerWeaponSlot(param1, CS_SLOT_KNIFE);
					if(weapon == -1)
					{		
						CPrintToChat(param1, "%t", "Knife Not Allowed", weaponname);
						return;
					}
					
					if(/*ZR_IsClientHuman(param1)*/ GetClientTeam(param1) == CS_TEAM_CT)
					{
						if(C_knives_give_mode)
						{
							if(IsPlayerAlive(param1))
							{
								bool taser = false;
								
								while (weapon > -1)
								{
									if(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 31)
									{
										taser = true;
									}
									RemovePlayerItem(param1, weapon);
									AcceptEntityInput(weapon, "Kill");
									weapon = GetPlayerWeaponSlot(param1, CS_SLOT_KNIFE);
								}

								GivePlayerItem(param1, "weapon_knife");
								
								if(taser)
								{
									GivePlayerItem(param1, "weapon_taser");
								}
								
								CPrintToChat(param1, "%t", "Knife Equiped", weaponname);
							}
							else
							{
								CPrintToChat(param1, "%t", "Knife Equiped Not Alive", weaponname);
							}
						}
						else
						{
							CPrintToChat(param1, "%t", "Knife Chosen", weaponname);
						}
					}
					else if(!C_knives_give_mode)
					{
						CPrintToChat(param1, "%t", "Knife Chosen CT", weaponname);
					}
					else
					{
						CPrintToChat(param1, "%t", "Knife Equiped Team CT", weaponname);
					}
					BuildMenuKnivesCT(param1);
				}
			}
		}
	}
	else
	{
		CloseHandle(menu);	
	}
}

/***********************************************************/
/******************* BUILD MENU KNIVES *********************/
/***********************************************************/
void BuildMenuKnivesT(int client)
{
	char title[40], defaultknife[40], huntsman[40], karambit[40], gut[40], flip[40], m9bayonet[40], bayonet[40], falchion[40], butterfly[40];
	
	Menu menu = CreateMenu(MenuKnivesTAction);
	
	Call_StartForward(hOnBuildMenuKnivesTFirstPosition);
	Call_PushCell(menu);
	Call_Finish();
	
	Format(defaultknife, sizeof(defaultknife), "%T", "MenuKnives_DEFAULT_MENU_TITLE", client);
	AddMenuItem(menu, "0", defaultknife);
	
	Format(bayonet, sizeof(bayonet), "%T", "MenuKnives_BAYONET_MENU_TITLE", client);
	AddMenuItem(menu, "500", bayonet);
	
	Format(flip, sizeof(flip), "%T", "MenuKnives_FLIP_MENU_TITLE", client);
	AddMenuItem(menu, "505", flip);
	
	Format(gut, sizeof(gut), "%T", "MenuKnives_GUT_MENU_TITLE", client);
	AddMenuItem(menu, "506", gut);
	
	Format(karambit, sizeof(karambit), "%T", "MenuKnives_KARAMBIT_MENU_TITLE", client);
	AddMenuItem(menu, "507", karambit);
	
	Format(m9bayonet, sizeof(m9bayonet), "%T", "MenuKnives_M9BAYONET_MENU_TITLE", client);
	AddMenuItem(menu, "508", m9bayonet);
	
	Format(huntsman, sizeof(huntsman), "%T", "MenuKnives_HUNTSMAN_MENU_TITLE", client);
	AddMenuItem(menu, "509", huntsman);
	
	Format(falchion, sizeof(falchion), "%T", "MenuKnives_FALCHION_MENU_TITLE", client);
	AddMenuItem(menu, "512", falchion);
	
	Format(butterfly, sizeof(butterfly), "%T", "MenuKnives_BUTTERFLY_MENU_TITLE", client);
	AddMenuItem(menu, "515", butterfly);
	
	Call_StartForward(hOnBuildMenuKnivesTLastPosition);
	Call_PushCell(menu);
	Call_Finish();
	
	Format(title, sizeof(title), "%T", "MenuKnivesT_TITLE", client);
	menu.SetTitle(title);
	SetMenuExitBackButton(menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
}

/***********************************************************/
/****************** MENU KNIVES ACTIONS ********************/
/***********************************************************/
public int MenuKnivesTAction(Menu menu, MenuAction action, int param1, int param2)
{

	if(C_knives_access_mode == 0
	|| C_knives_access_mode == 1 && (IsVip(param1) || IsAdminEx(param1))
	|| C_knives_access_mode == 2 && IsAdminEx(param1))
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
					BuildMenuKnives(param1);
				}		
			}
			case MenuAction_Select:
			{
				Call_StartForward(hOnBuildMenuKnivesTAction);
				Call_PushCell(menu);
				Call_PushCell(param1);
				Call_PushCell(param2);
				Call_Finish();
				
				char item[56], weaponname[32];
				menu.GetItem(param2, item, sizeof(item));
				
				if(StrEqual(item, "0")
				|| StrEqual(item, "500")
				|| StrEqual(item, "505")
				|| StrEqual(item, "506")
				|| StrEqual(item, "507")
				|| StrEqual(item, "508")
				|| StrEqual(item, "509")
				|| StrEqual(item, "512")
				|| StrEqual(item, "515")
				)
				{
					int weaponindex 	= StringToInt(item);
					
					C_Tknife[param1]	= weaponindex;
					
					if(C_knives_storage_mode == STORAGE_COOKIE)
					{
						SetClientCookie(param1, Cookie_Tknife, item);
					} 
					else if(C_knives_storage_mode == STORAGE_SQL)
					{
						if(IsClientAuthorized(param1))
						{
							Database db = Connect();
							if (db != null)
							{
								char steamId[64];
								GetClientAuthId(param1, AuthId_Steam2, steamId, sizeof(steamId));
								
								char strQuery[256];
								Format(strQuery, sizeof(strQuery), "SELECT knife_t FROM knives_client_prefs WHERE auth = '%s'", steamId);
								SQL_TQuery(db, SQLQuery_KNIFE_T, strQuery, GetClientUserId(param1), DBPrio_High);
							}
						}			
					}

					if(StrEqual(item, "0"))
					{
						Format(weaponname, sizeof(weaponname), "%T", "MenuKnives_DEFAULT_MENU_TITLE", param1);
					}
					else if(StrEqual(item, "500"))
					{
						Format(weaponname, sizeof(weaponname), "%T", "MenuKnives_BAYONET_MENU_TITLE", param1);
					}
					else if(StrEqual(item, "505"))
					{
						Format(weaponname, sizeof(weaponname), "%T", "MenuKnives_FLIP_MENU_TITLE", param1);
					}
					else if(StrEqual(item, "506"))
					{
						Format(weaponname, sizeof(weaponname), "%T", "MenuKnives_GUT_MENU_TITLE", param1);
					}
					else if(StrEqual(item, "507"))
					{
						Format(weaponname, sizeof(weaponname), "%T", "MenuKnives_KARAMBIT_MENU_TITLE", param1);
					}
					else if(StrEqual(item, "508"))
					{
						Format(weaponname, sizeof(weaponname), "%T", "MenuKnives_M9BAYONET_MENU_TITLE", param1);
					}
					else if(StrEqual(item, "509"))
					{
						Format(weaponname, sizeof(weaponname), "%T", "MenuKnives_HUNTSMAN_MENU_TITLE", param1);
					}
					else if(StrEqual(item, "512"))
					{
						Format(weaponname, sizeof(weaponname), "%T", "MenuKnives_FALCHION_MENU_TITLE", param1);
					}
					else if(StrEqual(item, "515"))
					{
						Format(weaponname, sizeof(weaponname), "%T", "MenuKnives_BUTTERFLY_MENU_TITLE", param1);
					}
					
					int weapon 	= GetPlayerWeaponSlot(param1, CS_SLOT_KNIFE);
					if(weapon == -1)
					{		
						CPrintToChat(param1, "%t", "Knife Not Allowed", weaponname);
						return;
					}
					
					if(/*ZR_IsClientZombie(param1)*/ GetClientTeam(param1) == CS_TEAM_T)
					{
						if(C_knives_give_mode)
						{
							if(IsPlayerAlive(param1))
							{
									bool taser = false;
									while (weapon > -1)
									{
										if(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 31)
										{
											taser = true;
										}
										RemovePlayerItem(param1, weapon);
										AcceptEntityInput(weapon, "Kill");
										weapon = GetPlayerWeaponSlot(param1, CS_SLOT_KNIFE);
									}

									GivePlayerItem(param1, "weapon_knife");
									
									if(taser)
									{
										GivePlayerItem(param1, "weapon_taser");
									}
									
									CPrintToChat(param1, "%t", "Knife Equiped", weaponname);
							}
							else
							{
								CPrintToChat(param1, "%t", "Knife Equiped Not Alive", weaponname);
							}
						}
						else
						{
							CPrintToChat(param1, "%t", "Knife Chosen", weaponname);
						}
					}
					else if(!C_knives_give_mode)
					{
						CPrintToChat(param1, "%t", "Knife Chosen T", weaponname);
					}
					else
					{
						CPrintToChat(param1, "%t", "Knife Equiped Team T", weaponname);
					}
					BuildMenuKnivesT(param1);
				}
			}
		}
	}
	else
	{
		CloseHandle(menu);	
	}
}

/***********************************************************/
/***************** GIVE KNIFE SAY EXPLODE ******************/
/***********************************************************/
void GiveKnifeSayExplode(int client, char[] menu_command, char[] name_weapon, int weaponindex, char[] text)
{
	char knife[PLATFORM_MAX_PATH];
	Format(knife, sizeof(knife), "%T", menu_command, client);
	
	char explode[20][PLATFORM_MAX_PATH];
	ExplodeString(knife, ", ", explode, sizeof explode, sizeof(explode));

	for(int cmd = 0; cmd < sizeof explode; cmd++)
	{
		char style1[PLATFORM_MAX_PATH], style2[PLATFORM_MAX_PATH];
		Format(style1, sizeof(style1), "!%s", explode[cmd]);
		Format(style2, sizeof(style2), "/%s", explode[cmd]);
		
		if(StrEqual(text, explode[cmd], false) || StrEqual(text, style1, false) && style1[1] || StrEqual(text, style2, false) && style2[1])
		{
			GiveKnifeSay(client, name_weapon, weaponindex);
			return;
		}
	}
}

/***********************************************************/
/********************* GIVE KNIFE SAY **********************/
/***********************************************************/
void GiveKnifeSay(int client, char[] translate, int weaponindex)
{
	char weaponname[32];
	Format(weaponname, sizeof(weaponname), "%T", translate, client);
	
	if(/*ZR_IsClientHuman(client)*/ GetClientTeam(client) == CS_TEAM_CT)
	{
		C_CTknife[client]	= weaponindex;
		
		if(C_knives_storage_mode == STORAGE_COOKIE)
		{
			char cookie[8];
			IntToString(C_CTknife[client], cookie, sizeof(cookie));
			SetClientCookie(client, Cookie_CTknife, cookie);
		} 
		else if(C_knives_storage_mode == STORAGE_SQL)
		{
			if(IsClientAuthorized(client))
			{
				Database db = Connect();
				if (db != null)
				{
					char steamId[64];
					GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
					
					char strQuery[256];
					Format(strQuery, sizeof(strQuery), "SELECT knife_ct FROM knives_client_prefs WHERE auth = '%s'", steamId);
					SQL_TQuery(db, SQLQuery_KNIFE_CT, strQuery, GetClientUserId(client), DBPrio_High);
				}
			}		
		}
		
		int weapon 	= GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
		
		if(weapon == -1)
		{		
			CPrintToChat(client, "%t", "Knife Not Allowed", weaponname);
			return;
		}
		
		if(C_knives_give_mode)
		{
			if(IsPlayerAlive(client))
			{
				bool taser = false;
	
				while (weapon > -1)
				{
					if(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 31)
					{
						taser = true;
					}
					RemovePlayerItem(client, weapon);
					AcceptEntityInput(weapon, "Kill");
					weapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
				}

				GivePlayerItem(client, "weapon_knife");
				
				if(taser)
				{
					GivePlayerItem(client, "weapon_taser");
				}
				
				CPrintToChat(client, "%t", "Knife Equiped", weaponname);
			}
			else
			{
				CPrintToChat(client, "%t", "Knife Equiped Not Alive", weaponname);
			}

			
		}
		else
		{
			CPrintToChat(client, "%t", "Knife Chosen", weaponname);
		}

	}
	else if(/*ZR_IsClientZombie(client)*/ GetClientTeam(client) == CS_TEAM_T)
	{
		C_Tknife[client]	= weaponindex;

		if(C_knives_storage_mode == STORAGE_COOKIE)
		{
			char cookie[8];
			IntToString(C_Tknife[client], cookie, sizeof(cookie));
			
			SetClientCookie(client, Cookie_Tknife, cookie);
		}
		else if(C_knives_storage_mode == STORAGE_SQL)
		{
			if(IsClientAuthorized(client))
			{
				Database db = Connect();
				if (db != null)
				{
					char steamId[64];
					GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
					
					char strQuery[256];
					Format(strQuery, sizeof(strQuery), "SELECT knife_t FROM knives_client_prefs WHERE auth = '%s'", steamId);
					SQL_TQuery(db, SQLQuery_KNIFE_T, strQuery, GetClientUserId(client), DBPrio_High);
				}
			}		
		}
		
		int weapon 	= GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
		
		if(weapon == -1)
		{		
			CPrintToChat(client, "%t", "Knife Not Allowed", weaponname);
			return;
		}	
		
		if(C_knives_give_mode)
		{
			if(IsPlayerAlive(client))
			{
				bool taser = false;
				
				while (weapon > -1)
				{
					if(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 31)
					{
						taser = true;
					}
					RemovePlayerItem(client, weapon);
					AcceptEntityInput(weapon, "Kill");
					weapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
				}

				GivePlayerItem(client, "weapon_knife");
				
				if(taser)
				{
					GivePlayerItem(client, "weapon_taser");
				}
				
				CPrintToChat(client, "%t", "Knife Equiped", weaponname);

			}
			else
			{
				CPrintToChat(client, "%t", "Knife Equiped Not Alive", weaponname);
			}
		}			
		else
		{
			CPrintToChat(client, "%t", "Knife Chosen", weaponname);
		}
	}
}

/***********************************************************/
/************* SQL LOAD PREFS ALL CLIENTS ******************/
/***********************************************************/
void SQL_LoadPrefAllClients()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(Client_IsIngame(i))
		{
			SQL_LoadPrefClients(i);
		}	
	}
}
/***********************************************************/
/*************** SQL LOAD PREFS CLIENTS ********************/
/***********************************************************/
public Action SQL_LoadPrefClients(int client)
{
	if(IsClientAuthorized(client) && !IsFakeClient(client))
	{
		Database db = Connect();
		if (db == null)
		{
			ReplyToCommand(client, "%s Could not connect to database", TAG_CHAT);
			return Plugin_Handled;
		}
		
		char steamId[64];
		GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
		
		char strQuery[256];
		Format(strQuery, sizeof(strQuery), "SELECT knife_ct, knife_t FROM knives_client_prefs WHERE auth = '%s'", steamId);
		SQL_TQuery(db, SQLQuery_LoadPrefClients, strQuery, GetClientUserId(client), DBPrio_High);
	}
	return Plugin_Handled;
}

/***********************************************************/
/************* SQL QUERY LOAD PREFS CLIENTS ****************/
/***********************************************************/
public void SQLQuery_LoadPrefClients(Handle hOwner, Handle hQuery, const char[] strError, any data)
{
	int client = GetClientOfUserId(data);
	if(!Client_IsValid(client))
		return;

	if(hOwner == INVALID_HANDLE || hQuery == INVALID_HANDLE)
	{
		LogToKnives(B_active_knives_dev, "%s SQL Error: %s", TAG_CHAT, strError);
		return;
	}
	
	if(SQL_FetchRow(hQuery) && SQL_GetRowCount(hQuery) != 0)
	{
		C_CTknife[client] 			= SQL_FetchInt(hQuery, 0);
		C_Tknife[client] 			= SQL_FetchInt(hQuery, 1);
	}
	else
	{
		Database db = Connect();
		if (db == null)
		{
			return;
		}
		
		char steamId[64];
		GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
		
		char strQuery[256];
		Format(strQuery, sizeof(strQuery), "INSERT INTO knives_client_prefs (knife_ct, knife_t, auth) VALUES (%i, %i, '%s')", C_knives_ct_default, C_knives_t_default, steamId);
		SQL_TQuery(db, SQLQuery_Update, strQuery, _, DBPrio_High);
		
		SQL_LoadPrefClients(client);
	}
}

/***********************************************************/
/************** SQL QUERY KNIFE CT PREFS *******************/
/***********************************************************/
public void SQLQuery_KNIFE_CT(Handle hOwner, Handle hQuery, const char[] strError, any data)
{
	int client = GetClientOfUserId(data);
	if(!Client_IsValid(client))
		return;

	if(hOwner == INVALID_HANDLE || hQuery == INVALID_HANDLE)
	{
		LogToKnives(B_active_knives_dev, "%s SQL Error: %s", TAG_CHAT, strError);
		return;
	}
	
	Database db = Connect();
	if (db == null)
	{
		ReplyToCommand(client, "%s Could not connect to database", TAG_CHAT);
		return;
	}
	
	char steamId[64];
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
	
	if(SQL_GetRowCount(hQuery) == 0)
	{
		char strQuery[256];
		Format(strQuery, sizeof(strQuery), "INSERT INTO knives_client_prefs (knife_ct, auth) VALUES (%i, '%s')", C_CTknife[client], steamId);
		SQL_TQuery(db, SQLQuery_Update, strQuery, _, DBPrio_High);
	}
	else
	{
		char strQuery[256];
		Format(strQuery, sizeof(strQuery), "UPDATE knives_client_prefs SET knife_ct = '%i' WHERE auth = '%s'", C_CTknife[client], steamId);
		SQL_TQuery(db, SQLQuery_Update, strQuery, _, DBPrio_Normal);
	}
}

/***********************************************************/
/************** SQL QUERY KNIFE T PREFS ********************/
/***********************************************************/
public void SQLQuery_KNIFE_T(Handle hOwner, Handle hQuery, const char[] strError, any data)
{
	int client = GetClientOfUserId(data);
	if(!Client_IsValid(client))
		return;

	if(hOwner == INVALID_HANDLE || hQuery == INVALID_HANDLE)
	{
		LogToKnives(B_active_knives_dev, "%s SQL Error: %s", TAG_CHAT, strError);
		return;
	}
	
	Database db = Connect();
	if (db == null)
	{
		ReplyToCommand(client, "%s Could not connect to database", TAG_CHAT);
		return;
	}
	
	char steamId[64];
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
	
	if(SQL_GetRowCount(hQuery) == 0)
	{
		char strQuery[256];
		Format(strQuery, sizeof(strQuery), "INSERT INTO knives_client_prefs (knife_t, auth) VALUES (%i, '%s')", C_Tknife[client], steamId);
		SQL_TQuery(db, SQLQuery_Update, strQuery, _, DBPrio_High);
	}
	else
	{
		char strQuery[256];
		Format(strQuery, sizeof(strQuery), "UPDATE knives_client_prefs SET knife_t = '%i' WHERE auth = '%s'", C_Tknife[client], steamId);
		SQL_TQuery(db, SQLQuery_Update, strQuery, _, DBPrio_Normal);
	}
}

/***********************************************************/
/******************* SQL QUERY UPDATE **********************/
/***********************************************************/
public void SQLQuery_Update(Handle hOwner, Handle hQuery, const char[] strError, any data)
{
	if(hQuery == INVALID_HANDLE)
	{
		LogToKnives(B_active_knives_dev, "%s SQL Error: %s", TAG_CHAT, strError);
	}
}

/***********************************************************/
/******************* DATABASE CONNECT **********************/
/***********************************************************/
Database Connect()
{
	char error[255];
	Database db;

	if (SQL_CheckConfig("knives"))
	{
		db = SQL_Connect("knives", true, error, sizeof(error));
	} 
	else 
	{
		db = SQL_Connect("default", true, error, sizeof(error));
	}

	if (db == null)
	{
		LogToKnives(B_active_knives_dev, "%s Could not connect to database: %s", TAG_CHAT, error);
		
	}

	return db;
}

/***********************************************************/
/**************** COMMAND CREATE TABLES ********************/
/***********************************************************/
public Action Command_CreateTables(int args)
{
	int client = 0;
	Database db = Connect();
	if (db == null)
	{
		ReplyToCommand(client, "%s Could not connect to database", TAG_CHAT);
		return Plugin_Handled;
	}

	char ident[16];
	db.Driver.GetIdentifier(ident, sizeof(ident));

	if (strcmp(ident, "mysql") == 0)
	{
		CreateMySQL(client, db);
	} 
	else if (strcmp(ident, "sqlite") == 0) 
	{
		CreateSQLite(client, db);
	} else 
	{
		ReplyToCommand(client, "%s Unknown driver type '%s', cannot create tables.", TAG_CHAT, ident);
	}

	delete db;

	return Plugin_Handled;
}

/***********************************************************/
/********************* CREATE MYSQL ************************/
/***********************************************************/
void CreateMySQL(int client, Handle db)
{
	char queries[1][] = 
	{
		"CREATE TABLE IF NOT EXISTS knives_client_prefs (id int(64) NOT NULL AUTO_INCREMENT, auth varchar(32) UNIQUE, knife_ct int(12) NOT NULL default 512, knife_t int(12) NOT NULL default 512, PRIMARY KEY (id)) ENGINE=InnoDB DEFAULT CHARSET=utf8;"
	};

	for (int i = 0; i < 1; i++)
	{
		if (!DoQuery(client, db, queries[i]))
		{
			return;
		}
	}

	ReplyToCommand(client, "%s Knives tables have been created.", TAG_CHAT);
}

/***********************************************************/
/******************** CREATE SQLITE ************************/
/***********************************************************/
void CreateSQLite(int client, Handle db)
{
	char queries[1][] = 
	{
		"CREATE TABLE IF NOT EXISTS zr_client_prefs (id int(64) NOT NULL AUTO_INCREMENT, auth varchar(32) UNIQUE, knife_ct int(12) NOT NULL default 1, knife_t int(12) NOT NULL default 1, PRIMARY KEY (id)) ENGINE=InnoDB DEFAULT CHARSET=utf8;"
	};

	for (int i = 0; i < 1; i++)
	{
		if (!DoQuery(client, db, queries[i]))
		{
			return;
		}
	}

	ReplyToCommand(client, "%s Knife tables have been created.", TAG_CHAT);
}

/***********************************************************/
/*********************** DO QUERY **************************/
/***********************************************************/
stock bool DoQuery(int client, Handle db, const char[] query)
{
	if (!SQL_FastQuery(db, query))
	{
		char error[255];
		SQL_GetError(db, error, sizeof(error));
		LogToKnives(B_active_knives_dev, "%s Query failed: %s", TAG_CHAT, error);
		LogToKnives(B_active_knives_dev, "%s Query dump: %s", TAG_CHAT, query);
		ReplyToCommand(client, "%s Failed to query database", TAG_CHAT);
		return false;
	}

	return true;
}

/***********************************************************/
/*********************** DO ERROR **************************/
/***********************************************************/
stock Action DoError(int client, Handle db, const char[] query, const char[] msg)
{
		char error[255];
		SQL_GetError(db, error, sizeof(error));
		LogToKnives(B_active_knives_dev, "%s %s: %s", TAG_CHAT, msg, error);
		LogToKnives(B_active_knives_dev, "%s Query dump: %s", TAG_CHAT, query);
		delete db;
		ReplyToCommand(client, "%s Failed to query database", TAG_CHAT);
		return Plugin_Handled;
}

/***********************************************************/
/********************* DO SMT ERROR ************************/
/***********************************************************/
stock Action DoStmtError(int client, Handle db, const char[] query, const char[] error, const char[] msg)
{
		LogToKnives(B_active_knives_dev, "%s %s: %s", TAG_CHAT, msg, error);
		LogToKnives(B_active_knives_dev, "%s Query dump: %s", TAG_CHAT, query);
		delete db;
		ReplyToCommand(client, "%s Failed to query database", TAG_CHAT);
		return Plugin_Handled;
}

/***********************************************************/
/********************* IS VALID CLIENT *********************/
/***********************************************************/
stock bool Client_IsValid(int client, bool checkConnected=true)
{
	if (client > 4096) {
		client = EntRefToEntIndex(client);
	}

	if (client < 1 || client > MaxClients) {
		return false;
	}

	if (checkConnected && !IsClientConnected(client)) {
		return false;
	}
	
	return true;
}

/***********************************************************/
/******************** IS CLIENT IN GAME ********************/
/***********************************************************/
stock bool Client_IsIngame(int client)
{
	if (!Client_IsValid(client, false)) {
		return false;
	}

	return IsClientInGame(client);
} 

/***********************************************************/
/******************** LOG TO ZOMBIE RIOT *******************/
/***********************************************************/
stock void LogToKnives(bool status, const char[] format, any ...)
{
	if(status)
	{
		char msg[MSG_LENGTH];
		char msg2[MSG_LENGTH];
		char logfile[MSG_LENGTH];
		Format(msg, MSG_LENGTH, "%s", format);
		VFormat(msg2, MSG_LENGTH, msg, 3);
		
		BuildPath(Path_SM, logfile, sizeof(logfile), "logs/drapi_knives.txt");
		LogToFile(logfile, msg2);
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
	if(
	/*|| GetUserFlagBits(client) & ADMFLAG_RESERVATION*/
	GetUserFlagBits(client) & ADMFLAG_GENERIC
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