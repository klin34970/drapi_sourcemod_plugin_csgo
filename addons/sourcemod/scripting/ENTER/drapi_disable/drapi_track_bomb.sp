/*  <DR. API TRACK BOMB> (c) by <De Battista Clint - (http://doyou.watch)    */
/*                                                                           */
/*                 <DR. API TRACK BOMB> is licensed under a                  */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//*****************************DR. API TRACK BOMB****************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_TRACK_BOMB 					"[TRACK BOMB] - "
#define PLUGIN_VERSION					"1.0.3"
#define MAX_MAP_TRACK_BOMB				100
#define MAX_DIRECTION_TRACK_BOMB		8	
#define MAX_WAY_TRACK_BOMB				16

#define DMG_KNIFE 						4100
#define DMG_HE							4
#define DMG_MOLOTOV						8
#define DMG_HS 							1073745922
#define DMG_SHOT 						4098

#define SND_BOMB						102

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <autoexec>
#include <csgocolors>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_track_bomb;
Handle cvar_active_track_bomb_dev;
Handle cvar_active_track_bomb_c4_explode;
Handle cvar_active_track_bomb_menu_name;
//Handle cvar_active_track_bomb_menu_time;
Handle cvar_active_track_bomb_menu_chat;
Handle cvar_active_track_bomb_menu_hint;
Handle cvar_active_track_bomb_menu_alert;
Handle cvar_active_track_bomb_delay_time_msg;
Handle cvar_active_track_bomb_hit_num;
Handle cvar_active_track_bomb_freeze_holder;

Handle mp_freezetime;
//Handle mp_c4timer;

Handle H_timer_beacon_entity;

//Bool
bool B_active_track_bomb 																											= false;
bool B_active_track_bomb_dev																										= false;
bool B_active_track_bomb_c4_explode																									= false;
bool B_active_track_bomb_menu_name																									= false;
bool B_active_track_bomb_menu_chat																									= false;
bool B_active_track_bomb_menu_hint																									= false;
bool B_active_track_bomb_menu_alert																									= false;
bool B_active_track_bomb_freeze_holder																								= false;

bool B_track_bomb_show_menu																											= false;
bool B_is_round_start																												= false;

bool B_has_bomb[MAXPLAYERS+1]																										= false;
bool B_is_freeze[MAXPLAYERS+1]																										= false;
bool B_FindConfigMap																												= false;

//String
char S_Mapname_TrackBomb[64];
char S_Direction_TrackBomb[MAX_DIRECTION_TRACK_BOMB][64];
char S_Way_TrackBomb[MAX_DIRECTION_TRACK_BOMB][MAX_WAY_TRACK_BOMB][64];
char S_WaySound_TrackBomb[MAX_DIRECTION_TRACK_BOMB][MAX_WAY_TRACK_BOMB][PLATFORM_MAX_PATH];
char S_active_track_bomb_menu_direction[64];

char M_LASERBEAM[] 																													= "materials/sprites/laserbeam.vmt";
char M_HALO01[] 																													= "materials/sprites/halo.vmt";
char SND_BEEP[] 																													= "buttons/blip1.wav";
char SND_EXPLODE[] 																													= "ambient/explosions/explode_8.wav";

//Float
float F_active_track_bomb_delay_time_msg;

//Customs/Others
int max_map;
int max_direction;
int max_way;

int C_PreOwner;
int C_active_track_bomb_hit_num																											= 0;
int C_hit_num																															= 0;
int M_TACK_BOMB_DECALS_BLOOD[13];

/*
int ColorDefault[] 																														= {255,255,255,255};
int ColorAqua[] 																														= {0,255,255,255};
int ColorBlack[]																														= {1,1,1,255};
int ColorBlue[] 																														= {0,0,255,255};
int ColorFuschia[] 																														= {255,0,255,255};
int ColorGray[] 																														= {128,128,128,255};
int ColorGreen[] 																														= {0,128,0,255};
int ColorLime[] 																														= {0,255,0,255};
int ColorMaroon[] 																														= {128,0,0,255};
int ColorNavy[] 																														= {0,0,128,255};
*/
int ColorRed[] 																															= {255,0,0,255};
/*
int ColorWhite[] 																														= {255,255,255,255};
int ColorYellow[]																														= {255,255,0,255};
int ColorSilver[]																														= {192,192,192,255};
int ColorTeal[]																															= {0,128,128,255};
int ColorPurple[]																														= {128,0,128,255};
int ColorOlive[]																														= {128,128,0,255};
*/

int M_LASERBEAM_PRECACHED;
int M_HALO01_PRECACHED;

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API TRACK BOMB",
	author = "Dr. Api",
	description = "DR.API TRACK BOMB by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://zombie4ever.eu"
}

/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	LoadTranslations("drapi/drapi_track_bomb.phrases");
	AutoExecConfig_SetFile("drapi_track_bomb", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("aio_track_bomb_version", PLUGIN_VERSION, "Version", CVARS);
		
	cvar_active_track_bomb 						= AutoExecConfig_CreateConVar("active_track_bomb",  								"1", 					"Enable/Disable Track the bomb", 						DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	cvar_active_track_bomb_dev					= AutoExecConfig_CreateConVar("active_track_bomb_dev", 								"0", 					"Enable/Disable Track the bomb Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	cvar_active_track_bomb_c4_explode 			= AutoExecConfig_CreateConVar("active_track_bomb_c4_explode",  						"0", 					"Enable/Disable Explode bomb on holder", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	cvar_active_track_bomb_menu_name			= AutoExecConfig_CreateConVar("active_track_bomb_name", 							"0", 					"Enable/Disable Name of holder in chat", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	cvar_active_track_bomb_menu_chat			= AutoExecConfig_CreateConVar("active_track_bomb_chat", 							"1", 					"Enable/Disable Chat message", 							DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	cvar_active_track_bomb_menu_hint			= AutoExecConfig_CreateConVar("active_track_bomb_hint", 							"0", 					"Enable/Disable Hint message", 							DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	cvar_active_track_bomb_menu_alert			= AutoExecConfig_CreateConVar("active_track_bomb_alert", 							"1", 					"Enable/Disable Alert message", 						DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	cvar_active_track_bomb_delay_time_msg		= AutoExecConfig_CreateConVar("active_track_bomb_delay_time_msg", 					"0.0", 					"Delay time for Chat/Hint/Alert Message", 				DEFAULT_FLAGS);
	cvar_active_track_bomb_hit_num				= AutoExecConfig_CreateConVar("active_track_bomb_hit_num", 							"3", 					"Number of hit for explode bomb", 						DEFAULT_FLAGS);
	
	cvar_active_track_bomb_freeze_holder		= AutoExecConfig_CreateConVar("active_track_bomb_freeze_holder", 					"0", 					"Freeze the bomber until he choose the way", 			DEFAULT_FLAGS);
	
	mp_freezetime								= FindConVar("mp_freezetime");
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(Client_IsIngame(i))
		{
			SDKHook(i, SDKHook_TraceAttack, OnTracekAttack);
		}
	}	
	
	HookEvent("round_start", 			Event_RoundStart);
	HookEvent("round_prestart", 		Event_RoundPreStart);
	HookEvent("round_poststart", 		Event_RoundPostStart);
	HookEvent("bomb_dropped", 			Event_BombDropped);
	HookEvent("bomb_pickup", 			Event_BombPickup);
	HookEvent("bomb_abortplant", 		Event_BombAbortPlant);
	HookEvent("bomb_planted", 			Event_BombPlanted);
	
	HookEvents();
	
	RegAdminCmd("sm_trackbomb",		Command_TrackBombMenu, 		ADMFLAG_CHANGEMAP, 		"Display the track bomb menu.");
	
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
		if(IsClientInGame(i))
		{
			SDKUnhook(i, SDKHook_TraceAttack, OnTracekAttack);
		}
		i++;
	}
}

/***********************************************************/
/**************** WHEN CLIENT PUT IN SERVER ****************/
/***********************************************************/
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_TraceAttack, OnTracekAttack);
}

/***********************************************************/
/***************** WHEN CLIENT DISCONNECT ******************/
/***********************************************************/
public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_TraceAttack, OnTracekAttack);
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEvents()
{
	HookConVarChange(cvar_active_track_bomb, 					Event_CvarChange);
	HookConVarChange(cvar_active_track_bomb_dev, 				Event_CvarChange);
	HookConVarChange(cvar_active_track_bomb_c4_explode, 		Event_CvarChange);
	HookConVarChange(cvar_active_track_bomb_menu_chat, 			Event_CvarChange);
	HookConVarChange(cvar_active_track_bomb_menu_hint, 			Event_CvarChange);
	HookConVarChange(cvar_active_track_bomb_menu_alert, 		Event_CvarChange);
	HookConVarChange(cvar_active_track_bomb_menu_name, 			Event_CvarChange);
	HookConVarChange(cvar_active_track_bomb_delay_time_msg, 	Event_CvarChange);
	HookConVarChange(cvar_active_track_bomb_hit_num, 			Event_CvarChange);
	HookConVarChange(cvar_active_track_bomb_freeze_holder, 		Event_CvarChange);
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
	B_active_track_bomb 					= GetConVarBool(cvar_active_track_bomb);
	B_active_track_bomb_dev 				= GetConVarBool(cvar_active_track_bomb_dev);
	B_active_track_bomb_c4_explode 			= GetConVarBool(cvar_active_track_bomb_c4_explode);
	B_active_track_bomb_menu_name 			= GetConVarBool(cvar_active_track_bomb_menu_name);
	B_active_track_bomb_menu_chat 			= GetConVarBool(cvar_active_track_bomb_menu_chat);
	B_active_track_bomb_menu_hint 			= GetConVarBool(cvar_active_track_bomb_menu_hint);
	B_active_track_bomb_menu_alert 			= GetConVarBool(cvar_active_track_bomb_menu_alert);
	F_active_track_bomb_delay_time_msg 		= GetConVarFloat(cvar_active_track_bomb_delay_time_msg);
	C_active_track_bomb_hit_num 			= GetConVarInt(cvar_active_track_bomb_hit_num);
	B_active_track_bomb_freeze_holder 		= GetConVarBool(cvar_active_track_bomb_freeze_holder);
	
	if(B_active_track_bomb_menu_hint && B_active_track_bomb_menu_alert)
	{
		SetFailState("%sYou need to choose between: active_track_bomb_hint or active_track_bomb_alert", TAG_TRACK_BOMB);
	}
}

/***********************************************************/
/******************* WHEN CONFIG EXECUTED ******************/
/***********************************************************/
public void OnConfigsExecuted()
{
	LoadLocationsBomb();
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public void OnMapStart()
{
	M_LASERBEAM_PRECACHED 							= PrecacheModel(M_LASERBEAM);
	M_HALO01_PRECACHED 								= PrecacheModel(M_HALO01);
	PrecacheSound(SND_BEEP, true);
	PrecacheSound(SND_EXPLODE, true);
	PrecacheDecalsBlood();
	
	UpdateState();
}

/***********************************************************/
/********************** WHEN MAP END ***********************/
/***********************************************************/
public void OnMapEnd()
{
	ClearTimer(H_timer_beacon_entity);
}

/***********************************************************/
/******************** WHEN ROUND START *********************/
/***********************************************************/
public Action Event_RoundStart(Handle event, char[] name, bool dontBroadcast)
{
	if(B_active_track_bomb)
	{
		C_hit_num = 0;
		
		if(!isWarmup())
		{
			B_track_bomb_show_menu = true;
			for(int i = 1; i <= MaxClients; ++i)
			{
				if(Client_IsIngame(i))
				{
					if(GetClientTeam(i) == CS_TEAM_T)
					{
						B_has_bomb[i] = false;
						int c4 = GetPlayerWeaponSlot(i, CS_SLOT_C4);
						if(c4 != -1)
						{
							B_has_bomb[i] = true;
							BuildTrackBombMenu(i);
							if(B_active_track_bomb_freeze_holder && B_FindConfigMap)
							{
								if(!IsFakeClient(i))
								{
									SetEntityMoveType(i, MOVETYPE_NONE);
									B_is_freeze[i] = true;
								}
							}
						}
					}
				}
			}
		}
	}
}

/***********************************************************/
/******************* WHEN ROUND PRESTART *******************/
/***********************************************************/
public Action Event_RoundPreStart(Handle event, char[] name, bool dontBroadcast)
{
	if(B_active_track_bomb)
	{
		B_is_round_start = false;
		C_PreOwner = 0;
		ClearTimer(H_timer_beacon_entity);
	}
}

/***********************************************************/
/********************* WHEN FREEZE END *********************/
/***********************************************************/
public Action Event_RoundPostStart(Handle event, char[] name, bool dontBroadcast)
{
	if(B_active_track_bomb)
	{
		B_is_round_start = true;
	}
}

/***********************************************************/
/****************** WHEN PLAYER DROP BOMB ******************/
/***********************************************************/
public Action Event_BombDropped(Handle event, char[] name, bool dontBroadcast)
{
	if(B_active_track_bomb)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if(Client_IsIngame(client) && GetClientTeam(client) == CS_TEAM_T)
		{
			char location[128];
			GetChatLocation(client, location, sizeof(location));
			
			C_PreOwner = client;
			
			if(B_active_track_bomb_freeze_holder && B_is_freeze[client])
			{
				SetEntityMoveType(client, MOVETYPE_WALK);
			}
							
			int c4 = GetPlayerWeaponSlot(client, CS_SLOT_C4);
			if(c4 != -1)
			{
				Handle dataPackHandle;
				H_timer_beacon_entity = CreateDataTimer(2.0, Timer_Beacon_Entity, dataPackHandle, TIMER_REPEAT);	
				WritePackCell(dataPackHandle, EntIndexToEntRef(c4));
			}
			
			int health = GetClientHealth(client);
			if(health > 0)
			{
				B_has_bomb[client] = false;
				CancelClientMenu(client);
				
				Handle dataPackHandle2;
				CreateDataTimer(F_active_track_bomb_delay_time_msg, DisplayMessageForTerroBombDropped, dataPackHandle2);
				WritePackString(dataPackHandle2, location);
			}
			else if(health <= 0)
			{
				B_has_bomb[client] = false;
				B_track_bomb_show_menu = false;
				CancelClientMenu(client);
				
				Handle dataPackHandle3;
				CreateDataTimer(F_active_track_bomb_delay_time_msg, DisplayMessageForTerroBombDroppedAndPlayerDead, dataPackHandle3);
				WritePackString(dataPackHandle3, location);		
			}
		}
	}
}

/***********************************************************/
/****************** WHEN PLAYER PICKUP BOMB ****************/
/***********************************************************/
public Action Event_BombPickup(Handle event, char[] name, bool dontBroadcast)
{
	if(B_active_track_bomb)
	{
		ClearTimer(H_timer_beacon_entity);
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if(C_PreOwner == client) return;
		
		if(Client_IsIngame(client) && GetClientTeam(client) == CS_TEAM_T)
		{
			B_has_bomb[client] = true;
			if(B_track_bomb_show_menu)
			{
				BuildTrackBombMenu(client);
			}
			if(!isWarmup() && B_is_round_start)
			{
				char location[128];
				GetChatLocation(client, location, sizeof(location));
				
				Handle dataPackHandle;
				CreateDataTimer(F_active_track_bomb_delay_time_msg, DisplayMessageForTerroBombPickup, dataPackHandle);
				WritePackString(dataPackHandle, location);	
			}
		}
	}
}

/***********************************************************/
/****************** WHEN PLAYER ABORT BOMB *****************/
/***********************************************************/
public Action Event_BombAbortPlant(Handle event, char[] name, bool dontBroadcast)
{
	if(B_active_track_bomb)
	{	
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if(Client_IsIngame(client) && GetClientTeam(client) == CS_TEAM_T)
		{
			char location[128];
			GetChatLocation(client, location, sizeof(location));
				
			Handle dataPackHandle;
			CreateDataTimer(F_active_track_bomb_delay_time_msg, DisplayMessageForTerroBombAborted, dataPackHandle);
			WritePackString(dataPackHandle, location);
		}
	}
}

/***********************************************************/
/****************** WHEN PLAYER PLANT BOMB *****************/
/***********************************************************/
public Action Event_BombPlanted(Handle event, char[] name, bool dontBroadcast)
{
	if(B_active_track_bomb)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if(Client_IsIngame(client) && GetClientTeam(client) == CS_TEAM_T)
		{
			B_has_bomb[client] = false;
			CancelClientMenu(client);
			
			char location[128];
			GetChatLocation(client, location, sizeof(location));
				
			Handle dataPackHandle;
			CreateDataTimer(F_active_track_bomb_delay_time_msg, DisplayMessageForTerroBombPlanted, dataPackHandle);
			WritePackString(dataPackHandle, location);
		}	
	}
}

/***********************************************************/
/********************* WHEN PLAYER HURT ********************/
/***********************************************************/
/* BACK = hitbox = 8 + hitgroup = 2 */
public Action OnTracekAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	//if(B_active_track_bomb)
	{
		if(B_active_track_bomb_c4_explode)
		{
			if(Client_IsIngame(victim) && Client_IsIngame(attacker))
			{
				int c4 = GetPlayerWeaponSlot(victim, CS_SLOT_C4);
				if(c4 != -1 && c4 != GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon"))
				{
					if(hitbox == 9 && damagetype == DMG_SHOT && hitgroup == 2)
					{
						if(GetClientTeam(victim) != GetClientTeam(attacker))
						{
							C_hit_num += 1;
							damage = 0.0;
							
							Handle kv = CreateKeyValues("bomb");
							KvSetNum(kv, "hit", C_hit_num);	
							KvSetNum(kv, "total_hit", C_active_track_bomb_hit_num);	
							KvSetNum(kv, "victim", victim);
							KvSetNum(kv, "attacker", attacker);
							
							if(C_hit_num == C_active_track_bomb_hit_num)
							{	
								Explode(victim, attacker, c4);
								CreateTimer(F_active_track_bomb_delay_time_msg, DisplayMessageHolderExplode, kv);	
								
								C_hit_num = 0;
							}
							else if(C_hit_num != 0 && C_hit_num < C_active_track_bomb_hit_num)
							{
								CreateTimer(F_active_track_bomb_delay_time_msg, DisplayMessageWarningBomb, kv);
							}
						}
						return Plugin_Changed;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

/***********************************************************/
/********************** PLAYER EXPLODE *********************/
/***********************************************************/
void Explode(int victim, int attacker, int c4)
{
	float pos[3];
	GetClientAbsOrigin(victim, pos);
	int victim_death = GetEntProp(victim, Prop_Data, "m_iDeaths");
	int vicitm_frags = GetEntProp(victim, Prop_Data, "m_iFrags");
	int attacker_frags = GetEntProp(attacker, Prop_Data, "m_iFrags");
	
	int explosion = CreateEntityByName("env_explosion");
	
	if(explosion != -1)
	{
		SetEntityHealth(victim, 1);
		
		// Stuff we will need
		float vector[3];
		int damage = 500;
		int radius = 128;
		int team = GetEntProp(victim, Prop_Send, "m_iTeamNum");
					
		// We're going to use eye level because the blast can be clipped by almost anything.
		// This way there's no chance that a small street curb will clip the blast.
		GetClientEyePosition(victim, vector);
					
			
		SetEntProp(explosion, Prop_Send, "m_iTeamNum", team);
		SetEntProp(explosion, Prop_Data, "m_spawnflags", 264);
		SetEntProp(explosion, Prop_Data, "m_iMagnitude", damage);
		SetEntProp(explosion, Prop_Data, "m_iRadiusOverride", radius);
		
		DispatchKeyValue(explosion, "rendermode", "5");
					
		DispatchSpawn(explosion);
		ActivateEntity(explosion);

		TE_SetupExplosion(pos, M_HALO01_PRECACHED, 5.0, 1, 0, 100, 1500);
		TE_Start("World Decal");
		TE_WriteVector("m_vecOrigin", pos);
		int random = GetRandomInt(0, 12);
		TE_WriteNum("m_nIndex", M_TACK_BOMB_DECALS_BLOOD[random]);
	
		TE_SendToAll();
		
		RemovePlayerItem(victim, c4);
		AcceptEntityInput(c4, "Kill");
		
		TeleportEntity(explosion, vector, NULL_VECTOR, NULL_VECTOR);
		EmitSoundToAll("weapons/hegrenade/explode3.wav", explosion, 1, 90);		
		AcceptEntityInput(explosion, "Explode");

		EmitSoundToAll("weapons/c4/c4_explode1.wav", explosion, 1, 90);
		
		SetEntProp(victim, Prop_Data, "m_iFrags", vicitm_frags);
		SetEntProp(victim, Prop_Data, "m_iDeaths", victim_death + 1);
		SetEntProp(attacker, Prop_Data, "m_iFrags", attacker_frags + 1);
	}
}

/***********************************************************/
/****************** PRECACHE BLOOD DECALS ******************/
/***********************************************************/
void PrecacheDecalsBlood()
{
	M_TACK_BOMB_DECALS_BLOOD[0] = PrecacheDecal("decals/blood_splatter.vtf");
	M_TACK_BOMB_DECALS_BLOOD[1] = PrecacheDecal("decals/bloodstain_003.vtf");
	M_TACK_BOMB_DECALS_BLOOD[2] = PrecacheDecal("decals/bloodstain_101.vtf");
	M_TACK_BOMB_DECALS_BLOOD[3] = PrecacheDecal("decals/bloodstain_002.vtf");
	M_TACK_BOMB_DECALS_BLOOD[4] = PrecacheDecal("decals/bloodstain_001.vtf");
	M_TACK_BOMB_DECALS_BLOOD[5] = PrecacheDecal("decals/blood8.vtf");
	M_TACK_BOMB_DECALS_BLOOD[6] = PrecacheDecal("decals/blood7.vtf");
	M_TACK_BOMB_DECALS_BLOOD[7] = PrecacheDecal("decals/blood6.vtf");
	M_TACK_BOMB_DECALS_BLOOD[8] = PrecacheDecal("decals/blood5.vtf");
	M_TACK_BOMB_DECALS_BLOOD[9] = PrecacheDecal("decals/blood4.vtf");
	M_TACK_BOMB_DECALS_BLOOD[10] = PrecacheDecal("decals/blood3.vtf");
	M_TACK_BOMB_DECALS_BLOOD[11] = PrecacheDecal("decals/blood2.vtf");
	M_TACK_BOMB_DECALS_BLOOD[12] = PrecacheDecal("decals/blood1.vtf");
}

/***********************************************************/
/******************** GET CHAT LOCATION ********************/
/***********************************************************/
bool GetChatLocation(int client, char[] szBuffer, int size)
{
    if (!Client_IsIngame(client) || !IsPlayerAlive(client))
        return false;

    if (GetClientTeam(client) != CS_TEAM_T && GetClientTeam(client) != CS_TEAM_CT)
        return false;

    GetEntPropString(client, Prop_Send, "m_szLastPlaceName", szBuffer, size);
    return true;

}

/***********************************************************/
/************* DISPLAY BEACON AROUND THE BOMB **************/
/***********************************************************/
public Action Timer_Beacon_Entity(Handle timer, Handle dataPackHandle)
{
	ResetPack(dataPackHandle);
	int entity = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	
	if(!IsValidEntity(entity))
	{
		return Plugin_Stop;
	}
	
	float position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	TE_SetupBeamRingPoint(position, 10.0, 375.0, M_LASERBEAM_PRECACHED, M_HALO01_PRECACHED, 0, 10, 0.2, 1.0, 0.5, ColorRed, 10, 0);
	

	TE_SendToAllTerro();
	PlayBeep(entity, 1.0, position, SND_NOFLAGS);
	return Plugin_Continue;
}

/***********************************************************/
/********* SEND BEACON AROUND THE BOMB FOR TERRO ***********/
/***********************************************************/
stock int TE_SendToAllTerro(float delay = 0.0)
{
	int total = 0;
	int[] clients = new int[MaxClients];
	for (int i = 1; i <= MaxClients; i++)
	{
		if(Client_IsIngame(i))
		{
			if(GetClientTeam(i) == CS_TEAM_T)//&& client != c
			{
				clients[total++] = i;
			}
		}
	}
	return TE_Send(clients, total, delay);
}

/***********************************************************/
/********* SEND SOUND AROUND THE BOMB FOR TERRO ************/
/***********************************************************/
void PlayBeep(int entity = SOUND_FROM_PLAYER, float vol, const float position[3] = NULL_VECTOR, int flags)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i))
		{
			if(GetClientTeam(i) == CS_TEAM_T)
			{	
				EmitSoundToClient(i, SND_BEEP, entity, SND_BOMB, _, flags, vol, _, _,position);
			}
		}
	}
}

/***********************************************************/
/********* DISPLAY MSG FOR TERRO WHEN BOMB PICKUP **********/
/***********************************************************/
public Action DisplayMessageForTerroBombPickup(Handle timer, Handle dataPackHandle)
{
	ResetPack(dataPackHandle);
	
	char location[128];
	ReadPackString(dataPackHandle, location, sizeof(location));
	
	if(StrEqual(location, "", false)) return Plugin_Handled;
	
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(Client_IsIngame(i))
		{	
			if(GetClientTeam(i) == CS_TEAM_T)//&& client != c
			{
				if(B_active_track_bomb_menu_chat)
				{
					CPrintToChat(i, "%t", "Track bomb bomb pickup chat", location);
				}
				
				if(B_active_track_bomb_menu_hint)
				{
					PrintHintText(i, "%t", "Track bomb bomb pickup hint", location);
				}
				else
				{
					PrintCenterText(i, "%t", "Track bomb bomb pickup alert", location);
				}
			}
		}
	}
	return Plugin_Continue;
}

/***********************************************************/
/********* DISPLAY MSG FOR TERRO WHEN BOMB PLANTED *********/
/***********************************************************/
public Action DisplayMessageForTerroBombPlanted(Handle timer, Handle dataPackHandle)
{
	ResetPack(dataPackHandle);
	
	char location[128];
	ReadPackString(dataPackHandle, location, sizeof(location));
	
	if(StrEqual(location, "", false)) return Plugin_Handled;
	
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(Client_IsIngame(i))
		{	
			if(GetClientTeam(i) == CS_TEAM_T)//&& client != c
			{
				if(B_active_track_bomb_menu_chat)
				{
					CPrintToChat(i, "%t", "Track bomb bomb planted chat", location);
				}
				
				if(B_active_track_bomb_menu_hint)
				{
					PrintHintText(i, "%t", "Track bomb bomb planted hint", location);
				}
				else
				{
					PrintCenterText(i, "%t", "Track bomb bomb planted alert", location);
				}
			}
		}
	}
	return Plugin_Continue;
}

/***********************************************************/
/********* DISPLAY MSG FOR TERRO WHEN BOMB ABORTED *********/
/***********************************************************/
public Action DisplayMessageForTerroBombAborted(Handle timer, Handle dataPackHandle)
{
	ResetPack(dataPackHandle);
	
	char location[128];
	ReadPackString(dataPackHandle, location, sizeof(location));
	
	if(StrEqual(location, "", false)) return Plugin_Handled;
	
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(Client_IsIngame(i))
		{	
			if(GetClientTeam(i) == CS_TEAM_T)//&& client != c
			{
				if(B_active_track_bomb_menu_chat)
				{
					CPrintToChat(i, "%t", "Track bomb bomb abort chat", location);
				}
				
				if(B_active_track_bomb_menu_hint)
				{
					PrintHintText(i, "%t", "Track bomb bomb abort hint", location);
				}
				else
				{
					PrintCenterText(i, "%t", "Track bomb bomb abort alert", location);
				}
			}
		}
	}
	return Plugin_Continue;
}

/***********************************************************/
/********* DISPLAY MSG FOR TERRO WHEN BOMB DROPPED *********/
/***********************************************************/
public Action DisplayMessageForTerroBombDropped(Handle timer, Handle dataPackHandle)
{
	ResetPack(dataPackHandle);
	
	char location[128];
	ReadPackString(dataPackHandle, location, sizeof(location));
	
	if(StrEqual(location, "", false)) return Plugin_Handled;
	
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(Client_IsIngame(i))
		{	
			if(GetClientTeam(i) == CS_TEAM_T)//&& client != c
			{
				if(B_active_track_bomb_menu_chat)
				{
					CPrintToChat(i, "%t", "Track bomb bomb dropped chat", location);
				}
				
				if(B_active_track_bomb_menu_hint)
				{
					PrintHintText(i, "%t", "Track bomb bomb dropped hint", location);
				}
				else
				{
					PrintCenterText(i, "%t", "Track bomb bomb dropped alert", location);
				}
			}
		}
	}
	return Plugin_Continue;
}

/***********************************************************/
/* DISPLAY MSG FOR TERRO WHEN BOMB DROPPED AND HOLDER DIE **/
/***********************************************************/
public Action DisplayMessageForTerroBombDroppedAndPlayerDead(Handle timer, Handle dataPackHandle)
{
	ResetPack(dataPackHandle);

	char location[128];
	ReadPackString(dataPackHandle, location, sizeof(location));
	
	if(StrEqual(location, "", false)) return Plugin_Handled;
	
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(Client_IsIngame(i))
		{	
			if(GetClientTeam(i) == CS_TEAM_T)//&& client != c
			{
				if(B_active_track_bomb_menu_chat)
				{
					CPrintToChat(i, "%t", "Track bomb bomb player die chat", location);
				}
				
				if(B_active_track_bomb_menu_hint)
				{
					PrintHintText(i, "%t", "Track bomb bomb player die hint", location);
				}
				else
				{
					PrintCenterText(i, "%t", "Track bomb bomb player die alert", location);
				}
			}
		}
	}
	return Plugin_Continue;
}

/***********************************************************/
/******** DISPLAY MSG FOR TERRO WHEN OBJECTIVE SET *********/
/***********************************************************/
public Action DisplayMessageForTerroObjective(Handle timer, any data)
{							
	char direction[64], way[64], sound[PLATFORM_MAX_PATH];
	Handle kv 	= view_as<Handle>(data);
	int client 	= KvGetNum(kv, "client", -1);
	KvGetString(kv, "direction", direction, sizeof(direction), "NULL");
	KvGetString(kv, "way", way, sizeof(way), "NULL");
	KvGetString(kv, "sound", sound, sizeof(sound), "NULL");
	
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(Client_IsIngame(i))
		{	
			if(GetClientTeam(i) == CS_TEAM_T)//&& client != c
			{
				if(B_active_track_bomb_menu_chat)
				{
					if(B_active_track_bomb_menu_name)
					{
						char holder[64];
						GetClientName(client, holder, sizeof(holder));
						
						CPrintToChat(i, "%t", "Track Bomb direction and way chat holder", holder);
					}
					CPrintToChat(i, "%t", "Track Bomb direction and way chat direction", direction);
					CPrintToChat(i, "%t", "Track Bomb direction and way chat way", way);
				}
				
				if(B_active_track_bomb_menu_hint)
				{
					PrintHintText(i, "%t", "Track Bomb direction and way hint", direction, way);
				}
				else
				{
					PrintCenterText(i, "%t", "Track Bomb direction and way alert", direction, way);
				}
				if(strlen(sound))
				{
					char soundFile[PLATFORM_MAX_PATH];
					Format(soundFile, sizeof(soundFile), "*%s", sound);

					EmitSoundToClient(i, soundFile, _, _, _, _, 1.0);
				}
			}
		}
	}
}

/***********************************************************/
/******* DISPLAY MSG WHEN BOMB TOUCHED AND EXPLODED ********/
/***********************************************************/
public Action DisplayMessageHolderExplode(Handle timer, any data)
{
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(Client_IsIngame(i))
		{
			Handle kv 		= view_as<Handle>(data);
			int victim 		= KvGetNum(kv, "victim", -1);
			int attacker 	= KvGetNum(kv, "attacker", -1);
			int hit			= KvGetNum(kv, "hit", -1);
			int total_hit	= KvGetNum(kv, "total_hit", -1);
			
			char victim_name[64], attacker_name[64];
			GetClientName(victim, victim_name, sizeof(victim_name));
			GetClientName(attacker, attacker_name, sizeof(attacker_name));

			if(B_active_track_bomb_menu_chat)
			{
				CPrintToChat(i, "%t", "Track Bomb holder explode chat", attacker_name, victim_name, hit, total_hit);
			}
			
			if(B_active_track_bomb_menu_hint)
			{
				PrintHintText(i, "%t", "Track Bomb holder explode hint ", attacker_name, victim_name, hit, total_hit);
			}
			else
			{
				PrintCenterText(i, "%t", "Track Bomb holder explode alert", attacker_name, victim_name, hit, total_hit);
			}
		}
	}
}

/***********************************************************/
/************* DISPLAY MSG WHEN BOMB TOUCHED ***************/
/***********************************************************/
public Action DisplayMessageWarningBomb(Handle timer, any data)
{
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(Client_IsIngame(i))
		{
			Handle kv 		= view_as<Handle>(data);
			int hit			= KvGetNum(kv, "hit", -1);
			int total_hit	= KvGetNum(kv, "total_hit", -1);
			

			if(GetClientTeam(i) == CS_TEAM_T)
			{
				if(B_active_track_bomb_menu_chat)
				{
					CPrintToChat(i, "%t", "Track bomb bomb hit terro chat", hit, total_hit);
				}
				
				if(B_active_track_bomb_menu_hint)
				{
					PrintHintText(i, "%t", "Track bomb bomb hit terro hint", hit, total_hit);
				}
				else
				{
					PrintCenterText(i, "%t", "Track bomb bomb hit terro alert", hit, total_hit);
				}
			}
			else if(GetClientTeam(i) == CS_TEAM_CT)
			{
				if(B_active_track_bomb_menu_chat)
				{
					CPrintToChat(i, "%t", "Track bomb bomb hit ct chat", hit, total_hit);
				}
				
				if(B_active_track_bomb_menu_hint)
				{
					PrintHintText(i, "%t", "Track bomb bomb hit ct hint", hit, total_hit);
				}
				else
				{
					PrintCenterText(i, "%t", "Track bomb bomb hit ct alert", hit, total_hit);
				}
			}
		}
	}
}
/***********************************************************/
/******************* COMMANDE TRACK BOMB *******************/
/***********************************************************/
public Action Command_TrackBombMenu(int client, int args) 
{
	BuildTrackBombMenu(client);
	return Plugin_Handled;
}

/***********************************************************/
/****************** BUILD TRACK BOMB MENU ******************/
/***********************************************************/
void BuildTrackBombMenu(int client)
{
	char title[40], direction[40];
	Menu menu = CreateMenu(TrackBomb_Menu);
	
	char Mapname[64];
	GetCurrentMap(Mapname, sizeof(Mapname));
	
	SetMenuExitBackButton(menu, false);
	SetMenuExitButton(menu, false);
	
	int c4 = GetPlayerWeaponSlot(client, CS_SLOT_C4);
	if(c4 != -1)
	{	

		if(strlen(S_Mapname_TrackBomb) && StrEqual(Mapname, S_Mapname_TrackBomb, false))
		{
			for(int i = 0; i < max_direction; ++i)
			{	
				if(strlen(S_Direction_TrackBomb[i]))
				{
					Format(direction, sizeof(direction), "%T", "Track Bomb direction menu", client, S_Direction_TrackBomb[i]);
					AddMenuItem(menu, S_Direction_TrackBomb[i], direction);
				}
			}
		}
		
		Format(title, sizeof(title), "%T", "Track Bomb site bomb menu title", client);
		SetMenuTitle(menu, title);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

/***********************************************************/
/**************** BUILD TRACK BOMB SUB MENU ****************/
/***********************************************************/
public int TrackBomb_Menu(Handle menu, MenuAction action, int param1, int param2)
{
	if(Client_IsIngame(param1))
	{
		int c4 = GetPlayerWeaponSlot(param1, CS_SLOT_C4);
		if(c4 != -1)
		{	
			switch(action)
			{
				case MenuAction_End:
				{
					CloseHandle(menu);	
				}
				case MenuAction_Select:
				{
					char title[40];
					Menu waymenu = CreateMenu(TrackBombWay_Menu);
					
					char menu1[64];
					char Mapname[64];
					
					GetMenuItem(menu, param2, menu1, sizeof(menu1));
					SetMenuExitBackButton(waymenu, true);
					SetMenuExitButton(waymenu, false);
					GetCurrentMap(Mapname, sizeof(Mapname));
					

					if(strlen(S_Mapname_TrackBomb) && StrEqual(Mapname, S_Mapname_TrackBomb, false))
					{
						for(int i = 0; i < max_direction; ++i)
						{	
							if(strlen(S_Direction_TrackBomb[i]) && StrEqual(menu1, S_Direction_TrackBomb[i], false))
							{
								S_active_track_bomb_menu_direction = S_Direction_TrackBomb[i];
								for(int w = 0; w < max_way; ++w)
								{
									if(strlen(S_Way_TrackBomb[i][w]))
									{
										char way[64];
										
										Format(way, sizeof(way), "%T", "Track Bomb way menu", param1, S_Way_TrackBomb[i][w]);
										AddMenuItem(waymenu, S_Way_TrackBomb[i][w], way);
									}
								}
							}
						}
					}

					Format(title, sizeof(title), "%T", "Track Bomb way menu title", param1);
					SetMenuTitle(waymenu, title);
					DisplayMenu(waymenu, param1, MENU_TIME_FOREVER);
				}
			}
		}
	}
}

/***********************************************************/
/************* DISPLAY MSG OBJECTIVE BY CHOICE *************/
/***********************************************************/
public int TrackBombWay_Menu(Handle menu, MenuAction action, int param1, int param2)
{
	if(Client_IsIngame(param1))
	{
		int c4 = GetPlayerWeaponSlot(param1, CS_SLOT_C4);
		if(c4 != -1)
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
						BuildTrackBombMenu(param1);
					}
				}
				case MenuAction_Select:
				{
					char menu1[64];
					char Mapname[64];
					
					GetMenuItem(menu, param2, menu1, sizeof(menu1));
					GetCurrentMap(Mapname, sizeof(Mapname));
					
					if(strlen(S_Mapname_TrackBomb) && StrEqual(Mapname, S_Mapname_TrackBomb, false))
					{
						for(int i = 0; i < max_direction; ++i)
						{	
							if(strlen(S_Direction_TrackBomb[i]) && StrEqual(S_active_track_bomb_menu_direction, S_Direction_TrackBomb[i], false))
							{
								for(int w = 0; w < max_way; ++w)
								{
									if(strlen(S_Way_TrackBomb[i][w]) && StrEqual(menu1, S_Way_TrackBomb[i][w], false))
									{
										Handle kv = CreateKeyValues("objective");
										KvSetNum(kv, "client", param1);
										KvSetString(kv, "direction", S_Direction_TrackBomb[i]);
										KvSetString(kv, "way", S_Way_TrackBomb[i][w]);
										KvSetString(kv, "sound", S_WaySound_TrackBomb[i][w]);
										
										float F_time_show_menu;
										float F_freezetime;
										
										F_freezetime = GetConVarFloat(mp_freezetime);
										if(!isWarmup() && isFreeze())
										{
											if(F_freezetime >= 4)
											{
												F_time_show_menu = F_freezetime;
											}
											else
											{
												F_time_show_menu = 4.0;
											}	
										}
										else
										{
											F_time_show_menu = 1.0;
										}
										
										CreateTimer(F_time_show_menu, DisplayMessageForTerroObjective, kv); 
										if(B_active_track_bomb_freeze_holder && B_FindConfigMap && B_is_freeze[param1])
										{
											SetEntityMoveType(param1, MOVETYPE_WALK);
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

/***********************************************************/
/****************** LOAD FILE SETTING BOMB *****************/
/***********************************************************/
public void LoadLocationsBomb()
{
	char hc[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, hc, sizeof(hc), "configs/drapi/track_bomb.cfg");
	
	Handle kv = CreateKeyValues("TrackBomb");
	FileToKeyValues(kv, hc);
	
	B_FindConfigMap = false;
	
	max_map = 0;
	max_direction = 0;
	max_way = 0;
	
	char S_Mapname[64];
	GetCurrentMap(S_Mapname, sizeof(S_Mapname));
	
	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			if(KvGetSectionName(kv, S_Mapname_TrackBomb, sizeof(S_Mapname_TrackBomb)) && StrEqual(S_Mapname_TrackBomb, S_Mapname, false))
			{
				if(KvGotoFirstSubKey(kv))
				{
					if(KvGotoFirstSubKey(kv))
					{
						do
						{
							if(KvGetSectionName(kv, S_Direction_TrackBomb[max_direction], 64) && strlen(S_Direction_TrackBomb[max_direction]))
							{
								for(int i = 1; i < MAX_WAY_TRACK_BOMB; ++i)
								{
									char key[64], sound[PLATFORM_MAX_PATH];
									IntToString(i, key, 64);
									Format(sound, sizeof(sound), "sound%i", i);
									
									if( (KvGetString(kv, key, S_Way_TrackBomb[max_direction][i], 64) && strlen(S_Way_TrackBomb[max_direction][i])) && (KvGetString(kv, sound, S_WaySound_TrackBomb[max_direction][i], PLATFORM_MAX_PATH) && strlen(S_WaySound_TrackBomb[max_direction][i])) )
									{
										if(!StrEqual(S_WaySound_TrackBomb[max_direction][i], "none", false))
										{
											char FULL_SOUND_PATH[PLATFORM_MAX_PATH];
											Format(FULL_SOUND_PATH, PLATFORM_MAX_PATH, "sound/%s", S_WaySound_TrackBomb[max_direction][i]);
											AddFileToDownloadsTable(FULL_SOUND_PATH);
											
											char RELATIVE_SOUND_PATH[PLATFORM_MAX_PATH];
											Format(RELATIVE_SOUND_PATH, PLATFORM_MAX_PATH, "*%s", S_WaySound_TrackBomb[max_direction][i]);
											FakePrecacheSound(RELATIVE_SOUND_PATH);
											
											//LogMessage("[%s] - %s: %s", S_Direction_TrackBomb[max_direction], S_Way_TrackBomb[max_direction][i], S_WaySound_TrackBomb[max_direction][i]);
										}
											
										B_FindConfigMap = true;
										max_way++;
									}
									else
									{
										break;
									}
								}
								max_direction++;
							}
							

						}
						while (KvGotoNextKey(kv));
					}
					KvGoBack(kv);
				}
				max_map++;
			}
			
		}
		while (KvGotoNextKey(kv));
	}
	CloseHandle(kv);
	
	//LogMessage("%i %i %i", max_map, max_direction, max_way);
}

/***********************************************************/
/********************* IS VALID CLIENT *********************/
/***********************************************************/
stock bool Client_IsValid(int client, bool checkConnected=true)
{
	if (client > 4096) 
	{
		client = EntRefToEntIndex(client);
	}

	if (client < 1 || client > MaxClients) 
	{
		return false;
	}

	if (checkConnected && !IsClientConnected(client)) 
	{
		return false;
	}
	
	return true;
}

/***********************************************************/
/******************** IS CLIENT IN GAME ********************/
/***********************************************************/
stock bool Client_IsIngame(int client)
{
	if (!Client_IsValid(client, false)) 
	{
		return false;
	}

	return IsClientInGame(client);
}

/***********************************************************/
/************************ IS WARMUP ************************/
/***********************************************************/
stock bool isWarmup()
{
	return (GameRules_GetProp("m_bWarmupPeriod") == 1);
}

/***********************************************************/
/************************ IS Freeze ************************/
/***********************************************************/
stock bool isFreeze()
{
	return (GameRules_GetProp("m_bFreezePeriod") == 1);
}

/***********************************************************/
/******************** ADD SOUND TO CACHE *******************/
/***********************************************************/
stock void FakePrecacheSound(const char[] szPath)
{
	AddToStringTable( FindStringTable( "soundprecache" ), szPath );
}

/***********************************************************/
/********************** CLEAR TIMER ************************/
/***********************************************************/
stock void ClearTimer(Handle &timer)
{
    if (timer != INVALID_HANDLE)
    {
        KillTimer(timer);
        timer = INVALID_HANDLE;
    }     
}