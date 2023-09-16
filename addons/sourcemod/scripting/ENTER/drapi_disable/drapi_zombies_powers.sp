/* <DR.API ZOMBIES POWERS> (c) by <De Battista Clint - (http://doyou.watch)  */
/*                                                                           */
/*              <DR.API ZOMBIES POWERS> is licensed under a                  */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//***************************DR.API ZOMBIES POWERS***************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[ZOMBIES POWERS] -"
#define MAX_SKINS						200
#define MAX_DAYS 						25


//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <stocks>
#include <drapi_zombie_riot>
#include <drapi_hpbar>

#pragma newdecls required


//***********************************//
//***********PARAMETERS**************//
//***********************************//

#define particle_smoker_tongue 			"smoker_tongue"
#define particle_smoker_cloud 			"smoker_smokecloud"

#define particle_boomer_vomit 			"boomer_vomit"
#define particle_boomer_explode 		"boomer_explode"
#define particle_boomer_screen 			"boomer_vomit_screeneffect"
#define SNDCHAN_SPIT					134
#define SNDCHAN_GRAB					133
#define SNDCHAN_SPITTER_EXPLODE			132
#define SNDCHAN_GRABBER_EXPLODE			131

//Handle
Handle cvar_active_zombies_powers_dev;

Handle cvar_zombies_powers_spitter_distance;
Handle cvar_zombies_powers_spitter_chance;
Handle cvar_zombies_powers_spitter_speed;
Handle cvar_zombies_powers_spitter_health;
Handle cvar_zombies_powers_spitter_damage;
Handle cvar_zombies_powers_spitter_fadeout_max;

Handle cvar_zombies_powers_grabber_distance;
Handle cvar_zombies_powers_grabber_chance;
Handle cvar_zombies_powers_grabber_speed;
Handle cvar_zombies_powers_grabber_health;
Handle cvar_zombies_powers_grabber_damage;
Handle cvar_zombies_powers_grabber_fadeout_max;
Handle cvar_zombies_powers_grabber_min_heal_stop;
Handle cvar_zombies_powers_grabber_damage_grabbing;
Handle cvar_zombies_powers_grabber_damage_grabbing_repeat;

Handle cvar_zombies_powers_damage;

Handle kvDays 													= INVALID_HANDLE;

int H_zombies_powers_spitter_chance;
int H_zombies_powers_spitter_health;

int H_zombies_powers_grabber_chance;
int H_zombies_powers_grabber_health;
int H_zombies_powers_grabber_min_heal_stop;
int H_zombies_powers_grabber_damage_grabbing;


Handle TrieAttackerPoisoned[MAXPLAYERS + 1]						= INVALID_HANDLE;
Handle TrieVictimPoisoned[MAXPLAYERS + 1]						= INVALID_HANDLE;

Handle TrieAttackerGrabbed[MAXPLAYERS + 1]						= INVALID_HANDLE;
Handle TrieVictimGrabbed[MAXPLAYERS + 1]						= INVALID_HANDLE;

//Bool
bool B_active_zombies_powers_dev 							= false;
bool B_AllowZombiesPowers									= false;
bool TimeToRelease											= false;

//Float
float F_zombies_powers_spitter_distance;
float F_zombies_powers_spitter_speed;
float F_zombies_powers_spitter_damage;
float F_zombies_powers_spitter_fadeout_max;


float F_zombies_powers_grabber_distance;
float F_zombies_powers_grabber_speed;
float F_zombies_powers_grabber_damage;
float F_zombies_powers_grabber_fadeout_max;
float F_zombies_powers_grabber_damage_grabbing_repeat;

float F_speed;
float F_zombies_powers_damage;

float F_last_time_damage_grabbed;

float data_zombies_powers_common_damage[MAX_DAYS];
float data_zombies_powers_spitter_distance[MAX_DAYS];
float data_zombies_powers_spitter_speed[MAX_DAYS];
float data_zombies_powers_spitter_damage[MAX_DAYS];
float data_zombies_powers_spitter_fadeout_max[MAX_DAYS];
float data_zombies_powers_grabber_distance[MAX_DAYS];
float data_zombies_powers_grabber_speed[MAX_DAYS];
float data_zombies_powers_grabber_damage[MAX_DAYS];
float data_zombies_powers_grabber_fadeout_max[MAX_DAYS];
float data_zombies_powers_grabber_damage_grabbing_repeat[MAX_DAYS];

//Strings
char S_sound_spit[1][PLATFORM_MAX_PATH]							= {"player/boomer/vomit/attack/bv1.mp3"};
char S_sound_spitter_explode[1][PLATFORM_MAX_PATH]				= {"player/boomer/explode/explo_medium_14.mp3"}; 
char S_sound_grab[1][PLATFORM_MAX_PATH]							= {"player/smoker/voice/attack/smoker_launchtongue_03.mp3"};
char S_sound_grabber_explode[1][PLATFORM_MAX_PATH]				= {"player/smoker/death/smoker_explode_02.mp3"};  
																  
char S_model_client[PLATFORM_MAX_PATH];
char S_skins[MAX_SKINS][PLATFORM_MAX_PATH];
char S_skins_height[MAX_SKINS][PLATFORM_MAX_PATH];

//Customs
int INT_TOTAL_DAY;
int max_skins;
int Spitter[MAXPLAYERS + 1];
int C_ChanceSpitter[MAXPLAYERS + 1];
int C_PlayerPoison[MAXPLAYERS + 1] 								= INVALID_ENT_REFERENCE;
int C_LastButtons[MAXPLAYERS + 1];
int VictimPoisoned[MAXPLAYERS + 1]								= false;
int AttackerPoisoned[MAXPLAYERS + 1]							= false;
int AllowToSpit[MAXPLAYERS + 1]									= false;


int Grabber[MAXPLAYERS + 1];
int C_ChanceGrabber[MAXPLAYERS + 1];
int AllowToGrab[MAXPLAYERS + 1]									= false;
int VictimGrabbed[MAXPLAYERS + 1]								= false;
int AttackerGrabbed[MAXPLAYERS + 1]								= false;
int VictimGrabbedTonguePartcile[MAXPLAYERS + 1][2];

int data_zombies_powers_spitter_chance[MAX_DAYS];
int data_zombies_powers_spitter_health[MAX_DAYS];
int data_zombies_powers_grabber_chance[MAX_DAYS];
int data_zombies_powers_grabber_health[MAX_DAYS];
int data_zombies_powers_grabber_min_heal_stop[MAX_DAYS];
int data_zombies_powers_grabber_damage_grabbing[MAX_DAYS];

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API ZOMBIES POWERS",
	author = "Dr. Api",
	description = "DR.API ZOMBIES POWERS by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://doyou.watch"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	FindOffsets();
	AutoExecConfig_SetFile("drapi_zombies_powers", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_zombies_powers_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_zombies_powers_dev							= AutoExecConfig_CreateConVar("drapi_active_zombies_powers_dev",							"0",		"Enable/Disable Dev Mod",				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	cvar_zombies_powers_damage								= AutoExecConfig_CreateConVar("drapi_zombies_powers_damage",								"5.0",		"Normal zombie damage",					DEFAULT_FLAGS);
	
	cvar_zombies_powers_spitter_distance					= AutoExecConfig_CreateConVar("drapi_zombies_powers_spitter_distance",						"100.0",	"Distance poison",						DEFAULT_FLAGS);
	cvar_zombies_powers_spitter_chance						= AutoExecConfig_CreateConVar("drapi_zombies_powers_spitter_chance",						"5",		"1 chance sur 3 to become poisoner",	DEFAULT_FLAGS);
	cvar_zombies_powers_spitter_speed						= AutoExecConfig_CreateConVar("drapi_zombies_powers_spitter_speed",							"345.0",	"Speed spitter",						DEFAULT_FLAGS);
	cvar_zombies_powers_spitter_health						= AutoExecConfig_CreateConVar("drapi_zombies_powers_spitter_health",						"50",		"Health spitter",						DEFAULT_FLAGS);
	cvar_zombies_powers_spitter_damage						= AutoExecConfig_CreateConVar("drapi_zombies_powers_spitter_damage",						"5.0",		"Damage spitter",						DEFAULT_FLAGS);
	cvar_zombies_powers_spitter_fadeout_max					= AutoExecConfig_CreateConVar("drapi_zombies_powers_spitter_fadeout_max",					"400.0",	"Fadeout max distance spitter",			DEFAULT_FLAGS);	
	
	cvar_zombies_powers_grabber_distance					= AutoExecConfig_CreateConVar("drapi_zombies_powers_grabber_distance",						"300.0",	"Distance grab",						DEFAULT_FLAGS);
	cvar_zombies_powers_grabber_chance						= AutoExecConfig_CreateConVar("drapi_zombies_powers_grabber_chance",						"10",		"1 chance sur 10 to become grabber",	DEFAULT_FLAGS);
	cvar_zombies_powers_grabber_speed						= AutoExecConfig_CreateConVar("drapi_zombies_powers_grabber_speed",							"315.0",	"Speed grabber",						DEFAULT_FLAGS);
	cvar_zombies_powers_grabber_health						= AutoExecConfig_CreateConVar("drapi_zombies_powers_grabber_health",						"250",		"Health grabber",						DEFAULT_FLAGS);
	cvar_zombies_powers_grabber_damage						= AutoExecConfig_CreateConVar("drapi_zombies_powers_grabber_damage",						"10.0",		"Damage grabber",						DEFAULT_FLAGS);
	cvar_zombies_powers_grabber_fadeout_max					= AutoExecConfig_CreateConVar("drapi_zombies_powers_grabber_fadeout_max",					"600.0",	"Fadeout max distance grabber",			DEFAULT_FLAGS);
	cvar_zombies_powers_grabber_min_heal_stop				= AutoExecConfig_CreateConVar("drapi_zombies_powers_grabber_min_heal_stop",					"10",		"Stop damage when player have 10HP",	DEFAULT_FLAGS);
	cvar_zombies_powers_grabber_damage_grabbing				= AutoExecConfig_CreateConVar("drapi_zombies_powers_grabber_damage_grabbing",				"2",		"Damage tongue",						DEFAULT_FLAGS);
	cvar_zombies_powers_grabber_damage_grabbing_repeat		= AutoExecConfig_CreateConVar("drapi_zombies_powers_grabber_damage_grabbing_repeat",		"4",		"Damage tongue each 4s",				DEFAULT_FLAGS);
	
	HookEvent("round_start",	Event_RoundStart);
	HookEvent("player_death",	Event_PlayerDeath);
	HookEvent("player_spawn", 	Event_PlayerSpawn);
	
	HookEvents();
	
	RegAdminCmd("sm_spit", 				Command_spit, 			ADMFLAG_CHANGEMAP, "Spit.");
	
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			ResetStates(i, false);
		}
		i++;
	}
	AutoExecConfig_ExecuteFile();
}

/***********************************************************/
/*********************** PLUGIN END **********************/
/***********************************************************/
public void OnPluginEnd()
{
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			ResetStates(i, false);
		}
		i++;
	}
}

/***********************************************************/
/**************** WHEN CLIENT PUT IN SERVER ****************/
/***********************************************************/
public void OnClientPutInServer(int client)
{
	if (IsClientInGame(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		ResetStates(client, false);
		
	}
}

/***********************************************************/
/***************** WHEN CLIENT DISCONNECT ******************/
/***********************************************************/
public void OnClientDisconnect(int client)
{	
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	ResetStates(client, false);
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEvents()
{
	HookConVarChange(cvar_active_zombies_powers_dev, 							Event_CvarChange);
	
	HookConVarChange(cvar_zombies_powers_damage, 								Event_CvarChange);
	
	HookConVarChange(cvar_zombies_powers_spitter_distance, 						Event_CvarChange);
	HookConVarChange(cvar_zombies_powers_spitter_chance, 						Event_CvarChange);
	HookConVarChange(cvar_zombies_powers_spitter_speed, 						Event_CvarChange);
	HookConVarChange(cvar_zombies_powers_spitter_health, 						Event_CvarChange);
	HookConVarChange(cvar_zombies_powers_spitter_damage, 						Event_CvarChange);
	HookConVarChange(cvar_zombies_powers_spitter_fadeout_max, 					Event_CvarChange);
	
	HookConVarChange(cvar_zombies_powers_grabber_distance, 						Event_CvarChange);
	HookConVarChange(cvar_zombies_powers_grabber_chance, 						Event_CvarChange);
	HookConVarChange(cvar_zombies_powers_grabber_speed, 						Event_CvarChange);
	HookConVarChange(cvar_zombies_powers_grabber_health, 						Event_CvarChange);
	HookConVarChange(cvar_zombies_powers_grabber_damage, 						Event_CvarChange);
	HookConVarChange(cvar_zombies_powers_grabber_fadeout_max, 					Event_CvarChange);
	HookConVarChange(cvar_zombies_powers_grabber_min_heal_stop, 				Event_CvarChange);
	HookConVarChange(cvar_zombies_powers_grabber_damage_grabbing, 				Event_CvarChange);
	HookConVarChange(cvar_zombies_powers_grabber_damage_grabbing_repeat, 		Event_CvarChange);
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
	B_active_zombies_powers_dev 						= GetConVarBool(cvar_active_zombies_powers_dev);
	
	F_zombies_powers_damage 							= GetConVarFloat(cvar_zombies_powers_damage);
	
	F_zombies_powers_spitter_distance 					= GetConVarFloat(cvar_zombies_powers_spitter_distance);
	H_zombies_powers_spitter_chance 					= GetConVarInt(cvar_zombies_powers_spitter_chance);
	F_zombies_powers_spitter_speed						= GetConVarFloat(cvar_zombies_powers_spitter_speed);
	H_zombies_powers_spitter_health						= GetConVarInt(cvar_zombies_powers_spitter_health);
	F_zombies_powers_spitter_damage						= GetConVarFloat(cvar_zombies_powers_spitter_damage);
	F_zombies_powers_spitter_fadeout_max				= GetConVarFloat(cvar_zombies_powers_spitter_fadeout_max);
	
	F_zombies_powers_grabber_distance 					= GetConVarFloat(cvar_zombies_powers_grabber_distance);
	H_zombies_powers_grabber_chance 					= GetConVarInt(cvar_zombies_powers_grabber_chance);
	F_zombies_powers_grabber_speed						= GetConVarFloat(cvar_zombies_powers_grabber_speed);
	H_zombies_powers_grabber_health						= GetConVarInt(cvar_zombies_powers_grabber_health);
	F_zombies_powers_grabber_damage						= GetConVarFloat(cvar_zombies_powers_grabber_damage);
	F_zombies_powers_grabber_fadeout_max				= GetConVarFloat(cvar_zombies_powers_grabber_fadeout_max);
	H_zombies_powers_grabber_min_heal_stop				= GetConVarInt(cvar_zombies_powers_grabber_min_heal_stop);
	H_zombies_powers_grabber_damage_grabbing			= GetConVarInt(cvar_zombies_powers_grabber_damage_grabbing);
	F_zombies_powers_grabber_damage_grabbing_repeat		= GetConVarFloat(cvar_zombies_powers_grabber_damage_grabbing_repeat);
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
	LoadDayData("configs/drapi/zombie_riot/days", "cfg");
	
	//POISON OVERLAY
	AddFileToDownloadsTable("materials/overlays/z4e/poison.vmt");
	AddFileToDownloadsTable("materials/overlays/z4e/poison.vtf");
	
	//WALKER
	AddFileToDownloadsTable("materials/models/player/kuristaja/walker/walker_body.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/walker/walker_body.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/walker/walker_body_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/walker/walker_eyes.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/walker/walker_eyes.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/walker/walker_face.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/walker/walker_face.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/walker/walker_face_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/walker/walker_lightwarp.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/walker/walker_lowerbody.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/walker/walker_lowerbody.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/walker/walker_lowerbody_normal.vtf");
	AddFileToDownloadsTable("models/player/kuristaja/walker/walker.dx90.vtx");
	AddFileToDownloadsTable("models/player/kuristaja/walker/walker.mdl");
	AddFileToDownloadsTable("models/player/kuristaja/walker/walker.phy");
	AddFileToDownloadsTable("models/player/kuristaja/walker/walker.vvd");
	PrecacheModel("models/player/kuristaja/walker/walker.mdl", true);

	//GRIM
	AddFileToDownloadsTable("materials/models/player/monster/grim/grim_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/monster/grim/grimbody.vmt");
	AddFileToDownloadsTable("materials/models/player/monster/grim/grimbody.vtf");
	AddFileToDownloadsTable("materials/models/player/monster/grim/mouth.vmt");
	AddFileToDownloadsTable("materials/models/player/monster/grim/mouth.vtf");
	AddFileToDownloadsTable("materials/models/player/monster/grim/mouth_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/monster/grim/skelface.vmt");
	AddFileToDownloadsTable("materials/models/player/monster/grim/skelface.vtf");
	AddFileToDownloadsTable("materials/models/player/monster/grim/skelface_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/monster/grim/skelface2.vmt");
	AddFileToDownloadsTable("materials/models/player/monster/grim/skelface2.vtf");
	AddFileToDownloadsTable("materials/models/player/monster/grim/skelface2_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/monster/grim/stimer.vmt");
	AddFileToDownloadsTable("materials/models/player/monster/grim/stimer.vtf");
	AddFileToDownloadsTable("models/player/monster/grim/grim.dx90.vtx");
	AddFileToDownloadsTable("models/player/monster/grim/grim.mdl");
	AddFileToDownloadsTable("models/player/monster/grim/grim.phy");
	AddFileToDownloadsTable("models/player/monster/grim/grim.vvd");
	PrecacheModel("models/player/monster/grim/grim.mdl", true);
	//SMOKER
	AddFileToDownloadsTable("particles/smoker_fx.pcf");
	PrecacheGeneric("particles/smoker_fx.pcf", true);
	/*Tongue*/
	PrecacheParticleEffect(particle_smoker_tongue);
	AddFileToDownloadsTable("materials/particle/smoker_tongue_beam.vmt");
	AddFileToDownloadsTable("materials/particle/smoker_tongue_beam.vtf");
	AddFileToDownloadsTable("materials/particle/spray1/spray1_streak.vmt");
	AddFileToDownloadsTable("materials/particle/spray1/spray1.vtf");
	AddFileToDownloadsTable("materials/particle/particle_spore/particle_spore.vmt");
	AddFileToDownloadsTable("materials/particle/particle_spore/particle_spore.vtf");
	AddFileToDownloadsTable("materials/cable/cablenormalmap.vtf");
	AddFileToDownloadsTable("particles/smoker_fx.pcf");
	/*Smoke cloud*/
	PrecacheParticleEffect(particle_smoker_cloud);
	AddFileToDownloadsTable("materials/particle/vistasmokev1/vistasmokev4_nearcull.vmt");
	AddFileToDownloadsTable("materials/particle/vistasmokev1/vistasmokev1.vtf");
	
	
	//BOOMER
	AddFileToDownloadsTable("particles/boomer_fx.pcf");
	PrecacheGeneric("particles/boomer_fx.pcf", true);
	/*Screen*/
	PrecacheParticleEffect(particle_boomer_screen);
	/*Vomit*/
	PrecacheParticleEffect(particle_boomer_vomit);
	AddFileToDownloadsTable("materials/particle/particle_glow_03_streak.vmt");
	AddFileToDownloadsTable("materials/particle/particle_glow_03.vtf");
	AddFileToDownloadsTable("materials/particle/particle_glow_01_streak.vmt");
	AddFileToDownloadsTable("materials/particle/particle_glow_01.vtf");
	AddFileToDownloadsTable("materials/particle/spray1/spray1.vmt");
	AddFileToDownloadsTable("materials/particle/spray1/spray1.vtf");
	AddFileToDownloadsTable("materials/particle/blood_core_streak.vmt");
	AddFileToDownloadsTable("materials/effects/blood_core.vtf");
	AddFileToDownloadsTable("materials/particle/water_splash/water_splash.vmt");
	AddFileToDownloadsTable("materials/particle/water_splash/water_splash.vtf");
	
	/*Explode*/
	PrecacheParticleEffect(particle_boomer_explode);
	AddFileToDownloadsTable("materials/particle/blood_mist/blood_mist.vmt");
	AddFileToDownloadsTable("materials/particle/blood_mist/blood_mist.vtf");

	AddFileToDownloadsTable("materials/particle/fire_particle_4/fire_particle_4.vmt");
	AddFileToDownloadsTable("materials/particle/fire_particle_4/fire_particle_4.vtf");

	AddFileToDownloadsTable("materials/particle/headshot/headshot.vmt");
	AddFileToDownloadsTable("materials/particle/headshot/headshot.vtf");

	AddFileToDownloadsTable("materials/particle/particle_debris_burst/particle_debris_burst_002.vmt");
	AddFileToDownloadsTable("materials/particle/particle_debris_burst/particle_debris_burst_002.vtf");

	AddFileToDownloadsTable("materials/particle/particle_flares/particle_flare_004.vmt");
	AddFileToDownloadsTable("materials/particle/particle_flares/particle_flare_004.vtf");
	AddFileToDownloadsTable("materials/particle/particle_flares/particle_flare_004_nodepth.vmt");

	AddFileToDownloadsTable("materials/particle/pebble1/particle_pebble_1.vmt");
	AddFileToDownloadsTable("materials/particle/pebble1/particle_pebble_1.vtf");

	AddFileToDownloadsTable("materials/particle/spray1/spray1.vmt");
	AddFileToDownloadsTable("materials/particle/spray1/spray1.vtf");

	AddFileToDownloadsTable("materials/particle/vistasmokev1/vistasmokev1.vmt");
	AddFileToDownloadsTable("materials/particle/vistasmokev1/vistasmokev1.vtf");
	
	FakeAndDownloadSound(false, S_sound_spit, 1);
	FakeAndDownloadSound(false, S_sound_spitter_explode, 1);
	FakeAndDownloadSound(false, S_sound_grab, 1);
	FakeAndDownloadSound(false, S_sound_grabber_explode, 1);
	
	
	AllowZombiesPowers();
	LoadSettings();
	UpdateState();
}

/***********************************************************/
/******************** WHEN ROUND START *********************/
/***********************************************************/
public void Event_RoundStart(Handle event, char[] name, bool dontBroadcast)
{
	ResetStatesAll(false);
	AllowZombiesPowers();
	TimeToRelease = false;
	CreateTimer(20.0, Timer_TimeToRelease);
}

/***********************************************************/
/******************* WHEN PLAYER SPAWN *********************/
/***********************************************************/
public void Event_PlayerSpawn(Handle event, char[] name, bool dontBroadcast)
{
	if(B_AllowZombiesPowers && TimeToRelease)
	{
		int client 				= GetClientOfUserId(GetEventInt(event, "userid"));
		ResetStates(client, false);
		if(Client_IsIngame(client))
		{
			if(IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_T)
			{
				C_ChanceSpitter[client] = GetRandomInt(1, GetDaySpitterChance(ZRiot_GetDay() - 1));
				if(C_ChanceSpitter[client] == 1)
				{
					CreateTimer(0.5, Timer_SetSkinToSpecialsZombiesSpitter, GetClientUserId(client));
					return;
				}
				
				
				C_ChanceGrabber[client] = GetRandomInt(1, GetDayGrabberChance(ZRiot_GetDay() - 1));
				if(C_ChanceGrabber[client] == 1)
				{
					CreateTimer(0.5, Timer_SetSkinToSpecialsZombiesGrabber, GetClientUserId(client));
					return;
				}
			}
		}
	}
}
/***********************************************************/
/******************** WHEN PLAYER DIE **********************/
/***********************************************************/
public void Event_PlayerDeath(Handle event, char[] name, bool dontBroadcast)
{	
	if(B_AllowZombiesPowers)
	{
		int victim 				= GetClientOfUserId(GetEventInt(event, "userid"));
		int attacker 			= GetClientOfUserId(GetEventInt(event, "attacker"));
		
		//if(!Client_IsValid(victim) || !Client_IsValid(attacker)) return;
		
		/*****SPITTER*****/
		if(VictimPoisoned[victim])
		{
			int attacker_poisoned;
			GetTrieValue(TrieVictimPoisoned[victim], "attacker", attacker_poisoned);
			ClearTrie(TrieVictimPoisoned[victim]);
			attacker_poisoned = GetClientOfUserId(attacker_poisoned);
			
			//Allow SPITER to spit
			AllowToSpit[attacker_poisoned] 		= true;
			AttackerPoisoned[attacker_poisoned] = false;
			//Victim die, so not longer poisoned
			VictimPoisoned[victim] 				= false;
			
			char attacker_poisoned_name[64];
			GetClientName(attacker_poisoned, attacker_poisoned_name, sizeof(attacker_poisoned_name));
			
			PrintToDev(B_active_zombies_powers_dev, "%s Attacker: %s, reset state", TAG_CHAT, attacker_poisoned_name);
			
		}
		else if(AllowToSpit[victim])
		{
			if(AttackerPoisoned[victim])
			{
				int victim_poisoned;
				GetTrieValue(TrieAttackerPoisoned[victim], "victim", victim_poisoned);
				ClearTrie(TrieAttackerPoisoned[victim]);
				victim_poisoned = GetClientOfUserId(victim_poisoned);
				
				//SPITER die, so reset state of poisoned
				VictimPoisoned[victim_poisoned] = false;
				DeleteOverlay(victim_poisoned);
				SetEffects(victim_poisoned, 255, 255, 255, 255, 1.0);
				
				char victim_poisoned_name[64];
				GetClientName(victim_poisoned, victim_poisoned_name, sizeof(victim_poisoned_name));
				
				PrintToDev(B_active_zombies_powers_dev, "%s Victim: %s, reset state", TAG_CHAT, victim_poisoned_name);
			}
			
			//SPITER die, so reset state of SPITER
			RadiusShake(victim, 100.0);
			SpitterExplode(victim, 10.0);
			AttackerPoisoned[victim] 		= false;
			AllowToSpit[victim] 			= false;
			C_ChanceSpitter[victim]			= 0;
			Spitter[victim]					= 0;
		}
		
		/*****GRABBER*****/
		//Victim is CT
		if(VictimGrabbed[victim])
		{
			int attacker_grabbed;
			GetTrieValue(TrieVictimGrabbed[victim], "attacker", attacker_grabbed);
			ClearTrie(TrieVictimGrabbed[victim]);
			attacker_grabbed = GetClientOfUserId(attacker_grabbed);
			
			//Allow GRABBER to re-grab
			AllowToGrab[attacker_grabbed]		= true;
			AttackerGrabbed[attacker_grabbed]	= false;
			SetEffects(attacker_grabbed, 255, 255, 255, 255, 1.0);
			
			//GRABBED die, so not longer grab
			VictimGrabbed[victim] 				= false;
			RemoveTongue(victim);
			
			char attacker_grabbed_name[64];
			GetClientName(attacker_grabbed, attacker_grabbed_name, sizeof(attacker_grabbed_name));
			
			PrintToDev(B_active_zombies_powers_dev, "%s Attacker: %s, reset state", TAG_CHAT, attacker_grabbed_name);
		}
		//Victim is Zombie
		else if(AllowToGrab[victim])
		{
			if(AttackerGrabbed[victim])
			{
				int victim_grabbed;
				GetTrieValue(TrieAttackerGrabbed[victim], "victim", victim_grabbed);
				ClearTrie(TrieAttackerGrabbed[victim]);
				victim_grabbed = GetClientOfUserId(victim_grabbed);
				
				
				VictimGrabbed[victim_grabbed] 	= false;
				RemoveTongue(victim_grabbed);
				SetEffects(victim_grabbed, 255, 255, 255, 255, 1.0);
				SetEntityGravity(victim_grabbed, 1.0);
				
				char victim_grabbed_name[64];
				GetClientName(victim_grabbed, victim_grabbed_name, sizeof(victim_grabbed_name));
				
				PrintToDev(B_active_zombies_powers_dev, "%s Victim: %s, reset state", TAG_CHAT, victim_grabbed_name);
			}
			
			//GRABBER die, reset state
			GrabberExplode(victim, 10.0);
			AttackerGrabbed[victim]			= false;
			AllowToGrab[victim] 			= false;
			C_ChanceGrabber[victim]			= 0;
			Grabber[victim]					= 0;
		}
	}
}

/***********************************************************/
/********************** ON GAME FRAME **********************/
/***********************************************************/
public void OnGameFrame()
{
	if(B_AllowZombiesPowers)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(Client_IsIngame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
			{
				if(Spitter[i] == GetClientUserId(i) && AllowToSpit[i] && !AttackerPoisoned[i])
				{
					SpitRange(GetClientUserId(i), GetDaySpitterDistance(ZRiot_GetDay() - 1));
				}
				else if(Grabber[i] == GetClientUserId(i) && AllowToGrab[i] && !AttackerGrabbed[i])
				{
					GrabRange(GetClientUserId(i), GetDayGrabberDistance(ZRiot_GetDay() - 1));
				}
				
			}
		}
	}
}

/***********************************************************/
/******************** ON TAKE DAMAGE ***********************/
/***********************************************************/
public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{

	if(B_AllowZombiesPowers)
	{
		if(Client_IsIngame(victim) && IsPlayerAlive(victim) && VictimPoisoned[victim] && GetClientTeam(victim) == CS_TEAM_CT)
		{
			if(Client_IsIngame(attacker) && IsPlayerAlive(attacker) && AllowToSpit[attacker])
			{

				if(F_speed > 0.15)
				{
					F_speed = F_speed - 0.15;
					SetPlayerSpeed(victim, F_speed * 300.0);
					
					//PrintToDev(B_active_zombies_powers_dev, "Speed: %f", F_speed);
				}
			}
		}
		
		if(Client_IsIngame(attacker) && IsPlayerAlive(attacker) && GetClientTeam(attacker) == CS_TEAM_T)
		{
			if(AllowToSpit[attacker])
			{
				damage = GetDaySpitterDamage(ZRiot_GetDay() - 1);
				return Plugin_Changed;
			}
			else if(AllowToGrab[attacker])
			{
				damage = GetDayGrabberDamage(ZRiot_GetDay() - 1);
				return Plugin_Changed;
			}
			else
			{
				damage = GetDayCommonDamage(ZRiot_GetDay() - 1);
				return Plugin_Changed;
			}	
		}
	}
	return Plugin_Continue;
}

/***********************************************************/
/********************** ON PRE THINK ***********************/
/***********************************************************/
public void OnPreThink(int attacker)
{
	if(AttackerGrabbed[attacker])
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(Client_IsIngame(i) && IsPlayerAlive(i))
			{
				//if(Grab_Attacker_Victim[attacker][i] == GetClientUserId(i))
				{	
					if(VictimGrabbed[i])
					{
						Grabbing(attacker, i);
					}
				}
			}
		}
	}
}

/***********************************************************/
/******************** ON PLAYER RUN CMD ********************/
/***********************************************************/
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(B_AllowZombiesPowers)
	{
		if(Client_IsIngame(client) && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_CT)
		{
			if(buttons & IN_JUMP && (VictimGrabbed[client] || VictimPoisoned[client]))
			{
				buttons &= ~IN_JUMP;
				return Plugin_Changed;
			}
			else if(buttons & IN_DUCK && (VictimGrabbed[client] || VictimPoisoned[client]))
			{
				buttons &= ~IN_DUCK;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

/***********************************************************/
/******************* TIMER TIME TO RELEASE******************/
/***********************************************************/
public Action Timer_TimeToRelease(Handle timer)
{
	TimeToRelease = true;
}

/***********************************************************/
/************************* CMD SPIT ************************/
/***********************************************************/
public Action Command_spit(int client, int args)
{
	RadiusShake(client, 400.0);
}

/***********************************************************/
/************************ RESET STATES *********************/
/***********************************************************/
void ResetStates(int client, bool trie)
{
	VictimPoisoned[client] 						= false;
	AttackerPoisoned[client] 					= false;
	C_PlayerPoison[client] 						= INVALID_ENT_REFERENCE;
	AllowToSpit[client]							= false;
	C_ChanceSpitter[client]						= 0;
	Spitter[client]								= 0;
	
	
	AllowToGrab[client]							= false;
	VictimGrabbed[client]						= false;
	AttackerGrabbed[client]						= false;
	VictimGrabbedTonguePartcile[client][0]		= INVALID_ENT_REFERENCE;
	VictimGrabbedTonguePartcile[client][1]		= INVALID_ENT_REFERENCE;
	C_ChanceGrabber[client]						= 0;
	Grabber[client]								= 0;
	
	C_LastButtons[client]						= 0;
	SetClientOverlay(client, "");
	
	if(trie)
	{
		ClearTrie(TrieVictimPoisoned[client]);
		ClearTrie(TrieAttackerPoisoned[client]);
		ClearTrie(TrieVictimGrabbed[client]);
		ClearTrie(TrieAttackerGrabbed[client]);
	}
}

/***********************************************************/
/********************* RESET STATES ALL ********************/
/***********************************************************/
void ResetStatesAll(bool trie)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(Client_IsIngame(i) && IsPlayerAlive(i))
		{
			ResetStates(i, trie);
		}
	}
}

/***********************************************************/
/********************* RESET STATES ALL ********************/
/***********************************************************/
stock bool AlreadyInfected(int client)
{
	if(VictimPoisoned[client])return true;
	if(VictimGrabbed[client])return true;
	return false;
}
/***********************************************************GRAB************************************************************/

/***********************************************************/
/*********************** GRAB RANGE ************************/
/***********************************************************/
public void GrabRange(int userid, float Distance)
{
	int attacker = GetClientOfUserId(userid);

	float vAngles[3], vOrigin[3], AnglesVec[3], EndPoint[3];

	GetClientEyeAngles(attacker,vAngles);
	GetClientEyePosition(attacker,vOrigin);

	GetAngleVectors(vAngles, AnglesVec, NULL_VECTOR, NULL_VECTOR);

	EndPoint[0] = vOrigin[0] + (AnglesVec[0]*Distance);
	EndPoint[1] = vOrigin[1] + (AnglesVec[1]*Distance);
	EndPoint[2] = vOrigin[2] + (AnglesVec[2]*Distance);

	Handle trace = TR_TraceRayFilterEx(vOrigin, EndPoint, MASK_SHOT, RayType_EndPoint, TraceEntityFilterPlayer, attacker);

	if (TR_DidHit(trace))
	{
		int victim = TR_GetEntityIndex(trace);

		if ((victim > 0) && (victim <= GetMaxClients()) && GetClientTeam(victim) == CS_TEAM_CT && !VictimGrabbed[victim])
		{
			char victim_name[64], attacker_name[64];
			GetClientName(victim, victim_name, sizeof(victim_name));
			GetClientName(attacker, attacker_name, sizeof(attacker_name));

			TrieVictimGrabbed[victim] 		= CreateTrie();
			TrieAttackerGrabbed[attacker] 	= CreateTrie();
			
			SetTrieValue(TrieVictimGrabbed[victim], 		"attacker", 	GetClientUserId(attacker));
			SetTrieValue(TrieAttackerGrabbed[attacker], 	"victim", 		GetClientUserId(victim));
			
			//Victim
			VictimGrabbed[victim] 					= true;
			SetEntityGravity(victim, 50.0);
			
			//Attacker
			AttackerGrabbed[attacker]				= true;
			SetEffects(attacker, 120, 48, 0, 255, 0.5);
			SetEntityGravity(victim, 50.0);
			Tongue(attacker, particle_smoker_tongue, victim);
			SDKHook(attacker, SDKHook_PreThink, OnPreThink);
			
			PrintToDev(B_active_zombies_powers_dev, "%sGrabbed: %s", TAG_CHAT, victim_name);
		}
	}
	CloseHandle(trace);
}

/***********************************************************/
/************************* GRABBING ************************/
/***********************************************************/
void Grabbing(int attacker, int victim)
{
	char victim_name[64], attacker_name[64];
	GetClientName(victim, victim_name, sizeof(victim_name));
	GetClientName(attacker, attacker_name, sizeof(attacker_name));

	float vecView[3], vecFwd[3], vecPos[3], vecVel[3];

	GetClientEyeAngles(attacker, vecView);
	GetAngleVectors(vecView, vecFwd, NULL_VECTOR, NULL_VECTOR);
	GetClientEyePosition(attacker, vecPos);

	vecPos[0]+=vecFwd[0]*20.0;
	vecPos[1]+=vecFwd[1]*20.0;
	vecPos[2]+=vecFwd[2]*20.0;

	GetClientAbsOrigin(victim, vecFwd);

	SubtractVectors(vecPos, vecFwd, vecVel);
	ScaleVector(vecVel, 1.0);

	TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vecVel);
	
	/*Some damage while wictim is grabbed*/
	float now = GetEngineTime();
	if(now >= F_last_time_damage_grabbed)
	{
		int victim_heal = GetClientHealth(victim);
		if(victim_heal > GetDayGrabberMinHealStop(ZRiot_GetDay() - 1)) 
		{
			char damage[12];
			IntToString(GetDayGrabberDamageGrabbing(ZRiot_GetDay() - 1), damage, sizeof(damage));
			SetDamage(victim, damage);
		}

		F_last_time_damage_grabbed = now + GetDayGrabberDamageGrabbingRepeat(ZRiot_GetDay() - 1);
		PrintToDev(B_active_zombies_powers_dev, "%s%s grabbing %s damaging: %f", TAG_CHAT, attacker_name, victim_name, GetDayGrabberDamageGrabbing(ZRiot_GetDay() - 1));
	}
}

/***********************************************************/
/********************** CREATE TONGUE **********************/
/***********************************************************/
void Tongue(int attacker, char[] particleType, int victim)
{
	int particle 	= -1; 
	int particle2 	= -1; 
	
	particle 		= CreateEntityByName("info_particle_system");
	particle2 		= CreateEntityByName("info_particle_system");
	
	if (IsValidEdict(particle))
	{ 
		//float pos[3]; 
		//GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", pos);
		//pos[2] = pos[2] + 63.0;  
		//TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);

		//GetEntPropVector(victim, Prop_Send, "m_vecOrigin", pos);
		//pos[2] = pos[2] + 60.0;  
		//TeleportEntity(particle2, pos, NULL_VECTOR, NULL_VECTOR);

		
		char attacker_name[128];
		Format(attacker_name, sizeof(attacker_name), "attacker%i%i", particle, attacker);
		DispatchKeyValue(attacker, "targetname", attacker_name);

		char victim_name[128];
		Format(victim_name, sizeof(victim_name), "victim%d", victim);
		DispatchKeyValue(victim, "targetname", victim_name);

		//--------------------------------------
		char tongue_victim_name[128];
		Format(tongue_victim_name, sizeof(tongue_victim_name), "victim_tongue%i%i", particle2, victim);

		DispatchKeyValue(particle2, "targetname", tongue_victim_name);
		DispatchKeyValue(particle2, "parentname", victim_name);

		SetVariantString(victim_name);
		AcceptEntityInput(particle2, "SetParent", victim, victim, 0);

		SetVariantString("muzzle_flash");
		AcceptEntityInput(particle2, "SetParentAttachment");
		
		//-----------------------------------------------

		char tongue_attacker_name[128];
		Format(tongue_attacker_name, sizeof(tongue_attacker_name), "attacker_tongue%d", attacker);
		
		DispatchKeyValue(particle, "targetname", tongue_attacker_name);
		DispatchKeyValue(particle, "parentname", attacker_name);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchKeyValue(particle, "cpoint1", tongue_victim_name);

		DispatchSpawn(particle);

		SetVariantString(attacker_name);
		AcceptEntityInput(particle, "SetParent", attacker, attacker, 0);

		SetVariantString("muzzle_flash");
		AcceptEntityInput(particle, "SetParentAttachment");

		//The particle is finally ready
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");

		VictimGrabbedTonguePartcile[victim][0] = EntIndexToEntRef(particle);
		VictimGrabbedTonguePartcile[victim][1] = EntIndexToEntRef(particle2);
		
		PlaySound(S_sound_grab[0], attacker, SNDCHAN_GRAB, 1.0);
		
		PrintToDev(B_active_zombies_powers_dev, "%sTongue: %i, %i", TAG_CHAT, VictimGrabbedTonguePartcile[victim][0], VictimGrabbedTonguePartcile[victim][1]);
	}
}

/***********************************************************/
/********************** REMOVE TONGUE **********************/
/***********************************************************/
void RemoveTongue(int victim)
{
	float Outside[3];
	Outside[0] = 20000.0;
	Outside[1] = 20000.0;
	Outside[2] = 20000.0;
	
	if(IsValidEntRef(VictimGrabbedTonguePartcile[victim][0]))
	{
		SetVariantString("");
		AcceptEntityInput(VictimGrabbedTonguePartcile[victim][0], "SetParent");
		
		TeleportEntity(VictimGrabbedTonguePartcile[victim][0], Outside, NULL_VECTOR, NULL_VECTOR);
		
		CreateTimer(0.1, Timer_RemoveTongue, VictimGrabbedTonguePartcile[victim][0]);

		PrintToDev(B_active_zombies_powers_dev, "%sRemove Tongue: %i", TAG_CHAT, VictimGrabbedTonguePartcile[victim][0]);
	}
	
	if(IsValidEntRef(VictimGrabbedTonguePartcile[victim][1]))
	{
		SetVariantString("");
		AcceptEntityInput(VictimGrabbedTonguePartcile[victim][1], "SetParent");
		
		TeleportEntity(VictimGrabbedTonguePartcile[victim][1], Outside, NULL_VECTOR, NULL_VECTOR);
		
		CreateTimer(0.1, Timer_RemoveTongue, VictimGrabbedTonguePartcile[victim][1]);
		
		PrintToDev(B_active_zombies_powers_dev, "%sRemove Tongue: %i", TAG_CHAT, VictimGrabbedTonguePartcile[victim][1]);
	}
}

/***********************************************************/
/******************** TIMER REMOVE TONGUE ******************/
/***********************************************************/
public Action Timer_RemoveTongue(Handle timer, any tongue)
{
		RemoveEntity(tongue);
}

/***********************************************************/
/********************* GRABBER EXPLODE *********************/
/***********************************************************/
void GrabberExplode(int client, float timer)
{
	float pos[3];
	pos[2] = pos[2] - 20;
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", pos);
	CreateParticle(client, particle_smoker_cloud, pos, NULL_VECTOR, timer);
	PlaySound(S_sound_grabber_explode[0], client, SNDCHAN_GRABBER_EXPLODE, 1.0);
}
/***********************************************************GRAB************************************************************/

/***********************************************************Spit***********************************************************/

/***********************************************************/
/******************* SET EFFECTS POISON ********************/
/***********************************************************/
void SetEffects(int client, int red, int green, int blue, int alpha, float movement)
{
	SetEntityRenderColor(client, red, green, blue, alpha);
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", movement);
	F_speed = movement;
}

/***********************************************************/
/******************* SET CORRECT Spit *********************/
/***********************************************************/
int SetCorrectspit(int client)
{
	int height;
	GetClientModel(client, S_model_client, PLATFORM_MAX_PATH);
	
	for (int i = 0; i < max_skins; i++)
	{
		if(StrEqual(S_model_client, S_skins[i], false))
		{
			height = StringToInt(S_skins_height[i]);
			return height;
		}
	}
	return 0;
}

/***********************************************************/
/*********************** SPIT RANGE ***********************/
/***********************************************************/
public void SpitRange(int userid, float Distance)
{
	int attacker = GetClientOfUserId(userid);

	float vAngles[3], vOrigin[3], AnglesVec[3], EndPoint[3];

	GetClientEyeAngles(attacker,vAngles);
	GetClientEyePosition(attacker,vOrigin);

	GetAngleVectors(vAngles, AnglesVec, NULL_VECTOR, NULL_VECTOR);

	EndPoint[0] = vOrigin[0] + (AnglesVec[0]*Distance);
	EndPoint[1] = vOrigin[1] + (AnglesVec[1]*Distance);
	EndPoint[2] = vOrigin[2] + (AnglesVec[2]*Distance);

	Handle trace = TR_TraceRayFilterEx(vOrigin, EndPoint, MASK_SHOT, RayType_EndPoint, TraceEntityFilterPlayer, attacker);

	if (TR_DidHit(trace))
	{
		int victim = TR_GetEntityIndex(trace);

		if ((victim > 0) && (victim <= GetMaxClients()) && GetClientTeam(victim) == CS_TEAM_CT && !VictimPoisoned[victim])
		{
			char victim_name[64], attacker_name[64];
			GetClientName(victim, victim_name, sizeof(victim_name));
			GetClientName(attacker, attacker_name, sizeof(attacker_name));
			
			TrieVictimPoisoned[victim] 		= CreateTrie();
			TrieAttackerPoisoned[attacker] 	= CreateTrie();
			
			SetTrieValue(TrieVictimPoisoned[victim], 		"attacker", 	GetClientUserId(attacker));
			SetTrieValue(TrieAttackerPoisoned[attacker], 	"victim", 		GetClientUserId(victim));
			
			//victim
			SetClientOverlay(victim, "overlays/z4e/poison");
			VictimPoisoned[victim]						= true;
			SetEffects(victim, 0, 255, 0, 255, 0.75);
			
			//Attacker
			AttackerPoisoned[attacker] 					= true;
			Spit(attacker);
			
			PrintToDev(B_active_zombies_powers_dev, "%s%s got poisoned by %s", TAG_CHAT, victim_name, attacker_name);
		}
	}
	CloseHandle(trace);
}

/***********************************************************/
/*********************** TRACE FILTER **********************/
/***********************************************************/
public bool TraceEntityFilterPlayer(int entity, int mask, any data)
{
	if (data != entity && (1 <= entity <= MaxClients))
	{
		return data != entity;
	}
	return false;
}

/***********************************************************/
/*************************** spit *************************/
/***********************************************************/
void Spit(int client)
{
	float vAngles[3];
	float vOrigin[3];

	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);

	CreatePoison(client, vOrigin, vAngles);
}

/***********************************************************/
/*********************** CREATE POISON *********************/
/***********************************************************/
void CreatePoison(int client, float origin[3], const float angles[3])
{
	if(SetCorrectspit(client))
	{
		origin[2] = origin[2] - SetCorrectspit(client);
	}
	
	char tName[128];
	Format(tName, sizeof(tName), "target%i", client);
	DispatchKeyValue(client, "targetname", tName);
		
	char poison_name[128];
	Format(poison_name, sizeof(poison_name), "poison%i", client);
	int poison = -1;

	poison = CreateEntityByName("info_particle_system");
	
	if(IsValidEntity(poison))
	{
		DispatchKeyValue(poison, "effect_name", particle_boomer_vomit);
		DispatchSpawn(poison);
		TeleportEntity(poison, origin, angles, NULL_VECTOR);
		SetVariantString(tName);
		AcceptEntityInput(poison, "SetParent", poison, poison, 0);
		ActivateEntity(poison);
		AcceptEntityInput(poison, "start");
		
		C_PlayerPoison[client] = EntIndexToEntRef(poison);
		PlaySound(S_sound_spit[0], client, SNDCHAN_SPIT, 1.0);
	}
}

/***********************************************************/
/********************** SPITTER EXPLODE ********************/
/***********************************************************/
void SpitterExplode(int client, float timer)
{
	float pos[3];
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", pos);
	CreateParticle(client, particle_boomer_explode, pos, NULL_VECTOR, timer);
	PlaySound(S_sound_spitter_explode[0], client, SNDCHAN_SPITTER_EXPLODE, 1.0);
	RemoveEntity(C_PlayerPoison[client]);
}

/***********************************************************Spit***********************************************************/

/***********************************************************/
/****************** TIMER CREATE SPITTER *******************/
/***********************************************************/
public Action Timer_SetSkinToSpecialsZombiesSpitter(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	
	if(Client_IsIngame(client) && IsPlayerAlive(client))
	{
		SetEntityModel(client, 		"models/player/kuristaja/walker/walker.mdl");
		SetPlayerSpeed(client, 		GetDaySpitterSpeed(ZRiot_GetDay() - 1)); 
		SetEntityHealth(client, 	GetDaySpitterHealth(ZRiot_GetDay() - 1));
		SetEntityRenderColor(client, 0, 255, 0, 255);
		SetPlayerMaxDist(client, 	GetDaySpitterFadeout(ZRiot_GetDay() - 1));
		NoCollide(client, 			true);
		AllowToSpit[client] 		= true;
		Spitter[client] 			= userid;
		
		ClearHPBar(client);
		SetHPBar(client, CS_TEAM_T, 100, GetDaySpitterHealth(ZRiot_GetDay() - 1));
	}
}

/***********************************************************/
/****************** TIMER CREATE GRABBER *******************/
/***********************************************************/
public Action Timer_SetSkinToSpecialsZombiesGrabber(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	
	if(Client_IsIngame(client) && IsPlayerAlive(client))
	{
		SetEntityModel(client, 		"models/player/monster/grim/grim.mdl");
		SetPlayerSpeed(client, 		GetDayGrabberSpeed(ZRiot_GetDay() - 1)); 
		SetEntityHealth(client, 	GetDayGrabberHealth(ZRiot_GetDay() - 1));
		SetPlayerMaxDist(client, 	GetDayGrabberFadeout(ZRiot_GetDay() - 1));
		NoCollide(client, 			true);
		AllowToGrab[client] 		= true;
		Grabber[client] 			= userid;
		
		ClearHPBar(client);
		SetHPBar(client, CS_TEAM_T, 100, GetDayGrabberHealth(ZRiot_GetDay() - 1));
	}
}

/***********************************************************/
/******************** CREATE PARTICLE **********************/
/***********************************************************/
void CreateParticle(int ent, char[] particleType, float Pos[3], float Ang[3], float time=10.0)
{
    int particle = CreateEntityByName("info_particle_system");
  
	
    if (IsValidEdict(particle))
    {
		char tName[128];

		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);

		
		TeleportEntity(particle, Pos, Ang, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		
		CreateTimer(time, Timer_DeleteParticle, particle);
    }
}

/***********************************************************/
/***************** TIMER REMOVE PARTICLE *******************/
/***********************************************************/
public Action Timer_DeleteParticle(Handle timer, any particle)
{
    if (IsValidEntity(particle))
    {
        char classname[128];
        GetEdictClassname(particle, classname, sizeof(classname));
        if (StrEqual(classname, "info_particle_system", false))
        {
            RemoveEdict(particle);
        }
    }
}

/***********************************************************/
/********************** SET DAMAGE *************************/
/***********************************************************/
void SetDamage(int client, char[] damage)
{
	int pointHurt = CreateEntityByName("point_hurt");		// Create point_hurt
	DispatchKeyValue(client, "targetname", "hurtme");		// mark client
	DispatchKeyValue(pointHurt, "Damage", damage);			// No Damage, just HUD display. Does stop Reviving though
	DispatchKeyValue(pointHurt, "DamageTarget", "hurtme");	// client Assignment
	DispatchKeyValue(pointHurt, "DamageType", "2");			// Type of damage
	DispatchSpawn(pointHurt);								// Spawn described point_hurt
	AcceptEntityInput(pointHurt, "Hurt");					// Trigger point_hurt execute
	AcceptEntityInput(pointHurt, "Kill");					// Remove point_hurt
	DispatchKeyValue(client, "targetname",    "cake");		// Clear client's mark
}

/***********************************************************/
/********************** SHAKE RADIUS ***********************/
/***********************************************************/
void RadiusShake(int client, float radius)
{
	float vec[3];
	GetClientAbsOrigin(client, vec);
	
	for (int i = 1; i <= MaxClients; ++i) 
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			float pos[3];
			GetClientAbsOrigin(i, pos);
			float distance = GetVectorDistance(vec, pos);
			
			if(distance <= radius)
			{
				float vector[3];
				GetClientEyePosition(i, pos);
				GetClientEyePosition(client, vec);
				
				MakeVectorFromPoints(pos, vec, vector);
				NormalizeVector(vector, vector);
				
				ScaleVector(vector, -400.0);
				TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, vector);	
				
				if(B_active_zombies_powers_dev)
				{
					char S_victim_name[MAX_NAME_LENGTH];
					GetClientName(i, S_victim_name, MAX_NAME_LENGTH);
				
					PrintToDev(B_active_zombies_powers_dev, "%s %s est dans votre champs et reçoit le shake", TAG_CHAT, S_victim_name);
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
/******************** ALLOW ZOMBIES POWERS *****************/
/***********************************************************/
void AllowZombiesPowers()
{
	if(ZRiot_GetDayMax() == ZRiot_GetDay())
	{
		B_AllowZombiesPowers = false;
	}
	else
	{
		B_AllowZombiesPowers = true;
	}
}

/***********************************************************/
/************************ PLAY SOUND ***********************/
/***********************************************************/
void PlaySound(char[] S_sound, int client, int SNDCHAN, float vol)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			EmitSoundToClientAny(i, S_sound, client, SNDCHAN, SNDLEVEL_TRAIN, _, vol, _);
			
			PrintToDev(B_active_zombies_powers_dev, "%s Sound: %s", TAG_CHAT, S_sound);
		}
	}
}
/***********************************************************/
/********************* LOAD FILE SETTING *******************/
/***********************************************************/
public void LoadSettings()
{
	char hc[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, hc, sizeof(hc), "configs/drapi/zombiespowers.cfg");
	
	Handle kv = CreateKeyValues("Skins");
	FileToKeyValues(kv, hc);
	
	max_skins = 0;
	
	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			if(KvGotoFirstSubKey(kv))
			{
				do
				{
					KvGetSectionName(kv, S_skins[max_skins], PLATFORM_MAX_PATH);
					//LogMessage("%s [%i]-Skins: %s", TAG_CHAT, max_skins, S_skins[max_skins]);
					
					KvGetString(kv, "height", S_skins_height[max_skins], PLATFORM_MAX_PATH);
					//LogMessage("%s [%i]-Height: %s", TAG_CHAT, max_skins, S_skins_height[max_skins]);
					
					max_skins++;
				}
				while (KvGotoNextKey(kv));
			}
			KvGoBack(kv);
		}
		while (KvGotoNextKey(kv));
	}
	CloseHandle(kv);
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
		data_zombies_powers_common_damage[INT_TOTAL_DAY] 									= KvGetFloat(kvDays, 		"common_damage", 					F_zombies_powers_damage);
		
		data_zombies_powers_spitter_chance[INT_TOTAL_DAY] 									= KvGetNum(kvDays, 			"spitter_chance", 					H_zombies_powers_spitter_chance);
		data_zombies_powers_spitter_health[INT_TOTAL_DAY] 									= KvGetNum(kvDays, 			"spitter_health", 					H_zombies_powers_spitter_health);
		data_zombies_powers_spitter_distance[INT_TOTAL_DAY] 								= KvGetFloat(kvDays, 		"spitter_distance", 				F_zombies_powers_spitter_distance);
		data_zombies_powers_spitter_speed[INT_TOTAL_DAY] 									= KvGetFloat(kvDays, 		"spitter_speed", 					F_zombies_powers_spitter_speed);
		data_zombies_powers_spitter_damage[INT_TOTAL_DAY] 									= KvGetFloat(kvDays, 		"spitter_damage", 					F_zombies_powers_spitter_damage);
		data_zombies_powers_spitter_fadeout_max[INT_TOTAL_DAY] 								= KvGetFloat(kvDays, 		"spitter_fadeout", 					F_zombies_powers_spitter_fadeout_max);
		
		data_zombies_powers_grabber_chance[INT_TOTAL_DAY] 									= KvGetNum(kvDays, 			"grabber_chance", 					H_zombies_powers_grabber_chance);
		data_zombies_powers_grabber_health[INT_TOTAL_DAY] 									= KvGetNum(kvDays, 			"grabber_health", 					H_zombies_powers_grabber_health);
		data_zombies_powers_grabber_distance[INT_TOTAL_DAY] 								= KvGetFloat(kvDays, 		"grabber_distance", 				F_zombies_powers_grabber_distance);
		data_zombies_powers_grabber_speed[INT_TOTAL_DAY] 									= KvGetFloat(kvDays, 		"grabber_speed", 					F_zombies_powers_grabber_speed);
		data_zombies_powers_grabber_damage[INT_TOTAL_DAY] 									= KvGetFloat(kvDays, 		"grabber_damage", 					F_zombies_powers_grabber_damage);
		data_zombies_powers_grabber_fadeout_max[INT_TOTAL_DAY] 								= KvGetFloat(kvDays, 		"grabber_fadeout", 					F_zombies_powers_grabber_fadeout_max);
		data_zombies_powers_grabber_min_heal_stop[INT_TOTAL_DAY] 							= KvGetNum(kvDays, 			"grabber_min_heal_stop", 			H_zombies_powers_grabber_min_heal_stop);
		data_zombies_powers_grabber_damage_grabbing[INT_TOTAL_DAY] 							= KvGetNum(kvDays, 			"grabber_damage_grabbing", 			H_zombies_powers_grabber_damage_grabbing);
		data_zombies_powers_grabber_damage_grabbing_repeat[INT_TOTAL_DAY] 					= KvGetFloat(kvDays, 		"grabber_damage_grabbing_repeat", 	F_zombies_powers_grabber_damage_grabbing_repeat);
		
		//LogMessage("%s [DAY%i] - Common damage: %f, Spitter Chance: %i, Grabber Chance: %i", TAG_CHAT, INT_TOTAL_DAY, data_zombies_powers_common_damage[INT_TOTAL_DAY], data_zombies_powers_spitter_chance[INT_TOTAL_DAY], data_zombies_powers_grabber_chance[INT_TOTAL_DAY]);
		
		INT_TOTAL_DAY++;
	} 
	while (KvGotoNextKey(kvDays));
}

/***********************************************************/
/******************* GET DAY COMMON DAMAGE *****************/
/***********************************************************/
float GetDayCommonDamage(int day)
{
    return data_zombies_powers_common_damage[day];
}

/***********************************************************/
/****************** GET DAY SPITTER CHANCE *****************/
/***********************************************************/
int GetDaySpitterChance(int day)
{
    return data_zombies_powers_spitter_chance[day];
}

/***********************************************************/
/****************** GET DAY SPITTER HEALTH *****************/
/***********************************************************/
int GetDaySpitterHealth(int day)
{
    return data_zombies_powers_spitter_health[day];
}

/***********************************************************/
/***************** GET DAY SPITTER DISTANCE ****************/
/***********************************************************/
float GetDaySpitterDistance(int day)
{
    return data_zombies_powers_spitter_distance[day];
}

/***********************************************************/
/******************* GET DAY SPITTER SPEED *****************/
/***********************************************************/
float GetDaySpitterSpeed(int day)
{
    return data_zombies_powers_spitter_speed[day];
}

/***********************************************************/
/****************** GET DAY SPITTER DAMAGE *****************/
/***********************************************************/
float GetDaySpitterDamage(int day)
{
    return data_zombies_powers_spitter_damage[day];
}

/***********************************************************/
/***************** GET DAY SPITTER FADEOUT *****************/
/***********************************************************/
float GetDaySpitterFadeout(int day)
{
    return data_zombies_powers_spitter_fadeout_max[day];
}

/***********************************************************/
/****************** GET DAY GRABBER CHANCE *****************/
/***********************************************************/
int GetDayGrabberChance(int day)
{
    return data_zombies_powers_grabber_chance[day];
}

/***********************************************************/
/****************** GET DAY GRABBER HEALTH *****************/
/***********************************************************/
int GetDayGrabberHealth(int day)
{
    return data_zombies_powers_grabber_health[day];
}

/***********************************************************/
/***************** GET DAY GRABBER DISTANCE ****************/
/***********************************************************/
float GetDayGrabberDistance(int day)
{
    return data_zombies_powers_grabber_distance[day];
}

/***********************************************************/
/******************* GET DAY GRABBER SPEED *****************/
/***********************************************************/
float GetDayGrabberSpeed(int day)
{
    return data_zombies_powers_grabber_speed[day];
}

/***********************************************************/
/****************** GET DAY GRABBER DAMAGE *****************/
/***********************************************************/
float GetDayGrabberDamage(int day)
{
    return data_zombies_powers_grabber_damage[day];
}

/***********************************************************/
/***************** GET DAY GRABBER FADEOUT *****************/
/***********************************************************/
float GetDayGrabberFadeout(int day)
{
    return data_zombies_powers_grabber_fadeout_max[day];
}

/***********************************************************/
/************** GET DAY GRABBER MIN HEAL STOP **************/
/***********************************************************/
int GetDayGrabberMinHealStop(int day)
{
    return data_zombies_powers_grabber_min_heal_stop[day];
}

/***********************************************************/
/************* GET DAY GRABBER DAMAGE GRABBING *************/
/***********************************************************/
int GetDayGrabberDamageGrabbing(int day)
{
    return data_zombies_powers_grabber_damage_grabbing[day];
}

/***********************************************************/
/********** GET DAY GRABBER DAMAGE GRABBING REPEAT *********/
/***********************************************************/
float GetDayGrabberDamageGrabbingRepeat(int day)
{
    return data_zombies_powers_grabber_damage_grabbing_repeat[day];
}