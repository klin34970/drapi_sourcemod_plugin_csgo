/*  <DR.API KNIVES PAINTS> (c) by <De Battista Clint - (http://doyou.watch)  */
/*                                                                           */
/*                 <DR.API KNIVES PAINTS> is licensed under a                */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//***************************DR.API KNIVES PAINTS****************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[KNIVES PAINTS] -"

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <stocks>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_knives_paints_dev;

Handle Array_KnifeSkin;

//Bool
bool B_cvar_active_knives_paints_dev					= false;

//Customs

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API KNIVES PAINTS",
	author = "Dr. Api",
	description = "DR.API KNIVES PAINTS by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://zombie4ever.eu"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	AutoExecConfig_SetFile("drapi_knives_paints", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_knives_paints_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_knives_paints_dev			= AutoExecConfig_CreateConVar("drapi_active_knives_paints_dev", 			"0", 					"Enable/Disable Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	HookEvents();
	
	AutoExecConfig_ExecuteFile();
	
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			SDKHook(i, SDKHook_WeaponEquipPost, OnPostWeaponEquip);
		}
		i++;
	}
	
	Array_KnifeSkin = CreateArray(3);
	
	RegConsoleCmd("sm_paint", 				Command_Paint, 			"Test paint kit");
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
			SDKUnhook(i, SDKHook_WeaponEquipPost, OnPostWeaponEquip);
		}
		i++;
	}
}

/***********************************************************/
/**************** WHEN CLIENT PUT IN SERVER ****************/
/***********************************************************/
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponEquipPost, OnPostWeaponEquip);
}

/***********************************************************/
/***************** WHEN CLIENT DISCONNECT ******************/
/***********************************************************/
public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_WeaponEquipPost, OnPostWeaponEquip);
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEvents()
{
	HookConVarChange(cvar_active_knives_paints_dev, 				Event_CvarChange);
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
	B_cvar_active_knives_paints_dev 					= GetConVarBool(cvar_active_knives_paints_dev);
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
/********************** WHEN MAP END ***********************/
/***********************************************************/
public void OnMapEnd()
{
	ClearArray(Array_KnifeSkin);
}

public Action Command_Paint(int client, int args)
{
	char S_args1[256];
	GetCmdArg(1, S_args1, sizeof(S_args1));
	
	int knife = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
	SetKnifeSkin(client, knife, StringToInt(S_args1));
}

/***********************************************************/
/****************** ON POST WEAPON EQUIP *******************/
/***********************************************************/
public Action OnPostWeaponEquip(int client, int weapon)
{
	Handle dataPackHandle;
	CreateDataTimer(0.0, TimerData_OnPostWeaponEquip, dataPackHandle);
	WritePackCell(dataPackHandle, EntIndexToEntRef(weapon));
	WritePackCell(dataPackHandle, client);
}

/***********************************************************/
/************ TIMER DATA ON POST WEAPON EQUIP **************/
/***********************************************************/
public Action TimerData_OnPostWeaponEquip(Handle timer, Handle dataPackHandle)
{
	ResetPack(dataPackHandle);
	int weapon 	= EntRefToEntIndex(ReadPackCell(dataPackHandle));
	int client 	= ReadPackCell(dataPackHandle);
	SetKnifeSkin(client, weapon, 12);
	return Plugin_Handled;
}

/***********************************************************/
/************** TIMER DATA RESTORE ITEM ID *****************/
/***********************************************************/
public Action TimerData_RestoreItemID(Handle timer, Handle dataPackHandle)
{
    ResetPack(dataPackHandle);
    int entity 			= ReadPackCell(dataPackHandle);
    int m_iItemIDHigh 	= ReadPackCell(dataPackHandle);
    int m_iItemIDLow 	= ReadPackCell(dataPackHandle);
    
    if(entity != INVALID_ENT_REFERENCE)
	{
		SetEntProp(entity, Prop_Send, "m_iItemIDHigh", m_iItemIDHigh);
		SetEntProp(entity, Prop_Send, "m_iItemIDLow", m_iItemIDLow);
	}
} 

/***********************************************************/
/******************** SET KNIFE SKIN ***********************/
/***********************************************************/
void SetKnifeSkin(int client, int weapon, int paintkit)
{
	if(GetEntProp(weapon, Prop_Send, "m_hPrevOwner") > 0 || (GetEntProp(weapon, Prop_Send, "m_iItemIDHigh") == 0 && GetEntProp(weapon, Prop_Send, "m_iItemIDLow") == 2048))
	{
		return;
	}
	
	if(GetPlayerWeaponSlot(client, CS_SLOT_KNIFE) == weapon)
	{
		char S_Classname[64];
		if(GetEdictClassname(weapon, S_Classname, sizeof(S_Classname)))
		{
			if(StrEqual(S_Classname, "weapon_knife")
			|| StrEqual(S_Classname, "weapon_knife_bayonet")
			|| StrEqual(S_Classname, "weapon_knife_flip")
			|| StrEqual(S_Classname, "weapon_knife_gut")
			|| StrEqual(S_Classname, "weapon_knife_karambit")
			|| StrEqual(S_Classname, "weapon_knife_m9_bayonet")
			|| StrEqual(S_Classname, "weapon_knife_huntsman")
			|| StrEqual(S_Classname, "weapon_knife_falchion")
			|| StrEqual(S_Classname, "weapon_knife_butterfly")
			)
			{
				RemovePlayerItem(client, weapon);
				AcceptEntityInput(weapon, "Kill");
				
				int new_knife = GivePlayerItem(client, S_Classname);
				EquipPlayerWeapon(client, new_knife);
				
				int m_iItemIDHigh	= GetEntProp(new_knife, Prop_Send, "m_iItemIDHigh");
				int m_iItemIDLow	= GetEntProp(new_knife, Prop_Send, "m_iItemIDLow");

				SetEntProp(new_knife, Prop_Send, "m_iItemIDLow", 2048);
				SetEntProp(new_knife, Prop_Send, "m_iItemIDHigh", 0);

				SetEntProp(new_knife, Prop_Send, "m_nFallbackPaintKit", paintkit);
				
				/* 1.0 pattern invisible, 0.5 = 50% visible*/
				SetEntPropFloat(new_knife,Prop_Send,"m_flFallbackWear", 0.0);
				
				/* Kill number visible on knife */
				SetEntProp(new_knife, Prop_Send, "m_nFallbackStatTrak", 0);
				
				/* 1 = Authentic, 2 = Retro, 3 = (*) */
				SetEntProp(new_knife, Prop_Send, "m_iEntityQuality", 3);
				
				Handle dataPackHandle2;
				CreateDataTimer(0.2, TimerData_RestoreItemID, dataPackHandle2);
				WritePackCell(dataPackHandle2, new_knife);
				WritePackCell(dataPackHandle2, m_iItemIDHigh);
				WritePackCell(dataPackHandle2, m_iItemIDLow);
			}
		}
	}
}
/***********************************************************/
/************** ADD ITEM ON MENU KNIVES CT *****************/
/***********************************************************/
public void OnBuildMenuKnivesCTFirstPosition(Menu menu)
{
	AddMenuItem(menu, "M_KniveCTSkins", "Skins Knives CT");
}

/***********************************************************/
/***************** MENU KNIVES CT ACTION *******************/
/***********************************************************/
public void OnBuildMenuKnivesCTAction(Menu menu, int param1, int param2)
{
	char item[56];
	menu.GetItem(param2, item, sizeof(item));
	
	if(StrEqual(item, "M_KniveCTSkins"))
	{
		BuildMenuKnivesCTSkins(param1);
	}
}

/***********************************************************/
/******************* BUILD MENU KNIVES *********************/
/***********************************************************/
void BuildMenuKnivesCTSkins(int client)
{
	Menu menu = CreateMenu(BuildMenuKnivesCTSkinsAction);
	
	AddMenuItem(menu, "12", 	"Crimson Web");
	AddMenuItem(menu, "232", 	"Crimson Web 2");
	
	AddMenuItem(menu, "410", 	"Damascus Steel (1)");
	AddMenuItem(menu, "411", 	"Damascus Steel (2)");
	AddMenuItem(menu, "247", 	"Damascus Steel (3)");
	
	AddMenuItem(menu, "98", 	"Ultraviolet");
	
	AddMenuItem(menu, "323", 	"Rust Coat (1)");
	AddMenuItem(menu, "203", 	"Rust Coat (2)");
	AddMenuItem(menu, "414", 	"Rust Coat (3)");
	
	AddMenuItem(menu, "409", 	"Tiger Tooth");
	
	AddMenuItem(menu, "413", 	"Marbel Fade");
	
	menu.SetTitle("Skins");
	SetMenuExitBackButton(menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
}

/***********************************************************/
/****************** MENU KNIVES ACTIONS ********************/
/***********************************************************/
public int BuildMenuKnivesCTSkinsAction(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);	
		}
		case MenuAction_Cancel:
		{	
		}
		case MenuAction_Select:
		{
			char item[56], infos[192], S_Classname[64];
			menu.GetItem(param2, item, sizeof(item));
			int paintkit = StringToInt(item);
			
			int knife = GetPlayerWeaponSlot(param1, CS_SLOT_KNIFE);
			//SetKnifeSkin(param1, knife, paintkit);
			
			BuildMenuKnivesCTSkins(param1);
		}
	}
}