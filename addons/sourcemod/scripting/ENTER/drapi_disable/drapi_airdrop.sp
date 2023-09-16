/*      <DR.API AIRDROP> (c) by <De Battista Clint - (http://doyou.watch)    */
/*                                                                           */
/*                     <DR.API AIRDROP> is licensed under a                  */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//******************************DR.API AIRDROP*******************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[AIRDROP] -"

#define SNDCHAN_HELICO_1				99
#define SNDCHAN_HELICO_2				98
#define SNDCHAN_HELICO_3				97

//***********************************//
//*************INCLUDE***************//
//***********************************//

//Include native
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <stocks>
#include <drapi_zombie_riot>

#pragma newdecls required



//***********************************//
//***********PARAMETERS**************//
//***********************************//

//defines
#define 													MAX_WEAPONS	32
#define 													MAX_SPAWNS 200
#define														MAX_PRESETS 7
#define														MAX_SLOTS 16
#define 													MAX_DAYS 25
#define														MAX_CHOPPER 3
#define														INDEX_PLAYER 10

//Handles
Handle kvDays 												= INVALID_HANDLE;
Handle cvar_active_aidrop_dev;
Handle cvar_airdrop_weapons_players;
Handle cvar_airdrop_box_throw_height;
Handle cvar_airdrop_helicopter_start;
Handle cvar_airdrop_helicopter_height;
Handle cvar_airdrop_helicopter_velocity_forward;
Handle cvar_airdrop_box_velocity_fall;
Handle cvar_airdrop_roundstart_timer_repeat;
Handle cvar_airdrop_roundstart_remove_weapons_timer_repeat;
Handle cvar_airdrop_break_box_timer;
Handle cvar_airdrop_box_heal;

Handle TimerRoundStart 										= INVALID_HANDLE;
Handle TimerRemoveWeapons 									= INVALID_HANDLE;
Handle TimerRemoveArmory[MAX_SPAWNS] 						= INVALID_HANDLE;
Handle TimerBreakBox[MAX_SPAWNS]							= INVALID_HANDLE;
Handle hAdminMenu 											= INVALID_HANDLE;
Handle hZombieRiotMenu										= INVALID_HANDLE;

//Bools
bool B_active_aidrop_dev;

bool BoxAllowToFall[MAX_SPAWNS]								= false;
bool HelicoAllowToForward[MAX_SPAWNS]						= false;
bool AllowToThrow[MAX_SPAWNS]								= false;
bool CallFromPlayer											= false;
bool inEditMode 											= false;

//Floats
float data_airdrop_time[MAX_DAYS];
float data_airdrop_remove_weapons_time[MAX_DAYS];
float F_airdrop_roundstart_timer_repeat;
float F_airdrop_roundstart_remove_weapons_timer_repeat;
float F_airdrop_break_box_timer;
float EntityOrigin[3];
float HeliPos[MAX_SPAWNS][3];
float HeliposThrowBox[MAX_SPAWNS][3];
float BoxOrigin[MAX_SPAWNS][3];
float ParachuteOrigin[MAX_SPAWNS][3];
float PlayerOrigin[3];

float spawnPositions[MAX_SPAWNS][3];
float spawnAngles[MAX_SPAWNS][3];
float spawnPointOffset[3] 									= { 0.0, 0.0, 20.0 };

//Strings

//Weapons Pistols
char S_weapons[MAX_WEAPONS][]								= {
																	"weapon_usp_silencer", //64
																	"weapon_glock", //4
																	"weapon_p250", //36
																	"weapon_fiveseven", //3
																	"weapon_deagle", //1
																	"weapon_elite", //2
																	"weapon_hkp2000",//61
																	"weapon_tec9", //30
																	"weapon_nova", //35
																	"weapon_xm1014", //25
																	"weapon_mag7", //27
																	"weapon_sawedoff", //29
																	"weapon_mp9", //34
																	"weapon_mac10", //17
																	"weapon_mag7", //27
																	"weapon_mp7", //33
																	"weapon_ump45", //24
																	"weapon_p90", //19
																	"weapon_bizon", //26
																	"weapon_famas", //10
																	"weapon_m4a1", //16
																	"weapon_m4a1_silencer", //60
																	"weapon_galilar", //13
																	"weapon_ak47", //7
																	"weapon_ssg08", //40
																	"weapon_aug", //8
																	"weapon_sg556", //39
																	"weapon_awp", //9
																	"weapon_scar20", //38
																	"weapon_g3sg1", //11
																	"weapon_hegrenade",
																	"weapon_smokegrenade"
																};
																
char SND_HELICOPTER[1][PLATFORM_MAX_PATH] 					= {"vehicles/loud_helicopter_lp_01.wav"};

//Customs 
int INT_TOTAL_DAY;
int INT_CHOPPER;
int IndexProp[2048];
int C_CabinetPresets[MAX_PRESETS][MAX_SLOTS];
int presetsCount;
int m_hOwnerEntity;

int C_airdrop_weapons_players;
int C_airdrop_box_throw_height;
int C_airdrop_helicopter_start;
int C_airdrop_helicopter_height;
int C_airdrop_helicopter_velocity_forward;
int C_airdrop_box_velocity_fall;
int C_airdrop_box_heal;

int AirDropBox[MAX_SPAWNS] 										= INVALID_ENT_REFERENCE;
int Helicopter[MAX_SPAWNS] 										= INVALID_ENT_REFERENCE;
int Parachute[MAX_SPAWNS]  										= INVALID_ENT_REFERENCE;
int Armory[MAX_SPAWNS] 											= INVALID_ENT_REFERENCE;
int Armory2[MAX_SPAWNS] 										= INVALID_ENT_REFERENCE;
int FlareBurning[MAX_SPAWNS] 									= INVALID_ENT_REFERENCE;
int WeaponsIndex[MAX_SPAWNS][2][MAX_SLOTS];

int HelicoAllowToSound[MAXPLAYERS+1];

int lastEditorSpawnPoint[MAXPLAYERS + 1] 						= { -1, ... };
int spawnPointCount 											= 0;
int glowSprite;
int spawnHeight[MAX_SPAWNS];
int SetspawnHeight[MAXPLAYERS+1];

int C_play_sound[MAXPLAYERS+1];

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API AIRDROP",
	author = "Dr. Api",
	description = "DR.API AIRDROP by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://doyou.watch"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	LoadTranslations("drapi/drapi_airdropbox.phrases");
	AutoExecConfig_SetFile("drapi_airdrop", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_aidrop_version", PLUGIN_VERSION, "Version", CVARS);
	
	m_hOwnerEntity 		= FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");

	
	cvar_active_aidrop_dev									= AutoExecConfig_CreateConVar("drapi_active_aidrop_dev", 											"0", 					"Enable/Disable Dev Mod",											DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	cvar_airdrop_weapons_players							= AutoExecConfig_CreateConVar("drapi_aidrop_weapons_players", 										"2", 					"Drop 1 x Pistol, 1 x (Heavy or Smgs or Snipes), 1 x grenade",		DEFAULT_FLAGS);
	cvar_airdrop_box_throw_height							= AutoExecConfig_CreateConVar("drapi_aidrop_box_throw_height", 										"600", 					"Distance between box and helicopter on throw",						DEFAULT_FLAGS);
	cvar_airdrop_helicopter_start							= AutoExecConfig_CreateConVar("drapi_helicopter_start", 											"10000", 				"Distance helicopter form spawn point",								DEFAULT_FLAGS);
	cvar_airdrop_helicopter_height							= AutoExecConfig_CreateConVar("drapi_helicopter_height", 											"1000", 				"Default Height Helicopter",										DEFAULT_FLAGS);
	cvar_airdrop_helicopter_velocity_forward				= AutoExecConfig_CreateConVar("drapi_aidrop_helicopter_velocity_forward", 							"10", 					"Velocity Helicopter",												DEFAULT_FLAGS);
	cvar_airdrop_box_velocity_fall							= AutoExecConfig_CreateConVar("drapi_aidrop_box_velocity_fall", 									"3",					"Velocity drop box",												DEFAULT_FLAGS);
	cvar_airdrop_roundstart_timer_repeat					= AutoExecConfig_CreateConVar("drapi_airdrop_roundstart_timer_repeat", 								"180.0",				"Timer call the chopper",											DEFAULT_FLAGS);
	cvar_airdrop_roundstart_remove_weapons_timer_repeat		= AutoExecConfig_CreateConVar("drapi_airdrop_roundstart_remove_weapons_timer_repeat", 				"180.0",				"Timer remove weapons on the ground",								DEFAULT_FLAGS);
	cvar_airdrop_break_box_timer							= AutoExecConfig_CreateConVar("drapi_airdrop_break_box_timer", 										"30.0",					"Timer break box",													DEFAULT_FLAGS);
	cvar_airdrop_box_heal									= AutoExecConfig_CreateConVar("drapi_airdrop_box_heal_heal", 										"25",					"Life of box/player",												DEFAULT_FLAGS);
	
	
	HookEvent("round_start", Event_RoundStart);
	
	RegAdminCmd("sm_chopper", 			Command_SpawnAirDrop, 	ADMFLAG_CHANGEMAP, "Call chopper");
	RegAdminCmd("sm_airdropspawn", 		Command_SpawnMenu, 		ADMFLAG_CHANGEMAP, "Opens the spawn menu.");
	RegAdminCmd("sm_airdropheight", 	Command_AirDropHeight, 	ADMFLAG_CHANGEMAP, "Set Height Helicopter.");
	
	RegConsoleCmd("sm_airdrop",			Command_AirDrop, 		"Zombie riot airdrop menu");
	
	RegServerCmd("sm_create_airdrop_tables", Command_CreateTables);
	
	HookEvents();
	
	FakeAndDownloadSound(false, SND_HELICOPTER, 1);
	

	
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			SDKHook(i, SDKHook_WeaponEquipPost, OnPostWeaponEquip);
		}
		i++;
	}
	
	SQL_LoadPrefAllClients();
	AutoExecConfig_ExecuteFile();
	
	Handle topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}	
	
	Handle topmenu2;
	if(LibraryExists("zombie_riot") && ((topmenu2 = ZRiot_GetMenu()) != INVALID_HANDLE))
	{
		ZRiot_OnMenuReady(topmenu2);
	}
}

/***********************************************************/
/******************* ON LIBRARY REMOVED ********************/
/***********************************************************/
public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "adminmenu"))
	{
		hAdminMenu = INVALID_HANDLE;
	}	
	
	if (StrEqual(name, "menu_zombie_riot"))
	{
		hZombieRiotMenu = INVALID_HANDLE;
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
/************** WHEN CLIENT POST ADMIN CHECK ***************/
/***********************************************************/
public void OnClientPostAdminCheck(int client)
{
	SQL_LoadPrefClients(client);
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
	HookConVarChange(cvar_active_aidrop_dev, 									Event_CvarChange);
	
	HookConVarChange(cvar_airdrop_weapons_players, 								Event_CvarChange);
	HookConVarChange(cvar_airdrop_box_throw_height, 							Event_CvarChange);
	HookConVarChange(cvar_airdrop_helicopter_start, 							Event_CvarChange);
	HookConVarChange(cvar_airdrop_helicopter_height, 							Event_CvarChange);
	HookConVarChange(cvar_airdrop_helicopter_velocity_forward, 					Event_CvarChange);
	HookConVarChange(cvar_airdrop_box_velocity_fall, 							Event_CvarChange);
	HookConVarChange(cvar_airdrop_roundstart_timer_repeat, 						Event_CvarChange);
	HookConVarChange(cvar_airdrop_roundstart_remove_weapons_timer_repeat, 		Event_CvarChange);
	HookConVarChange(cvar_airdrop_break_box_timer, 								Event_CvarChange);
	HookConVarChange(cvar_airdrop_box_heal, 									Event_CvarChange);
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
	B_active_aidrop_dev 									= GetConVarBool(cvar_active_aidrop_dev);
	
	C_airdrop_weapons_players 								= GetConVarInt(cvar_airdrop_weapons_players);
	C_airdrop_box_throw_height								= GetConVarInt(cvar_airdrop_box_throw_height);
	C_airdrop_helicopter_start								= GetConVarInt(cvar_airdrop_helicopter_start);
	C_airdrop_helicopter_height								= GetConVarInt(cvar_airdrop_helicopter_height);
	C_airdrop_helicopter_velocity_forward					= GetConVarInt(cvar_airdrop_helicopter_velocity_forward);
	C_airdrop_box_velocity_fall								= GetConVarInt(cvar_airdrop_box_velocity_fall);
	F_airdrop_roundstart_timer_repeat						= GetConVarFloat(cvar_airdrop_roundstart_timer_repeat);
	F_airdrop_roundstart_remove_weapons_timer_repeat		= GetConVarFloat(cvar_airdrop_roundstart_remove_weapons_timer_repeat);
	F_airdrop_break_box_timer								= GetConVarFloat(cvar_airdrop_break_box_timer);
	C_airdrop_box_heal										= GetConVarInt(cvar_airdrop_box_heal);
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
	AddFileToDownloadsTable("materials/models/props_vehicles/helicopter_bladeramp.vmt");
	AddFileToDownloadsTable("materials/models/props_vehicles/helicopter_bladeramp.vtf");
	AddFileToDownloadsTable("materials/models/props_vehicles/helicopter_rescue.vmt");
	AddFileToDownloadsTable("materials/models/props_vehicles/helicopter_rescue.vtf");
	AddFileToDownloadsTable("materials/models/props_vehicles/helicopter_rescue_windows.vmt");
	AddFileToDownloadsTable("materials/models/props_vehicles/helicopter_rescue_windows.vtf");
	
	AddFileToDownloadsTable("models/props_vehicles/helicopter_rescue.ani");
	AddFileToDownloadsTable("models/props_vehicles/helicopter_rescue.dx90.vtx");
	AddFileToDownloadsTable("models/props_vehicles/helicopter_rescue.mdl");
	AddFileToDownloadsTable("models/props_vehicles/helicopter_rescue.phy");
	AddFileToDownloadsTable("models/props_vehicles/helicopter_rescue.vvd");
	
	AddFileToDownloadsTable("materials/models/z4e/parachute/Default.vmt");
	AddFileToDownloadsTable("materials/models/z4e/parachute/Default.vtf");
	
	AddFileToDownloadsTable("models/z4e/parachute/parachute.mdl");
	AddFileToDownloadsTable("models/z4e/parachute/parachute.dx90.vtx");
	AddFileToDownloadsTable("models/z4e/parachute/parachute.vvd");
	
	AddFileToDownloadsTable("materials/models/props_unique/guncabinet01_main.vmt");
	AddFileToDownloadsTable("materials/models/props_unique/guncabinet01_main.vtf");
	
	AddFileToDownloadsTable("models/props_unique/guncabinet01_main.dll");
	AddFileToDownloadsTable("models/props_unique/guncabinet01_main.phy");
	AddFileToDownloadsTable("models/props_unique/guncabinet01_main.vvd");
	AddFileToDownloadsTable("models/props_unique/guncabinet01_main.dx90.vtx");


	glowSprite = PrecacheModel("sprites/glow01.vmt", true);
	
	PrecacheModel("models/props_vehicles/helicopter_rescue.mdl", true);
	PrecacheModel("models/z4e/parachute/parachute.mdl", true);
	PrecacheModel("models/props_unique/guncabinet01_main.dll", true);
	
	FakeAndDownloadSound(false, SND_HELICOPTER, 1);
	
	//WEAPON_FX
	//AddFileToDownloadsTable("particles/weapon_fx_river.pcf");
	//PrecacheGeneric("particles/weapon_fx_river.pcf", true);
	//FLARE BURNING
	//PrecacheParticleEffect(particle_flare_buring);
	//AddFileToDownloadsTable("materials/particle/particle_glow_02_add_15ob_trail.vmt");
	//AddFileToDownloadsTable("materials/particle/particle_glow_02.vtf");
	//AddFileToDownloadsTable("materials/particle/particle_glow_05_add_15ob_minsize.vmt");
	//AddFileToDownloadsTable("materials/particle/particle_glow_05.vtf");
	//AddFileToDownloadsTable("materials/particle/particle_glow_05_add_5ob.vmt");
	//AddFileToDownloadsTable("materials/particle/smoke1/smoke1.vmt");
	//AddFileToDownloadsTable("materials/particle/smoke1/smoke1.vtf");
	
	LoadDayData("configs/drapi/zombie_riot/days", "cfg");
	LoadPresets();
	LoadMapConfig();
	RemoveBuyZoneMap();
	UpdateState();
}

/***********************************************************/
/******************** WHEN ROUND START *********************/
/***********************************************************/
public void Event_RoundStart(Handle event, char[] name, bool dontBroadcast)
{
	for(int i = 0; i < MAX_CHOPPER; i++)
	{
		ClearTimer(TimerBreakBox[i]);
		ClearTimer(TimerRemoveArmory[i]);
	}
	ClearTimer(TimerRemoveWeapons);
	ClearTimer(TimerRoundStart);
	
	
	CreateTimer(1.0, Timer_RoundStart);
	
	float time 						= GetDayAirDropTime(ZRiot_GetDay()-1);
	TimerRoundStart 				= CreateTimer(time, Timer_RoundStart, INVALID_HANDLE, TIMER_REPEAT);
	
	/*for(int i = 1; i <= MaxClients; i++)
	{
		if(Client_IsIngame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT)
		{
			Client_RemoveAllWeapons(i, "weapon_knife");
			int gun = GivePlayerItem(i, "weapon_deagle");
			EquipPlayerWeapon(i, gun);
		}
	}*/
	
	//CPrintToChatAll("%t", "Helico round start warning");
}

/***********************************************************/
/********************* ON GAME FRAME ***********************/
/***********************************************************/
public void OnGameFrame()
{
	if(!CallFromPlayer)
	{
		for(int i = 0; i < INT_CHOPPER; i++)
		{
			SetAnimations(i);
		}
	}
	else
	{
		SetAnimations(INDEX_PLAYER);
	}
}

/***********************************************************/
/***************** ON POST EQUIP WEAPON ********************/
/***********************************************************/
public Action OnPostWeaponEquip(int client, int weapon)
{
	if(Client_IsIngame(client) && IsPlayerAlive(client))
	{
		char classname[64];
		GetEdictClassname(weapon, classname, sizeof(classname));
		int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");

		if(index == 0)
		{
			int gun = GivePlayerItem(client, classname);
			EquipPlayerWeapon(client, gun);

			int newindex = GetEntProp(gun, Prop_Send, "m_iItemDefinitionIndex");
			PrintToDev(B_active_aidrop_dev, "weapon: %s, index: %i, new index: %i", classname, index, newindex);

			RemoveEdict(weapon);
		}
	}
	return Plugin_Handled;
}

/***********************************************************/
/****************** MENU CMD SPAWN AIR DROP ****************/
/***********************************************************/
public Action Command_AirDropHeight(int client, int args)
{
	if(args)
	{
		char S_args1[256];
		GetCmdArg(1, S_args1, sizeof(S_args1));
		
		SetspawnHeight[client] = StringToInt(S_args1);
		CPrintToChat(client, "%t", "AirDropBox Height", S_args1);
	}
	return Plugin_Handled;
}
/***********************************************************/
/****************** MENU CMD SPAWN AIR DROP ****************/
/***********************************************************/
public Action Command_SpawnAirDrop(int client, int args)
{
	if(args)
	{

		if (IsValidEntRef(Parachute[INDEX_PLAYER]))
		{
			int parachute = EntIndexToEntRef(Parachute[INDEX_PLAYER]);
			RemoveEntity(parachute);		
		}
		
		if (IsValidEntRef(Armory[INDEX_PLAYER]))
		{
			int armory = EntIndexToEntRef(Armory[INDEX_PLAYER]);
			RemoveEntity(armory);		
		}
		
		if (IsValidEntRef(Armory2[INDEX_PLAYER]))
		{
			int armory2 = EntIndexToEntRef(Armory2[INDEX_PLAYER]);
			RemoveEntity(armory2);	
		}
		
		if (IsValidEntRef(AirDropBox[INDEX_PLAYER]))
		{
			int airdropbox = EntIndexToEntRef(AirDropBox[INDEX_PLAYER]);
			RemoveEntity(airdropbox);		
		}
		
		if (IsValidEntRef(FlareBurning[INDEX_PLAYER]))
		{
			int flare = EntIndexToEntRef(FlareBurning[INDEX_PLAYER]);
			RemoveEntity(flare);	
		}
		
		if (IsValidEntRef(Helicopter[INDEX_PLAYER]))
		{
			int helicopter = EntIndexToEntRef(Helicopter[INDEX_PLAYER]);
			RemoveEntity(helicopter);
			
			char S_sound_to_play[PLATFORM_MAX_PATH];
			Format(S_sound_to_play, PLATFORM_MAX_PATH, "*%s", SND_HELICOPTER[0]);
			
			RemoveSound(INDEX_PLAYER, Helicopter[INDEX_PLAYER], S_sound_to_play);
			CPrintToChat(client, "%t", "Helico removed");			
		}	
		
		
		char S_args1[256];
		GetClientAbsOrigin(client, PlayerOrigin);
		GetCmdArg(1, S_args1, sizeof(S_args1));
		SetspawnHeight[client] = StringToInt(S_args1);
		SpawnEntity(INDEX_PLAYER, 1, PlayerOrigin, NULL_VECTOR, SetspawnHeight[client]);
		CreateParticle(INDEX_PLAYER, "office_smoke", PlayerOrigin, NULL_VECTOR);
		
		CreateTimer(0.1, Timer_RemoveWeapons);
		
		CallFromPlayer = true;	
		
		char clientname[32];
		GetClientName(client, clientname, sizeof(clientname));
		CPrintToChatAll("%t", "Helico on player", clientname);
	}
	else
	{
		for(int i = 0; i < INT_CHOPPER; i++)
		{
			if (IsValidEntRef(Parachute[i]))
			{
				int parachute = EntIndexToEntRef(Parachute[i]);
				RemoveEntity(parachute);	
			}
			
			if (IsValidEntRef(Armory[i]))
			{
				int armory = EntIndexToEntRef(Armory[i]);
				RemoveEntity(armory);		
			}
			
			if (IsValidEntRef(Armory2[i]))
			{
				int armory2 = EntIndexToEntRef(Armory2[i]);
				RemoveEntity(armory2);		
			}
			
			if (IsValidEntRef(AirDropBox[i]))
			{
				int airdropbox = EntIndexToEntRef(AirDropBox[i]);
				RemoveEntity(airdropbox);	
			}
			
			if (IsValidEntRef(FlareBurning[i]))
			{
				int flare = EntIndexToEntRef(FlareBurning[i]);
				RemoveEntity(flare);		
			}
			
			if (IsValidEntRef(Helicopter[i]))
			{
				int helicopter = EntIndexToEntRef(Helicopter[i]);
				RemoveEntity(helicopter);
				
				char S_sound_to_play[PLATFORM_MAX_PATH];
				Format(S_sound_to_play, PLATFORM_MAX_PATH, "*%s", SND_HELICOPTER[0]);
				
				RemoveSound(i, Helicopter[i], S_sound_to_play);
				CPrintToChat(client, "%t", "Helico removed");			
			}	
		}
		
		INT_CHOPPER = 0;
		float time_remove_weapons		= GetDayAirDropRemoveWeaponsTime(ZRiot_GetDay()-1);
		
		if(spawnPointCount >= MAX_CHOPPER)
		{
			for(int i = 0; i < MAX_CHOPPER; i++)
			{
				SpawnEntity(i, 1, spawnPositions[i], spawnAngles[i], spawnHeight[i]);
				CreateParticle(i, "office_smoke", spawnPositions[i], NULL_VECTOR);
				ClearTimer(TimerRemoveArmory[i]);
				TimerRemoveArmory[i] = CreateTimer(time_remove_weapons, Timer_RemoveArmory, i);
				INT_CHOPPER++;
			}
			
			CreateTimer(0.1, Timer_RemoveWeapons);
			ClearTimer(TimerRemoveWeapons);
			TimerRemoveWeapons 				= CreateTimer(time_remove_weapons, Timer_RemoveWeapons);
			
			CallFromPlayer = false;
			
			char clientname[32];
			GetClientName(client, clientname, sizeof(clientname));
			CPrintToChatAll("%t", "Helico on spawn", clientname);
		}
		else
		{
			CPrintToChat(client, "%t", "Helico no spawn");
		}
	}
	return Plugin_Handled;
}

/***********************************************************/
/********************* CREATE ENTITY ***********************/
/***********************************************************/
bool CreateEntity(int index, const char[] entType, int option, char[] modelName, float Origin[3], float Angles[3], int Height)
{
	int prop = -1;
	
	if (!IsModelPrecached(modelName))
	{
    	if(!PrecacheModel(modelName))
    	{
    		return false;
    	}
    }
	
	EntityOrigin[0] = (Origin[0] + (50 * Cosine(DegToRad(Angles[1]))));
	EntityOrigin[1] = (Origin[1] + (50 * Sine(DegToRad(Angles[1]))));
	EntityOrigin[2] = (Origin[2]);
	
	prop = CreateEntityByName(entType);
    
	if (IsValidEntity(prop)) 
	{
		DispatchKeyValue(prop, "model", modelName);
		IndexProp[prop] = index;

		if(option == 1)
		{
			DispatchKeyValue(prop, "massScale", "50.0");
			DispatchSpawn(prop);
			
			DispatchKeyValue(prop, "Solid", "6");
			
			AcceptEntityInput(prop, "DisableCollision");
			AcceptEntityInput(prop, "EnableCollision");
			SetEntProp(prop, Prop_Data, "m_takedamage", 0);
			
			int healbox = (GetPlayersAlive(CS_TEAM_CT, "both") * C_airdrop_box_heal) + 1;
			
			SetEntProp(prop, Prop_Data, "m_iMaxHealth", healbox);
			SetEntProp(prop, Prop_Data, "m_iHealth", healbox);
			
			PrintToDev(B_active_aidrop_dev, "%s healbox: %i, player alive: %i, life: %i", TAG_CHAT, healbox, GetPlayersAlive(CS_TEAM_CT, "both"), C_airdrop_box_heal);
			
			//AcceptEntityInput(prop, "enablemotion");
			
			AcceptEntityInput(prop, "TurnOn", prop, prop, 0);
		
			BoxOrigin[index][0] = EntityOrigin[0];
			BoxOrigin[index][1] = EntityOrigin[1];
			BoxOrigin[index][2] = EntityOrigin[2] - C_airdrop_box_throw_height;
			
			TeleportEntity(prop, BoxOrigin[index], NULL_VECTOR, NULL_VECTOR);
			SetEntityMoveType(prop, MOVETYPE_VPHYSICS); 
		
			HookSingleEntityOutput(prop, "OnBreak", OnBreakAirDrop, true);	
			
			AirDropBox[index] 		= EntIndexToEntRef(prop);
			BoxAllowToFall[index]  = true;
		}
		else if(option == 2)
		{
			DispatchSpawn(prop);
			
			DispatchKeyValue(prop, "Solid", "6");
			SetEntProp(prop, Prop_Data, "m_takedamage", 0);
			SetEntProp(prop, Prop_Data, "m_iMaxHealth", 0);
			SetEntProp(prop, Prop_Data, "m_iHealth", 0);
			AcceptEntityInput(prop, "DisableCollision");
			AcceptEntityInput(prop, "EnableCollision");
			
			HeliPos[index][0] = EntityOrigin[0] - C_airdrop_helicopter_start; //Demarre longueur
			HeliPos[index][1] = EntityOrigin[1];
			
			if(Height != 0)
			{
				HeliPos[index][2] = EntityOrigin[2] + Height;
			}
			else
			{
				HeliPos[index][2] = EntityOrigin[2] + C_airdrop_helicopter_height; //Hauteur
			}
			
			HeliposThrowBox[index][0] = HeliPos[index][0] + C_airdrop_helicopter_start; //Largue la caisse
			HeliposThrowBox[index][1] = HeliPos[index][1];
			HeliposThrowBox[index][2] = HeliPos[index][2];
			
			TeleportEntity(prop, HeliPos[index], NULL_VECTOR, NULL_VECTOR);
			
			Helicopter[index] 				= EntIndexToEntRef(prop);
			HelicoAllowToForward[index] 	= true;
			AllowToThrow[index] 			= true;
			SetVariantString("3ready");
			AcceptEntityInput(Helicopter[index], "SetAnimation");	
		}
		else if(option == 3)
		{
			DispatchSpawn(prop);
			
			DispatchKeyValue(prop, "Solid", "6");
			AcceptEntityInput(prop, "EnableCollision");
			AcceptEntityInput(prop, "DisableCollision");
			SetEntProp(prop, Prop_Data, "m_takedamage", 0);
			//SetEntityRenderColor(prop, 0, 255, 255, 255);
			ParachuteOrigin[index][0] = EntityOrigin[0];
			ParachuteOrigin[index][1] = EntityOrigin[1];
			ParachuteOrigin[index][2] = EntityOrigin[2] - C_airdrop_box_throw_height - 16;
			
			float Angle[3];
			Angle[1] = Angle[1] + 90;
			TeleportEntity(prop, ParachuteOrigin[index], Angle, NULL_VECTOR);
			Parachute[index] 	= EntIndexToEntRef(prop);
		}
		else if(option == 4)
		{
			//DispatchKeyValue(prop, "Solid", "6");
			
			TeleportEntity(prop, Origin, Angles, NULL_VECTOR);
			DispatchSpawn(prop);
			
			Armory[index] = EntIndexToEntRef(prop);
		}
		else if(option == 5)
		{
			//DispatchKeyValue(prop, "Solid", "6");
			
			TeleportEntity(prop, Origin, Angles, NULL_VECTOR);
			DispatchSpawn(prop);
			
			Armory2[index] = EntIndexToEntRef(prop);
		}
	}
	else
	{
		return false;
	}
	return true;
}

/***********************************************************/
/********************* CREATE SOUND ************************/
/***********************************************************/
public void CreateSound(int index, int edict, char[] sound)
{
	int CHANNEL = 100 + index;
	int LEVEL = SNDLEVEL_HELICOPTER;
	
	for (int i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i) && C_play_sound[i])
		{
			float target[3];
			GetClientAbsOrigin(i, target);
			float distance = GetVectorDistance(HeliPos[index], target);
			
			if (distance > 0 && distance < 2000)
			{
				if(HelicoAllowToSound[i] != 1)
				{
					//EmitSoundToClient(i, sound, edict, CHANNEL, SNDLEVEL_NORMAL, SND_STOPLOOPING, SNDVOL_NORMAL, SNDPITCH_NORMAL, _, _, _, _,0.0);
					EmitSoundToClient(i, sound, edict, CHANNEL, LEVEL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, _, _, _, _, _);
					HelicoAllowToSound[i] = 1;
					
					PrintToDev(B_active_aidrop_dev, "%s Helico sound 1.0", TAG_CHAT);
				}
			}
			else if (distance > 2001 && distance < 4000)
			{
				if(HelicoAllowToSound[i] != 2)
				{
					//EmitSoundToClient(i, sound, edict, CHANNEL, SNDLEVEL_NORMAL, SND_STOPLOOPING, SNDVOL_NORMAL, SNDPITCH_NORMAL, _, _, _, _,0.0);
					EmitSoundToClient(i, sound, edict, CHANNEL, LEVEL, SND_NOFLAGS, 0.8, SNDPITCH_NORMAL, _, _, _, _, _);
					HelicoAllowToSound[i] = 2;
					
					PrintToDev(B_active_aidrop_dev, "%s Helico sound 0.8", TAG_CHAT);
				}
			}
			else if (distance > 4001 && distance < 6000)
			{
				if(HelicoAllowToSound[i] != 3)
				{
					//EmitSoundToClient(i, sound, edict, CHANNEL, SNDLEVEL_NORMAL, SND_STOPLOOPING, SNDVOL_NORMAL, SNDPITCH_NORMAL, _, _, _, _,0.0);
					EmitSoundToClient(i, sound, edict, CHANNEL, LEVEL, SND_NOFLAGS, 0.6, SNDPITCH_NORMAL, _, _, _, _, _);
					HelicoAllowToSound[i] = 3;
					
					PrintToDev(B_active_aidrop_dev, "%s Helico sound 0.6", TAG_CHAT);
				}
			}
			else if (distance > 6001 && distance < 10000)
			{
				if(HelicoAllowToSound[i] != 4)
				{
					//EmitSoundToClient(i, sound, edict, CHANNEL, SNDLEVEL_NORMAL, SND_STOPLOOPING, SNDVOL_NORMAL, SNDPITCH_NORMAL, _, _, _, _,0.0);
					EmitSoundToClient(i, sound, edict, CHANNEL, LEVEL, SND_NOFLAGS, 0.4, SNDPITCH_NORMAL, _, _, _, _, _);
					HelicoAllowToSound[i] = 4;
					
					PrintToDev(B_active_aidrop_dev, "%s Helico sound 0.4", TAG_CHAT);
				}
			}
			
			
			else if (distance > 10001)
			{
				if(HelicoAllowToSound[i] != 0)
				{
					RemoveSound(index, edict, sound);
				}
			}
		}
	}
}

/***********************************************************/
/********************* REMOVE ENTITY ***********************/
/***********************************************************/
void RemoveEntity(int Ref)
{

	int entity = EntRefToEntIndex(Ref);
	if (entity != -1)
	{
		AcceptEntityInput(entity, "Kill");
		//Ref = INVALID_ENT_REFERENCE;
	}
		
}

/***********************************************************/
/******************* REMOVE HELICOPTER *********************/
/***********************************************************/
void RemoveSound(int index, int edict, char[] sound)
{
	for (int i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i))
		{
			EmitSoundToClient(i, sound, edict, 100 + index, SNDLEVEL_NORMAL, SND_STOPLOOPING, SNDVOL_NORMAL, SNDPITCH_NORMAL, _, _, _, _,0.0);
			
			HelicoAllowToSound[i] = 0;
		}
	}
		
}

/***********************************************************/
/********************** SPAWN ENTITY ***********************/
/***********************************************************/
void SpawnEntity(int index, int option, float pos[3], float ang[3], int height)
{
	if(option == 1)
	{
		if(!CreateEntity(index, "prop_dynamic", 2, "models/props_vehicles/helicopter_rescue.mdl", pos, ang, height))
		{
			PrintToChatAll("Helico");
		}
	}
	
	else if(option == 2)
	{
		if(!CreateEntity(index, "prop_physics_override", 1, "models/props/de_nuke/crate_extralarge.mdl", pos, ang, height))
		{
			PrintToChatAll("Box");
		}
	}
	else if(option == 3)
	{
		if(!CreateEntity(index, "prop_dynamic", 3, "models/z4e/parachute/parachute.mdl", pos, ang, height))
		{
			PrintToChatAll("Parachute");
		}
	}
	else if(option == 4)
	{
		if(!CreateEntity(index, "prop_dynamic_override", 4, "models/props_unique/guncabinet01_main.mdl", pos, ang, height))
		{
			PrintToChatAll("Cabinet");
		}	
	}
	else if(option == 5)
	{
		if(!CreateEntity(index, "prop_dynamic_override", 5, "models/props_unique/guncabinet01_main.mdl", pos, ang, height))
		{
			PrintToChatAll("Cabinet");
		}	
	}
}

/***********************************************************/
/********************* SET ANIMATIONS **********************/
/***********************************************************/
void SetAnimations(int index)
{
	if(IsValidEntRef(Helicopter[index]))
	{
		//Helicopter can advance
		if(HelicoAllowToForward[index])
		{
			HeliPos[index][0] = HeliPos[index][0] + C_airdrop_helicopter_velocity_forward;
			TeleportEntity(Helicopter[index], HeliPos[index], NULL_VECTOR, NULL_VECTOR);
			
			char S_sound_to_play[PLATFORM_MAX_PATH];
			Format(S_sound_to_play, PLATFORM_MAX_PATH, "*%s", SND_HELICOPTER[0]);
			
			CreateSound(index, Helicopter[index], S_sound_to_play);
			
			float distance_end_helicopter_spawn 	= GetVectorDistance(HeliPos[index], spawnPositions[index]);
			float distance_end_helicopter_player 	= GetVectorDistance(BoxOrigin[index], PlayerOrigin);
			
			int end_point = C_airdrop_helicopter_start + 1000;
			
			//If disante == 11000 between helico and spawn/player. We delete helico
			if(distance_end_helicopter_spawn > end_point && HelicoAllowToForward[index] && !CallFromPlayer || distance_end_helicopter_player > end_point && HelicoAllowToForward[index] && CallFromPlayer)
			{
				RemoveEntity(Helicopter[index]);
				RemoveSound(index, Helicopter[index], S_sound_to_play);
				HelicoAllowToForward[index] = false;
				
				PrintToDev(B_active_aidrop_dev, "%s Helicopter deleted : %i", TAG_CHAT, end_point);
			}
			
			float distance_point_de_largage = GetVectorDistance(HeliPos[index], HeliposThrowBox[index]);
			
			//Is distance between helico and point drop <= 10. We drop the box.
			if(distance_point_de_largage <= 10 && AllowToThrow[index])
			{
				//distance between helico and spawn/player is less than height of parachute. We don't spwan the parachute and reajust the box height.
				if(HeliPos[index][2] < C_airdrop_box_throw_height)
				{
					float BoxNewPos[3];
					BoxNewPos[0] = HeliPos[index][0];
					BoxNewPos[1] = HeliPos[index][1];
					BoxNewPos[2] = HeliPos[index][2] + C_airdrop_box_throw_height;
					SpawnEntity(index, 2, BoxNewPos, NULL_VECTOR, 0);
					
					if(!CallFromPlayer)
					{
						PrintToDev(B_active_aidrop_dev, "%s Cannot deploy parachute min. height: %i, current height: %f", TAG_CHAT, C_airdrop_box_throw_height, spawnHeight[index]);
					}
					else
					{	
						PrintToDev(B_active_aidrop_dev, "%s Cannot deploy parachute min. height: %i, current height: %f", TAG_CHAT, C_airdrop_box_throw_height, PlayerOrigin[2]);
					}
				}
				else
				{
					SpawnEntity(index, 2, HeliPos[index], NULL_VECTOR, 0);
					SpawnEntity(index, 3, HeliPos[index], NULL_VECTOR, 0);
				}
				
				AllowToThrow[index] = false;
			}
		
			if(IsValidEntRef(AirDropBox[index]))
			{
				//Box fall
				if(BoxAllowToFall[index])
				{
					BoxOrigin[index][2] = BoxOrigin[index][2] - C_airdrop_box_velocity_fall;
					TeleportEntity(AirDropBox[index], BoxOrigin[index], NULL_VECTOR, NULL_VECTOR);
					
						
					//If parachute. Fall
					if(IsValidEntRef(Parachute[index]))
					{
						ParachuteOrigin[index][2] = ParachuteOrigin[index][2] - C_airdrop_box_velocity_fall;
						TeleportEntity(Parachute[index], ParachuteOrigin[index], NULL_VECTOR, NULL_VECTOR);
					}
					
					float distance_entre_le_sol_et_box 		= GetVectorDistance(BoxOrigin[index], spawnPositions[index]);
					float distance_entre_le_player_et_box 	= GetVectorDistance(BoxOrigin[index], PlayerOrigin);
					
					//if distance between box and spawn/player <= 100. We release the box.
					if(distance_entre_le_sol_et_box <= 100 && BoxAllowToFall[index] && !CallFromPlayer || distance_entre_le_player_et_box <= 100 && BoxAllowToFall[index] && CallFromPlayer)
					{
						RemoveEntity(Parachute[index]);
						SetEntProp(AirDropBox[index], Prop_Data, "m_takedamage", 2);
						
						//ClearTimer(TimerBreakBox[index]);
						TimerBreakBox[index] 	= CreateTimer(F_airdrop_break_box_timer, Timer_BreakAirDropBox, index);
						
						BoxAllowToFall[index] 	= false;
						CallFromPlayer 			= false;
						
						PrintToDev(B_active_aidrop_dev, "%s Helico drop box", TAG_CHAT);
					}
				}
			}
			
			//PrintToDev(B_active_aidrop_dev, "Heli pos: %f, %f, %f", HeliPos[0], HeliPos[1], HeliPos[2]);
		}
	}
	
}

/***********************************************************/
/****************** WHEN ROUND START TIMER *****************/
/***********************************************************/
public Action Timer_RoundStart(Handle timer)
{
	INT_CHOPPER = 0;
	CallFromPlayer = false;
	
	
	float time_remove_weapons		= GetDayAirDropRemoveWeaponsTime(ZRiot_GetDay()-1);
	
	
	if(spawnPointCount >= MAX_CHOPPER)
	{
		for(int i = 0; i < MAX_CHOPPER; i++)
		{
			SpawnEntity(i, 1, spawnPositions[i], spawnAngles[i], spawnHeight[i]);
			CreateParticle(i, "office_smoke", spawnPositions[i], NULL_VECTOR);
			//ClearTimer(TimerRemoveArmory[i]);
			TimerRemoveArmory[i] = CreateTimer(time_remove_weapons, Timer_RemoveArmory, i);
			INT_CHOPPER++;
		}
		//ClearTimer(TimerRemoveWeapons);
		TimerRemoveWeapons 				= CreateTimer(time_remove_weapons, Timer_RemoveWeapons);
		
		CPrintToChatAll("%t", "Helico round start");
	}
}

/***********************************************************/
/****************** TIMER BREAK AIR DROP BOX ***************/
/***********************************************************/
public Action Timer_BreakAirDropBox(Handle timer, any index)
{
	if(IsValidEntRef(AirDropBox[index]))
	{
		int box = EntRefToEntIndex(AirDropBox[index]);
		AcceptEntityInput(box, "Break");
		//RemoveEntity(box);
		PrintToDev(B_active_aidrop_dev, "%s Timer Break box", TAG_CHAT);
	}
	TimerBreakBox[index] = INVALID_HANDLE;
}

/***********************************************************/
/******************* TIMER REMOVE WEAPONS ******************/
/***********************************************************/
public Action Timer_RemoveWeapons(Handle timer)
{
	RemoveWeaponsOnMap(m_hOwnerEntity);
	TimerRemoveWeapons = INVALID_HANDLE;
	//RemoveWeapons(index);
	PrintToDev(B_active_aidrop_dev, "%s Timer Remove weapons", TAG_CHAT);
}
/***********************************************************/
/******************* TIMER REMOVE WEAPONS ******************/
/***********************************************************/
public Action Timer_RemoveArmory(Handle timer, any index)
{
	if(IsValidEntRef(Armory[index]))
	{
		int armory = EntRefToEntIndex(Armory[index]);
		RemoveEntity(armory);
	}
	
	if(IsValidEntRef(Armory2[index]))
	{
		int armory2 = EntRefToEntIndex(Armory2[index]);
		RemoveEntity(armory2);
	}
	
	TimerRemoveArmory[index] = INVALID_HANDLE;
	PrintToDev(B_active_aidrop_dev, "%s Timer Remove armories on map", TAG_CHAT);
}

/***********************************************************/
/****************** WHEN AIRDROPBOX BREAK ******************/
/***********************************************************/
public void OnBreakAirDrop(const char[] output, int caller, int activator, float delay)
{
	//int count = GetPlayersInGame(CS_TEAM_CT, "player");

	//Armory contain 6 or more primary weapons.
	//Max player 40 - 24 = 16, ok let say 20.
	//20 / 6 * 2 = 1.6, roung to 2.
	//Max entities = 16 * 2 * 2 + 2 * 20 * 2= 144;
	
	/*
	if(count >= 2)
	{
		count = RoundToZero(float(count) / float(2));
	}
	PrintToDev(B_active_aidrop_dev, "%s Floor: %i, Nearest: %i, Zero: %i", TAG_CHAT, RoundToFloor(11.0 / 2.0), RoundToNearest(11.0 / 2.0), RoundToZero(11.0 / 2.0));
	*/
	if(IsValidEntity(caller))
	{
		int index = IndexProp[caller];
		float position[3];
		GetEntPropVector(caller, Prop_Send, "m_vecOrigin", position);
		
		if(!CallFromPlayer)
		{
			position[2] = spawnPositions[index][2];
		}
		else
		{
			position[2] = PlayerOrigin[2];
		}
		
		float Angles[3];
		Angles[1] += 180;
		position[0] -= 25.0;
		SpawnEntity(index, 4, position, Angles, 0);
		
		int random = GetRandomInt(0, presetsCount-1);
		//int count = 1;
		
		//for(int i = 0; i < count; i++)
		{
			CreateArmory(index, 0, random, position, Angles);
		}
		

		Angles[1] += 180;
		position[0] += 25.0;
		SpawnEntity(index, 5, position, Angles, 0);
		int random2 = GetRandomInt(0, presetsCount-1);
		
		//for(int i = 0; i < count; i++)
		{
			CreateArmory(index, 1, random2, position, Angles);
		}
		
		
		if(IsValidEntRef(FlareBurning[index]))
		{
			int flare = EntRefToEntIndex(FlareBurning[index]);
			RemoveEntity(flare);		
		}
		
		PrintToDev(B_active_aidrop_dev, "%s Box position: %f, %f, %f", TAG_CHAT, position[0], position[1], position[2]);
		
		PrintToDev(B_active_aidrop_dev, "%s Box break, index: %i", TAG_CHAT, index);
	
		AirDropBox[index] = INVALID_ENT_REFERENCE;
	}
}


/***********************************************************/
/***************** CREATE ARMORY WITH GUNS *****************/
/***********************************************************/
void CreateArmory(int index, int style, int preset, const float vOrigin[3], const float vAngles[3])
{
	// ARRAYS
	int iGuns[10];
	int iPist[4];
	int iItem[2];

	// MODEL TYPE
	for(int slot = 0; slot < 10; slot++)
	{
		iGuns[slot] = C_CabinetPresets[preset][slot];
	}
	for(int slot = 10; slot < 14; slot++)
	{
		iPist[slot-10] = C_CabinetPresets[preset][slot];
	}
	for(int slot = 14; slot < 16; slot++)
	{
		iItem[slot-14] = C_CabinetPresets[preset][slot];
	}
	
	// INDEX HOLDER
	int iAmGuns[10];
	int iAmPist[4];
	int iAmItem[2];

	// VALID COUNT
	int iCountGun;
	int iCountPis;
	int iCountIte;

	// VALIDATE AND PUSH INDEX HOLDER
	for(int i = 0; i < 10; i++)
	{
		if( iGuns[i] != 0 ) iAmGuns[iCountGun++] = i;
	}
	for(int i = 0; i < 4; i++)
	{
		if( iPist[i] != 0 ) iAmPist[iCountPis++] = i;
	}
	for(int i = 0; i < 2; i++)
	{
		if( iItem[i] != 0 ) iAmItem[iCountIte++] = i;
	}

	int dex;

	SortIntegers(iAmGuns, iCountGun, Sort_Random);
	for(int x = 0; x < iCountGun; x++)
	{
		dex = iAmGuns[x];
		CreateWeapon(index, style, dex, iGuns[dex] -1, vOrigin, vAngles);

	}

	SortIntegers(iAmPist, iCountPis, Sort_Random);
	for(int x = 0; x < iCountPis; x++)
	{
		dex = iAmPist[x];
		CreateWeapon(index, style, dex + 10, iPist[dex] -1, vOrigin, vAngles);
	}

	SortIntegers(iAmItem, iCountIte, Sort_Random);
	
	int players = C_airdrop_weapons_players * GetPlayersInGame(CS_TEAM_CT, "player");
	if(!players) players = 1;
	
	for(int i = 0; i < players; i++)
	{
		for(int x = 0; x < iCountIte; x++)
		{
			dex = iAmItem[x];
			CreateWeapon(index, style, dex + 14, iItem[dex] -1, vOrigin, vAngles);
			PrintToDev(B_active_aidrop_dev, "%s Item: %i", TAG_CHAT, x);
		}	
	}
}

/***********************************************************/
/********************** CREATE WEAPONS *********************/
/***********************************************************/
int CreateWeapon(int index, int style, int slot, int model, const float vOrigin[3], const float vAngles[3])
{
	int entity_weapon = -1;
	entity_weapon = CreateEntityByName(S_weapons[model]);
	if(entity_weapon != -1 )
	{
		DispatchKeyValue(entity_weapon, "model", S_weapons[model]);

		float vPos[3], vAng[3];

		vPos = vOrigin;
		vAng = vAngles;
		
		if(strcmp("weapon_aug", S_weapons[model]) == 0)
		{
			vPos[2] = vPos[2] - 4;
		}
		else if(strcmp("weapon_sawedoff", S_weapons[model]) == 0)
		{
			vPos[2] = vPos[2] - 10;
		}
		else if(strcmp("weapon_m4a1", S_weapons[model]) == 0)
		{
			if(style == 0)
			{
				vPos[0] = vPos[0] + 2;
			}
			else if(style == 1)
			{
				vPos[0] = vPos[0] - 2;
			}
		}
		else if(strcmp("weapon_ak47", S_weapons[model]) == 0)
		{
			if(style == 0)
			{
				vPos[0] = vPos[0] - 2;
			}
			else if(style == 1)
			{
				vPos[0] = vPos[0] + 2;
			}
		}
		else if(strcmp("weapon_scar20", S_weapons[model]) == 0)
		{
			if(style == 0)
			{
				vPos[0] = vPos[0] + 1.5;
				vPos[1] = vPos[1] - 0.2;
			}
			else if(style == 1)
			{
				vPos[0] = vPos[0] - 1.5;
				vPos[1] = vPos[1] + 0.2;
			}
		}
		else if(strcmp("weapon_hegrenade", S_weapons[model]) == 0)
		{
			vPos[2] += 47.0;
		}
		else if(strcmp("weapon_smokegrenade", S_weapons[model]) == 0)
		{
			vPos[2] += 48.0;
		}
		else if(strcmp("weapon_p90", S_weapons[model]) == 0)
		{
			vPos[2] = vPos[2] - 10;
		}
		else if(strcmp("weapon_mac10", S_weapons[model]) == 0)
		{
			vPos[2] = vPos[2] - 10;
		}
		else if(strcmp("weapon_mag7", S_weapons[model]) == 0)
		{
			vPos[2] = vPos[2] - 10;
		}
		else if(strcmp("weapon_mp7", S_weapons[model]) == 0)
		{
			vPos[2] = vPos[2] - 10;
		}
		

		switch(slot)
		{
			case 0:
			{
				// RACK #1
				MoveForward(vPos, vAng, vPos, 0.2); // + recule
				MoveSideway(vPos, vAng, vPos, 19.1);// + deplace gauche
			}

			case 1:
			{
				// RACK #2
				MoveForward(vPos, vAng, vPos, -0.1);
				MoveSideway(vPos, vAng, vPos, 15.3);
			}

			case 2:
			{
				// RACK #3
				MoveForward(vPos, vAng, vPos, 1.0);
				MoveSideway(vPos, vAng, vPos, 11.8);
			}

			case 3:
			{
				// RACK #4
				MoveForward(vPos, vAng, vPos, -1.5);
				MoveSideway(vPos, vAng, vPos, 7.6);
			}

			case 4:
			{
				// RACK #5
				MoveForward(vPos, vAng, vPos, 1.0);
				MoveSideway(vPos, vAng, vPos, 3.8);
			}

			case 5:
			{
				// RACK #6
				MoveForward(vPos, vAng, vPos, 0.5);
				MoveSideway(vPos, vAng, vPos, 0.0);
			}

			case 6:
			{
				// RACK #7
				MoveForward(vPos, vAng, vPos, 0.0);  // - avance
				MoveSideway(vPos, vAng, vPos, -3.7); // - deplace vers la droite
			}

			case 7:
			{
				// RACK #8
				MoveForward(vPos, vAng, vPos, -2.5);
				MoveSideway(vPos, vAng, vPos, -7.6);
			}

			case 8:
			{
				// RACK #9
				MoveForward(vPos, vAng, vPos, -1.0);
				MoveSideway(vPos, vAng, vPos, -11.0);
			}

			case 9:
			{
				// RACK #10
				MoveForward(vPos, vAng, vPos, -2.5);
				MoveSideway(vPos, vAng, vPos, -15.0);
			}
			case 10:
			{
				if(strcmp("weapon_deagle", S_weapons[model]) == 0 
				|| strcmp("weapon_p250", S_weapons[model]) == 0
				|| strcmp("weapon_elite", S_weapons[model]) == 0
				|| strcmp("weapon_hkp2000", S_weapons[model]) == 0
				|| strcmp("weapon_tec9", S_weapons[model]) == 0
				|| strcmp("weapon_fiveseven", S_weapons[model]) == 0)
				{
					// RACK PISTOL #1 - UP
					vPos[2] += 37.0;
					MoveForward(vPos, vAng, vPos, -6.2);
					MoveSideway(vPos, vAng, vPos, 24.8);
				
					vAng[0] -= 18 - 90;
					vAng[1] -= 90.0;
				}
			}
			case 11:
			{
				if(strcmp("weapon_deagle", S_weapons[model]) == 0 
				|| strcmp("weapon_p250", S_weapons[model]) == 0
				|| strcmp("weapon_elite", S_weapons[model]) == 0
				|| strcmp("weapon_hkp2000", S_weapons[model]) == 0
				|| strcmp("weapon_tec9", S_weapons[model]) == 0
				|| strcmp("weapon_fiveseven", S_weapons[model]) == 0)
				{
					// RACK PISTOL #2 - UP
					vPos[2] += 37.0;
					MoveForward(vPos, vAng, vPos, -6.2);
					MoveSideway(vPos, vAng, vPos, 9.5);
					
					vAng[0] -= 18 - 90;
					vAng[1] -= 90.0;			
				}			
			}
			case 12:
			{
				if(strcmp("weapon_deagle", S_weapons[model]) == 0 
				|| strcmp("weapon_p250", S_weapons[model]) == 0
				|| strcmp("weapon_elite", S_weapons[model]) == 0
				|| strcmp("weapon_hkp2000", S_weapons[model]) == 0
				|| strcmp("weapon_tec9", S_weapons[model]) == 0
				|| strcmp("weapon_fiveseven", S_weapons[model]) == 0)
				{
					// RACK PISTOL #2 - DOWN
					vPos[2] += 28.0;
					MoveForward(vPos, vAng, vPos, -6.2);
					MoveSideway(vPos, vAng, vPos, 9.5);
					
					vAng[0] -= 18 - 90;
					vAng[1] -= 90.0;			
				}			
			}
			case 13:
			{
				if(strcmp("weapon_deagle", S_weapons[model]) == 0 
				|| strcmp("weapon_p250", S_weapons[model]) == 0
				|| strcmp("weapon_elite", S_weapons[model]) == 0
				|| strcmp("weapon_hkp2000", S_weapons[model]) == 0
				|| strcmp("weapon_tec9", S_weapons[model]) == 0
				|| strcmp("weapon_fiveseven", S_weapons[model]) == 0)
				{
					// RACK PISTOL #1 - DOWN
					vPos[2] += 28.0;
					MoveForward(vPos, vAng, vPos, -6.2);
					MoveSideway(vPos, vAng, vPos, 24.8);
				
					vAng[0] -= 18 - 90;
					vAng[1] -= 90.0;
				}		
			}
			case 14:
			{	
				if(strcmp("weapon_hegrenade", S_weapons[model]) == 0 || strcmp("weapon_smokegrenade", S_weapons[model]) == 0)
				{
					MoveForward(vPos, vAng, vPos, -1.0);
					MoveSideway(vPos, vAng, vPos, -5.0);
					vAng[0] -= 18 - 90;
					vAng[1] -= 90.0;
				}
			}
			case 15:
			{
				if(strcmp("weapon_hegrenade", S_weapons[model]) == 0 || strcmp("weapon_smokegrenade", S_weapons[model]) == 0)
				{
					MoveForward(vPos, vAng, vPos, -1.0);
					MoveSideway(vPos, vAng, vPos, -16.0);
					vAng[0] -= 18 - 90;
					vAng[1] -= 90.0;
				}			
			}
		}
		
		if(style == 0)
		{
			vAng[0] = vAng[0] + 288; //Axe Y
			vAng[1] = vAng[1] + 180; // Axe Z
			//vAng[2] = vAng[2] + 20; //Axe X

			vPos[0] = vPos[0] + 3;
			vPos[2] = vPos[2] + 17; //Axe X
		}
		else if(style == 1)
		{
			vAng[0] = vAng[0] + 288; //Axe Y
			vAng[1] = vAng[1] + 180; // Axe Z
			//vAng[2] = vAng[2] + 20; //Axe X

			vPos[0] = vPos[0] - 3;
			vPos[2] = vPos[2] + 17; //Axe X		
		}
		
		TeleportEntity(entity_weapon, vPos, vAng, NULL_VECTOR);
		DispatchSpawn(entity_weapon);
		
		SetEntProp(entity_weapon, Prop_Send, "m_CollisionGroup", 11); 	//WEAPONS COLLISION
		SetEntProp(entity_weapon, Prop_Send, "m_usSolidFlags", 8);    	//TRIGGER
		SetEntProp(entity_weapon, Prop_Send, "m_nSolidType", 6);		//VPHYSIC
		SetEntityMoveType(entity_weapon, MOVETYPE_NONE);
		
		WeaponsIndex[index][style][slot] = EntIndexToEntRef(entity_weapon);
	}
	return entity_weapon;
}

/***********************************************************/
/********************** REMOVE WEAPONS *********************/
/***********************************************************/
stock void RemoveWeapons(int index)
{
	int stack1, stack2;

	for(int x = 0; x < MAX_SLOTS; x++)
	{
		stack1 = WeaponsIndex[index][0][x];
		stack2 = WeaponsIndex[index][1][x];
		
		WeaponsIndex[index][0][x] = 0;
		WeaponsIndex[index][1][x] = 0;

		if(IsValidEntRef(stack1))
		{
			int istack1 = EntRefToEntIndex(stack1);
			RemoveEntity(istack1);
		}
		
		if(IsValidEntRef(stack2))
		{
			int istack2 = EntRefToEntIndex(stack2);
			RemoveEntity(istack2);
		}
	}
}

/***********************************************************/
/******************* MOVE WEAPON FORWARD *******************/
/***********************************************************/
void MoveForward(const float vPos[3], const float vAng[3], float vReturn[3], float fDistance)
{
	float vDir[3];
	GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
	vReturn = vPos;
	vReturn[0] += vDir[0] * fDistance;
	vReturn[1] += vDir[1] * fDistance;
	vReturn[2] += vDir[2] * fDistance;
}

/***********************************************************/
/******************* MOVE WEAPON SIDEWAY *******************/
/***********************************************************/
void MoveSideway(const float vPos[3], const float vAng[3], float vReturn[3], float fDistance)
{
	float vDir[3];
	GetAngleVectors(vAng, NULL_VECTOR, vDir, NULL_VECTOR);
	vReturn = vPos;
	vReturn[0] += vDir[0] * fDistance;
	vReturn[1] += vDir[1] * fDistance;
	vReturn[2] += vDir[2] * fDistance;
}

/***********************************************************/
/******************** CREATE PARTICLE **********************/
/***********************************************************/
void CreateParticle(int index, char[] particleType, float Pos[3], float Ang[3])
{
    int particle = CreateEntityByName("info_particle_system");
  
	
    if (IsValidEdict(particle))
    {
		TeleportEntity(particle, Pos, Ang, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		
		FlareBurning[index] = EntIndexToEntRef(particle);
    }
}

/***********************************************************/
/********************* LOAD DAYS DATA **********************/
/***********************************************************/
void LoadDayData(char[] folder, char[] extension)
{
	char path[PLATFORM_MAX_PATH];
	char currentMap[64];
	
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	BuildPath(Path_SM, path, sizeof(path), "%s_%s.%s", folder, currentMap, extension);

	if(!FileExists(path))
	{
		BuildPath(Path_SM, path, sizeof(path), "%s.%s", folder, extension);
	}
		
	ReadDayFile(path);
}

/***********************************************************/
/********************* LOAD DAYS DATA **********************/
/***********************************************************/
void ReadDayFile(char[] path)
{
	if (!FileExists(path))
	{
		return;
	}

	if (kvDays != INVALID_HANDLE)
	{
		CloseHandle(kvDays);
	}

	kvDays = CreateKeyValues("days");
	KvSetEscapeSequences(kvDays, true);

	if (!FileToKeyValues(kvDays, path))
	{
		SetFailState("\"%s\" failed to load", path);
	}

	KvRewind(kvDays);
	if (!KvGotoFirstSubKey(kvDays))
	{
		SetFailState("No day data defined in \"%s\"", path);
	}
	
	INT_TOTAL_DAY = 0;
	do
	{
		data_airdrop_time[INT_TOTAL_DAY] 							= KvGetFloat(kvDays, 		"airdrop_time", F_airdrop_roundstart_timer_repeat);
		data_airdrop_remove_weapons_time[INT_TOTAL_DAY] 			= KvGetFloat(kvDays, 		"airdrop_remove_weapons_time", F_airdrop_roundstart_remove_weapons_timer_repeat);
		
		//LogMessage("%s [DAY%i] - Time: %f, Remove: %f", TAG_CHAT, INT_TOTAL_DAY, data_airdrop_time[INT_TOTAL_DAY], data_airdrop_remove_weapons_time[INT_TOTAL_DAY]);
		
		INT_TOTAL_DAY++;
	} 
	while (KvGotoNextKey(kvDays));
}
/***********************************************************/
/******************* GET DAY AIRDROP TIME ******************/
/***********************************************************/
float GetDayAirDropTime(int day)
{
    return data_airdrop_time[day];
}

/***********************************************************/
/*********** GET DAY AIRDROP REMOVE WEAPONS TIME ***********/
/***********************************************************/
float GetDayAirDropRemoveWeaponsTime(int day)
{
    return data_airdrop_remove_weapons_time[day];
}

/***********************************************************/
/*************** COMMAND ZOMBIE RIOT MENU ******************/
/***********************************************************/
public Action Command_AirDrop(int client, int args) 
{
	BuildMenuAirDrop(client);
	return Plugin_Handled;
}

/***********************************************************/
/**************** BUILD ZOMBIE RIOT MENU *******************/
/***********************************************************/
void BuildMenuAirDrop(int client)
{
	char title[40]; 
	char sound[40];
	Menu menu = CreateMenu(MenuAirDropAction);
	
	Format(sound, sizeof(sound), "%T", "MenuAirDrop_SOUNDS_MENU_TITLE", client);
	AddMenuItem(menu, "M_sounds", sound);
	
	Format(title, sizeof(title), "%T", "MenuAirDrop_TITLE", client);
	menu.SetTitle(title);
	SetMenuExitBackButton(menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
}

/***********************************************************/
/*************** ZOMBIE RIOT MENU ACTIONS ******************/
/***********************************************************/
public int MenuAirDropAction(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);	
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && hZombieRiotMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hZombieRiotMenu, param1, TopMenuPosition_Start);
			}		
		}
		case MenuAction_Select:
		{
			char menu1[56];
			menu.GetItem(param2, menu1, sizeof(menu1));
			
			if(StrEqual(menu1, "M_sounds"))
			{
				BuildMenuAirDrop_SOUNDS(param1);
			}

		}
	}
}

/***********************************************************/
/****************** BUILD SOUNDS MENU **********************/
/***********************************************************/
void BuildMenuAirDrop_SOUNDS(int client)
{
	char title[40]; 
	char sound[40]; 
	char status[40];
	Menu menu = CreateMenu(BuildMenuAirDrop_SOUNDS_ACTION);
	SetMenuExitBackButton(menu, true);

	Format(status, sizeof(status), "%T", (C_play_sound[client]) ? "Enabled" : "Disabled", client);
	
	Format(sound, sizeof(sound), "%T", "SOUNDS_STATUS_MENU_TITLE", client, status);
	AddMenuItem(menu, "M_sounds_status", sound);
	
	Format(title, sizeof(title), "%T", "SOUNDS_TITLE", client);
	menu.SetTitle(title);
	menu.Display(client, MENU_TIME_FOREVER);
}

/***********************************************************/
/***************** SOUNDS MENU ACTIONS *********************/
/***********************************************************/
public int BuildMenuAirDrop_SOUNDS_ACTION(Menu menu, MenuAction action, int param1, int param2)
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
				BuildMenuAirDrop(param1);
			}
		}
		case MenuAction_Select:
		{
			char menu1[56];
			menu.GetItem(param2, menu1, sizeof(menu1));
			if(StrEqual(menu1, "M_sounds_status"))
			{
				if(C_play_sound[param1])
				{
					C_play_sound[param1] = 0;
					BuildMenuAirDrop_SOUNDS(param1);
				}
				else
				{
					C_play_sound[param1] = 1;
					BuildMenuAirDrop_SOUNDS(param1);
				}
				
				if(IsClientAuthorized(param1))
				{
					Database db = Connect();
					if (db != null)
					{
						char steamId[64];
						GetClientAuthId(param1, AuthId_Steam2, steamId, sizeof(steamId));
						
						char strQuery[256];
						Format(strQuery, sizeof(strQuery), "SELECT sounds FROM aidrop_client_prefs WHERE auth = '%s'", steamId);
						SQL_TQuery(db, SQLQuery_SOUNDS, strQuery, GetClientUserId(param1), DBPrio_High);
					}
				}
			}	
		}
	}
}

/***********************************************************/
/************* ON ZOMBIE RIOT MENU READY *******************/
/***********************************************************/
public void ZRiot_OnMenuReady(Handle topmenu)
{
	if (topmenu == hZombieRiotMenu)
	{
		return;
	}
	
	hZombieRiotMenu = topmenu;
	
	TopMenuObject menu = FindTopMenuCategory(hZombieRiotMenu, "menu_airdrop");
	
	if (menu == INVALID_TOPMENUOBJECT)
	{
		menu = AddToTopMenu(
		hZombieRiotMenu,			// Menu
		"menu_airdrop",				// Name
		TopMenuObject_Category,		// Type
		Handle_CategoryMenu,		// Callback
		INVALID_TOPMENUOBJECT		// Parent
		);
	}
	
	AddToTopMenu(hZombieRiotMenu, "sm_menu_airdrop_sound", TopMenuObject_Item, Menu_AirDropSounds, menu, "sm_menu_airdrop_sound");
}

/***********************************************************/
/******************* HANDLE CATEGORY ***********************/
/***********************************************************/
public void Handle_CategoryMenu(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayTitle:
			Format(buffer, maxlength, "%T", "MenuZombieRiotAirDrop_TITLE", param);
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "%T", "MenuZombieRiotAirDrop_TITLE", param);
	}
}

/***********************************************************/
/**************** ON ADMIN MENU HUMANIFY *******************/
/***********************************************************/
public void Menu_AirDropSounds(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "%T", "MenuAirDrop_SOUNDS_MENU_TITLE", param);
		case TopMenuAction_SelectOption:
		{
			BuildMenuAirDrop_SOUNDS(param);
		}
	}
}

/***********************************************************/
/***************** ON ADMIN MENU READY *********************/
/***********************************************************/
public void OnAdminMenuReady(Handle topmenu)
{
	if(topmenu == hAdminMenu)
	{
		return;
	}
	
	hAdminMenu = topmenu;
	TopMenuObject menu = FindTopMenuCategory(hAdminMenu, "admin_menu_zombie_riot");
	if(menu == INVALID_TOPMENUOBJECT)
	{
		return;
	}
	AddToTopMenu(hAdminMenu, "sm_adminairdropspawn", TopMenuObject_Item, AdminMenu_AirDrop, menu, "sm_adminairdropspawn", ADMFLAG_GENERIC);
}

/***********************************************************/
/**************** ON ADMIN MENU HUMANIFY *******************/
/***********************************************************/
public void AdminMenu_AirDrop(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "%T", "MenuAdminAirDrop_SPAWNS_TITLE", param);
		case TopMenuAction_SelectOption:
		{
			DisplayMenu(BuildSpawnEditorMenu(), param, MENU_TIME_FOREVER);
		}
	}
}

/***********************************************************/
/*********************** LOAD PRESETS **********************/
/***********************************************************/
void LoadPresets()
{
	presetsCount = 0;
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/drapi/airdropbox.cfg");
	if( !FileExists(sPath) )
	{
		SetFailState("Error: Missing required preset config: %s", sPath);
	}

	Handle hFile = CreateKeyValues("presets");
	if( !FileToKeyValues(hFile, sPath) )
	{
		SetFailState("Error: Cannot read the preset config: %s", sPath);
	}

	char sBuff[64], sTemp[64];
	for(int preset = 0; preset < MAX_PRESETS; preset++)
	{
		Format(sTemp, sizeof(sTemp), "preset%d", preset + 1);
		if(KvJumpToKey(hFile, sTemp))
		{
			KvGetString(hFile, "name", sBuff, sizeof(sBuff));
			IntToString(preset + 1, sTemp, sizeof(sTemp));

			for(int slot = 0; slot < MAX_SLOTS; slot++)
			{
				Format(sTemp, sizeof(sTemp), "slot%d", slot + 1);
				KvGetString(hFile, sTemp, sBuff, sizeof(sBuff));

				if(strcmp(sBuff, ""))
				{
					if(strcmp(sBuff, "random") == 0)
					{
						if(slot < 10)						C_CabinetPresets[preset][slot] = GetRandomInt(9, 30);		// Random primary
						if(slot >= 11 && slot <= 14)		C_CabinetPresets[preset][slot] = GetRandomInt(1, 8);		// Random pistol
						if(slot >= 15 && slot <= 16)		C_CabinetPresets[preset][slot] = GetRandomInt(31, 32);		// Random medical/grenade
					} 
					else 
					{
						Format(sBuff, sizeof(sBuff), "weapon_%s", sBuff);

						for(int i = 0; i < MAX_WEAPONS; i++)
						{
							if(strcmp(sBuff, S_weapons[i]) == 0)
							{
								C_CabinetPresets[preset][slot] = i + 1;
								break;
							}
						}
					}
				}
			}presetsCount++;
		}

		KvRewind(hFile);
	}

	CloseHandle(hFile);
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
	
	SetMenuTitle(menu, "AirDrop Spawn Editor:");
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
	
	if(SetspawnHeight[client])
	{
		spawnHeight[spawnPointCount] = SetspawnHeight[client];
	}
	else
	{
		spawnHeight[spawnPointCount] = C_airdrop_helicopter_height;
	}
	
	
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
			
			spawnHeight[i + 1] = spawnHeight[i];
		}
		// Insert new spawn point.
		GetClientAbsOrigin(client, spawnPositions[lastEditorSpawnPoint[client]]);
		GetClientAbsAngles(client, spawnAngles[lastEditorSpawnPoint[client]]);
		
		if(SetspawnHeight[client])
		{
			spawnHeight[lastEditorSpawnPoint[client]] = SetspawnHeight[client];
		}
		else
		{
			spawnHeight[lastEditorSpawnPoint[client]] = C_airdrop_helicopter_height;
		}
		
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
	Format(path, sizeof(path), "addons/sourcemod/configs/drapi/airdropbox/spawns/%s.txt", map);
	
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
		ExplodeString(buffer, " ", parts, 7, 16);
		spawnPositions[spawnPointCount][0] = StringToFloat(parts[0]);
		spawnPositions[spawnPointCount][1] = StringToFloat(parts[1]);
		spawnPositions[spawnPointCount][2] = StringToFloat(parts[2]);
		spawnAngles[spawnPointCount][0] = StringToFloat(parts[3]);
		spawnAngles[spawnPointCount][1] = StringToFloat(parts[4]);
		spawnAngles[spawnPointCount][2] = StringToFloat(parts[5]);
		
		spawnHeight[spawnPointCount] = StringToInt(parts[6]);
		
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
	Format(path, sizeof(path), "addons/sourcemod/configs/drapi/airdropbox/spawns/%s.txt", map);
	
	// Open file
	Handle file = OpenFile(path, "w");
	if (file == INVALID_HANDLE)
	{
		LogError("Could not open spawn point file \"%s\" for writing.", path);
		return false;
	}
	// Write spawn points
	for (int i = 0; i < spawnPointCount; i++)
		WriteFileLine(file, "%f %f %f %f %f %f %i", spawnPositions[i][0], spawnPositions[i][1], spawnPositions[i][2], spawnAngles[i][0], spawnAngles[i][1], spawnAngles[i][2], spawnHeight[i]);
	// Close file
	CloseHandle(file);
	return true;
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
		Format(strQuery, sizeof(strQuery), "SELECT sounds FROM aidrop_client_prefs WHERE auth = '%s'", steamId);
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
		LogToZombieRiot(true, "%s SQL Error: %s", TAG_CHAT, strError);
		return;
	}
	
	if(SQL_FetchRow(hQuery) && SQL_GetRowCount(hQuery) != 0)
	{
		C_play_sound[client] 			= SQL_FetchInt(hQuery, 0);
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
		Format(strQuery, sizeof(strQuery), "INSERT INTO aidrop_client_prefs (sounds, auth) VALUES (%i, '%s')", 1, steamId);
		SQL_TQuery(db, SQLQuery_Update, strQuery, _, DBPrio_High);
		
		SQL_LoadPrefClients(client);
	}
}

/***********************************************************/
/***************** SQL QUERY HUD PREFS *********************/
/***********************************************************/
public void SQLQuery_SOUNDS(Handle hOwner, Handle hQuery, const char[] strError, any data)
{
	int client = GetClientOfUserId(data);
	if(!Client_IsValid(client))
		return;

	if(hOwner == INVALID_HANDLE || hQuery == INVALID_HANDLE)
	{
		LogToZombieRiot(true, "%s SQL Error: %s", TAG_CHAT, strError);
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
		Format(strQuery, sizeof(strQuery), "INSERT INTO aidrop_client_prefs (sounds, auth) VALUES (%i, '%s')", C_play_sound[client], steamId);
		SQL_TQuery(db, SQLQuery_Update, strQuery, _, DBPrio_High);
	}
	else
	{
		char strQuery[256];
		Format(strQuery, sizeof(strQuery), "UPDATE aidrop_client_prefs SET sounds = '%i' WHERE auth = '%s'", C_play_sound[client], steamId);
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
		LogToZombieRiot(true, "%s SQL Error: %s", TAG_CHAT, strError);
	}
}

/***********************************************************/
/******************* DATABASE CONNECT **********************/
/***********************************************************/
Database Connect()
{
	char error[255];
	Database db;

	if (SQL_CheckConfig("zombieriot"))
	{
		db = SQL_Connect("zombieriot", true, error, sizeof(error));
	} 
	else 
	{
		db = SQL_Connect("default", true, error, sizeof(error));
	}

	if (db == null)
	{
		LogToZombieRiot(true, "%s Could not connect to database: %s", TAG_CHAT, error);
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
		"CREATE TABLE IF NOT EXISTS aidrop_client_prefs (id int(64) NOT NULL AUTO_INCREMENT, auth varchar(32) UNIQUE, sounds int(12) NOT NULL default 1, PRIMARY KEY (id)) ENGINE=InnoDB DEFAULT CHARSET=utf8;"
	};

	for (int i = 0; i < 1; i++)
	{
		if (!DoQuery(client, db, queries[i]))
		{
			return;
		}
	}

	ReplyToCommand(client, "%s AirDrop tables have been created.", TAG_CHAT);
}

/***********************************************************/
/******************** CREATE SQLITE ************************/
/***********************************************************/
void CreateSQLite(int client, Handle db)
{
	char queries[1][] = 
	{
		"CREATE TABLE IF NOT EXISTS aidrop_client_prefs (id int(64) NOT NULL AUTO_INCREMENT, auth varchar(32) UNIQUE, sounds int(12) NOT NULL default 1, PRIMARY KEY (id)) ENGINE=InnoDB DEFAULT CHARSET=utf8;"
	};

	for (int i = 0; i < 1; i++)
	{
		if (!DoQuery(client, db, queries[i]))
		{
			return;
		}
	}

	ReplyToCommand(client, "%s AirDrop tables have been created.", TAG_CHAT);
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
		LogToZombieRiot(true, "%s Query failed: %s", TAG_CHAT, error);
		LogToZombieRiot(true, "%s Query dump: %s", TAG_CHAT, query);
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
		LogToZombieRiot(true, "%s %s: %s", TAG_CHAT, msg, error);
		LogToZombieRiot(true, "%s Query dump: %s", TAG_CHAT, query);
		delete db;
		ReplyToCommand(client, "%s Failed to query database", TAG_CHAT);
		return Plugin_Handled;
}

/***********************************************************/
/********************* DO SMT ERROR ************************/
/***********************************************************/
stock Action DoStmtError(int client, Handle db, const char[] query, const char[] error, const char[] msg)
{
		LogToZombieRiot(true, "%s %s: %s", TAG_CHAT, msg, error);
		LogToZombieRiot(true, "%s Query dump: %s", TAG_CHAT, query);
		delete db;
		ReplyToCommand(client, "%s Failed to query database", TAG_CHAT);
		return Plugin_Handled;
}
