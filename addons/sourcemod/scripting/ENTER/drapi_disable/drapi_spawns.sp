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
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[SPAWNS] -"
#define MAX_SPAWNS						200
#define MAX_SPAWNS_GAME					32

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
Handle cvar_spawns_change_timer;
Handle cvar_spawns_distance;

Handle Array_SpawnsCT;
Handle Array_SpawnsT;
Handle hAdminMenu 								= INVALID_HANDLE;

//Bool
bool B_cvar_active_spawns_dev					= false;

bool InEditMode;

//Floats
float F_spawns_change_timer;
float F_spawns_distance;

float F_spawns_ct[MAX_SPAWNS][3];
float F_spawns_t[MAX_SPAWNS][3];
float playerPositions[MAX_SPAWNS][3];

//Strings
char MapCfgPath[PLATFORM_MAX_PATH];

//Customs
int RandomSpawnsT;
int RedGlowSprite;
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
	
	cvar_spawns_change_timer		= AutoExecConfig_CreateConVar("drapi_spawns_change_timer", 			"30.0", 				"Timer to change the spawn T", 			DEFAULT_FLAGS);
	cvar_spawns_distance			= AutoExecConfig_CreateConVar("drapi_spawns_distance", 				"1000.0", 				"Spawn more than x units are free", 	DEFAULT_FLAGS);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	
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
	
	Array_SpawnsCT = CreateArray(3);
	Array_SpawnsT = CreateArray(3);
	
	//CreateTimer(F_spawns_change_timer, Timer_RandomSpawnsT, INVALID_HANDLE, TIMER_REPEAT);
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
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEvents()
{
	HookConVarChange(cvar_active_spawns_dev, 				Event_CvarChange);
	
	HookConVarChange(cvar_spawns_change_timer, 				Event_CvarChange);
	HookConVarChange(cvar_spawns_distance, 					Event_CvarChange);
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
	
	F_spawns_change_timer 						= GetConVarFloat(cvar_spawns_change_timer);
	F_spawns_distance 							= GetConVarFloat(cvar_spawns_distance);
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
	InEditMode 				= false;
	
	RedGlowSprite 			= PrecacheModel("sprites/redglow3.vmt");
	BlueGlowSprite 			= PrecacheModel("sprites/blueglow1.vmt");
	
	char mapName[64];
	GetCurrentMap(mapName, sizeof(mapName));
	BuildPath(Path_SM, MapCfgPath, sizeof(MapCfgPath), "configs/drapi/spawns/%s.cfg", mapName);
	ReadSpawnsFile();
	
	RemoveAllDefaultSpawns();
	SetDefaultSpawns();
	
	UpdateState();
}

/***********************************************************/
/********************** WHEN MAP END ***********************/
/***********************************************************/
public void OnMapEnd()
{
	ClearArray(Array_SpawnsCT);
	ClearArray(Array_SpawnsT);
}

/***********************************************************/
/************************ ROUND START **********************/
/***********************************************************/
public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if(!isWarmup())
	{
		SpawnTOutside();
		CreateTimer(20.0, Timer_RandomSpawnsT, INVALID_HANDLE);
	}
}

/***********************************************************/
/************************ ROUND START **********************/
/***********************************************************/
public void Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	SpawnTOutside();
}

/***********************************************************/
/******************* WHEN PLAYER SPAWN *********************/
/***********************************************************/
public void Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(GetClientTeam(client) == CS_TEAM_CT)
	{
		int arraySizeCT = GetArraySize(Array_SpawnsCT);
		
		if(arraySizeCT)
		{
			int random = GetRandomInt(0, arraySizeCT - 1);
			float F_origin_spawn_ct[3];
			
			GetArrayArray(Array_SpawnsCT, random, F_origin_spawn_ct);
			TeleportEntity(client, F_origin_spawn_ct, NULL_VECTOR, NULL_VECTOR);
			//PrintToDev(B_cvar_active_spawns_dev, "%s Spawn CT: %N, %f %f %f", TAG_CHAT, client, F_origin_spawn_ct[0], F_origin_spawn_ct[1], F_origin_spawn_ct[2]);
		}
	}
	else if(GetClientTeam(client) == CS_TEAM_T)
	{
		SpawnsTRandom(client);
	}
}

/***********************************************************/
/********************* SPAWN T OUTISDE *********************/
/***********************************************************/
void SpawnTOutside()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(Client_IsIngame(i) && GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i))
		{
			float vPos[3], vMins[3], vMaxs[3];
			GetEntPropVector(0, Prop_Data, "m_WorldMins", vMins);
			GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vMaxs);
			vPos[0] = (vMins[0] + vMaxs[0]) / 2;
			vPos[1] = (vMins[1] + vMaxs[1]) / 2;
			vPos[2] = vMaxs[2] + 2000.0;
			TeleportEntity(i, vPos, NULL_VECTOR, NULL_VECTOR);
		}
	}
}

/***********************************************************/
/***************** TIMER RANDOM SPAWNS T *******************/
/***********************************************************/
public Action Timer_RandomSpawnsT(Handle timer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(Client_IsIngame(i) && GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i))
		{
			SpawnsTRandom(i);
		}
	}
}

/***********************************************************/
/******************** RANDOM SPAWNS T **********************/
/***********************************************************/
void SpawnsTRandom(int client)
{
	int arraySizeT = GetArraySize(Array_SpawnsT);
	Handle Array_SpawnsTFree = CreateArray(1);
	
	if(arraySizeT)
	{
		int numberOfAlivePlayers = 0;

		for(int i = 1; i <= MaxClients; i++)
		{
			if(Client_IsIngame(i) && GetClientTeam(i) == CS_TEAM_CT && IsPlayerAlive(i))
			{
				GetClientAbsOrigin(i, playerPositions[numberOfAlivePlayers]);
				numberOfAlivePlayers++;
			}
		}
		
		for(int i = 0; i < arraySizeT; i++)
		{
			for(int j = 0; j < numberOfAlivePlayers; j++)
			{
				float F_origin_spawn[3];
				GetArrayArray(Array_SpawnsT, i, F_origin_spawn);
				float distance = GetVectorDistance(F_origin_spawn, playerPositions[j]);
				
				char key[64];
				IntToString(i, key, 64);
					
				if(distance > F_spawns_distance)
				{
					PushArrayString(Array_SpawnsTFree, key);
					//PrintToDev(B_cvar_active_spawns_dev, "%s Spawn (%f): %i", TAG_CHAT, distance, i);
				}
				else
				{
					if(FindStringInArray(Array_SpawnsTFree, key) != -1)
					{
						RemoveFromArray(Array_SpawnsTFree, FindStringInArray(Array_SpawnsTFree, key));
						PrintToDev(B_cvar_active_spawns_dev, "Remove (%f): %i - %N", distance, i, j);
					}
				}
			}		
		}
		
		int arraySizeTFree = GetArraySize(Array_SpawnsTFree);
		
		if(arraySizeTFree)
		{
			int random = GetRandomInt(0, arraySizeTFree - 1);
			char GetSpawnTFreeID[64]; 
			GetArrayString(Array_SpawnsTFree, random, GetSpawnTFreeID, sizeof(GetSpawnTFreeID));
			
			RandomSpawnsT = StringToInt(GetSpawnTFreeID);
			//PrintToDev(B_cvar_active_spawns_dev, "%s Spawn T Free(%f): %i", TAG_CHAT, F_spawns_distance, RandomSpawnsT);
		}
		else
		{
			RandomSpawnsT = GetRandomInt(0, arraySizeT - 1);
			//PrintToDev(B_cvar_active_spawns_dev, "%s Spawn T Not Free: %i", TAG_CHAT, RandomSpawnsT);
		}
		
		float F_origin_spawn_t[3];
		GetArrayArray(Array_SpawnsT, RandomSpawnsT, F_origin_spawn_t);
		TeleportEntity(client, F_origin_spawn_t, NULL_VECTOR, NULL_VECTOR);
		//PrintToDev(B_cvar_active_spawns_dev, "%s Spawn T: %N, %f %f %f", TAG_CHAT, client, F_origin_spawn_t[0], F_origin_spawn_t[1], F_origin_spawn_t[2]);
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if(Client_IsIngame(i) && GetClientTeam(i) == CS_TEAM_CT && IsPlayerAlive(i))
			{
				float F_origin_client[3];
				GetClientAbsOrigin(i, F_origin_client);
				float distance = GetVectorDistance(F_origin_spawn_t, F_origin_client);
				PrintToDev(B_cvar_active_spawns_dev,"R: %i - %N/%N - %f", RandomSpawnsT, client, i, distance);
			}
		}
		
		ClearArray(Array_SpawnsTFree);
	}
}

/***********************************************************/
/******************* COMMAND MENU SPAWN ********************/
/***********************************************************/
public Action Command_MenuSpawns(int client, int args)
{
	BuildMenuSpawns(client);
	return Plugin_Handled;
}

/***********************************************************/
/*********************** BUILD MENU ************************/
/***********************************************************/
void BuildMenuSpawns(int client)
{
	Menu menu = CreateMenu(MenuSpawnsAction);
	
	char menuItem[64];
	Format(menuItem, sizeof(menuItem), "%s Edit Mode", InEditMode == false ? "Enable" : "Disable");
	AddMenuItem(menu, "M_GLOW", menuItem);
	
	AddMenuItem(menu, "M_CT", "Spawns CT");
	AddMenuItem(menu, "M_T", "Spawns T");

	SetMenuTitle(menu, "Spawns");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

/***********************************************************/
/********************** MENU ACTIONS ***********************/
/***********************************************************/
public int MenuSpawnsAction(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);	
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hAdminMenu
				, param1, TopMenuPosition_Start);
			}	
		}
		case MenuAction_Select:
		{
			char menu1[56];
			menu.GetItem(param2, menu1, sizeof(menu1));
			
			if(StrEqual(menu1, "M_CT"))
			{
				BuildMenuSpawnsCT(param1);
			}
			else if(StrEqual(menu1, "M_T"))
			{
				BuildMenuSpawnsT(param1);
			}
			else if(StrEqual(menu1, "M_GLOW"))
			{
				InEditMode = InEditMode == false ? true : false;
				PrintToChatAll("[Spawns] Edit Mode %s.", InEditMode == false ? "Disabled" : "Enabled");
				if(InEditMode)
				{
					CreateTimer(1.0, ShowEditModeGoodies, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
				BuildMenuSpawns(param1);
			}
		}
	}
}

/***********************************************************/
/******************* BUILD MENU SPAWN CT *******************/
/***********************************************************/
void BuildMenuSpawnsCT(int client)
{
	Menu menu = CreateMenu(MenuSpawnsCTAction);
	
	
	AddMenuItem(menu, "M_ADD_SPAWN_CT", "Add Spawn");
	AddMenuItem(menu, "M_REMOVE_SPAWN_CT", "Remove Spawn");
	AddMenuItem(menu, "M_SAVE", "Save configuration");

	SetMenuTitle(menu, "Spawns CT");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

/***********************************************************/
/****************** MENU ACTIONS SPAWN CT ******************/
/***********************************************************/
public int MenuSpawnsCTAction(Menu menu, MenuAction action, int param1, int param2)
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
				BuildMenuSpawns(param1);
			}		
		}
		case MenuAction_Select:
		{
			char menu1[56];
			menu.GetItem(param2, menu1, sizeof(menu1));
			
			if(StrEqual(menu1, "M_ADD_SPAWN_CT"))
			{
				if(CreateSpawn(param1, 3))
				{
					ReplyToCommand(param1, "%s Spawn CT created", TAG_CHAT);
				}
				else
				{
					ReplyToCommand(param1, "%s Spawn CT not created", TAG_CHAT);
				}
				BuildMenuSpawnsCT(param1);
			}
			else if(StrEqual(menu1, "M_REMOVE_SPAWN_CT"))
			{
				
				if(RemoveSpawn(param1, 3))
				{
					ReplyToCommand(param1, "%s Spawn CT removed", TAG_CHAT);
				}
				else
				{
					ReplyToCommand(param1, "%s Spawn CT not removed", TAG_CHAT);
				}
				BuildMenuSpawnsCT(param1);
			}
			else if(StrEqual(menu1, "M_SAVE"))
			{
				SaveSpawnsFile();
				BuildMenuSpawnsCT(param1);
				
			}
		}
	}
}

/***********************************************************/
/******************* BUILD MENU SPAWN T ********************/
/***********************************************************/
void BuildMenuSpawnsT(int client)
{
	Menu menu = CreateMenu(MenuSpawnsTAction);
	
	AddMenuItem(menu, "M_ADD_SPAWN_T", "Add Spawn");
	AddMenuItem(menu, "M_REMOVE_SPAWN_T", "Remove Spawn");
	AddMenuItem(menu, "M_SAVE", "Save configuration");

	SetMenuTitle(menu, "Spawns T");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

/***********************************************************/
/****************** MENU ACTIONS SPAWN T *******************/
/***********************************************************/
public int MenuSpawnsTAction(Menu menu, MenuAction action, int param1, int param2)
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
				BuildMenuSpawns(param1);
			}		
		}
		case MenuAction_Select:
		{
			char menu1[56];
			menu.GetItem(param2, menu1, sizeof(menu1));
			
			if(StrEqual(menu1, "M_ADD_SPAWN_T"))
			{
				if(CreateSpawn(param1, 2))
				{
					ReplyToCommand(param1, "%s Spawn T created", TAG_CHAT);
				}
				else
				{
					ReplyToCommand(param1, "%s Spawn T not created", TAG_CHAT);
				}
				BuildMenuSpawnsT(param1);
			}
			else if(StrEqual(menu1, "M_REMOVE_SPAWN_T"))
			{
				
				if(RemoveSpawn(param1, 2))
				{
					ReplyToCommand(param1, "%s Spawn T removed", TAG_CHAT);
				}
				else
				{
					ReplyToCommand(param1, "%s Spawn T not removed", TAG_CHAT);
				}
				BuildMenuSpawnsT(param1);
			}
			else if(StrEqual(menu1, "M_SAVE"))
			{
				SaveSpawnsFile();
				BuildMenuSpawnsT(param1);
				
			}
		}
	}
}

/***********************************************************/
/********************* LOAD DAYS DATA **********************/
/***********************************************************/
void ReadSpawnsFile()
{
	Handle kv = CreateKeyValues("Spawns");
	FileToKeyValues(kv, MapCfgPath);
	
	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			char Sname[64];
			KvGetSectionName(kv, Sname, 64);
			
			if(StrEqual(Sname, "CT", false))
			{
				char S_spawns_ct[MAX_SPAWNS];
				for(int i = 1; i <= MAX_SPAWNS; ++i)
				{
					char key[64];
					IntToString(i, key, 64);
					
					if(KvGetString(kv, key, S_spawns_ct[i], 64) && strlen(S_spawns_ct[i]))
					{
						char explode[3][64];
						ExplodeString(S_spawns_ct[i], " ", explode, 3, 64);
						
						for(int f = 0; f < 3; f++)
						{
							F_spawns_ct[i][f] = StringToFloat(explode[f]);
							//LogMessage("%s [%i] - Spawn CT [%i]: %f", TAG_CHAT, i, f, F_spawns_ct[i][f]);
						}
					}
					else
					{
						break;
					}
					
					PushArrayArray(Array_SpawnsCT, F_spawns_ct[i]);
				}	
				
								
			}
			else if(StrEqual(Sname, "T", false))
			{
				char S_spawns_t[MAX_SPAWNS];
				for(int i = 1; i <= MAX_SPAWNS; ++i)
				{
					char key[64];
					IntToString(i, key, 64);
					
					if(KvGetString(kv, key, S_spawns_t[i], 64) && strlen(S_spawns_t[i]))
					{
						char explode[3][64];
						ExplodeString(S_spawns_t[i], " ", explode, 3, 64);
						
						for(int f = 0; f < 3; f++)
						{
							F_spawns_t[i][f] = StringToFloat(explode[f]);
							//LogMessage("%s [%i] - Spawn T [%i]: %f", TAG_CHAT, i, f, F_spawns_t[i][f]);
						}
					}
					else
					{
						break;
					}
					
					PushArrayArray(Array_SpawnsT, F_spawns_t[i]);
					
				}	
			}
		}
		while (KvGotoNextKey(kv));
	}
	CloseHandle(kv);
}

/***********************************************************/
/********************* LOAD DAYS DATA **********************/
/***********************************************************/
void SaveSpawnsFile()
{
	Handle kv = CreateKeyValues("Spawns");
	KvJumpToKey(kv, "Spawns", true);
	
	int arraySizeCT = GetArraySize(Array_SpawnsCT);
	float F_origin_spawn_ct[3], F_origin_spawn_t[3];
	
	KvJumpToKey(kv, "CT", true);
	
	if(arraySizeCT)
	{
		for(int i = 0; i < arraySizeCT; i++)
		{
			GetArrayArray(Array_SpawnsCT, i, F_origin_spawn_ct);
			
			char key[64], value[64];
			
			IntToString(i+1, key, 64);
			Format(value, sizeof(value), "%f %f %f", F_origin_spawn_ct[0], F_origin_spawn_ct[1], F_origin_spawn_ct[2]);
			
			KvSetString(kv, key, value);
			
		}
		KvGoBack(kv);
	}
	
	
	int arraySizeT = GetArraySize(Array_SpawnsT);
	KvJumpToKey(kv, "T", true);
	if(arraySizeT)
	{
		for(int i = 0; i < arraySizeT; i++)
		{
			GetArrayArray(Array_SpawnsT, i, F_origin_spawn_t);
			
			char key[64], value[64];
			
			IntToString(i+1, key, 64);
			Format(value, sizeof(value), "%f %f %f", F_origin_spawn_t[0], F_origin_spawn_t[1], F_origin_spawn_t[2]);
			
			KvSetString(kv, key, value);
			
		}
		KvGoBack(kv);
	}
	
	if(KeyValuesToFile(kv, MapCfgPath))
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
/********************** CREATE SPAWN ***********************/
/***********************************************************/
bool CreateSpawn(int client, int team)
{
	float F_origin_client[3];
	
	GetClientAbsOrigin(client, F_origin_client);
	
	F_origin_client[2] += 16;
	
	if(team == 3)
	{
		PushArrayArray(Array_SpawnsCT, F_origin_client);
		return true;
	}
	else if(team == 2)
	{
		PushArrayArray(Array_SpawnsT, F_origin_client);
		return true;
	}
	
	return false;
}

/***********************************************************/
/********************** REMOVE SPAWN ***********************/
/***********************************************************/
bool RemoveSpawn(int client, int team)
{
	float F_origin_client[3], F_origin_spawn[3];
	GetClientAbsOrigin(client, F_origin_client);
	F_origin_client[2] += 16;
	
	if(team == 3)
	{
		int arraySizeCT = GetArraySize(Array_SpawnsCT);
		
		for(int i = 0; i < arraySizeCT; i++)
		{
			GetArrayArray(Array_SpawnsCT, i, F_origin_spawn);
			
			if(GetVectorDistance(F_origin_client, F_origin_spawn) < 42.7)
			{
				RemoveFromArray(Array_SpawnsCT, i);
				return true;
			}
		}
	}
	else if(team == 2)
	{
		int arraySizeT = GetArraySize(Array_SpawnsT);
		
		for(int i = 0; i < arraySizeT; i++)
		{
			GetArrayArray(Array_SpawnsT, i, F_origin_spawn);
			
			if(GetVectorDistance(F_origin_client, F_origin_spawn) < 42.7)
			{
				RemoveFromArray(Array_SpawnsT, i);
				return true;
			}
		}
	}
	
	return false;
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
	
	int arraySizeCT = GetArraySize(Array_SpawnsCT);
	
	for(int i = 0; i < arraySizeCT; i++)
	{
		float F_origin_spawn[3];
		GetArrayArray(Array_SpawnsCT, i, F_origin_spawn);
		TE_SetupGlowSprite(F_origin_spawn, BlueGlowSprite, 1.0, 0.4, 249);
		TE_SendToAll();
	}
	
	int arraySizeT = GetArraySize(Array_SpawnsT);
	
	for(int i = 0; i < arraySizeT; i++)
	{
		float F_origin_spawn[3];
		GetArrayArray(Array_SpawnsT, i, F_origin_spawn);
		TE_SetupGlowSprite(F_origin_spawn, RedGlowSprite, 1.0, 0.4, 249);
		TE_SendToAll();
	}
	
	PrintHintTextToAll("T Spawns: %i \nCT Spawns: %i", arraySizeT, arraySizeCT);

	return Plugin_Continue;
}

/***********************************************************/
/****************** REMOVE DEFAULT SPAWN *******************/
/***********************************************************/
void RemoveAllDefaultSpawns()
{
	int arraySizeCT = GetArraySize(Array_SpawnsCT);
	int arraySizeT = GetArraySize(Array_SpawnsT);
	
	if(arraySizeCT && arraySizeT)
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
}

/***********************************************************/
/******************** GET BUY ZONE MAP *********************/
/***********************************************************/
void SetDefaultSpawns()
{
	float vPos[3], vAng[3];
	vAng[0] = 0.0;
	vAng[1] = -90.0;
	vAng[2] = 0.0;
	
	
	int arraySizeCT = GetArraySize(Array_SpawnsCT);
	if(arraySizeCT)
	{
		GetArrayArray(Array_SpawnsCT, 0, vPos);
		
		for(int i = 1; i <= MAX_SPAWNS_GAME; ++i)
		{
			int entity = CreateEntityByName("info_player_counterterrorist");
			if(DispatchSpawn(entity))
			{	
				TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
			}
		}
		//LogMessage("%s info_player_counterterrorist: %f %f %f", TAG_CHAT, vPos[0], vPos[1], vPos[2]);

	}
	
	int arraySizeT = GetArraySize(Array_SpawnsT);
	if(arraySizeT)
	{
		GetArrayArray(Array_SpawnsT, 0, vPos);
		
		for(int i = 1; i <= MAX_SPAWNS_GAME; ++i)
		{
			int entity = CreateEntityByName("info_player_terrorist");
			if(DispatchSpawn(entity))
			{	
				TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
			}
		}
		//LogMessage("%s info_player_terrorist: %f %f %f", TAG_CHAT, vPos[0], vPos[1], vPos[2]);

	}
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
		BuildMenuSpawns(param);
	}
}

/***********************************************************/
/***************** TIMER RANDOM SPAWNS T *******************/
/***********************************************************/
/*
public Action Timer_RandomSpawnsT(Handle timer)
{
	int arraySizeT = GetArraySize(Array_SpawnsT);
	Handle Array_SpawnsTFree = CreateArray(1);
	
	if(arraySizeT)
	{
		int numberOfAlivePlayers = 0;

		for(int i = 1; i <= MaxClients; i++)
		{
			if(Client_IsIngame(i) && GetClientTeam(i) == CS_TEAM_CT && IsPlayerAlive(i))
			{
				GetClientAbsOrigin(i, playerPositions[numberOfAlivePlayers]);
				numberOfAlivePlayers++;
			}
		}
		
		for(int i = 0; i < arraySizeT; i++)
		{
			for(int j = 0; j < numberOfAlivePlayers; j++)
			{
				float F_origin_spawn[3];
				GetArrayArray(Array_SpawnsT, i, F_origin_spawn);
				float distance = GetVectorDistance(F_origin_spawn, playerPositions[j]);
				
				if(distance > F_spawns_distance)
				{
					char key[64];
					IntToString(i, key, 64);
					PushArrayString(Array_SpawnsTFree, key);
					PrintToDev(B_cvar_active_spawns_dev, "%s Spawn (%f): %i", TAG_CHAT, F_spawns_distance, i);
					break;
				}
			}		
		}
		
		int arraySizeTFree = GetArraySize(Array_SpawnsTFree);
		if(arraySizeTFree)
		{
			int random = GetRandomInt(0, arraySizeTFree - 1);
			char GetSpawnTFreeID[64]; 
			GetArrayString(Array_SpawnsTFree, random, GetSpawnTFreeID, sizeof(GetSpawnTFreeID));
			
			RandomSpawnsT = StringToInt(GetSpawnTFreeID);
			PrintToDev(B_cvar_active_spawns_dev, "%s Spawn T Free(%f): %i", TAG_CHAT, F_spawns_distance, RandomSpawnsT);
		}
		else
		{
			RandomSpawnsT = GetRandomInt(0, arraySizeT - 1);
			PrintToDev(B_cvar_active_spawns_dev, "%s Spawn T Not Free: %i", TAG_CHAT, RandomSpawnsT);
		}
		
		ClearArray(Array_SpawnsTFree);
		
		PrintToDev(B_cvar_active_spawns_dev,"%s Random: %i", TAG_CHAT, RandomSpawnsT);
		return Plugin_Continue;
	}
	else
	{
		return Plugin_Stop;
	}
}
*/