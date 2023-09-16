/*      <DR.API SPAWNS> (c) by <De Battista Clint - (http://doyou.watch)     */
/*                                                                           */
/*                     <DR.API SPAWNS> is licensed under a                   */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//*******************************DR.API SPAWNS*******************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[SPAWNS] -"

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <stocks>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_spawns_dev;

Handle KillSpawnsADT;
Handle CustSpawnsADT;
Handle hAdminMenu 								= INVALID_HANDLE;

//Bool
bool B_cvar_active_spawns_dev					= false;

bool RemoveDefSpawns;
bool InEditMode;

//STRINGS
char MapCfgPath[PLATFORM_MAX_PATH];

//CUSTOMS
int  RedGlowSprite;
int BlueGlowSprite;

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API SPAWNS",
	author = "Dr. Api",
	description = "DR.API SPAWNS by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://doyou.watch"
}

/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	AutoExecConfig_SetFile("drapi_spawns", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_spawns_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_spawns_dev			= AutoExecConfig_CreateConVar("drapi_active_spawns_dev", 			"0", 					"Enable/Disable Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	HookEvents();
	
	AutoExecConfig_ExecuteFile();
	
	RegAdminCmd("sm_spawns",	Command_MenuSpawns, 	ADMFLAG_CHANGEMAP, "Spawns admin menu");
	
	char configspath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, configspath, sizeof(configspath), "configs/drapi/spawns");
	if(!DirExists(configspath))
	{
		CreateDirectory(configspath, 511);
	}
	
	Handle topmenu;
	if(LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}

	KillSpawnsADT = CreateArray(3);
	CustSpawnsADT = CreateArray(5);
}

/***********************************************************/
/******************* ON LIBRARY REMOVED ********************/
/***********************************************************/
public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "adminmenu"))
		hAdminMenu = INVALID_HANDLE;
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
		}
		i++;
	}
}

/***********************************************************/
/**************** WHEN CLIENT PUT IN SERVER ****************/
/***********************************************************/
public void OnClientPutInServer(int client)
{

}

/***********************************************************/
/***************** WHEN CLIENT DISCONNECT ******************/
/***********************************************************/
public void OnClientDisconnect(int client)
{

}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEvents()
{
	HookConVarChange(cvar_active_spawns_dev, 				Event_CvarChange);
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
	B_cvar_active_spawns_dev 					= GetConVarBool(cvar_active_spawns_dev);
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
	RemoveDefSpawns 		= false;
	InEditMode 				= false;

	char mapName[64];
	GetCurrentMap(mapName, sizeof(mapName));
	BuildPath(Path_SM, MapCfgPath, sizeof(MapCfgPath), "configs/drapi/spawns/%s.cfg", mapName);
	ReadConfig();

	RedGlowSprite 			= PrecacheModel("sprites/redglow3.vmt");
	BlueGlowSprite 			= PrecacheModel("sprites/blueglow1.vmt");
	UpdateState();
}

/***********************************************************/
/********************** WHEN MAP END ***********************/
/***********************************************************/
public void OnMapEnd()
{
	ClearArray(KillSpawnsADT);
	ClearArray(CustSpawnsADT);
}

/***********************************************************/
/******************* COMMAND MENU SPAWN ********************/
/***********************************************************/
public Action Command_MenuSpawns(int client, int args)
{
	ShowToolzMenu(client);
	return Plugin_Handled;
}

/***********************************************************/
/*********************** READ CONFIG ***********************/
/***********************************************************/
void ReadConfig()
{
	Handle kv = CreateKeyValues("ST7Root");
	if(FileToKeyValues(kv, MapCfgPath))
	{
		int num;
		char sBuffer[32];
		float fVec[3], DataFloats[5];
		if(KvGetNum(kv, "remdefsp"))
		{
			RemoveAllDefaultSpawns();
			RemoveDefSpawns = true;
		}
		else
		{
			Format(sBuffer, sizeof(sBuffer), "rs:%d:pos", num);
			KvGetVector(kv, sBuffer, fVec);
			
			while(fVec[0] != 0.0)
			{
				RemoveSingleDefaultSpawn(fVec);
				PushArrayArray(KillSpawnsADT, fVec);
				num++;
				Format(sBuffer, sizeof(sBuffer), "rs:%d:pos", num);
				KvGetVector(kv, sBuffer, fVec);
			}
		}
		num = 0;
		Format(sBuffer, sizeof(sBuffer), "ns:%d:pos", num);
		KvGetVector(kv, sBuffer, fVec);
		
		while(fVec[0] != 0.0)
		{
			DataFloats[0] = fVec[0];
			DataFloats[1] = fVec[1];
			DataFloats[2] = fVec[2];
			Format(sBuffer, sizeof(sBuffer), "ns:%d:ang", num);
			DataFloats[3] = KvGetFloat(kv, sBuffer);
			Format(sBuffer, sizeof(sBuffer), "ns:%d:team", num);
			DataFloats[4] = KvGetFloat(kv, sBuffer);
			CreateSpawn(DataFloats, false);
			PushArrayArray(CustSpawnsADT, DataFloats);
			num++;
			Format(sBuffer, sizeof(sBuffer), "ns:%d:pos", num);
			KvGetVector(kv, sBuffer, fVec);
		}
	}

	CloseHandle(kv);
}

/***********************************************************/
/*********************** BUILD MENU ************************/
/***********************************************************/
void ShowToolzMenu(int client)
{
	Menu menu = CreateMenu(MainMenuHandler);
	SetMenuTitle(menu, "Spawns");
	char menuItem[64];
	Format(menuItem, sizeof(menuItem), "%s Edit Mode", InEditMode == false ? "Enable" : "Disable");
	AddMenuItem(menu, "0", menuItem);
	Format(menuItem, sizeof(menuItem), "%s Default Spawn Removal", RemoveDefSpawns == false ? "Enable" : "Disable");
	AddMenuItem(menu, "1", menuItem);
	AddMenuItem(menu, "2", "Add T Spawn");
	AddMenuItem(menu, "3", "Add CT Spawn");
	AddMenuItem(menu, "4", "Remove Spawn");
	AddMenuItem(menu, "5", "Save Configuration");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

/***********************************************************/
/********************** MENU ACTIONS ***********************/
/***********************************************************/
public int MainMenuHandler(Handle menu, MenuAction action, int client, int selection)
{
	if(action == MenuAction_Select)
	{
		if(selection == 0)
		{
			InEditMode = InEditMode == false ? true : false;
			PrintToChatAll("[Spawns] Edit Mode %s.", InEditMode == false ? "Disabled" : "Enabled");
			if (InEditMode)
			{
				CreateTimer(1.0, ShowEditModeGoodies, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}

			ShowToolzMenu(client);
		}
		else if(selection == 1)
		{
			RemoveDefSpawns = RemoveDefSpawns == false ? true : false;
			PrintToChatAll("[Spawns] Default Spawn Removal will be %s.", RemoveDefSpawns == false ? "Disabled" : "Enabled");
			ShowToolzMenu(client);
		}
		else if(selection == 2)
		{
			InitializeNewSpawn(client, 2);
			ShowToolzMenu(client);
		}
		else if(selection == 3)
		{
			InitializeNewSpawn(client, 3);
			ShowToolzMenu(client);
		}
		else if(selection == 4)
		{
			if(!RemoveSpawn(client))
			{
				PrintToChatAll("[Spawns] No valid spawn point found.");
			}
			else
			{
				PrintToChatAll("[Spawns] Spawn point removed!");
			}

			ShowToolzMenu(client);
		}
		else if(selection == 5)
		{
		SaveConfiguration();
		ShowToolzMenu(client);
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

/***********************************************************/
/******************* SHOW SPAWN POINTS *********************/
/***********************************************************/
public Action ShowEditModeGoodies(Handle timer)
{
	if(!InEditMode)
	{
		return Plugin_Stop;
	}

	int maxEnt = GetMaxEntities(), tsCount, ctsCount;
	char sClassName[64]; 
	float fVec[3];
	for(int i = MaxClients; i < maxEnt; i++)
	{
		if(IsValidEdict(i) && IsValidEntity(i) && GetEdictClassname(i, sClassName, sizeof(sClassName)))
		{
			if(StrEqual(sClassName, "info_player_terrorist"))
			{
				tsCount++;
				GetEntPropVector(i, Prop_Data, "m_vecOrigin", fVec);
				TE_SetupGlowSprite(fVec, RedGlowSprite, 1.0, 0.4, 249);
				TE_SendToAll();
			}
			else if(StrEqual(sClassName, "info_player_counterterrorist"))
			{
				ctsCount++;
				GetEntPropVector(i, Prop_Data, "m_vecOrigin", fVec);
				TE_SetupGlowSprite(fVec, BlueGlowSprite, 1.0, 0.3, 237);
				TE_SendToAll();
			}
		}
	}
	PrintHintTextToAll("T Spawns: %i \nCT Spawns: %i", tsCount, ctsCount);

	return Plugin_Continue;
}

/***********************************************************/
/****************** REMOVE DEFAULT SPAWN *******************/
/***********************************************************/
void RemoveAllDefaultSpawns()
{
	int maxent = GetMaxEntities();
	char sClassName[64];
	for(int i = MaxClients; i < maxent; i++)
	{
		if(IsValidEdict(i) && IsValidEntity(i) && GetEdictClassname(i, sClassName, sizeof(sClassName)) && (StrEqual(sClassName, "info_player_terrorist") || StrEqual(sClassName, "info_player_counterterrorist")))
		{
			RemoveEdict(i);
		}
	}
}

/***********************************************************/
/******************* REMOVE SINGLE SPAWN *******************/
/***********************************************************/
void RemoveSingleDefaultSpawn(float fVec[3])
{
	int maxent = GetMaxEntities();
	char sClassName[64]; 
	float ent_fVec[3];
	for(int i = MaxClients; i < maxent; i++)
	{
		if(IsValidEdict(i) && IsValidEntity(i) && GetEdictClassname(i, sClassName, sizeof(sClassName)) &&(StrEqual(sClassName, "info_player_terrorist") || StrEqual(sClassName, "info_player_counterterrorist")))
		{
			GetEntPropVector(i, Prop_Data, "m_vecOrigin", ent_fVec);
			if (fVec[0] == ent_fVec[0])
			{
				RemoveEdict(i);
				break;
			}
		}
	}
}

/***********************************************************/
/********************* INIT NEW SPAWN **********************/
/***********************************************************/
void InitializeNewSpawn(int client, int team)
{
	float DataFloats[5], posVec[3], angVec[3];
	GetClientAbsOrigin(client, posVec);
	GetClientEyeAngles(client, angVec);
	DataFloats[0] = posVec[0];
	DataFloats[1] = posVec[1];
	DataFloats[2] = (posVec[2] + 16.0);
	DataFloats[3] = angVec[1];
	DataFloats[4] = float(team);

	if(CreateSpawn(DataFloats, true))
	{
		PrintToChatAll("[Spawns] New spawn point created!");
	}
	else
	{
		LogError("failed to create new sp entity");
	}
}

/***********************************************************/
/********************** CREATE SPAWN ***********************/
/***********************************************************/
bool CreateSpawn(float DataFloats[5], bool isNew)
{
	float posVec[3], angVec[3];
	posVec[0] = DataFloats[0];
	posVec[1] = DataFloats[1];
	posVec[2] = DataFloats[2];
	angVec[0] = 0.0;
	angVec[1] = DataFloats[3];
	angVec[2] = 0.0;

	int entity = CreateEntityByName(DataFloats[4] == 2.0 ? "info_player_terrorist" : "info_player_counterterrorist");
	if(DispatchSpawn(entity))
	{
		TeleportEntity(entity, posVec, angVec, NULL_VECTOR);
		if (isNew)
		{
			PushArrayArray(CustSpawnsADT, DataFloats);
		}

		return true;
	}

	return false;
}

/***********************************************************/
/********************** REMOVE SPAWN ***********************/
/***********************************************************/
bool RemoveSpawn(int client)
{
	int arraySize = GetArraySize(CustSpawnsADT);
	int maxent = GetMaxEntities();
	float client_posVec[3], DataFloats[5], ent_posVec[3];
	char sClassName[64];
	int i, d;
	GetClientAbsOrigin(client, client_posVec);
	client_posVec[2] += 16;
	for(d = MaxClients; d < maxent; d++)
	{
		if (IsValidEdict(d) && IsValidEntity(d) && GetEdictClassname(d, sClassName, sizeof(sClassName)) && (StrEqual(sClassName, "info_player_terrorist") || StrEqual(sClassName, "info_player_counterterrorist")))
		{
			GetEntPropVector(d, Prop_Data, "m_vecOrigin", ent_posVec);
			if (GetVectorDistance(client_posVec, ent_posVec) < 42.7)
			{
				for (i = 0; i < arraySize; i++)
				{
					GetArrayArray(CustSpawnsADT, i, DataFloats);
					if (DataFloats[0] == ent_posVec[0])
					{
						/* spawn was custom */
						RemoveFromArray(CustSpawnsADT, i);
						RemoveEdict(d);

						return true;
					}
				}
				/* spawn was default */
				PushArrayArray(KillSpawnsADT, ent_posVec);
				RemoveEdict(d);

				return true;
			}
		}
	}
	
	return false;
}

/***********************************************************/
/*********************** SAVE CONFIG ***********************/
/***********************************************************/
void SaveConfiguration()
{
	Handle kv = CreateKeyValues("ST7Root");
	int arraySize;
	char sBuffer[32];
	float DataFloats[5], posVec[3];
	KvJumpToKey(kv, "smdata", true);
	KvSetNum(kv, "remdefsp", RemoveDefSpawns == true ? 1 : 0);
	arraySize = GetArraySize(CustSpawnsADT);
	
	if (arraySize)
	{
		for (int i = 0; i < arraySize; i++)
		{
			GetArrayArray(CustSpawnsADT, i, DataFloats);
			posVec[0] = DataFloats[0];
			posVec[1] = DataFloats[1];
			posVec[2] = DataFloats[2];
			Format(sBuffer, sizeof(sBuffer), "ns:%d:pos", i);
			KvSetVector(kv, sBuffer, posVec);
			Format(sBuffer, sizeof(sBuffer), "ns:%d:ang", i);
			KvSetFloat(kv, sBuffer, DataFloats[3]);
			Format(sBuffer, sizeof(sBuffer), "ns:%d:team", i);
			KvSetFloat(kv, sBuffer, DataFloats[4]);
		}
	}
	
	arraySize = GetArraySize(KillSpawnsADT);
	
	if (arraySize)
	{
		for (int i = 0; i < arraySize; i++)
		{
			GetArrayArray(KillSpawnsADT, i, posVec);
			Format(sBuffer, sizeof(sBuffer), "rs:%d:pos", i);
			KvSetVector(kv, sBuffer, posVec);
		}
	}
	
	if (KeyValuesToFile(kv, MapCfgPath))
	{
		PrintToChatAll("[Spawns] Configuration Saved!");
	}
	else
	{
		LogError("failed to save to key values");
	}

	CloseHandle(kv);
}

/***********************************************************/
/****************** ON ADMIN MENU READY ********************/
/***********************************************************/
public void OnAdminMenuReady(Handle topmenu)
{
	if(topmenu == hAdminMenu)
	{
		return;
	}

	hAdminMenu = topmenu;
	TopMenuObject menu = FindTopMenuCategory(hAdminMenu, "admin_menu_zombie_riot");
	AddToTopMenu(hAdminMenu, "sm_spawns", TopMenuObject_Item, TopMenuHandler, menu, "sm_spawns", ADMFLAG_RCON);
}

/***********************************************************/
/******************* ADMIN MENU ACTIONS ********************/
/***********************************************************/
public void TopMenuHandler(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Spawns");
	}

	else if (action == TopMenuAction_SelectOption)
	{
		ShowToolzMenu(param);
	}
}