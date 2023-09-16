/*    <DR.API PROJECTORS> (c) by <De Battista Clint - (http://doyou.watch)   */
/*                                                                           */
/*                 <DR.API PROJECTORS> is licensed under a                   */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//****************************DR.API PROJECTORS******************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[PROJECTORS] -"

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <stocks>
#include <zombie_riot>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//DEFINES
#define 													MAX_PROJECTOR 25
#define 													MAX_SPAWNS 25
		
//HANDLE
Handle cvar_active_projectors_dev;

Handle hAdminMenu 											= INVALID_HANDLE;

//BOOL
bool B_cvar_active_projectors_dev							= false;
bool inEditMode 											= false;

//INT
int C_Projector[MAX_PROJECTOR]								= INVALID_ENT_REFERENCE;
int C_ProjectorLight[MAX_PROJECTOR]							= INVALID_ENT_REFERENCE;
int C_ProjectorLight2[MAX_PROJECTOR]						= INVALID_ENT_REFERENCE;
int C_ProjectorLight3[MAX_PROJECTOR]						= INVALID_ENT_REFERENCE;
int INT_PROJECTOR_COUNT										= 0;
int lastEditorSpawnPoint[MAXPLAYERS + 1] 					= { -1, ... };
int spawnPointCount 										= 0;
int glowSprite;

//FLOATS
float spawnPositions[MAX_SPAWNS][3];
float spawnAngles[MAX_SPAWNS][3];
float spawnPointOffset[3] 									= { 0.0, 0.0, 20.0 };


//Informations plugin
public Plugin myinfo =
{
	name = "DR.API PROJECTORS",
	author = "Dr. Api",
	description = "DR.API PROJECTORS by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://doyou.watch"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	AutoExecConfig_SetFile("drapi_projectors", "sourcemod/drapi");
	LoadTranslations("drapi/drapi_projectors.phrases");
	
	AutoExecConfig_CreateConVar("drapi_projectors_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_projectors_dev						= AutoExecConfig_CreateConVar("drapi_active_projectors_dev", 			"0", 					"Enable/Disable Dev Mod", 											DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	RegAdminCmd("sm_projector", 		Command_Projector, 			ADMFLAG_CHANGEMAP, "");
	RegAdminCmd("sm_deleteprojector", 	Command_DeleteProjector, 	ADMFLAG_CHANGEMAP, "");
	
	RegAdminCmd("sm_projectorspawn", 	Command_SpawnMenu, 		ADMFLAG_CHANGEMAP, "Opens the spawn menu.");
	
	HookEvent("round_start", Event_RoundStart);
	
	HookEvents();
	
	AutoExecConfig_ExecuteFile();
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
	HookConVarChange(cvar_active_projectors_dev, 				Event_CvarChange);
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
	B_cvar_active_projectors_dev 					= GetConVarBool(cvar_active_projectors_dev);
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
	AddFileToDownloadsTable("models/props_vehicles/radio_generator.mdl");
	AddFileToDownloadsTable("models/props_vehicles/radio_generator.phy");
	AddFileToDownloadsTable("models/props_vehicles/radio_generator.vvd");
	AddFileToDownloadsTable("models/props_vehicles/radio_generator.dx90.vtx");
	
	AddFileToDownloadsTable("materials/models/props_vehicles/floodlight_generator.vmt");
	AddFileToDownloadsTable("materials/models/props_vehicles/floodlight_generator.vtf");
	
	PrecacheModel("models/props_vehicles/radio_generator.mdl", true);
	glowSprite = PrecacheModel("sprites/glow01.vmt", true);
	
	LoadMapConfig();
	UpdateState();
}

/***********************************************************/
/******************** WHEN ROUND START *********************/
/***********************************************************/
public void Event_RoundStart(Handle event, char[] name, bool dontBroadcast)
{
	if(spawnPointCount > 0)
	{
		for (int i = 0; i < spawnPointCount; i++)
		{
			CreateEntity(-1, i, "prop_dynamic", 1, "models/props_vehicles/radio_generator.mdl", spawnPositions[i], spawnAngles[i]);
			CreateEntity(-1, i, "point_spotlight", 2, "", spawnPositions[i], spawnAngles[i]);
			CreateEntity(-1, i, "point_spotlight", 3, "", spawnPositions[i], spawnAngles[i]);
			CreateEntity(-1, i, "light_dynamic", 4, "", spawnPositions[i], spawnAngles[i]);

			PrintToDev(B_cvar_active_projectors_dev,"%s Spawn count: %i", TAG_CHAT, i);		
		}
	}
}

/***********************************************************/
/********************* ADD PROJECTOR ***********************/
/***********************************************************/
public Action Command_Projector(int client, int args)
{
	if(INT_PROJECTOR_COUNT < MAX_PROJECTOR)
	{
		float pos[3], ang[3], Angles[3];
		GetClientAbsOrigin(client, pos);
		GetClientAbsAngles(client, ang);

		Angles[1] += ang[1] - 90.0;
		
		CreateEntity(-1, INT_PROJECTOR_COUNT, "prop_dynamic", 1, "models/props_vehicles/radio_generator.mdl", pos, Angles);
	
		CreateEntity(-1, INT_PROJECTOR_COUNT, "point_spotlight", 2, "", pos, Angles);
		CreateEntity(-1, INT_PROJECTOR_COUNT, "point_spotlight", 3, "", pos, Angles);
		CreateEntity(-1, INT_PROJECTOR_COUNT, "light_dynamic", 4, "", pos, Angles);
		
		
		PrintToDev(B_cvar_active_projectors_dev, "%s Index: %i", TAG_CHAT, INT_PROJECTOR_COUNT);
		INT_PROJECTOR_COUNT += 1;
		PrintToDev(B_cvar_active_projectors_dev, "%s Next index: %i", TAG_CHAT, INT_PROJECTOR_COUNT);
	}
}

/***********************************************************/
/******************* DELETE PROJECTOR **********************/
/***********************************************************/
public Action Command_DeleteProjector(int client, int args)
{
	for (int i = 0; i < INT_PROJECTOR_COUNT; i++)
	{
		if(IsValidEntity(C_Projector[i]))RemoveEntity(C_Projector[i], false);
		if(IsValidEntity(C_ProjectorLight[i]))RemoveEntity(C_ProjectorLight[i], true);
		if(IsValidEntity(C_ProjectorLight2[i]))RemoveEntity(C_ProjectorLight2[i], true);
		if(IsValidEntity(C_ProjectorLight3[i]))RemoveEntity(C_ProjectorLight3[i], true);
		
		PrintToDev(B_cvar_active_projectors_dev, "%s Index: %i", TAG_CHAT, i);
	}
	INT_PROJECTOR_COUNT = 0;
}
/***********************************************************/
/********************* CREATE ENTITY ***********************/
/***********************************************************/
bool CreateEntity(int client, int index=0, char[] entType, int option, char[] modelName, float vOrigin[3], float vAngles[3])
{
	int prop = -1;
	
	if (!IsModelPrecached(modelName))
	{
    	if(!PrecacheModel(modelName))
    	{
    		return false;
    	}
    }
	
	prop = CreateEntityByName(entType);
    
	if (IsValidEntity(prop)) 
	{
		if(strlen(modelName))
		{
			DispatchKeyValue(prop, "model", modelName);
		}
		
		if(option == 1)
		{
			DispatchSpawn(prop);
			
			DispatchKeyValue(prop, "Solid", "0");
			
			AcceptEntityInput(prop, "DisableCollision");
			//AcceptEntityInput(prop, "EnableCollision");
			SetEntProp(prop, Prop_Data, "m_takedamage", 0);
			
			TeleportEntity(prop, vOrigin, vAngles, NULL_VECTOR);
			DispatchSpawn(prop);
			
			C_Projector[index]	= EntIndexToEntRef(prop);
		}
		else if(option == 2)
		{
			DispatchKeyValue(prop, "rendercolor", "250 250 200");
			DispatchKeyValue(prop, "rendermode", "9");
			//DispatchKeyValue(prop, "renderfx", "1");
			DispatchKeyValue(prop, "spotlightwidth", "30");
			DispatchKeyValue(prop, "spotlightlength", "500");
			DispatchKeyValue(prop, "renderamt", "200");
			DispatchKeyValue(prop, "spawnflags", "1");
			
			DispatchSpawn(prop);
			AcceptEntityInput(prop, "TurnOn");
			
			float vTargetOrigin[3], vTargetAngles[3], vTargetBaseAngles[3];
			vTargetOrigin = vOrigin;
			vTargetBaseAngles = vAngles;
			
			vTargetBaseAngles[2] -= 37;
			
			vTargetAngles[0] = DegToRad(vAngles[0]);
			vTargetAngles[1] = DegToRad(vAngles[1]);
			
			vTargetOrigin[0] += 15.0 * Cosine(vTargetAngles[0]) * Cosine(vTargetAngles[1]);
			vTargetOrigin[1] += 15.0 * Cosine(vTargetAngles[0]) * Sine(vTargetAngles[1]);
			vTargetOrigin[2] += 320;
			
			RotateYaw(vTargetBaseAngles, 90.0);
			TeleportEntity(prop, vTargetOrigin, vTargetBaseAngles, NULL_VECTOR);
				

			C_ProjectorLight[index]	= EntIndexToEntRef(prop);					
		}
		else if(option == 3)
		{
			DispatchKeyValue(prop, "rendercolor", "250 250 200");
			DispatchKeyValue(prop, "rendermode", "9");
			//DispatchKeyValue(prop, "renderfx", "1");
			DispatchKeyValue(prop, "spotlightwidth", "30");
			DispatchKeyValue(prop, "spotlightlength", "500");
			DispatchKeyValue(prop, "renderamt", "200");
			DispatchKeyValue(prop, "spawnflags", "1");

			DispatchSpawn(prop);
			AcceptEntityInput(prop, "TurnOn");

			float vTargetOrigin[3], vTargetAngles[3], vTargetBaseAngles[3];
			vTargetOrigin = vOrigin;
			vTargetBaseAngles = vAngles;
			
			vTargetBaseAngles[2] -= 37;
			
			vTargetAngles[0] = DegToRad(vAngles[0]);
			vTargetAngles[1] = DegToRad(vAngles[1]);
			
			vTargetOrigin[0] += -25.0 * Cosine(vTargetAngles[0]) * Cosine(vTargetAngles[1]);
			vTargetOrigin[1] += -25.0 * Cosine(vTargetAngles[0]) * Sine(vTargetAngles[1]);
			vTargetOrigin[2] += 320;
			
			RotateYaw(vTargetBaseAngles, 90.0);
			TeleportEntity(prop, vTargetOrigin, vTargetBaseAngles, NULL_VECTOR);

			C_ProjectorLight2[index]	= EntIndexToEntRef(prop);	
		}
		else if(option == 4)
		{
			DispatchKeyValue(prop, "brightness", "0");
			DispatchKeyValueFloat(prop, "spotlight_radius", 100.0);
			DispatchKeyValueFloat(prop, "distance", 500.0);
			DispatchKeyValue(prop, "_light", "255 255 255 50");
			DispatchKeyValue(prop, "style", "0");
			DispatchSpawn(prop);
			AcceptEntityInput(prop, "TurnOn");	
			
			float vTargetOrigin[3], vTargetAngles[3], vTargetBaseAngles[3];
			vTargetOrigin = vOrigin;
			vTargetBaseAngles = vAngles;
			
			vTargetBaseAngles[2] -= 37;
			
			vTargetAngles[0] = DegToRad(vAngles[0]);
			vTargetAngles[1] = DegToRad(vAngles[1]);
			
			vTargetOrigin[0] += -25.0 * Cosine(vTargetAngles[0]) * Cosine(vTargetAngles[1]);
			vTargetOrigin[1] += -25.0 * Cosine(vTargetAngles[0]) * Sine(vTargetAngles[1]);
			vTargetOrigin[2] += 320;
			
			RotateYaw(vTargetBaseAngles, 90.0);
			
			Handle trace = TR_TraceRayFilterEx(vTargetOrigin, vTargetBaseAngles, MASK_SHOT, RayType_Infinite, FilterSelf);

			if(TR_DidHit(trace))
			{
				TR_GetEndPosition(vTargetOrigin, trace);
				vTargetOrigin[2] += 50;
				TeleportEntity(prop, vTargetOrigin, vTargetBaseAngles, NULL_VECTOR);
			}
			CloseHandle(trace);
			
			if(client)
			{
				SDKHook(prop, SDKHook_SetTransmit, SetTransmitLight);
			}
			
			C_ProjectorLight3[index]	= EntIndexToEntRef(prop);
		}
	}
	else
	{
		return false;
	}
	return true;
}

/***********************************************************/
/****************** SET TRANSMIT LIGHT *********************/
/***********************************************************/
public Action SetTransmitLight(int entity, int client)
{
	float lightpos[3], clientpos[3];
	GetClientAbsOrigin(client, clientpos);
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", lightpos);
	
	float distance = GetVectorDistance(clientpos, lightpos);
	
	//PrintToDev(B_cvar_active_projectors_dev, "%s Distance: %f", TAG_CHAT, distance);
	
	if(distance <= 1000.0)
	{
		DispatchKeyValueFloat(entity, "distance", 1000.0 - distance);
		//PrintToDev(B_cvar_active_projectors_dev, "%s Light: 255", TAG_CHAT);
		return Plugin_Continue;
	}
	else
	{
		DispatchKeyValueFloat(entity, "distance", 0.0);
		//PrintToDev(B_cvar_active_projectors_dev, "%s Light: 0", TAG_CHAT);
		return Plugin_Continue;
	}
}

/***********************************************************/
/********************* REMOVE ENTITY ***********************/
/***********************************************************/
void RemoveEntity(int Ref, bool light)
{

	int entity = EntRefToEntIndex(Ref);
	if (entity != -1)
	{
		if(light) AcceptEntityInput(entity, "LightOff");
		AcceptEntityInput(entity, "Kill");
		Ref = INVALID_ENT_REFERENCE;
	}
		
}

/***********************************************************/
/************************* FILTER **************************/
/***********************************************************/
public bool FilterSelf(int entity, int mask, any data)
{
	if (entity == data)
	{
		return false; //entity hit itself, ignore this hit
	}
	return true; //entity did not hit itself, target is valid
}

/***********************************************************/
/*********************** ROTATE YAW ************************/
/***********************************************************/
void RotateYaw(float angles[3], float degree )
{
	float direction[3], normal[3];
	GetAngleVectors( angles, direction, NULL_VECTOR, normal );

	float sin = Sine( degree * 0.01745328 );	 // Pi/180
	float cos = Cosine( degree * 0.01745328 );
	float a = normal[0] * sin;
	float b = normal[1] * sin;
	float c = normal[2] * sin;
	float x = direction[2] * b + direction[0] * cos - direction[1] * c;
	float y = direction[0] * c + direction[1] * cos - direction[2] * a;
	float z = direction[1] * a + direction[2] * cos - direction[0] * b;
	direction[0] = x;
	direction[1] = y;
	direction[2] = z;

	GetVectorAngles( direction, angles );

	float up[3];
	GetVectorVectors( direction, NULL_VECTOR, up );

	float roll = GetAngleBetweenVectors( up, normal, direction );
	angles[2] += roll;
}

/***********************************************************/
/*************** GET ANGLE BETWEEN VECTORS *****************/
/***********************************************************/
float GetAngleBetweenVectors(const float vector1[3], const float vector2[3], const float direction[3])
{
	float vector1_n[3], vector2_n[3], direction_n[3], cross[3];
	NormalizeVector(direction, direction_n);
	NormalizeVector(vector1, vector1_n);
	NormalizeVector(vector2, vector2_n);
	float degree = ArcCosine(GetVectorDotProduct(vector1_n, vector2_n)) * 57.29577951;   // 180/Pi
	GetVectorCrossProduct(vector1_n, vector2_n, cross);

	if(GetVectorDotProduct(cross, direction_n) < 0.0)
		degree *= -1.0;

	return degree;
}

/***********************************************************/
/*********************** MENU SPAWNS ***********************/
/***********************************************************/
public Action Command_SpawnMenu(int client,int args)
{
	DisplayMenu(BuildSpawnEditorMenu(), client, MENU_TIME_FOREVER);
}

/***********************************************************/
/******************** BUILD MENU SPAWNS ********************/
/***********************************************************/
Handle BuildSpawnEditorMenu()
{
	Menu menu = CreateMenu(Menu_SpawnEditor);
	menu.ExitBackButton = true;
	char editModeItem[24];
	Format(editModeItem, sizeof(editModeItem), "%s Edit Mode", (!inEditMode) ? "Enable" : "Disable");
	AddMenuItem(menu, "Edit", editModeItem);
	AddMenuItem(menu, "Nearest", "Teleport to nearest");
	AddMenuItem(menu, "Previous", "Teleport to previous");
	AddMenuItem(menu, "Next", "Teleport to next");
	AddMenuItem(menu, "Add", "Add position");
	AddMenuItem(menu, "Insert", "Insert position here");
	AddMenuItem(menu, "Delete", "Delete nearest");
	AddMenuItem(menu, "Delete All", "Delete all");
	AddMenuItem(menu, "Save", "Save Configuration");
	
	SetMenuTitle(menu, "Projectors Spawn Editor:");
	return menu;
}

/***********************************************************/
/******************** MENU SPAWNS EDITOR *******************/
/***********************************************************/
public int Menu_SpawnEditor(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
		}	
	}
	else if (action == MenuAction_Select)
	{
		char info[24];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "Edit"))
		{
			inEditMode = !inEditMode;
			if (inEditMode)
			{
				CreateTimer(1.0, RenderSpawnPoints, INVALID_HANDLE, TIMER_REPEAT);
				CPrintToChat(param1, "%t", "Spawn Editor Enabled");
			}
			else
				CPrintToChat(param1, "%t", "Spawn Editor Disabled");
		}
		else if (StrEqual(info, "Nearest"))
		{
			int spawnPoint = GetNearestSpawn(param1);
			if (spawnPoint != -1)
			{
				TeleportEntity(param1, spawnPositions[spawnPoint], spawnAngles[spawnPoint], NULL_VECTOR);
				lastEditorSpawnPoint[param1] = spawnPoint;
				CPrintToChat(param1, "%t #%i (%i total).", "Spawn Editor Teleported", spawnPoint + 1, spawnPointCount);
			}
		}
		else if (StrEqual(info, "Previous"))
		{
			if (spawnPointCount == 0)
				CPrintToChat(param1, "%t", "Spawn Editor No Spawn");
			else
			{
				int spawnPoint = lastEditorSpawnPoint[param1] - 1;
				if (spawnPoint < 0)
					spawnPoint = spawnPointCount - 1;
				TeleportEntity(param1, spawnPositions[spawnPoint], spawnAngles[spawnPoint], NULL_VECTOR);
				lastEditorSpawnPoint[param1] = spawnPoint;
				CPrintToChat(param1, "%t #%i (%i total).", "Spawn Editor Teleported", spawnPoint + 1, spawnPointCount);
			}
		}
		else if (StrEqual(info, "Next"))
		{
			if (spawnPointCount == 0)
				CPrintToChat(param1, "%t", "Spawn Editor No Spawn");
			else
			{
				int spawnPoint = lastEditorSpawnPoint[param1] + 1;
				if (spawnPoint >= spawnPointCount)
					spawnPoint = 0;
				TeleportEntity(param1, spawnPositions[spawnPoint], spawnAngles[spawnPoint], NULL_VECTOR);
				lastEditorSpawnPoint[param1] = spawnPoint;
				CPrintToChat(param1, "%t #%i (%i total).", "Spawn Editor Teleported", spawnPoint + 1, spawnPointCount);
			}
		}
		else if (StrEqual(info, "Add"))
		{
			AddSpawn(param1);
		}
		else if (StrEqual(info, "Insert"))
		{
			InsertSpawn(param1);
		}
		else if (StrEqual(info, "Delete"))
		{
			int spawnPoint = GetNearestSpawn(param1);
			if (spawnPoint != -1)
			{
				DeleteSpawn(spawnPoint);
				CPrintToChat(param1, "%t #%i (%i total).", "Spawn Editor Deleted Spawn", spawnPoint + 1, spawnPointCount);
			}
		}
		else if (StrEqual(info, "Delete All"))
		{
			Panel panel = CreatePanel();
			SetPanelTitle(panel, "Delete all spawn points?");
			DrawPanelItem(panel, "Yes");
			DrawPanelItem(panel, "No");
			SendPanelToClient(panel, param1, Panel_ConfirmDeleteAllSpawns, MENU_TIME_FOREVER);
			CloseHandle(panel);
		}
		else if (StrEqual(info, "Save"))
		{
			if (WriteMapConfig())
				CPrintToChat(param1, "%t", "Spawn Editor Config Saved");
			else
				CPrintToChat(param1, "%t", "Spawn Editor Config Not Saved");
		}
		if (!StrEqual(info, "Delete All"))
			DisplayMenu(BuildSpawnEditorMenu(), param1, MENU_TIME_FOREVER);
	}
}

/***********************************************************/
/************** PANEL CONFIRM DELETE ALL SPAWN *************/
/***********************************************************/
public int Panel_ConfirmDeleteAllSpawns(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 1)
		{
			spawnPointCount = 0;
			CPrintToChat(param1, "%t", "Spawn Editor Deleted All");
		}
		DisplayMenu(BuildSpawnEditorMenu(), param1, MENU_TIME_FOREVER);
	}
}

/***********************************************************/
/******************* RENDER SPAWN POINTS *******************/
/***********************************************************/
public Action RenderSpawnPoints(Handle timer)
{
	if (!inEditMode)
		return Plugin_Stop;
	
	for (int i = 0; i < spawnPointCount; i++)
	{
		float spawnPosition[3];
		AddVectors(spawnPositions[i], spawnPointOffset, spawnPosition);
		
		spawnPosition[2] += 50;
		TE_SetupGlowSprite(spawnPosition, glowSprite, 1.0, 0.5, 255);
		TE_SendToAll();
	}
	return Plugin_Continue;
}

/***********************************************************/
/********************* GET NEAREST SPAWN *******************/
/***********************************************************/
int GetNearestSpawn(int client)
{
	if (spawnPointCount == 0)
	{
		CPrintToChat(client, "%t", "Spawn Editor No Spawn");
		return -1;
	}
	
	float clientPosition[3];
	GetClientAbsOrigin(client, clientPosition);
	
	int nearestPoint = 0;
	float nearestPointDistance = GetVectorDistance(spawnPositions[0], clientPosition, true);
	
	for (int i = 1; i < spawnPointCount; i++)
	{
		float distance = GetVectorDistance(spawnPositions[i], clientPosition, true);
		if (distance < nearestPointDistance)
		{
			nearestPoint = i;
			nearestPointDistance = distance;
		}
	}
	return nearestPoint;
}

/***********************************************************/
/************************** ADD SPAWN **********************/
/***********************************************************/
void AddSpawn(int client)
{
	if (spawnPointCount >= MAX_SPAWNS)
	{
		CPrintToChat(client, "%t", "Spawn Editor Spawn Not Added");
		return;
	}
	GetClientAbsOrigin(client, spawnPositions[spawnPointCount]);
	GetClientAbsAngles(client, spawnAngles[spawnPointCount]);
	spawnAngles[spawnPointCount][1] -= 90.0;
	
	spawnPointCount++;
	CPrintToChat(client, "%t", "Spawn Editor Spawn Added", spawnPointCount, spawnPointCount);
}

/***********************************************************/
/************************ INSERT SPAWN *********************/
/***********************************************************/
void InsertSpawn(int client)
{
	if (spawnPointCount >= MAX_SPAWNS)
	{
		CPrintToChat(client, "%t", "Spawn Editor Spawn Not Added");
		return;
	}
	
	if (spawnPointCount == 0)
		AddSpawn(client);
	else
	{
		// Move spawn points down the list to make room for insertion.
		for (int i = spawnPointCount - 1; i >= lastEditorSpawnPoint[client]; i--)
		{
			spawnPositions[i + 1] = spawnPositions[i];
			spawnAngles[i + 1] = spawnAngles[i];
		}
		// Insert new spawn point.
		GetClientAbsOrigin(client, spawnPositions[lastEditorSpawnPoint[client]]);
		GetClientAbsAngles(client, spawnAngles[lastEditorSpawnPoint[client]]);
		
		spawnPointCount++;
		CPrintToChat(client, "%t #%i (%i total).", "Spawn Editor Spawn Inserted", lastEditorSpawnPoint[client] + 1, spawnPointCount);
	}
}

/***********************************************************/
/************************ DELETE SPAWN *********************/
/***********************************************************/
void DeleteSpawn(int spawnIndex)
{
	for (int i = spawnIndex; i < (spawnPointCount - 1); i++)
	{
		spawnPositions[i] = spawnPositions[i + 1];
		spawnAngles[i] = spawnAngles[i + 1];
	}
	spawnPointCount--;
}

/***********************************************************/
/********************** CONFIGS SPAWNS *********************/
/***********************************************************/
void LoadMapConfig()
{
	char map[64];
	GetCurrentMap(map, sizeof(map));
	
	char path[PLATFORM_MAX_PATH];
	Format(path, sizeof(path), "addons/sourcemod/configs/drapi/projectors/spawns/%s.txt", map);
	
	spawnPointCount = 0;
	
	// Open file
	Handle file = OpenFile(path, "r");
	if (file == INVALID_HANDLE)
		return;
	// Read file
	char buffer[256];
	char parts[7][16];
	while (!IsEndOfFile(file) && ReadFileLine(file, buffer, sizeof(buffer)))
	{
		ExplodeString(buffer, " ", parts, 6, 16);
		spawnPositions[spawnPointCount][0] = StringToFloat(parts[0]);
		spawnPositions[spawnPointCount][1] = StringToFloat(parts[1]);
		spawnPositions[spawnPointCount][2] = StringToFloat(parts[2]);
		spawnAngles[spawnPointCount][0] = StringToFloat(parts[3]);
		spawnAngles[spawnPointCount][1] = StringToFloat(parts[4]);
		spawnAngles[spawnPointCount][2] = StringToFloat(parts[5]);
		
		LogMessage("%s Spawn count: %i", TAG_CHAT, spawnPointCount);
		spawnPointCount++;
	}
	// Close file
	CloseHandle(file);
}

/***********************************************************/
/********************* WRITE MAP CONFIG ********************/
/***********************************************************/
bool WriteMapConfig()
{
	char map[64];
	GetCurrentMap(map, sizeof(map));
	
	char path[PLATFORM_MAX_PATH];
	Format(path, sizeof(path), "addons/sourcemod/configs/drapi/projectors/spawns/%s.txt", map);
	
	// Open file
	Handle file = OpenFile(path, "w");
	if (file == INVALID_HANDLE)
	{
		LogError("Could not open spawn point file \"%s\" for writing.", path);
		return false;
	}
	// Write spawn points
	for (int i = 0; i < spawnPointCount; i++)
		WriteFileLine(file, "%f %f %f %f %f %f", spawnPositions[i][0], spawnPositions[i][1], spawnPositions[i][2], spawnAngles[i][0], spawnAngles[i][1], spawnAngles[i][2]);
	// Close file
	CloseHandle(file);
	return true;
}