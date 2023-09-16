/*      <DR.API KNIFES> (c) by <De Battista Clint - (http://doyou.watch)     */
/*                                                                           */
/*                     <DR.API KNIFES> is licensed under a                   */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//*******************************DR.API KNIFES*******************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[KNIFES] -"

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <csgocolors>
#include <clientprefs>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_knifes_dev;
Handle cvar_knifes_ct_default;
Handle cvar_knifes_t_default;

Handle Cookie_CTknife;
Handle Cookie_Tknife;

//Bool
bool B_cvar_active_knifes_dev					= false;

//Customs
int C_knifes_ct_default;
int C_knifes_t_default;

int C_CTknife[MAXPLAYERS+1];
int C_Tknife[MAXPLAYERS+1];

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API KNIFES (zombie4ever.eu)",
	author = "Dr. Api",
	description = "DR.API KNIFES by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://zombie4ever.eu"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	LoadTranslations("drapi/drapi_knifes.phrases");
	
	CreateConVar("drapi_knifes_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_knifes_dev			= CreateConVar("drapi_active_knifes_dev", 			"0", 					"Enable/Disable Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	cvar_knifes_ct_default			= CreateConVar("drapi_knifes_ct_default", 			"512", 					"Default knife for CT", 				DEFAULT_FLAGS);
	cvar_knifes_t_default			= CreateConVar("drapi_knifes_t_default", 			"512", 					"Default knife for T", 					DEFAULT_FLAGS);
	
	HookEvents();
	
	RegAdminCmd("sm_windex", 		Command_WeaponsIndex, ADMFLAG_CHANGEMAP, "");
	
	//RegConsoleCmd("sm_knife", 		Command_BuildMenuKnifes);
	//RegConsoleCmd("sm_knifes", 		Command_BuildMenuKnifes);
	//RegConsoleCmd("sm_knives", 		Command_BuildMenuKnifes);
	
	//RegConsoleCmd("sm_ctknifes", 		Command_BuildMenuKnifesCT);
	//RegConsoleCmd("sm_ctknives", 		Command_BuildMenuKnifesCT);
	//RegConsoleCmd("sm_ctknife", 		Command_BuildMenuKnifesCT);
	
	//RegConsoleCmd("sm_tknifes", 		Command_BuildMenuKnifesT);
	//RegConsoleCmd("sm_tknives", 		Command_BuildMenuKnifesT);
	//RegConsoleCmd("sm_tknife", 		Command_BuildMenuKnifesT);
	
	AddCommandListener(Event_Say, "say");
	AddCommandListener(Event_Say, "say_team");
	
	Cookie_CTknife 					= RegClientCookie("Cookie_CTknife", "", CookieAccess_Private);
	Cookie_Tknife 					= RegClientCookie("Cookie_Tknife", "", CookieAccess_Private);
	
	int info;
	SetCookieMenuItem(KnifesCookieHandler, info, "Knives");

	AutoExecConfig(true, "drapi_knifes", "sourcemod/drapi");
	
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
				SDKHook(i, SDKHook_WeaponEquip, OnPostWeaponEquip);
			}
		}
		i++;
	}
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

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEvents()
{
	HookConVarChange(cvar_active_knifes_dev, 				Event_CvarChange);
	
	HookConVarChange(cvar_knifes_ct_default, 				Event_CvarChange);
	HookConVarChange(cvar_knifes_t_default, 				Event_CvarChange);
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
	B_cvar_active_knifes_dev 					= GetConVarBool(cvar_active_knifes_dev);
	
	C_knifes_ct_default 						= GetConVarInt(cvar_knifes_ct_default);
	C_knifes_t_default 							= GetConVarInt(cvar_knifes_t_default);
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
        char S_classname[64];
        if(!GetEdictClassname(weapon, S_classname, sizeof(S_classname)) || StrContains(S_classname, "weapon_knife", false) != 0)
        {
                return;
        }
       
        if(GetClientTeam(client) == CS_TEAM_T)
        {
			if(C_Tknife[client] < 1)
			{
					int weaponindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
					if(weaponindex == 42 || weaponindex == 59)
					{					
						SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", C_knifes_t_default);
					}
			}
			else 
			{
				SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", C_Tknife[client]);
			}
                               
        }
        else if(GetClientTeam(client) == CS_TEAM_CT)
        {
			if(C_CTknife[client] < 1)
			{
					int weaponindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
					if(weaponindex == 42 || weaponindex == 59)
					{					
						SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", C_knifes_ct_default);
					}
			}
			else 
			{
				SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", C_CTknife[client]);
			}
                               
        }
}

/***********************************************************/
/*********************** EVENT SAY *************************/
/***********************************************************/
public Action Event_Say(int client, const char[] command, int args)
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
		
		if(StrEqual(text, explode[cmd], false) || StrEqual(text, style1, false) || StrEqual(text, style2, false))
		{
			BuildMenuKnifes(client);
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
		
		if(StrEqual(text, ct_explode[cmd], false) || StrEqual(text, style1, false) || StrEqual(text, style2, false))
		{
			BuildMenuKnifesCT(client);
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
		
		if(StrEqual(text, t_explode[cmd], false) || StrEqual(text, style1, false) || StrEqual(text, style2, false))
		{
			BuildMenuKnifesT(client);
			return Plugin_Handled;
		}
	}
	
	GiveKnifeSayExplode(client, 	"Knife Menu Command Bayonet", 		"MenuKnifes_BAYONET_MENU_TITLE", 	500, 	text);
	GiveKnifeSayExplode(client, 	"Knife Menu Command Flip", 			"MenuKnifes_FLIP_MENU_TITLE", 		505, 	text);
	GiveKnifeSayExplode(client, 	"Knife Menu Command Gut", 			"MenuKnifes_GUT_MENU_TITLE", 		506, 	text);
	GiveKnifeSayExplode(client, 	"Knife Menu Command Karambit", 		"MenuKnifes_KARAMBIT_MENU_TITLE", 	507, 	text);
	GiveKnifeSayExplode(client, 	"Knife Menu Command M9Bayonet", 	"MenuKnifes_M9BAYONET_MENU_TITLE", 	508, 	text);
	GiveKnifeSayExplode(client, 	"Knife Menu Command Huntsman", 		"MenuKnifes_HUNTSMAN_MENU_TITLE", 	509, 	text);
	GiveKnifeSayExplode(client, 	"Knife Menu Command Falchion", 		"MenuKnifes_FALCHION_MENU_TITLE", 	512, 	text);
	GiveKnifeSayExplode(client, 	"Knife Menu Command Butterfly", 	"MenuKnifes_BUTTERFLY_MENU_TITLE", 	515, 	text);
	
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
/********************* CMD MENU KNIFES *********************/
/***********************************************************/
public Action Command_BuildMenuKnifes(int client, int args)
{
	BuildMenuKnifes(client);
}

/***********************************************************/
/******************** CMD MENU KNIFES CT *******************/
/***********************************************************/
public Action Command_BuildMenuKnifesCT(int client, int args)
{
	BuildMenuKnifesCT(client);
}

/***********************************************************/
/******************** CMD MENU KNIFES T ********************/
/***********************************************************/
public Action Command_BuildMenuKnifesT(int client, int args)
{
	BuildMenuKnifesT(client);
}

/***********************************************************/
/********************** MENU SETTINGS **********************/
/***********************************************************/
public void KnifesCookieHandler(int client, CookieMenuAction action, any info, char [] buffer, int maxlen)
{
	BuildMenuKnifes(client);
} 

/***********************************************************/
/******************* BUILD MENU KNIFES *********************/
/***********************************************************/
void BuildMenuKnifes(int client)
{
	char title[40], ct[40], t[40];
	Menu menu = CreateMenu(MenuKnifesAction);
	
	Format(ct, sizeof(ct), "%T", "MenuKnifes_CT_MENU_TITLE", client);
	AddMenuItem(menu, "M_CT", ct);
	
	Format(t, sizeof(t), "%T", "MenuKnifes_T_MENU_TITLE", client);
	AddMenuItem(menu, "M_T", t);
	
	Format(title, sizeof(title), "%T", "MenuKnifes_TITLE", client);
	menu.SetTitle(title);
	SetMenuExitBackButton(menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
}

/***********************************************************/
/****************** MENU KNIFES ACTIONS ********************/
/***********************************************************/
public int MenuKnifesAction(Menu menu, MenuAction action, int param1, int param2)
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
			
			if(StrEqual(menu1, "M_CT"))
			{
				BuildMenuKnifesCT(param1);
			}
			else if(StrEqual(menu1, "M_T"))
			{
				BuildMenuKnifesT(param1);
			}
		}
	}
}

/***********************************************************/
/******************* BUILD MENU KNIFES *********************/
/***********************************************************/
void BuildMenuKnifesCT(int client)
{
	char title[40], defaultknife[40], huntsman[40], karambit[40], gut[40], flip[40], m9bayonet[40], bayonet[40], falchion[40], butterfly[40];
	
	Menu menu = CreateMenu(MenuKnifesCTAction);
	
	Format(defaultknife, sizeof(defaultknife), "%T", "MenuKnifes_DEFAULT_MENU_TITLE", client);
	AddMenuItem(menu, "0", defaultknife);
	
	Format(bayonet, sizeof(bayonet), "%T", "MenuKnifes_BAYONET_MENU_TITLE", client);
	AddMenuItem(menu, "500", bayonet);
	
	Format(flip, sizeof(flip), "%T", "MenuKnifes_FLIP_MENU_TITLE", client);
	AddMenuItem(menu, "505", flip);
	
	Format(gut, sizeof(gut), "%T", "MenuKnifes_GUT_MENU_TITLE", client);
	AddMenuItem(menu, "506", gut);
	
	Format(karambit, sizeof(karambit), "%T", "MenuKnifes_KARAMBIT_MENU_TITLE", client);
	AddMenuItem(menu, "507", karambit);
	
	Format(m9bayonet, sizeof(m9bayonet), "%T", "MenuKnifes_M9BAYONET_MENU_TITLE", client);
	AddMenuItem(menu, "508", m9bayonet);
	
	Format(huntsman, sizeof(huntsman), "%T", "MenuKnifes_HUNTSMAN_MENU_TITLE", client);
	AddMenuItem(menu, "509", huntsman);
	
	Format(falchion, sizeof(falchion), "%T", "MenuKnifes_FALCHION_MENU_TITLE", client);
	AddMenuItem(menu, "512", falchion);
	
	Format(butterfly, sizeof(butterfly), "%T", "MenuKnifes_BUTTERFLY_MENU_TITLE", client);
	AddMenuItem(menu, "515", butterfly);
	
	
	Format(title, sizeof(title), "%T", "MenuKnifesCT_TITLE", client);
	menu.SetTitle(title);
	SetMenuExitBackButton(menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
}

/***********************************************************/
/****************** MENU KNIFES ACTIONS ********************/
/***********************************************************/
public int MenuKnifesCTAction(Menu menu, MenuAction action, int param1, int param2)
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
				BuildMenuKnifes(param1);
			}		
		}
		case MenuAction_Select:
		{
			char item[56], weaponname[32];
			menu.GetItem(param2, item, sizeof(item));
			
			int weaponindex 	= StringToInt(item);
			
			C_CTknife[param1]	= weaponindex;
			SetClientCookie(param1, Cookie_CTknife, item);
			
			if(StrEqual(item, "0"))
			{
				Format(weaponname, sizeof(weaponname), "%T", "MenuKnifes_DEFAULT_MENU_TITLE", param1);
			}
			else if(StrEqual(item, "500"))
			{
				Format(weaponname, sizeof(weaponname), "%T", "MenuKnifes_BAYONET_MENU_TITLE", param1);
			}
			else if(StrEqual(item, "505"))
			{
				Format(weaponname, sizeof(weaponname), "%T", "MenuKnifes_FLIP_MENU_TITLE", param1);
			}
			else if(StrEqual(item, "506"))
			{
				Format(weaponname, sizeof(weaponname), "%T", "MenuKnifes_GUT_MENU_TITLE", param1);
			}
			else if(StrEqual(item, "507"))
			{
				Format(weaponname, sizeof(weaponname), "%T", "MenuKnifes_KARAMBIT_MENU_TITLE", param1);
			}
			else if(StrEqual(item, "508"))
			{
				Format(weaponname, sizeof(weaponname), "%T", "MenuKnifes_M9BAYONET_MENU_TITLE", param1);
			}
			else if(StrEqual(item, "509"))
			{
				Format(weaponname, sizeof(weaponname), "%T", "MenuKnifes_HUNTSMAN_MENU_TITLE", param1);
			}
			else if(StrEqual(item, "512"))
			{
				Format(weaponname, sizeof(weaponname), "%T", "MenuKnifes_FALCHION_MENU_TITLE", param1);
			}
			else if(StrEqual(item, "515"))
			{
				Format(weaponname, sizeof(weaponname), "%T", "MenuKnifes_BUTTERFLY_MENU_TITLE", param1);
			}
			
			if(GetClientTeam(param1) == CS_TEAM_CT)
			{
				if(IsPlayerAlive(param1))
				{
					int weapon = GetPlayerWeaponSlot(param1, CS_SLOT_KNIFE);
					if(weapon != -1)
					{
						RemovePlayerItem(param1, weapon);
						AcceptEntityInput(weapon, "Kill");

						GivePlayerItem(param1, "weapon_knife");
						CPrintToChat(param1, "%t", "Knife Equiped", weaponname);
					}
				}
				else
				{
					CPrintToChat(param1, "%t", "Knife Equiped Not Alive", weaponname);
				}
			}
			else
			{
				CPrintToChat(param1, "%t", "Knife Equiped Team CT", weaponname);
			}
			BuildMenuKnifesCT(param1);
		}
	}
}

/***********************************************************/
/******************* BUILD MENU KNIFES *********************/
/***********************************************************/
void BuildMenuKnifesT(int client)
{
	char title[40], defaultknife[40], huntsman[40], karambit[40], gut[40], flip[40], m9bayonet[40], bayonet[40], falchion[40], butterfly[40];
	
	Menu menu = CreateMenu(MenuKnifesTAction);
	
	Format(defaultknife, sizeof(defaultknife), "%T", "MenuKnifes_DEFAULT_MENU_TITLE", client);
	AddMenuItem(menu, "0", defaultknife);
	
	Format(bayonet, sizeof(bayonet), "%T", "MenuKnifes_BAYONET_MENU_TITLE", client);
	AddMenuItem(menu, "500", bayonet);
	
	Format(flip, sizeof(flip), "%T", "MenuKnifes_FLIP_MENU_TITLE", client);
	AddMenuItem(menu, "505", flip);
	
	Format(gut, sizeof(gut), "%T", "MenuKnifes_GUT_MENU_TITLE", client);
	AddMenuItem(menu, "506", gut);
	
	Format(karambit, sizeof(karambit), "%T", "MenuKnifes_KARAMBIT_MENU_TITLE", client);
	AddMenuItem(menu, "507", karambit);
	
	Format(m9bayonet, sizeof(m9bayonet), "%T", "MenuKnifes_M9BAYONET_MENU_TITLE", client);
	AddMenuItem(menu, "508", m9bayonet);
	
	Format(huntsman, sizeof(huntsman), "%T", "MenuKnifes_HUNTSMAN_MENU_TITLE", client);
	AddMenuItem(menu, "509", huntsman);
	
	Format(falchion, sizeof(falchion), "%T", "MenuKnifes_FALCHION_MENU_TITLE", client);
	AddMenuItem(menu, "512", falchion);
	
	Format(butterfly, sizeof(butterfly), "%T", "MenuKnifes_BUTTERFLY_MENU_TITLE", client);
	AddMenuItem(menu, "515", butterfly);
	
	
	Format(title, sizeof(title), "%T", "MenuKnifesT_TITLE", client);
	menu.SetTitle(title);
	SetMenuExitBackButton(menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
}

/***********************************************************/
/****************** MENU KNIFES ACTIONS ********************/
/***********************************************************/
public int MenuKnifesTAction(Menu menu, MenuAction action, int param1, int param2)
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
				BuildMenuKnifes(param1);
			}		
		}
		case MenuAction_Select:
		{
			char item[56], weaponname[32];
			menu.GetItem(param2, item, sizeof(item));
			
			int weaponindex 	= StringToInt(item);
			
			C_Tknife[param1]	= weaponindex;
			SetClientCookie(param1, Cookie_Tknife, item);

			if(StrEqual(item, "0"))
			{
				Format(weaponname, sizeof(weaponname), "%T", "MenuKnifes_DEFAULT_MENU_TITLE", param1);
			}
			else if(StrEqual(item, "500"))
			{
				Format(weaponname, sizeof(weaponname), "%T", "MenuKnifes_BAYONET_MENU_TITLE", param1);
			}
			else if(StrEqual(item, "505"))
			{
				Format(weaponname, sizeof(weaponname), "%T", "MenuKnifes_FLIP_MENU_TITLE", param1);
			}
			else if(StrEqual(item, "506"))
			{
				Format(weaponname, sizeof(weaponname), "%T", "MenuKnifes_GUT_MENU_TITLE", param1);
			}
			else if(StrEqual(item, "507"))
			{
				Format(weaponname, sizeof(weaponname), "%T", "MenuKnifes_KARAMBIT_MENU_TITLE", param1);
			}
			else if(StrEqual(item, "508"))
			{
				Format(weaponname, sizeof(weaponname), "%T", "MenuKnifes_M9BAYONET_MENU_TITLE", param1);
			}
			else if(StrEqual(item, "509"))
			{
				Format(weaponname, sizeof(weaponname), "%T", "MenuKnifes_HUNTSMAN_MENU_TITLE", param1);
			}
			else if(StrEqual(item, "512"))
			{
				Format(weaponname, sizeof(weaponname), "%T", "MenuKnifes_FALCHION_MENU_TITLE", param1);
			}
			else if(StrEqual(item, "515"))
			{
				Format(weaponname, sizeof(weaponname), "%T", "MenuKnifes_BUTTERFLY_MENU_TITLE", param1);
			}
			
			if(GetClientTeam(param1) == CS_TEAM_T)
			{
				if(IsPlayerAlive(param1))
				{
					int weapon = GetPlayerWeaponSlot(param1, CS_SLOT_KNIFE);
					if(weapon != -1)
					{
						RemovePlayerItem(param1, weapon);
						AcceptEntityInput(weapon, "Kill");

						GivePlayerItem(param1, "weapon_knife");
						CPrintToChat(param1, "%t", "Knife Equiped", weaponname);
					}
				}
				else
				{
					CPrintToChat(param1, "%t", "Knife Equiped Not Alive", weaponname);
				}
			}
			else
			{
				CPrintToChat(param1, "%t", "Knife Equiped Team T", weaponname);
			}
			BuildMenuKnifesT(param1);
		}
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
		
		if(StrEqual(text, explode[cmd], false) || StrEqual(text, style1, false) || StrEqual(text, style2, false))
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
	
	if(GetClientTeam(client) == CS_TEAM_CT)
	{
		C_CTknife[client]	= weaponindex;
		
		char cookie[8];
		IntToString(C_CTknife[client], cookie, sizeof(cookie));
		
		SetClientCookie(client, Cookie_CTknife, cookie);
		
		if(IsPlayerAlive(client))
		{
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
			if(weapon != -1)
			{
				RemovePlayerItem(client, weapon);
				AcceptEntityInput(weapon, "Kill");

				GivePlayerItem(client, "weapon_knife");
				CPrintToChat(client, "%t", "Knife Equiped", weaponname);
			}
		}
		else
		{
			CPrintToChat(client, "%t", "Knife Equiped Not Alive", weaponname);
		}
	}
	else if(GetClientTeam(client) == CS_TEAM_T)
	{
		C_Tknife[client]	= weaponindex;
		
		char cookie[8];
		IntToString(C_Tknife[client], cookie, sizeof(cookie));
		
		SetClientCookie(client, Cookie_Tknife, cookie);
		
		if(IsPlayerAlive(client))
		{
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
			if(weapon != -1)
			{
				RemovePlayerItem(client, weapon);
				AcceptEntityInput(weapon, "Kill");

				GivePlayerItem(client, "weapon_knife");
				CPrintToChat(client, "%t", "Knife Equiped", weaponname);
			}
		}
		else
		{
			CPrintToChat(client, "%t", "Knife Equiped Not Alive", weaponname);
		}
	}
}