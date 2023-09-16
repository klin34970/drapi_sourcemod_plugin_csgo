#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <smlib>
#include <csgocolors>
#include <sdktools_entinput>
#include <sdktools_functions>
#include <clientprefs>

#define PLUGIN_VERSION "1.0.0"
#define CVARS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY
#define DEFAULT_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY

#define MAX_SPAWNS 200
#define MAX_CATEGORIES 16
#define MAX_HATS 256

enum Slots
{
	SlotPrimary,
	SlotSecondary,
	SlotKnife,
	SlotGrenade,
	SlotC4,
	SlotNone
};

enum Teams
{
	TeamNone,
	TeamSpectator,
	TeamT,
	TeamCT
};

enum ChatCommand {
	String:command[32],
	String:description[255]
}

enum HelpMenuType {
	HelpMenuType_List,
	HelpMenuType_Text
}

enum HelpMenu {
	String:HelpName[32],
	String:HelpTitle[128],
	HelpMenuType:HelpType,
	Handle:HelpItems,
	itemct
}

enum Hat
{
	String:Name[64],
	String:ModelPath[PLATFORM_MAX_PATH],
	Float:Position[3],
	Float:Angles[3],
	Flags,
	Team,
	Category
}

//Plugins parametres

/*Handle*/
new Handle:cvar_active;
new Handle:cvar_active_os;
new Handle:cvar_active_os_stats;
new Handle:cvar_active_deathmatch;
new Handle:cvar_active_laser;
new Handle:cvar_active_switch;
new Handle:cvar_active_glowhe;
new Handle:cvar_active_beamhe;
new Handle:cvar_active_knifes;
new Handle:cvar_active_he_stick_player;
new Handle:cvar_active_he_stick_wall;
new Handle:cvar_active_he_beacon;
new Handle:cvar_active_sounds;
new Handle:cvar_active_hats;
new Handle:cvar_active_hats_king;
new Handle:cvar_active_super_jump;

new Handle:cvar_dev;
new Handle:cvar_ammo;
new Handle:cvar_removeObjectives;
new Handle:cvar_removeWeapons;
new Handle:cvar_respawnTime;
new Handle:cvar_protection_time;
new Handle:cvar_he_radius;
new Handle:cvar_he_damage;
new Handle:cvar_consecutive_kill_continue_time;
new Handle:cvar_sounds_spree;
new Handle:cvar_sounds_rampage;
new Handle:cvar_sounds_unstoppable;
new Handle:cvar_sounds_domination;
new Handle:cvar_sounds_godlike;
new Handle:cvar_remove_hats = INVALID_HANDLE;

new Handle:mp_playercashawards;
new Handle:mp_teamcashawards;
new Handle:mp_friendlyfire;
new Handle:mp_autokick;
new Handle:mp_tkpunish;
new Handle:mp_teammates_are_enemies;
new Handle:ff_damage_reduction_bullets;
new Handle:ff_damage_reduction_grenade;
new Handle:ff_damage_reduction_other;
new Handle:ff_damage_reduction_grenade_self;
new Handle:sv_autobuyammo;
new Handle:mp_death_drop_gun;
new Handle:mp_solid_teammates;
new Handle:mp_maxrounds;
new Handle:mp_warmuptime;	
new Handle:mp_roundtime;
new Handle:mp_roundtime_hostage;
new Handle:mp_roundtime_defuse;
new Handle:mp_startmoney;	
new Handle:mp_timelimit;
new Handle:mp_freezetime;
new Handle:mp_buytime;
new Handle:mp_ignore_round_win_conditions;

new Handle:g_cookieLaser;
new Handle:g_cookieSwitch;
new Handle:g_cookieGlowHe;
new Handle:g_cookieBeamHe;
new Handle:g_cookieKnife;
new Handle:g_cookieMessages;
new Handle:g_cookieMessagesCMD;
new Handle:g_cookieSounds;
new Handle:g_cookieSoundsKillHs;
new Handle:g_cookieSoundsKillSpree;
new Handle:g_cookieSoundsKillRampage;
new Handle:g_cookieSoundsKillUnstoppable;
new Handle:g_cookieSoundsKillDomination;
new Handle:g_cookieSoundsKillGodlike;
new Handle:g_cookieSoundsKillDouble;
new Handle:g_cookieSoundsKillTriple;
new Handle:g_cookieSoundsKillMonster;
new Handle:g_cookieSoundsFirstPosition;
new Handle:g_cookieHats[MAX_CATEGORIES] 		 = {INVALID_HANDLE, ...};
new Handle:g_cookieColorDefaultTrail;
new Handle:g_cookieColorDefaultGlow;
new Handle:g_cookieColorDefaultKill;
new Handle:g_cookieColorDefaultHs;
new Handle:g_hLookupAttachment					 = INVALID_HANDLE;


/*Bool*/
new bool:H_active 								= false;
new bool:H_active_os 							= false;
new bool:H_active_os_stats 						= false;
new bool:H_active_deathmatch 					= false;
new bool:H_active_laser 						= false;
new bool:H_active_switch 						= false;
new bool:H_active_glowhe 						= false;
new bool:H_active_beamhe 						= false;
new bool:H_active_knifes 						= false;
new bool:H_active_he_stick_player 				= false;
new bool:H_active_he_stick_wall 				= false;
new bool:H_active_he_beacon 					= false;
new bool:H_active_sounds 						= false;
new bool:H_active_hats 							= false;
new bool:H_active_hats_king 					= false;
new bool:H_active_super_jump 					= false;

new bool:H_dev 									= false;
new bool:H_removeObjectives;
new bool:H_removeWeapons;
new bool:spawnPointOccupied[MAX_SPAWNS] 		= {false, ...};
new bool:lineOfSightSpawning;
new bool:playerMoved[MAXPLAYERS + 1] 			= { false, ... };
new bool:roundEnded 							= false;
new bool:inEditMode 							= false;
//new bool:g_bOverlayed 						= false;
new bool:H_remove_hats 							= false;
new bool:g_bHatView[MAXPLAYERS+1] 				= false;
new bool:TheRoundIsWarmUp						= false;

/*Float*/
new Float:H_respawnTime;
new Float:spawnPositions[MAX_SPAWNS][3];
new Float:spawnAngles[MAX_SPAWNS][3];
new Float:spawnDistanceFromEnemies;
new Float:eyeOffset[3] 							= { 0.0, 0.0, 64.0 };
new Float:spawnPointOffset[3] 					= { 0.0, 0.0, 20.0 };
new Float:H_spawnProtectionTime;
new Float:StartLaser[MAXPLAYERS+1][3];
new Float:EndLaser[MAXPLAYERS+1][3];
new Float:HeOrigin[3];
new Float:H_he_radius;
new Float:H_he_damage;
new Float:consecutivelyKill_Timer[MAXPLAYERS+1];

// Native backup variables
new backup_mp_startmoney;
new backup_mp_playercashawards;
new backup_mp_teamcashawards;
new backup_mp_friendlyfire;
new backup_mp_autokick;
new backup_mp_tkpunish;
new backup_mp_teammates_are_enemies;
new Float:backup_ff_damage_reduction_bullets;
new Float:backup_ff_damage_reduction_grenade;
new Float:backup_ff_damage_reduction_other;
new Float:backup_ff_damage_reduction_grenade_self;
new backup_sv_autobuyammo;
new backup_mp_death_drop_gun;
new backup_mp_solid_teammates;
new backup_mp_maxrounds;
new backup_mp_warmuptime;
new backup_mp_roundtime;
new backup_mp_roundtime_hostage;
new backup_mp_roundtime_defuse;
new backup_mp_timelimit;
new backup_mp_freezetime;
new backup_mp_buytime;
new backup_mp_ignore_round_win_conditions;

/*Custom*/
new H_ammo;
new Ammo[MAXPLAYERS+1];
new H_consecutive_kill_continue_time;
new DMG_KNIFE 									= 4100;
new DMG_HE 										= 64;
new DMG_HS 										= 1073745922;
new DMG_SHOT 									= 4098;
new spawnPointCount 							= 0;
new lineOfSightAttempts;
new ownerOffset;
new lastEditorSpawnPoint[MAXPLAYERS + 1] 		= { -1, ... };
new glowSprite;
new Laser[MAXPLAYERS+1] 						= false;
new Switch[MAXPLAYERS+1] 						= true;
new GlowHe[MAXPLAYERS+1] 						= false;
new BeamHe[MAXPLAYERS+1] 						= false;
new Messages[MAXPLAYERS+1] 						= true;
new MessagesCMD[MAXPLAYERS+1] 					= true;
new consecutivelyKill[MAXPLAYERS+1];
new EachHs[MAXPLAYERS+1];
new EachKill[MAXPLAYERS+1];
new PlayerIsFirst[MAXPLAYERS+1];
new PlayerIsAlreadyFirst[MAXPLAYERS+1] 			= false;
new PlayerHadNormalSkin[MAXPLAYERS+1] 			= false;
new PlayerHadKingSkin[MAXPLAYERS+1] 			= false;
new g_iHatCache[MAXPLAYERS+1][MAX_CATEGORIES];
new g_iHats[MAXPLAYERS+1][MAX_CATEGORIES];
new g_iDefaults[MAX_CATEGORIES] 				= {-1, ...};
new g_iNumHats 									= 0;
new g_iCategories 								= 0;
new g_eHats[MAX_HATS][Hat];
new String:g_sCategories[MAX_CATEGORIES][64];
new PlayerIsDead[MAXPLAYERS+1] 					= false;
new PlayerJustSpawn[MAXPLAYERS+1]				= false;

//Sounds
new Sounds[MAXPLAYERS+1] 						= true;
new SoundsKillDouble[MAXPLAYERS+1] 				= true;
new SoundsKillTriple[MAXPLAYERS+1] 				= true;
new SoundsKillMonster[MAXPLAYERS+1] 			= true;
new SoundsKillHs[MAXPLAYERS+1] 					= true;
new SoundsKillSpree[MAXPLAYERS+1] 				= true;
new SoundsKillRampage[MAXPLAYERS+1] 			= true;
new SoundsKillUnstoppable[MAXPLAYERS+1] 		= true;
new SoundsKillDomination[MAXPLAYERS+1] 			= true;
new SoundsKillGodlike[MAXPLAYERS+1] 			= true;
new SoundsFirstPosition[MAXPLAYERS+1] 			= true;
new H_sound_spree;
new H_sound_rampage;
new H_sound_unstoppable;
new H_sound_domination;
new H_sound_godlike;
new Knifes[MAXPLAYERS+1] = 0;
new PlayerKing[MAXPLAYERS+1];
new He_Offset_Radius;
new He_Offset_Damage;
new He_Offset_Thrower;

//Super Jump
new Float:JumpTime[MAXPLAYERS+1];
new bool:Jumped[MAXPLAYERS+1];
new LastButton[MAXPLAYERS+1];
new Handle:cvar_super_jump_xy_mult = INVALID_HANDLE;
new Handle:cvar_super_jump_z_mult = INVALID_HANDLE;
new Handle:cvar_super_jump_damage = INVALID_HANDLE;
new Handle:cvar_super_jump_xy_mult2 = INVALID_HANDLE;
new Handle:cvar_super_jump_z_mult2 = INVALID_HANDLE;
new Handle:cvar_super_jump_damage2 = INVALID_HANDLE;
new Handle:cvar_super_jump_tick = INVALID_HANDLE;
new Super_Jump_iVelocity;

new Float:H_super_jump_z_mult;
new Float:H_super_jump_xy_mult;
new H_super_jump_damage;
new Float:H_super_jump_z_mult2;
new Float:H_super_jump_xy_mult2;
new H_super_jump_damage2;
new Float:H_super_jump_tick;

//Colors	

new ColorDefaultTrail[MAXPLAYERS+1][4];
new ColorDefaultGlow[MAXPLAYERS+1][4];
new ColorDefaultKill[MAXPLAYERS+1][4];
new ColorDefaultHs[MAXPLAYERS+1][4];

new ColorBeamHe[MAXPLAYERS+1];
new ColorGlowHe[MAXPLAYERS+1];
new ColorKill[MAXPLAYERS+1];
new ColorHs[MAXPLAYERS+1];

new ColorDefault[] 								= {255,255,255,255};
new ColorAqua[] 								= {0,255,255,255};
new ColorBlack[]								= {1,1,1,255};
new ColorBlue[] 								= {0,0,255,255};
new ColorFuschia[] 								= {255,0,255,255};
new ColorGray[] 								= {128,128,128,255};
new ColorGreen[] 								= {0,128,0,255};
new ColorLime[] 								= {0,255,0,255};
new ColorMaroon[] 								= {128,0,0,255};
new ColorNavy[] 								= {0,0,128,255};
new ColorRed[] 									= {255,0,0,255};
new ColorWhite[] 								= {255,255,255,255};
new ColorYellow[]								= {255,255,0,255};
new ColorSilver[]								= {192,192,192,255};
new ColorTeal[]									= {0,128,128,255};
new ColorPurple[]								= {128,0,128,255};
new ColorOlive[]								= {128,128,0,255};

// Spawn stats
new numberOfPlayerSpawns 						= 0;
new losSearchAttempts 							= 0;
new losSearchSuccesses 							= 0;
new losSearchFailures							= 0;
new distanceSearchAttempts 						= 0;
new distanceSearchSuccesses 					= 0;
new distanceSearchFailures 						= 0;
new spawnPointSearchFailures 					= 0;

//Stats
new StatsHS[MAXPLAYERS+1] 						= 0;
new StatsKILL[MAXPLAYERS+1] 					= 0;
new StatsHE[MAXPLAYERS+1] 						= 0;
new StatsKNIFE[MAXPLAYERS+1] 					= 0;
new StatsKILLED[MAXPLAYERS+1] 					= 0;
new Backup_StatsHS[MAXPLAYERS+1] 				= 0;
new Backup_StatsKILL[MAXPLAYERS+1] 				= 0;
new Backup_StatsHE[MAXPLAYERS+1] 				= 0;
new Backup_StatsKNIFE[MAXPLAYERS+1] 			= 0;
new Backup_StatsKILLED[MAXPLAYERS+1] 			= 0;

//Downloader
new Handle:g_DownloaderEnabled					= INVALID_HANDLE;
new Handle:g_DownloaderSimple					= INVALID_HANDLE;
new Handle:g_DownloaderNormal					= INVALID_HANDLE;

new String:DowloaderMap[256];
new bool:downloadfiles							= true;
new String:mediatype[256];
new downloadtype;

//Help menu
new Handle:g_helpMenus 							= INVALID_HANDLE;
new Handle:g_mapArray 							= INVALID_HANDLE;
new g_mapSerial 								= -1;
new g_configLevel 								= -1;


//Weapons
new const String:g_weapons[38][] 				= {
													"weapon_ak47", 
													"weapon_aug", 
													"weapon_bizon", 
													"weapon_deagle", 
													"weapon_decoy", 
													"weapon_elite", 
													"weapon_famas", 
													"weapon_fiveseven", 
													"weapon_flashbang",
													"weapon_g3sg1", 
													"weapon_galilar", 
													"weapon_glock", 
													"weapon_hegrenade", 
													"weapon_hkp2000", 
													"weapon_incgrenade", 
													"weapon_knife", 
													"weapon_m249", 
													"weapon_m4a1",
													"weapon_mac10", 
													"weapon_mag7", 
													"weapon_molotov", 
													"weapon_mp7", 
													"weapon_mp9", 
													"weapon_negev", 
													"weapon_nova", 
													"weapon_p250", 
													"weapon_p90", 
													"weapon_sawedoff",
													"weapon_scar20", 
													"weapon_sg556", 
													"weapon_smokegrenade", 
													"weapon_ssg08", 
													"weapon_taser", 
													"weapon_tec9", 
													"weapon_ump45", 
													"weapon_xm1014",
													"weapon_awp",
													"weapon_m4a1_silencer"
													};
static const String:models[10][] 				= {
												"models/os/player/cowboy.mdl",
												"models/os/player/cowboy_1.mdl",
												"models/os/player/cowboy_2.mdl",
												"models/os/player/cowboy_3.mdl",
												"models/os/player/cowboy_4.mdl",
												"models/os/player/cowboy_5.mdl",
												"models/os/player/cowboy_6.mdl",
												"models/os/player/cowboy_7.mdl",
												"models/os/player/cowboy_8.mdl",
												"models/os/player/cowboy_9.mdl"
												};
									
static String:MDL_SKIN_KING[] 				= "models/os/player/cowboy_king.mdl";

//static String:MDL_CROWN[] 				= "models/os/hat/crown/crown.mdl";
								
//static String:SND_KILL_COMBO[] 			= "os/kill/combowhore.mp3";
static String:SND_KILL_DOMINATION[] 		= "os/kill/dominating.mp3";
static String:SND_KILL_DOUBLE[] 			= "os/kill/double_kill.mp3";
//static String:SND_KILL_FIRST[] 			= "os/kill/firstblood.mp3";
static String:SND_KILL_GODLIKE[] 			= "os/kill/godlike.mp3";
static String:SND_KILL_HOLYSHIT[] 			= "os/kill/holyshit.mp3";
static String:SND_KILL_SPREE[] 				= "os/kill/killing_spree.mp3";
//static String:SND_KILL_MEGAKILL[] 		= "os/kill/megakill.mp3";
static String:SND_KILL_MONSTER[] 			= "os/kill/monster_kill.mp3";
//static String:SND_KILL_OWNED[] 			= "os/kill/ownage.mp3";
static String:SND_KILL_RAMPAGE[] 			= "os/kill/rampage.mp3";
static String:SND_KILL_TRIPLE[] 			= "os/kill/triple_kill.mp3";
//static String:SND_KILL_ULTRA[] 			= "os/kill/ultrakill.mp3";
static String:SND_KILL_UNSTOPPABLE[] 		= "os/kill/unstoppable.mp3";
static String:SND_KILL_WHICKEDSICK[] 		= "os/kill/whickedsick.mp3";
static String:SND_BEEP[] 					= "buttons/blip1.wav";
	
static String:M_PURPLELASER[] 				= "materials/sprites/purplelaser1.vmt";
static String:M_HALO01[] 					= "materials/sprites/halo01.vmt";
static String:M_LASERBEAM[] 				= "materials/sprites/laserbeam.vmt";
//static String:S_BLUEGLOW1[] 				= "sprites/blueglow1.vmt";

new M_PURPLELASER_PRECACHED;
new M_HALO01_PRECACHED;
new M_LASERBEAM_PRECACHED;
//new S_BLUEGLOW1_PRECACHED;

/***********************************************************/
/************************ INFOS PLUGIN **********************/
/***********************************************************/
public Plugin:myinfo =
{
	name = "One Shot Mode",
	author = "De Battista Clint",
	description = "Deagle mode by DoYou.Watch",
	version = PLUGIN_VERSION,
	url = "http://doyou.watch"
};

/**********************************************************************************************************************/
/************************************************** EVENTS SOURCEMOD **************************************************/
/**********************************************************************************************************************/


/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public OnPluginStart()
{
	//Chargement traduction
	LoadTranslations("os.phrases");
	
	//Generals
	CreateConVar("os_version", PLUGIN_VERSION, "os_mode", CVARS);
	cvar_active = CreateConVar("os_active", "1", "Enable/Disable OS mode", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	cvar_active_os = CreateConVar("os_active_one_shot", "1", "Enable/Disable One Shot", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	cvar_active_os_stats = CreateConVar("os_active_one_shot_stats", "1", "Enable/Disable One Shot Stats", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	cvar_active_deathmatch = CreateConVar("os_active_deathmatch", "1", "Enable/Disable Deathmatch", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	cvar_active_laser = CreateConVar("os_active_laser", "1", "Enable/Disable Laser", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	cvar_active_switch = CreateConVar("os_active_switch", "1", "Enable/Disable Switch", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	cvar_active_glowhe = CreateConVar("os_active_glowhe", "1", "Enable/Disable GlowHe", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	cvar_active_beamhe = CreateConVar("os_active_beamhe", "1", "Enable/Disable GlowHe", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	cvar_active_knifes = CreateConVar("os_active_knifes", "1", "Enable/Disable Knifes Skins", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	cvar_active_he_stick_player = CreateConVar("os_active_he_stick_player", "1", "Enable/Disable HE Stick Player", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	cvar_active_he_stick_wall = CreateConVar("os_active_he_stick_wall", "0", "Enable/Disable He Stick Wall", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	cvar_active_he_beacon = CreateConVar("os_active_he_beacon", "1", "Enable/Disable He Stick Wall", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	cvar_active_sounds = CreateConVar("os_active_sounds", "1", "Enable/Disable Sounds", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	cvar_active_hats = CreateConVar("os_active_hats", "1", "Enable/Disable Sounds", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	cvar_active_hats_king = CreateConVar("os_active_hats_king", "1", "Enable/Disable Sounds", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	cvar_active_super_jump = CreateConVar("os_active_super_jump", "1", "Enable/Disable Super Jump", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	
	
	cvar_dev = CreateConVar("os_dev", "0", "Enable/Disable Developpement mode", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	cvar_ammo = CreateConVar("os_ammo", "1", "Total ammo allowed", DEFAULT_FLAGS, true, 0.0);
	
	//Sounds
	cvar_consecutive_kill_continue_time = CreateConVar("os_consecutive_kill_continue_time", "1.0", "Time to make multikill", DEFAULT_FLAGS, true, 0.0);
	cvar_sounds_spree = CreateConVar("os_sound_spree", "6", "How many kills to play the sound", DEFAULT_FLAGS, true, 0.0);
	cvar_sounds_rampage = CreateConVar("os_sound_rampage", "7", "How many kills to play the sound", DEFAULT_FLAGS, true, 0.0);
	cvar_sounds_unstoppable = CreateConVar("os_sound_unstoppable", "10", "How many kills to play the sound", DEFAULT_FLAGS, true, 0.0);
	cvar_sounds_domination = CreateConVar("os_sound_domination", "14", "How many kills to play the sound", DEFAULT_FLAGS, true, 0.0);
	cvar_sounds_godlike = CreateConVar("os_sound_godlike", "18", "How many kills to play the sound", DEFAULT_FLAGS, true, 0.0);
	
	//Deatmatch
	decl String:spawnsPath[] = "addons/sourcemod/configs/os/spawns/";
	if (!DirExists(spawnsPath))
	{
		CreateDirectory(spawnsPath, 711);
	}
	cvar_removeObjectives = CreateConVar("os_remove_objectif", "1", "Remove/Disable C4/Site bomb", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	cvar_removeWeapons = CreateConVar("os_remove_weapons", "1", "Remove/Disable C4/Site bomb", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	cvar_respawnTime = CreateConVar("os_respawn_time", "2.0", "Remove/Disable C4/Site bomb", DEFAULT_FLAGS, true, 0.0);
	cvar_protection_time = CreateConVar("os_protection_time", "1.0", "Spawn protection time.", DEFAULT_FLAGS, true, 0.0);
	
	//He damage
	cvar_he_radius = CreateConVar("os_he_radius", "125", "Radius He Grenade", DEFAULT_FLAGS, true, 0.0);
	cvar_he_damage = CreateConVar("os_he_damage", "10000", "Damage He Grenade", DEFAULT_FLAGS, true, 0.0);
	He_Offset_Radius = FindSendPropOffs("CBaseGrenade", "m_DmgRadius");
	He_Offset_Damage = FindSendPropOffs("CBaseGrenade", "m_flDamage");
	He_Offset_Thrower = FindSendPropOffs("CBaseGrenade", "m_hThrower"); 
	
	//Hats
	cvar_remove_hats = CreateConVar("os_hats_remove", "1", "Whether to remove hats on death");
	
	//Super Jump
	cvar_super_jump_z_mult = CreateConVar("os_jump_zmult", "1.0", "Vertical Acceleration", FCVAR_PLUGIN);
	cvar_super_jump_xy_mult = CreateConVar("os_jump_xymult", "1.3", "Horizontal Acceleration", FCVAR_PLUGIN);
	cvar_super_jump_damage = CreateConVar("os_jump_damage", "0", "how many health lost when use supper Qing Gong", FCVAR_PLUGIN);
	cvar_super_jump_z_mult2 = CreateConVar("os_jump_zmult2", "1.3", "supper Qing Gong Vertical Acceleration", FCVAR_PLUGIN);
	cvar_super_jump_xy_mult2 = CreateConVar("os_jump_xymult2", "1.0", "supper Qing Gong Horizontal Acceleration", FCVAR_PLUGIN);
	cvar_super_jump_damage2 = CreateConVar("os_jump_damage2", "0", "how many health lost when supper use Qing Gong", FCVAR_PLUGIN);
	cvar_super_jump_tick = CreateConVar("os_jump_tick", "0.1", "use difficulty more small more difficult ", FCVAR_PLUGIN);
	Super_Jump_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
	
	//Downloader
	g_DownloaderSimple = CreateConVar("sm_downloader_simple","1", "Simple Download", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	g_DownloaderNormal = CreateConVar("sm_downloader_normal","1", "Normal Download", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	g_DownloaderEnabled = CreateConVar("sm_downloader_enabled","1", "Enable Download", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	
	//Help menu
	new String:hc[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, hc, sizeof(hc), "configs/os/help/menu.cfg");
	g_mapArray = CreateArray(32);
	ParseConfigFile(hc);
	
	// Les events
	HookEvent("round_start", RoundStart_Event);
	HookEvent("round_end", RoundEnd_Event);
	HookEvent("cs_win_panel_match", RoundEndPanel_Event);
	HookEvent("player_spawn", PlayerSpawn_Event);
	HookEvent("player_death", PlayerDeath_Event, EventHookMode_Pre);
	HookEvent("player_hurt", PlayerHurt_Event);
	HookEvent("weapon_fire_on_empty", WeaponFireOnEmpty_Event);
	HookEvent("bullet_impact", BulletImpact_Event, EventHookMode_Pre);
	HookEvent("hegrenade_detonate", HegrenadeDetonate_Event, EventHookMode_Pre);
	HookEvent("round_prestart", Event_RoundPrestart, EventHookMode_PostNoCopy);
	HookEvent("bomb_pickup", BombPickup_Event);
	HookEvent("player_jump", PlayerJump_Event);
	
	//Cvars Event
	HookConVarChange(cvar_active, Event_CvarChange);
	HookConVarChange(cvar_active_os, Event_CvarChange);
	HookConVarChange(cvar_active_os_stats, Event_CvarChange);
	HookConVarChange(cvar_active_deathmatch, Event_CvarChange);
	HookConVarChange(cvar_active_laser, Event_CvarChange);
	HookConVarChange(cvar_active_switch, Event_CvarChange);
	HookConVarChange(cvar_active_glowhe, Event_CvarChange);
	HookConVarChange(cvar_active_beamhe, Event_CvarChange);
	HookConVarChange(cvar_active_he_stick_player, Event_CvarChange);
	HookConVarChange(cvar_active_he_stick_wall, Event_CvarChange);
	HookConVarChange(cvar_active_he_beacon, Event_CvarChange);
	HookConVarChange(cvar_active_sounds, Event_CvarChange);
	HookConVarChange(cvar_active_hats, Event_CvarChange);
	HookConVarChange(cvar_active_hats_king, Event_CvarChange);
	HookConVarChange(cvar_active_super_jump, Event_CvarChange);
	HookConVarChange(cvar_super_jump_z_mult, Event_CvarChange);
	HookConVarChange(cvar_super_jump_xy_mult, Event_CvarChange);
	HookConVarChange(cvar_super_jump_damage, Event_CvarChange);
	HookConVarChange(cvar_super_jump_z_mult2, Event_CvarChange);
	HookConVarChange(cvar_super_jump_xy_mult2, Event_CvarChange);
	HookConVarChange(cvar_super_jump_damage2, Event_CvarChange);
	HookConVarChange(cvar_super_jump_tick, Event_CvarChange);
	
	
	HookConVarChange(cvar_dev, Event_CvarChange);
	HookConVarChange(cvar_ammo, Event_CvarChange);
	HookConVarChange(cvar_removeObjectives, Event_CvarChange);
	HookConVarChange(cvar_removeWeapons, Event_CvarChange);
	HookConVarChange(cvar_respawnTime, Event_CvarChange);
	HookConVarChange(cvar_protection_time, Event_CvarChange);
	HookConVarChange(cvar_he_radius, Event_CvarChange);
	HookConVarChange(cvar_he_damage, Event_CvarChange);
	HookConVarChange(cvar_consecutive_kill_continue_time, Event_CvarChange);
	HookConVarChange(cvar_sounds_spree, Event_CvarChange);
	HookConVarChange(cvar_sounds_rampage, Event_CvarChange);
	HookConVarChange(cvar_sounds_unstoppable, Event_CvarChange);
	HookConVarChange(cvar_sounds_domination, Event_CvarChange);
	HookConVarChange(cvar_sounds_godlike, Event_CvarChange);
	HookConVarChange(cvar_remove_hats, Event_CvarChange);

	
	//Creation du CFG
	AutoExecConfig(true, "ossettings", "os");
	
	//User
	RegConsoleCmd("osrespawn", Event_JoinClass, "Respawn CMD");
	RegConsoleCmd("joinclass", Event_JoinClass);
	RegConsoleCmd("osjoin", Command_Join, "Join CMD");
	
	RegConsoleCmd("os", OSMenu, "Os menu general");
	RegConsoleCmd("ossettings", OSMenuSettings, "Open settings os menu");
	RegConsoleCmd("osstats", OSMenuStats, "Open setats os menu");
	RegConsoleCmd("osknifes", OSMenuKnifes, "Open knifes os menu");
	RegConsoleCmd("oshelp", OSMenuHelp, "Display the help menu.", FCVAR_PLUGIN);
	
	RegConsoleCmd("osadmins", Command_Admins, "Lists all admins");
	RegConsoleCmd("oslaser", Command_Laser, "Laser CMD");
	RegConsoleCmd("osswitch", Command_Switch, "Switch CMD");
	RegConsoleCmd("osheglow", Command_GlowHe, "GlowHe CMD");
	RegConsoleCmd("oshebeam", Command_BeamHe, "TrailHe CMD");
	RegConsoleCmd("osmsg", Command_Messages, "Message CMD");
	RegConsoleCmd("oscmd", Command_MessagesCMD, "Commands Messages CMD");
	RegConsoleCmd("ossounds", Command_Sounds, "Sounds CMD");
	RegConsoleCmd("osbest", Command_BestPlayerRound, "Best Player Round CMD");
	
	
	//Admin
	AddCommandListener(SayHook, "say"); 
	RegAdminCmd("ospawns", Command_SpawnMenu, ADMFLAG_CHANGEMAP, "Opens OS menu spawn.");
	RegAdminCmd("osweapon", smWeapon, ADMFLAG_BAN, "- <target> <weaponname>");
	RegAdminCmd("osweaponlist", smWeaponList, ADMFLAG_BAN, "- list of the weapon names");
	RegAdminCmd("oshats", Command_Hats, ADMFLAG_ROOT, "Open hats os menu");
	RegAdminCmd("oshatpos",	Command_HatsPos, ADMFLAG_ROOT, "Shows a menu allowing you to adjust the hat position (affects all hats/players)." );
	RegAdminCmd("oshatsize", Command_HatsSize, ADMFLAG_ROOT, "Shows a menu allowing you to adjust the hat size (affects all hats/players)." );
	RegAdminCmd("oshatang",	Command_HatsAng, ADMFLAG_ROOT, "Shows a menu allowing you to adjust the hat ang (affects all hats/players)." );
	RegAdminCmd("oshatview", Command_HatShow, ADMFLAG_ROOT, "Shows/Hide hat." );
	RegAdminCmd("oshatsdefault", Command_Default, ADMFLAG_ROOT, "Set hat defautl");
	RegAdminCmd("osresetstats", Command_ResetStats, ADMFLAG_CHANGEMAP, "Reset Stats." );
	RegAdminCmd("osrespawnall", Command_RespawnAll, ADMFLAG_CHANGEMAP, "Respawns all players.");  
	
	//Cvars
	mp_friendlyfire = FindConVar("mp_friendlyfire");
	mp_autokick = FindConVar("mp_autokick");
	mp_tkpunish = FindConVar("mp_tkpunish");
	mp_teammates_are_enemies = FindConVar("mp_teammates_are_enemies");
	mp_playercashawards = FindConVar("mp_playercashawards");
	mp_teamcashawards = FindConVar("mp_teamcashawards");
	ff_damage_reduction_bullets = FindConVar("ff_damage_reduction_bullets");
	ff_damage_reduction_grenade = FindConVar("ff_damage_reduction_grenade");
	ff_damage_reduction_other = FindConVar("ff_damage_reduction_other");
	ff_damage_reduction_grenade_self = FindConVar("ff_damage_reduction_grenade_self");
	sv_autobuyammo = FindConVar("sv_autobuyammo");
	mp_death_drop_gun = FindConVar("mp_death_drop_gun");
	mp_solid_teammates = FindConVar("mp_solid_teammates");
	mp_maxrounds = FindConVar("mp_maxrounds");
	mp_warmuptime = FindConVar("mp_warmuptime");	
	mp_roundtime = FindConVar("mp_roundtime");
	mp_roundtime_hostage = FindConVar("mp_roundtime_hostage");
	mp_roundtime_defuse	= FindConVar("mp_roundtime_defuse");
	mp_startmoney = FindConVar("mp_startmoney");	
	mp_timelimit = FindConVar("mp_timelimit");
	mp_freezetime = FindConVar("mp_freezetime");
	mp_buytime = FindConVar("mp_buytime");
	mp_ignore_round_win_conditions = FindConVar("mp_ignore_round_win_conditions");

	//Backup Cvars
	backup_mp_startmoney = GetConVarInt(mp_startmoney);
	backup_mp_playercashawards = GetConVarInt(mp_playercashawards);
	backup_mp_teamcashawards = GetConVarInt(mp_teamcashawards);
	backup_mp_friendlyfire = GetConVarInt(mp_friendlyfire);
	backup_mp_autokick = GetConVarInt(mp_autokick);
	backup_mp_tkpunish = GetConVarInt(mp_tkpunish);
	backup_mp_teammates_are_enemies = GetConVarInt(mp_teammates_are_enemies);
	backup_ff_damage_reduction_bullets = GetConVarFloat(ff_damage_reduction_bullets);
	backup_ff_damage_reduction_grenade = GetConVarFloat(ff_damage_reduction_grenade);
	backup_ff_damage_reduction_other = GetConVarFloat(ff_damage_reduction_other);
	backup_ff_damage_reduction_grenade_self = GetConVarFloat(ff_damage_reduction_grenade_self);
	
	backup_sv_autobuyammo = GetConVarInt(sv_autobuyammo);
	backup_mp_death_drop_gun = GetConVarInt(mp_death_drop_gun);
	backup_mp_solid_teammates = GetConVarInt(mp_solid_teammates);
	backup_mp_maxrounds = GetConVarInt(mp_maxrounds);
	backup_mp_warmuptime = GetConVarInt(mp_warmuptime);
	backup_mp_roundtime = GetConVarInt(mp_roundtime);
	backup_mp_roundtime_hostage = GetConVarInt(mp_roundtime_hostage);
	backup_mp_roundtime_defuse = GetConVarInt(mp_roundtime_defuse);
	backup_mp_timelimit = GetConVarInt(mp_timelimit);
	backup_mp_freezetime = GetConVarInt(mp_freezetime);
	backup_mp_buytime = GetConVarInt(mp_buytime);
	backup_mp_ignore_round_win_conditions = GetConVarInt(mp_ignore_round_win_conditions);
	
	//Variables
	ownerOffset = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
	
	//Cookies
	g_cookieLaser = RegClientCookie("Laser", "", CookieAccess_Private);
	g_cookieSwitch = RegClientCookie("Switch", "", CookieAccess_Private);
	g_cookieGlowHe = RegClientCookie("GlowHe", "", CookieAccess_Private);
	g_cookieBeamHe = RegClientCookie("GlowBeam", "", CookieAccess_Private);
	g_cookieKnife = RegClientCookie("Knifes", "", CookieAccess_Private);
	g_cookieMessages = RegClientCookie("Messages", "", CookieAccess_Private);
	g_cookieMessagesCMD = RegClientCookie("MessagesCMD", "", CookieAccess_Private);
	g_cookieSounds = RegClientCookie("Sounds", "", CookieAccess_Private);
	g_cookieSoundsKillHs = RegClientCookie("Sound Hs", "", CookieAccess_Private);
	g_cookieSoundsKillSpree = RegClientCookie("Sound Spree", "", CookieAccess_Private);
	g_cookieSoundsKillRampage = RegClientCookie("Sound Rampage", "", CookieAccess_Private);
	g_cookieSoundsKillUnstoppable = RegClientCookie("Sound Unstoppable", "", CookieAccess_Private);
	g_cookieSoundsKillDomination = RegClientCookie("Sound Domination", "", CookieAccess_Private);
	g_cookieSoundsKillGodlike = RegClientCookie("Sound Godlike", "", CookieAccess_Private);
	g_cookieSoundsKillDouble = RegClientCookie("Sound Double", "", CookieAccess_Private);
	g_cookieSoundsKillTriple = RegClientCookie("Sound Triple", "", CookieAccess_Private);
	g_cookieSoundsKillMonster = RegClientCookie("Sound Monster", "", CookieAccess_Private);
	g_cookieSoundsFirstPosition = RegClientCookie("Sound First", "", CookieAccess_Private);
	g_cookieColorDefaultTrail = RegClientCookie("Color Default Trail", "", CookieAccess_Private);
	g_cookieColorDefaultGlow = RegClientCookie("Color Default Glow", "", CookieAccess_Private);
	g_cookieColorDefaultKill = RegClientCookie("Color Default Kill", "", CookieAccess_Private);
	g_cookieColorDefaultHs = RegClientCookie("Color Default Hs", "", CookieAccess_Private);
	
	//Hats Config
	new String:tmp[64];
	for(new i=0;i<MAX_CATEGORIES;++i)
	{
		Format(tmp, 64, "EquippedHatSlot%d", i);
		g_cookieHats[i] = RegClientCookie(tmp, tmp, CookieAccess_Private);
	}
	new Handle:hGameConf = LoadGameConfigFile("hats.gamedata");
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "LookupAttachment");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	g_hLookupAttachment = EndPrepSDKCall();
	
	//Timers
	CreateTimer(10.0, Timer_RemoveGroundWeapons, INVALID_HANDLE, TIMER_REPEAT);
	CreateTimer(0.5, Timer_UpdateSpawnPointStatus, INVALID_HANDLE, TIMER_REPEAT);
	CreateTimer(0.5, Timer_CheckAmmoWeapons, INVALID_HANDLE, TIMER_REPEAT);
	CreateTimer(0.5, Timer_GetFirstPosition, INVALID_HANDLE, TIMER_REPEAT);
	CreateTimer(2.0, Timer_CheckSuicide, INVALID_HANDLE, TIMER_REPEAT);
	
}

/***********************************************************/
/************************ PLUGIN END ***********************/
/***********************************************************/
public OnPluginEnd()
{
	CloseHandle(g_DownloaderEnabled);
	CloseHandle(g_DownloaderSimple);
	CloseHandle(g_DownloaderNormal);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		DisableSpawnProtection(INVALID_HANDLE, i);
		for(new n=0;n<MAX_CATEGORIES;++n)
		{
			g_iHatCache[i][n]=-1;
		}
	}

	SetObjectives("Enable");
	RestoreCashState();
	DisableSettingsDeathmatch();
	DisableSettingsOS();

}

/***********************************************************/
/******************* WHEN CONFIG EXECUTED ******************/
/***********************************************************/
public OnConfigsExecuted()
{
	UpdateState();
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public OnMapStart()
{
	for (new i = 1; i < sizeof(models); i++)
	{
		PrecacheModel(models[i], true);
	}
	PrecacheModel(MDL_SKIN_KING, true);
	PrecacheSound(SND_BEEP, true);
	
	if(GetConVarInt(g_DownloaderEnabled) == 1)
	{
		if(GetConVarInt(g_DownloaderNormal) == 1) ReadDownloads();
		if(GetConVarInt(g_DownloaderSimple) == 1) ReadDownloadsSimple();
	}
	
	M_PURPLELASER_PRECACHED = PrecacheModel(M_PURPLELASER);
	M_HALO01_PRECACHED = PrecacheModel(M_HALO01);
	M_LASERBEAM_PRECACHED = PrecacheModel(M_LASERBEAM);
	//S_BLUEGLOW1_PRECACHED = PrecacheModel(S_BLUEGLOW1);
	
	LoadMapConfig();
	LoadHats();
			
	if(H_active)
	{
		SetCashState();
		new String:hc[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, hc, sizeof(hc), "configs/os/help/menu.cfg");
		ParseConfigFile(hc);
		
		if(H_active_os)
		{
			EnableSettingsOS();
			ResetAllSkins();
		}
	
		if(H_active_os_stats)
		{
			ResetAllStats();
			ResetAllBackupStats();
		}
		
		if(H_active_deathmatch)
		{
			EnableSettingsDeathmatch();
		
			if (H_removeObjectives)
			{
				SetObjectives("Disable");
				RemoveHostages();
			}

			if (spawnPointCount > 0)
			{
				for (new i = 0; i < spawnPointCount; i++)
				{
					spawnPointOccupied[i] = false;
				}
			}
		}
	}
}

/***********************************************************/
/********************* WHEN MAP END ************************/
/***********************************************************/
public OnMapEnd()
{
	if(H_active)
	{
		if(H_active_os_stats)
		{
			ResetAllStats();
			ResetAllBackupStats();
		}
		
		if(H_active_os)
		{
			ResetAllSkins();
		}
	}
}

/**********************************************************************************************************************/
/*************************************************** EVENTS CLIENT ****************************************************/
/**********************************************************************************************************************/

/***********************************************************/
/******************* WHEN CONFIG EXECUTED ******************/
/***********************************************************/
public OnClientPutInServer(client)
{
	if(H_active)
	{
		SetCookieClientColorKill(client);
		SetCookieClientColorHs(client);
		SetCookieClientColorHeGlow(client);
		SetCookieClientColorHeBeam(client);
		SetCookieClientSounds(client);
		SetCookieClientMSG(client);
		if(H_active_os_stats)
		{
			ResetStats(client);
		}
		if(H_active_os)
		{
			PlayerHadNormalSkin[client] = false;
			PlayerHadKingSkin[client] = false;
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
			SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
		}
		if(H_active_deathmatch)
		{
			SDKHook(client, SDKHook_PostThinkPost, Hook_OnPostThinkPost);
			SDKHook(client, SDKHook_PostThink, Hook_OnPostThink);
		}
	}
}

public OnClientPostAdminCheck(client)
{
	if(H_active)
	{
		if(H_active_os)
		{
			CreateTimer(20.0, Timer_WelcomeMsg, client, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(20.0, Timer_WelcomeMenu, client, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(20.0, MessagesPlugin, client, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(180.0, MessagesPlugin, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);	
		}
	}
}

public OnClientConnected(client)
{
	if(H_active)
	{
		if(H_active_hats)
		{
			for(new i=0;i<MAX_CATEGORIES;++i)
			{
				g_iHatCache[client][i]=-1;
			}
		}
	}
}

public OnClientDisconnect(client)
{
	if(H_active)
	{
		if(H_active_os_stats)
		{
			ResetStats(client);
			PlayerIsFirst[client] = false;
			PlayerIsAlreadyFirst[client] = false;
		}
		if(H_active_os)
		{
			PlayerHadNormalSkin[client] = false;
			PlayerHadKingSkin[client] = false;
			SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKUnhook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
			SDKUnhook(client, SDKHook_WeaponEquip, OnWeaponEquip);			
		}
		if(H_active_hats)
		{
			for(new i=0;i<MAX_CATEGORIES;++i)
			{
				g_iHatCache[client][i]=-1;
			}
			RemoveHats(client);
		}
		if(H_active_deathmatch)
		{
			SDKUnhook(client, SDKHook_PostThinkPost, Hook_OnPostThinkPost);
			SDKUnhook(client, SDKHook_PostThink, Hook_OnPostThink);
		}
	}
}

/***********************************************************/
/******************** WHEN COOKIE CACHED *******************/
/***********************************************************/
public OnClientCookiesCached(client)
{
	new String:value[16];
	GetClientCookie(client, g_cookieLaser, value, sizeof(value));
	if(strlen(value) > 0) Laser[client] = StringToInt(value);
	
	GetClientCookie(client, g_cookieSwitch, value, sizeof(value));
	if(strlen(value) > 0) Switch[client] = StringToInt(value);
	
	GetClientCookie(client, g_cookieGlowHe, value, sizeof(value));
	if(strlen(value) > 0) GlowHe[client] = StringToInt(value);
	
	GetClientCookie(client, g_cookieBeamHe, value, sizeof(value));
	if(strlen(value) > 0) BeamHe[client] = StringToInt(value);
	
	GetClientCookie(client, g_cookieKnife, value, sizeof(value));
	if(strlen(value) > 0) Knifes[client] = StringToInt(value);
	
	GetClientCookie(client, g_cookieMessages, value, sizeof(value));
	if(strlen(value) > 0) Messages[client] = StringToInt(value);
	
	GetClientCookie(client, g_cookieMessagesCMD, value, sizeof(value));
	if(strlen(value) > 0) MessagesCMD[client] = StringToInt(value);
	
	GetClientCookie(client, g_cookieSounds, value, sizeof(value));
	if(strlen(value) > 0) Sounds[client] = StringToInt(value);
	
	GetClientCookie(client, g_cookieSoundsKillHs, value, sizeof(value));
	if(strlen(value) > 0) SoundsKillHs[client] = StringToInt(value);
	
	GetClientCookie(client, g_cookieSoundsKillSpree, value, sizeof(value));
	if(strlen(value) > 0) SoundsKillSpree[client] = StringToInt(value);
	
	GetClientCookie(client, g_cookieSoundsKillRampage, value, sizeof(value));
	if(strlen(value) > 0) SoundsKillRampage[client] = StringToInt(value);
	
	GetClientCookie(client, g_cookieSoundsKillUnstoppable, value, sizeof(value));
	if(strlen(value) > 0) SoundsKillUnstoppable[client] = StringToInt(value);
	
	GetClientCookie(client, g_cookieSoundsKillDomination, value, sizeof(value));
	if(strlen(value) > 0) SoundsKillDomination[client] = StringToInt(value);
	
	GetClientCookie(client, g_cookieSoundsKillGodlike, value, sizeof(value));
	if(strlen(value) > 0) SoundsKillGodlike[client] = StringToInt(value);
	
	GetClientCookie(client, g_cookieSoundsKillDouble, value, sizeof(value));
	if(strlen(value) > 0) SoundsKillDouble[client] = StringToInt(value);
	
	GetClientCookie(client, g_cookieSoundsKillTriple, value, sizeof(value));
	if(strlen(value) > 0) SoundsKillTriple[client] = StringToInt(value);
	
	GetClientCookie(client, g_cookieSoundsKillMonster, value, sizeof(value));
	if(strlen(value) > 0) SoundsKillMonster[client] = StringToInt(value);
	
	GetClientCookie(client, g_cookieSoundsFirstPosition, value, sizeof(value));
	if(strlen(value) > 0) SoundsFirstPosition[client] = StringToInt(value);
	
	GetClientCookie(client, g_cookieColorDefaultKill, value, sizeof(value));
	if(strlen(value) > 0) ColorKill[client] = StringToInt(value);
	
	GetClientCookie(client, g_cookieColorDefaultHs, value, sizeof(value));
	if(strlen(value) > 0) ColorHs[client] = StringToInt(value);
	
	GetClientCookie(client, g_cookieColorDefaultGlow, value, sizeof(value));
	if(strlen(value) > 0) ColorGlowHe[client] = StringToInt(value);
	
	GetClientCookie(client, g_cookieColorDefaultTrail, value, sizeof(value));
	if(strlen(value) > 0) ColorBeamHe[client] = StringToInt(value);

	new String:model[PLATFORM_MAX_PATH];
	for(new i=0;i<MAX_CATEGORIES;++i)
	{
		GetClientCookie(client, g_cookieHats[i], model, sizeof(model));
		
		g_iHatCache[client][i] = ItemExists_Hat(model);
		
		if(g_iHatCache[client][i]==-1)
		{
			SetClientCookie(client, g_cookieHats[i], "");
			g_iHatCache[client][i]=g_iDefaults[i];
		}
	}
}

/**********************************************************************************************************************/
/*************************************************** EVENTS CS:GO *****************************************************/
/**********************************************************************************************************************/

/***********************************************************/
/******************** WHEN CVARS CHANGE ********************/
/***********************************************************/
public Event_CvarChange(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	UpdateState();
}

/***********************************************************/
/********************* WHEN ROUND START ********************/
/***********************************************************/
public RoundStart_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(H_active)
	{
		if(H_dev)
		{
			//PrintToChatAll("Objective : %s", Time);
		}
		
		if(H_active_os)
		{
			PlayerHadNormalSkin[client] = false;
			PlayerHadKingSkin[client] = false;
		}
		if(H_active_os_stats)
		{
			decl String:Time[192];
			decl String:WarmupTime[192];
			decl String:RoundTime[192];
			GetEventString(event, "timelimit", Time, sizeof(Time));
			
			IntToString(GetConVarInt(mp_warmuptime), WarmupTime, sizeof(WarmupTime));
			IntToString(GetConVarInt(mp_roundtime)*60, RoundTime, sizeof(RoundTime));
			
			//PrintToChatAll("info round: %s, warmup:%s", RoundTime, WarmupTime);
			
			if(TheRoundIsWarmUp)
			{
				ResetAllBackupStats();	
				ResetAllStats();	
				TheRoundIsWarmUp = false;					
			}
			
			if( !StrEqual(Time, RoundTime) )
			{	
				TheRoundIsWarmUp = true;
			}
		}
		if(H_active_deathmatch)
		{
			if (H_removeObjectives)
			{
				RemoveHostages();
			}
			if (H_removeWeapons)
			{
				Timer_RemoveGroundWeapons(INVALID_HANDLE);		
			}
		}
	}
}

/***********************************************************/
/********************* WHEN ROUND STOP *********************/
/***********************************************************/
public RoundEnd_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(H_active)
	{
		if(H_active_os_stats)
		{
			ResetAllStats();
			PlayerIsFirst[client] = false;
			PlayerIsAlreadyFirst[client] = false;
			PlayerHadNormalSkin[client] = false;
			PlayerHadKingSkin[client] = false;
			BuildStatsMenu(client);
		}
		if(H_active_deathmatch)
		{
			roundEnded = true;
		}
	}
}

/***********************************************************/
/******************** WHEN ROUND PRESTART ******************/
/***********************************************************/
public Action:Event_RoundPrestart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(H_active)
	{
		if(H_active_deathmatch)
		{
			roundEnded = false;
		}
	}
}

/***********************************************************/
/************** WHEN ROUND STOP AND SHOW PANEL *************/
/***********************************************************/
public RoundEndPanel_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(H_active)
	{
		if(H_active_os_stats)
		{
			BuildStatsMenu(client);
		}
	}
}

/***********************************************************/
/******************** WHEN PLAYER SPAWN ********************/
/***********************************************************/
public PlayerSpawn_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(H_active)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));

		if (IsClientInGame(client))
		{
			if (IsPlayerAlive(client))
			{
				if(H_active_deathmatch)
				{
					PlayerIsDead[client] = false;
					if (spawnPointCount > 0)
					{
						Ammo[client] = 1;
						MovePlayer(client);
					}
					if (H_spawnProtectionTime > 0.0)
					{
						EnableSpawnProtection(client);
					}
					
					if (H_removeObjectives)
					{
						StripC4(client);
					}
				}
				
				if(H_active_os)
				{
					PlayerJustSpawn[client] = true;
					//RandomSkins(client);
					CreateTimer(0.0, Timer_Ammo, client);
				}
				
				if(H_active_hats)
				{
					RemoveHats(client);
					CreateTimer(0.0, Timer_SpawnPostPost, client);
				}
			}
		}
	}
}

/***********************************************************/
/**************** WHEN WEAPON FIRE ON EMPTY ****************/
/***********************************************************/
public WeaponFireOnEmpty_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(H_active)
	{
		if(H_active_switch)
		{
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			new weapon_sec = GetPlayerWeaponSlot(client, _:SlotSecondary);
			new knife = GetPlayerWeaponSlot(client, _:SlotKnife);
			new ammo = Weapon_GetPrimaryClip(weapon_sec);

			if(!Switch[client])
			{
				if (IsClientInGame(client))
				{
					if (IsPlayerAlive(client))
					{
						if(Client_GetActiveWeapon(client) == weapon_sec)
						{
							if(ammo == 0)
							{
								new String:knife_classname[30];
								GetEntityClassname(knife, knife_classname, sizeof(knife_classname));
								
								Client_RemoveWeapon(client, knife_classname, true, false);
								Client_GiveWeapon(client, "weapon_knife", true);

								new newknife = GiveKnifes(client);
								SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", newknife);
								ChangeEdictState(client, FindDataMapOffs(client, "m_hActiveWeapon"));
							}
						}
					}
				}
			}
		}
	}
}

/***********************************************************/
/********************* WHEN PLAYER HURT ********************/
/***********************************************************/
public PlayerHurt_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(H_active)
	{
		new victimId = GetClientOfUserId(GetEventInt(event, "userid"));
		new health = GetClientHealth(victimId);
		
		if(health <= 0)
		{
			PlayerIsDead[victimId] = true;
		}
		//PrintToChat(victimId, "Partie du corps : %i", health);
	}
}

/***********************************************************/
/********************** WHEN PLAYER DIE ********************/
/***********************************************************/
public Action:PlayerDeath_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(H_active)
	{
		//declarations
		decl String:weapon[64];
		decl String:attackerName[128];
		decl String:victimName[128];
		
		//infos joueurs
		new victimId = GetClientOfUserId(GetEventInt(event, "userid"));
		new attackerId = GetClientOfUserId(GetEventInt(event, "attacker"));
		new victim = GetClientOfUserId(victimId);
		new attacker = GetClientOfUserId(attackerId);
		GetClientName(attacker, attackerName, sizeof(attackerName));
		GetClientName(victim, victimName, sizeof(victimName));	
		
		//infos events
		//new bool:headshot = GetEventBool(event, "headshot");
		new bool:penetrated = GetEventBool(event, "penetrated");
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		new grenade = GetPlayerWeaponSlot(attackerId, _:SlotGrenade);

		
		if(H_active_os)
		{
		
			if (penetrated)
			{
				if(grenade == -1)
				{
					GivePlayerItem(attackerId, "weapon_hegrenade");
				}
			}
			else
			{
				if(H_dev)
				{
					//PrintToChatAll("[MOD IN DEV] - Wall shot : %i", grenade);
					if(grenade == -1)
					{
						GivePlayerItem(attackerId, "weapon_hegrenade");
					}
				}
			}

			if(victimId)
			{
				CreateTimer(0.0, Timer_RemoveGroundWeapons, INVALID_HANDLE);
				PlayerHadNormalSkin[victimId] = false;
			}
		}
		
		if(H_active_deathmatch)
		{
			CreateTimer(H_respawnTime, Respawn, victimId);
		}

		if(H_active_hats)
		{
			RemoveHats(victimId);
		}
	}
	return Plugin_Continue;
}

/***********************************************************/
/****************** WHEN PLAYER PICKUP BOMB ****************/
/***********************************************************/
public BombPickup_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (H_active && H_active_deathmatch && H_removeObjectives)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		StripC4(client);
	}
}

/***********************************************************/
/********************** WHEN PLAYER JUMP *******************/
/***********************************************************/
public Action:PlayerJump_Event(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (!client) return;
	if (!IsClientInGame(client)) return;
	if (!IsPlayerAlive(client)) return;
	LastButton[client]=GetClientButtons(client);
	JumpTime[client]=GetEngineTime();
	Jumped[client]=true;
 }
 
/**********************************************************************************************************************/
/*************************************************** EVENTS SKHOOK ****************************************************/
/**********************************************************************************************************************/

/***********************************************************/
/******************** WHEN PLAYER SWITCH *******************/
/***********************************************************/
public Action:OnWeaponSwitch(client, weapon)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			new weapon_pri = GetPlayerWeaponSlot(client, _:SlotPrimary);
			new weapon_sec = GetPlayerWeaponSlot(client, _:SlotSecondary);
			new knife = GetPlayerWeaponSlot(client, _:SlotKnife);
			
			if(weapon_pri != -1 && !CheckCommandAccess(client, "", ADMFLAG_GENERIC ))
			{
				CreateTimer(0.0, Timer_Ammo, client);
			}
			
			if(weapon_sec == -1 || knife == -1)
			{
				CreateTimer(0.0, Timer_Ammo, client);
			}
			else if(weapon_sec)
			{
				decl String:weapon_name[32];
				GetEntityClassname(weapon_sec, weapon_name, 32);
				
				if (!StrEqual(weapon_name, "weapon_deagle"))
				{
					CreateTimer(0.0, Timer_Ammo, client);
				}	
			}
		}
	}
}

/***********************************************************/
/***************** WHEN PLAYER TAKE DAMAGE *****************/
/***********************************************************/
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if(H_active)
	{
		if(H_dev)
		{
			//PrintToChat(attacker, "[MOD IN DEV] - Damage type :%i", damagetype);
			if(damagetype == DMG_SHOT)
			{
				StatsKILL[attacker] = StatsKILL[attacker] + 1;
				Backup_StatsKILL[attacker] = Backup_StatsKILL[attacker] + 1;
				//PrintToChat(attacker, "[MOD IN DEV] - Kills :%i", StatsKILL[attacker]);
			}
			if(damagetype == DMG_KNIFE)
			{
				StatsKNIFE[attacker] = StatsKNIFE[attacker] + 1;
				Backup_StatsKNIFE[attacker] = Backup_StatsKNIFE[attacker] + 1;
				//PrintToChat(attacker, "[MOD IN DEV] - Knife :%i", StatsKNIFE[attacker]);
			}
			if(damagetype == DMG_HE)
			{
				StatsHE[attacker] = StatsHE[attacker] + 1;
				Backup_StatsHE[attacker] = Backup_StatsHE[attacker] + 1;
				//PrintToChat(attacker, "[MOD IN DEV] - Grenade :%i", StatsHE[attacker]);
			}
			if(damagetype == DMG_HS)
			{
				StatsHS[attacker] = StatsHS[attacker] + 1;
				Backup_StatsHS[attacker] = Backup_StatsHS[attacker] + 1;
				//PrintToChat(attacker, "[MOD IN DEV] - Headshot :%i", StatsHS[attacker]);
			}
		}
		if(H_active_hats)
		{
			if(!H_remove_hats)
			{
				if(GetClientHealth(victim)-damage<=0)
				{
					for(new i=0;i<MAX_CATEGORIES;++i)
					{
						if(IsValidEdict(g_iHats[victim][i]) && g_iHats[victim][i] > MaxClients)
						{
							new String:sModel[PLATFORM_MAX_PATH];
							GetEntPropString(g_iHats[victim][i], Prop_Data, "m_ModelName", sModel, PLATFORM_MAX_PATH);
							new Float:fPos[3];
							GetClientEyePosition(victim, fPos);
							
							new ent = CreateEntityByName("prop_physics");
							SetEntProp(ent, Prop_Data, "m_CollisionGroup", 2);
							SetEntityModel(ent, sModel);
							DispatchSpawn(ent);
							
							TeleportEntity(ent, fPos, NULL_VECTOR, damageForce);
						}
					}
				}	
			}
		}
		
		if(H_active_os)
		{
			if(IsClientInGame(victim) || IsClientInGame(attacker))
			{
				SoundsKill(attacker, victim, damagetype);			

				if(damagetype == DMG_SHOT)
				{
					if(!H_dev)
					{
						StatsKILL[attacker] = StatsKILL[attacker] + 1;
						StatsKILLED[victim] = StatsKILL[victim] + 1;
						Backup_StatsKILL[attacker] = Backup_StatsKILL[attacker] + 1;
						Backup_StatsKILLED[victim] = Backup_StatsKILL[victim] + 1;
					}		
				}

				if(damagetype == DMG_KNIFE)
				{
					if(!H_dev)
					{
						StatsKNIFE[attacker] = StatsKNIFE[attacker] + 1;
						StatsKILLED[victim] = StatsKILL[victim] + 1;
						Backup_StatsKNIFE[attacker] = Backup_StatsKNIFE[attacker] + 1;
						Backup_StatsKILLED[victim] = Backup_StatsKILL[victim] + 1;
					}			
				}
				
				if(damagetype == DMG_HE)
				{
					if(!H_dev)
					{
						StatsHE[attacker] = StatsHE[attacker] + 1;
						StatsKILLED[victim] = StatsKILL[victim] + 1;
						Backup_StatsHE[attacker] = Backup_StatsHE[attacker] + 1;
						Backup_StatsKILLED[victim] = Backup_StatsKILL[victim] + 1;
					}		
				}

				if(damagetype == DMG_HS)
				{
					if(!H_dev)
					{
						StatsHS[attacker] = StatsHS[attacker] + 1;
						StatsKILLED[victim] = StatsKILL[victim] + 1;
						Backup_StatsHS[attacker] = Backup_StatsHS[attacker] + 1;
						Backup_StatsKILLED[victim] = Backup_StatsKILL[victim] + 1;
					}	
				}
				
				if(IsClientValid(attacker) && IsPlayerAlive(attacker))
				{
					new weapon_sec = GetPlayerWeaponSlot(attacker, _:SlotSecondary);
					if(damagetype == DMG_SHOT || damagetype == DMG_KNIFE)
					{
						damage *= 700;
						
						if(Messages[attacker])
						{
							CPrintToChat(attacker, "%t", "Kill");
						}
						if(weapon_sec != -1)
						{
							Ammo[attacker] = Weapon_GetPrimaryClip(weapon_sec);
							Ammo[attacker] = Ammo[attacker] + 1;
							Weapon_SetPrimaryClip(weapon_sec, Ammo[attacker]);
							Client_SetWeaponPlayerAmmoEx(attacker, weapon_sec, 0, -1);
							
							if(H_active_laser)
							{
								if(Laser[attacker])
								{
									if(Client_GetActiveWeapon(attacker) == weapon_sec)
									{
										Setlaser(attacker, ColorDefaultKill[attacker]);
									}
								}
							}
							
							if(H_active_switch)
							{
								if(Switch[attacker])
								{
									if(Weapon_GetPrimaryClip(weapon_sec) != 0 && Ammo[attacker] == 1)
									{
										if(Client_GetActiveWeapon(attacker) != weapon_sec)
										{
											CreateTimer(0.5, Timer_RefillGun, attacker);
										}
									}
								}
							}
						}
						return Plugin_Changed;
					}
					else if (damagetype == DMG_HS)
					{
						damage *= 700;
						if(Messages[attacker])
						{
							CPrintToChat(attacker, "%t", "HSKill");
						}
						if(weapon_sec != -1)
						{
							if(H_active_laser)
							{
								if(Laser[attacker])
								{
									if(Client_GetActiveWeapon(attacker) == weapon_sec)
									{
										Setlaser(attacker, ColorDefaultHs[attacker]);
									}
								}
							}
							Ammo[attacker] = Weapon_GetPrimaryClip(weapon_sec);
							Ammo[attacker] = Ammo[attacker] + 2;
							Weapon_SetPrimaryClip(weapon_sec, Ammo[attacker]);
							Client_SetWeaponPlayerAmmoEx(attacker, weapon_sec, 0, -1);
						}
						return Plugin_Changed;
					}
					else if(damagetype == DMG_HE)
					{
						damage *= 700;
						if(Messages[attacker])
						{
							CPrintToChat(attacker, "%t", "HEKill");
						}
						if(weapon_sec != -1)
						{
							Ammo[attacker] = Weapon_GetPrimaryClip(weapon_sec);
							Ammo[attacker] = Ammo[attacker] + 1;
							Weapon_SetPrimaryClip(weapon_sec, Ammo[attacker]);
							Client_SetWeaponPlayerAmmoEx(attacker, weapon_sec, 0, -1);
							
							if(H_active_switch)
							{
								if(Switch[attacker])
								{
									if(Weapon_GetPrimaryClip(weapon_sec) != 0 && Ammo[attacker] == 1)
									{
										if(Client_GetActiveWeapon(attacker) != weapon_sec)
										{
											CreateTimer(0.5, Timer_RefillGun, attacker);
										}
									}
								}
							}
						}
						
						if(H_active_glowhe)
						{
							if(GlowHe[attacker])
							{
								setGlowHe(attacker, victim);
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
/****************** WEAPON ALLOWED TO USE ******************/
/***********************************************************/
public Action:OnWeaponEquip(client, weapon) 
{ 
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			new weapon_pri = GetPlayerWeaponSlot(client, _:SlotPrimary);
			new weapon_sec = GetPlayerWeaponSlot(client, _:SlotSecondary);
			new knife = GetPlayerWeaponSlot(client, _:SlotKnife);
			
			if(weapon_pri != -1 && !CheckCommandAccess(client, "", ADMFLAG_GENERIC ))
			{
				CreateTimer(0.0, Timer_Ammo, client);
			}
			
			if(weapon_sec == -1 || knife == -1)
			{
				CreateTimer(0.0, Timer_Ammo, client);
			}
			else if(weapon_sec)
			{
				decl String:weapon_name[32];
				GetEntityClassname(weapon_sec, weapon_name, 32);
				
				if (!StrEqual(weapon_name, "weapon_deagle"))
				{
					CreateTimer(0.0, Timer_Ammo, client);
				}	
			}
		}
	}
}

/**********************************************************************************************************************/
/**************************************************** CUSTOMS FUNCTIONS ***********************************************/
/**********************************************************************************************************************/

/***********************************************************/
/******************** FUNCTIONS GENERALS *******************/
/***********************************************************/
public Hook_OnPostThinkPost(client)
{
	SetEntPropString(client, Prop_Send, "m_szLastPlaceName", "");
}

public Hook_OnPostThink(client)
{
	SetEntPropEnt(client, Prop_Send, "m_bSpotted", 0);
}

ResetAllStats()
{
	for (new i = 0; i < MaxClients; i++)
	{
		ResetStats(i);
		PlayerIsFirst[i] = false;
		PlayerIsAlreadyFirst[i] = false;
	}
}

ResetAllBackupStats()
{
	for (new i = 0; i < MaxClients; i++)
	{
		ResetBackupStats(i);
	}
}

ResetAllSkins()
{
	for (new i = 0; i < MaxClients; i++)
	{
		PlayerHadNormalSkin[i] = false;
	}
}

ResetStats(client)
{
	StatsHS[client] = 0;
	StatsKILL[client] = 0;
	StatsHE[client] = 0;
	StatsKNIFE[client] = 0;
	StatsKILLED[client] = 0;
}

ResetBackupStats(client)
{
	Backup_StatsHS[client] = 0;
	Backup_StatsKILL[client] = 0;
	Backup_StatsHE[client] = 0;
	Backup_StatsKNIFE[client] = 0;
	Backup_StatsKILLED[client] = 0;
}

public Action:SayHook(client, const String:cmdsay[], args) 
{
	if(H_active)
	{
		new AdminId:AdminID = GetUserAdmin(client); 
		if(AdminID == INVALID_ADMIN_ID) 
			return Plugin_Continue; 
		 
		decl String:Named[MAX_NAME_LENGTH]; 
		decl String:Msg[256]; 
			 
		GetClientName(client, Named, sizeof(Named)); 
		GetCmdArgString(Msg, sizeof(Msg));
		
		Msg[strlen(Msg)-1] = '\0'; 
		
		if(Msg[0] == '/' || !Msg[1])
		{
			return Plugin_Handled;
		}  		
		
		CPrintToChatAllEx(client, "[\x04Admin\x01] \x07%s\x01: \x01%s", Named, Msg[1]); 
	}
	return Plugin_Handled; 
}  
SetCookieClientMSG(client)
{
	if(Messages[client] == -1)
	{
		Messages[client] = 1;
	}
	
	if(MessagesCMD[client] == -1)
	{
		MessagesCMD[client] = 1;
	}
	
}
SetCookieClientSounds(client)
{
	if(Sounds[client] == -1)
	{
		Sounds[client] = 1;
	}
	
	if(SoundsKillDouble[client] == -1)
	{
		SoundsKillDouble[client] = 1;
	}
	
	if(SoundsKillTriple[client] == -1)
	{
		SoundsKillTriple[client] = 1;
	}
	
	if(SoundsKillMonster[client] == -1)
	{
		SoundsKillMonster[client] = 1;
	}
	
	if(SoundsKillHs[client] == -1)
	{
		SoundsKillHs[client] = 1;
	}
	
	if(SoundsKillSpree[client] == -1)
	{
		SoundsKillSpree[client] = 1;
	}
	
	if(SoundsKillRampage[client] == -1)
	{
		SoundsKillRampage[client] = 1;
	}
	
	if(SoundsKillUnstoppable[client] == -1)
	{
		SoundsKillUnstoppable[client] = 1;
	}
	
	if(SoundsKillDomination[client] == -1)
	{
		SoundsKillDomination[client] = 1;
	}
	
	if(SoundsKillGodlike[client] == -1)
	{
		SoundsKillGodlike[client] = 1;
	}
	
	if(SoundsFirstPosition[client] == -1)
	{
		SoundsFirstPosition[client] = 1;
	}
}
SetCookieClientColorHs(client)
{
	if (ColorHs[client] == 1)
	{
		ColorDefaultHs[client][0] = ColorAqua[0];
		ColorDefaultHs[client][1] = ColorAqua[1];
		ColorDefaultHs[client][2] = ColorAqua[2];
		ColorDefaultHs[client][3] = ColorAqua[3];
	}
	else if (ColorHs[client] == 2)
	{
		ColorDefaultHs[client][0] = ColorBlack[0];
		ColorDefaultHs[client][1] = ColorBlack[1];
		ColorDefaultHs[client][2] = ColorBlack[2];
		ColorDefaultHs[client][3] = ColorBlack[3];
	}
	else if (ColorHs[client] == 3)
	{
		ColorDefaultHs[client][0] = ColorBlue[0];
		ColorDefaultHs[client][1] = ColorBlue[1];
		ColorDefaultHs[client][2] = ColorBlue[2];
		ColorDefaultHs[client][3] = ColorBlue[3];
	}
	else if (ColorHs[client] == 4)
	{
		ColorDefaultHs[client][0] = ColorFuschia[0];
		ColorDefaultHs[client][1] = ColorFuschia[1];
		ColorDefaultHs[client][2] = ColorFuschia[2];
		ColorDefaultHs[client][3] = ColorFuschia[3];
	}
	else if (ColorHs[client] == 5)
	{
		ColorDefaultHs[client][0] = ColorGreen[0];
		ColorDefaultHs[client][1] = ColorGreen[1];
		ColorDefaultHs[client][2] = ColorGreen[2];
		ColorDefaultHs[client][3] = ColorGreen[3];
	}
	else if (ColorHs[client] == 6)
	{
		ColorDefaultHs[client][0] = ColorGray[0];
		ColorDefaultHs[client][1] = ColorGray[1];
		ColorDefaultHs[client][2] = ColorGray[2];
		ColorDefaultHs[client][3] = ColorGray[3];
	}
	else if (ColorHs[client] == 7)
	{
		ColorDefaultHs[client][0] = ColorLime[0];
		ColorDefaultHs[client][1] = ColorLime[1];
		ColorDefaultHs[client][2] = ColorLime[2];
		ColorDefaultHs[client][3] = ColorLime[3];
	}
	else if (ColorHs[client] == 8)
	{
		ColorDefaultHs[client][0] = ColorMaroon[0];
		ColorDefaultHs[client][1] = ColorMaroon[1];
		ColorDefaultHs[client][2] = ColorMaroon[2];
		ColorDefaultHs[client][3] = ColorMaroon[3];
	}
	else if (ColorHs[client] == 9)
	{
		ColorDefaultHs[client][0] = ColorNavy[0];
		ColorDefaultHs[client][1] = ColorNavy[1];
		ColorDefaultHs[client][2] = ColorNavy[2];
		ColorDefaultHs[client][3] = ColorNavy[3];
	}
	else if (ColorHs[client] == 10)
	{
		ColorDefaultHs[client][0] = ColorOlive[0];
		ColorDefaultHs[client][1] = ColorOlive[1];
		ColorDefaultHs[client][2] = ColorOlive[2];
		ColorDefaultHs[client][3] = ColorOlive[3];
	}
	else if (ColorHs[client] == 11)
	{
		ColorDefaultHs[client][0] = ColorPurple[0];
		ColorDefaultHs[client][1] = ColorPurple[1];
		ColorDefaultHs[client][2] = ColorPurple[2];
		ColorDefaultHs[client][3] = ColorPurple[3];
	}
	else if (ColorHs[client] == 12)
	{
		ColorDefaultHs[client][0] = ColorRed[0];
		ColorDefaultHs[client][1] = ColorRed[1];
		ColorDefaultHs[client][2] = ColorRed[2];
		ColorDefaultHs[client][3] = ColorRed[3];
	}
	else if (ColorHs[client] == 13)
	{
		ColorDefaultHs[client][0] = ColorSilver[0];
		ColorDefaultHs[client][1] = ColorSilver[1];
		ColorDefaultHs[client][2] = ColorSilver[2];
		ColorDefaultHs[client][3] = ColorSilver[3];
	}
	else if (ColorHs[client] == 14)
	{
		ColorDefaultHs[client][0] = ColorTeal[0];
		ColorDefaultHs[client][1] = ColorTeal[1];
		ColorDefaultHs[client][2] = ColorTeal[2];
		ColorDefaultHs[client][3] = ColorTeal[3];
	}
	else if (ColorHs[client] == 15)
	{
		ColorDefaultHs[client][0] = ColorYellow[0];
		ColorDefaultHs[client][1] = ColorYellow[1];
		ColorDefaultHs[client][2] = ColorYellow[2];
		ColorDefaultHs[client][3] = ColorYellow[3];
	}
	else if (ColorHs[client] == 16)
	{
		ColorDefaultHs[client][0] = ColorWhite[0];
		ColorDefaultHs[client][1] = ColorWhite[1];
		ColorDefaultHs[client][2] = ColorWhite[2];
		ColorDefaultHs[client][3] = ColorWhite[3];
	}
	else
	{
		ColorDefaultHs[client][0] = ColorRed[0];
		ColorDefaultHs[client][1] = ColorRed[1];
		ColorDefaultHs[client][2] = ColorRed[2];
		ColorDefaultHs[client][3] = ColorRed[3];
		ColorHs[client] = 12;		
	}
}

SetCookieClientColorKill(client)
{
	if (ColorKill[client] == 1)
	{
		ColorDefaultKill[client][0] = ColorAqua[0];
		ColorDefaultKill[client][1] = ColorAqua[1];
		ColorDefaultKill[client][2] = ColorAqua[2];
		ColorDefaultKill[client][3] = ColorAqua[3];
	}
	else if (ColorKill[client] == 2)
	{
		ColorDefaultKill[client][0] = ColorBlack[0];
		ColorDefaultKill[client][1] = ColorBlack[1];
		ColorDefaultKill[client][2] = ColorBlack[2];
		ColorDefaultKill[client][3] = ColorBlack[3];
	}
	else if (ColorKill[client] == 3)
	{
		ColorDefaultKill[client][0] = ColorBlue[0];
		ColorDefaultKill[client][1] = ColorBlue[1];
		ColorDefaultKill[client][2] = ColorBlue[2];
		ColorDefaultKill[client][3] = ColorBlue[3];
	}
	else if (ColorKill[client] == 4)
	{
		ColorDefaultKill[client][0] = ColorFuschia[0];
		ColorDefaultKill[client][1] = ColorFuschia[1];
		ColorDefaultKill[client][2] = ColorFuschia[2];
		ColorDefaultKill[client][3] = ColorFuschia[3];
	}
	else if (ColorKill[client] == 5)
	{
		ColorDefaultKill[client][0] = ColorGreen[0];
		ColorDefaultKill[client][1] = ColorGreen[1];
		ColorDefaultKill[client][2] = ColorGreen[2];
		ColorDefaultKill[client][3] = ColorGreen[3];
	}
	else if (ColorKill[client] == 6)
	{
		ColorDefaultKill[client][0] = ColorGray[0];
		ColorDefaultKill[client][1] = ColorGray[1];
		ColorDefaultKill[client][2] = ColorGray[2];
		ColorDefaultKill[client][3] = ColorGray[3];
	}
	else if (ColorKill[client] == 7)
	{
		ColorDefaultKill[client][0] = ColorLime[0];
		ColorDefaultKill[client][1] = ColorLime[1];
		ColorDefaultKill[client][2] = ColorLime[2];
		ColorDefaultKill[client][3] = ColorLime[3];
	}
	else if (ColorKill[client] == 8)
	{
		ColorDefaultKill[client][0] = ColorMaroon[0];
		ColorDefaultKill[client][1] = ColorMaroon[1];
		ColorDefaultKill[client][2] = ColorMaroon[2];
		ColorDefaultKill[client][3] = ColorMaroon[3];
	}
	else if (ColorKill[client] == 9)
	{
		ColorDefaultKill[client][0] = ColorNavy[0];
		ColorDefaultKill[client][1] = ColorNavy[1];
		ColorDefaultKill[client][2] = ColorNavy[2];
		ColorDefaultKill[client][3] = ColorNavy[3];
	}
	else if (ColorKill[client] == 10)
	{
		ColorDefaultKill[client][0] = ColorOlive[0];
		ColorDefaultKill[client][1] = ColorOlive[1];
		ColorDefaultKill[client][2] = ColorOlive[2];
		ColorDefaultKill[client][3] = ColorOlive[3];
	}
	else if (ColorKill[client] == 11)
	{
		ColorDefaultKill[client][0] = ColorPurple[0];
		ColorDefaultKill[client][1] = ColorPurple[1];
		ColorDefaultKill[client][2] = ColorPurple[2];
		ColorDefaultKill[client][3] = ColorPurple[3];
	}
	else if (ColorKill[client] == 12)
	{
		ColorDefaultKill[client][0] = ColorRed[0];
		ColorDefaultKill[client][1] = ColorRed[1];
		ColorDefaultKill[client][2] = ColorRed[2];
		ColorDefaultKill[client][3] = ColorRed[3];
	}
	else if (ColorKill[client] == 13)
	{
		ColorDefaultKill[client][0] = ColorSilver[0];
		ColorDefaultKill[client][1] = ColorSilver[1];
		ColorDefaultKill[client][2] = ColorSilver[2];
		ColorDefaultKill[client][3] = ColorSilver[3];
	}
	else if (ColorKill[client] == 14)
	{
		ColorDefaultKill[client][0] = ColorTeal[0];
		ColorDefaultKill[client][1] = ColorTeal[1];
		ColorDefaultKill[client][2] = ColorTeal[2];
		ColorDefaultKill[client][3] = ColorTeal[3];
	}
	else if (ColorKill[client] == 15)
	{
		ColorDefaultKill[client][0] = ColorYellow[0];
		ColorDefaultKill[client][1] = ColorYellow[1];
		ColorDefaultKill[client][2] = ColorYellow[2];
		ColorDefaultKill[client][3] = ColorYellow[3];
	}
	else if (ColorKill[client] == 16)
	{
		ColorDefaultKill[client][0] = ColorWhite[0];
		ColorDefaultKill[client][1] = ColorWhite[1];
		ColorDefaultKill[client][2] = ColorWhite[2];
		ColorDefaultKill[client][3] = ColorWhite[3];
	}
	else
	{
		ColorDefaultKill[client][0] = ColorGreen[0];
		ColorDefaultKill[client][1] = ColorGreen[1];
		ColorDefaultKill[client][2] = ColorGreen[2];
		ColorDefaultKill[client][3] = ColorGreen[3];
		ColorKill[client] = 5;		
	}
}

SetCookieClientColorHeGlow(client)
{
	if (ColorGlowHe[client] == 1)
	{
		ColorDefaultGlow[client][0] = ColorAqua[0];
		ColorDefaultGlow[client][1] = ColorAqua[1];
		ColorDefaultGlow[client][2] = ColorAqua[2];
		ColorDefaultGlow[client][3] = ColorAqua[3];
	}
	else if (ColorGlowHe[client] == 2)
	{
		ColorDefaultGlow[client][0] = ColorBlack[0];
		ColorDefaultGlow[client][1] = ColorBlack[1];
		ColorDefaultGlow[client][2] = ColorBlack[2];
		ColorDefaultGlow[client][3] = ColorBlack[3];
	}
	else if (ColorGlowHe[client] == 3)
	{
		ColorDefaultGlow[client][0] = ColorBlue[0];
		ColorDefaultGlow[client][1] = ColorBlue[1];
		ColorDefaultGlow[client][2] = ColorBlue[2];
		ColorDefaultGlow[client][3] = ColorBlue[3];
	}
	else if (ColorGlowHe[client] == 4)
	{
		ColorDefaultGlow[client][0] = ColorFuschia[0];
		ColorDefaultGlow[client][1] = ColorFuschia[1];
		ColorDefaultGlow[client][2] = ColorFuschia[2];
		ColorDefaultGlow[client][3] = ColorFuschia[3];
	}
	else if (ColorGlowHe[client] == 5)
	{
		ColorDefaultGlow[client][0] = ColorGreen[0];
		ColorDefaultGlow[client][1] = ColorGreen[1];
		ColorDefaultGlow[client][2] = ColorGreen[2];
		ColorDefaultGlow[client][3] = ColorGreen[3];
	}
	else if (ColorGlowHe[client] == 6)
	{
		ColorDefaultGlow[client][0] = ColorGray[0];
		ColorDefaultGlow[client][1] = ColorGray[1];
		ColorDefaultGlow[client][2] = ColorGray[2];
		ColorDefaultGlow[client][3] = ColorGray[3];
	}
	else if (ColorGlowHe[client] == 7)
	{
		ColorDefaultGlow[client][0] = ColorLime[0];
		ColorDefaultGlow[client][1] = ColorLime[1];
		ColorDefaultGlow[client][2] = ColorLime[2];
		ColorDefaultGlow[client][3] = ColorLime[3];
	}
	else if (ColorGlowHe[client] == 8)
	{
		ColorDefaultGlow[client][0] = ColorMaroon[0];
		ColorDefaultGlow[client][1] = ColorMaroon[1];
		ColorDefaultGlow[client][2] = ColorMaroon[2];
		ColorDefaultGlow[client][3] = ColorMaroon[3];
	}
	else if (ColorGlowHe[client] == 9)
	{
		ColorDefaultGlow[client][0] = ColorNavy[0];
		ColorDefaultGlow[client][1] = ColorNavy[1];
		ColorDefaultGlow[client][2] = ColorNavy[2];
		ColorDefaultGlow[client][3] = ColorNavy[3];
	}
	else if (ColorGlowHe[client] == 10)
	{
		ColorDefaultGlow[client][0] = ColorOlive[0];
		ColorDefaultGlow[client][1] = ColorOlive[1];
		ColorDefaultGlow[client][2] = ColorOlive[2];
		ColorDefaultGlow[client][3] = ColorOlive[3];
	}
	else if (ColorGlowHe[client] == 11)
	{
		ColorDefaultGlow[client][0] = ColorPurple[0];
		ColorDefaultGlow[client][1] = ColorPurple[1];
		ColorDefaultGlow[client][2] = ColorPurple[2];
		ColorDefaultGlow[client][3] = ColorPurple[3];
	}
	else if (ColorGlowHe[client] == 12)
	{
		ColorDefaultGlow[client][0] = ColorRed[0];
		ColorDefaultGlow[client][1] = ColorRed[1];
		ColorDefaultGlow[client][2] = ColorRed[2];
		ColorDefaultGlow[client][3] = ColorRed[3];
	}
	else if (ColorGlowHe[client] == 13)
	{
		ColorDefaultGlow[client][0] = ColorSilver[0];
		ColorDefaultGlow[client][1] = ColorSilver[1];
		ColorDefaultGlow[client][2] = ColorSilver[2];
		ColorDefaultGlow[client][3] = ColorSilver[3];
	}
	else if (ColorGlowHe[client] == 14)
	{
		ColorDefaultGlow[client][0] = ColorTeal[0];
		ColorDefaultGlow[client][1] = ColorTeal[1];
		ColorDefaultGlow[client][2] = ColorTeal[2];
		ColorDefaultGlow[client][3] = ColorTeal[3];
	}
	else if (ColorGlowHe[client] == 15)
	{
		ColorDefaultGlow[client][0] = ColorYellow[0];
		ColorDefaultGlow[client][1] = ColorYellow[1];
		ColorDefaultGlow[client][2] = ColorYellow[2];
		ColorDefaultGlow[client][3] = ColorYellow[3];
	}
	else if (ColorGlowHe[client] == 16)
	{
		ColorDefaultGlow[client][0] = ColorWhite[0];
		ColorDefaultGlow[client][1] = ColorWhite[1];
		ColorDefaultGlow[client][2] = ColorWhite[2];
		ColorDefaultGlow[client][3] = ColorWhite[3];
	}
	else
	{
		ColorDefaultGlow[client][0] = ColorRed[0];
		ColorDefaultGlow[client][1] = ColorRed[1];
		ColorDefaultGlow[client][2] = ColorRed[2];
		ColorDefaultGlow[client][3] = ColorRed[3];
		ColorGlowHe[client] = 12;		
	}
}

SetCookieClientColorHeBeam(client)
{
	if (ColorBeamHe[client] == 1)
	{
		ColorDefaultTrail[client][0] = ColorAqua[0];
		ColorDefaultTrail[client][1] = ColorAqua[1];
		ColorDefaultTrail[client][2] = ColorAqua[2];
		ColorDefaultTrail[client][3] = ColorAqua[3];
	}
	else if (ColorBeamHe[client] == 2)
	{
		ColorDefaultTrail[client][0] = ColorBlack[0];
		ColorDefaultTrail[client][1] = ColorBlack[1];
		ColorDefaultTrail[client][2] = ColorBlack[2];
		ColorDefaultTrail[client][3] = ColorBlack[3];
	}
	else if (ColorBeamHe[client] == 3)
	{
		ColorDefaultTrail[client][0] = ColorBlue[0];
		ColorDefaultTrail[client][1] = ColorBlue[1];
		ColorDefaultTrail[client][2] = ColorBlue[2];
		ColorDefaultTrail[client][3] = ColorBlue[3];
	}
	else if (ColorBeamHe[client] == 4)
	{
		ColorDefaultTrail[client][0] = ColorFuschia[0];
		ColorDefaultTrail[client][1] = ColorFuschia[1];
		ColorDefaultTrail[client][2] = ColorFuschia[2];
		ColorDefaultTrail[client][3] = ColorFuschia[3];
	}
	else if (ColorBeamHe[client] == 5)
	{
		ColorDefaultTrail[client][0] = ColorGreen[0];
		ColorDefaultTrail[client][1] = ColorGreen[1];
		ColorDefaultTrail[client][2] = ColorGreen[2];
		ColorDefaultTrail[client][3] = ColorGreen[3];
	}
	else if (ColorBeamHe[client] == 6)
	{
		ColorDefaultTrail[client][0] = ColorGray[0];
		ColorDefaultTrail[client][1] = ColorGray[1];
		ColorDefaultTrail[client][2] = ColorGray[2];
		ColorDefaultTrail[client][3] = ColorGray[3];
	}
	else if (ColorBeamHe[client] == 7)
	{
		ColorDefaultTrail[client][0] = ColorLime[0];
		ColorDefaultTrail[client][1] = ColorLime[1];
		ColorDefaultTrail[client][2] = ColorLime[2];
		ColorDefaultTrail[client][3] = ColorLime[3];
	}
	else if (ColorBeamHe[client] == 8)
	{
		ColorDefaultTrail[client][0] = ColorMaroon[0];
		ColorDefaultTrail[client][1] = ColorMaroon[1];
		ColorDefaultTrail[client][2] = ColorMaroon[2];
		ColorDefaultTrail[client][3] = ColorMaroon[3];
	}
	else if (ColorBeamHe[client] == 9)
	{
		ColorDefaultTrail[client][0] = ColorNavy[0];
		ColorDefaultTrail[client][1] = ColorNavy[1];
		ColorDefaultTrail[client][2] = ColorNavy[2];
		ColorDefaultTrail[client][3] = ColorNavy[3];
	}
	else if (ColorBeamHe[client] == 10)
	{
		ColorDefaultTrail[client][0] = ColorOlive[0];
		ColorDefaultTrail[client][1] = ColorOlive[1];
		ColorDefaultTrail[client][2] = ColorOlive[2];
		ColorDefaultTrail[client][3] = ColorOlive[3];
	}
	else if (ColorBeamHe[client] == 11)
	{
		ColorDefaultTrail[client][0] = ColorPurple[0];
		ColorDefaultTrail[client][1] = ColorPurple[1];
		ColorDefaultTrail[client][2] = ColorPurple[2];
		ColorDefaultTrail[client][3] = ColorPurple[3];
	}
	else if (ColorBeamHe[client] == 12)
	{
		ColorDefaultTrail[client][0] = ColorRed[0];
		ColorDefaultTrail[client][1] = ColorRed[1];
		ColorDefaultTrail[client][2] = ColorRed[2];
		ColorDefaultTrail[client][3] = ColorRed[3];
	}
	else if (ColorBeamHe[client] == 13)
	{
		ColorDefaultTrail[client][0] = ColorSilver[0];
		ColorDefaultTrail[client][1] = ColorSilver[1];
		ColorDefaultTrail[client][2] = ColorSilver[2];
		ColorDefaultTrail[client][3] = ColorSilver[3];
	}
	else if (ColorBeamHe[client] == 14)
	{
		ColorDefaultTrail[client][0] = ColorTeal[0];
		ColorDefaultTrail[client][1] = ColorTeal[1];
		ColorDefaultTrail[client][2] = ColorTeal[2];
		ColorDefaultTrail[client][3] = ColorTeal[3];
	}
	else if (ColorBeamHe[client] == 15)
	{
		ColorDefaultTrail[client][0] = ColorYellow[0];
		ColorDefaultTrail[client][1] = ColorYellow[1];
		ColorDefaultTrail[client][2] = ColorYellow[2];
		ColorDefaultTrail[client][3] = ColorYellow[3];
	}
	else if (ColorBeamHe[client] == 16)
	{
		ColorDefaultTrail[client][0] = ColorWhite[0];
		ColorDefaultTrail[client][1] = ColorWhite[1];
		ColorDefaultTrail[client][2] = ColorWhite[2];
		ColorDefaultTrail[client][3] = ColorWhite[3];
	}
	else
	{
		ColorDefaultTrail[client][0] = ColorRed[0];
		ColorDefaultTrail[client][1] = ColorRed[1];
		ColorDefaultTrail[client][2] = ColorRed[2];
		ColorDefaultTrail[client][3] = ColorRed[3];
		ColorBeamHe[client] = 12;		
	}
}
UpdateState()
{
	H_active = GetConVarBool(cvar_active);
	H_active_os = GetConVarBool(cvar_active_os);
	H_active_os_stats = GetConVarBool(cvar_active_os_stats);
	H_active_deathmatch = GetConVarBool(cvar_active_deathmatch);
	H_active_laser = GetConVarBool(cvar_active_laser);
	H_active_switch = GetConVarBool(cvar_active_switch);
	H_active_glowhe = GetConVarBool(cvar_active_glowhe);
	H_active_beamhe = GetConVarBool(cvar_active_beamhe);
	H_active_knifes = GetConVarBool(cvar_active_knifes);
	H_active_he_stick_player = GetConVarBool(cvar_active_he_stick_player);
	H_active_he_stick_wall = GetConVarBool(cvar_active_he_stick_wall);
	H_active_he_beacon = GetConVarBool(cvar_active_he_beacon);
	H_active_sounds = GetConVarBool(cvar_active_sounds);
	H_active_hats = GetConVarBool(cvar_active_hats);
	H_active_hats_king = GetConVarBool(cvar_active_hats_king);
	H_active_super_jump = GetConVarBool(cvar_active_super_jump);
	
	H_dev = GetConVarBool(cvar_dev);
	H_ammo = GetConVarInt(cvar_ammo);
	H_consecutive_kill_continue_time = GetConVarInt(cvar_consecutive_kill_continue_time);
	H_removeObjectives = GetConVarBool(cvar_removeObjectives);
	H_removeWeapons = GetConVarBool(cvar_removeWeapons);
	H_respawnTime = GetConVarFloat(cvar_respawnTime);
	H_spawnProtectionTime = GetConVarFloat(cvar_protection_time);
	H_he_radius = GetConVarFloat(cvar_he_radius);
	H_he_damage = GetConVarFloat(cvar_he_damage);
	H_remove_hats = GetConVarBool(cvar_remove_hats);
	H_super_jump_z_mult = GetConVarFloat(cvar_super_jump_z_mult);
	H_super_jump_xy_mult = GetConVarFloat(cvar_super_jump_xy_mult);
	H_super_jump_damage = GetConVarInt(cvar_super_jump_damage);
	H_super_jump_z_mult2 = GetConVarFloat(cvar_super_jump_z_mult2);
	H_super_jump_xy_mult2 = GetConVarFloat(cvar_super_jump_xy_mult2);
	H_super_jump_damage2 = GetConVarInt(cvar_super_jump_damage2);
	H_super_jump_tick = GetConVarFloat(cvar_super_jump_tick);

	
	H_sound_spree = GetConVarInt(cvar_sounds_spree);
	H_sound_rampage = GetConVarInt(cvar_sounds_rampage);
	H_sound_unstoppable = GetConVarInt(cvar_sounds_unstoppable);
	H_sound_domination = GetConVarInt(cvar_sounds_domination);
	H_sound_godlike = GetConVarInt(cvar_sounds_godlike);
	
	if(H_active)
	{
		if(H_dev)
		{
			SetConVarInt(FindConVar("bot_quota"), 20);
		}
		
		SetCashState();
		if(H_active_os)
		{
			EnableSettingsOS();
		}
		
		if(H_active_os_stats)
		{
			ResetAllStats();
		}
		
		if(H_active_deathmatch)
		{
			EnableSettingsDeathmatch();
			decl String:status[10];
			status = (H_removeObjectives) ? "Disable" : "Enable";
			SetObjectives(status);
			
			if (H_removeObjectives)
			{
				RemoveC4();
			}
		}
		if(H_active_hats)
		{
			for( new i = 1; i <= MaxClients; i++ )
			{
				g_bHatView[i] = false;
			}
		}
	}
	else
	{
		RestoreCashState();
		DisableSettingsOS();
		DisableSettingsDeathmatch();
	}

}

EnableSettingsDeathmatch()
{

	SetConVarInt(mp_teammates_are_enemies, 1);
	SetConVarInt(mp_friendlyfire, 1);
	SetConVarInt(mp_autokick, 0);
	SetConVarInt(mp_tkpunish, 0);
	SetConVarFloat(ff_damage_reduction_bullets, 1.0);
	SetConVarFloat(ff_damage_reduction_grenade, 1.0);
	SetConVarFloat(ff_damage_reduction_other, 1.0);
	SetConVarFloat(ff_damage_reduction_grenade_self, 1.0);
	SetConVarInt(mp_ignore_round_win_conditions, 0);
	
}

EnableSettingsOS()
{
	SetConVarInt(sv_autobuyammo, 0);
	SetConVarInt(mp_death_drop_gun, 0);
	SetConVarInt(mp_solid_teammates, 1);
	SetConVarInt(mp_maxrounds, 1);
	SetConVarInt(mp_warmuptime, 30);
	SetConVarInt(mp_roundtime, 10);
	SetConVarInt(mp_timelimit, 10);
	SetConVarInt(mp_roundtime_hostage, 10);
	SetConVarInt(mp_roundtime_defuse, 10);
	SetConVarInt(mp_freezetime, 0);
	SetConVarInt(mp_buytime, 0);

}

DisableSettingsDeathmatch()
{
	SetConVarInt(mp_teammates_are_enemies, backup_mp_teammates_are_enemies);
	SetConVarInt(mp_friendlyfire, backup_mp_friendlyfire);
	SetConVarInt(mp_autokick, backup_mp_autokick);
	SetConVarInt(mp_tkpunish, backup_mp_tkpunish);
	SetConVarFloat(ff_damage_reduction_bullets, backup_ff_damage_reduction_bullets);
	SetConVarFloat(ff_damage_reduction_grenade, backup_ff_damage_reduction_grenade);
	SetConVarFloat(ff_damage_reduction_other, backup_ff_damage_reduction_other);
	SetConVarFloat(ff_damage_reduction_grenade_self, backup_ff_damage_reduction_grenade_self);
	SetConVarInt(mp_ignore_round_win_conditions, backup_mp_ignore_round_win_conditions);
}

DisableSettingsOS()
{
	SetConVarInt(sv_autobuyammo, backup_sv_autobuyammo);
	SetConVarInt(mp_death_drop_gun, backup_mp_death_drop_gun);
	SetConVarInt(mp_solid_teammates, backup_mp_solid_teammates);
	SetConVarInt(mp_maxrounds, backup_mp_maxrounds);
	SetConVarInt(mp_warmuptime, backup_mp_warmuptime);
	SetConVarInt(mp_roundtime, backup_mp_roundtime);
	SetConVarInt(mp_roundtime_hostage, backup_mp_roundtime_hostage);
	SetConVarInt(mp_roundtime_defuse, backup_mp_roundtime_defuse);
	SetConVarInt(mp_timelimit, backup_mp_timelimit);
	SetConVarInt(mp_freezetime, backup_mp_freezetime);
	SetConVarInt(mp_buytime, backup_mp_buytime);
}

RandomSkins(client) 
{
	if(IsClientValid(client))
	{
		if(IsPlayerAlive(client))
		{
			new Teams:clientTeam = Teams:GetClientTeam(client); 
			if(clientTeam == TeamT || clientTeam == TeamCT) 
			{ 
				if(!PlayerIsFirst[client])
				{

					new random = GetRandomInt(0, 9);
					SetEntityModel(client, models[random]);
					PlayerHadNormalSkin[client] = true;
					PlayerHadKingSkin[client] = true;

				}
				else
				{
					SetEntityModel(client, MDL_SKIN_KING);
					PlayerHadNormalSkin[client] = false;
					PlayerHadKingSkin[client] = true;
				}
			} 
		}
	}
}
SoundsKill(client, victim, damagetype)
{
	if(H_active)
	{
		if(H_active_sounds)
		{
			if(victim)
			{
				EachKill[victim] = 0;
			}
			new Float:now = GetEngineTime();
			
			if(consecutivelyKill_Timer[client] <= now)
			{
				consecutivelyKill[client] = 0;
			}
			
			consecutivelyKill_Timer[client] = GetEngineTime() + H_consecutive_kill_continue_time;
			consecutivelyKill[client] = consecutivelyKill[client] + 1;
			
			if(Sounds[client] && SoundsKillHs[client] && damagetype == DMG_HS)
			{
				EachHs[client] = EachHs[client] + 1;
				if(EachHs[client] == 1)
				{
					if(IsClientInGame(client) && !IsFakeClient(client))
					{
						ClientCommand(client, "play *%s", SND_KILL_HOLYSHIT);
					}
					EachHs[client] = 0;
				}
			}	
			EachKill[client] = EachKill[client]  + 1;
			
			if(H_dev)
			{
				//PrintToChat(client, "eachkill: %i", EachKill[client]);
				//PrintToChat(client, "Time: %i, kill: %i", now, consecutivelyKill[client]);
			}

			if(IsClientValid(client))
			{
				if(!IsFakeClient(client))
				{
					if(EachKill[client] == H_sound_spree && Sounds[client] && SoundsKillSpree[client])
					{
						ClientCommand(client, "play *%s", SND_KILL_SPREE);
					}

					if(EachKill[client] == H_sound_rampage && Sounds[client] && SoundsKillRampage[client])
					{
						ClientCommand(client, "play *%s", SND_KILL_RAMPAGE);
					}

					if(EachKill[client] == H_sound_unstoppable && Sounds[client] && SoundsKillUnstoppable[client])
					{
						ClientCommand(client, "play *%s", SND_KILL_UNSTOPPABLE);
					}

					if(EachKill[client] == H_sound_domination && Sounds[client] && SoundsKillDomination[client])
					{
						ClientCommand(client, "play *%s", SND_KILL_DOMINATION);
					}
					
					if(EachKill[client] == H_sound_godlike && Sounds[client] && SoundsKillGodlike[client])
					{
						ClientCommand(client, "play *%s", SND_KILL_GODLIKE);
					}

					
					
					if(consecutivelyKill[client] == 2 && !isplayerKillingSpree(client) && Sounds[client] && SoundsKillDouble[client])
					{
						ClientCommand(client, "play *%s", SND_KILL_DOUBLE);
					}
					
					if(consecutivelyKill[client] == 3 && !isplayerKillingSpree(client) && Sounds[client] && SoundsKillTriple[client])
					{
						ClientCommand(client, "play *%s", SND_KILL_TRIPLE);
					}
					
					if(consecutivelyKill[client] == 4 && !isplayerKillingSpree(client) && Sounds[client] && SoundsKillMonster[client])
					{
						ClientCommand(client, "play *%s", SND_KILL_MONSTER);
					}
				}
			}
		}
	}
}

isplayerKillingSpree(attacker)
{
	if(EachKill[attacker] == 4 || EachKill[attacker] == 5 || EachKill[attacker] == 7 || EachKill[attacker] == 10 || EachKill[attacker] == 14 )
	{
		return 1;
	}
	else{
		return 0;
	}
}

public Action:Timer_CheckSuicide(Handle:timer)
{
	if(H_active)
	{
		if(H_active_deathmatch)
		{
			for (new i = 0; i < MaxClients; i++)
			{
				if(PlayerIsDead[i])
				{
					CreateTimer(H_respawnTime, Respawn, i);
				}
			}
		}
	}
}
public Action:Timer_RemoveGroundWeapons(Handle:timer)
{
	if(H_active)
	{
		if(H_active_deathmatch)
		{
			if (H_removeWeapons)
			{
				new maxEntities = GetMaxEntities();
				decl String:class[24];
				
				for (new i = MaxClients + 1; i < maxEntities; i++)
				{
					if (IsValidEdict(i) && (GetEntDataEnt2(i, ownerOffset) == -1))
					{
						GetEdictClassname(i, class, sizeof(class));
						if ((StrContains(class, "weapon_") != -1) || (StrContains(class, "item_") != -1))
						{
							if (StrEqual(class, "weapon_c4"))
							{
								if (!H_removeObjectives)
									continue;
							}
							AcceptEntityInput(i, "Kill");
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Command_ResetStats(client, args)
{
	if(H_active)
	{
		if(H_active_os_stats)
		{
			ResetAllStats();
		}
	}
}

public Action:Command_Messages(client, args)
{
	if(H_active)
	{
		if (!Messages[client])
		{
			SetClientCookie(client, g_cookieMessages, "1");
			Messages[client]=true;
			CPrintToChat(client, "%t", "Switch on");
		}
		else
		{
			SetClientCookie(client, g_cookieMessages, "0");
			Messages[client]=false;
			CPrintToChat(client, "%t", "Switch off");
		}
	}
	
  	return Plugin_Handled;
}

public Action:Command_MessagesCMD(client, args)
{
	if(H_active)
	{
		if (!MessagesCMD[client])
		{
			SetClientCookie(client, g_cookieMessagesCMD, "1");
			MessagesCMD[client]=true;
			CPrintToChat(client, "%t", "Switch on");
		}
		else
		{
			SetClientCookie(client, g_cookieMessagesCMD, "0");
			MessagesCMD[client]=false;
			CPrintToChat(client, "%t", "Switch off");	
		}
	}
	
  	return Plugin_Handled;
}

public Action:Command_Sounds(client, args)
{
	if(H_active)
	{
		if (!Sounds[client])
		{
			SetClientCookie(client, g_cookieSounds, "1");
			Sounds[client]=true;
			CPrintToChat(client, "%t", "Sounds on");
		}
		else
		{
			SetClientCookie(client, g_cookieSounds, "0");
			Sounds[client]=false;
			CPrintToChat(client, "%t", "Sounds off");	
		}
	}
	
  	return Plugin_Handled;
}
public Action:Command_BestPlayerRound(client, args)
{
	if(!args)
	{
		BestPlayerRound(client, 1);
	}
	else
	{
		new String:full[256];
		GetCmdArg(args, full, sizeof(full));
		
		if(StringToInt(full) < MaxClients)
		{
			BestPlayerRound(client, StringToInt(full));
		}
	}
	
}
BestPlayerRound(client, String:count)
{
	if(H_active)
	{
		if(H_active_os_stats)
		{
			new Scores[MaxClients][7];
			new RowCount;
			
			for (new i = 0; i < MaxClients; i++)
			{
				new TotalKill = StatsKILL[i] + StatsHS[i] + StatsHE[i] + StatsKNIFE[i];

				Scores[i][0] = i;
				Scores[i][1] = TotalKill;
				Scores[i][2] = StatsKILL[i];
				Scores[i][3] = StatsHS[i];
				Scores[i][4] = StatsHE[i];
				Scores[i][5] = StatsKNIFE[i];
				Scores[i][6] = StatsKILLED[i];
			}
			
			SortCustom2D(Scores, MaxClients, SortScoreDesc);
			
			RowCount = 0;
			for (new n = 0; n <= count-1; n++)
			{
				if (Scores[n][1] > 0)
				{
					decl String:name[65];
					GetClientName(Scores[n][0], name, sizeof(name));
					
					CPrintToChat(client, "%t", "Message Best Player", RowCount, name, Scores[n][2], Scores[n][3], Scores[n][4], Scores[n][5]);
					RowCount++;
				}
			}
		}
	}
}

public Action:Timer_WelcomeMsg(Handle:timer, any:client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		PrintHintText(client, "%t", "WelcomeMSG Version");
	}
	return Plugin_Stop;
}

public Action:Timer_WelcomeMenu(Handle:timer, any:client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		BuildOSMenu(client);
	}
	return Plugin_Stop;
}
public Action:MessagesPlugin(Handle:timer, any:client)
{
	if(Messages[client] && IsClientInGame(client))
	{
		CPrintToChat(client, "%t", "Messages Plugin");
		
		if(H_active_knifes)
		{
			CPrintToChat(client, "%t", "Messages Plugin Knifes");
		}
		
		if(H_active_os_stats)
		{
			CPrintToChat(client, "%t", "Messages Plugin Stats");
		}
	}
}

stock bool:IsClientValid(client) 
{ 
    return ((client > 0 && client <= MaxClients) && IsClientInGame(client)) ? true : false; 
} 

/***********************************************************/
/*********************** SUPER JUMP ************************/
/***********************************************************/
public OnGameFrame()
{
	if(!H_active_super_jump)return;

	new Float:time=GetEngineTime();
	new Float:tick=H_super_jump_tick;
	
  	for (new client = 1; client < MAXPLAYERS+1; client++)
	{
		if (IsClientValid(client))
		{
			if(IsPlayerAlive(client))
			{
				new knife = GetPlayerWeaponSlot(client, _:SlotKnife);
				if(Client_GetActiveWeapon(client) == knife)
				{
					if(JumpTime[client]>=time+tick)
					{	 
						Jumped[client]=false;
						return;
					}
					new buttons = GetClientButtons(client);
					new suppermode=false;
					if( (buttons & IN_JUMP) && !(LastButton[client] & IN_JUMP) )
					{
						if  ((buttons & IN_DUCK) || (buttons & IN_USE))
						{
							suppermode=true;
						}
						if(JumpTime[client]<time)
						{
							decl Float:velocity[3];
							GetEntDataVector(client, Super_Jump_iVelocity, velocity);
							if(velocity[2]<0.0)
							{
								Jumped[client]=false;
								return;
							}
								
							new Float:zmult=H_super_jump_z_mult;
							new Float:xymult=H_super_jump_xy_mult;
							new Float:zmult2=H_super_jump_z_mult2;
							new Float:xymult2=H_super_jump_xy_mult2;
							new damage=H_super_jump_damage;
							new damage2=H_super_jump_damage2;

							decl String:sdemage[10];
							Format(sdemage, sizeof(sdemage),  "%i", damage);
							decl String:sdemage2[10];
							Format(sdemage2, sizeof(sdemage2),  "%i", damage2); 
							if  (suppermode)
							{
								velocity[0]=velocity[0]*xymult2;
								velocity[1]=velocity[1]*xymult2;
								velocity[2]=velocity[2]*zmult2;
							}
							else
							{
								velocity[0]=velocity[0]*xymult;
								velocity[1]=velocity[1]*xymult;
								velocity[2]=velocity[2]*zmult;
							}
							TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
							SetEntDataVector(client, Super_Jump_iVelocity, velocity);
							Jumped[client]=false;
							 
							if(damage>0)
							{
								if(suppermode)DamageEffect(client, sdemage2);
								else DamageEffect(client, sdemage);
							}
		 
						}
					}
					LastButton[client]=buttons;
				}
			}
		}
	}
	return;
}
 
 stock DamageEffect(target, String:demage[])
{
	new pointHurt = CreateEntityByName("point_hurt");			// Create point_hurt
	DispatchKeyValue(target, "targetname", "hurtme");			// mark target
	DispatchKeyValue(pointHurt, "Damage", demage);					// No Damage, just HUD display. Does stop Reviving though
	DispatchKeyValue(pointHurt, "DamageTarget", "hurtme");		// Target Assignment
	DispatchKeyValue(pointHurt, "DamageType", "65536");			// Type of damage
	DispatchSpawn(pointHurt);									// Spawn descriped point_hurt
	AcceptEntityInput(pointHurt, "Hurt"); 						// Trigger point_hurt execute
	AcceptEntityInput(pointHurt, "Kill"); 						// Remove point_hurt
	DispatchKeyValue(target, "targetname",	"cake");			// Clear target's mark
}

/***********************************************************/
/********************* AUTOMATIC SWITCH ********************/
/***********************************************************/
public Action:Command_Switch(client, args)
{
	if(H_active)
	{
		if(H_active_switch)
		{
			if (!Switch[client])
			{
				SetClientCookie(client, g_cookieSwitch, "1");
				Switch[client]=true;
				if(Messages[client] || MessagesCMD[client])
				{
					CPrintToChat(client, "%t", "Switch on");
				}
			}
			else
			{
				SetClientCookie(client, g_cookieSwitch, "0");
				Switch[client]=false;
				if(Messages[client] || MessagesCMD[client])
				{
					CPrintToChat(client, "%t", "Switch off");
				}
			}
		}
	}
	
  	return Plugin_Handled;
}

/***********************************************************/
/************************ LASER TAG ************************/
/***********************************************************/
public Action:BulletImpact_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(H_active)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		// Bullet impact location
		new Float:x = GetEventFloat(event, "x");
		new Float:y = GetEventFloat(event, "y");
		new Float:z = GetEventFloat(event, "z");

		StartLaser[client][0] = x;
		StartLaser[client][1] = y;
		StartLaser[client][2] = z;

		EndLaser[client][0] = x;
		EndLaser[client][1] = y;
		EndLaser[client][2] = z;
	}
 	return Plugin_Continue;
}

Setlaser(client, mode[4])
{
	// Current player's EYE position
	decl Float:playerPos[3];
	GetClientEyePosition(client, playerPos);

	decl Float:lineVector[3];
	SubtractVectors(playerPos, StartLaser[client], lineVector);
	NormalizeVector(lineVector, lineVector);

	// Offset
	ScaleVector(lineVector, 20.0);
	// Find starting point to draw line from
	SubtractVectors(playerPos, lineVector, StartLaser[client]);
	
	TE_SetupBeamPoints(StartLaser[client], EndLaser[client], M_PURPLELASER_PRECACHED, 0, 0, 0, 1.0, 1.0, 1.0, 1, 0.0, mode, 0);
	
	TE_SendToClient(client);
	
}

public Action:Command_Laser(client, args)
{
	if(H_active)
	{
		if(H_active_laser)
		{
			if(!args)
			{
				if (!Laser[client])
				{
					SetClientCookie(client, g_cookieLaser, "1");
					Laser[client]=true;
					if(Messages[client] || MessagesCMD[client])
					{
						CPrintToChat(client, "%t", "Laser on");
					}	
				}
				else
				{
					SetClientCookie(client, g_cookieLaser, "0");
					Laser[client]=false;
					if(Messages[client] || MessagesCMD[client])
					{
						CPrintToChat(client, "%t", "Laser off");
					}	
				}
			}
		}
	}
  	return Plugin_Handled;
}

/***********************************************************/
/************************ HE EFFECTS ***********************/
/***********************************************************/
public HegrenadeDetonate_Event(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(H_active)
	{
		new Float:x = GetEventFloat(event, "x");
		new Float:y = GetEventFloat(event, "y");
		new Float:z = GetEventFloat(event, "z");
		
		HeOrigin[0] = x;
		HeOrigin[1] = y;
		HeOrigin[2] = z;
		
		if(H_dev)
		{
			//TE_SetupBeamRingPoint(HeOrigin, 10.0, 375.0, M_LASERBEAM, M_HALO01, 0, 1, 0.6, 10.0, 0.5, ColorRed, 10, 0);
			//TE_SendToAll();
			//new client = GetClientOfUserId(GetEventInt(event, "userid"));
			//CreateTimer(1.0, Timer_Beacon, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public OnEntityCreated(Entity, const String:Classname[])
{
	if(H_active)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				if (IsPlayerAlive(i))
				{
					if(strcmp(Classname, "hegrenade_projectile") == 0)
					{
						if(BeamHe[i])
						{
							TE_SetupBeamFollow(Entity, M_PURPLELASER_PRECACHED,	0, 5.0, 1.0, 1.0, 1, ColorDefaultTrail[i]);
							TE_SendToClient(i);
						}
						
						SDKHook(Entity, SDKHook_SpawnPost, OnEntitySpawned);
						
					} else if(strcmp(Classname, "flashbang_projectile") == 0)
					{
						if(BeamHe[i])
						{
							TE_SetupBeamFollow(Entity, M_PURPLELASER_PRECACHED,	0, 5.0, 1.0, 1.0, 1, ColorDefaultTrail[i]);
							TE_SendToClient(i);
						}
					} else if(strcmp(Classname, "smokegrenade_projectile") == 0)
					{
						if(BeamHe[i])
						{
							TE_SetupBeamFollow(Entity, M_PURPLELASER_PRECACHED,	0, 5.0, 1.0, 1.0, 1, ColorDefaultTrail[i]);
							TE_SendToClient(i);
						}
					}
				}
			}
		}
	}
	return;
}

public OnEntitySpawned(Entity)
{
	CreateTimer(0.0, InitGrenade, Entity, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:InitGrenade(Handle:timer, any:Entity)
{
	if(!IsValidEntity(Entity))
	{
		return;
	}
	
	new iClient = GetEntDataEnt2(Entity, He_Offset_Thrower);
	
	if(iClient < 1 || iClient > MaxClients)
	{
		return;
	}	
	
	if(H_dev)
	{
		//PrintToChatAll("[MOD IN DEV] - Change infos HE");
	}
	
	SetEntDataFloat(Entity, He_Offset_Damage, H_he_damage);
	SetEntDataFloat(Entity, He_Offset_Radius, H_he_radius);
	SDKHook(Entity, SDKHook_StartTouch, GrenadeTouch);
}
setGlowHe(client, victim)
{
	new Float:vec[3];
	GetClientAbsOrigin(victim, vec);
	vec[2] += 10;
	
	TE_SetupBeamRingPoint(vec, 10.0, 375.0, M_LASERBEAM_PRECACHED, M_HALO01_PRECACHED, 0, 1, 0.6, 1.0, 0.5, ColorDefaultGlow[client], 10, 0);
	TE_SendToClient(client);
}

public Action:Command_GlowHe(client, args)
{
	if(H_active)
	{
		if(H_active_glowhe)
		{
			if (!GlowHe[client])
			{
				SetClientCookie(client, g_cookieGlowHe, "1");
				GlowHe[client]=true;
				if(Messages[client] || MessagesCMD[client])
				{
					CPrintToChat(client, "%t", "GlowHe on");
				}
			}
			else
			{
				SetClientCookie(client, g_cookieGlowHe, "0");
				GlowHe[client]=false;
				if(Messages[client] || MessagesCMD[client])
				{
					CPrintToChat(client, "%t", "GlowHe off");
				}
			}
		}
	}
  	return Plugin_Handled;
}

public Action:Command_BeamHe(client, args)
{
	if(H_active)
	{
		if(H_active_glowhe)
		{
			if (!BeamHe[client])
			{
				SetClientCookie(client, g_cookieBeamHe, "1");
				BeamHe[client]=true;
				if(Messages[client] || MessagesCMD[client])
				{
					CPrintToChat(client, "%t", "BeamHe off");
				}
			}
			else
			{
				SetClientCookie(client, g_cookieBeamHe, "0");
				BeamHe[client]=false;
				if(Messages[client] || MessagesCMD[client])
				{
					CPrintToChat(client, "%t", "BeamHe off");
				}
			}
		}
	}
  	return Plugin_Handled;
}	

/***********************************************************/
/********************* HE STICKS ********************/
/***********************************************************/

StickGrenade(iClient, iGrenade)
{	
	//Remove Collision
	SetEntProp(iGrenade, Prop_Send, "m_CollisionGroup", 2);
	
	//stop movement
	SetEntityMoveType(iGrenade, MOVETYPE_NONE);
	
	// Stick grenade to victim
	SetVariantString("!activator");
	AcceptEntityInput(iGrenade, "SetParent", iClient);
	SetVariantString("idle");
	AcceptEntityInput(iGrenade, "SetAnimation");

	//set properties
	//SetEntDataFloat(iGrenade, He_Offset_Damage, H_he_damage_stuck);
	//SetEntDataFloat(iGrenade, He_Offset_Radius, H_he_radius_stuck);
	
	if(H_active_he_beacon)
	{
		CreateTimer(0.4, Timer_Beacon_Player, iClient, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

public GrenadeTouch(iGrenade, iClient) 
{
	SDKUnhook(iGrenade, SDKHook_StartTouch, GrenadeTouch);
	
	if(H_active_he_stick_player)
	{
		if(iClient > 0 && iClient <= MaxClients)
		{
			StickGrenade(iClient, iGrenade);
		}
	}
	
	if(H_active_he_stick_wall)
	{
		if(GetEntityMoveType(iGrenade) != MOVETYPE_NONE)
		{
			SetEntityMoveType(iGrenade, MOVETYPE_NONE);
			if(H_active_he_beacon)
			{
				CreateTimer(0.2, Timer_Beacon_Entity, iGrenade, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Action:Timer_Beacon_Player(Handle:timer, any:client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}
	
	//PrintToChatAll("Stick on %i", vec);
	
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	
	new Float:vec2[3];
	GetClientAbsOrigin(client, vec2);
	vec[2] += 10;

	TE_SetupBeamRingPoint(vec, 10.0, 375.0, M_LASERBEAM_PRECACHED, M_HALO01_PRECACHED, 0, 10, 0.2, 1.0, 0.5, ColorRed, 10, 0);
	EmitAmbientSound(SND_BEEP, vec2, client, SNDLEVEL_RAIDSIREN);
	TE_SendToAll();

	
	return Plugin_Continue;
}

public Action:Timer_Beacon_Entity(Handle:timer, any:entity)
{


	if(!IsValidEntity(entity))
	{
		return Plugin_Stop;
	}
	
	new Float:position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	TE_SetupBeamRingPoint(position, 10.0, 375.0, M_LASERBEAM_PRECACHED, M_HALO01_PRECACHED, 0, 10, 0.2, 1.0, 0.5, ColorRed, 10, 0);	

	TE_SendToAll();
		
	return Plugin_Continue;
}
/***********************************************************/
/********************** ATTACH PLAYER **********************/
/***********************************************************/
stock CreateLight(client) 
{
    new Float:clientposition[3];
    GetClientAbsOrigin(client, clientposition);
    clientposition[2] += 40.0;

    new GLOW_ENTITY = CreateEntityByName("env_glow");

    SetEntProp(GLOW_ENTITY, Prop_Data, "m_nBrightness", 70, 4);

    DispatchKeyValue(GLOW_ENTITY, "model", "sprites/ledglow.vmt");

    DispatchKeyValue(GLOW_ENTITY, "rendermode", "3");
    DispatchKeyValue(GLOW_ENTITY, "renderfx", "14");
    DispatchKeyValue(GLOW_ENTITY, "scale", "4.0");
    DispatchKeyValue(GLOW_ENTITY, "renderamt", "255");
    DispatchKeyValue(GLOW_ENTITY, "rendercolor", "255 255 255 255");
    DispatchSpawn(GLOW_ENTITY);
    AcceptEntityInput(GLOW_ENTITY, "ShowSprite");
    TeleportEntity(GLOW_ENTITY, clientposition, NULL_VECTOR, NULL_VECTOR);

    new String:target[20];
    FormatEx(target, sizeof(target), "glowclient_%d", client);
    DispatchKeyValue(client, "targetname", target);
    SetVariantString(target);
    AcceptEntityInput(GLOW_ENTITY, "SetParent");
    AcceptEntityInput(GLOW_ENTITY, "TurnOn");
}

stock CreateRing(client)
{
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;
	
	TE_SetupBeamRingPoint(vec, 10.0, 375.0, S_BLUEGLOW1, S_BLUEGLOW1, 0, 15, 0.5, 5.0, 0.0, {128, 128, 128, 255}, 10, 0); 
	TE_SendToAll(); 
}

/***********************************************************/
/************************* OVERLAYS ************************/
/***********************************************************/
/*
public DisplayScreenOverlay(const String:sFile[], const String:sSound[], const Float:fTime)
{
	new iFlags = GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", iFlags &~ FCVAR_CHEAT);

	for(new i = 1; i <= MaxClients; i++) if(IsClientInGame(i))
		ClientCommand(i, "r_screenoverlay \"%s\"", sFile);

	SetCommandFlags("r_screenoverlay", iFlags);

	g_bOverlayed = true;
	CreateTimer(fTime, Timer_RemoveOverlay, _, TIMER_FLAG_NO_MAPCHANGE);
}

public ClearScreenOverlay()
{
	new iFlags = GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", iFlags &~ FCVAR_CHEAT);

	for(new i = 1; i <= MaxClients; i++) if(IsClientInGame(i))
		ClientCommand(i, "r_screenoverlay \"\"");

	SetCommandFlags("r_screenoverlay", iFlags);
}

public Action:Timer_RemoveOverlay(Handle:hTimer)
{
	g_bOverlayed = false;
	ClearScreenOverlay();
}
*/
/***********************************************************/
/************************* ONE SHOT ************************/
/***********************************************************/
public Action:Timer_Ammo(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			new weapon_pri = GetPlayerWeaponSlot(client, _:SlotPrimary);
			new weapon_sec = GetPlayerWeaponSlot(client, _:SlotSecondary);
			new knife = GetPlayerWeaponSlot(client, _:SlotKnife);
			new ammo = Weapon_GetPrimaryClip(weapon_sec);
			
			if(weapon_sec != -1)
			{
				decl String:weapon_name[32];
				GetEntityClassname(weapon_sec, weapon_name, 32);
				
				if(!StrEqual(weapon_name, "weapon_deagle"))
				{
					//Enlever toutes les armes
					Client_RemoveAllWeapons(client, "", true);
		
					//Donner armes
					GivePlayerItem(client, "weapon_deagle");
					GiveKnifes(client);
					Client_SetWeaponAmmo(client, "weapon_deagle", 0, 0, H_ammo, 0);
				}
				
				if(PlayerJustSpawn[client])
				{
					PlayerJustSpawn[client] = false;
					if(ammo > 1)
					{
						//PrintToChatAll("spawn with :%i", ammo);
						//Enlever toutes les armes
						Client_RemoveAllWeapons(client, "", true);
			
						//Donner armes
						GivePlayerItem(client, "weapon_deagle");
						GiveKnifes(client);
						Client_SetWeaponAmmo(client, "weapon_deagle", 0, 0, H_ammo, 0);
					}
				}
			}
			
			if(weapon_pri != -1 || weapon_sec == -1 || knife == -1)
			{
				//Enlever toutes les armes
				Client_RemoveAllWeapons(client, "", true);
	
				//Donner armes
				GivePlayerItem(client, "weapon_deagle");
				GiveKnifes(client);
				Client_SetWeaponAmmo(client, "weapon_deagle", 0, 0, H_ammo, 0);			
			}
		}
	}
}

public Action:Timer_RefillGun(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			new weapon_sec = GetPlayerWeaponSlot(client, _:SlotSecondary);
			new String:weapon_sec_classname[30];
			GetEntityClassname(weapon_sec, weapon_sec_classname, sizeof(weapon_sec_classname));
			
			Client_RemoveWeapon(client, weapon_sec_classname, true, false);
			GivePlayerItem(client, "weapon_deagle");
			Client_SetWeaponAmmo(client, "weapon_deagle", 0, 0, Ammo[client], 0);
		}
	}
}

public Action:Timer_CheckAmmoWeapons(Handle:timer)
{
	if(H_active)
	{
		if(H_active_switch)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if(Switch[i])
				{
					if (IsClientInGame(i))
					{
						if (IsPlayerAlive(i))
						{
							new weapon_sec = GetPlayerWeaponSlot(i, _:SlotSecondary);
							new knife = GetPlayerWeaponSlot(i, _:SlotKnife);
							new grenade = GetPlayerWeaponSlot(i, _:SlotGrenade);
							
							if(IsValidEntity(weapon_sec))
							{
								if(Client_GetActiveWeapon(i) == weapon_sec)
								{
									new ammo = Weapon_GetPrimaryClip(weapon_sec);
									if(ammo == 0 && grenade == -1)
									{
										if(IsValidEntity(knife))
										{
											new String:knife_classname[30];
											GetEntityClassname(knife, knife_classname, sizeof(knife_classname));
											Client_RemoveWeapon(i, knife_classname, true, false);

											new newknife = GiveKnifes(i);
											SetEntPropEnt(i, Prop_Data, "m_hActiveWeapon", newknife);
											ChangeEdictState(i, FindDataMapOffs(i, "m_hActiveWeapon"));
										}
									}
									else if(ammo == 0 && grenade != -1)
									{
										if(IsValidEntity(grenade))
										{
											new String:grenade_classname[30];
											GetEntityClassname(grenade, grenade_classname, sizeof(grenade_classname));
											
											Client_RemoveWeapon(i, grenade_classname, true, false);
											new newgrenade = GivePlayerItem(i, "weapon_hegrenade");
											SetEntPropEnt(i, Prop_Data, "m_hActiveWeapon", newgrenade);
											ChangeEdictState(i, FindDataMapOffs(i, "m_hActiveWeapon"));		
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
	return Plugin_Continue;
}

SetCashState()
{

	if(H_active_os || H_active_deathmatch)
	{
		SetConVarInt(mp_startmoney, 0);
		SetConVarInt(mp_playercashawards, 0);
		SetConVarInt(mp_teamcashawards, 0);
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i))
				SetEntProp(i, Prop_Send, "m_iAccount", 0);
		}
	}
	
	if(!H_active_os && !H_active_deathmatch)
	{
		SetConVarInt(mp_startmoney, backup_mp_startmoney);
		SetConVarInt(mp_playercashawards, backup_mp_playercashawards);
		SetConVarInt(mp_teamcashawards, backup_mp_teamcashawards);
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i))
				SetEntProp(i, Prop_Send, "m_iAccount", backup_mp_startmoney);
		}
	}

}

RestoreCashState()
{
	SetConVarInt(mp_startmoney, backup_mp_startmoney);
	SetConVarInt(mp_playercashawards, backup_mp_playercashawards);
	SetConVarInt(mp_teamcashawards, backup_mp_teamcashawards);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
			SetEntProp(i, Prop_Send, "m_iAccount", backup_mp_startmoney);
	}
}

/***********************************************************/
/*********************** SKINS KNIFES **********************/
/***********************************************************/
GiveKnifes(client)
{
	new iItem;
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			new knife = GetPlayerWeaponSlot(client, _:SlotKnife);
			if(knife != -1)
			{
				new String:knife_classname[30];
				GetEntityClassname(knife, knife_classname, sizeof(knife_classname));
				Client_RemoveWeapon(client, knife_classname, true, false);
			}
			
			switch(Knifes[client]) 
			{
				case 0:iItem = GivePlayerItem(client, "weapon_knife");
				case 1:iItem = GivePlayerItem(client, "weapon_bayonet");
				case 2:iItem = GivePlayerItem(client, "weapon_knife_gut");
				case 3:iItem = GivePlayerItem(client, "weapon_knife_flip");
				case 4:iItem = GivePlayerItem(client, "weapon_knife_m9_bayonet");
				case 5:iItem = GivePlayerItem(client, "weapon_knife_karambit");
				case 6:iItem = GivePlayerItem(client, "weapon_knife_tactical");
				case 7:iItem = GivePlayerItem(client, "weapon_knife_butterfly");
				case 8:iItem = GivePlayerItem(client, "weapon_knifegg");
			}
			
			if(IsValidClient(client))
			{
				if (iItem > 0)
				{	
					EquipPlayerWeapon(client, iItem);
				}
			}
		}
	}
	return iItem;
}

bool:IsValidClient(client)
{
	if (!(0 < client <= MaxClients)) return false;
	if (!IsClientInGame(client)) return false;
	if (IsFakeClient(client)) return false;
	if (!CheckCommandAccess(client, "sm_knifeupgrade", 0, true)) return false;
	return true;
}

/***********************************************************/
/*********************** PANEL STATS ***********************/
/***********************************************************/
public Action:Timer_GetFirstPosition(Handle:timer)
{
	new Scores[MaxClients][2];
	new RowCount;
	
	for (new i = 0; i < MaxClients; i++)
	{
		new TotalKill = StatsKILL[i] + StatsHS[i] + StatsHE[i] + StatsKNIFE[i];

		Scores[i][0] = i;
		Scores[i][1] = TotalKill;
	}
	
	SortCustom2D(Scores, MaxClients, SortScoreDesc);
	
	RowCount = 0;
	for (new n = 0; n <= 0; n++)
	{
		if (Scores[n][1] > 0)
		{
			if(H_dev)
			{
				//PrintToChatAll("[MOD IN DEV] - 1ER = :%i, Scores:%i", Scores[n][0], Scores[n][1]);
			}
			
			PlayerIsFirst[Scores[n][0]] = true;
			
			if(!PlayerIsAlreadyFirst[Scores[n][0]])
			{
				PlayerIsAlreadyFirst[Scores[n][0]] = true;
				PlayerHadNormalSkin[Scores[n][0]] = false;
				PlayerHadKingSkin[Scores[n][0]] = true;
				
				
				
				if(Messages[Scores[n][0]])
				{
					CPrintToChat(Scores[n][0], "%t", "Your are first");
				}
				
				if(SoundsFirstPosition[Scores[n][0]])
				{
					ClientCommand(Scores[n][0], "play *%s", SND_KILL_WHICKEDSICK);
				}
				
				if(H_active_hats_king)
				{
					if(IsClientValid(Scores[n][0]))
						{
							if(IsPlayerAlive(Scores[n][0]))
							{
								//SetEntityModel(Scores[n][0], MDL_SKIN_KING);
							}
						}
				}
				
			}
			
			RowCount++;
		}
	}
	
	for (new m = 1; m <= MaxClients; m++)
	{
		if (Scores[m][1] > 0)
		{
			if(H_dev)
			{
				//PrintToChatAll("[MOD IN DEV] - OTHERS = :%i, Scores:%i", Scores[m][0], Scores[m][1]);
			}
			
			PlayerIsFirst[Scores[m][0]] = false;
			PlayerIsAlreadyFirst[Scores[m][0]] = false;
			
			if(!PlayerHadNormalSkin[Scores[m][0]])
			{
				PlayerHadNormalSkin[Scores[m][0]] = true;
				if(H_active_hats_king)
				{
					if(IsClientValid(Scores[m][0]))
					{
						if(IsPlayerAlive(Scores[m][0]))
						{
							SetEntityModel(Scores[m][0], models[5]);
						}
					}
				}
			}
			RowCount++;
		}
	}
}

public SortScoreDesc(x[], y[], array[][], Handle:data)
{
	if (x[1] > y[1])
		return -1;
	else if (x[1] < y[1])
		return 1;
	return 0;
}

/***********************************************************/
/************************* GIVE WEAPONS *************************/
/***********************************************************/
public Action:smWeapon(id, args)
{
	if(args < 2)
	{
		ReplyToCommand(id, "[SM] Usage: sm_weapon <name | #userid> <weaponname>");
		return Plugin_Handled;
	}
	
	decl String:sArg[256];
	decl String:sTempArg[32];
	decl String:sWeaponName[32];
	decl String:sWeaponNameTemp[32];
	decl iL;
	decl iNL;
	
	GetCmdArgString(sArg, sizeof(sArg));
	iL = BreakString(sArg, sTempArg, sizeof(sTempArg));
	
	if((iNL = BreakString(sArg[iL], sWeaponName, sizeof(sWeaponName))) != -1)
		iL += iNL;
	
	new i;
	new iValid = 0;
	
	if(StrContains(sWeaponName, "weapon_") == -1)
	{
		FormatEx(sWeaponNameTemp, 31, "weapon_");
		StrCat(sWeaponNameTemp, 31, sWeaponName);
		
		strcopy(sWeaponName, 31, sWeaponNameTemp);
	}
	
	for(i = 0; i < MAX_WEAPONS; ++i)
	{
		if(StrEqual(sWeaponName, g_weapons[i]))
		{
			iValid = 1;
			break;
		}
	}
	
	if(!iValid)
	{
		ReplyToCommand(id, "[SM] The weaponname (%s) isn't valid", sWeaponName);
		return Plugin_Handled;
	}
	
	decl String:sTargetName[MAX_TARGET_LENGTH];
	decl sTargetList[1];
	decl bool:bTN_IsML;
	
	new iTarget = -1;
	
	if(ProcessTargetString(sTempArg, id, sTargetList, 1, COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_MULTI, sTargetName, sizeof(sTargetName), bTN_IsML) > 0)
		iTarget = sTargetList[0];
	
	if(iTarget != -1 && !IsFakeClient(iTarget))
		GivePlayerItem(iTarget, sWeaponName);
	
	return Plugin_Handled;
}

public Action:smWeaponList(id, args)
{
	new i;
	for(i = 0; i < MAX_WEAPONS; ++i)
		ReplyToCommand(id, "%s", g_weapons[i]);
	
	ReplyToCommand(id, "");
	ReplyToCommand(id, "* No need to put weapon_ in the <weaponname>");
	
	return Plugin_Handled;
}
/***********************************************************/
/************************* MENU OS *************************/
/***********************************************************/
public Action:OSMenu(client,args)
{
	if(H_active)
	{
		BuildOSMenu(client);
	}
	else
	{
		CPrintToChat(client, "%t", "OS Menu Disable");
	}
	return Plugin_Handled;
}

public Action:OSMenuSettings(client,args)
{
	BuildSettingsMenu(client);
	return Plugin_Handled;
}

public Action:OSMenuStats(client,args)
{
	if(H_active_os_stats)
	{
		BuildStatsMenu(client);
	}
	return Plugin_Handled;
}

public Action:OSMenuKnifes(client,args)
{
	if(H_active_knifes)
	{
		BuildKnifesMenu(client);
	}
	else
	{
		CPrintToChat(client, "%t", "OS Menu Knifes Disable");
	}
	return Plugin_Handled;
}
BuildOSMenu(client)
{
	decl String:title[256], String:settings[256], String:stats[256], String:help[256], String:admin[256];
	new Handle:menu = CreateMenu(OS_Menu);

	Format(settings, sizeof(settings), "%T", "OS Settings", client);
	AddMenuItem(menu, "g_SettingsMenu", settings);

	if(H_active_os_stats)
	{
		Format(stats, sizeof(stats), "%T", "OS Stats", client);
		AddMenuItem(menu, "g_StatsMenu", stats);
	}
	
	Format(help, sizeof(help), "%T", "OS Help", client);
	AddMenuItem(menu, "g_HelpMenu", help);
	
	if(CheckCommandAccess(client, "", ADMFLAG_GENERIC ))
	{
		Format(admin, sizeof(admin), "%T", "OS Admin", client);
		AddMenuItem(menu, "g_AdminMenu", admin);
	}
	Format(title, sizeof(title), "%T", "OS menu", client);
	SetMenuTitle(menu, title);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public OS_Menu(Handle:menu, MenuAction:action, param1, param2)
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
			if(StrEqual(menu1, "g_SettingsMenu"))
			{
				BuildSettingsMenu(param1);
			}	
			else if(StrEqual(menu1, "g_StatsMenu"))
			{
				BuildStatsMenu(param1);
			}
			else if(StrEqual(menu1, "g_HelpMenu"))
			{
				BuildHelpMenu(param1);
			}	
			else if(StrEqual(menu1, "g_AdminMenu"))
			{
				BuildAdminMenu(param1);
			}			
		}
	}
}

BuildSettingsMenu(client)
{
	decl String:title[256], String:lasermenu[256], String:switched[256], String:glowhe[256], String:beamhe[256], String:messages[256], String:messagscmd[256],String:sounds[256];
	new Handle:menu = CreateMenu(SettingsMenuHandler);
	SetMenuExitBackButton(menu, true);

	if(H_active_sounds)
	{
		Format(sounds, sizeof(sounds), "%t", (Sounds[client]) ? "OS Sounds Menu Enable" : "OS Sounds Menu Disable");
		AddMenuItem(menu, "g_SoundsMenu", sounds);	
	}
	
	if(H_active_knifes)
	{
		KnifesMenuItems(client, menu);
	}
	
	if(H_active_laser)
	{
		Format(lasermenu, sizeof(lasermenu), "%t", (Laser[client]) ? "OS Laser Menu Enable" : "OS Laser Menu Disable");
		AddMenuItem(menu, "g_LaserMenu", lasermenu);
	}
	
	if(H_active_switch)
	{
		Format(switched, sizeof(switched), "%t", (Switch[client]) ? "OS Switch Menu Enable" : "OS Switch Menu Disable");
		AddMenuItem(menu, "g_SwitchMenu", switched);
	}
	
	if(H_active_glowhe)
	{
		Format(glowhe, sizeof(glowhe), "%t", (GlowHe[client]) ? "OS GlowHe Menu Enable" : "OS GlowHe Menu Disable");
		AddMenuItem(menu, "g_GlowHeMenu", glowhe);
	}
	
	if(H_active_beamhe)
	{
		Format(beamhe, sizeof(beamhe), "%t", (BeamHe[client]) ? "OS BeamHe Menu Enable" : "OS BeamHe Menu Disable");
		AddMenuItem(menu, "g_BeamHeMenu", beamhe);
	}
	
	Format(messages, sizeof(messages), "%t", (Messages[client]) ? "OS Messages Menu Enable" : "OS Messages Menu Disable");
	AddMenuItem(menu, "g_MessagesMenu", messages);

	Format(messagscmd, sizeof(messagscmd), "%t", (MessagesCMD[client]) ? "OS MessagesCMD Menu Enable" : "OS MessagesCMD Menu Disable");
	AddMenuItem(menu, "g_MessagesCMDMenu", messagscmd);
	
	Format(title, sizeof(title),"%T", "OS Settings Menu", client);
	SetMenuTitle(menu, title);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildStatsMenu(client)
{
	decl String:title[256], String:back[256], String:exits[256], String:kill[256], String:hs[256], String:he[256], String:knife[256], String:total[256];
	new Handle:cpanel = CreatePanel();
	
	Format(title, sizeof(title),"%T", "OS Stats Menu", client);
	SetPanelTitle(cpanel, title);
	
	new TotalKill = Backup_StatsKILL[client] + Backup_StatsHS[client] + Backup_StatsHE[client] + Backup_StatsKNIFE[client];
	
	Format(kill, sizeof(kill), "%t", "OS Stats KILL", Backup_StatsKILL[client]);
	DrawPanelText(cpanel, kill);

	Format(hs, sizeof(hs), "%t", "OS Stats HS", Backup_StatsHS[client]);
	DrawPanelText(cpanel, hs);

	Format(he, sizeof(he), "%t", "OS Stats HE", Backup_StatsHE[client]);
	DrawPanelText(cpanel, he);

	Format(knife, sizeof(knife), "%t", "OS Stats KNIFE", Backup_StatsKNIFE[client]);
	DrawPanelText(cpanel, knife);
	
	DrawPanelText(cpanel, " ");
	
	Format(total, sizeof(total), "%t", "OS Stats TOTAL", TotalKill);
	DrawPanelText(cpanel, total);
	
	DrawPanelItem(cpanel, " ", ITEMDRAW_NOTEXT);
	DrawPanelText(cpanel, " ");
	
	Format(back, sizeof(back), "%t", "OS Stats Back");
	DrawPanelItem(cpanel, back, ITEMDRAW_CONTROL);
	
	DrawPanelItem(cpanel, " ", ITEMDRAW_NOTEXT);
	DrawPanelText(cpanel, " ");
	
	Format(exits, sizeof(exits), "%t", "OS Stats Exit");
	DrawPanelItem(cpanel, exits, ITEMDRAW_CONTROL);
	
	SendPanelToClient(cpanel, client, StatsMenuHandler, 30);
	CloseHandle(cpanel);
}

BuildAdminMenu(client)
{
	decl String:title[256], String:spawneditor[256], String:general[256], String:hats[256];
	new Handle:menu = CreateMenu(AdminMenuHandler);
	SetMenuExitBackButton(menu, true);
	
	if(CheckCommandAccess(client, "", ADMFLAG_GENERIC ))
	{
		Format(general, sizeof(general), "%t", "OS General");
		AddMenuItem(menu, "g_GeneralMenu", general);
		
		if(H_active_os)
		{
			Format(spawneditor, sizeof(spawneditor), "%t", "OS Spawn Editor");
			AddMenuItem(menu, "g_SpawnEditorMenu", spawneditor);	
		}
		
		if(H_active_hats)
		{
			Format(hats, sizeof(hats), "%t", "OS Hats");
			AddMenuItem(menu, "g_HatsMenu", hats);	
		}
	}
	Format(title, sizeof(title),"%T", "OS Admin Menu", client);
	SetMenuTitle(menu, title);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public StatsMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);	
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack || param2 == 4)
			{	
				BuildOSMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			if(param2 == 8 || param2 == 2)
			{
				BuildOSMenu(param1);
			}
		}
	}
}

public SettingsMenuHandler(Handle:menu, MenuAction:action, param1, param2)
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
				BuildOSMenu(param1);
			}
		}		
		case MenuAction_Select:
		{
			new String:menu1[56];
			GetMenuItem(menu, param2, menu1, sizeof(menu1));
			if(StrEqual(menu1, "g_LaserMenu"))
			{
				BuildLaserMenu(param1);
			}
			else if(StrEqual(menu1, "g_SwitchMenu"))
			{
				BuildSwitchMenu(param1);
			}
			else if(StrEqual(menu1, "g_GlowHeMenu"))
			{
				BuildGlowHeMenu(param1);
			}
			else if(StrEqual(menu1, "g_BeamHeMenu"))
			{
				BuildBeamHeMenu(param1);
			}
			else if(StrEqual(menu1, "g_KnifesMenu"))
			{
				BuildKnifesMenu(param1);
			}
			else if(StrEqual(menu1, "g_MessagesMenu"))
			{
				BuildMessagesMenu(param1);
			}
			else if(StrEqual(menu1, "g_MessagesCMDMenu"))
			{
				BuildMessagesCMDMenu(param1);
			}
			else if(StrEqual(menu1, "g_SoundsMenu"))
			{
				BuildSoundsMenu(param1);
			}
		}
	}
}

public AdminMenuHandler(Handle:menu, MenuAction:action, param1, param2)
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
				BuildOSMenu(param1);
			}
		}		
		case MenuAction_Select:
		{
			new String:menu1[56];
			GetMenuItem(menu, param2, menu1, sizeof(menu1));
			if(StrEqual(menu1, "g_GeneralMenu"))
			{
				FakeClientCommandEx(param1, "say /admin");
			}
			else if(StrEqual(menu1, "g_SpawnEditorMenu"))
			{
				DisplayMenu(BuildSpawnEditorMenu(), param1, MENU_TIME_FOREVER);
			}
			else if(StrEqual(menu1, "g_HatsMenu"))
			{
				DisplayMenu(CreateHatsMenu(param1, -1), param1, 0);
			}
		}
	}
}

BuildLaserMenu(param1)
{
	decl String:yes[256], String:no[256], String:title[256];
	new Handle:menu = CreateMenu(MenuHandler_Laser);

	if(Laser[param1])
	{
		Format(no, sizeof(no),"%T", "Disable", param1);
		AddMenuItem(menu, "Disable", no);
		LaserColorKillMenuItems(param1, menu);
		LaserColorHsMenuItems(param1, menu);
	}
	else
	{
		Format(yes, sizeof(yes),"%T", "Enable", param1);
		AddMenuItem(menu, "Enable", yes);
	}
		
	Format(title, sizeof(title), "%t", (Laser[param1]) ? "OS Laser Menu Enable" : "OS Laser Menu Disable");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

BuildSwitchMenu(param1)
{
	decl String:yes[256], String:no[256], String:title[256];
	new Handle:menu = CreateMenu(MenuHandler_Switch);
	
	if(Switch[param1])
	{
		Format(no, sizeof(no),"%T", "Disable", param1);
		AddMenuItem(menu, "Disable", no);
	}
	else
	{
		Format(yes, sizeof(yes),"%T", "Enable", param1);
		AddMenuItem(menu, "Enable", yes);
	}
	Format(title, sizeof(title), "%t", (Switch[param1]) ? "OS Switch Menu Enable" : "OS Switch Menu Disable");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

BuildGlowHeMenu(param1)
{
	decl String:yes[256], String:no[256], String:title[256];
	new Handle:menu = CreateMenu(MenuHandler_GlowHe);
	
	if(GlowHe[param1])
	{
		Format(no, sizeof(no),"%T", "Disable", param1);
		AddMenuItem(menu, "Disable", no);
		GlowColorHeMenuItems(param1, menu);
	}
	else
	{
		Format(yes, sizeof(yes),"%T", "Enable", param1);
		AddMenuItem(menu, "Enable", yes);
	}
	Format(title, sizeof(title), "%t", (GlowHe[param1]) ? "OS GlowHe Menu Enable" : "OS GlowHe Menu Disable");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

BuildBeamHeMenu(param1)
{
	decl String:yes[256], String:no[256], String:title[256];
	new Handle:menu = CreateMenu(MenuHandler_BeamHe);
	
	if(BeamHe[param1])
	{
		Format(no, sizeof(no),"%T", "Disable", param1);
		AddMenuItem(menu, "Disable", no);
		BeamColorHeMenuItems(param1, menu);
	}
	else
	{
		Format(yes, sizeof(yes),"%T", "Enable", param1);
		AddMenuItem(menu, "Enable", yes);
	}
	Format(title, sizeof(title), "%t", (BeamHe[param1]) ? "OS BeamHe Menu Enable" : "OS BeamHe Menu Disable");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

BuildMessagesMenu(param1)
{
	decl String:yes[256], String:no[256], String:title[256];
	new Handle:menu = CreateMenu(MenuHandler_Messages);
	
	if(Messages[param1])
	{
		Format(no, sizeof(no),"%T", "Disable", param1);
		AddMenuItem(menu, "Disable", no);
	}
	else
	{
		Format(yes, sizeof(yes),"%T", "Enable", param1);
		AddMenuItem(menu, "Enable", yes);
	}
	Format(title, sizeof(title), "%t", (Messages[param1]) ? "OS Messages Menu Enable" : "OS Messages Menu Disable");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

BuildMessagesCMDMenu(param1)
{
	decl String:yes[256], String:no[256], String:title[256];
	new Handle:menu = CreateMenu(MenuHandler_MessagesCMD);
	
	if(MessagesCMD[param1])
	{
		Format(no, sizeof(no),"%T", "Disable", param1);
		AddMenuItem(menu, "Disable", no);
	}
	else
	{
		Format(yes, sizeof(yes),"%T", "Enable", param1);
		AddMenuItem(menu, "Enable", yes);
	}
	Format(title, sizeof(title), "%t", (MessagesCMD[param1]) ? "OS MessagesCMD Menu Enable" : "OS MessagesCMD Menu Disable");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

BuildSoundsMenu(param1)
{
	decl String:yes[256], String:no[256], String:title[256], String:hs[256], String:first[256], String:spree[256], String:rampage[256], String:unstoppable[256], String:domination[256], String:godlike[256], String:doubleex[256], String:triple[256], String:monster[256];
	new Handle:menu = CreateMenu(MenuHandler_Sounds);
	
	if(Sounds[param1])
	{
		Format(no, sizeof(no),"%T", "Disable", param1);
		AddMenuItem(menu, "Disable", no);
		
		Format(first, sizeof(first), "%t", (SoundsFirstPosition[param1]) ? "OS Sounds Menu FirstPosition Enable" : "OS Sounds Menu FirstPosition Disable");
		AddMenuItem(menu, "FirstPosition", first);
		
		Format(hs, sizeof(hs), "%t", (SoundsKillHs[param1]) ? "OS Sounds Menu Hs Enable" : "OS Sounds Menu Hs Disable");
		AddMenuItem(menu, "Hs", hs);
		
		Format(spree, sizeof(spree), "%t", (SoundsKillSpree[param1]) ? "OS Sounds Menu Spree Enable" : "OS Sounds Menu Spree Disable");
		AddMenuItem(menu, "Spree", spree);
		
		Format(rampage, sizeof(rampage), "%t", (SoundsKillRampage[param1]) ? "OS Sounds Menu Rampage Enable" : "OS Sounds Menu Rampage Disable");
		AddMenuItem(menu, "Rampage", rampage);
		
		Format(unstoppable, sizeof(unstoppable), "%t", (SoundsKillUnstoppable[param1]) ? "OS Sounds Menu Unstoppable Enable" : "OS Sounds Menu Unstoppable Disable");
		AddMenuItem(menu, "Unstoppable", unstoppable);
		
		Format(domination, sizeof(domination), "%t", (SoundsKillDomination[param1]) ? "OS Sounds Menu Domination Enable" : "OS Sounds Menu Domination Disable");
		AddMenuItem(menu, "Domination", domination);
		
		Format(godlike, sizeof(godlike), "%t", (SoundsKillGodlike[param1]) ? "OS Sounds Menu Godlike Enable" : "OS Sounds Menu Godlike Disable");
		AddMenuItem(menu, "Godlike", godlike);
		
		Format(doubleex, sizeof(doubleex), "%t", (SoundsKillDouble[param1]) ? "OS Sounds Menu Double Enable" : "OS Sounds Menu Double Disable");
		AddMenuItem(menu, "Double", doubleex);
		
		Format(triple, sizeof(triple), "%t", (SoundsKillTriple[param1]) ? "OS Sounds Menu Triple Enable" : "OS Sounds Menu Triple Disable");
		AddMenuItem(menu, "Triple", triple);
		
		Format(monster, sizeof(monster), "%t", (SoundsKillMonster[param1]) ? "OS Sounds Menu Monster Enable" : "OS Sounds Menu Monster Disable");
		AddMenuItem(menu, "Monster", monster);
	}
	else
	{
		Format(yes, sizeof(yes),"%T", "Enable", param1);
		AddMenuItem(menu, "Enable", yes);
	}
	
	Format(title, sizeof(title), "%t", (Sounds[param1]) ? "OS Sounds Menu Enable" : "OS Sounds Menu Disable");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

BuildKnifesMenu(client)
{
	decl String:Bayonet[32];
	decl String:Gut[32];
	decl String:Flip[32];
	decl String:M9[32];
	decl String:Karambit[32];
	decl String:Huntsman[32];
	decl String:Butterfly[32];
	decl String:Default[32];
	decl String:Golden[32];
	
	Format(Default, sizeof(Default), "%t", "Menu Knife Default");
	Format(Bayonet, sizeof(Bayonet), "%t", "Menu Knife Bayonet");
	Format(Gut, sizeof(Gut), "%t", "Menu Knife Gut");
	Format(Flip, sizeof(Flip), "%t", "Menu Knife Flip");
	Format(M9, sizeof(M9), "%t", "Menu Knife M9");
	Format(Karambit, sizeof(Karambit), "%t", "Menu Knife Karambit");
	Format(Huntsman, sizeof(Huntsman), "%t", "Menu Knife Huntsman");
	Format(Butterfly, sizeof(Butterfly), "%t", "Menu Knife Butterfly");
	Format(Golden, sizeof(Golden), "%t", "Menu Knife Golden");	
	
	new Handle:menu = CreateMenu(MenuHandler_Knifes);
	SetMenuTitle(menu, "%t", "OS Knifes Menu");


	AddMenuItem(menu, "knife", Default);
	AddMenuItem(menu, "bayonet", Bayonet);
	AddMenuItem(menu, "gut", Gut);
	AddMenuItem(menu, "flip", Flip);
	AddMenuItem(menu, "m9", M9);
	AddMenuItem(menu, "karambit", Karambit);
	AddMenuItem(menu, "huntsman", Huntsman);
	AddMenuItem(menu, "butterfly", Butterfly);
	AddMenuItem(menu, "golden", Golden);
	
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 20);
}

KnifesMenuItems(client, Handle:menu)
{
	decl String:knifes[256];
	
	if(Knifes[client] == 0)
	{
		Format(knifes, sizeof(knifes), "%t", "OS Knifes Menu Normal");
		AddMenuItem(menu, "g_KnifesMenu", knifes);
		if(IsClientInGame(client))
		{
			if(IsPlayerAlive(client))
			{
				GiveKnifes(client);
			}
		}
	}
	else if(Knifes[client] == 1)
	{
		Format(knifes, sizeof(knifes), "%t", "OS Knifes Menu Bayonet");
		AddMenuItem(menu, "g_KnifesMenu", knifes);
		if(IsClientInGame(client))
		{
			if(IsPlayerAlive(client))
			{
				GiveKnifes(client);
			}
		}
	}
	else if(Knifes[client] == 2)
	{
		Format(knifes, sizeof(knifes), "%t", "OS Knifes Menu Gut");
		AddMenuItem(menu, "g_KnifesMenu", knifes);
		if(IsClientInGame(client))
		{
			if(IsPlayerAlive(client))
			{
				GiveKnifes(client);
			}
		}
	}	
	else if(Knifes[client] == 3)
	{
		Format(knifes, sizeof(knifes), "%t", "OS Knifes Menu Flip");
		AddMenuItem(menu, "g_KnifesMenu", knifes);
		if(IsClientInGame(client))
		{
			if(IsPlayerAlive(client))
			{
				GiveKnifes(client);
			}
		}
	}
	else if(Knifes[client] == 4)
	{
		Format(knifes, sizeof(knifes), "%t", "OS Knifes Menu M9");
		AddMenuItem(menu, "g_KnifesMenu", knifes);
		if(IsClientInGame(client))
		{
			if(IsPlayerAlive(client))
			{
				GiveKnifes(client);
			}
		}
	}
	else if(Knifes[client] == 5)
	{
		Format(knifes, sizeof(knifes), "%t", "OS Knifes Menu Karambit");
		AddMenuItem(menu, "g_KnifesMenu", knifes);
		if(IsClientInGame(client))
		{
			if(IsPlayerAlive(client))
			{
				GiveKnifes(client);
			}
		}
	}
	else if(Knifes[client] == 6)
	{
		Format(knifes, sizeof(knifes), "%t", "OS Knifes Menu Huntsan");
		AddMenuItem(menu, "g_KnifesMenu", knifes);
		if(IsClientInGame(client))
		{
			if(IsPlayerAlive(client))
			{
				GiveKnifes(client);
			}
		}
	}
	else if(Knifes[client] == 7)
	{
		Format(knifes, sizeof(knifes), "%t", "OS Knifes Menu Butterfly");
		AddMenuItem(menu, "g_KnifesMenu", knifes);
		if(IsClientInGame(client))
		{
			if(IsPlayerAlive(client))
			{
				GiveKnifes(client);
			}
		}
	}
	else if(Knifes[client] == 8)
	{
		Format(knifes, sizeof(knifes), "%t", "OS Knifes Menu Golden");
		AddMenuItem(menu, "g_KnifesMenu", knifes);
		if(IsClientInGame(client))
		{
			if(IsPlayerAlive(client))
			{
				GiveKnifes(client);
			}
		}
	}
}

public MenuHandler_Laser(Handle:menu, MenuAction:action, param1, param2)
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
				BuildSettingsMenu(param1);
			}
		}		
		case MenuAction_Select:
		{
			decl String:choice[256];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "Disable", false))
			{
				SetClientCookie(param1, g_cookieLaser, "0");
				Laser[param1] = false;
				BuildSettingsMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "Laser off");
				}
			}
			else if (StrEqual(choice, "Enable", false))
			{
				SetClientCookie(param1, g_cookieLaser, "1");
				Laser[param1] = true;
				BuildSettingsMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "Laser on");
				}
			}
			else if (StrEqual(choice, "g_LaserColorKillMenu", false))
			{
				BuildLaserColorKillMenu(param1);
			}
			else if (StrEqual(choice, "g_LaserColorHsMenu", false))
			{
				BuildLaserColorHsMenu(param1);
			}
		}
	}
}	

BuildLaserColorKillMenu(client)
{
	decl String:black[64];
	decl String:white[64];
	decl String:red[64];
	decl String:lime[64];
	decl String:blue[64];
	decl String:yellow[64];
	decl String:aqua[64];
	decl String:fuchsia[64];
	decl String:silver[64];
	decl String:grey[64];
	decl String:maroon[64];
	decl String:olive[64];
	decl String:green[64];
	decl String:purple[64];
	decl String:teel[64];
	decl String:navy[64];
	
	Format(black, sizeof(black), "%t", "Menu Color Black");
	Format(white, sizeof(white), "%t", "Menu Color White");
	Format(red, sizeof(red), "%t", "Menu Color Red");
	Format(lime, sizeof(lime), "%t", "Menu Color Lime");
	Format(blue, sizeof(blue), "%t", "Menu Color Blue");
	Format(yellow, sizeof(yellow), "%t", "Menu Color Yellow");
	Format(aqua, sizeof(aqua), "%t", "Menu Color Aqua");
	Format(fuchsia, sizeof(fuchsia), "%t", "Menu Color Fuchsia");
	Format(silver, sizeof(silver), "%t", "Menu Color Silver");
	Format(grey, sizeof(grey), "%t", "Menu Color Grey");
	Format(maroon, sizeof(maroon), "%t", "Menu Color Maroon");
	Format(olive, sizeof(olive), "%t", "Menu Color Olive");
	Format(green, sizeof(green), "%t", "Menu Color Green");
	Format(purple, sizeof(purple), "%t", "Menu Color Purple");
	Format(teel, sizeof(teel), "%t", "Menu Color Teel");
	Format(navy, sizeof(navy), "%t", "Menu Color Navy");
	

	
	new Handle:menu = CreateMenu(MenuHandler_BuildLaserColorKill);
	SetMenuTitle(menu, "%t", "Menu Laser Color Kill");

	
	AddMenuItem(menu, "aqua", aqua);
	AddMenuItem(menu, "black", black);
	AddMenuItem(menu, "blue", blue);
	AddMenuItem(menu, "fuchsia", fuchsia);
	AddMenuItem(menu, "green", green);
	AddMenuItem(menu, "grey", grey);
	AddMenuItem(menu, "lime", lime);
	AddMenuItem(menu, "maroon", maroon);
	AddMenuItem(menu, "navy", navy);
	AddMenuItem(menu, "olive", olive);
	AddMenuItem(menu, "purple", purple);
	AddMenuItem(menu, "red", red);
	AddMenuItem(menu, "silver", silver);
	AddMenuItem(menu, "teel", teel);
	AddMenuItem(menu, "yellow", yellow);
	AddMenuItem(menu, "white", white);
	
	
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 20);
}

LaserColorKillMenuItems(client, Handle:menu)
{
	decl String:colors[256];
	
	if(ColorKill[client] == 1)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Kill Menu Aqua");
		AddMenuItem(menu, "g_LaserColorKillMenu", colors);
	}
	else if(ColorKill[client] == 2)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Kill Menu Black");
		AddMenuItem(menu, "g_LaserColorKillMenu", colors);
	}
	else if(ColorKill[client] == 3)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Kill Menu Blue");
		AddMenuItem(menu, "g_LaserColorKillMenu", colors);
	}
	else if(ColorKill[client] == 4)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Kill Menu Fuchsia");
		AddMenuItem(menu, "g_LaserColorKillMenu", colors);
	}
	else if(ColorKill[client] == 5)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Kill Menu Green");
		AddMenuItem(menu, "g_LaserColorKillMenu", colors);
	}
	else if(ColorKill[client] == 6)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Kill Menu Grey");
		AddMenuItem(menu, "g_LaserColorKillMenu", colors);
	}
	else if(ColorKill[client] == 7)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Kill Menu Lime");
		AddMenuItem(menu, "g_LaserColorKillMenu", colors);
	}
	else if(ColorKill[client] == 8)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Kill Menu Maroon");
		AddMenuItem(menu, "g_LaserColorKillMenu", colors);
	}
	else if(ColorKill[client] == 9)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Kill Menu Navy");
		AddMenuItem(menu, "g_LaserColorKillMenu", colors);
	}
	else if(ColorKill[client] == 10)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Kill Menu Olive");
		AddMenuItem(menu, "g_LaserColorKillMenu", colors);
	}
	else if(ColorKill[client] == 11)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Kill Menu Purple");
		AddMenuItem(menu, "g_LaserColorKillMenu", colors);
	}
	else if(ColorKill[client] == 12)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Kill Menu Red");
		AddMenuItem(menu, "g_LaserColorKillMenu", colors);
	}
	else if(ColorKill[client] == 13)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Kill Menu Silver");
		AddMenuItem(menu, "g_LaserColorKillMenu", colors);
	}
	else if(ColorKill[client] == 14)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Kill Menu Teel");
		AddMenuItem(menu, "g_LaserColorKillMenu", colors);
	}
	else if(ColorKill[client] == 15)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Kill Menu Yellow");
		AddMenuItem(menu, "g_LaserColorKillMenu", colors);
	}
	else if(ColorKill[client] == 16)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Kill Menu White");
		AddMenuItem(menu, "g_LaserColorKillMenu", colors);
	}
	else
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Kill Menu No Color");
		AddMenuItem(menu, "g_LaserColorKillMenu", colors);
	}
}

BuildLaserColorHsMenu(client)
{
	decl String:black[64];
	decl String:white[64];
	decl String:red[64];
	decl String:lime[64];
	decl String:blue[64];
	decl String:yellow[64];
	decl String:aqua[64];
	decl String:fuchsia[64];
	decl String:silver[64];
	decl String:grey[64];
	decl String:maroon[64];
	decl String:olive[64];
	decl String:green[64];
	decl String:purple[64];
	decl String:teel[64];
	decl String:navy[64];
	
	Format(black, sizeof(black), "%t", "Menu Color Black");
	Format(white, sizeof(white), "%t", "Menu Color White");
	Format(red, sizeof(red), "%t", "Menu Color Red");
	Format(lime, sizeof(lime), "%t", "Menu Color Lime");
	Format(blue, sizeof(blue), "%t", "Menu Color Blue");
	Format(yellow, sizeof(yellow), "%t", "Menu Color Yellow");
	Format(aqua, sizeof(aqua), "%t", "Menu Color Aqua");
	Format(fuchsia, sizeof(fuchsia), "%t", "Menu Color Fuchsia");
	Format(silver, sizeof(silver), "%t", "Menu Color Silver");
	Format(grey, sizeof(grey), "%t", "Menu Color Grey");
	Format(maroon, sizeof(maroon), "%t", "Menu Color Maroon");
	Format(olive, sizeof(olive), "%t", "Menu Color Olive");
	Format(green, sizeof(green), "%t", "Menu Color Green");
	Format(purple, sizeof(purple), "%t", "Menu Color Purple");
	Format(teel, sizeof(teel), "%t", "Menu Color Teel");
	Format(navy, sizeof(navy), "%t", "Menu Color Navy");
	

	
	new Handle:menu = CreateMenu(MenuHandler_BuildLaserColorHs);
	SetMenuTitle(menu, "%t", "Menu Laser Color Hs");

	
	AddMenuItem(menu, "aqua", aqua);
	AddMenuItem(menu, "black", black);
	AddMenuItem(menu, "blue", blue);
	AddMenuItem(menu, "fuchsia", fuchsia);
	AddMenuItem(menu, "green", green);
	AddMenuItem(menu, "grey", grey);
	AddMenuItem(menu, "lime", lime);
	AddMenuItem(menu, "maroon", maroon);
	AddMenuItem(menu, "navy", navy);
	AddMenuItem(menu, "olive", olive);
	AddMenuItem(menu, "purple", purple);
	AddMenuItem(menu, "red", red);
	AddMenuItem(menu, "silver", silver);
	AddMenuItem(menu, "teel", teel);
	AddMenuItem(menu, "yellow", yellow);
	AddMenuItem(menu, "white", white);
	
	
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 20);
}

LaserColorHsMenuItems(client, Handle:menu)
{
	decl String:colors[256];
	
	if(ColorHs[client] == 1)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Hs Menu Aqua");
		AddMenuItem(menu, "g_LaserColorHsMenu", colors);
	}
	else if(ColorHs[client] == 2)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Hs Menu Black");
		AddMenuItem(menu, "g_LaserColorHsMenu", colors);
	}
	else if(ColorHs[client] == 3)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Hs Menu Blue");
		AddMenuItem(menu, "g_LaserColorHsMenu", colors);
	}
	else if(ColorHs[client] == 4)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Hs Menu Fuchsia");
		AddMenuItem(menu, "g_LaserColorHsMenu", colors);
	}
	else if(ColorHs[client] == 5)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Hs Menu Green");
		AddMenuItem(menu, "g_LaserColorHsMenu", colors);
	}
	else if(ColorHs[client] == 6)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Hs Menu Grey");
		AddMenuItem(menu, "g_LaserColorHsMenu", colors);
	}
	else if(ColorHs[client] == 7)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Hs Menu Lime");
		AddMenuItem(menu, "g_LaserColorHsMenu", colors);
	}
	else if(ColorHs[client] == 8)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Hs Menu Maroon");
		AddMenuItem(menu, "g_LaserColorHsMenu", colors);
	}
	else if(ColorHs[client] == 9)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Hs Menu Navy");
		AddMenuItem(menu, "g_LaserColorHsMenu", colors);
	}
	else if(ColorHs[client] == 10)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Hs Menu Olive");
		AddMenuItem(menu, "g_LaserColorHsMenu", colors);
	}
	else if(ColorHs[client] == 11)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Hs Menu Purple");
		AddMenuItem(menu, "g_LaserColorHsMenu", colors);
	}
	else if(ColorHs[client] == 12)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Hs Menu Red");
		AddMenuItem(menu, "g_LaserColorHsMenu", colors);
	}
	else if(ColorHs[client] == 13)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Hs Menu Silver");
		AddMenuItem(menu, "g_LaserColorHsMenu", colors);
	}
	else if(ColorHs[client] == 14)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Hs Menu Teel");
		AddMenuItem(menu, "g_LaserColorHsMenu", colors);
	}
	else if(ColorHs[client] == 15)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Hs Menu Yellow");
		AddMenuItem(menu, "g_LaserColorHsMenu", colors);
	}
	else if(ColorHs[client] == 16)
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Hs Menu White");
		AddMenuItem(menu, "g_LaserColorHsMenu", colors);
	}
	else
	{
		Format(colors, sizeof(colors), "%t", "OS Laser Color Hs Menu No Color");
		AddMenuItem(menu, "g_LaserColorHsMenu", colors);
	}
}

public MenuHandler_Switch(Handle:menu, MenuAction:action, param1, param2)
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
				BuildSettingsMenu(param1);
			}
		}		
		case MenuAction_Select:
		{
			decl String:choice[256];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "Disable", false))
			{
				SetClientCookie(param1, g_cookieSwitch, "0");
				Switch[param1] = false;
				BuildSettingsMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "Switch off");
				}
			}
			else if (StrEqual(choice, "Enable", false))
			{
				SetClientCookie(param1, g_cookieSwitch, "1");
				Switch[param1] = true;
				BuildSettingsMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "Switch on");
				}
			}
		}
	}
}
	
public MenuHandler_GlowHe(Handle:menu, MenuAction:action, param1, param2)
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
				BuildSettingsMenu(param1);
			}
		}		
		case MenuAction_Select:
		{
			decl String:choice[256];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "Disable", false))
			{
				SetClientCookie(param1, g_cookieGlowHe, "0");
				GlowHe[param1] = false;
				BuildSettingsMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "GlowHe off");
				}
			}
			else if (StrEqual(choice, "Enable", false))
			{
				SetClientCookie(param1, g_cookieGlowHe, "1");
				GlowHe[param1] = true;
				BuildSettingsMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "GlowHe on");
				}
			}
			else if (StrEqual(choice, "g_GlowColorHeMenu", false))
			{
				BuildGlowColorHeMenu(param1);
			}
		}
	}
}

BuildGlowColorHeMenu(client)
{
	decl String:black[64];
	decl String:white[64];
	decl String:red[64];
	decl String:lime[64];
	decl String:blue[64];
	decl String:yellow[64];
	decl String:aqua[64];
	decl String:fuchsia[64];
	decl String:silver[64];
	decl String:grey[64];
	decl String:maroon[64];
	decl String:olive[64];
	decl String:green[64];
	decl String:purple[64];
	decl String:teel[64];
	decl String:navy[64];
	
	Format(black, sizeof(black), "%t", "Menu Color Black");
	Format(white, sizeof(white), "%t", "Menu Color White");
	Format(red, sizeof(red), "%t", "Menu Color Red");
	Format(lime, sizeof(lime), "%t", "Menu Color Lime");
	Format(blue, sizeof(blue), "%t", "Menu Color Blue");
	Format(yellow, sizeof(yellow), "%t", "Menu Color Yellow");
	Format(aqua, sizeof(aqua), "%t", "Menu Color Aqua");
	Format(fuchsia, sizeof(fuchsia), "%t", "Menu Color Fuchsia");
	Format(silver, sizeof(silver), "%t", "Menu Color Silver");
	Format(grey, sizeof(grey), "%t", "Menu Color Grey");
	Format(maroon, sizeof(maroon), "%t", "Menu Color Maroon");
	Format(olive, sizeof(olive), "%t", "Menu Color Olive");
	Format(green, sizeof(green), "%t", "Menu Color Green");
	Format(purple, sizeof(purple), "%t", "Menu Color Purple");
	Format(teel, sizeof(teel), "%t", "Menu Color Teel");
	Format(navy, sizeof(navy), "%t", "Menu Color Navy");
	

	
	new Handle:menu = CreateMenu(MenuHandler_BuildGlowColorHe);
	SetMenuTitle(menu, "%t", "Menu Glow Color He");

	
	AddMenuItem(menu, "aqua", aqua);
	AddMenuItem(menu, "black", black);
	AddMenuItem(menu, "blue", blue);
	AddMenuItem(menu, "fuchsia", fuchsia);
	AddMenuItem(menu, "green", green);
	AddMenuItem(menu, "grey", grey);
	AddMenuItem(menu, "lime", lime);
	AddMenuItem(menu, "maroon", maroon);
	AddMenuItem(menu, "navy", navy);
	AddMenuItem(menu, "olive", olive);
	AddMenuItem(menu, "purple", purple);
	AddMenuItem(menu, "red", red);
	AddMenuItem(menu, "silver", silver);
	AddMenuItem(menu, "teel", teel);
	AddMenuItem(menu, "yellow", yellow);
	AddMenuItem(menu, "white", white);
	
	
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 20);
}

GlowColorHeMenuItems(client, Handle:menu)
{
	decl String:colors[256];
	
	if(ColorGlowHe[client] == 1)
	{
		Format(colors, sizeof(colors), "%t", "OS Glow Color He Menu Aqua");
		AddMenuItem(menu, "g_GlowColorHeMenu", colors);
	}
	else if(ColorGlowHe[client] == 2)
	{
		Format(colors, sizeof(colors), "%t", "OS Glow Color He Menu Black");
		AddMenuItem(menu, "g_GlowColorHeMenu", colors);
	}
	else if(ColorGlowHe[client] == 3)
	{
		Format(colors, sizeof(colors), "%t", "OS Glow Color He Menu Blue");
		AddMenuItem(menu, "g_GlowColorHeMenu", colors);
	}
	else if(ColorGlowHe[client] == 4)
	{
		Format(colors, sizeof(colors), "%t", "OS Glow Color He Menu Fuchsia");
		AddMenuItem(menu, "g_GlowColorHeMenu", colors);
	}
	else if(ColorGlowHe[client] == 5)
	{
		Format(colors, sizeof(colors), "%t", "OS Glow Color He Menu Green");
		AddMenuItem(menu, "g_GlowColorHeMenu", colors);
	}
	else if(ColorGlowHe[client] == 6)
	{
		Format(colors, sizeof(colors), "%t", "OS Glow Color He Menu Grey");
		AddMenuItem(menu, "g_GlowColorHeMenu", colors);
	}
	else if(ColorGlowHe[client] == 7)
	{
		Format(colors, sizeof(colors), "%t", "OS Glow Color He Menu Lime");
		AddMenuItem(menu, "g_GlowColorHeMenu", colors);
	}
	else if(ColorGlowHe[client] == 8)
	{
		Format(colors, sizeof(colors), "%t", "OS Glow Color He Menu Maroon");
		AddMenuItem(menu, "g_GlowColorHeMenu", colors);
	}
	else if(ColorGlowHe[client] == 9)
	{
		Format(colors, sizeof(colors), "%t", "OS Glow Color He Menu Navy");
		AddMenuItem(menu, "g_GlowColorHeMenu", colors);
	}
	else if(ColorGlowHe[client] == 10)
	{
		Format(colors, sizeof(colors), "%t", "OS Glow Color He Menu Olive");
		AddMenuItem(menu, "g_GlowColorHeMenu", colors);
	}
	else if(ColorGlowHe[client] == 11)
	{
		Format(colors, sizeof(colors), "%t", "OS Glow Color He Menu Purple");
		AddMenuItem(menu, "g_GlowColorHeMenu", colors);
	}
	else if(ColorGlowHe[client] == 12)
	{
		Format(colors, sizeof(colors), "%t", "OS Glow Color He Menu Red");
		AddMenuItem(menu, "g_GlowColorHeMenu", colors);
	}
	else if(ColorGlowHe[client] == 13)
	{
		Format(colors, sizeof(colors), "%t", "OS Glow Color He Menu Silver");
		AddMenuItem(menu, "g_GlowColorHeMenu", colors);
	}
	else if(ColorGlowHe[client] == 14)
	{
		Format(colors, sizeof(colors), "%t", "OS Glow Color He Menu Teel");
		AddMenuItem(menu, "g_GlowColorHeMenu", colors);
	}
	else if(ColorGlowHe[client] == 15)
	{
		Format(colors, sizeof(colors), "%t", "OS Glow Color He Menu Yellow");
		AddMenuItem(menu, "g_GlowColorHeMenu", colors);
	}
	else if(ColorGlowHe[client] == 16)
	{
		Format(colors, sizeof(colors), "%t", "OS Glow Color He Menu White");
		AddMenuItem(menu, "g_GlowColorHeMenu", colors);
	}
	else
	{
		Format(colors, sizeof(colors), "%t", "OS Glow Color He Menu No Color");
		AddMenuItem(menu, "g_GlowColorHeMenu", colors);
	}
}

public MenuHandler_BeamHe(Handle:menu, MenuAction:action, param1, param2)
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
				BuildSettingsMenu(param1);
			}
		}		
		case MenuAction_Select:
		{
			decl String:choice[256];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "Disable", false))
			{
				SetClientCookie(param1, g_cookieBeamHe, "0");
				BeamHe[param1] = false;
				BuildSettingsMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "BeamHe off");
				}
			}
			else if (StrEqual(choice, "Enable", false))
			{
				SetClientCookie(param1, g_cookieBeamHe, "1");
				BeamHe[param1] = true;
				BuildSettingsMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "BeamHe on");
				}
			}
			else if (StrEqual(choice, "g_BeamColorHeMenu", false))
			{
				BuildBeamColorHeMenu(param1);
			}
		}
	}
}

BuildBeamColorHeMenu(client)
{
	decl String:black[64];
	decl String:white[64];
	decl String:red[64];
	decl String:lime[64];
	decl String:blue[64];
	decl String:yellow[64];
	decl String:aqua[64];
	decl String:fuchsia[64];
	decl String:silver[64];
	decl String:grey[64];
	decl String:maroon[64];
	decl String:olive[64];
	decl String:green[64];
	decl String:purple[64];
	decl String:teel[64];
	decl String:navy[64];
	
	Format(black, sizeof(black), "%t", "Menu Color Black");
	Format(white, sizeof(white), "%t", "Menu Color White");
	Format(red, sizeof(red), "%t", "Menu Color Red");
	Format(lime, sizeof(lime), "%t", "Menu Color Lime");
	Format(blue, sizeof(blue), "%t", "Menu Color Blue");
	Format(yellow, sizeof(yellow), "%t", "Menu Color Yellow");
	Format(aqua, sizeof(aqua), "%t", "Menu Color Aqua");
	Format(fuchsia, sizeof(fuchsia), "%t", "Menu Color Fuchsia");
	Format(silver, sizeof(silver), "%t", "Menu Color Silver");
	Format(grey, sizeof(grey), "%t", "Menu Color Grey");
	Format(maroon, sizeof(maroon), "%t", "Menu Color Maroon");
	Format(olive, sizeof(olive), "%t", "Menu Color Olive");
	Format(green, sizeof(green), "%t", "Menu Color Green");
	Format(purple, sizeof(purple), "%t", "Menu Color Purple");
	Format(teel, sizeof(teel), "%t", "Menu Color Teel");
	Format(navy, sizeof(navy), "%t", "Menu Color Navy");
	

	
	new Handle:menu = CreateMenu(MenuHandler_BuildBeamColorHe);
	SetMenuTitle(menu, "%t", "Menu Beam Color He");

	
	AddMenuItem(menu, "aqua", aqua);
	AddMenuItem(menu, "black", black);
	AddMenuItem(menu, "blue", blue);
	AddMenuItem(menu, "fuchsia", fuchsia);
	AddMenuItem(menu, "green", green);
	AddMenuItem(menu, "grey", grey);
	AddMenuItem(menu, "lime", lime);
	AddMenuItem(menu, "maroon", maroon);
	AddMenuItem(menu, "navy", navy);
	AddMenuItem(menu, "olive", olive);
	AddMenuItem(menu, "purple", purple);
	AddMenuItem(menu, "red", red);
	AddMenuItem(menu, "silver", silver);
	AddMenuItem(menu, "teel", teel);
	AddMenuItem(menu, "yellow", yellow);
	AddMenuItem(menu, "white", white);
	
	
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 20);
}

BeamColorHeMenuItems(client, Handle:menu)
{
	decl String:colors[256];
	
	if(ColorBeamHe[client] == 1)
	{
		Format(colors, sizeof(colors), "%t", "OS Beam Color He Menu Aqua");
		AddMenuItem(menu, "g_BeamColorHeMenu", colors);
	}
	else if(ColorBeamHe[client] == 2)
	{
		Format(colors, sizeof(colors), "%t", "OS Beam Color He Menu Black");
		AddMenuItem(menu, "g_BeamColorHeMenu", colors);
	}
	else if(ColorBeamHe[client] == 3)
	{
		Format(colors, sizeof(colors), "%t", "OS Beam Color He Menu Blue");
		AddMenuItem(menu, "g_BeamColorHeMenu", colors);
	}
	else if(ColorBeamHe[client] == 4)
	{
		Format(colors, sizeof(colors), "%t", "OS Beam Color He Menu Fuchsia");
		AddMenuItem(menu, "g_BeamColorHeMenu", colors);
	}
	else if(ColorBeamHe[client] == 5)
	{
		Format(colors, sizeof(colors), "%t", "OS Beam Color He Menu Green");
		AddMenuItem(menu, "g_BeamColorHeMenu", colors);
	}
	else if(ColorBeamHe[client] == 6)
	{
		Format(colors, sizeof(colors), "%t", "OS Beam Color He Menu Grey");
		AddMenuItem(menu, "g_BeamColorHeMenu", colors);
	}
	else if(ColorBeamHe[client] == 7)
	{
		Format(colors, sizeof(colors), "%t", "OS Beam Color He Menu Lime");
		AddMenuItem(menu, "g_BeamColorHeMenu", colors);
	}
	else if(ColorBeamHe[client] == 8)
	{
		Format(colors, sizeof(colors), "%t", "OS Beam Color He Menu Maroon");
		AddMenuItem(menu, "g_BeamColorHeMenu", colors);
	}
	else if(ColorBeamHe[client] == 9)
	{
		Format(colors, sizeof(colors), "%t", "OS Beam Color He Menu Navy");
		AddMenuItem(menu, "g_BeamColorHeMenu", colors);
	}
	else if(ColorBeamHe[client] == 10)
	{
		Format(colors, sizeof(colors), "%t", "OS Beam Color He Menu Olive");
		AddMenuItem(menu, "g_BeamColorHeMenu", colors);
	}
	else if(ColorBeamHe[client] == 11)
	{
		Format(colors, sizeof(colors), "%t", "OS Beam Color He Menu Purple");
		AddMenuItem(menu, "g_BeamColorHeMenu", colors);
	}
	else if(ColorBeamHe[client] == 12)
	{
		Format(colors, sizeof(colors), "%t", "OS Beam Color He Menu Red");
		AddMenuItem(menu, "g_BeamColorHeMenu", colors);
	}
	else if(ColorBeamHe[client] == 13)
	{
		Format(colors, sizeof(colors), "%t", "OS Beam Color He Menu Silver");
		AddMenuItem(menu, "g_BeamColorHeMenu", colors);
	}
	else if(ColorBeamHe[client] == 14)
	{
		Format(colors, sizeof(colors), "%t", "OS Beam Color He Menu Teel");
		AddMenuItem(menu, "g_BeamColorHeMenu", colors);
	}
	else if(ColorBeamHe[client] == 15)
	{
		Format(colors, sizeof(colors), "%t", "OS Beam Color He Menu Yellow");
		AddMenuItem(menu, "g_BeamColorHeMenu", colors);
	}
	else if(ColorBeamHe[client] == 16)
	{
		Format(colors, sizeof(colors), "%t", "OS Beam Color He Menu White");
		AddMenuItem(menu, "g_BeamColorHeMenu", colors);
	}
	else
	{
		Format(colors, sizeof(colors), "%t", "OS Beam Color He Menu No Color");
		AddMenuItem(menu, "g_BeamColorHeMenu", colors);
	}
}

public MenuHandler_Messages(Handle:menu, MenuAction:action, param1, param2)
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
				BuildSettingsMenu(param1);
			}
		}		
		case MenuAction_Select:
		{
			decl String:choice[256];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "Disable", false))
			{
				SetClientCookie(param1, g_cookieMessages, "0");
				Messages[param1] = false;
				BuildSettingsMenu(param1);
				CPrintToChat(param1, "%t", "Messages off");
			}
			else if (StrEqual(choice, "Enable", false))
			{
				SetClientCookie(param1, g_cookieMessages, "1");
				Messages[param1] = true;
				BuildSettingsMenu(param1);
				CPrintToChat(param1, "%t", "Messages on");

			}
		}
	}
}

public MenuHandler_MessagesCMD(Handle:menu, MenuAction:action, param1, param2)
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
				BuildSettingsMenu(param1);
			}
		}		
		case MenuAction_Select:
		{
			decl String:choice[256];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "Disable", false))
			{
				SetClientCookie(param1, g_cookieMessagesCMD, "0");
				MessagesCMD[param1] = false;
				BuildSettingsMenu(param1);
				CPrintToChat(param1, "%t", "MessagesCMD off");
			}
			else if (StrEqual(choice, "Enable", false))
			{
				SetClientCookie(param1, g_cookieMessagesCMD, "1");
				MessagesCMD[param1] = true;
				BuildSettingsMenu(param1);
				CPrintToChat(param1, "%t", "MessagesCMD on");
			}
		}
	}
}

public MenuHandler_Sounds(Handle:menu, MenuAction:action, param1, param2)
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
				BuildSettingsMenu(param1);
			}
		}		
		case MenuAction_Select:
		{
			decl String:choice[256];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "Disable", false))
			{
				SetClientCookie(param1, g_cookieSounds, "0");
				Sounds[param1] = false;
				BuildSettingsMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "Sounds off");
				}
			}
			else if (StrEqual(choice, "Enable", false))
			{
				SetClientCookie(param1, g_cookieSounds, "1");
				Sounds[param1] = true;
				BuildSettingsMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "Sounds on");
				}
			}
			else if (StrEqual(choice, "Hs", false))
			{
				if(SoundsKillHs[param1])
				{
					SetClientCookie(param1, g_cookieSoundsKillHs, "0");
					SoundsKillHs[param1] = false;
					BuildSoundsMenu(param1);
					if(Messages[param1] || MessagesCMD[param1])
					{
						CPrintToChat(param1, "%t", "Sounds Hs off");
					}
				}
				else
				{
					SetClientCookie(param1, g_cookieSoundsKillHs, "1");
					SoundsKillHs[param1] = true;
					BuildSoundsMenu(param1);
					if(Messages[param1] || MessagesCMD[param1])
					{
						CPrintToChat(param1, "%t", "Sounds Hs on");
					}
				}
			}
			else if (StrEqual(choice, "Spree", false))
			{
				if(SoundsKillSpree[param1])
				{
					SetClientCookie(param1, g_cookieSoundsKillSpree, "0");
					SoundsKillSpree[param1] = false;
					BuildSoundsMenu(param1);
					if(Messages[param1] || MessagesCMD[param1])
					{
						CPrintToChat(param1, "%t", "Sounds Spree off");
					}
				}
				else
				{
					SetClientCookie(param1, g_cookieSoundsKillSpree, "1");
					SoundsKillSpree[param1] = true;
					BuildSoundsMenu(param1);
					if(Messages[param1] || MessagesCMD[param1])
					{
						CPrintToChat(param1, "%t", "Sounds Spree on");
					}
				}
			}
			else if (StrEqual(choice, "Rampage", false))
			{
				if(SoundsKillRampage[param1])
				{
					SetClientCookie(param1, g_cookieSoundsKillRampage, "0");
					SoundsKillRampage[param1] = false;
					BuildSoundsMenu(param1);
					if(Messages[param1] || MessagesCMD[param1])
					{
						CPrintToChat(param1, "%t", "Sounds Rampage off");
					}
				}
				else
				{
					SetClientCookie(param1, g_cookieSoundsKillRampage, "1");
					SoundsKillRampage[param1] = true;
					BuildSoundsMenu(param1);
					if(Messages[param1] || MessagesCMD[param1])
					{
						CPrintToChat(param1, "%t", "Sounds Rampage on");
					}
				}
			}
			else if (StrEqual(choice, "Unstoppable", false))
			{
				if(SoundsKillUnstoppable[param1])
				{
					SetClientCookie(param1, g_cookieSoundsKillUnstoppable, "0");
					SoundsKillUnstoppable[param1] = false;
					BuildSoundsMenu(param1);
					if(Messages[param1] || MessagesCMD[param1])
					{
						CPrintToChat(param1, "%t", "Sounds Unstoppable off");
					}
				}
				else
				{
					SetClientCookie(param1, g_cookieSoundsKillUnstoppable, "1");
					SoundsKillUnstoppable[param1] = true;
					BuildSoundsMenu(param1);
					if(Messages[param1] || MessagesCMD[param1])
					{
						CPrintToChat(param1, "%t", "Sounds Unstoppable on");
					}
				}
			}
			else if (StrEqual(choice, "Domination", false))
			{
				if(SoundsKillDomination[param1])
				{
					SetClientCookie(param1, g_cookieSoundsKillDomination, "0");
					SoundsKillDomination[param1] = false;
					BuildSoundsMenu(param1);
					if(Messages[param1] || MessagesCMD[param1])
					{
						CPrintToChat(param1, "%t", "Sounds Domination off");
					}
				}
				else
				{
					SetClientCookie(param1, g_cookieSoundsKillDomination, "1");
					SoundsKillDomination[param1] = true;
					BuildSoundsMenu(param1);
					if(Messages[param1] || MessagesCMD[param1])
					{
						CPrintToChat(param1, "%t", "Sounds Domination on");
					}
				}
			}
			else if (StrEqual(choice, "Godlike", false))
			{
				if(SoundsKillGodlike[param1])
				{
					SetClientCookie(param1, g_cookieSoundsKillGodlike, "0");
					SoundsKillGodlike[param1] = false;
					BuildSoundsMenu(param1);
					if(Messages[param1] || MessagesCMD[param1])
					{
						CPrintToChat(param1, "%t", "Sounds Godlike off");
					}
				}
				else
				{
					SetClientCookie(param1, g_cookieSoundsKillGodlike, "1");
					SoundsKillGodlike[param1] = true;
					BuildSoundsMenu(param1);
					if(Messages[param1] || MessagesCMD[param1])
					{
						CPrintToChat(param1, "%t", "Sounds Godlike on");
					}
				}
			}
			else if (StrEqual(choice, "Double", false))
			{
				if(SoundsKillDouble[param1])
				{
					SetClientCookie(param1, g_cookieSoundsKillDouble, "0");
					SoundsKillDouble[param1] = false;
					BuildSoundsMenu(param1);
					if(Messages[param1] || MessagesCMD[param1])
					{
						CPrintToChat(param1, "%t", "Sounds Double off");
					}
				}
				else
				{
					SetClientCookie(param1, g_cookieSoundsKillDouble, "1");
					SoundsKillDouble[param1] = true;
					BuildSoundsMenu(param1);
					if(Messages[param1] || MessagesCMD[param1])
					{
						CPrintToChat(param1, "%t", "Sounds Double on");
					}
				}
			}
			else if (StrEqual(choice, "Triple", false))
			{
				if(SoundsKillTriple[param1])
				{
					SetClientCookie(param1, g_cookieSoundsKillTriple, "0");
					SoundsKillTriple[param1] = false;
					BuildSoundsMenu(param1);
					if(Messages[param1] || MessagesCMD[param1])
					{
						CPrintToChat(param1, "%t", "Sounds Triple off");
					}
				}
				else
				{
					SetClientCookie(param1, g_cookieSoundsKillTriple, "1");
					SoundsKillTriple[param1] = true;
					BuildSoundsMenu(param1);
					if(Messages[param1] || MessagesCMD[param1])
					{
						CPrintToChat(param1, "%t", "Sounds Triple on");
					}
				}
			}
			else if (StrEqual(choice, "Monster", false))
			{
				if(SoundsKillMonster[param1])
				{
					SetClientCookie(param1, g_cookieSoundsKillMonster, "0");
					SoundsKillMonster[param1] = false;
					BuildSoundsMenu(param1);
					if(Messages[param1] || MessagesCMD[param1])
					{
						CPrintToChat(param1, "%t", "Sounds Monster off");
					}
				}
				else
				{
					SetClientCookie(param1, g_cookieSoundsKillMonster, "1");
					SoundsKillMonster[param1] = true;
					BuildSoundsMenu(param1);
					if(Messages[param1] || MessagesCMD[param1])
					{
						CPrintToChat(param1, "%t", "Sounds Monster on");
					}
				}
			}
			else if (StrEqual(choice, "FirstPosition", false))
			{
				if(SoundsFirstPosition[param1])
				{
					SetClientCookie(param1, g_cookieSoundsFirstPosition, "0");
					SoundsFirstPosition[param1] = false;
					BuildSoundsMenu(param1);
					if(Messages[param1] || MessagesCMD[param1])
					{
						CPrintToChat(param1, "%t", "Sounds FirstPosition off");
					}
				}
				else
				{
					SetClientCookie(param1, g_cookieSoundsFirstPosition, "1");
					SoundsFirstPosition[param1] = true;
					BuildSoundsMenu(param1);
					if(Messages[param1] || MessagesCMD[param1])
					{
						CPrintToChat(param1, "%t", "Sounds FirstPosition on");
					}
				}
			}
		}
	}
}

public MenuHandler_Knifes(Handle:menu, MenuAction:action, param1, param2)
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
				BuildSettingsMenu(param1);
			}
		}		
		case MenuAction_Select:
		{
			decl String:choice[256];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "knife", false))
			{
				SetClientCookie(param1, g_cookieKnife, "0");
				Knifes[param1] = 0;
				BuildSettingsMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Knifes knife");
				}
				
			}
			else if (StrEqual(choice, "bayonet", false))
			{
				SetClientCookie(param1, g_cookieKnife, "1");
				Knifes[param1] = 1;
				BuildSettingsMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Knifes bayonet");
				}
			}
			else if (StrEqual(choice, "gut", false))
			{
				SetClientCookie(param1, g_cookieKnife, "2");
				Knifes[param1] = 2;
				BuildSettingsMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Knifes gut");
				}
			}
			else if (StrEqual(choice, "flip", false))
			{
				SetClientCookie(param1, g_cookieKnife, "3");
				Knifes[param1] = 3;
				BuildSettingsMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Knifes flip");
				}
			}
			else if (StrEqual(choice, "m9", false))
			{
				SetClientCookie(param1, g_cookieKnife, "4");
				Knifes[param1] = 4;
				BuildSettingsMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Knifes m9");
				}
			}
			else if (StrEqual(choice, "karambit", false))
			{
				SetClientCookie(param1, g_cookieKnife, "5");
				Knifes[param1] = 5;
				BuildSettingsMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Knifes karambit");
				}
			}
			else if (StrEqual(choice, "huntsman", false))
			{
				SetClientCookie(param1, g_cookieKnife, "6");
				Knifes[param1] = 6;
				BuildSettingsMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Knifes huntsman");
				}
			}
			else if (StrEqual(choice, "butterfly", false))
			{
				SetClientCookie(param1, g_cookieKnife, "7");
				Knifes[param1] = 7;
				BuildSettingsMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Knifes butterfly");
				}
			}
			else if (StrEqual(choice, "golden", false))
			{
				SetClientCookie(param1, g_cookieKnife, "8");
				Knifes[param1] = 8;
				BuildSettingsMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Knifes golden");
				}
			}
		}
	}
}	

public MenuHandler_BuildLaserColorKill(Handle:menu, MenuAction:action, param1, param2)
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
				BuildLaserMenu(param1);
			}
		}		
		case MenuAction_Select:
		{
			decl String:choice[256];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "aqua", false))
			{
				ColorDefaultKill[param1][0] = ColorAqua[0];
				ColorDefaultKill[param1][1] = ColorAqua[1];
				ColorDefaultKill[param1][2] = ColorAqua[2];
				ColorDefaultKill[param1][3] = ColorAqua[3];
				ColorKill[param1] = 1;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Kill Aqua");
				}
			}
			else if (StrEqual(choice, "black", false))
			{
				ColorDefaultKill[param1][0] = ColorBlack[0];
				ColorDefaultKill[param1][1] = ColorBlack[1];
				ColorDefaultKill[param1][2] = ColorBlack[2];
				ColorDefaultKill[param1][3] = ColorBlack[3];
				ColorKill[param1] = 2;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Kill Black");
				}
			}
			else if (StrEqual(choice, "blue", false))
			{
				ColorDefaultKill[param1][0] = ColorBlue[0];
				ColorDefaultKill[param1][1] = ColorBlue[1];
				ColorDefaultKill[param1][2] = ColorBlue[2];
				ColorDefaultKill[param1][3] = ColorBlue[3];
				ColorKill[param1] = 3;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Kill Blue");
				}
			}
			else if (StrEqual(choice, "fuchsia", false))
			{
				ColorDefaultKill[param1][0] = ColorFuschia[0];
				ColorDefaultKill[param1][1] = ColorFuschia[1];
				ColorDefaultKill[param1][2] = ColorFuschia[2];
				ColorDefaultKill[param1][3] = ColorFuschia[3];
				ColorKill[param1] = 4;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Kill Fuchsia");
				}
			}
			else if (StrEqual(choice, "green", false))
			{
				ColorDefaultKill[param1][0] = ColorGreen[0];
				ColorDefaultKill[param1][1] = ColorGreen[1];
				ColorDefaultKill[param1][2] = ColorGreen[2];
				ColorDefaultKill[param1][3] = ColorGreen[3];
				ColorKill[param1] = 5;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Kill Green");
				}
			}
			else if (StrEqual(choice, "grey", false))
			{
				ColorDefaultKill[param1][0] = ColorGray[0];
				ColorDefaultKill[param1][1] = ColorGray[1];
				ColorDefaultKill[param1][2] = ColorGray[2];
				ColorDefaultKill[param1][3] = ColorGray[3];
				ColorKill[param1] = 6;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Kill Grey");
				}
			}
			else if (StrEqual(choice, "lime", false))
			{
				ColorDefaultKill[param1][0] = ColorLime[0];
				ColorDefaultKill[param1][1] = ColorLime[1];
				ColorDefaultKill[param1][2] = ColorLime[2];
				ColorDefaultKill[param1][3] = ColorLime[3];
				ColorKill[param1] = 7;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Kill Lime");
				}
			}
			else if (StrEqual(choice, "maroon", false))
			{
				ColorDefaultKill[param1][0] = ColorMaroon[0];
				ColorDefaultKill[param1][1] = ColorMaroon[1];
				ColorDefaultKill[param1][2] = ColorMaroon[2];
				ColorDefaultKill[param1][3] = ColorMaroon[3];
				ColorKill[param1] = 8;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Kill Maroon");
				}
			}
			else if (StrEqual(choice, "navy", false))
			{
				ColorDefaultKill[param1][0] = ColorNavy[0];
				ColorDefaultKill[param1][1] = ColorNavy[1];
				ColorDefaultKill[param1][2] = ColorNavy[2];
				ColorDefaultKill[param1][3] = ColorNavy[3];
				ColorKill[param1] = 9;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Kill Navy");
				}
			}
			else if (StrEqual(choice, "olive", false))
			{
				ColorDefaultKill[param1][0] = ColorOlive[0];
				ColorDefaultKill[param1][1] = ColorOlive[1];
				ColorDefaultKill[param1][2] = ColorOlive[2];
				ColorDefaultKill[param1][3] = ColorOlive[3];
				ColorKill[param1] = 10;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Kill Olive");
				}
			}
			else if (StrEqual(choice, "purple", false))
			{
				ColorDefaultKill[param1][0] = ColorPurple[0];
				ColorDefaultKill[param1][1] = ColorPurple[1];
				ColorDefaultKill[param1][2] = ColorPurple[2];
				ColorDefaultKill[param1][3] = ColorPurple[3];
				ColorKill[param1] = 11;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Kill Purple");
				}
			}
			else if (StrEqual(choice, "red", false))
			{
				ColorDefaultKill[param1][0] = ColorRed[0];
				ColorDefaultKill[param1][1] = ColorRed[1];
				ColorDefaultKill[param1][2] = ColorRed[2];
				ColorDefaultKill[param1][3] = ColorRed[3];
				ColorKill[param1] = 12;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Kill Red");
				}
			}
			else if (StrEqual(choice, "silver", false))
			{
				ColorDefaultKill[param1][0] = ColorSilver[0];
				ColorDefaultKill[param1][1] = ColorSilver[1];
				ColorDefaultKill[param1][2] = ColorSilver[2];
				ColorDefaultKill[param1][3] = ColorSilver[3];
				ColorKill[param1] = 13;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Kill Silver");
				}
			}
			else if (StrEqual(choice, "teel", false))
			{
				ColorDefaultKill[param1][0] = ColorTeal[0];
				ColorDefaultKill[param1][1] = ColorTeal[1];
				ColorDefaultKill[param1][2] = ColorTeal[2];
				ColorDefaultKill[param1][3] = ColorTeal[3];
				ColorKill[param1] = 14;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Kill Teel");
				}
			}
			else if (StrEqual(choice, "yellow", false))
			{
				ColorDefaultKill[param1][0] = ColorYellow[0];
				ColorDefaultKill[param1][1] = ColorYellow[1];
				ColorDefaultKill[param1][2] = ColorYellow[2];
				ColorDefaultKill[param1][3] = ColorYellow[3];
				ColorKill[param1] = 15;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Kill Yellow");
				}
			}
			else if (StrEqual(choice, "white", false))
			{
				ColorDefaultKill[param1][0] = ColorWhite[0];
				ColorDefaultKill[param1][1] = ColorWhite[1];
				ColorDefaultKill[param1][2] = ColorWhite[2];
				ColorDefaultKill[param1][3] = ColorWhite[3];
				ColorKill[param1] = 16;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Kill White");
				}
			}
		}
	}
}

public MenuHandler_BuildLaserColorHs(Handle:menu, MenuAction:action, param1, param2)
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
				BuildLaserMenu(param1);
			}
		}		
		case MenuAction_Select:
		{
			decl String:choice[256];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "aqua", false))
			{
				ColorDefaultHs[param1][0] = ColorAqua[0];
				ColorDefaultHs[param1][1] = ColorAqua[1];
				ColorDefaultHs[param1][2] = ColorAqua[2];
				ColorDefaultHs[param1][3] = ColorAqua[3];
				ColorHs[param1] = 1;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Hs Aqua");
				}
			}
			else if (StrEqual(choice, "black", false))
			{
				ColorDefaultHs[param1][0] = ColorBlack[0];
				ColorDefaultHs[param1][1] = ColorBlack[1];
				ColorDefaultHs[param1][2] = ColorBlack[2];
				ColorDefaultHs[param1][3] = ColorBlack[3];
				ColorHs[param1] = 2;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Hs Black");
				}
			}
			else if (StrEqual(choice, "blue", false))
			{
				ColorDefaultHs[param1][0] = ColorBlue[0];
				ColorDefaultHs[param1][1] = ColorBlue[1];
				ColorDefaultHs[param1][2] = ColorBlue[2];
				ColorDefaultHs[param1][3] = ColorBlue[3];
				ColorHs[param1] = 3;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Hs Blue");
				}
			}
			else if (StrEqual(choice, "fuchsia", false))
			{
				ColorDefaultHs[param1][0] = ColorFuschia[0];
				ColorDefaultHs[param1][1] = ColorFuschia[1];
				ColorDefaultHs[param1][2] = ColorFuschia[2];
				ColorDefaultHs[param1][3] = ColorFuschia[3];
				ColorHs[param1] = 4;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Hs Fuchsia");
				}
			}
			else if (StrEqual(choice, "green", false))
			{
				ColorDefaultHs[param1][0] = ColorGreen[0];
				ColorDefaultHs[param1][1] = ColorGreen[1];
				ColorDefaultHs[param1][2] = ColorGreen[2];
				ColorDefaultHs[param1][3] = ColorGreen[3];
				ColorHs[param1] = 5;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Hs Green");
				}
			}
			else if (StrEqual(choice, "grey", false))
			{
				ColorDefaultHs[param1][0] = ColorGray[0];
				ColorDefaultHs[param1][1] = ColorGray[1];
				ColorDefaultHs[param1][2] = ColorGray[2];
				ColorDefaultHs[param1][3] = ColorGray[3];
				ColorHs[param1] = 6;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Hs Grey");
				}
			}
			else if (StrEqual(choice, "lime", false))
			{
				ColorDefaultHs[param1][0] = ColorLime[0];
				ColorDefaultHs[param1][1] = ColorLime[1];
				ColorDefaultHs[param1][2] = ColorLime[2];
				ColorDefaultHs[param1][3] = ColorLime[3];
				ColorHs[param1] = 7;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Hs Lime");
				}
			}
			else if (StrEqual(choice, "maroon", false))
			{
				ColorDefaultHs[param1][0] = ColorMaroon[0];
				ColorDefaultHs[param1][1] = ColorMaroon[1];
				ColorDefaultHs[param1][2] = ColorMaroon[2];
				ColorDefaultHs[param1][3] = ColorMaroon[3];
				ColorHs[param1] = 8;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Hs Maroon");
				}
			}
			else if (StrEqual(choice, "navy", false))
			{
				ColorDefaultHs[param1][0] = ColorNavy[0];
				ColorDefaultHs[param1][1] = ColorNavy[1];
				ColorDefaultHs[param1][2] = ColorNavy[2];
				ColorDefaultHs[param1][3] = ColorNavy[3];
				ColorHs[param1] = 9;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Hs Navy");
				}
			}
			else if (StrEqual(choice, "olive", false))
			{
				ColorDefaultHs[param1][0] = ColorOlive[0];
				ColorDefaultHs[param1][1] = ColorOlive[1];
				ColorDefaultHs[param1][2] = ColorOlive[2];
				ColorDefaultHs[param1][3] = ColorOlive[3];
				ColorHs[param1] = 10;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Hs Olive");
				}
			}
			else if (StrEqual(choice, "purple", false))
			{
				ColorDefaultHs[param1][0] = ColorPurple[0];
				ColorDefaultHs[param1][1] = ColorPurple[1];
				ColorDefaultHs[param1][2] = ColorPurple[2];
				ColorDefaultHs[param1][3] = ColorPurple[3];
				ColorHs[param1] = 11;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Hs Purple");
				}
			}
			else if (StrEqual(choice, "red", false))
			{
				ColorDefaultHs[param1][0] = ColorRed[0];
				ColorDefaultHs[param1][1] = ColorRed[1];
				ColorDefaultHs[param1][2] = ColorRed[2];
				ColorDefaultHs[param1][3] = ColorRed[3];
				ColorHs[param1] = 12;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Hs Red");
				}
			}
			else if (StrEqual(choice, "silver", false))
			{
				ColorDefaultHs[param1][0] = ColorSilver[0];
				ColorDefaultHs[param1][1] = ColorSilver[1];
				ColorDefaultHs[param1][2] = ColorSilver[2];
				ColorDefaultHs[param1][3] = ColorSilver[3];
				ColorHs[param1] = 13;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Hs Silver");
				}
			}
			else if (StrEqual(choice, "teel", false))
			{
				ColorDefaultHs[param1][0] = ColorTeal[0];
				ColorDefaultHs[param1][1] = ColorTeal[1];
				ColorDefaultHs[param1][2] = ColorTeal[2];
				ColorDefaultHs[param1][3] = ColorTeal[3];
				ColorHs[param1] = 14;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Hs Teel");
				}
			}
			else if (StrEqual(choice, "yellow", false))
			{
				ColorDefaultHs[param1][0] = ColorYellow[0];
				ColorDefaultHs[param1][1] = ColorYellow[1];
				ColorDefaultHs[param1][2] = ColorYellow[2];
				ColorDefaultHs[param1][3] = ColorYellow[3];
				ColorHs[param1] = 15;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Hs Yellow");
				}
			}
			else if (StrEqual(choice, "white", false))
			{
				ColorDefaultHs[param1][0] = ColorWhite[0];
				ColorDefaultHs[param1][1] = ColorWhite[1];
				ColorDefaultHs[param1][2] = ColorWhite[2];
				ColorDefaultHs[param1][3] = ColorWhite[3];
				ColorHs[param1] = 16;
				BuildLaserMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Laser Color Hs White");
				}
			}
		}
	}
}	

public MenuHandler_BuildBeamColorHe(Handle:menu, MenuAction:action, param1, param2)
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
				BuildBeamHeMenu(param1);
			}
		}		
		case MenuAction_Select:
		{
			decl String:choice[256];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "aqua", false))
			{
				ColorDefaultTrail[param1][0] = ColorAqua[0];
				ColorDefaultTrail[param1][1] = ColorAqua[1];
				ColorDefaultTrail[param1][2] = ColorAqua[2];
				ColorDefaultTrail[param1][3] = ColorAqua[3];
				ColorBeamHe[param1] = 1;
				BuildBeamHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Beam Color He Aqua");
				}
			}
			else if (StrEqual(choice, "black", false))
			{
				ColorDefaultTrail[param1][0] = ColorBlack[0];
				ColorDefaultTrail[param1][1] = ColorBlack[1];
				ColorDefaultTrail[param1][2] = ColorBlack[2];
				ColorDefaultTrail[param1][3] = ColorBlack[3];
				ColorBeamHe[param1] = 2;
				BuildBeamHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Beam Color He Black");
				}
			}
			else if (StrEqual(choice, "blue", false))
			{
				ColorDefaultTrail[param1][0] = ColorBlue[0];
				ColorDefaultTrail[param1][1] = ColorBlue[1];
				ColorDefaultTrail[param1][2] = ColorBlue[2];
				ColorDefaultTrail[param1][3] = ColorBlue[3];
				ColorBeamHe[param1] = 3;
				BuildBeamHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Beam Color He Blue");
				}
			}
			else if (StrEqual(choice, "fuchsia", false))
			{
				ColorDefaultTrail[param1][0] = ColorFuschia[0];
				ColorDefaultTrail[param1][1] = ColorFuschia[1];
				ColorDefaultTrail[param1][2] = ColorFuschia[2];
				ColorDefaultTrail[param1][3] = ColorFuschia[3];
				ColorBeamHe[param1] = 4;
				BuildBeamHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Beam Color He Fuchsia");
				}
			}
			else if (StrEqual(choice, "green", false))
			{
				ColorDefaultTrail[param1][0] = ColorGreen[0];
				ColorDefaultTrail[param1][1] = ColorGreen[1];
				ColorDefaultTrail[param1][2] = ColorGreen[2];
				ColorDefaultTrail[param1][3] = ColorGreen[3];
				ColorBeamHe[param1] = 5;
				BuildBeamHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Beam Color He Green");
				}
			}
			else if (StrEqual(choice, "grey", false))
			{
				ColorDefaultTrail[param1][0] = ColorGray[0];
				ColorDefaultTrail[param1][1] = ColorGray[1];
				ColorDefaultTrail[param1][2] = ColorGray[2];
				ColorDefaultTrail[param1][3] = ColorGray[3];
				ColorBeamHe[param1] = 6;
				BuildBeamHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Beam Color He Grey");
				}
			}
			else if (StrEqual(choice, "lime", false))
			{
				ColorDefaultTrail[param1][0] = ColorLime[0];
				ColorDefaultTrail[param1][1] = ColorLime[1];
				ColorDefaultTrail[param1][2] = ColorLime[2];
				ColorDefaultTrail[param1][3] = ColorLime[3];
				ColorBeamHe[param1] = 7;
				BuildBeamHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Beam Color He Lime");
				}
			}
			else if (StrEqual(choice, "maroon", false))
			{
				ColorDefaultTrail[param1][0] = ColorMaroon[0];
				ColorDefaultTrail[param1][1] = ColorMaroon[1];
				ColorDefaultTrail[param1][2] = ColorMaroon[2];
				ColorDefaultTrail[param1][3] = ColorMaroon[3];
				ColorBeamHe[param1] = 8;
				BuildBeamHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Beam Color He Maroon");
				}
			}
			else if (StrEqual(choice, "navy", false))
			{
				ColorDefaultTrail[param1][0] = ColorNavy[0];
				ColorDefaultTrail[param1][1] = ColorNavy[1];
				ColorDefaultTrail[param1][2] = ColorNavy[2];
				ColorDefaultTrail[param1][3] = ColorNavy[3];
				ColorBeamHe[param1] = 9;
				BuildBeamHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Beam Color He Navy");
				}
			}
			else if (StrEqual(choice, "olive", false))
			{
				ColorDefaultTrail[param1][0] = ColorOlive[0];
				ColorDefaultTrail[param1][1] = ColorOlive[1];
				ColorDefaultTrail[param1][2] = ColorOlive[2];
				ColorDefaultTrail[param1][3] = ColorOlive[3];
				ColorBeamHe[param1] = 10;
				BuildBeamHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Beam Color He Olive");
				}
			}
			else if (StrEqual(choice, "purple", false))
			{
				ColorDefaultTrail[param1][0] = ColorPurple[0];
				ColorDefaultTrail[param1][1] = ColorPurple[1];
				ColorDefaultTrail[param1][2] = ColorPurple[2];
				ColorDefaultTrail[param1][3] = ColorPurple[3];
				ColorBeamHe[param1] = 11;
				BuildBeamHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Beam Color He Purple");
				}
			}
			else if (StrEqual(choice, "red", false))
			{
				ColorDefaultTrail[param1][0] = ColorRed[0];
				ColorDefaultTrail[param1][1] = ColorRed[1];
				ColorDefaultTrail[param1][2] = ColorRed[2];
				ColorDefaultTrail[param1][3] = ColorRed[3];
				ColorBeamHe[param1] = 12;
				BuildBeamHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Beam Color He Red");
				}
			}
			else if (StrEqual(choice, "silver", false))
			{
				ColorDefaultTrail[param1][0] = ColorSilver[0];
				ColorDefaultTrail[param1][1] = ColorSilver[1];
				ColorDefaultTrail[param1][2] = ColorSilver[2];
				ColorDefaultTrail[param1][3] = ColorSilver[3];
				ColorBeamHe[param1] = 13;
				BuildBeamHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Beam Color He Silver");
				}
			}
			else if (StrEqual(choice, "teel", false))
			{
				ColorDefaultTrail[param1][0] = ColorTeal[0];
				ColorDefaultTrail[param1][1] = ColorTeal[1];
				ColorDefaultTrail[param1][2] = ColorTeal[2];
				ColorDefaultTrail[param1][3] = ColorTeal[3];
				ColorBeamHe[param1] = 14;
				BuildBeamHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Beam Color He Teel");
				}
			}
			else if (StrEqual(choice, "yellow", false))
			{
				ColorDefaultTrail[param1][0] = ColorYellow[0];
				ColorDefaultTrail[param1][1] = ColorYellow[1];
				ColorDefaultTrail[param1][2] = ColorYellow[2];
				ColorDefaultTrail[param1][3] = ColorYellow[3];
				ColorBeamHe[param1] = 15;
				BuildBeamHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Beam Color He Yellow");
				}
			}
			else if (StrEqual(choice, "white", false))
			{
				ColorDefaultTrail[param1][0] = ColorWhite[0];
				ColorDefaultTrail[param1][1] = ColorWhite[1];
				ColorDefaultTrail[param1][2] = ColorWhite[2];
				ColorDefaultTrail[param1][3] = ColorWhite[3];
				ColorBeamHe[param1] = 16;
				BuildBeamHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Beam Color He White");
				}
			}
		}
	}
}

public MenuHandler_BuildGlowColorHe(Handle:menu, MenuAction:action, param1, param2)
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
				BuildBeamHeMenu(param1);
			}
		}		
		case MenuAction_Select:
		{
			decl String:choice[256];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "aqua", false))
			{
				ColorDefaultGlow[param1][0] = ColorAqua[0];
				ColorDefaultGlow[param1][1] = ColorAqua[1];
				ColorDefaultGlow[param1][2] = ColorAqua[2];
				ColorDefaultGlow[param1][3] = ColorAqua[3];
				ColorGlowHe[param1] = 1;
				BuildGlowHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Glow Color He Aqua");
				}
			}
			else if (StrEqual(choice, "black", false))
			{
				ColorDefaultGlow[param1][0] = ColorBlack[0];
				ColorDefaultGlow[param1][1] = ColorBlack[1];
				ColorDefaultGlow[param1][2] = ColorBlack[2];
				ColorDefaultGlow[param1][3] = ColorBlack[3];
				ColorGlowHe[param1] = 2;
				BuildGlowHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Glow Color He Black");
				}
			}
			else if (StrEqual(choice, "blue", false))
			{
				ColorDefaultGlow[param1][0] = ColorBlue[0];
				ColorDefaultGlow[param1][1] = ColorBlue[1];
				ColorDefaultGlow[param1][2] = ColorBlue[2];
				ColorDefaultGlow[param1][3] = ColorBlue[3];
				ColorGlowHe[param1] = 3;
				BuildGlowHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Glow Color He Blue");
				}
			}
			else if (StrEqual(choice, "fuchsia", false))
			{
				ColorDefaultGlow[param1][0] = ColorFuschia[0];
				ColorDefaultGlow[param1][1] = ColorFuschia[1];
				ColorDefaultGlow[param1][2] = ColorFuschia[2];
				ColorDefaultGlow[param1][3] = ColorFuschia[3];
				ColorGlowHe[param1] = 4;
				BuildGlowHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Glow Color He Fuchsia");
				}
			}
			else if (StrEqual(choice, "green", false))
			{
				ColorDefaultGlow[param1][0] = ColorGreen[0];
				ColorDefaultGlow[param1][1] = ColorGreen[1];
				ColorDefaultGlow[param1][2] = ColorGreen[2];
				ColorDefaultGlow[param1][3] = ColorGreen[3];
				ColorGlowHe[param1] = 5;
				BuildGlowHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Glow Color He Green");
				}
			}
			else if (StrEqual(choice, "grey", false))
			{
				ColorDefaultGlow[param1][0] = ColorGray[0];
				ColorDefaultGlow[param1][1] = ColorGray[1];
				ColorDefaultGlow[param1][2] = ColorGray[2];
				ColorDefaultGlow[param1][3] = ColorGray[3];
				ColorGlowHe[param1] = 6;
				BuildGlowHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Glow Color He Grey");
				}
			}
			else if (StrEqual(choice, "lime", false))
			{
				ColorDefaultGlow[param1][0] = ColorLime[0];
				ColorDefaultGlow[param1][1] = ColorLime[1];
				ColorDefaultGlow[param1][2] = ColorLime[2];
				ColorDefaultGlow[param1][3] = ColorLime[3];
				ColorGlowHe[param1] = 7;
				BuildGlowHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Glow Color He Lime");
				}
			}
			else if (StrEqual(choice, "maroon", false))
			{
				ColorDefaultGlow[param1][0] = ColorMaroon[0];
				ColorDefaultGlow[param1][1] = ColorMaroon[1];
				ColorDefaultGlow[param1][2] = ColorMaroon[2];
				ColorDefaultGlow[param1][3] = ColorMaroon[3];
				ColorGlowHe[param1] = 8;
				BuildGlowHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Glow Color He Maroon");
				}
			}
			else if (StrEqual(choice, "navy", false))
			{
				ColorDefaultGlow[param1][0] = ColorNavy[0];
				ColorDefaultGlow[param1][1] = ColorNavy[1];
				ColorDefaultGlow[param1][2] = ColorNavy[2];
				ColorDefaultGlow[param1][3] = ColorNavy[3];
				ColorGlowHe[param1] = 9;
				BuildGlowHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Glow Color He Navy");
				}
			}
			else if (StrEqual(choice, "olive", false))
			{
				ColorDefaultGlow[param1][0] = ColorOlive[0];
				ColorDefaultGlow[param1][1] = ColorOlive[1];
				ColorDefaultGlow[param1][2] = ColorOlive[2];
				ColorDefaultGlow[param1][3] = ColorOlive[3];
				ColorGlowHe[param1] = 10;
				BuildGlowHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Glow Color He Olive");
				}
			}
			else if (StrEqual(choice, "purple", false))
			{
				ColorDefaultGlow[param1][0] = ColorPurple[0];
				ColorDefaultGlow[param1][1] = ColorPurple[1];
				ColorDefaultGlow[param1][2] = ColorPurple[2];
				ColorDefaultGlow[param1][3] = ColorPurple[3];
				ColorGlowHe[param1] = 11;
				BuildGlowHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Glow Color He Purple");
				}
			}
			else if (StrEqual(choice, "red", false))
			{
				ColorDefaultGlow[param1][0] = ColorRed[0];
				ColorDefaultGlow[param1][1] = ColorRed[1];
				ColorDefaultGlow[param1][2] = ColorRed[2];
				ColorDefaultGlow[param1][3] = ColorRed[3];
				ColorGlowHe[param1] = 12;
				BuildGlowHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Glow Color He Red");
				}
			}
			else if (StrEqual(choice, "silver", false))
			{
				ColorDefaultGlow[param1][0] = ColorSilver[0];
				ColorDefaultGlow[param1][1] = ColorSilver[1];
				ColorDefaultGlow[param1][2] = ColorSilver[2];
				ColorDefaultGlow[param1][3] = ColorSilver[3];
				ColorGlowHe[param1] = 13;
				BuildGlowHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Glow Color He Silver");
				}
			}
			else if (StrEqual(choice, "teel", false))
			{
				ColorDefaultGlow[param1][0] = ColorTeal[0];
				ColorDefaultGlow[param1][1] = ColorTeal[1];
				ColorDefaultGlow[param1][2] = ColorTeal[2];
				ColorDefaultGlow[param1][3] = ColorTeal[3];
				ColorGlowHe[param1] = 14;
				BuildGlowHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Glow Color He Teel");
				}
			}
			else if (StrEqual(choice, "yellow", false))
			{
				ColorDefaultGlow[param1][0] = ColorYellow[0];
				ColorDefaultGlow[param1][1] = ColorYellow[1];
				ColorDefaultGlow[param1][2] = ColorYellow[2];
				ColorDefaultGlow[param1][3] = ColorYellow[3];
				ColorGlowHe[param1] = 15;
				BuildGlowHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Glow Color He Yellow");
				}
			}
			else if (StrEqual(choice, "white", false))
			{
				ColorDefaultGlow[param1][0] = ColorWhite[0];
				ColorDefaultGlow[param1][1] = ColorWhite[1];
				ColorDefaultGlow[param1][2] = ColorWhite[2];
				ColorDefaultGlow[param1][3] = ColorWhite[3];
				ColorGlowHe[param1] = 16;
				BuildGlowHeMenu(param1);
				if(Messages[param1] || MessagesCMD[param1])
				{
					CPrintToChat(param1, "%t", "OS Menu Glow Color He White");
				}
			}
		}
	}
}
/***** Admin list menu *****/
public Action:Command_Admins(client, Args)
{
	if(H_active)
	{
		decl String:NoAdmin[32];
		Format(NoAdmin, sizeof(NoAdmin), "%t", "No Admin");
		
		if( client )
		{
			decl Handle:Menuex, String:Buffer[MAX_NAME_LENGTH];
			Menuex = CreateMenu(HandleAdminList);
			
			SetMenuTitle(Menuex, "%t", "Admin List");
			
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					if(CheckCommandAccess(i, "", ADMFLAG_GENERIC ))
					{
						Format(Buffer, sizeof(Buffer), "%N", i);
						AddMenuItem(Menuex, "", Buffer);
					}
				}
			}
			
			if(GetMenuItemCount( Menuex ) > 0)
			{
				DisplayMenu(Menuex, client, 30);
			}
			else
			{	
				AddMenuItem(Menuex, "", NoAdmin);
				DisplayMenu(Menuex, client, 30);
			}
		}
	}
	return Plugin_Handled;
}

public HandleAdminList(Handle:hMenu, MenuAction:HandleAction, client, Parameter)
{
	if(HandleAction == MenuAction_End)
	{
		CloseHandle(hMenu);
	}
}

/***********************************************************/
/************************ HELP MENU ************************/
/***********************************************************/
bool:ParseConfigFile(const String:file[]) {
	if (g_helpMenus != INVALID_HANDLE) {
		ClearArray(g_helpMenus);
		CloseHandle(g_helpMenus);
		g_helpMenus = INVALID_HANDLE;
	}

	new Handle:parser = SMC_CreateParser();
	SMC_SetReaders(parser, Config_NewSection, Config_KeyValue, Config_EndSection);
	SMC_SetParseEnd(parser, Config_End);

	new line = 0;
	new col = 0;
	new String:error[128];
	new SMCError:result = SMC_ParseFile(parser, file, line, col);
	CloseHandle(parser);

	if (result != SMCError_Okay) {
		SMC_GetErrorString(result, error, sizeof(error));
		LogError("%s on line %d, col %d of %s", error, line, col, file);
	}

	return (result == SMCError_Okay);
}

public SMCResult:Config_NewSection(Handle:parser, const String:section[], bool:quotes) {
	g_configLevel++;
	if (g_configLevel == 1) {
		new hmenu[HelpMenu];
		strcopy(hmenu[HelpName], sizeof(hmenu[HelpName]), section);
		hmenu[HelpItems] = CreateDataPack();
		hmenu[itemct] = 0;
		if (g_helpMenus == INVALID_HANDLE)
			g_helpMenus = CreateArray(sizeof(hmenu));
		PushArrayArray(g_helpMenus, hmenu[0]);
	}
	return SMCParse_Continue;
}

public SMCResult:Config_KeyValue(Handle:parser, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes) {
	new msize = GetArraySize(g_helpMenus);
	new hmenu[HelpMenu];
	GetArrayArray(g_helpMenus, msize-1, hmenu[0]);
	switch (g_configLevel) {
		case 1: {
			if(strcmp(key, "title", false) == 0)
				strcopy(hmenu[HelpTitle], sizeof(hmenu[HelpTitle]), value);
			if(strcmp(key, "type", false) == 0) {
				if(strcmp(value, "text", false) == 0)
					hmenu[HelpType] = HelpMenuType_Text;
				else
					hmenu[HelpType] = HelpMenuType_List;
			}
		}
		case 2: {
			WritePackString(hmenu[HelpItems], key);
			WritePackString(hmenu[HelpItems], value);
			hmenu[itemct]++;
		}
	}
	SetArrayArray(g_helpMenus, msize-1, hmenu[0]);
	return SMCParse_Continue;
}
public SMCResult:Config_EndSection(Handle:parser) {
	g_configLevel--;
	if (g_configLevel == 1) {
		new hmenu[HelpMenu];
		new msize = GetArraySize(g_helpMenus);
		GetArrayArray(g_helpMenus, msize-1, hmenu[0]);
		ResetPack(hmenu[HelpItems]);
	}
	return SMCParse_Continue;
}

public Config_End(Handle:parser, bool:halted, bool:failed) {
	if (failed)
		SetFailState("Plugin configuration error");
}

public Action:OSMenuHelp(client, args) {
	BuildHelpMenu(client);
	return Plugin_Handled;
}

BuildHelpMenu(client) {
	new Handle:menu = CreateMenu(Help_MainMenuHandler);
	SetMenuExitBackButton(menu, true);
	SetMenuTitle(menu, "Help Menu\n ");
	new msize = GetArraySize(g_helpMenus);
	new hmenu[HelpMenu];
	new String:menuid[10];
	for (new i = 0; i < msize; ++i) {
		Format(menuid, sizeof(menuid), "helpmenu_%d", i);
		GetArrayArray(g_helpMenus, i, hmenu[0]);
		AddMenuItem(menu, menuid, hmenu[HelpName]);
	}
	DisplayMenu(menu, client, 30);
}

public Help_MainMenuHandler(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) {
		CloseHandle(menu);
	} else if (action == MenuAction_Select) {
		new String:buf[64];
		new msize = GetArraySize(g_helpMenus);
		if (param2 == msize) { // Maps
			new Handle:mapMenu = CreateMenu(Help_MenuHandler);
			SetMenuExitBackButton(mapMenu, true);
			ReadMapList(g_mapArray, g_mapSerial, "default");
			Format(buf, sizeof(buf), "Current Rotation (%d maps)\n ", GetArraySize(g_mapArray));
			SetMenuTitle(mapMenu, buf);
			if (g_mapArray != INVALID_HANDLE) {
				new mapct = GetArraySize(g_mapArray);
				new String:mapname[64];
				for (new i = 0; i < mapct; ++i) {
					GetArrayString(g_mapArray, i, mapname, sizeof(mapname));
					AddMenuItem(mapMenu, mapname, mapname, ITEMDRAW_DISABLED);
				}
			}
			DisplayMenu(mapMenu, param1, 30);
		} else if (param2 == msize+1) { // Admins
			new Handle:adminMenu = CreateMenu(Help_MenuHandler);
			SetMenuExitBackButton(adminMenu, true);
			SetMenuTitle(adminMenu, "Online Admins\n ");
			new maxc = GetMaxClients();
			new String:aname[64];
			for (new i = 1; i < maxc; ++i) {
				if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && (GetUserFlagBits(i) & ADMFLAG_GENERIC) == ADMFLAG_GENERIC) {
					GetClientName(i, aname, sizeof(aname));
					AddMenuItem(adminMenu, aname, aname, ITEMDRAW_DISABLED);
				}
			}
			DisplayMenu(adminMenu, param1, 30);
		} else { // Menu from config file
			if (param2 <= msize) {
				new hmenu[HelpMenu];
				GetArrayArray(g_helpMenus, param2, hmenu[0]);
				new String:mtitle[512];
				Format(mtitle, sizeof(mtitle), "%s\n ", hmenu[HelpTitle]);
				if (hmenu[HelpType] == HelpMenuType_Text) {
					new Handle:cpanel = CreatePanel();
					SetPanelTitle(cpanel, mtitle);
					new String:text[128];
					new String:junk[128];
					for (new i = 0; i < hmenu[itemct]; ++i) {
						ReadPackString(hmenu[HelpItems], junk, sizeof(junk));
						ReadPackString(hmenu[HelpItems], text, sizeof(text));
						DrawPanelText(cpanel, text);
					}
					for (new j = 0; j < 7; ++j)
						DrawPanelItem(cpanel, " ", ITEMDRAW_NOTEXT);
					DrawPanelText(cpanel, " ");
					DrawPanelItem(cpanel, "Back", ITEMDRAW_CONTROL);
					DrawPanelItem(cpanel, " ", ITEMDRAW_NOTEXT);
					DrawPanelText(cpanel, " ");
					DrawPanelItem(cpanel, "Exit", ITEMDRAW_CONTROL);
					ResetPack(hmenu[HelpItems]);
					SendPanelToClient(cpanel, param1, Help_MenuHandler, 30);
					CloseHandle(cpanel);
				} else {
					new Handle:cmenu = CreateMenu(Help_CustomMenuHandler);
					SetMenuExitBackButton(cmenu, true);
					SetMenuTitle(cmenu, mtitle);
					new String:cmd[128];
					new String:desc[128];
					for (new i = 0; i < hmenu[itemct]; ++i) {
						ReadPackString(hmenu[HelpItems], cmd, sizeof(cmd));
						ReadPackString(hmenu[HelpItems], desc, sizeof(desc));
						new drawstyle = ITEMDRAW_DEFAULT;
						if (strlen(cmd) == 0)
							drawstyle = ITEMDRAW_DISABLED;
						AddMenuItem(cmenu, cmd, desc, drawstyle);
					}
					ResetPack(hmenu[HelpItems]);
					DisplayMenu(cmenu, param1, 30);
				}
			}
		}
	}else if(action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			BuildOSMenu(param1);
		}		
	}
}

public Help_MenuHandler(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) {
		CloseHandle(menu);
	} else if (menu == INVALID_HANDLE && action == MenuAction_Select && param2 == 8) {
		BuildHelpMenu(param1);
	} else if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack)
			BuildHelpMenu(param1);
	}
}

public Help_CustomMenuHandler(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) {
		CloseHandle(menu);
	} else if (action == MenuAction_Select) {
		new String:itemval[32];
		GetMenuItem(menu, param2, itemval, sizeof(itemval));
		if (strlen(itemval) > 0)
			FakeClientCommand(param1, itemval);
	} else if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack)
			BuildHelpMenu(param1);
	}
}

/***********************************************************/
/********************* DOWNLOADER FILES ********************/
/***********************************************************/
public ReadFileFolder(String:path[]){
	new Handle:dirh = INVALID_HANDLE;
	new String:buffer[256];
	new String:tmp_path[256];
	new FileType:type = FileType_Unknown;
	new len;
	
	len = strlen(path);
	if (path[len-1] == '\n')
		path[--len] = '\0';

	TrimString(path);
	
	if(DirExists(path)){
		dirh = OpenDirectory(path);
		while(ReadDirEntry(dirh,buffer,sizeof(buffer),type)){
			len = strlen(buffer);
			if (buffer[len-1] == '\n')
				buffer[--len] = '\0';

			TrimString(buffer);

			if (!StrEqual(buffer,"",false) && !StrEqual(buffer,".",false) && !StrEqual(buffer,"..",false)){
				strcopy(tmp_path,255,path);
				StrCat(tmp_path,255,"/");
				StrCat(tmp_path,255,buffer);
				if(type == FileType_File){
					if(downloadtype == 1){
						ReadItem(tmp_path);
					}
					else{
						ReadItemSimple(tmp_path);
					}
				}
				else{
					ReadFileFolder(tmp_path);
				}
			}
		}
	}
	else{
		if(downloadtype == 1){
			ReadItem(path);
		}
		else{
			ReadItemSimple(path);
		}
	}
	if(dirh != INVALID_HANDLE){
		CloseHandle(dirh);
	}
}

public ReadDownloads(){
	new String:file[256];
	BuildPath(Path_SM, file, 255, "configs/os/downloads/normal.ini");
	new Handle:fileh = OpenFile(file, "r");
	new String:buffer[256];
	downloadtype = 1;
	new len;
	
	GetCurrentMap(DowloaderMap,255);
	
	if(fileh == INVALID_HANDLE) return;
	while (ReadFileLine(fileh, buffer, sizeof(buffer)))
	{	
		len = strlen(buffer);
		if (buffer[len-1] == '\n')
			buffer[--len] = '\0';

		TrimString(buffer);

		if(!StrEqual(buffer,"",false)){
			ReadFileFolder(buffer);
		}
		
		if (IsEndOfFile(fileh))
			break;
	}
	if(fileh != INVALID_HANDLE){
		CloseHandle(fileh);
	}
}

public ReadItem(String:buffer[]){
	new len = strlen(buffer);
	if (buffer[len-1] == '\n')
		buffer[--len] = '\0';
	
	TrimString(buffer);
	
	if(StrContains(buffer,"//Files (Download Only No Precache)",true) >= 0){
		strcopy(mediatype,255,"File");
		downloadfiles=true;
	}
	else if(StrContains(buffer,"//Decal Files (Download and Precache)",true) >= 0){
		strcopy(mediatype,255,"Decal");
		downloadfiles=true;
	}
	else if(StrContains(buffer,"//Sound Files (Download and Precache)",true) >= 0){
		strcopy(mediatype,255,"Sound");
		downloadfiles=true;
	}
	else if(StrContains(buffer,"//Model Files (Download and Precache)",true) >= 0){
		strcopy(mediatype,255,"Model");
		downloadfiles=true;
	}
	else if(len >= 2 && buffer[0] == '/' && buffer[1] == '/'){
		//Comment
		if(StrContains(buffer,"//") >= 0){
			ReplaceString(buffer,255,"//","");
		}
		if(StrEqual(buffer,DowloaderMap,true)){
			downloadfiles=true;
		}
		else if(StrEqual(buffer,"Any",false)){
			downloadfiles=true;
		}
		else{
			downloadfiles=false;
		}
	}
	else if (!StrEqual(buffer,"",false) && FileExists(buffer))
	{
		if(downloadfiles){
			if(StrContains(mediatype,"Decal",true) >= 0){
				PrecacheDecal(buffer,true);
			}
			else if(StrContains(mediatype,"Sound",true) >= 0){
				PrecacheSound(buffer,true);
			}
			else if(StrContains(mediatype,"Model",true) >= 0){
				PrecacheModel(buffer,true);
			}
			AddFileToDownloadsTable(buffer);
		}
	}
}

public ReadDownloadsSimple(){
	new String:file[256];
	BuildPath(Path_SM, file, 255, "configs/os/download/simple.ini");
	new Handle:fileh = OpenFile(file, "r");
	new String:buffer[256];
	downloadtype = 2;
	new len;
	
	if(fileh == INVALID_HANDLE) return;
	while (ReadFileLine(fileh, buffer, sizeof(buffer)))
	{
		len = strlen(buffer);
		if (buffer[len-1] == '\n')
			buffer[--len] = '\0';

		TrimString(buffer);

		if(!StrEqual(buffer,"",false)){
			ReadFileFolder(buffer);
		}
		
		if (IsEndOfFile(fileh))
			break;
	}
	if(fileh != INVALID_HANDLE){
		CloseHandle(fileh);
	}
}

public ReadItemSimple(String:buffer[]){
	new len = strlen(buffer);
	if (buffer[len-1] == '\n')
		buffer[--len] = '\0';
	
	TrimString(buffer);
	if(len >= 2 && buffer[0] == '/' && buffer[1] == '/'){
		//Comment
	}
	else if (!StrEqual(buffer,"",false) && FileExists(buffer))
	{
		AddFileToDownloadsTable(buffer);
	}
}

/**********************************************************************/
/***************************** DEATHMATCH *****************************/
/**********************************************************************/

/***********************************************************/
/********************** TELEPORTATION **********************/
/***********************************************************/
LoadMapConfig()
{
	decl String:map[64];
	GetCurrentMap(map, sizeof(map));
	
	decl String:path[PLATFORM_MAX_PATH];
	Format(path, sizeof(path), "addons/sourcemod/configs/os/spawns/%s.txt", map);
	
	spawnPointCount = 0;
	
	// Open file
	new Handle:file = OpenFile(path, "r");
	if (file == INVALID_HANDLE)
		return;
	// Read file
	decl String:buffer[256];
	decl String:parts[6][16];
	while (!IsEndOfFile(file) && ReadFileLine(file, buffer, sizeof(buffer)))
	{
		ExplodeString(buffer, " ", parts, 6, 16);
		spawnPositions[spawnPointCount][0] = StringToFloat(parts[0]);
		spawnPositions[spawnPointCount][1] = StringToFloat(parts[1]);
		spawnPositions[spawnPointCount][2] = StringToFloat(parts[2]);
		spawnAngles[spawnPointCount][0] = StringToFloat(parts[3]);
		spawnAngles[spawnPointCount][1] = StringToFloat(parts[4]);
		spawnAngles[spawnPointCount][2] = StringToFloat(parts[5]);
		spawnPointCount++;
	}
	// Close file
	CloseHandle(file);
}

MovePlayer(client)
{
	numberOfPlayerSpawns++; // Stats
	
	new Teams:clientTeam = Teams:GetClientTeam(client);
	
	new spawnPoint;
	new bool:spawnPointFound = false;
	
	decl Float:enemyEyePositions[MaxClients][3];
	new numberOfEnemies = 0;
	
	// Retrieve enemy positions if required by LoS/distance spawning (at eye level for LoS checking).
	if (lineOfSightSpawning || (spawnDistanceFromEnemies > 0.0))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && (Teams:GetClientTeam(i) > TeamSpectator) && IsPlayerAlive(i))
			{
				new bool:enemy = ((Teams:GetClientTeam(i) != clientTeam));
				if (enemy)
				{
					GetClientEyePosition(i, enemyEyePositions[numberOfEnemies]);
					numberOfEnemies++;
				}
			}
		}
	}
	
	if (lineOfSightSpawning)
	{
		losSearchAttempts++; // Stats
		
		// Try to find a suitable spawn point with a clear line of sight.
		for (new i = 0; i < lineOfSightAttempts; i++)
		{
			spawnPoint = GetRandomInt(0, spawnPointCount - 1);
			
			if (spawnPointOccupied[spawnPoint])
				continue;
			
			if (spawnDistanceFromEnemies > 0.0)
			{
				if (!IsPointSuitableDistance(spawnPoint, enemyEyePositions, numberOfEnemies))
					continue;
			}
			
			decl Float:spawnPointEyePosition[3];
			AddVectors(spawnPositions[spawnPoint], eyeOffset, spawnPointEyePosition);
			
			new bool:hasClearLineOfSight = true;
			
			for (new j = 0; j < numberOfEnemies; j++)
			{
				new Handle:trace = TR_TraceRayFilterEx(spawnPointEyePosition, enemyEyePositions[j], MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, TraceEntityFilterPlayer);
				if (!TR_DidHit(trace))
				{
					hasClearLineOfSight = false;
					CloseHandle(trace);
					break;
				}
				CloseHandle(trace);
			}
			if (hasClearLineOfSight)
			{
				spawnPointFound = true;
				break;
			}
		}
		// Stats
		if (spawnPointFound)
			losSearchSuccesses++;
		else
			losSearchFailures++;
	}
	
	// First fallback. Find a random unccupied spawn point at a suitable distance.
	if (!spawnPointFound && (spawnDistanceFromEnemies > 0.0))
	{
		distanceSearchAttempts++; // Stats
		
		for (new i = 0; i < 50; i++)
		{
			spawnPoint = GetRandomInt(0, spawnPointCount - 1);
			if (spawnPointOccupied[spawnPoint])
				continue;
			
			if (!IsPointSuitableDistance(spawnPoint, enemyEyePositions, numberOfEnemies))
				continue;
			
			spawnPointFound = true;
			break;
		}
		// Stats
		if (spawnPointFound)
			distanceSearchSuccesses++;
		else
			distanceSearchFailures++;
	}
	
	// Final fallback. Find a random unoccupied spawn point.
	if (!spawnPointFound)
	{
		for (new i = 0; i < 100; i++)
		{
			spawnPoint = GetRandomInt(0, spawnPointCount - 1);
			if (!spawnPointOccupied[spawnPoint])
			{
				spawnPointFound = true;
				break;
			}
		}
	}
	
	if (spawnPointFound)
	{
		TeleportEntity(client, spawnPositions[spawnPoint], spawnAngles[spawnPoint], NULL_VECTOR);
		spawnPointOccupied[spawnPoint] = true;
		playerMoved[client] = true;
	}
	
	if (!spawnPointFound) spawnPointSearchFailures++; // Stats
}

public Action:Timer_UpdateSpawnPointStatus(Handle:timer)
{
	if(H_active)
	{
		if ( H_active_deathmatch && spawnPointCount > 0)
		{
			// Retrieve player positions.
			decl Float:playerPositions[MaxClients][3];
			new numberOfAlivePlayers = 0;
		
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && (Teams:GetClientTeam(i) > TeamSpectator) && IsPlayerAlive(i))
				{
					GetClientAbsOrigin(i, playerPositions[numberOfAlivePlayers]);
					numberOfAlivePlayers++;
				}
			}
		
			// Check each spawn point for occupation by proximity to alive players
			for (new i = 0; i < spawnPointCount; i++)
			{
				spawnPointOccupied[i] = false;
				for (new j = 0; j < numberOfAlivePlayers; j++)
				{
					new Float:distance = GetVectorDistance(spawnPositions[i], playerPositions[j], true);
					if (distance < 10000.0)
					{
						spawnPointOccupied[i] = true;
						break;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

bool:IsPointSuitableDistance(spawnPoint, const Float:enemyEyePositions[][3], numberOfEnemies)
{
	for (new i = 0; i < numberOfEnemies; i++)
	{
		new Float:distance = GetVectorDistance(spawnPositions[spawnPoint], enemyEyePositions[i], true);
		if (distance < spawnDistanceFromEnemies)
			return false;
	}
	return true;
}

public bool:TraceEntityFilterPlayer(entityIndex, mask)
{
	if ((entityIndex > 0) && (entityIndex <= MaxClients)) return false;
	return true;
}

public Action:Respawn(Handle:timer, any:client)
{
	if (!roundEnded && IsClientInGame(client) && (Teams:GetClientTeam(client) > TeamSpectator) && !IsPlayerAlive(client))
	{
		playerMoved[client] = false;
		CS_RespawnPlayer(client);
	}
}

public Action:Event_JoinClass(client, args)
{
		CreateTimer(2.0, Respawn, client);
}

public Action:Command_Join(client, arg)
{
    if(Teams:GetClientTeam(client) != TeamSpectator)
        return Plugin_Handled;
    else
	{
		new random = GetRandomInt(2, 3);
		SetEntProp(client, Prop_Send, "m_iTeamNum", random);
		ForcePlayerSuicide(client);
		CS_RespawnPlayer(client);
	}

    return Plugin_Continue;
}

public Action:Command_RespawnAll(client, args)
{
	RespawnAll();
	return Plugin_Handled;
}

RespawnAll()
{
	for (new i = 1; i <= MaxClients; i++)
		Respawn(INVALID_HANDLE, i);
}
/***********************************************************/
/********************* PROTECTION SPAWN ********************/
/***********************************************************/
EnableSpawnProtection(client)
{
	new Teams:clientTeam = Teams:GetClientTeam(client);
	// Disable damage
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	// Set player colour
	if (clientTeam == TeamT)
		SetPlayerColour(client, ColorRed);
	else if (clientTeam == TeamCT)
		SetPlayerColour(client, ColorBlue);
	// Create timer to remove spawn protection
	CreateTimer(H_spawnProtectionTime, DisableSpawnProtection, client);
}

public Action:DisableSpawnProtection(Handle:Timer, any:client)
{
	if (IsClientInGame(client) && (Teams:GetClientTeam(client) > TeamSpectator) && IsPlayerAlive(client))
	{
		// Enable damage
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		// Set player colour
		SetPlayerColour(client, ColorDefault);
	}
}

SetPlayerColour(client, const colour[4])
{
	new RenderMode:mode = (colour[3] == 255) ? RENDER_NORMAL : RENDER_TRANSCOLOR;
	SetEntityRenderMode(client, mode);
	SetEntityRenderColor(client, colour[0], colour[1], colour[2], colour[3]);
}

/***********************************************************/
/******************** REMOVE OBJECTIVES ********************/
/***********************************************************/
RemoveHostages()
{
	new maxEntities = GetMaxEntities();
	decl String:class[24];
	
	for (new i = MaxClients + 1; i < maxEntities; i++)
	{
		if (IsValidEdict(i))
		{
			GetEdictClassname(i, class, sizeof(class));
			if (StrEqual(class, "hostage_entity"))
				AcceptEntityInput(i, "Kill");
		}
	}
}

SetObjectives(const String:status[])
{
	new maxEntities = GetMaxEntities();
	decl String:class[24];
	
	for (new i = MaxClients + 1; i < maxEntities; i++)
	{
		if (IsValidEdict(i))
		{
			GetEdictClassname(i, class, sizeof(class));
			if (StrEqual(class, "func_bomb_target") || StrEqual(class, "func_hostage_rescue"))
				AcceptEntityInput(i, status);
		}
	}
}

RemoveC4()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (StripC4(i))
			break;
	}
}

bool:StripC4(client)
{
	if (IsClientInGame(client) && (Teams:GetClientTeam(client) == TeamT) && IsPlayerAlive(client))
	{
		new c4Index = GetPlayerWeaponSlot(client, _:SlotC4);
		if (c4Index != -1)
		{
			decl String:weapon[24];
			GetClientWeapon(client, weapon, sizeof(weapon));
			// If the player is holding C4, switch to the best weapon before removing it.
			if (StrEqual(weapon, "weapon_c4"))
			{
				if (GetPlayerWeaponSlot(client, _:SlotPrimary) != -1)
					ClientCommand(client, "slot1");
				else if (GetPlayerWeaponSlot(client, _:SlotSecondary) != -1)
					ClientCommand(client, "slot2");
				else
					ClientCommand(client, "slot3");
				
			}
			RemovePlayerItem(client, c4Index);
			AcceptEntityInput(c4Index, "Kill");
			return true;
		}
	}
	return false;
}

/***********************************************************/
/******************** EDITOR SPAWNS MENU *******************/
/***********************************************************/
Handle:BuildSpawnEditorMenu()
{
	decl String:editModeItem[32];
	decl String:Nearest[32];
	decl String:Previous[32];
	decl String:Next[32];
	decl String:Add[32];
	decl String:Insert[32];
	decl String:Delete[32];
	decl String:DeleteAll[32];
	decl String:Save[32];
	
	Format(editModeItem, sizeof(editModeItem), "%t", (!inEditMode) ? "Edit Enable" : "Edit Disable");
	Format(Nearest, sizeof(Nearest), "%t", "Teleport to nearest");
	Format(Previous, sizeof(Previous), "%t", "Teleport to previous");
	Format(Next, sizeof(Next), "%t", "Teleport to next");
	Format(Add, sizeof(Add), "%t", "Add position");
	Format(Insert, sizeof(Insert), "%t", "Insert position here");
	Format(Delete, sizeof(Delete), "%t", "Delete nearest");
	Format(DeleteAll, sizeof(DeleteAll), "%t", "Delete all");
	Format(Save, sizeof(Save), "%t", "Save Configuration");
	
	
	new Handle:menu = CreateMenu(Menu_SpawnEditor);
	SetMenuTitle(menu, "%t", "Spawn Point Editor");
	SetMenuExitButton(menu, true);


	AddMenuItem(menu, "Edit", editModeItem);
	AddMenuItem(menu, "Nearest", Nearest);
	AddMenuItem(menu, "Previous", Previous);
	AddMenuItem(menu, "Next", Next);
	AddMenuItem(menu, "Add", Add);
	AddMenuItem(menu, "Insert", Insert);
	AddMenuItem(menu, "Delete", Delete);
	AddMenuItem(menu, "Delete All", DeleteAll);
	AddMenuItem(menu, "Save", Save);
	return menu;
}

public Action:Command_SpawnMenu(client, args)
{
	if(H_active)
	{
		DisplayMenu(BuildSpawnEditorMenu(), client, MENU_TIME_FOREVER);
	}
}

public Menu_SpawnEditor(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[24];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "Edit"))
		{
			inEditMode = !inEditMode;
			if (inEditMode)
			{
				CreateTimer(1.0, RenderSpawnPoints, INVALID_HANDLE, TIMER_REPEAT);
				CPrintToChat(param1, "%t", "Edit mode enabled");
			}
			else
				CPrintToChat(param1, "%t", "Edit mode disabled");
		}
		else if (StrEqual(info, "Nearest"))
		{
			new spawnPoint = GetNearestSpawn(param1);
			if (spawnPoint != -1)
			{
				TeleportEntity(param1, spawnPositions[spawnPoint], spawnAngles[spawnPoint], NULL_VECTOR);
				lastEditorSpawnPoint[param1] = spawnPoint;
				CPrintToChat(param1, "%t", "Teleported to spawn", spawnPoint + 1, spawnPointCount);
			}
		}
		else if (StrEqual(info, "Previous"))
		{
			if (spawnPointCount == 0)
				CPrintToChat(param1, "%t", "There are no spawn points");
			else
			{
				new spawnPoint = lastEditorSpawnPoint[param1] - 1;
				if (spawnPoint < 0)
					spawnPoint = spawnPointCount - 1;
				TeleportEntity(param1, spawnPositions[spawnPoint], spawnAngles[spawnPoint], NULL_VECTOR);
				lastEditorSpawnPoint[param1] = spawnPoint;
				CPrintToChat(param1, "%t", "Teleported to spawn", spawnPoint + 1, spawnPointCount);
			}
		}
		else if (StrEqual(info, "Next"))
		{
			if (spawnPointCount == 0)
				CPrintToChat(param1, "%t", "There are no spawn points");
			else
			{
				new spawnPoint = lastEditorSpawnPoint[param1] + 1;
				if (spawnPoint >= spawnPointCount)
					spawnPoint = 0;
				TeleportEntity(param1, spawnPositions[spawnPoint], spawnAngles[spawnPoint], NULL_VECTOR);
				lastEditorSpawnPoint[param1] = spawnPoint;
				CPrintToChat(param1, "%t", "Teleported to spawn", spawnPoint + 1, spawnPointCount);
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
			new spawnPoint = GetNearestSpawn(param1);
			if (spawnPoint != -1)
			{
				DeleteSpawn(spawnPoint);
				CPrintToChat(param1, "%t", "Deleted spawn point", spawnPoint + 1, spawnPointCount);
			}
		}
		else if (StrEqual(info, "Delete All"))
		{
			decl String:DeleteAllPoints[32];
			
			Format(DeleteAllPoints, sizeof(DeleteAllPoints), "%t", "Delete all spawn points");
			
			new Handle:panel = CreatePanel();
			SetPanelTitle(panel, DeleteAllPoints);
			DrawPanelItem(panel, "Yes");
			DrawPanelItem(panel, "No");
			SendPanelToClient(panel, param1, Panel_ConfirmDeleteAllSpawns, MENU_TIME_FOREVER);
			CloseHandle(panel);
		}
		else if (StrEqual(info, "Save"))
		{
			if (WriteMapConfig())
				CPrintToChat(param1, "%t", "Configuration has been saved.");
			else
				CPrintToChat(param1, "%t", "Configuration could not be saved");
		}
		if (!StrEqual(info, "Delete All"))
			DisplayMenu(BuildSpawnEditorMenu(), param1, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
}

public Panel_ConfirmDeleteAllSpawns(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 1)
		{
			spawnPointCount = 0;
			CPrintToChat(param1, "%t", "All spawn points have been deleted");
		}
		DisplayMenu(BuildSpawnEditorMenu(), param1, MENU_TIME_FOREVER);
	}
}

public Action:RenderSpawnPoints(Handle:timer)
{
	if (!inEditMode)
		return Plugin_Stop;
	
	for (new i = 0; i < spawnPointCount; i++)
	{
		decl Float:spawnPosition[3];
		AddVectors(spawnPositions[i], spawnPointOffset, spawnPosition);
		TE_SetupGlowSprite(spawnPosition, glowSprite, 1.0, 0.5, 255);
		TE_SendToAll();
	}
	return Plugin_Continue;
}

GetNearestSpawn(client)
{
	if (spawnPointCount == 0)
	{
		CPrintToChat(client, "%t", "There are no spawn points");
		return -1;
	}
	
	decl Float:clientPosition[3];
	GetClientAbsOrigin(client, clientPosition);
	
	new nearestPoint = 0;
	new Float:nearestPointDistance = GetVectorDistance(spawnPositions[0], clientPosition, true);
	
	for (new i = 1; i < spawnPointCount; i++)
	{
		new Float:distance = GetVectorDistance(spawnPositions[i], clientPosition, true);
		if (distance < nearestPointDistance)
		{
			nearestPoint = i;
			nearestPointDistance = distance;
		}
	}
	return nearestPoint;
}

AddSpawn(client)
{
	if (spawnPointCount >= MAX_SPAWNS)
	{
		CPrintToChat(client, "%t", "Could not add spawn point");
		return;
	}
	GetClientAbsOrigin(client, spawnPositions[spawnPointCount]);
	GetClientAbsAngles(client, spawnAngles[spawnPointCount]);
	spawnPointCount++;
	CPrintToChat(client, "%t", "Added spawn point", spawnPointCount, spawnPointCount);
}

InsertSpawn(client)
{
	if (spawnPointCount >= MAX_SPAWNS)
	{
		CPrintToChat(client, "%t", "Could not add spawn point");
		return;
	}
	
	if (spawnPointCount == 0)
		AddSpawn(client);
	else
	{
		// Move spawn points down the list to make room for insertion.
		for (new i = spawnPointCount - 1; i >= lastEditorSpawnPoint[client]; i--)
		{
			spawnPositions[i + 1] = spawnPositions[i];
			spawnAngles[i + 1] = spawnAngles[i];
		}
		// Insert new spawn point.
		GetClientAbsOrigin(client, spawnPositions[lastEditorSpawnPoint[client]]);
		GetClientAbsAngles(client, spawnAngles[lastEditorSpawnPoint[client]]);
		spawnPointCount++;
		CPrintToChat(client, "%t", "Inserted spawn point", lastEditorSpawnPoint[client] + 1, spawnPointCount);
	}
}

DeleteSpawn(spawnIndex)
{
	for (new i = spawnIndex; i < (spawnPointCount - 1); i++)
	{
		spawnPositions[i] = spawnPositions[i + 1];
		spawnAngles[i] = spawnAngles[i + 1];
	}
	spawnPointCount--;
}

bool:WriteMapConfig()
{
	decl String:map[64];
	GetCurrentMap(map, sizeof(map));
	
	decl String:path[PLATFORM_MAX_PATH];
	Format(path, sizeof(path), "addons/sourcemod/configs/os/spawns/%s.txt", map);
	
	// Open file
	new Handle:file = OpenFile(path, "w");
	if (file == INVALID_HANDLE)
	{
		LogError("Could not open spawn point file \"%s\" for writing.", path);
		return false;
	}
	// Write spawn points
	for (new i = 0; i < spawnPointCount; i++)
		WriteFileLine(file, "%f %f %f %f %f %f", spawnPositions[i][0], spawnPositions[i][1], spawnPositions[i][2], spawnAngles[i][0], spawnAngles[i][1], spawnAngles[i][2]);
	// Close file
	CloseHandle(file);
	return true;
}

/***********************************************************/
/******************** CREATE HATS  *************************/
/***********************************************************/
stock LookupAttachment(client, String:point[])
{
    if(g_hLookupAttachment==INVALID_HANDLE) return 0;
    if( client<=0 || !IsClientInGame(client) ) return 0;
    return SDKCall(g_hLookupAttachment, client, point);
}

public LoadHats()
{
	g_iCategories = 0;
	g_iNumHats = 0;

	for(new i=0;i<MAX_CATEGORIES;++i)
		g_sCategories[i]="";
	for(new i=0;i<MAX_HATS;++i)
		g_eHats[i][Category]=-1;
	
	new String:hc[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, hc, sizeof(hc), "configs/os/hats/hats.txt");
	
	new Handle:kv = CreateKeyValues("Hats");
	FileToKeyValues(kv, hc);

	new Float:temp[3];
	new String:sTemp[2];
	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			KvGetSectionName(kv, g_sCategories[g_iCategories], 64);
			if(KvGotoFirstSubKey(kv))
			{
				do
				{
					KvGetSectionName(kv, g_eHats[g_iNumHats][Name], 64);
					KvGetString(kv, "model", g_eHats[g_iNumHats][ModelPath], PLATFORM_MAX_PATH);
					KvGetString(kv, "flag", sTemp, 2);
					g_eHats[g_iNumHats][Flags] = ReadFlagString(sTemp);
					KvGetVector(kv, "position", temp);
					g_eHats[g_iNumHats][Position] = temp;
					KvGetVector(kv, "angles", temp);
					g_eHats[g_iNumHats][Angles] = temp;
					g_eHats[g_iNumHats][Team] = KvGetNum(kv, "team");
					g_eHats[g_iNumHats][Category] = g_iCategories;
					
					if(strcmp(g_eHats[g_iNumHats][ModelPath], "")!=0 && (FileExists(g_eHats[g_iNumHats][ModelPath]) || FileExists(g_eHats[g_iNumHats][ModelPath], true)))
						PrecacheModel(g_eHats[g_iNumHats][ModelPath], true);
					
					++g_iNumHats;
				} 
				while (KvGotoNextKey(kv));
			}
			KvGoBack(kv);
			g_iCategories++;
		}
		while (KvGotoNextKey(kv));
	}
	CloseHandle(kv);
}

public Action:Timer_SpawnPostPost(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		if(IsPlayerAlive(client) && !PlayerIsFirst[client] && !PlayerKing[client])
		{
			for(new i=0;i<MAX_CATEGORIES;++i)
				if(g_iHatCache[client][i]!=-1)
					CreateHat(client, i);
		}
	}
		
	return Plugin_Stop;
}

public Action:Command_Default(client, args)
{
	if(!H_active_hats)
	{
		return Plugin_Handled;
	}
	
	if(args != 2)
	{
		ReplyToCommand(0, "Usage: sm_hats_default <slot> <model>");
		return Plugin_Handled;
	}
	
	new String:sId[4];
	GetCmdArg(1, sId, 4);
	
	new cat = StringToInt(sId);
	if(cat > g_iCategories-1)
	{
		ReplyToCommand(0, "Invalid slot value (max is %d)", g_iCategories);
		return Plugin_Handled;
	}
	
	new String:sModel[PLATFORM_MAX_PATH];
	GetCmdArg(2, sModel, PLATFORM_MAX_PATH);
	
	g_iDefaults[cat] = ItemExists_Hat(sModel);
	
	return Plugin_Handled;
}

public Action:Command_Hats(client, args)
{
	if(!H_active_hats)
	{
		CPrintToChat(client, "%t", "OS Menu Hats Disable");
		return Plugin_Handled;
	}
	
	if(!LookupAttachment(client, "forward"))
	{
		CPrintToChat(client, "%t", "OS Menu Hats not support");
		return Plugin_Handled;
	}
	if(GetNumHats(client, -1) == 0)
	{
		CPrintToChat(client, "%t", "OS Menu Hats no menu");
		return Plugin_Handled;
	}
	DisplayMenu(CreateHatsMenu(client, -1), client, 0);
	return Plugin_Handled;
}

public Handle:CreateHatsMenu(client, category)
{	
	new Handle:hMenu = CreateMenu(Handler_Hats);
	new String:id[11];
	
	if(category==-1)
	{
		new cat;
		if(GetNumCategories(client, cat)==1)
		{
			return CreateHatsMenu(client, cat);
		}
		else
		{
			SetMenuTitle(hMenu, "Hats Menu");
			for(new i=0;i<MAX_CATEGORIES;++i)
			{			
				if(GetNumHats(client, i)==0)
					continue;
					
				IntToString((i+1)*-1, id, sizeof(id));
				
				AddMenuItem(hMenu, id, g_sCategories[i]);
			}
		}
	}
	else
	{
		if(g_iCategories>1)
			SetMenuExitBackButton(hMenu, true);
			
		SetMenuTitle(hMenu, g_sCategories[category]);
	
		for(new i=0;i<MAX_HATS;++i)
		{
			if(g_eHats[i][Category]!=category)
				continue;
				
			IntToString(i, id, sizeof(id));
			
			if(!CompareTeam(client, g_eHats[i][Team]))
				continue;
		
			if(g_eHats[i][Flags] != 0 && (!(GetUserFlagBits(client) & g_eHats[i][Flags]) && !(GetUserFlagBits(client) & ADMFLAG_ROOT)))
				continue;
			
			AddMenuItem(hMenu, id, g_eHats[i][Name], (i==g_iHatCache[client][g_eHats[i][Category]]?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT));
		}
	}
	
	return hMenu;
}

public Handler_Hats(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:id[11];
		GetMenuItem(menu, param2, id, sizeof(id));
		
		new i = StringToInt(id);
		
		if(i<0)
		{
			i=(i+1)*-1;
			DisplayMenu(CreateHatsMenu(client, i), client, 0);
		}
		else
		{
			g_iHatCache[client][g_eHats[i][Category]] = i;
			SetClientCookie(client, g_cookieHats[g_eHats[i][Category]], g_eHats[i][ModelPath]);

			if(IsPlayerAlive(client))
				RemoveHat(client, g_eHats[i][Category]);
					
			
			if(IsPlayerAlive(client) && strcmp(g_eHats[i][ModelPath], "")!=0)
			{
				CreateHat(client, g_eHats[i][Category]);
				CPrintToChat(client, "%t", "OS Menu Hats equipped", g_eHats[i][Name]);
			}
			
			DisplayMenu(CreateHatsMenu(client, g_eHats[i][Category]), client, 0);
		}
	}
	else if ((action == MenuAction_Cancel))
	{
		if(param2 == MenuCancel_ExitBack)
		{
			DisplayMenu(CreateHatsMenu(client, -1), client, 0);
		}
	} else if ((action == MenuAction_End))
	{
		CloseHandle(menu);
	}
}

CreateHat(client, slot)
{	
	if(!LookupAttachment(client, "forward"))
		return;

	if(g_eHats[g_iHatCache[client][slot]][Team] != 0 && GetClientTeam(client) != g_eHats[g_iHatCache[client][slot]][Team])
		return;

	if(PlayerIsFirst[client] || PlayerKing[client])
		return;
	
	new Float:or[3];
	new Float:ang[3];
	new Float:fForward[3];
	new Float:fRight[3];
	new Float:fUp[3];
	GetClientAbsOrigin(client,or);
	GetClientAbsAngles(client,ang);
	
	ang[0] += g_eHats[g_iHatCache[client][slot]][Angles][0];
	ang[1] += g_eHats[g_iHatCache[client][slot]][Angles][1];
	ang[2] += g_eHats[g_iHatCache[client][slot]][Angles][2];

	new Float:fOffset[3];
	fOffset[0] = g_eHats[g_iHatCache[client][slot]][Position][0];
	fOffset[1] = g_eHats[g_iHatCache[client][slot]][Position][1];
	fOffset[2] = g_eHats[g_iHatCache[client][slot]][Position][2];

	GetAngleVectors(ang, fForward, fRight, fUp);

	or[0] += fRight[0]*fOffset[0]+fForward[0]*fOffset[1]+fUp[0]*fOffset[2];
	or[1] += fRight[1]*fOffset[0]+fForward[1]*fOffset[1]+fUp[1]*fOffset[2];
	or[2] += fRight[2]*fOffset[0]+fForward[2]*fOffset[1]+fUp[2]*fOffset[2];
	
	new ent = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(ent, "model", g_eHats[g_iHatCache[client][slot]][ModelPath]);
	DispatchKeyValue(ent, "spawnflags", "4");
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 2);
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	DispatchSpawn(ent);	
	AcceptEntityInput(ent, "TurnOn", ent, ent, 0);
	
	g_iHats[client][slot]=ent;
	
	if(!g_bHatView[client])
	{
		SDKHook(ent, SDKHook_SetTransmit, ShouldHide);
	}
	
	TeleportEntity(ent, or, ang, NULL_VECTOR); 
	
	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", client, ent, 0);
	
	SetVariantString("forward");
	AcceptEntityInput(ent, "SetParentAttachmentMaintainOffset", ent, ent, 0);
}

RemoveHats(client)
{
	for(new i=0;i<MAX_CATEGORIES;++i)
	{
		RemoveHat(client, i);
	}
}

RemoveHat(client, slot)
{
	if(IsValidEntity(g_iHats[client][slot]) && g_iHats[client][slot] > MaxClients)
	{
		SDKUnhook(g_iHats[client][slot], SDKHook_SetTransmit, ShouldHide);
		AcceptEntityInput(g_iHats[client][slot], "Kill");
	}
	g_iHats[client][slot]=0;	
}

public Action:ShouldHide(ent, client)
{	
	for(new i=0;i<MAX_CATEGORIES;++i)
		if(ent == g_iHats[client][i])
			return Plugin_Handled;
			
	if(IsClientInGame(client))
		if(GetEntProp(client, Prop_Send, "m_iObserverMode") == 4 && GetEntPropEnt(client, Prop_Send, "m_hObserverTarget")>=0)
			for(new i=0;i<MAX_CATEGORIES;++i)
				if(ent == g_iHats[GetEntPropEnt(client, Prop_Send, "m_hObserverTarget")][i])
					return Plugin_Handled;
	
	return Plugin_Continue;
}

public ItemExists_Hat(const String:data[])
{
	for(new i=0;i<MAX_HATS;++i)
	{
		if(strcmp(g_eHats[i][ModelPath], data)==0 && strcmp(data, "")!=0)
			return i;
	}
	return -1;
}

GetNumCategories(client, &category=0)
{
	new count = 0;

	for(new i=0;i<g_iCategories;++i)
		if(GetNumHats(client, i)>0)
		{
			category=i;
			count++;
		}
			
	return count;
}

GetNumHats(client, category)
{
	new flags = GetUserFlagBits(client);
	new count = 0;

	if(category==-1)
	{
		for(new i=0;i<g_iCategories;++i)
			count+=GetNumHats(client, i);
	}
	else
	{		
		for(new i=0;i<g_iNumHats;++i)
		{
			if(g_eHats[i][Category] == category && (g_eHats[i][Flags]==0?true:bool:(flags & g_eHats[i][Flags])) && CompareTeam(client, g_eHats[i][Team]))
				count++;
		}
	}
	
	return count;
}

bool:CompareTeam(client, team)
{
	new cteam = GetClientTeam(client);
	if(team==0)
	{
		return true;
	}
	else
	{
		if(cteam == team)
		{
			return true;
		}
	}
	return false;
}

public Action:Command_HatShow(client, args)
{
	if(!H_active_hats)
	{
		CPrintToChat(client,  "%t", "Os Menu Hats no access");
		return Plugin_Handled;
	}

	for(new n=0;n<MAX_CATEGORIES;++n)
	{
		new entity = EntRefToEntIndex(g_iHats[client][n]);

		if(IsValidEntRef(entity))
		{

			g_bHatView[client] = !g_bHatView[client];
			if(!g_bHatView[client])
			{
				CPrintToChat(client, "Hat ON");
				SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
			}
			else
			{
				CPrintToChat(client, "Hat OFF");
				SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
			}
		}
	}

	//decl String:sTemp[32];
	//Format(sTemp, sizeof(sTemp), "%T", g_bHatView[client] ? "Hat_On" : "Hat_Off", client);
	//Client_PrintToChat(client, false,  "%s%t", CHAT_TAG, "Hat_View", sTemp);
	return Plugin_Handled;
}

public Action:Hook_SetTransmit(entity, client)
{
	for(new n=0;n<MAX_CATEGORIES;++n)
	{
		if( EntIndexToEntRef(entity) == EntIndexToEntRef(g_iHats[client][n]) )
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

bool:IsValidEntRef(entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}

/********************* Menu Hats Pos **********************/
public Action:Command_HatsAng(client, args)
{
	if(H_active_hats)
	{
		BuildHatsAngMenu(client);
	}
	else
	{
		CPrintToChat(client, "%t", "Os Menu Hats Disable");
	}
	return Plugin_Handled;
}

BuildHatsAngMenu(client)
{
	if( !IsValidClient(client) )
	{
		CPrintToChat(client,  "%t", "Os Menu Hats No Access");
		return;
	}

	new Handle:menu = CreateMenu(HatsAngMenuHandler);

	AddMenuItem(menu, "", "X + 10.0");
	AddMenuItem(menu, "", "Y + 10.0");
	AddMenuItem(menu, "", "Z + 10.0");
	AddMenuItem(menu, "", "");
	AddMenuItem(menu, "", "X - 10.0");
	AddMenuItem(menu, "", "Y - 10.0");
	AddMenuItem(menu, "", "Z - 10.0");

	SetMenuTitle(menu, "Set hat angles.");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public HatsAngMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_End )
		CloseHandle(menu);
	else if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			BuildHatsAngMenu(client);
	}
	else if( action == MenuAction_Select )
	{
		if( IsValidClient(client) )
		{
			BuildHatsAngMenu(client);

			new Float:vAng[3], entity;
			for( new i = 1; i <= MaxClients; i++ )
			{
				if( IsValidClient(i) )
				{
					for(new n=0;n<MAX_CATEGORIES;++n)
					{
						entity = EntIndexToEntRef(g_iHats[i][n]);
						if( IsValidEntRef(entity) )
						{
							GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);
							if( index == 0 ) vAng[0] += 10.0;
							else if( index == 1 ) vAng[1] += 10.0;
							else if( index == 2 ) vAng[2] += 10.0;
							else if( index == 4 ) vAng[0] -= 10.0;
							else if( index == 5 ) vAng[1] -= 10.0;
							else if( index == 6 ) vAng[2] -= 10.0;
							TeleportEntity(entity, NULL_VECTOR, vAng, NULL_VECTOR);
						}
					}
				}
			}
			CPrintToChat(client, "%t", "OS Menu Hats ang", vAng[0], vAng[1], vAng[2]);
		}
	}
}

public Action:Command_HatsSize(client, args)
{
	if(H_active_hats)
	{
		BuildHatsSizeMenu(client);
	}
	else
	{
		CPrintToChat(client, "%t", "Os Menu Hats Disable");
	}
	return Plugin_Handled;
}

BuildHatsSizeMenu(client)
{
	if( !IsValidClient(client) )
	{
		CPrintToChat(client,  "%t", "OS Menu Hats No Access");
		return;
	}

	new Handle:menu = CreateMenu(HatsSizeMenuHandler);

	AddMenuItem(menu, "", "+ 0.1");
	AddMenuItem(menu, "", "- 0.1");
	AddMenuItem(menu, "", "+ 0.5");
	AddMenuItem(menu, "", "- 0.5");
	AddMenuItem(menu, "", "+ 1.0");
	AddMenuItem(menu, "", "- 1.0");

	SetMenuTitle(menu, "Set hat size.");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public HatsSizeMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_End )
		CloseHandle(menu);
	else if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			BuildHatsSizeMenu(client);
	}
	else if( action == MenuAction_Select )
	{
		if( IsValidClient(client) )
		{
			BuildHatsSizeMenu(client);

			new Float:fSize, entity;
			for( new i = 1; i <= MaxClients; i++ )
			{
				for(new n=0;n<MAX_CATEGORIES;++n)
				{
					entity = EntIndexToEntRef(g_iHats[i][n]);
					if( IsValidEntRef(entity) )
					{
						fSize = GetEntPropFloat(entity, Prop_Send, "m_flModelScale");
						if( index == 0 ) fSize += 0.1;
						else if( index == 1 ) fSize -= 0.1;
						else if( index == 2 ) fSize += 0.5;
						else if( index == 3 ) fSize -= 0.5;
						else if( index == 4 ) fSize += 1.0;
						else if( index == 5 ) fSize -= 1.0;
						SetEntPropFloat(entity, Prop_Send, "m_flModelScale", fSize);
					}
				}
			}

			CPrintToChat(client, "%t", "OS Menu Hats size", fSize);
		}
	}
}

public Action:Command_HatsPos(client, args)
{
	if(H_active_hats)
	{
		BuildHatsPosMenu(client);
	}
	else
	{
		CPrintToChat(client, "%t", "Os Menu Hats Disable");
	}
	return Plugin_Handled;
}

BuildHatsPosMenu(client)
{
	if( !IsValidClient(client) )
	{
		CPrintToChat(client,  "%t", "OS Menu Hats No Access");
		return;
	}

	new Handle:menu = CreateMenu(HatsPosMenuHandler);

	AddMenuItem(menu, "", "X + 0.5");
	AddMenuItem(menu, "", "Y + 0.5");
	AddMenuItem(menu, "", "Z + 0.5");
	AddMenuItem(menu, "", "");
	AddMenuItem(menu, "", "X - 0.5");
	AddMenuItem(menu, "", "Y - 0.5");
	AddMenuItem(menu, "", "Z - 0.5");

	SetMenuTitle(menu, "Set hat position.");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public HatsPosMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_End )
		CloseHandle(menu);
	else if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			BuildHatsPosMenu(client);
	}
	else if( action == MenuAction_Select )
	{
		if( IsValidClient(client) )
		{
			BuildHatsPosMenu(client);

			new Float:vPos[3], entity;
			for( new i = 1; i <= MaxClients; i++ )
			{
				if( IsValidClient(i) )
				{
					for(new n=0;n<MAX_CATEGORIES;++n)
					{
						entity = EntIndexToEntRef(g_iHats[i][n]);
						if( IsValidEntRef(entity) )
						{
							GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
							if( index == 0 ) vPos[0] += 0.5;
							else if( index == 1 ) vPos[1] += 0.5;
							else if( index == 2 ) vPos[2] += 0.5;
							else if( index == 4 ) vPos[0] -= 0.5;
							else if( index == 5 ) vPos[1] -= 0.5;
							else if( index == 6 ) vPos[2] -= 0.5;
							TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
						}
					}
				}
			}
			CPrintToChat(client, "%t", "OS Menu Hats origin", vPos[0], vPos[1], vPos[2]);
		}
	}
}



