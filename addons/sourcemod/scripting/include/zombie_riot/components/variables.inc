/*    <DR.API ZOMBIE RIOT> (c) by <De Battista Clint - (http://doyou.watch)  */
/*                                                                           */
/*                  <DR.API ZOMBIE RIOT> is licensed under a                 */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//*************************DR.API ZOMBIE RIOT VARIABLES**********************//
//***************************************************************************//
//***************************************************************************//

//***********************************//
//*********CVARS VARIABLES***********//
//***********************************//
//DEFINES
#define															KNIFE 2

#define 														DEFAULT_FOV 90
#define 														DEFAULT_GRAVITY 1.0

#define 														NONE 0
#define 														SPECTATOR 1


//HANDLLES
Handle cvar_active_zombie_riot;
Handle cvar_active_zombie_riot_dev;

Handle cvar_zombie_riot_hostname;

Handle cvar_zombie_riot_remove_objectives;
Handle cvar_zombie_riot_remove_buyzone;

Handle cvar_zombie_riot_respawn_time;
Handle cvar_zombie_riot_cash;
Handle cvar_zombie_riot_freeze_time_zombies;
Handle cvar_zombie_riot_remove_radgoll;
Handle cvar_zombie_riot_hud;
Handle cvar_zombie_riot_hud_targeting;
Handle cvar_zombie_riot_collision;
Handle cvar_zombie_riot_overlays;
Handle cvar_zombie_riot_zvision;
Handle cvar_zombie_riot_sounds;

/*VALVE UPDATE USELESS
Handle cvar_zombie_riot_ammo_338mag_max;
Handle cvar_zombie_riot_ammo_357sig_max;
Handle cvar_zombie_riot_ammo_45acp_max;
Handle cvar_zombie_riot_ammo_50AE_max;
Handle cvar_zombie_riot_ammo_556mm_box_max;
Handle cvar_zombie_riot_ammo_556mm_max;
Handle cvar_zombie_riot_ammo_57mm_max;
Handle cvar_zombie_riot_ammo_762mm_max;
Handle cvar_zombie_riot_ammo_9mm_max;
Handle cvar_zombie_riot_ammo_buckshot_max;
Handle cvar_zombie_riot_ammo_357sig_small_max;
Handle cvar_zombie_riot_ammo_556mm_small_max;
Handle cvar_zombie_riot_ammo_357sig_p250_max;

Handle ammo_338mag_max;
Handle ammo_357sig_max;
Handle ammo_45acp_max;
Handle ammo_50AE_max;
Handle ammo_556mm_box_max;
Handle ammo_556mm_max;
Handle ammo_57mm_max;
Handle ammo_762mm_max;
Handle ammo_9mm_max;
Handle ammo_buckshot_max;
Handle ammo_357sig_small_max;
Handle ammo_556mm_small_max;
Handle ammo_357sig_p250_max;
*/

Handle mp_autoteambalance;
Handle mp_limitteams;
Handle mp_freezetime;
Handle mp_timelimit;
Handle mp_roundtime;
Handle mp_maxrounds;
Handle mp_ignore_round_win_conditions;
Handle sv_turbophysics;
Handle phys_pushscale;
Handle mp_humanteam;
Handle bot_join_team;
Handle bot_chatter;
Handle mp_ct_default_melee;
Handle mp_ct_default_secondary;
Handle mp_ct_default_primary;
Handle mp_t_default_melee;
Handle mp_t_default_secondary;
Handle mp_t_default_primary;
Handle mp_weapons_glow_on_ground;
Handle sv_ignoregrenaderadio;

//INT
int INT_ZOMBIE_KILLED;

int H_zombie_riot_respawn_time;
int H_zombie_riot_cash;

/*VALVE UPDATE USELESS
int H_zombie_riot_ammo_338mag_max;
int H_zombie_riot_ammo_357sig_max;
int H_zombie_riot_ammo_45acp_max;
int H_zombie_riot_ammo_50AE_max;
int H_zombie_riot_ammo_556mm_box_max;
int H_zombie_riot_ammo_556mm_max;
int H_zombie_riot_ammo_57mm_max;
int H_zombie_riot_ammo_762mm_max;
int H_zombie_riot_ammo_9mm_max;
int H_zombie_riot_ammo_buckshot_max;
int H_zombie_riot_ammo_357sig_small_max;
int H_zombie_riot_ammo_556mm_small_max;
int H_zombie_riot_ammo_357sig_p250_max;

int backup_ammo_338mag_max; 
int backup_ammo_357sig_max;
int backup_ammo_45acp_max;
int backup_ammo_50AE_max;
int backup_ammo_556mm_box_max;
int backup_ammo_556mm_max;
int backup_ammo_57mm_max;
int backup_ammo_762mm_max;
int backup_ammo_9mm_max;
int backup_ammo_buckshot_max;
int backup_ammo_357sig_small_max;
int backup_ammo_556mm_small_max;
int backup_ammo_357sig_p250_max;
*/

int backup_mp_limitteams;
int backup_mp_freezetime;
int backup_mp_timelimit;
int backup_mp_roundtime;
int backup_mp_maxrounds;
int backup_mp_ignore_round_win_conditions;
int backup_sv_turbophysics;
int backup_phys_pushscale;
int backup_mp_weapons_glow_on_ground;
int backup_sv_ignoregrenaderadio;

//BOOLS
bool B_active_zombie_riot;
bool B_active_zombie_riot_dev;

bool B_zombie_riot_remove_objectives;
bool B_zombie_riot_remove_buyzone;

bool B_zombie_riot_hud;
bool B_zombie_riot_hud_targeting;
bool B_zombie_riot_collision;
bool B_zombie_riot_overlays;
bool B_zombie_riot_sounds;

bool backup_mp_autoteambalance;

bool PLUGIN_AIRDROP 											= false;
bool B_day_start												= true;

//FLOATS
float F_zombie_riot_freeze_time_zombies;
float F_zombie_riot_remove_radgoll;
float F_zombie_riot_zvision;

//STRING
char S_zombie_riot_hostname[512];
char backup_mp_humanteam[24];
char backup_bot_join_team[24];
char backup_bot_chatter[24];
char backup_mp_ct_default_melee[24];
char backup_mp_ct_default_secondary[24];
char backup_mp_ct_default_primary[24];
char backup_mp_t_default_melee[24];
char backup_mp_t_default_secondary[24];
char backup_mp_t_default_primary[24];

//***********************************//
//******ZOMBIES DATAS VARIABLES******//
//***********************************//
//DEFINES

#define 														MAX_ZOMBIES	100
//HANDLES
Handle kvZombies 												= INVALID_HANDLE;
Handle adtModels 												= INVALID_HANDLE;
Handle adtZombies = INVALID_HANDLE;

//INT
int ZOMBIE_COUNT;

int data_health[MAX_ZOMBIES];
int data_fov[MAX_ZOMBIES];

//BOOLS
bool data_override_required[MAX_ZOMBIES];

//FLOATS
float data_speed[MAX_ZOMBIES];
float data_gravity[MAX_ZOMBIES];
float data_jump[MAX_ZOMBIES];

//STRINGS
char data_name[MAX_ZOMBIES][64];
char data_model[MAX_ZOMBIES][256];
char data_zvision[MAX_ZOMBIES][256];
char modelSuffix[8][16] 										= {
																	".dx80.vtx", 
																	".dx90.vtx", 
																	".mdl", 
																	".phy", 
																	".sw.vtx", 
																	".vvd", 
																	".xbox", 
																	".xbox.vtx"
																};
																
//***********************************//
//*******DAYS DATAS VARIABLES********//
//***********************************//

//DEFINES
#define 														MAX_DAYS 25

//HANDLE 
Handle kvDays 													= INVALID_HANDLE;
	
//INT
int INT_CURRENT_DAY;
int INT_TOTAL_DAY;

int data_respawn[MAX_DAYS];
int data_admin_respawn_time[MAX_DAYS];
int data_vip_respawn_time[MAX_DAYS];
int data_player_respawn_time[MAX_DAYS];
int data_count[MAX_DAYS];
int data_count2[MAX_DAYS];
int data_healthboost[MAX_DAYS];
int data_deaths_before_zombie[MAX_DAYS];
int data_add_zombies_by_player[MAX_DAYS];
int data_regression[MAX_DAYS];

//FLOATS
float data_fademin[MAX_DAYS];
float data_fademax[MAX_DAYS];
float data_sound_timer[MAX_DAYS];
	
//STRINGS
char data_display[MAX_DAYS][64];
char data_storyline[MAX_DAYS][129];
char data_zombieoverride[MAX_DAYS][32*MAX_ZOMBIES];
char data_overlay_human[MAX_DAYS][32*MAX_ZOMBIES];
char data_overlay_zombie[MAX_DAYS][32*MAX_ZOMBIES];
char data_sound[MAX_DAYS][PLATFORM_MAX_PATH];
char data_ct_default_melee[MAX_DAYS][64], data_ct_default_secondary[MAX_DAYS][64], data_ct_default_primary[MAX_DAYS][64];


//***********************************//
//********DEATHS VARIABLES***********//
//***********************************//

//HANDLE
Handle trie_iDeaths = INVALID_HANDLE;

//***********************************//
//*********DAYS VARIABLES************//
//***********************************//

//HANDLE
Handle trie_countDay = INVALID_HANDLE;

//***********************************//
//********HUMANS VARIABLES***********//
//***********************************//

//DEFINES
#define HUMAN													3

//HANDLES
Handle H_Timer_Respawn[MAXPLAYERS + 1]							= INVALID_HANDLE;

//INT
int INT_NB_HUMANS_PLAYER_IN_GAME								= 0;
int INT_NB_HUMANS_BOT_IN_GAME									= 0;
int INT_NB_HUMANS_BOTH_IN_GAME									= 0;

int INT_NB_HUMANS_PLAYER_ALIVE									= 0;
int INT_NB_HUMANS_BOT_ALIVE										= 0;
int INT_NB_HUMANS_BOTH_ALIVE									= 0;

int Timer_Respawn[MAXPLAYERS + 1];

//BOOLS
bool B_Player_Is_Human[MAXPLAYERS + 1]							= false;

//FLOATS


//CUSTOMS
C_Player_Is_Human[MAXPLAYERS + 1];

//***********************************//
//********ZOMBIES VARIABLES**********//
//***********************************//

//DEFINES
#define ZOMBIE													2

//HANDLES
Handle H_Timer_Freeze											= INVALID_HANDLE;
Handle H_Timer_Zvision[MAXPLAYERS + 1]							= INVALID_HANDLE;
//INT
int INT_NB_ZOMBIES_PLAYER_IN_GAME								= 0;
int INT_NB_ZOMBIES_BOT_IN_GAME									= 0;
int INT_NB_ZOMBIES_BOTH_IN_GAME									= 0;

int INT_NB_ZOMBIES_PLAYER_ALIVE									= 0;
int INT_NB_ZOMBIES_BOT_ALIVE									= 0;
int INT_NB_ZOMBIES_BOTH_ALIVE									= 0;

int INT_ZOMBIE_ID[MAXPLAYERS + 1];


//BOOLS
bool B_Player_Is_Zombie[MAXPLAYERS + 1]							= false;
bool B_Force_Player_Is_Zombie[MAXPLAYERS + 1]					= false;


//CUSTOMS
C_Player_Is_Zombie[MAXPLAYERS + 1];
C_show_zvision[MAXPLAYERS + 1];

//***********************************//
//***********HUD VARIABLES***********//
//***********************************//

//HANDLES
Handle H_Timer_HUD												= INVALID_HANDLE;

//BOOLS
bool B_Target[MAXPLAYERS + 1][MAXPLAYERS + 1];

//CUSTOMS
C_Target[MAXPLAYERS + 1];
C_show_hud[MAXPLAYERS + 1];

//***********************************//
//********OVERLAYS VARIABLES*********//
//***********************************//

//CUSTOMS
C_show_overlays[MAXPLAYERS + 1];

//***********************************//
//*********ADMINS VARIABLES**********//
//***********************************//

//HANDLES
Handle hAdminMenu 												= INVALID_HANDLE;
TopMenuObject obj_admin_menu_zombie_riot 						= INVALID_TOPMENUOBJECT;

//***********************************//
//**********MENUS VARIABLES**********//
//***********************************//

//HANDLE
Handle hOnMenuZombieRiotReady									= INVALID_HANDLE;
TopMenu MenuZombieRiot;
TopMenuObject obj_menu_zombie_riot 								= INVALID_TOPMENUOBJECT;

//***********************************//
//**********ZRMENU VARIABLES*********//
//***********************************//

//ENUMS
enum HelpMenuType 
{
	HelpMenuType_List,
	HelpMenuType_Text
}

enum HelpMenu 
{
	String:Hname[32],
	String:Htitle[128],
	HelpMenuType:Htype,
	Handle:Hitems,
	itemct
}

//HANDLE
Handle Array_Helpmenus 											= INVALID_HANDLE;
Handle Array_Map 												= INVALID_HANDLE;

//Customs
int C_mapSerial 												= -1;
int C_configLevel 												= -1;

//***********************************//
//*********SOUNDS VARIABLES**********//
//***********************************//

//DEFINES
#define															SNDCHAN_AMBIENT 8
#define															SNDCHAN_DEATH 9

//HANDLES
Handle H_Timer_Ambient_Sound[MAXPLAYERS + 1]					= INVALID_HANDLE;

//STRINGS

char S_sound_death[8][]											= {
																  "zombie/zombie_die7d77.mp3",
																  "zombie/zombie_die6d66.mp3",
																  "zombie/zombie_die5d55.mp3",
																  "zombie/zombie_die3d33.mp3",
																  "zombie/zombie_die2d22.mp3",
																  "zombie/zombie_die1d11.mp3",
																  "zombie/zombie_die8d.mp3",
																  "zombie/zombie_die4d.mp3"
																  };
//CUSTOMS
C_play_sound[MAXPLAYERS + 1];

//***********************************//
//**********BOTS VARIABLES***********//
//***********************************//
UserMsg TextMsg;
UserMsg SayText; 
UserMsg SayText2;
UserMsg RadioText;