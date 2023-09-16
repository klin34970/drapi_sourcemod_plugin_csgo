/*    <DR.API HULK> (c) by <De Battista Clint - (http://doyou.watch)         */
/*                                                                           */
/*                       <DR.API HULK> is licensed under a                   */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//******************************DR.API HULK**********************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[HULK] -"

#define DMG_KNIFE     					( DMG_NEVERGIB | DMG_BULLET )
#define DMG_BURN                		(1 << 3)

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <stocks>
#include <drapi_zombie_riot>

//***********************************//
//***********PARAMETERS**************//
//***********************************//
//Enums
enum Slots
{
	SlotPrimary,
	SlotSecondary,
	SlotKnife,
	SlotGrenade,
	SlotC4,
	SlotNone
};

//Handle
new Handle:cvar_active_hulk_dev;

new Handle:cvar_shake_amplitude;
new Handle:cvar_shake_frequency;

new Handle:cvar_timer_state_idle_attack;
new Handle:cvar_timer_state_run_attack;
new Handle:cvar_timer_state_run;
new Handle:cvar_timer_state_back;
new Handle:cvar_timer_state_right;
new Handle:cvar_timer_state_left;

new Handle:cvar_timer_shake_idle_attack;
new Handle:cvar_timer_shake_run_attack;
new Handle:cvar_timer_shake_run;
new Handle:cvar_timer_shake_runx2;

new Handle:cvar_timer_sound_run_attack;
new Handle:cvar_timer_sound_idle_attack;

new Handle:cvar_hulk_heal;
new Handle:cvar_hulk_fadeout;

new Handle:cvar_hulk_power_random;

new Handle:cvar_hulk_power_1;
new Handle:cvar_hulk_power_2;
new Handle:cvar_hulk_power_3;
new Handle:cvar_hulk_power_4;
new Handle:cvar_hulk_power_5;
new Handle:cvar_hulk_power_6;
new Handle:cvar_hulk_power_7;
new Handle:cvar_hulk_power_8;
new Handle:cvar_hulk_power_9;
new Handle:cvar_hulk_power_10;

new Handle:cvar_hulk_power_1_time_out;
new Handle:cvar_hulk_power_2_time_out;
new Handle:cvar_hulk_power_3_time_out;
new Handle:cvar_hulk_power_4_time_out;
new Handle:cvar_hulk_power_5_time_out;
new Handle:cvar_hulk_power_6_time_out;
new Handle:cvar_hulk_power_7_time_out;
new Handle:cvar_hulk_power_8_time_out;
new Handle:cvar_hulk_power_9_time_out;
new Handle:cvar_hulk_power_10_time_out;

new Handle:cvar_hulk_power_6_radius;
new Handle:cvar_hulk_power_6_push;

new Handle:cvar_hulk_power_8_radius;
new Handle:cvar_hulk_power_8_push;

new Handle:cvar_hulk_power_9_interval;
new Handle:cvar_hulk_power_9_heal;

new Handle:cvar_hulk_teleport_running_radius;
new Handle:cvar_hulk_teleport_running_timer;
new Handle:cvar_hulk_teleport_running_timer_min;
new Handle:cvar_hulk_teleport_running_timer_max;

new Handle:cvar_hulk_swallow_projectile_radius;
new Handle:cvar_hulk_swallow_projectile_heal;

new Handle:cvar_hulk_speed_normal;
new Handle:cvar_hulk_speed_normal_bot;
new Handle:cvar_hulk_speed_faster;

new Handle:cvar_max_player_boss;

new Handle:TimersResetState[MAXPLAYERS+1] 		= INVALID_HANDLE;
new Handle:TimersShake[MAXPLAYERS+1] 			= INVALID_HANDLE;
new Handle:TimersShakeRepeat[MAXPLAYERS+1] 		= INVALID_HANDLE;
new Handle:TimersSound[MAXPLAYERS+1] 			= INVALID_HANDLE;
new Handle:TimersPowersHulkStep[MAXPLAYERS+1] 	= INVALID_HANDLE;
new Handle:TimerHulkAttrack[MAXPLAYERS + 1]		= INVALID_HANDLE;

//Bools
new bool:B_active_hulk_dev 						= false;
new bool:PlayerIsAttacking[MAXPLAYERS+1] 		= false;
new bool:PlayerIsHulk[MAXPLAYERS+1] 			= false;

new bool:B_hulk_power_random;

new bool:B_hulk_power_1;
new bool:B_hulk_power_2;
new bool:B_hulk_power_3;
new bool:B_hulk_power_4;
new bool:B_hulk_power_5;
new bool:B_hulk_power_6;
new bool:B_hulk_power_7;
new bool:B_hulk_power_8;
new bool:B_hulk_power_9;
new bool:B_hulk_power_10;

new bool:HulkShield[MAXPLAYERS + 1];
new bool:HulkRage[MAXPLAYERS + 1];
new bool:HulkInvisible[MAXPLAYERS + 1];

new bool:CanWinParty							= true;

//Floats
new Float:F_shake_amplitude;
new Float:F_shake_frequency;

new Float:F_timer_state_idle_attack;
new Float:F_timer_state_run_attack;
new Float:F_timer_state_run;
new Float:F_timer_state_back;
new Float:F_timer_state_right;
new Float:F_timer_state_left;

new Float:F_timer_shake_idle_attack;
new Float:F_timer_shake_run_attack;
new Float:F_timer_shake_run;
new Float:F_timer_shake_runx2;

new Float:F_timer_sound_run_attack;
new Float:F_timer_sound_idle_attack;

new Float:F_hulk_power_1_time_out;
new Float:F_hulk_power_2_time_out;
new Float:F_hulk_power_3_time_out;
new Float:F_hulk_power_4_time_out;
new Float:F_hulk_power_5_time_out;
new Float:F_hulk_power_6_time_out;
new Float:F_hulk_power_7_time_out;
new Float:F_hulk_power_8_time_out;
new Float:F_hulk_power_9_time_out;
new Float:F_hulk_power_10_time_out;

new Float:F_hulk_power_6_radius;
new Float:F_hulk_power_6_push;

new Float:F_hulk_power_8_radius;
new Float:F_hulk_power_8_push;

new Float:F_hulk_power_9_interval;

new Float:F_hulk_teleport_running_radius;
new Float:F_hulk_teleport_running_timer;
new Float:F_hulk_teleport_running_timer_min;
new Float:F_hulk_teleport_running_timer_max;

new Float:F_hulk_swallow_projectile_radius;

new Float:F_hulk_speed_normal;
new Float:F_hulk_speed_normal_bot;
new Float:F_hulk_speed_faster;



new Float:TimerHurt[MAXPLAYERS+1];
new Float:TimerPower[MAXPLAYERS+1];
new Float:TimerJump[MAXPLAYERS+1];
new Float:TimerSpawn[MAXPLAYERS+1];
new Float:TimerRun[MAXPLAYERS+1];
new Float:TimerRunTeleport[MAXPLAYERS+1];
float TimerKnife[MAXPLAYERS + 1];


//Customs
new C_iClone[MAXPLAYERS+1];
new C_iCloneState[MAXPLAYERS+1];
new C_health[MAXPLAYERS + 1];
new LifeHulk[MAXPLAYERS + 1];
new TotalLifeHulk[MAXPLAYERS + 1];
new PowersHulkStep[MAXPLAYERS + 1];
new PowersHulkStepDone[MAXPLAYERS + 1];
new HulkHaveShield[MAXPLAYERS + 1];
new HulkHeal[MAXPLAYERS + 1];

new C_hulk_heal;
new C_hulk_fadeout;

new C_hulk_swallow_projectile_heal;
new C_hulk_power_9_heal;
new C_max_player_boss;

new C_become_hulk[MAXPLAYERS+1]		= false;

//Sounds
static const String:S_hulk_noise_sound[4][PLATFORM_MAX_PATH] 					= {
																				"hulk/fall/tank_death_bodyfall_01.mp3",
																				"hulk/hit/hulk_punch_1.mp3",
																				"hulk/hit/pound_victim_1.mp3",
																				"hulk/hit/pound_victim_2.mp3"
																				};
																				
static const String:S_hulk_voice_attack_sound[10][PLATFORM_MAX_PATH] 			= {
																				"hulk/voice/attack/tank_attack_01.mp3",
																				"hulk/voice/attack/tank_attack_02.mp3",
																				"hulk/voice/attack/tank_attack_03.mp3",
																				"hulk/voice/attack/tank_attack_04.mp3",
																				"hulk/voice/attack/tank_attack_05.mp3",
																				"hulk/voice/attack/tank_attack_06.mp3",
																				"hulk/voice/attack/tank_attack_07.mp3",
																				"hulk/voice/attack/tank_attack_08.mp3",
																				"hulk/voice/attack/tank_attack_09.mp3",
																				"hulk/voice/attack/tank_attack_10.mp3"
																				};
																				
static const String:S_hulk_voice_death_sound[7][PLATFORM_MAX_PATH] 				= {
																				"hulk/voice/die/tank_death_01.mp3",
																				"hulk/voice/die/tank_death_02.mp3",
																				"hulk/voice/die/tank_death_03.mp3",
																				"hulk/voice/die/tank_death_04.mp3",
																				"hulk/voice/die/tank_death_05.mp3",
																				"hulk/voice/die/tank_death_06.mp3",
																				"hulk/voice/die/tank_death_07.mp3"
																				};
																				
static const String:S_hulk_voice_die_sound[7][PLATFORM_MAX_PATH] 				= {
																				"hulk/voice/die/tank_death_01.mp3",
																				"hulk/voice/die/tank_death_02.mp3",
																				"hulk/voice/die/tank_death_03.mp3",
																				"hulk/voice/die/tank_death_04.mp3",
																				"hulk/voice/die/tank_death_05.mp3",
																				"hulk/voice/die/tank_death_06.mp3",
																				"hulk/voice/die/tank_death_07.mp3"
																				};
																				
static const String:S_hulk_voice_pain_sound[18][PLATFORM_MAX_PATH] 				= {
																				"hulk/voice/pain/tank_fire_01.mp3",
																				"hulk/voice/pain/tank_fire_02.mp3",
																				"hulk/voice/pain/tank_fire_03.mp3",
																				"hulk/voice/pain/tank_fire_04.mp3",
																				"hulk/voice/pain/tank_fire_05.mp3",
																				"hulk/voice/pain/tank_fire_06.mp3",
																				"hulk/voice/pain/tank_fire_07.mp3",
																				"hulk/voice/pain/tank_fire_08.mp3",
																				"hulk/voice/pain/tank_pain_01.mp3",
																				"hulk/voice/pain/tank_pain_02.mp3",
																				"hulk/voice/pain/tank_pain_03.mp3",
																				"hulk/voice/pain/tank_pain_04.mp3",
																				"hulk/voice/pain/tank_pain_05.mp3",
																				"hulk/voice/pain/tank_pain_06.mp3",
																				"hulk/voice/pain/tank_pain_07.mp3",
																				"hulk/voice/pain/tank_pain_08.mp3",
																				"hulk/voice/pain/tank_pain_09.mp3",
																				"hulk/voice/pain/tank_pain_10.mp3"
																				};
																				
static const String:S_hulk_voice_yell_sound[12][PLATFORM_MAX_PATH] 				= {
																				"hulk/voice/yell/tank_yell_01.mp3",
																				"hulk/voice/yell/tank_yell_02.mp3",
																				"hulk/voice/yell/tank_yell_03.mp3",
																				"hulk/voice/yell/tank_yell_04.mp3",
																				"hulk/voice/yell/tank_yell_05.mp3",
																				"hulk/voice/yell/tank_yell_06.mp3",
																				"hulk/voice/yell/tank_yell_07.mp3",
																				"hulk/voice/yell/tank_yell_08.mp3",
																				"hulk/voice/yell/tank_yell_09.mp3",
																				"hulk/voice/yell/tank_yell_10.mp3",
																				"hulk/voice/yell/tank_yell_12.mp3",
																				"hulk/voice/yell/tank_yell_16.mp3"
																				};
																				
//Informations plugin
public Plugin:myinfo =
{
	name = "DR.API HULK",
	author = "Dr. Api",
	description = "DR.API HULK by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://doyou.watch"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public OnPluginStart()
{
	LoadTranslations("drapi/drapi_hulk.phrases");
	
	FindOffsets();
	CreateConVar("drapi_hulk_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_hulk_dev					= CreateConVar("drapi_hulk_active_dev", 					"0", 		"Enable/Disable HULK Dev Mod",					DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	cvar_max_player_boss					= CreateConVar("drapi_max_player_boss", 					"6", 		"Max player for boss being player",				DEFAULT_FLAGS);
	
	cvar_shake_amplitude					= CreateConVar("drapi_hulk_shake_amplitude", 				"10", 		"Amplitude of Shake",							DEFAULT_FLAGS);
	cvar_shake_frequency					= CreateConVar("drapi_hulk_shake_frequency", 				"10", 		"Frequency of Shake",							DEFAULT_FLAGS);
	
	cvar_timer_state_idle_attack			= CreateConVar("drapi_hulk_timer_state_idle_attack", 		"1.0", 		"Animation idle+attack",						DEFAULT_FLAGS);
	cvar_timer_state_run_attack				= CreateConVar("drapi_hulk_timer_state_run_attack", 		"1.0", 		"Animation run+attack",							DEFAULT_FLAGS);
	cvar_timer_state_run					= CreateConVar("drapi_hulk_timer_state_run", 				"1.68", 	"Animation run",								DEFAULT_FLAGS);
	cvar_timer_state_back					= CreateConVar("drapi_hulk_timer_state_back", 				"1.36", 	"Animation Back",								DEFAULT_FLAGS);
	cvar_timer_state_right					= CreateConVar("drapi_hulk_timer_state_right", 				"2.5", 		"Animation Right",								DEFAULT_FLAGS);
	cvar_timer_state_left					= CreateConVar("drapi_hulk_timer_state_left", 				"2.5", 		"Animation Left",								DEFAULT_FLAGS);
	
	cvar_timer_shake_idle_attack			= CreateConVar("drapi_hulk_timer_shake_idle_attack", 		"0.6", 		"Shake sync with animation idle+attack",		DEFAULT_FLAGS);
	cvar_timer_shake_run_attack				= CreateConVar("drapi_hulk_timer_shake_run_attack", 		"0.66", 	"Shake sync with animation run+attack",			DEFAULT_FLAGS);
	cvar_timer_shake_run					= CreateConVar("drapi_hulk_timer_shake_run", 				"0.53", 	"Shake sync with animation run",				DEFAULT_FLAGS);
	cvar_timer_shake_runx2					= CreateConVar("drapi_hulk_timer_shake_runx2", 				"1.06", 	"Shake sync with animation runx2",				DEFAULT_FLAGS);
	
	cvar_timer_sound_run_attack				= CreateConVar("drapi_hulk_timer_sound_run_attack", 		"0.53", 	"Sound sync with animation run+attacke",		DEFAULT_FLAGS);
	cvar_timer_sound_idle_attack			= CreateConVar("drapi_hulk_timer_sound_idle_attack", 		"0.53", 	"Sound sync with animation idle+attack",		DEFAULT_FLAGS);
	
	cvar_hulk_heal 							= CreateConVar("drapi_hulk_heal", 							"10000", 	"Life of HULK per players anytime", 			DEFAULT_FLAGS);
	cvar_hulk_fadeout 						= CreateConVar("drapi_hulk_fadeout", 						"1000", 	"Model fade out distance max", 					DEFAULT_FLAGS);
	
	
	cvar_hulk_power_random					= CreateConVar("drapi_hulk_power_random", 					"0", 		"0 = HP, 1 = RAMDOM",							DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	cvar_hulk_teleport_running_radius		= CreateConVar("drapi_hulk_teleport_running_radius", 		"10.0", 	"Teleportation radius",							DEFAULT_FLAGS);
	cvar_hulk_teleport_running_timer		= CreateConVar("drapi_hulk_teleport_running_timer", 		"1.0", 		"Teleportation timer",							DEFAULT_FLAGS);
	cvar_hulk_teleport_running_timer_min	= CreateConVar("drapi_hulk_teleport_running_timer_min", 	"5.0", 		"Teleportation timer min",						DEFAULT_FLAGS);
	cvar_hulk_teleport_running_timer_max	= CreateConVar("drapi_hulk_teleport_running_timer_max", 	"15.0", 	"Teleportation timer max",						DEFAULT_FLAGS);
	
	cvar_hulk_swallow_projectile_radius		= CreateConVar("drapi_hulk_swallow_projectile_radius", 		"800.0", 	"Swallow projectile radius",					DEFAULT_FLAGS);
	cvar_hulk_swallow_projectile_heal		= CreateConVar("drapi_hulk_swallow_projectile_heal", 		"500", 		"Swallow projectile heal/players",				DEFAULT_FLAGS);
	
	//POWER1
	cvar_hulk_power_1						= CreateConVar("drapi_hulk_power_1", 						"1", 		"Enable/Disable Power 1",						DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	cvar_hulk_power_1_time_out				= CreateConVar("drapi_hulk_power_1_time_out", 				"10.0", 	"Loose power time",								DEFAULT_FLAGS);
	
	//POWER2
	cvar_hulk_power_2						= CreateConVar("drapi_hulk_power_2", 						"1", 		"Enable/Disable Power 2",						DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	cvar_hulk_power_2_time_out				= CreateConVar("drapi_hulk_power_2_time_out", 				"10.0", 	"Loose power time",								DEFAULT_FLAGS);
	
	//POWER3
	cvar_hulk_power_3						= CreateConVar("drapi_hulk_power_3", 						"1", 		"Enable/Disable Power 3",						DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	cvar_hulk_power_3_time_out				= CreateConVar("drapi_hulk_power_3_time_out", 				"10.0",		"Loose power time",								DEFAULT_FLAGS);
		
	//POWER4 INVISIBLE
	cvar_hulk_power_4						= CreateConVar("drapi_hulk_power_4", 						"1", 		"Enable/Disable INVISIBLE",						DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	cvar_hulk_power_4_time_out				= CreateConVar("drapi_hulk_power_4_time_out", 				"10.0", 	"Loose power time",								DEFAULT_FLAGS);
	
	//POWER5
	cvar_hulk_power_5						= CreateConVar("drapi_hulk_power_5", 						"1", 		"Enable/Disable Power 5",						DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	cvar_hulk_power_5_time_out				= CreateConVar("drapi_hulk_power_5_time_out", 				"10.0", 	"Loose power time",								DEFAULT_FLAGS);
	
	//POWER6 SHIELD
	cvar_hulk_power_6						= CreateConVar("drapi_hulk_power_6", 						"1", 		"Enable/Disable SHIELD",						DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	cvar_hulk_power_6_time_out				= CreateConVar("drapi_hulk_power_6_time_out", 				"10.0",		"Loose power time",								DEFAULT_FLAGS);
	cvar_hulk_power_6_radius				= CreateConVar("drapi_hulk_power_6_radius", 				"50.0", 	"Radius",										DEFAULT_FLAGS);
	cvar_hulk_power_6_push					= CreateConVar("drapi_hulk_power_6_push", 					"-200.0",	"Push",											DEFAULT_FLAGS);
	
	//POWER7
	cvar_hulk_power_7						= CreateConVar("drapi_hulk_power_7", 						"1", 		"Enable/Disable Power 7",						DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	cvar_hulk_power_7_time_out				= CreateConVar("drapi_hulk_power_7_time_out", 				"10.0", 	"Loose power time",								DEFAULT_FLAGS);
	
	//POWER8 RAGE
	cvar_hulk_power_8						= CreateConVar("drapi_hulk_power_8", 						"1", 		"Enable/Disable RAGE",							DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	cvar_hulk_power_8_time_out				= CreateConVar("drapi_hulk_power_8_time_out", 				"10.0", 	"Loose power time",								DEFAULT_FLAGS);
	cvar_hulk_power_8_radius				= CreateConVar("drapi_hulk_power_8_radius", 				"300.0", 	"Radius",										DEFAULT_FLAGS);
	cvar_hulk_power_8_push					= CreateConVar("drapi_hulk_power_8_push", 					"300.0",	"Push",											DEFAULT_FLAGS);
	cvar_hulk_speed_normal					= CreateConVar("drapi_hulk_speed_normal", 					"300.0",	"Velocity normal",								DEFAULT_FLAGS);
	cvar_hulk_speed_normal_bot				= CreateConVar("drapi_hulk_speed_normal_bot", 				"380.0",	"Velocity normal bot",							DEFAULT_FLAGS);
	cvar_hulk_speed_faster					= CreateConVar("drapi_hulk_speed_faster", 					"400.0",	"Velocity mode rage",							DEFAULT_FLAGS);
	
	//POWER9 HEAL
	cvar_hulk_power_9						= CreateConVar("drapi_hulk_power_9", 						"1", 		"Enable/Disable HEAL",							DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	cvar_hulk_power_9_time_out				= CreateConVar("drapi_hulk_power_9_time_out", 				"10.0", 	"Loose power time",								DEFAULT_FLAGS);
	cvar_hulk_power_9_interval				= CreateConVar("drapi_hulk_power_9_interval", 				"2.0", 		"Heal/seconde",									DEFAULT_FLAGS);
	cvar_hulk_power_9_heal					= CreateConVar("drapi_hulk_power_9_heal", 					"70.0", 	"Heal",											DEFAULT_FLAGS);
	
	//POWER10
	cvar_hulk_power_10						= CreateConVar("drapi_hulk_power_10", 						"1", 		"Enable/Disable Power 10",						DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	cvar_hulk_power_10_time_out				= CreateConVar("drapi_hulk_power_10_time_out", 				"10.0", 	"Loose power time",								DEFAULT_FLAGS);
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_jump", Event_PlayerJump);
	HookEvent("player_footstep", Event_PlayerFootStep);
	
	
	HookEvents();
	
	RegAdminCmd("sm_hulk", Command_Hulk, ADMFLAG_CHANGEMAP, "");
	RegAdminCmd("sm_shield", Command_Shield, ADMFLAG_CHANGEMAP, "");
	RegAdminCmd("sm_push", Command_Push, ADMFLAG_CHANGEMAP, "");
	RegAdminCmd("sm_telep", Command_Teleport, ADMFLAG_CHANGEMAP, "");
	RegAdminCmd("sm_dmg", Command_Damage, ADMFLAG_CHANGEMAP, "");
	
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			ResetAll(i, true);
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKHook(i, SDKHook_WeaponCanUse, OnWeaponCanUse); 
		}
		i++;
	}
	
	//AutoExecConfig(true, "drapi_hulk", "Z4E");
}

/********************* DELETE THIS AFTER *********************/
public Action:Command_Hulk(client, args)
{
	if(IsValidEntRef(C_iClone[client]))
	{
		ClearHulk(client);
	}
	else
	{
		CreateHulk(client);
	}
	return Plugin_Handled;
}

public Action:Command_Shield(client, args)
{
	if(HulkShield[client])
	{
		ShieldHulk(client, true);
	}
	else
	{
		ShieldHulk(client, false);
	}
	return Plugin_Handled;
}

public Action:Command_Push(client, args)
{
	new Handle:kv = CreateKeyValues("ShieldAttrack");
	KvSetNum(kv, "client", client);
	KvSetNum(kv, "teleportself", args);
	KvSetFloat(kv, "radius", 300.0);
	KvSetFloat(kv, "push", -300.0);
		
	CreateTimer(8.0, Timer_DeleteAttrack, client, TIMER_FLAG_NO_MAPCHANGE);
	TimerHulkAttrack[client] = CreateTimer(0.1, Timer_Attrack, kv, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	
	return Plugin_Handled;
}
public Action:Command_Teleport(client, args)
{
	TeleportHulk(client, 300.0);
	
	return Plugin_Handled;
}

public Action:Command_Damage(client, args)
{
	SetDamage(client, "100");
	
	return Plugin_Handled;
}
/********************* DELETE THIS AFTER *********************/


/***********************************************************/
/************************ PLUGIN END ***********************/
/***********************************************************/
public OnPluginEnd()
{
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			ResetAll(i, true);
			SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKUnhook(i, SDKHook_WeaponCanUse, OnWeaponCanUse); 
		}
		i++;
	}
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
HookEvents()
{
	HookConVarChange(cvar_active_hulk_dev, 						Event_CvarChange);
	
	HookConVarChange(cvar_shake_amplitude, 						Event_CvarChange);
	HookConVarChange(cvar_shake_frequency, 						Event_CvarChange);
	
	HookConVarChange(cvar_timer_state_idle_attack, 				Event_CvarChange);
	HookConVarChange(cvar_timer_state_run_attack, 				Event_CvarChange);
	HookConVarChange(cvar_timer_state_run, 						Event_CvarChange);
	HookConVarChange(cvar_timer_state_back, 					Event_CvarChange);
	HookConVarChange(cvar_timer_state_right, 					Event_CvarChange);
	HookConVarChange(cvar_timer_state_left, 					Event_CvarChange);
	
	HookConVarChange(cvar_timer_shake_idle_attack, 				Event_CvarChange);
	HookConVarChange(cvar_timer_shake_run_attack, 				Event_CvarChange);
	HookConVarChange(cvar_timer_shake_run, 						Event_CvarChange);
	HookConVarChange(cvar_timer_shake_runx2, 					Event_CvarChange);
	
	HookConVarChange(cvar_timer_sound_run_attack, 				Event_CvarChange);
	HookConVarChange(cvar_timer_sound_idle_attack, 				Event_CvarChange);
	
	HookConVarChange(cvar_hulk_heal, 							Event_CvarChange);
	HookConVarChange(cvar_hulk_fadeout, 						Event_CvarChange);
	
	HookConVarChange(cvar_hulk_power_random, 					Event_CvarChange);
	
	HookConVarChange(cvar_hulk_power_1, 						Event_CvarChange);
	HookConVarChange(cvar_hulk_power_2, 						Event_CvarChange);
	HookConVarChange(cvar_hulk_power_3, 						Event_CvarChange);
	HookConVarChange(cvar_hulk_power_4, 						Event_CvarChange);
	HookConVarChange(cvar_hulk_power_5, 						Event_CvarChange);
	HookConVarChange(cvar_hulk_power_6, 						Event_CvarChange);
	HookConVarChange(cvar_hulk_power_7, 						Event_CvarChange);
	HookConVarChange(cvar_hulk_power_8, 						Event_CvarChange);
	HookConVarChange(cvar_hulk_power_9, 						Event_CvarChange);
	HookConVarChange(cvar_hulk_power_10, 						Event_CvarChange);
	
	HookConVarChange(cvar_hulk_power_1_time_out, 				Event_CvarChange);
	HookConVarChange(cvar_hulk_power_2_time_out, 				Event_CvarChange);
	HookConVarChange(cvar_hulk_power_3_time_out, 				Event_CvarChange);
	HookConVarChange(cvar_hulk_power_4_time_out, 				Event_CvarChange);
	HookConVarChange(cvar_hulk_power_5_time_out, 				Event_CvarChange);
	HookConVarChange(cvar_hulk_power_6_time_out, 				Event_CvarChange);
	HookConVarChange(cvar_hulk_power_7_time_out, 				Event_CvarChange);
	HookConVarChange(cvar_hulk_power_8_time_out, 				Event_CvarChange);
	HookConVarChange(cvar_hulk_power_9_time_out, 				Event_CvarChange);
	HookConVarChange(cvar_hulk_power_10_time_out, 				Event_CvarChange);
	
	HookConVarChange(cvar_hulk_power_6_radius, 					Event_CvarChange);
	HookConVarChange(cvar_hulk_power_6_push, 					Event_CvarChange);
	
	HookConVarChange(cvar_hulk_power_8_radius, 					Event_CvarChange);
	HookConVarChange(cvar_hulk_power_8_push, 					Event_CvarChange);
	
	HookConVarChange(cvar_hulk_teleport_running_radius, 		Event_CvarChange);
	HookConVarChange(cvar_hulk_teleport_running_timer, 			Event_CvarChange);
	HookConVarChange(cvar_hulk_teleport_running_timer_min, 		Event_CvarChange);
	HookConVarChange(cvar_hulk_teleport_running_timer_max, 		Event_CvarChange);
	
	HookConVarChange(cvar_hulk_swallow_projectile_radius, 		Event_CvarChange);
	HookConVarChange(cvar_hulk_swallow_projectile_heal, 		Event_CvarChange);
	
	HookConVarChange(cvar_hulk_power_9_interval, 				Event_CvarChange);
	HookConVarChange(cvar_hulk_power_9_heal, 					Event_CvarChange);
	
	HookConVarChange(cvar_hulk_speed_normal, 					Event_CvarChange);
	HookConVarChange(cvar_hulk_speed_normal_bot, 				Event_CvarChange);
	HookConVarChange(cvar_hulk_speed_faster, 					Event_CvarChange);
	
	HookConVarChange(cvar_max_player_boss, 						Event_CvarChange);
}

/***********************************************************/
/******************** WHEN CVARS CHANGE ********************/
/***********************************************************/
public Event_CvarChange(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	UpdateState();
}

/***********************************************************/
/*********************** UPDATE STATE **********************/
/***********************************************************/
UpdateState()
{
	B_active_hulk_dev 						= GetConVarBool(cvar_active_hulk_dev);
	
	F_shake_amplitude						= GetConVarFloat(cvar_shake_amplitude);
	F_shake_frequency						= GetConVarFloat(cvar_shake_frequency);
	
	F_timer_state_idle_attack				= GetConVarFloat(cvar_timer_state_idle_attack);
	F_timer_state_run_attack				= GetConVarFloat(cvar_timer_state_run_attack);
	F_timer_state_run						= GetConVarFloat(cvar_timer_state_run);
	F_timer_state_back						= GetConVarFloat(cvar_timer_state_back);
	F_timer_state_right						= GetConVarFloat(cvar_timer_state_right);
	F_timer_state_left						= GetConVarFloat(cvar_timer_state_left);
	
	F_timer_shake_idle_attack				= GetConVarFloat(cvar_timer_shake_idle_attack);
	F_timer_shake_run_attack				= GetConVarFloat(cvar_timer_shake_run_attack);
	F_timer_shake_run						= GetConVarFloat(cvar_timer_shake_run);
	F_timer_shake_runx2						= GetConVarFloat(cvar_timer_shake_runx2);
	
	F_timer_sound_run_attack				= GetConVarFloat(cvar_timer_sound_run_attack);
	F_timer_sound_idle_attack				= GetConVarFloat(cvar_timer_sound_idle_attack);
	
	C_hulk_heal								= GetConVarInt(cvar_hulk_heal);
	C_hulk_fadeout							= GetConVarInt(cvar_hulk_fadeout);
	
	B_hulk_power_random						= GetConVarBool(cvar_hulk_power_random);
	
	B_hulk_power_1							= GetConVarBool(cvar_hulk_power_1);
	B_hulk_power_2							= GetConVarBool(cvar_hulk_power_2);
	B_hulk_power_3							= GetConVarBool(cvar_hulk_power_3);
	B_hulk_power_4							= GetConVarBool(cvar_hulk_power_4);
	B_hulk_power_5							= GetConVarBool(cvar_hulk_power_5);
	B_hulk_power_6							= GetConVarBool(cvar_hulk_power_6);
	B_hulk_power_7							= GetConVarBool(cvar_hulk_power_7);
	B_hulk_power_8							= GetConVarBool(cvar_hulk_power_8);
	B_hulk_power_9							= GetConVarBool(cvar_hulk_power_9);
	B_hulk_power_10							= GetConVarBool(cvar_hulk_power_10);
	
	F_hulk_power_1_time_out					= GetConVarFloat(cvar_hulk_power_1_time_out);
	F_hulk_power_2_time_out					= GetConVarFloat(cvar_hulk_power_2_time_out);
	F_hulk_power_3_time_out					= GetConVarFloat(cvar_hulk_power_3_time_out);
	F_hulk_power_4_time_out					= GetConVarFloat(cvar_hulk_power_4_time_out);
	F_hulk_power_5_time_out					= GetConVarFloat(cvar_hulk_power_5_time_out);
	F_hulk_power_6_time_out					= GetConVarFloat(cvar_hulk_power_6_time_out);
	F_hulk_power_7_time_out					= GetConVarFloat(cvar_hulk_power_7_time_out);
	F_hulk_power_8_time_out					= GetConVarFloat(cvar_hulk_power_8_time_out);
	F_hulk_power_9_time_out					= GetConVarFloat(cvar_hulk_power_9_time_out);
	F_hulk_power_10_time_out				= GetConVarFloat(cvar_hulk_power_10_time_out);
	
	F_hulk_power_6_radius					= GetConVarFloat(cvar_hulk_power_6_radius);
	F_hulk_power_6_push						= GetConVarFloat(cvar_hulk_power_6_push);
	
	F_hulk_power_8_radius					= GetConVarFloat(cvar_hulk_power_8_radius);
	F_hulk_power_8_push						= GetConVarFloat(cvar_hulk_power_8_push);
	
	F_hulk_teleport_running_radius			= GetConVarFloat(cvar_hulk_teleport_running_radius);
	F_hulk_teleport_running_timer			= GetConVarFloat(cvar_hulk_teleport_running_timer);
	F_hulk_teleport_running_timer_min		= GetConVarFloat(cvar_hulk_teleport_running_timer_min);
	F_hulk_teleport_running_timer_max		= GetConVarFloat(cvar_hulk_teleport_running_timer_max);
	
	F_hulk_swallow_projectile_radius		= GetConVarFloat(cvar_hulk_swallow_projectile_radius);
	C_hulk_swallow_projectile_heal			= GetConVarInt(cvar_hulk_swallow_projectile_heal);
	
	F_hulk_power_9_interval					= GetConVarFloat(cvar_hulk_power_9_interval);
	C_hulk_power_9_heal						= GetConVarInt(cvar_hulk_power_9_heal);
	
	F_hulk_speed_normal						= GetConVarFloat(cvar_hulk_speed_normal);
	F_hulk_speed_normal_bot					= GetConVarFloat(cvar_hulk_speed_normal_bot);
	F_hulk_speed_faster						= GetConVarFloat(cvar_hulk_speed_faster);
	
	C_max_player_boss						= GetConVarInt(cvar_max_player_boss);
}

/***********************************************************/
/******************* WHEN CONFIG EXECUTED ******************/
/***********************************************************/
public OnConfigsExecuted()
{
	//UpdateState();
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public OnMapStart()
{
	AddFileToDownloadsTable("materials/models/infected/hulk/hulk_01.vmt");
	AddFileToDownloadsTable("materials/models/infected/hulk/hulk_01_normal.vtf");
	AddFileToDownloadsTable("materials/models/infected/hulk/hulk_traincar_01.vmt");
	AddFileToDownloadsTable("materials/models/infected/hulk/hulk_traincar_01.vtf");
	AddFileToDownloadsTable("materials/models/infected/hulk/hulk_traincar_01_normal.vtf");
	AddFileToDownloadsTable("materials/models/infected/hulk/tank_color.vtf");
	AddFileToDownloadsTable("materials/models/infected/hulk/tank_normal.vtf");
	AddFileToDownloadsTable("materials/models/infected/hulk/coach_head_wrp.vtf");
	AddFileToDownloadsTable("models/infected/anim_hulk.mdl");
	AddFileToDownloadsTable("models/infected/anim_hulk.ani");
	AddFileToDownloadsTable("models/infected/hulk_dlc3.vvd");
	AddFileToDownloadsTable("models/infected/hulk_dlc3.mdl");
	AddFileToDownloadsTable("models/infected/hulk_DLC3.dx90.vtx");
	AddFileToDownloadsTable("models/infected/hulk_DLC3.phy");
	
	AddFileToDownloadsTable("models/infected/hulk/shield/shield.mdl");
	AddFileToDownloadsTable("models/infected/hulk/shield/shield.dx90.vtx");
	AddFileToDownloadsTable("models/infected/hulk/shield/shield.vvd");
	AddFileToDownloadsTable("materials/models/infected/hulk/shield/shield.vmt");
	AddFileToDownloadsTable("materials/models/infected/hulk/shield/shield.vtf");
	AddFileToDownloadsTable("materials/models/infected/hulk/shield/shield_blue.vmt");
	AddFileToDownloadsTable("materials/models/infected/hulk/shield/shield_blue.vtf");
	
	PrecacheModel("models/infected/hulk_dlc3.mdl", true);
	PrecacheModel("models/infected/anim_hulk.mdl", true);
	PrecacheModel("models/infected/anim_hulk.ani", true);
	
	PrecacheModel("models/infected/hulk/shield/shield.mdl", true);
	
	FakeAndDownloadSound(false, S_hulk_noise_sound, 4);
	FakeAndDownloadSound(false, S_hulk_voice_attack_sound, 10);
	FakeAndDownloadSound(false, S_hulk_voice_death_sound, 7);
	FakeAndDownloadSound(false, S_hulk_voice_die_sound, 7);
	FakeAndDownloadSound(false, S_hulk_voice_pain_sound, 18);
	FakeAndDownloadSound(false, S_hulk_voice_yell_sound, 12);
	
	ResetAllClients(true);
	UpdateState();
	
}

/***********************************************************/
/**************** WHEN CLIENT PUT IN SERVER ****************/
/***********************************************************/
public OnClientPutInServer(client)
{
	if (IsClientInGame(client))
	{
		ResetAll(client, false);
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse); 
	}
}

/***********************************************************/
/***************** WHEN CLIENT DISCONNECT ******************/
/***********************************************************/
public OnClientDisconnect(client)
{
	if(PlayerIsHulk[client])
	{
		ResetAll(client, true);
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	}
}

/***********************************************************/
/***************** RESET ALL IS POSSIBLE *******************/
/***********************************************************/
ResetAll(client, bool:timer)
{
	if(PlayerIsHulk[client])
	{
		PlayerIsHulk[client] 		= false;
		LifeHulk[client] 			= 0;
		
		C_iClone[client]			= 0;
		C_health[client]			= 0;
		
		HulkShield[client] 			= false;
		HulkRage[client]			= false;
		HulkInvisible[client]		= false;
		HulkHeal[client]			= false;
		
		TimerHurt[client] 			= 0.0;
		TimerPower[client] 			= 0.0;
		TimerJump[client] 			= 0.0;
		TimerSpawn[client] 			= 0.0;
		TimerRun[client]			= 0.0;
		TimerRunTeleport[client]	= 0.0;
			
		if(timer)
		{
			ClearTimer(TimersShakeRepeat[client]);
			ClearTimer(TimersShake[client]);
			ClearTimer(TimersSound[client]);
			ClearTimer(TimersResetState[client]);
			ClearTimer(TimersPowersHulkStep[client]);
			ClearTimer(TimerHulkAttrack[client]);
		}
		ClearHulk(client);
	}
}

ResetAllClients(bool:timer)
{
	for (new i = 1; i <= MaxClients; ++i) 
	{
		if(IsClientInGame(i))
		{
			ResetAll(i, timer);
		}
	}
}
/***********************************************************/
/******************** WHEN ROUND START *********************/
/***********************************************************/
public Event_RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	ResetAllClients(true);
	
	if(ZRiot_GetDay() == ZRiot_GetDayMax())
	{
		if(GetPlayersAlive(3, "both") >= C_max_player_boss)
		{
			SetPlayerMoveTypeAll(MOVETYPE_NONE);
			VoteForHulk();
			CreateTimer(20.0, Timer_GetPlayerCanBeHulk);
		}
		else
		{	
			SetPlayerMoveTypeAll(MOVETYPE_NONE);
			CreateTimer(20.0, Timer_GetPlayerCanBeHulk);
		}
	}
}

/***********************************************************/
/********************* WHEN ROUND END **********************/
/***********************************************************/
public Event_RoundEnd(Handle:event, String:name[], bool:dontBroadcast)
{	
	ResetAllClients(false);
}

/***********************************************************/
/********************* PLAYER FOOTSTEP *********************/
/***********************************************************/
public Event_PlayerFootStep(Handle:event, String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(PlayerIsHulk[client])
	{
		new Float:now = GetEngineTime();
		if(now >= TimerRun[client])
		{
			PlayRandomVoice(client, true, S_hulk_voice_pain_sound, 0, 11);
			TimerRun[client] = now + GetRandomFloat(5.0, 15.0);
			
			new String:targetName[64];
			Format(targetName, sizeof(targetName), "Client%d", client);
			
			//PrintToDev(B_active_hulk_dev, "%s Run sound", TAG_CHAT);
			
		}
		
		if(now >= TimerRunTeleport[client])
		{
			TimerRunTeleport[client] = now + GetRandomFloat(F_hulk_teleport_running_timer_min, F_hulk_teleport_running_timer_max);
			
			new Handle:kv = CreateKeyValues("TeleportRunning");
			KvSetNum(kv, "client", client);
			KvSetFloat(kv, "radius", F_hulk_teleport_running_radius);
		
			CreateTimer(F_hulk_teleport_running_timer, Timer_TeleportHulk, kv);
		}
	}
}

/***********************************************************/
/******************** WHEN PLAYER DIE **********************/
/***********************************************************/
public Event_PlayerDeath(Handle:event, String:name[], bool:dontBroadcast)
{	
	new victim 				= GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(PlayerIsHulk[victim])
	{
		AcceptEntityInput(C_iClone[victim], "BecomeRagdoll");
		PlayRandomVoice(C_iClone[victim], false, S_hulk_voice_death_sound, 0, 6);
		
		ResetAll(victim, true);
		
	}
}

/***********************************************************/
/******************** WHEN PLAYER SPAWN ********************/
/***********************************************************/
public Event_PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		ResetAll(client, false);
		CreateTimer(16.0, Timer_SpawnHulk, client);
	}
}

/***********************************************************/
/******************** WHEN PLAYER HURT *********************/
/***********************************************************/
public Event_PlayerHurt(Handle:event, String:name[], bool:dontBroadcast)
{
	new victim 				= GetClientOfUserId(GetEventInt(event, "userid"));
	C_health[victim] 		= GetEventInt(event, "health");

	if(PlayerIsHulk[victim])
	{
		TotalLifeHulk[victim] = RoundToNearest(float(C_health[victim]) / float(LifeHulk[victim]) * 100.0);
		
		PrintToDev(B_active_hulk_dev, "%s Vie restant: %i, Max vie: %i, Pourcentage %i", TAG_CHAT, C_health[victim], LifeHulk[victim], TotalLifeHulk[victim]);
			
		if(B_hulk_power_random)
		{
			new Float:now = GetEngineTime();
			if(now >= TimerPower[victim])
			{
				SetPowersHulkStep(victim, true);
				TimerPower[victim] = now + GetRandomFloat(10.0, 15.0);
			}
		}
		else
		{
			GetPowersHulkStep(victim, TotalLifeHulk[victim]);
			SetPowersHulkStep(victim, false);
		}
		
		new Float:now = GetEngineTime();
		if(now >= TimerHurt[victim])
		{
			PlayRandomVoice(victim, true, S_hulk_voice_pain_sound, 0, 11);
			TimerHurt[victim] = now + GetRandomFloat(1.5, 5.0);
			
			PrintToDev(B_active_hulk_dev, "%s Hurt sound", TAG_CHAT);
			
		}
	}
}

/***********************************************************/
/******************** WHEN PLAYER SPAWN ********************/
/***********************************************************/
public Event_PlayerJump(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	new Float:now = GetEngineTime();
	
	
	if(PlayerIsHulk[client])
	{
		if(now >= TimerJump[client])
		{
			PlayRandomVoice(client, true, S_hulk_voice_yell_sound, 0, 11);
			TimerJump[client] = now + GetRandomFloat(0.5, 1.0);
			
			//PrintToDev(B_active_hulk_dev, "%s Jump sound", TAG_CHAT);
			
		}
	}
}
/***********************************************************/
/********************** ON GAME FRAME **********************/
/***********************************************************/

public OnGameFrame()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(PlayerIsHulk[i])
		{
			SetHulkHpBase(i, false);
			new newlife = GetClientHealth(i);
			if(newlife >= LifeHulk[i])
			{
				//new oldlife = LifeHulk[i];
				LifeHulk[i] = newlife;
			}
			
			new knife = GetPlayerWeaponSlot(i, _:SlotKnife);
			if(GetEntityRenderMode(knife) == RENDER_NONE)
			{
				SetEntityRenderMode(knife, RENDER_NONE);
			}
		}
	}
}

/***********************************************************/
/***************** WHEN PLAYER TAKE DAMAGE *****************/
/***********************************************************/
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if(PlayerIsHulk[victim])
	{
		if(damagetype & DMG_BURN)
		{
			ExtinguishPlayer(victim);
		}
		
		if(!(damagetype & DMG_BULLET) && !(damagetype & DMG_KNIFE))
		{
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

/***********************************************************/
/********************* WEAPON CAN USE **********************/
/***********************************************************/
public Action:OnWeaponCanUse(client, weapon)
{
    if(PlayerIsHulk[client])
    {
        decl String:weaponString[64];
        GetEdictClassname(weapon, weaponString, sizeof(weaponString));
        if (!StrEqual(weaponString, "weapon_knife"))
		{
            return Plugin_Handled;
		}
    }

    return Plugin_Continue;
}
/***********************************************************/
/******************** ON ENTITY CREATED ********************/
/***********************************************************/
public OnEntityCreated(Entity, const String:Classname[])
{
	if(strcmp(Classname, "hegrenade_projectile") == 0 || strcmp(Classname, "flashbang_projectile") == 0 || strcmp(Classname, "smokegrenade_projectile") == 0)
	{
		CreateTimer(0.8, SwallowProjectile, Entity, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:CS_OnTerminateRound(&Float:delay, &CSRoundEndReason:reason) 
{
	if(!CanWinParty)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}  

/***********************************************************/
/****************** WHEN PLAYER HOLD KEYS ******************/
/***********************************************************/
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	//0 			= IDLE
	//2 			= JUMP
	//10            = RUN + JUMP
	//4 			= CROUCH
	//8 			= RUN FRONT
	//16 			= RUN BACK
	//512 			= LEFT
	//1024 			= RIGHT
	//131080 		= WALK FRONT
	//131088 		= WALK BACK
	//132096 		= WALK RIGH
	//131584 		= WALK LEFT
	//1 			= CLICK LEFT
	//2048 			= CLICK RIGHT

	if(IsClientInGame(client) && IsPlayerAlive(client) && PlayerIsHulk[client])
	{
	
		//DETECT WHEN PLAYER IS ATTACKING WITH CLICKS MOUSE
		if( buttons & IN_ATTACK && !PlayerIsAttacking[client] || buttons & IN_ATTACK2 && !PlayerIsAttacking[client] )
		{
			PlayerIsAttacking[client] = true;
			
			//PrintToDev(B_active_hulk_dev, "%s attack", TAG_CHAT);
		}
		
		else if( !(buttons & IN_ATTACK) && !(buttons & IN_ATTACK2) && PlayerIsAttacking[client] )
		{
			PlayerIsAttacking[client] = false;
			
			//PrintToDev(B_active_hulk_dev, "%s no attack", TAG_CHAT);
		}
		
		
		//Power Damage Knife
		if(buttons & IN_ATTACK || buttons & IN_ATTACK2)
		{
			KnifeDamageRadius(client);
		}
		
		
		//ANIMATIONS TO SET WHILE PLAYER DOING SOMETHING
		//IDLE ID = 1
		
		if((buttons & buttons) == 0 && !PlayerIsAttacking[client] && C_iCloneState[client] != 1)
		{
			SetVariantString("idle");
			AcceptEntityInput(C_iClone[client], "SetAnimation");
			SetVariantString("idle");
			C_iCloneState[client] = 1;
			
			//PrintToDev(B_active_hulk_dev, "%s idle", TAG_CHAT);
		}
		
		//IDLE + ATTACK ID = 10
		else if( !(buttons & IN_FORWARD) && (GetEntityFlags(client) & FL_ONGROUND) && PlayerIsAttacking[client] && C_iCloneState[client] != 10 && !(GetClientButtons(client) & IN_BACK) && !(GetClientButtons(client) & IN_MOVERIGHT) && !(GetClientButtons(client) & IN_MOVELEFT))
		{
			SetVariantString("attack_incap_03");
			AcceptEntityInput(C_iClone[client], "SetAnimation");
			SetVariantString("attack_incap_03");
			C_iCloneState[client] = 10;
			
			TimersResetState[client] 	= CreateTimer(F_timer_state_idle_attack, Timer_ResetStates, client);
			
			new Handle:kv = CreateKeyValues("SoundIdleAttack");
			KvSetNum(kv, "client", client);
			KvSetNum(kv, "num", 2);
			
			TimersSound[client]			= CreateTimer(F_timer_sound_idle_attack, Timer_Sounds, kv);
			
			RadiusShake(client, F_timer_shake_idle_attack, false);
			
			//PrintToDev(B_active_hulk_dev, "%s idle+attack", TAG_CHAT);
		}
		
		
		//JUMP ID = 98
		else if((buttons & IN_JUMP) && !(GetEntityFlags(client) & FL_ONGROUND) && C_iCloneState[client] != 98)
		{
			SetVariantString("jump");
			AcceptEntityInput(C_iClone[client], "SetAnimation");
			SetVariantString("jump");
			
			new Handle:kv = CreateKeyValues("SoundJump");
			KvSetNum(kv, "client", client);
			KvSetNum(kv, "num", 1);
			
			C_iCloneState[client] = 98;
			
			//PrintToDev(B_active_hulk_dev, "%s jump", TAG_CHAT);
		}
		
		//RUN + ATTACK ID = 110
		else if((buttons & IN_FORWARD) && (GetEntityFlags(client) & FL_ONGROUND) && PlayerIsAttacking[client] && C_iCloneState[client] != 110 && !(GetClientButtons(client) & IN_BACK))
		{
			SetVariantString("raw_hulk_runattack1");
			AcceptEntityInput(C_iClone[client], "SetAnimation");
			SetVariantString("raw_hulk_runattack1");
			C_iCloneState[client] = 110;
			
			TimersResetState[client] = CreateTimer(F_timer_state_run_attack, Timer_ResetStates, client);
			
			new Handle:kv = CreateKeyValues("SoundRunAttack");
			KvSetNum(kv, "client", client);
			KvSetNum(kv, "num", 3);
			
			TimersSound[client]			= CreateTimer(F_timer_sound_run_attack, Timer_Sounds, kv);
			
			RadiusShake(client, F_timer_shake_run_attack, false);
			
			//PrintToDev(B_active_hulk_dev, "%s run+attack", TAG_CHAT);
		}
		
		//RUN ID = 100
		else if((buttons & IN_FORWARD) && (GetEntityFlags(client) & FL_ONGROUND) && !PlayerIsAttacking[client] && C_iCloneState[client] != 100 && !(GetClientButtons(client) & IN_BACK))
		{
			SetVariantString("hulk_runmad");
			AcceptEntityInput(C_iClone[client], "SetAnimation");
			SetVariantString("hulk_runmad");
			C_iCloneState[client] = 100;
			
			TimersResetState[client] = CreateTimer(F_timer_state_run, Timer_ResetStates, client);
			
			RadiusShake(client, F_timer_shake_run, false);
			RadiusShake(client, F_timer_shake_runx2, true);
			
			//PrintToDev(B_active_hulk_dev, "%s run", TAG_CHAT);
		}	
		
		//BACK ID = 125
		else if(GetClientButtons(client) & IN_BACK && (GetEntityFlags(client) & FL_ONGROUND) && C_iCloneState[client] != 125 && !(buttons & IN_FORWARD))
		{
			SetVariantString("shoved_backward");
			AcceptEntityInput(C_iClone[client], "SetAnimation");
			SetVariantString("shoved_backward");
			C_iCloneState[client] = 125;
			
			TimersResetState[client] = CreateTimer(F_timer_state_back, Timer_ResetStates, client);
			
			//PrintToDev(B_active_hulk_dev, "%s backward", TAG_CHAT);
		}
		
		//RIGHT ID = 175
		else if(GetClientButtons(client) & IN_MOVERIGHT && (GetEntityFlags(client) & FL_ONGROUND) && C_iCloneState[client] != 175 && !(GetClientButtons(client) & IN_MOVELEFT) && !(GetClientButtons(client) & IN_BACK) && !(buttons & IN_FORWARD))
		{
			SetVariantString("shoved_rightward");
			AcceptEntityInput(C_iClone[client], "SetAnimation");
			SetVariantString("shoved_rightward");
			C_iCloneState[client] = 175;
			
			TimersResetState[client] = CreateTimer(F_timer_state_right, Timer_ResetStates, client);
			
			//PrintToDev(B_active_hulk_dev, "%s right", TAG_CHAT);
		}
		
		//LEFT ID = 195
		else if(GetClientButtons(client) & IN_MOVELEFT && (GetEntityFlags(client) & FL_ONGROUND) && C_iCloneState[client] != 195 && !(GetClientButtons(client) & IN_MOVERIGHT) && !(GetClientButtons(client) & IN_BACK) && !(buttons & IN_FORWARD))
		{
			SetVariantString("shoved_leftward");
			AcceptEntityInput(C_iClone[client], "SetAnimation");
			SetVariantString("shoved_leftward");
			C_iCloneState[client] = 195;
			
			TimersResetState[client] = CreateTimer(F_timer_state_left, Timer_ResetStates, client);
			
			//PrintToDev(B_active_hulk_dev, "%s left", TAG_CHAT);
		}
	}
}

/***********************************************************/
/******************* TIMER SPAWN HULK **********************/
/***********************************************************/
public Action:Timer_SpawnHulk(Handle:timer, any:client)
{
	if(PlayerIsHulk[client])
	{
		new Float:now = GetEngineTime();
		if(now >= TimerSpawn[client])
		{
			PlayRandomVoice(client, true, S_hulk_voice_yell_sound, 0, 11);
			TimerSpawn[client] = now + GetRandomFloat(5.0, 20.0);
			
			//PrintToDev(B_active_hulk_dev, "%s Spawn sound", TAG_CHAT);
		}	
	}
}

/***********************************************************/
/******************* RESET STATE TIMER *********************/
/***********************************************************/
public Action:Timer_ResetStates(Handle:timer, any:client)
{
	C_iCloneState[client] = 9999;
	ClearTimer(TimersResetState[client]);
}

/***********************************************************/
/********************** SHAKE TIMER ************************/
/***********************************************************/
public Action:Timer_Shake(Handle:timer, any:data)
{
	new Handle:kv 		= Handle:data;
	new client 			= KvGetNum(kv, "client", -1);
	new Float:time 		= KvGetFloat(kv, "time");
	
	Shake(client, time, F_shake_frequency, F_shake_amplitude);
	ClearTimer(TimersShake[client]);
}

/***********************************************************/
/******************* SHAKE TIMER REPEAT ********************/
/***********************************************************/
public Action:Timer_ShakeRepeat(Handle:timer, any:data)
{
	new Handle:kv 		= Handle:data;
	new client 			= KvGetNum(kv, "client", -1);
	new Float:time 		= KvGetFloat(kv, "time");
	
	Shake(client, time, F_shake_frequency, F_shake_amplitude);
	ClearTimer(TimersShakeRepeat[client]);
}

/***********************************************************/
/******************* SHAKE TIMER REPEAT ********************/
/***********************************************************/
public Action:Timer_Sounds(Handle:timer, any:data)
{
	
	new String:S_sound_to_play[PLATFORM_MAX_PATH];
	new Handle:kv 		= Handle:data;
	new client 			= KvGetNum(kv, "client", -1);
	new num 			= KvGetNum(kv, "num", -1);
	
	
	if(num == 0)
	{
		Format(S_sound_to_play, PLATFORM_MAX_PATH, "*%s", S_hulk_noise_sound[0]);
	}
	else if(num == 1)
	{
		Format(S_sound_to_play, PLATFORM_MAX_PATH, "*%s", S_hulk_noise_sound[1]);
	}
	else if(num == 2)
	{
		Format(S_sound_to_play, PLATFORM_MAX_PATH, "*%s", S_hulk_noise_sound[2]);
	}
	else if(num == 3)
	{
		Format(S_sound_to_play, PLATFORM_MAX_PATH, "*%s", S_hulk_noise_sound[3]);
	}

	decl newClients[MaxClients+1];
	new totalClients = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			newClients[totalClients++] = i;
		}
	}
	new Float:position[3];
	GetClientAbsOrigin(client, position);
	
	EmitSound(newClients, totalClients, S_sound_to_play, client, SNDCHAN_ITEM, SNDLEVEL_SCREAMING, SND_NOFLAGS, 1.0, _, _, position);
	ClearTimer(TimersSound[client]);
}

/***********************************************************/
/***************** GET STEPS POWERS HULK *******************/
/***********************************************************/
GetPowersHulkStep(client, hp)
{

	if(hp >= 95)
	{
		PowersHulkStep[client] = 1;
	}
	else if(hp >= 90)
	{
		PowersHulkStep[client] = 2;
	}
	else if(hp >= 80)
	{
		PowersHulkStep[client] = 3;	
	}
	else if(hp >= 70)
	{
		PowersHulkStep[client] = 4;	
	}
	else if(hp >= 60)
	{
		PowersHulkStep[client] = 5;
	}
	else if(hp >= 50)
	{
		PowersHulkStep[client] = 6;	
	}
	else if(hp >= 40)
	{
		PowersHulkStep[client] = 7;
	}
	else if(hp >= 30)
	{
		PowersHulkStep[client] = 8;
	}
	else if(hp >= 20)
	{
		PowersHulkStep[client] = 9;	
	}
	else if(hp >= 10)
	{
		PowersHulkStep[client] = 10;
	}

}

/***********************************************************/
/***************** SET STEPS POWERS HULK *******************/
/***********************************************************/
SetPowersHulkStep(client, bool:random)
{
	new num;
	if(random)
	{
		num = GetRandomInt(1, 10);
	}
	else
	{
		if(PowersHulkStepDone[client] && PowersHulkStep[client] && PowersHulkStepDone[client] != PowersHulkStep[client])
		{
			ResetPowers(client);
		}
		num = PowersHulkStep[client];
	}
	
	switch(num)
	{
		case 1:
		{
			if(B_hulk_power_1 && PowersHulkStepDone[client] != 1)
			{
				TimersPowersHulkStep[client] = INVALID_HANDLE;
				PowersHulkStepDone[client] = 1;
			}
		}
		case 2:
		{
			if(B_hulk_power_2 && PowersHulkStepDone[client] != 2)
			{
				TimersPowersHulkStep[client] = INVALID_HANDLE;
				PowersHulkStepDone[client] = 2;
			}		
		}
		case 3:
		{
			if(B_hulk_power_3 && PowersHulkStepDone[client] != 3)
			{
				TimersPowersHulkStep[client] = INVALID_HANDLE;
				PowersHulkStepDone[client] = 3;
			}		
		}
		
		//INVISIBLE POWER
		case 4:
		{
			if(B_hulk_power_4 && PowersHulkStepDone[client] != 4)
			{
				InvisibleHulk(client, false);
				TimersPowersHulkStep[client] = CreateTimer(F_hulk_power_4_time_out, Timer_UnInvisibleHulk, client);
				PowersHulkStepDone[client] = 4;
			}		
		}
		case 5:
		{
			if(B_hulk_power_5 && PowersHulkStepDone[client] != 5)
			{
				TimersPowersHulkStep[client] = INVALID_HANDLE;
				PowersHulkStepDone[client] = 5;
			}		
		}
		
		//SHIELD POWER
		case 6:
		{
			if(B_hulk_power_6 && PowersHulkStepDone[client] != 6)
			{
				ShieldHulk(client, false);	
				TimersPowersHulkStep[client] = CreateTimer(F_hulk_power_6_time_out, Timer_UnShieldHulk, client);
				PowersHulkStepDone[client] = 6;
			}		
		}
		
		case 7:
		{
			if(B_hulk_power_7 && PowersHulkStepDone[client] != 7)
			{
				TimersPowersHulkStep[client] = INVALID_HANDLE;
				PowersHulkStepDone[client] = 7;
			}		
		}
		
		//RAGE POWER
		case 8:
		{
			if(B_hulk_power_8 && PowersHulkStepDone[client] != 8)
			{
				RageHulk(client, false);
				TimersPowersHulkStep[client] = CreateTimer(F_hulk_power_8_time_out, Timer_UnRageHulk, client);
				PowersHulkStepDone[client] = 8;
			}		
		}
		
		//HEAL POWER
		case 9:
		{
			if(B_hulk_power_9 && PowersHulkStepDone[client] != 9)
			{
				CreateTimer(F_hulk_power_9_time_out, Timer_UnHealHulk, client);
				TimersPowersHulkStep[client] = CreateTimer(F_hulk_power_9_interval, Timer_HealHulk, client, TIMER_REPEAT);
				SetColorHulkHeal(client, false);
				PowersHulkStepDone[client] = 9;
			}		
		}
		case 10:
		{
			if(B_hulk_power_10 && PowersHulkStepDone[client] != 10)
			{
				TimersPowersHulkStep[client] = INVALID_HANDLE;
				PowersHulkStepDone[client] = 10;
			}		
		}
		
	}
	
	
}

ResetPowers(client)
{
	if(HulkInvisible[client])
	{
		InvisibleHulk(client, true);
		ClearTimer(TimersPowersHulkStep[client]);
	}
	else if(HulkShield[client])
	{
		ShieldHulk(client, true);
		ClearTimer(TimersPowersHulkStep[client]);		
	}
	else if(HulkRage[client])
	{
		RageHulk(client, true);
		ClearTimer(TimersPowersHulkStep[client]);
	}
	else if(HulkHeal[client])
	{
		SetColorHulkHeal(client, true);
		ClearTimer(TimersPowersHulkStep[client]);
	}
}
/*************** SHIELD ***************/
ShieldHulk(client, bool:reverse)
{
	if(!reverse)
	{
		SetEntityRenderMode(C_iClone[client], RENDER_TRANSCOLOR);
		SetEntityRenderColor(C_iClone[client], 0, 0, 255, 240);
		
		CreateShield(client);
		
		SetEntityRenderMode(HulkHaveShield[client], RENDER_TRANSCOLOR);
		SetEntityRenderColor(HulkHaveShield[client], 0, 0, 255, 240);
		
		SetEntProp(client, Prop_Data, "m_takedamage", 0);  //default = 2
		
		new Handle:kv = CreateKeyValues("ShieldAttrack");
		KvSetNum(kv, "client", client);
		KvSetNum(kv, "teleportself", 0);
		KvSetFloat(kv, "radius", F_hulk_power_6_radius);
		KvSetFloat(kv, "push", F_hulk_power_6_push);
		
		CreateTimer(F_hulk_power_6_time_out, Timer_DeleteAttrack, client, TIMER_FLAG_NO_MAPCHANGE);		
		TimerHulkAttrack[client] = CreateTimer(0.1, Timer_Attrack, kv, TIMER_REPEAT);
		
		HulkShield[client] = true;

		CPrintToChatAll("%t", "Hulk Shield");
	}
	else
	{
		SetEntityRenderMode(C_iClone[client], RENDER_TRANSCOLOR);
		SetEntityRenderColor(C_iClone[client], 255, 255, 255, 255);
		SetEntProp(client, Prop_Data, "m_takedamage", 2);  //default = 2
		
		ClearTimer(TimerHulkAttrack[client]);
		ClearShield(client);
		HulkShield[client] = false;
		CPrintToChatAll("%t", "Hulk UnShield");
	}
		
	
}
public Action:Timer_UnShieldHulk(Handle:timer, any:client)
{
	ShieldHulk(client, true);
}
/*************** SHIELD ***************/

/**************** RAGE ****************/
RageHulk(client, bool:reverse)
{
	if(!reverse)
	{
		SetEntityRenderMode(C_iClone[client], RENDER_TRANSCOLOR);
		SetEntityRenderColor(C_iClone[client], 255, 0, 0, 240);
		
		new String:targetName[64];
		Format(targetName, sizeof(targetName), "Client%d", client);
		
		new Handle:kv = CreateKeyValues("ShieldAttrack");
		KvSetNum(kv, "client", client);
		KvSetNum(kv, "teleportself", 0);
		KvSetFloat(kv, "radius", F_hulk_power_8_radius);
		KvSetFloat(kv, "push", F_hulk_power_8_push);
		
		CreateTimer(F_hulk_power_8_time_out, Timer_DeleteAttrack, client, TIMER_FLAG_NO_MAPCHANGE);		
		TimerHulkAttrack[client] = CreateTimer(0.1, Timer_Attrack, kv, TIMER_REPEAT);
		
		HulkRage[client] = true;
		
		SetPlayerSpeed(client, F_hulk_speed_faster);
		
		CPrintToChatAll("%t", "Hulk Speed Faster", RoundFloat(F_hulk_speed_faster/300.0));
		CPrintToChatAll("%t", "Hulk Rage");
		
	}
	else
	{
		SetEntityRenderMode(C_iClone[client], RENDER_TRANSCOLOR);
		SetEntityRenderColor(C_iClone[client], 255, 255, 255, 255);
		
		ClearTimer(TimerHulkAttrack[client]);
		
		HulkRage[client] = false;
		
		if(!IsFakeClient(client))
		{
			SetPlayerSpeed(client, F_hulk_speed_normal);
		}
		else
		{	
			SetPlayerSpeed(client, F_hulk_speed_normal_bot);
		}
		
		CPrintToChatAll("%t", "Hulk Speed Normal");
		CPrintToChatAll("%t", "Hulk UnRage");
	}	
}

public Action:Timer_UnRageHulk(Handle:timer, any:client)
{
	RageHulk(client, true);
}
/**************** RAGE ****************/

/************* INVISIBLE **************/
InvisibleHulk(client, bool:reverse)
{
	if(!reverse)
	{
		SetEntityRenderMode(C_iClone[client], RENDER_TRANSCOLOR);
		SetEntityRenderColor(C_iClone[client], 255, 255, 255, 50);
		
		HulkInvisible[client] = true;
		CPrintToChatAll("%t", "Hulk Invisible");
	}
	else
	{
		SetEntityRenderMode(C_iClone[client], RENDER_TRANSCOLOR);
		SetEntityRenderColor(C_iClone[client], 255, 255, 255, 255);
		
		HulkInvisible[client] = false;
		CPrintToChatAll("%t", "Hulk UnInvisible");
	}
		
	
}
public Action:Timer_UnInvisibleHulk(Handle:timer, any:client)
{
	InvisibleHulk(client, true);
}
/************* INVISIBLE **************/

/******** SWALLOW PROJECTILES *********/
public Action:SwallowProjectile(Handle:timer, any:Entity)
{
	if(IsValidEntity(Entity))
	{
		new iCount;
		new Float:projectile[3], Float:client[3];
		
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				if(GetClientTeam(i) == CS_TEAM_CT)
				{
					iCount++;
				}
				if(PlayerIsHulk[i])
				{
					GetClientAbsOrigin(i, client);
					GetEntPropVector(Entity, Prop_Send, "m_vecOrigin", projectile);
					new Float:distance = GetVectorDistance(client, projectile);
				
					if (distance <= F_hulk_swallow_projectile_radius)
					{
						AcceptEntityInput(Entity, "Kill");
						new add_heal = C_hulk_swallow_projectile_heal * iCount;
						RegenerateHulk(i, add_heal, false);
						CPrintToChatAll("%t", "Hulk Swallow", add_heal);
					}
				}
			}
		}
	}
	
}
/******** SWALLOW PROJECTILES *********/

/********** REGENERATION HP ***********/
public Action:Timer_HealHulk(Handle:timer, any:client)
{
	new iCount;
	new add_heal;
	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT)
		{
			iCount++;
			add_heal = C_hulk_power_9_heal * iCount;
		}
	}
	RegenerateHulk(client, add_heal, true);
}

public Action:Timer_UnHealHulk(Handle:timer, any:client)
{
	SetColorHulkHeal(client, true);
	ClearTimer(TimersPowersHulkStep[client]);
}

SetColorHulkHeal(client, bool:reverse)
{
	if(!reverse)
	{
		SetEntityRenderMode(C_iClone[client], RENDER_TRANSCOLOR);
		SetEntityRenderColor(C_iClone[client], 0, 255, 0, 240);
		HulkHeal[client] = true;
	}
	else
	{
		SetEntityRenderMode(C_iClone[client], RENDER_TRANSCOLOR);
		SetEntityRenderColor(C_iClone[client], 255, 255, 255, 255);
		HulkHeal[client] = false;	
	}
}
RegenerateHulk(client, amount, bool:msg)
{
	if(C_health[client] && LifeHulk[client] && TotalLifeHulk[client])
	{
		new extra_heal = C_health[client] + amount;
		
		if(extra_heal < LifeHulk[client])
		{
			//SetEntityHealth(client, extra_heal);
			SetEntProp(client, Prop_Data, "m_iHealth", extra_heal);
			SetEntProp(client, Prop_Data, "m_iMaxHealth", extra_heal);
		}
		else
		{
			//SetEntityHealth(client, LifeHulk[client]);
			SetEntProp(client, Prop_Data, "m_iHealth", LifeHulk[client]);
			SetEntProp(client, Prop_Data, "m_iMaxHealth", LifeHulk[client]);
		}
		
		if(msg)
		{
			CPrintToChatAll("%t", "Hulk Heal", amount);
		}
		
		C_health[client] = extra_heal;
	}
	
}
/********** REGENERATION HP ***********/

/*********** KNIFE DAMAGE ************/
void KnifeDamageRadius(int client)
{
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	
	for (new i = 1; i <= MaxClients; ++i) 
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && client != i)
		{
			new Float:pos[3];
			GetClientEyePosition(i, pos);
			new Float:distance = GetVectorDistance(vec, pos);
			
			if (distance <= 170)
			{
				new Float:now = GetEngineTime();
				if(now >= TimerKnife[client])
				{
					if(GetClientHealth(i) > 10)
					{
						SetDamage(i, "10");
						
						TimerKnife[client] = now + 1.0;
						if(B_active_hulk_dev)
						{
							new String:S_victim_name[MAX_NAME_LENGTH];
							GetClientName(i, S_victim_name, MAX_NAME_LENGTH);
						
							PrintToDev(B_active_hulk_dev, "%s %s reçoit le knife", TAG_CHAT, S_victim_name);
						}
					}
				}
			}
		}
	}
}

/***********************************************************/
/********************** SHAKE RADIUS ***********************/
/***********************************************************/
RadiusShake(client, Float:time, bool:repeat)
{
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	
	for (new i = 1; i <= MaxClients; ++i) 
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			new Float:pos[3];
			GetClientEyePosition(i, pos);
			new Float:distance = GetVectorDistance(vec, pos);
			
			if (distance <= 400)
			{
				if(B_active_hulk_dev)
				{
					new String:S_victim_name[MAX_NAME_LENGTH];
					GetClientName(i, S_victim_name, MAX_NAME_LENGTH);
				
					PrintToDev(B_active_hulk_dev, "%s %s est dans votre champs et reçoit le shake", TAG_CHAT, S_victim_name);
				}
				
				new Handle:kv = CreateKeyValues("RadiusShake");
				KvSetNum(kv, "client", i);
				KvSetFloat(kv, "time", time);
				
				if(repeat)
				{
					TimersShakeRepeat[i] = CreateTimer(time, Timer_ShakeRepeat, kv);	
				}
				else
				{
					TimersShake[i] = CreateTimer(time, Timer_Shake, kv);
				}
			}
		}
	}
}

/***********************************************************/
/********************* CREATE ENTITY ***********************/
/***********************************************************/
public Action:CreateHulk(client)
{
	new ent = CreateEntityByName("prop_dynamic_override");
	if (ent == -1)
	{
		PlayerIsHulk[client] = false;
		return Plugin_Handled;
	}

	SetEntityModel(client, "models/infected/anim_hulk.mdl");
	SetEntityModel(ent, "models/infected/hulk_dlc3.mdl");
	
	DispatchSpawn(ent);
	
	
	SetEntProp(ent, Prop_Data, "m_takedamage", 0);
	SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
	SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client);
	SetEntProp(ent, Prop_Data, "m_iMaxHealth", 1000000);
	SetEntProp(ent, Prop_Data, "m_iHealth", 1000000);

	AcceptEntityInput( ent, "DisableCollision" );
	AcceptEntityInput( client, "DisableCollision" );
	//AcceptEntityInput( ent, "EnableCollision" );

	SetVariantString("idle");
	AcceptEntityInput(ent, "SetAnimation", -1, -1, 0); 

	new Float:pos[3], Float:angle[3];
	GetClientAbsOrigin(client, pos);
	GetClientAbsAngles(client, angle);
	
	new Float:Direction[3];
	Direction[0] = pos[0];
	Direction[1] = pos[1];
	Direction[2] = pos[2];

	new Float:AmmoPos[3];

	new Handle:Trace = TR_TraceRayFilterEx(pos, Direction, MASK_SOLID, RayType_EndPoint, TraceFilterAll, client);
	TR_GetEndPosition(AmmoPos, Trace);
	CloseHandle(Trace);

	TeleportEntity(ent, AmmoPos, angle, NULL_VECTOR);

	new String:fadeout[32];
	IntToString(C_hulk_fadeout, fadeout, 32);
	DispatchKeyValue(ent, "fademaxdist", fadeout);
	decl String:iTarget[16];
	Format(iTarget, 16, "client%d", client);
	DispatchKeyValue(client, "targetname", iTarget);

	SetVariantString(iTarget);
	AcceptEntityInput(ent, "SetParent");

	C_iClone[client] = EntIndexToEntRef(ent);
	PlayerIsHulk[client] = true;
	
	new knife = GetPlayerWeaponSlot(client, _:SlotKnife);
	SetEntityRenderMode(knife , RENDER_NONE);
	
	SDKHook(ent, SDKHook_SetTransmit, ShouldHide);
	
	
	return Plugin_Handled;
}

/***********************************************************/
/********************** SHOULD HIDE ************************/
/***********************************************************/
public Action:ShouldHide(ent, client)
{
	if(IsClientInGame(client))
	{
		new owner 				= GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		new m_hObserverTarget 	= GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
		
		if(PlayerIsHulk[owner] && owner == client)
		{
			if(m_hObserverTarget != 0)
			{
				return Plugin_Handled;
			}
		}
	
	}
	return Plugin_Continue;
}

/***********************************************************/
/**************** SET PLAYER CAN BE HULK *******************/
/***********************************************************/
public Action:Timer_GetPlayerCanBeHulk(Handle:timer)
{

	new ct = GetRandomPlayerEx(CS_TEAM_CT);
	new t = GetRandomPlayer(CS_TEAM_T);

	if(GetPlayersAlive(CS_TEAM_CT, "both") >= C_max_player_boss)
	{
		if(ct != -1)
		{
			SetPlayerHulk(ct);
			SetHulkHpBase(ct, true);
		}
		else
		{
			SetBotHulk(t, 2);
			SetHulkHpBase(t, true);
		}
	}
	else
	{
		SetBotHulk(t, 1);
		SetHulkHpBase(t, true);
	}
	
	SetPlayerMoveTypeAll(MOVETYPE_WALK);
}

/***********************************************************/
/******************* SET DAMAGE AND HP *********************/
/***********************************************************/
SetHulkHpBase(client, bool:spawn)
{
	// 10 000 * 2 players = 20 000
	new base_heal = C_hulk_heal * GetPlayersInGame(CS_TEAM_CT, "both");
	
	if(base_heal == 0)
	{
		base_heal = C_hulk_heal;
		PrintToDev(B_active_hulk_dev, "base heal = 0", TAG_CHAT);
	}
	
	if(base_heal > LifeHulk[client])
	{
		if(spawn)
		{
			//SetEntityHealth(client, base_heal);
			SetEntProp(client, Prop_Data, "m_iHealth", base_heal);
			SetEntProp(client, Prop_Data, "m_iMaxHealth", base_heal);
			//LifeHulk[client] = base_heal;
			
			LifeHulk[client] = base_heal;
			
			PrintToDev(B_active_hulk_dev, "%s New life: %i, %i Players", TAG_CHAT, LifeHulk[client], GetPlayersInGame(CS_TEAM_CT, "both"));
			
		}
		else
		{
		
			new damage;
			new life_remaining;
			
			if(life_remaining != C_health[client])
			{
				damage = LifeHulk[client] - C_health[client];
				life_remaining = LifeHulk[client] - damage;
			}
			else
			{
				damage = 0;
				life_remaining = 0;
			}
			
			//SetEntityHealth(client, base_heal);
			SetEntProp(client, Prop_Data, "m_iHealth", base_heal);
			SetEntProp(client, Prop_Data, "m_iMaxHealth", base_heal);
			
			if(damage > 0)
			{
				//SetDamage
				new Handle:kv = CreateKeyValues("ShieldAttrack");
				KvSetNum(kv, "client", client);
				KvSetNum(kv, "damage", damage);
				CreateTimer(0.1, Timer_SetDamage, kv);
			}
			
			//Max life = 20 000
			LifeHulk[client] = base_heal;
			
			PrintToDev(B_active_hulk_dev, "%s New life: %i, Damage: %i, Life: %i %i Players", TAG_CHAT, LifeHulk[client], life_remaining, damage, GetPlayersInGame(CS_TEAM_CT, "both"));
		}
	}
	else if(base_heal < LifeHulk[client])
	{
		//47 000
		new life = GetClientHealth(client);
		
		//47 000 / 50 0000 * 100 = 94%
		new pourcentage = RoundToNearest(float(life) / float(LifeHulk[client]) * 100.0);
		
		//40 000 * 94 / 100 = 37600
		new heal_pourcente = base_heal * pourcentage / 100;
		
		//40000 - 37600 = 2400
		new damage = base_heal - heal_pourcente;
		
		PrintToDev(B_active_hulk_dev, "%s Pourcentage : %i, heal pourcente: %i  -- Life:%i, Base: %i, LIFE: %i -- Damage: %i", TAG_CHAT, pourcentage, heal_pourcente, life, base_heal, LifeHulk[client], damage);
		
		//SetEntityHealth(client, base_heal);
		SetEntProp(client, Prop_Data, "m_iHealth", base_heal);
		SetEntProp(client, Prop_Data, "m_iMaxHealth", base_heal);
		 
		if(damage > 0)
		{
			//SetDamage
			new Handle:kv = CreateKeyValues("ShieldAttrack");
			KvSetNum(kv, "client", client);
			KvSetNum(kv, "damage", damage);
			CreateTimer(0.1, Timer_SetDamage, kv);
		}
		
		//Max life = 40 000
		LifeHulk[client] = base_heal;
		
		PrintToDev(B_active_hulk_dev, "%s New life: %i, Damage: %i, %i Players", TAG_CHAT, LifeHulk[client], damage, GetPlayersInGame(CS_TEAM_CT, "both"));
	}
}
public Action:Timer_SetDamage(Handle:timer, any:data)
{
	new Handle:kv 			= Handle:data;
	new client 				= KvGetNum(kv, "client", -1);
	new damage 				= KvGetNum(kv, "damage");
	
	new String:heal[512];
	IntToString(damage, heal, sizeof(heal));
	SetDamage(client, heal);
	
	PrintToDev(B_active_hulk_dev, "%s Damage set: %i", TAG_CHAT, damage);
}
public SetDamage(client, String:damage[]) //For people who prefer murder instead of suicide...
{
	new pointHurt = CreateEntityByName("point_hurt");		// Create point_hurt
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
/******************* CLEAR HULK ENTITY *********************/
/***********************************************************/
stock ClearHulk(client)
{
	if (C_iClone[client])
	{
		new entity = EntRefToEntIndex(C_iClone[client]);
		if (entity != -1)
		{
			AcceptEntityInput(entity, "Kill", -1, -1, 0);
		}
		
		C_iClone[client]		= 0;
	}
	
	PlayerIsHulk[client]		= false;
	
	return false;
}

/***********************************************************/
/************************* SHIELD **************************/
/***********************************************************/
public Action:CreateShield(client)
{
	new ent = CreateEntityByName("prop_dynamic");
	if (ent == -1)
	{
		return Plugin_Handled;
	}
	
	SetEntityModel(ent, "models/infected/hulk/shield/shield.mdl");

	DispatchSpawn(ent);

	new Float:pos[3], Float:angle[3];
	GetClientAbsOrigin(client, pos);
	GetClientEyeAngles(client, angle);

	new Float:Direction[3];
	Direction[0] = pos[0];
	Direction[1] = pos[1];
	Direction[2] = pos[2];

	new Float:AmmoPos[3];

	new Handle:Trace = TR_TraceRayFilterEx(pos, Direction, MASK_SOLID, RayType_EndPoint, TraceFilterAll, client);
	TR_GetEndPosition(AmmoPos, Trace);
	CloseHandle(Trace);


	TeleportEntity(ent, AmmoPos, angle, NULL_VECTOR);


	//name the spider
	decl String:iTarget[16];
	Format(iTarget, 16, "client%d", client);
	DispatchKeyValue(client, "targetname", iTarget);
	
	new String:boxName[128];
	Format(boxName, sizeof(boxName), "shield%i", ent);
	DispatchKeyValue(ent, "targetname", iTarget);

	SetVariantString(iTarget);
	AcceptEntityInput(ent, "SetParent");
	
	HulkHaveShield[client] = EntIndexToEntRef(ent);
	
	return Plugin_Handled;
    
}

stock ClearShield(client)
{
	if (HulkHaveShield[client])
	{
		new entity = EntRefToEntIndex(HulkHaveShield[client]);
		if (entity != -1)
		{
			AcceptEntityInput(entity, "Kill", -1, -1, 0);
		}
		
		HulkHaveShield[client]		= 0;
	}
}

/***********************************************************/
/*********************** KNOCKBACK *************************/
/***********************************************************/

public Action:Timer_Attrack(Handle:timer, any:data)
{
	new Handle:kv 			= Handle:data;
	new client 				= KvGetNum(kv, "client", -1);
	new teleportself 		= KvGetNum(kv, "teleportself", -1);
	new Float:radius 		= KvGetFloat(kv, "radius");
	new Float:push 			= KvGetFloat(kv, "push");
	
	AttrackAll(client, bool:teleportself, radius, push);
}

public Action:Timer_DeleteAttrack(Handle:timer, any:client)
{
	ClearTimer(TimerHulkAttrack[client]);
}

AttrackAll(client, bool:teleportself, Float:radius_distance, Float:radius_push)
{
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] -= 10.0;
	
	for (new i = 1; i <= MaxClients; ++i) 
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(client) != GetClientTeam(i) && client != i)
		{
			new Float:pos[3], Float:vector[3];
			GetClientAbsOrigin(i, pos);
			pos[2] += 2.0;
			new Float:distance = GetVectorDistance(vec, pos);
			
			if (distance <= radius_distance)
			{
			
				GetClientEyePosition(i, pos);
				GetClientEyePosition(client, vec);
				
				MakeVectorFromPoints(pos, vec, vector);
				NormalizeVector(vector, vector);
				
				ScaleVector(vector, radius_push);
				if(teleportself)
				{
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vector);	
				}
				else
				{
					TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, vector);	
				}
			}
		}
	}
}

/***********************************************************/
/********************* TELEPORTATION ***********************/
/***********************************************************/
public Action:Timer_TeleportHulk(Handle:timer, any:data)
{
	new Handle:kv 					= Handle:data;
	new client 						= KvGetNum(kv, "client", -1);
	new Float:radius_distance 		= KvGetFloat(kv, "radius");
	
	TeleportHulk(client, Float:radius_distance);
}

TeleportHulk(client, Float:radius_distance)
{
	decl iClients[MaxClients];
	new numClients;
	
	for (new i = 1; i <= MaxClients; ++i) 
	{
		//if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(client) != GetClientTeam(i) && client != i)
		if(IsClientInGame(i) && IsPlayerAlive(i) && client != i)
		{
			new Float:origin[3], Float:target[3];
			GetClientAbsOrigin(client, origin);
			GetClientAbsOrigin(i, target);
			new Float:distance = GetVectorDistance(origin, target);
			
			if (distance <= radius_distance)
			{
				iClients[numClients++] = i;
				
				if(B_active_hulk_dev)
				{
					new String:name[MAX_NAME_LENGTH];
					GetClientName(i, name, sizeof(name));
					PrintToDev(B_active_hulk_dev, "%s client: %s is on range", TAG_CHAT, name);
				}
			}
		}
	}
	
	if (numClients)
    {
		if(IsClientInGame(numClients) && IsPlayerAlive(numClients))
		{
			new target_id = iClients[GetURandomInt() % numClients];
					
			new Float:target[3];
			//GetEntPropVector(target_id, Prop_Send, "m_vecOrigin", target);
			GetClientAbsOrigin(target_id, target);
			
			TeleportEntity(client, target, NULL_VECTOR, NULL_VECTOR);
			
			CPrintToChatAll("%t", "Hulk Teleport");
			
			if(B_active_hulk_dev)
			{
				new String:name[MAX_NAME_LENGTH];
				GetClientName(target_id, name, sizeof(name));
				PrintToDev(B_active_hulk_dev, "%s client :%i, target: %s", TAG_CHAT, client, name);
			}
		}
    }
		
}

/***********************************************************/
/*********************** TRACE FILTER***********************/
/***********************************************************/
public bool:TraceFilterAll(caller, contentsMask, any:SphereNum)
{
	new String:modelname[128];
	GetEntPropString(caller, Prop_Data, "m_ModelName", modelname, 128);
	
	new String:checkclass[64];
	GetEdictClassname(caller, checkclass,sizeof(checkclass));
	
	return !(StrEqual(checkclass, "player", false) ||(caller==SphereNum) || StrEqual(modelname, "models/infected/hulk_dlc3.mdl") || StrEqual(modelname, "models/infected/anim_hulk.mdl"));
}

/***********************************************************/
/*********************** VOICE RANDOM **********************/
/***********************************************************/
stock PlayRandomVoice(entity, bool:alive, const String:sound[][], min, max)
{
	new random = GetRandomInt(min, max);

	new String:S_sound_to_play[PLATFORM_MAX_PATH];
	Format(S_sound_to_play, PLATFORM_MAX_PATH, "*%s", sound[random]);
	
	PlaySound(entity, alive, S_sound_to_play);
}

/***********************************************************/
/************************ PLAY SOUND ***********************/
/***********************************************************/
stock PlaySound(entity, bool:alive, const String:sound[])
{
	decl newClients[MaxClients];
	new totalClients = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			newClients[totalClients++] = i;
		}
	}
	new Float:position[3];
	if(alive)
	{
		GetClientAbsOrigin(entity, position);
	}
	else
	{
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	}
	
	EmitSound(newClients, totalClients, sound, entity, SNDCHAN_ITEM, SNDLEVEL_SCREAMING, SND_NOFLAGS, 1.0, _, _, position);

	PrintToDev(B_active_hulk_dev, "%s Hulk sound : %s, Array clients: %i, Num. clients: %i", TAG_CHAT, sound, newClients, totalClients);
}

/***********************************************************/
/*********************** TURN OFF FIRE *********************/
/***********************************************************/
public ExtinguishPlayer(client)
{
	ExtinguishEntity(client);
	new iFireEnt = GetEntPropEnt(client, Prop_Data, "m_hEffectEntity");
	if (IsValidEntity(iFireEnt))
	{
		decl String:szClassName[64];
		GetEdictClassname(iFireEnt, szClassName, sizeof(szClassName));
		if (StrEqual(szClassName, "entityflame", false))
		{
			SetEntPropFloat(iFireEnt, Prop_Data, "m_flLifetime", 0.0);
		}
	}
}

/***********************************************************/
/*********************** SET PLAYER HULK *******************/
/***********************************************************/
SetPlayerHulk(client)
{
	CanWinParty = false;

	//CS_SwitchTeam(client, CS_TEAM_T);
	//CS_RespawnPlayer(client);
	ZRiot_Zombie(client);

	CreateHulk(client);

	CanWinParty = true;

	SetConVarInt(FindConVar("bot_quota"), 0);

	new String:name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));

	CPrintToChatAll("%t", "Hulk is player", name);
	
	CreateTimer(1.0, Timer_RemoveWeapons, client);
}

/***********************************************************/
/************************ SET BOT HULK *********************/
/***********************************************************/
SetBotHulk(client, option)
{
	CreateHulk(client);
	CreateTimer(1.0, Timer_RemoveWeapons, client);
	SetPlayerSpeed(client, F_hulk_speed_normal_bot);
	
	if(option ==1)
	{
		CPrintToChatAll("%t", "Hulk is bot", C_max_player_boss);
	}
	else if(option ==2)
	{
		CPrintToChatAll("%t", "Hulk is bot no human");
	}
}

/***********************************************************/
/****************** TIMER REMOVE WEAPONS *******************/
/***********************************************************/
public Action:Timer_RemoveWeapons(Handle:timer, any:client)
{ 
	Client_RemoveAllWeapons(client, "weapon_knife");
	GivePlayerItem(client, "weapon_knife");
}

/***********************************************************/
/************************ VOTE HULK ************************/
/***********************************************************/
BuildVoteHulk(client)
{
	decl String:title[40], String:yes[40], String:no[40];
	C_become_hulk[client] = 0;
	new Handle:menu = CreateMenu(BuildVoteHulk_Menu);
	SetMenuExitBackButton(menu, false);
	
	Format(yes, sizeof(yes), "%T", "Yes", client);
	Format(no, sizeof(no), "%T", "No", client);
	AddMenuItem(menu, "yes", yes);
	AddMenuItem(menu, "no", no);
	
	Format(title, sizeof(title), "%T", "Become Hulk Menu", client);
	SetMenuTitle(menu, title);
	
	DisplayMenu(menu, client, 20);
}

public BuildVoteHulk_Menu(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);	
		}
		case MenuAction_Select:
		{
			new String:menu1[56];
			GetMenuItem(menu, param2, menu1, sizeof(menu1));
			
			if(StrEqual(menu1, "yes"))
			{
				C_become_hulk[param1] = 1;
			}
			else if(StrEqual(menu1, "no"))
			{
				C_become_hulk[param1] = 0;
			}
		}
	}
}

/***********************************************************/
/*********************** VOT HULK **************************/
/***********************************************************/
VoteForHulk()
{
	for (new i = 1; i <= MaxClients; ++i) 
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == CS_TEAM_CT)
		{
			BuildVoteHulk(i);
		}
	}
}

/***********************************************************/
/*********************** RANDOM PLAYER *********************/
/***********************************************************/
stock GetRandomPlayerEx(team) 
{
	new clients[MaxClients+1], clientCount;
	for (new i = 1; i <= MaxClients; i++)
	{
		if(Client_IsIngame(i) && (GetClientTeam(i) == team) && C_become_hulk[i])
		{
			clients[clientCount++] = i;
		}
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}

/***********************************************************/
/******************* SET MOVE TYPE ALL *********************/
/***********************************************************/
SetPlayerMoveTypeAll(MoveType type)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if(Client_IsIngame(i) && IsPlayerAlive(i))
		{
			SetPlayerMoveType(i, type);
		}
	}
}