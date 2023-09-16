/*      <DR.API MEDIC> (c) by <De Battista Clint - (http://doyou.watch)      */
/*                                                                           */
/*                     <DR.API MEDIC> is licensed under a                    */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//******************************DR.API MEDIC*********************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[MEDIC] -"

#define MAX_NUM_SETS					13
#define MAX_MAPS						100
#define MAX_DAYS 						25

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <stocks>
#include <drapi_zombie_riot>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle kvDays 												= INVALID_HANDLE;
Handle hZombieRiotMenu										= INVALID_HANDLE;
Handle cvar_active_medic_dev;
Handle cvar_active_medic_mode;
Handle cvar_medic_kill_zombie;
Handle cvar_medic_timer;
Handle cvar_medic_default_hp;
Handle cvar_medic_heal_hp;
Handle Timers[MAXPLAYERS+1];

//Bool
bool B_active_medic_dev 					= false;

//FloatAbs
float F_medic_timer[MAXPLAYERS+1];

//Cutoms 
int INT_TOTAL_DAY;
int data_medic_time[MAX_DAYS];
int data_medic_kill[MAX_DAYS];
int Kill[MAXPLAYERS+1];
int life[MAXPLAYERS + 1];
int H_active_medic_mode;
int H_current_map_kill;
int H_current_map_timer;
int H_medic_kill_zombie;
int H_medic_timer;
int H_medic_default_hp;
int H_medic_heal_hp;
int icon[MAXPLAYERS+1];
int C_pourcentage[MAXPLAYERS+1];


//String
//new String:S_mapname[MAX_MAPS][64];
//new String:S_mapname_kill[MAX_MAPS][64];
//new String:S_mapname_timer[MAX_MAPS][64];


//Sounds
static const char S_medic_sound[MAX_NUM_SETS][PLATFORM_MAX_PATH] 				= {
																				"z4e/medic/demoman_medic01.mp3",
																				"z4e/medic/demoman_medic03.mp3",
																				"z4e/medic/engineer_medic02.mp3",
																				"z4e/medic/engineer_medic03.mp3",
																				"z4e/medic/heavy_medic01.mp3",
																				"z4e/medic/heavy_medic02.mp3",
																				"z4e/medic/medic_medic02.mp3",
																				"z4e/medic/medic_medic03.mp3",
																				"z4e/medic/pyro_medic01.mp3",
																				"z4e/medic/scout_medic01.mp3",
																				"z4e/medic/sniper_medic02.mp3",
																				"z4e/medic/soldier_medic01.mp3",
																				"z4e/medic/spy_DominationMedic02.mp3"
																				};
//Informations plugin
public Plugin myinfo =
{
	name = "DR.API MEDIC",
	author = "Dr. Api",
	description = "DR.API MEDIC by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://doyou.watch"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	AutoExecConfig_SetFile("drapi_medic", "sourcemod/drapi");
	//LoadSettings();
	LoadTranslations("drapi/drapi_medic.phrases");
	
	AutoExecConfig_CreateConVar("drapi_medic_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_medic_dev						= AutoExecConfig_CreateConVar("drapi_medic_active_dev", 			"0", 					"Enable/Disable Bot Dev Mod", 											DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	cvar_active_medic_mode						= AutoExecConfig_CreateConVar("drapi_active_medic_mode", 			"3", 					"1 = kill, 2 = timer, 3 = both", 										DEFAULT_FLAGS);
	cvar_medic_kill_zombie						= AutoExecConfig_CreateConVar("drapi_medic_kill_zombie", 			"20", 					"How much zombie to kill for getting medic", 							DEFAULT_FLAGS);
	cvar_medic_timer							= AutoExecConfig_CreateConVar("drapi_medic_timer", 					"60", 					"Time for getting medic", 												DEFAULT_FLAGS);
	cvar_medic_default_hp						= AutoExecConfig_CreateConVar("drapi_medic_default_hp", 			"0", 					"0 = player health max, HP of the player at beginin", 					DEFAULT_FLAGS);
	cvar_medic_heal_hp							= AutoExecConfig_CreateConVar("drapi_medic_heal_hp", 				"0", 					"0 =player health max, Ammout heal HP", 								DEFAULT_FLAGS);
	
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	RegConsoleCmd("sm_medic", 				Command_Medic, 			"medic to heal yourself");
	RegConsoleCmd("sm_medicmenu",			Command_MedicMenu, 		"Zombie riot medic menu");
	RegServerCmd("sm_create_medic_tables",	Command_CreateTables);
	
	HookEvents();
	
	SQL_LoadPrefAllClients();
	
	AutoExecConfig_ExecuteFile();
	
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
			ClearIconMedic(i);
			Kill[i] = 0;
			F_medic_timer[i] = 0.0;
		}
		i++;
	}
}
/***********************************************************/
/**************** WHEN CLIENT PUT IN SERVER ****************/
/***********************************************************/
public void OnClientPutInServer(int client)
{
	Kill[client] = 0;
	icon[client] = 0;
	F_medic_timer[client] = 0.0;
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
	Kill[client] = 0;
	ClearIconMedic(client);
	ClearTimer(Timers[client]);
	F_medic_timer[client] = 0.0;
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEvents()
{
	HookConVarChange(cvar_active_medic_dev, 				Event_CvarChange);
	HookConVarChange(cvar_active_medic_mode, 				Event_CvarChange);
	HookConVarChange(cvar_medic_kill_zombie, 				Event_CvarChange);
	HookConVarChange(cvar_medic_timer, 						Event_CvarChange);
	HookConVarChange(cvar_medic_default_hp, 				Event_CvarChange);
	HookConVarChange(cvar_medic_heal_hp, 					Event_CvarChange);
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
	B_active_medic_dev 							= GetConVarBool(cvar_active_medic_dev);
	H_active_medic_mode 						= GetConVarInt(cvar_active_medic_mode);
	H_medic_kill_zombie 						= GetConVarInt(cvar_medic_kill_zombie);
	H_medic_timer 								= GetConVarInt(cvar_medic_timer);
	H_medic_default_hp 							= GetConVarInt(cvar_medic_default_hp);
	H_medic_heal_hp 							= GetConVarInt(cvar_medic_heal_hp);
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
	AddFileToDownloadsTable("materials/sprites/z4e/medic/icon_medkit.vmt");
	AddFileToDownloadsTable("materials/sprites/z4e/medic/icon_medkit.vtf");
		
	PrecacheModel("materials/sprites/z4e/medic/icon_medkit.vmt");
		
	//LoadSettings();
	FakeAndDownloadSound(false, S_medic_sound, sizeof(S_medic_sound) - 1);
	
	LoadDayData("configs/drapi/zombie_riot/days", "cfg");
	UpdateState();
}

/***********************************************************/
/******************** WHEN ROUND START *********************/
/***********************************************************/
public void Event_RoundStart(Handle event, char[] name, bool dontBroadcast)
{	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	H_current_map_timer = GetDayMedicTime(ZRiot_GetDay() - 1);
	H_current_map_kill = GetDayMedicKill(ZRiot_GetDay() - 1);
	
	F_medic_timer[client] = GetEngineTime() + H_current_map_timer;
	Kill[client] = 0;
}

/***********************************************************/
/******************** WHEN PLAYER SPAWN ********************/
/***********************************************************/
public void Event_PlayerSpawn(Handle event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(3.0, Timer_Checklife, client);
	
	H_current_map_timer = GetDayMedicTime(ZRiot_GetDay() - 1);
	H_current_map_kill = GetDayMedicKill(ZRiot_GetDay() - 1);
	
	F_medic_timer[client] = GetEngineTime() + H_current_map_timer;
	Kill[client] = 0;
}
/***********************************************************/
/******************* WHEN PLAYER HURT **********************/
/***********************************************************/
public void Event_PlayerHurt(Handle event, char[] name, bool dontBroadcast)
{
	int client 			= GetClientOfUserId(GetEventInt(event, "userid"));
	int liferemaining	= GetEventInt(event, "health");
	
	int pourcentage = RoundToNearest(float(liferemaining) / float(life[client]) * 100.0);
	
	if(pourcentage <= C_pourcentage[client])
	{
		if(GetClientTeam(client) == CS_TEAM_CT)
		{
			Heal(client, false);
		}
	}
}

/***********************************************************/
/******************** WHEN PLAYER DIE **********************/
/***********************************************************/
public void Event_PlayerDeath(Handle event, char[] name, bool dontBroadcast)
{	
	int victim 				= GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker 			= GetClientOfUserId(GetEventInt(event, "attacker"));
	
	Kill[victim] = 0;
	Kill[attacker]++;
	ClearIconMedic(victim);
	ClearTimer(Timers[victim]);
	F_medic_timer[victim] = 0.0;
}

/***********************************************************/
/********************** ON GAME FRAME **********************/
/***********************************************************/

public void OnGameFrame()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(Client_IsIngame(i))
		{
			int newlife = GetClientHealth(i);
			if(newlife >= life[i] && life[i] != 0 && !H_medic_default_hp)
			{
				life[i] = newlife;
			}
		}
	}
}

/***********************************************************/
/******************** CMD SHOWSPRITE ***********************/
/***********************************************************/
public Action ShowSprite(int client, int args)
{
	if(IconValid(client))
	{
		ClearIconMedic(client);
	}
	else
	{
		CreateIconSoundHeal(client, 100);
	}
}

/***********************************************************/
/********************** MENU CMD MEDIC *********************/
/***********************************************************/
public Action Command_Medic(int client, int args)
{

	Heal(client, true);
	return Plugin_Handled;
}

/***********************************************************/
/*************************** HEAL **************************/
/***********************************************************/
void Heal(int client, bool chat)
{
	int lifenow = GetClientHealth(client);
	int healamount;
	
	if(H_medic_default_hp != 0 && H_medic_heal_hp == 0)
	{
		healamount = H_medic_default_hp;
	}
	else if(H_medic_default_hp != 0 && H_medic_heal_hp !=0)
	{
		//H_medic_default_hp = 125
		//H_medic_heal_hp = 40%
		int lifetogive = lifenow + H_medic_heal_hp;
		
		PrintToDev(B_active_medic_dev, "%s BaseHP: %i, Medic Heal: %i, Life Now :%i; Life to give : %i", TAG_CHAT, life[client], H_medic_heal_hp, lifenow, lifetogive);		
		
		if(lifetogive > H_medic_default_hp)
		{
			healamount = life[client];
		}
		else
		{
			healamount = lifetogive;
		}
		
	}
	else if(H_medic_default_hp == 0 && H_medic_heal_hp !=0)
	{
		//life[client] = 200
		//H_medic_heal_hp = 40%
		//lifenow = 38
		
		//lifetogive = 38 + (40 / 100) = 15.2
		//healamount
		
		int lifetogive = lifenow + H_medic_heal_hp;
		
		PrintToDev(B_active_medic_dev, "%s BaseHP: %i, Medic Heal: %i, Life Now :%i; Life to give : %i", TAG_CHAT, life[client], H_medic_heal_hp, lifenow, lifetogive);
		
		if(lifetogive > life[client])
		{
			healamount = life[client];
		}
		else
		{
			healamount = lifetogive;
		}
	}
	else
	{
		healamount = life[client];
	}
		
	if(IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_CT)
	{
		//KILL MODE
		if(H_active_medic_mode == 1)
		{
			 if(Kill[client] >= H_current_map_kill)
			 {
				if(life[client] > lifenow)
				{	
					CreateIconSoundHeal(client, healamount);
				}
				else
				{
					CPrintToChat(client, "%t", "Medic can be used");
				}
			 }
			 else
			 {
				if(chat)
				{
					int KillRemaining = H_current_map_kill - Kill[client];
					CPrintToChat(client, "%t", "Medic Must kill zombies", KillRemaining);
				}
			 }
		}
		//TIMER MODE
		else if (H_active_medic_mode == 2)
		{
			float now = GetEngineTime();
			if(F_medic_timer[client] <= now)
			{
				if(life[client] > lifenow)
				{	
					CreateIconSoundHeal(client, healamount);
				}
				else
				{
					CPrintToChat(client, "%t", "Medic can be used");
				}
			}
			else
			{
				if(chat)
				{
					int TimeRemaining =  RoundFloat(F_medic_timer[client] - GetEngineTime());
					CPrintToChat(client, "%t", "Medic Must wait", TimeRemaining);
				}
				
				
			}
		}
		//KILL + TIMER MODE
		else if(H_active_medic_mode == 3)
		{
			float now = GetEngineTime();
			if(Kill[client] >= H_current_map_kill || F_medic_timer[client] <= now)
			{
				if(life[client] > lifenow)
				{	
					CreateIconSoundHeal(client, healamount);
				}
				else
				{
					CPrintToChat(client, "%t", "Medic can be used");
				}
			}
			else
			{
				if(chat)
				{	
					int TimeRemaining =  RoundFloat(F_medic_timer[client] - GetEngineTime());
					int KillRemaining = H_current_map_kill - Kill[client];
					CPrintToChat(client, "%t", "Medic Must wait and kill", TimeRemaining, KillRemaining);
				}
			}
		}
	}
	else if(!IsPlayerAlive(client))
	{
		CPrintToChat(client, "%t", "Medic player die");
	}
	else if(GetClientTeam(client) == CS_TEAM_T)
	{
		CPrintToChat(client, "%t", "Medic player is zombie");
	}
}
/***********************************************************/
/**************** CREATE ICON SOUND AND HEAL ***************/
/***********************************************************/
void CreateIconSoundHeal(int client, int healamount)
{
	SetEntityHealth(client, healamount);
	
	PlayRandomVoice(client);
	Kill[client] = 0;
	F_medic_timer[client] = GetEngineTime() + H_current_map_timer;
	
	icon[client] = CreateIconMedic(client);
	
	ClearTimer(Timers[client]);
	Timers[client] = CreateTimer(3.0, ClearIconMedicUsed, client, 0);
	
	CPrintToChat(client, "%t", "Medic used");
}
/***********************************************************/
/********************* IMER CHECK LIFE *********************/
/***********************************************************/

public Action Timer_Checklife(Handle timer, any client)
{
	if(Client_IsIngame(client))
	{
		if(H_medic_default_hp)
		{
			life[client] = H_medic_default_hp;
		}
		else
		{
			life[client] = GetClientHealth(client);
		}
		
		PrintToDev(B_active_medic_dev, "%s Client spawn, totalvie:%i hp", TAG_CHAT, life[client]);
	}
	
	return Plugin_Stop;
}

/***********************************************************/
/*********************** VOICE RANDOM **********************/
/***********************************************************/
void PlayRandomVoice(int client)
{
	int random = GetRandomInt(0, 12);

	char S_sound_to_play[PLATFORM_MAX_PATH];
	Format(S_sound_to_play, PLATFORM_MAX_PATH, "*%s", S_medic_sound[random]);
	
	PlaySound(client, S_sound_to_play);
	//EmitSoundToClient( client, S_sound_to_play );
}

/***********************************************************/
/************************ PLAY SOUND ***********************/
/***********************************************************/
void PlaySound(int client, const char[] sound)
{
	int[] newClients = new int[MaxClients];
	int totalClients = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
				newClients[totalClients++] = i;
		}
	}
	
	float position[3];
	GetClientAbsOrigin(client, position);
	
	EmitSound(newClients, totalClients, sound, client, SNDCHAN_VOICE, SNDLEVEL_SCREAMING, SND_NOFLAGS, 1.0, _, _, position);
	
	PrintToDev(B_active_medic_dev, "%s Medic sound : %s, Array clients: %i, Num. clients: %i", TAG_CHAT, sound, newClients, totalClients);
}

/***********************************************************/
/********************* CREATE ICON MEDIC *******************/
/***********************************************************/
int CreateIconMedic(int client)
{
	char iTarget[16];
	Format(iTarget, 16, "client%d", client);
	DispatchKeyValue(client, "targetname", iTarget);
	float origin[3];
	GetClientAbsOrigin(client, origin);
	origin[0] = origin[0] + 0.0;
	origin[1] = origin[1] + 0.0;
	origin[2] = origin[2] + 108.0;
	
	int Ent = CreateEntityByName("env_sprite", -1);
	if (!Ent)
	{
		return false;
	}
	
	DispatchKeyValue(Ent, "model", "materials/sprites/z4e/medic/icon_medkit.vmt");
	//new String:fadeout[32];
	//IntToString(H_hpbar_fadeout_t, fadeout, 32);
	
	DispatchKeyValue(Ent, "classname", "medic");
	//DispatchKeyValue(Ent, "fademaxdist", fadeout);
	DispatchKeyValue(Ent, "spawnflags", "1");
	//DispatchKeyValue(Ent, "scale", "0.08");
	DispatchKeyValue(Ent, "rendermode", "1");
	DispatchKeyValue(Ent, "rendercolor", "255 255 255");
	DispatchSpawn(Ent);
	TeleportEntity(Ent, origin, NULL_VECTOR, NULL_VECTOR);
	SetVariantString(iTarget);
	AcceptEntityInput(Ent, "SetParent", Ent, Ent, 0);
	return EntIndexToEntRef(Ent);
}

/***********************************************************/
/******************** CLEAR ICON MEDIC *********************/
/***********************************************************/
void ClearIconMedic(int client)
{
	if (icon[client])
	{
		int entity = EntRefToEntIndex(icon[client]);
		if (entity != -1)
		{
			AcceptEntityInput(entity, "Kill", -1, -1, 0);
		}
		icon[client] = 0;
	}
}

/***********************************************************/
/*************** CLEAR ICON MEDIC WHEN USED ****************/
/***********************************************************/
public Action ClearIconMedicUsed(Handle timer, any client)
{
	Timers[client] = INVALID_HANDLE;
	ClearIconMedic(client);
	return Plugin_Stop;
}

/***********************************************************/
/******************** CHECK ICON VALID *********************/
/***********************************************************/
bool IconValid(int client)
{
	if (icon[client])
	{
		int entity = EntRefToEntIndex(icon[client]);
		if (entity != -1)
		{
			return true;
		}
	}
	return false;
}

/***********************************************************/
/************************ MENU MEDIC ***********************/
/***********************************************************/
public Action Command_MedicMenu(int client, int args)
{
	BuildMenuMedic(client);
	return Plugin_Handled;
}

/***********************************************************/
/**************** BUILD ZOMBIE RIOT MENU *******************/
/***********************************************************/
void BuildMenuMedic(int client)
{
	char title[40]; 
	char pourcentage_10[40], pourcentage_20[40], pourcentage_30[40], pourcentage_40[40], pourcentage_50[40];
	Menu menu = CreateMenu(MenuMedicAction);
	
	if(C_pourcentage[client] != 10)
	{
		Format(pourcentage_10, sizeof(pourcentage_10), "%T", "MenuMedic_POURCENTAGE_MENU_TITLE_10", client);
		AddMenuItem(menu, "M_pourcentage_10", pourcentage_10);
	}
	else
	{
		Format(pourcentage_10, sizeof(pourcentage_10), "%T", "MenuMedic_POURCENTAGE_MENU_TITLE_10", client);
		AddMenuItem(menu, "M_pourcentage_10", pourcentage_10, ITEMDRAW_DISABLED);	
	}
	
	if(C_pourcentage[client] != 20)
	{
		Format(pourcentage_20, sizeof(pourcentage_20), "%T", "MenuMedic_POURCENTAGE_MENU_TITLE_20", client);
		AddMenuItem(menu, "M_pourcentage_20", pourcentage_20);
	}
	else
	{
		Format(pourcentage_20, sizeof(pourcentage_20), "%T", "MenuMedic_POURCENTAGE_MENU_TITLE_20", client);
		AddMenuItem(menu, "M_pourcentage_20", pourcentage_20, ITEMDRAW_DISABLED);	
	}
	
	if(C_pourcentage[client] != 30)
	{
		Format(pourcentage_30, sizeof(pourcentage_30), "%T", "MenuMedic_POURCENTAGE_MENU_TITLE_30", client);
		AddMenuItem(menu, "M_pourcentage_30", pourcentage_30);
	}
	else
	{
		Format(pourcentage_30, sizeof(pourcentage_30), "%T", "MenuMedic_POURCENTAGE_MENU_TITLE_30", client);
		AddMenuItem(menu, "M_pourcentage_30", pourcentage_30, ITEMDRAW_DISABLED);	
	}
	
	if(C_pourcentage[client] != 40)
	{
		Format(pourcentage_40, sizeof(pourcentage_40), "%T", "MenuMedic_POURCENTAGE_MENU_TITLE_40", client);
		AddMenuItem(menu, "M_pourcentage_40", pourcentage_40);
	}
	else
	{
		Format(pourcentage_40, sizeof(pourcentage_40), "%T", "MenuMedic_POURCENTAGE_MENU_TITLE_40", client);
		AddMenuItem(menu, "M_pourcentage_40", pourcentage_40, ITEMDRAW_DISABLED);	
	}
	
	if(C_pourcentage[client] != 50)
	{
		Format(pourcentage_50, sizeof(pourcentage_50), "%T", "MenuMedic_POURCENTAGE_MENU_TITLE_50", client);
		AddMenuItem(menu, "M_pourcentage_50", pourcentage_50);
	}
	else
	{
		Format(pourcentage_50, sizeof(pourcentage_50), "%T", "MenuMedic_POURCENTAGE_MENU_TITLE_50", client);
		AddMenuItem(menu, "M_pourcentage_50", pourcentage_50, ITEMDRAW_DISABLED);	
	}
	
	Format(title, sizeof(title), "%T", "MenuMedic_TITLE", client, C_pourcentage[client]/10);
	menu.SetTitle(title);
	SetMenuExitBackButton(menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
}

/***********************************************************/
/*************** ZOMBIE RIOT MENU ACTIONS ******************/
/***********************************************************/
public int MenuMedicAction(Menu menu, MenuAction action, int param1, int param2)
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
			if(StrEqual(menu1, "M_pourcentage_10"))
			{
				C_pourcentage[param1] = 10;
			}
			else if(StrEqual(menu1, "M_pourcentage_20"))
			{
				C_pourcentage[param1] = 20;
			}
			else if(StrEqual(menu1, "M_pourcentage_30"))
			{
				C_pourcentage[param1] = 30;
			}
			else if(StrEqual(menu1, "M_pourcentage_40"))
			{
				C_pourcentage[param1] = 40;
			}
			else if(StrEqual(menu1, "M_pourcentage_50"))
			{
				C_pourcentage[param1] = 50;
			}
			
			if(IsClientAuthorized(param1))
			{
				Database db = Connect();
				if (db != null)
				{
					char steamId[64];
					GetClientAuthId(param1, AuthId_Steam2, steamId, sizeof(steamId));
					
					char strQuery[256];
					Format(strQuery, sizeof(strQuery), "SELECT pourcentage FROM medic_client_prefs WHERE auth = '%s'", steamId);
					SQL_TQuery(db, SQLQuery_POURCENTAGE, strQuery, GetClientUserId(param1), DBPrio_High);
				}
			}
			BuildMenuMedic(param1);		
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
	
	TopMenuObject menu = FindTopMenuCategory(hZombieRiotMenu, "menu_medic");
	
	if (menu == INVALID_TOPMENUOBJECT)
	{
		menu = AddToTopMenu(
		hZombieRiotMenu,			// Menu
		"menu_medic",				// Name
		TopMenuObject_Category,		// Type
		Handle_CategoryMenu,		// Callback
		INVALID_TOPMENUOBJECT		// Parent
		);
	}
	
	AddToTopMenu(hZombieRiotMenu, "sm_menu_medic_pourcentage", TopMenuObject_Item, Menu_MedicPourcentage, menu, "sm_menu_medic_pourcentage");
}

/***********************************************************/
/******************* HANDLE CATEGORY ***********************/
/***********************************************************/
public void Handle_CategoryMenu(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayTitle:
			Format(buffer, maxlength, "%T", "MenuZombieRiotMedic_TITLE", param);
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "%T", "MenuZombieRiotMedic_TITLE", param);
	}
}

/***********************************************************/
/**************** ON ADMIN MENU HUMANIFY *******************/
/***********************************************************/
public void Menu_MedicPourcentage(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "%T", "MenuMedic_POURCENTAGE_MENU_TITLE", param);
		case TopMenuAction_SelectOption:
		{
			BuildMenuMedic(param);
		}
	}
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
		Format(strQuery, sizeof(strQuery), "SELECT pourcentage FROM medic_client_prefs WHERE auth = '%s'", steamId);
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
		C_pourcentage[client] 			= SQL_FetchInt(hQuery, 0);
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
		Format(strQuery, sizeof(strQuery), "INSERT INTO medic_client_prefs (pourcentage, auth) VALUES (%i, '%s')", 10, steamId);
		SQL_TQuery(db, SQLQuery_Update, strQuery, _, DBPrio_High);
		
		SQL_LoadPrefClients(client);
	}
}

/***********************************************************/
/***************** SQL QUERY HUD PREFS *********************/
/***********************************************************/
public void SQLQuery_POURCENTAGE(Handle hOwner, Handle hQuery, const char[] strError, any data)
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
		Format(strQuery, sizeof(strQuery), "INSERT INTO medic_client_prefs (pourcentage, auth) VALUES (%i, '%s')", C_pourcentage[client], steamId);
		SQL_TQuery(db, SQLQuery_Update, strQuery, _, DBPrio_High);
	}
	else
	{
		char strQuery[256];
		Format(strQuery, sizeof(strQuery), "UPDATE medic_client_prefs SET pourcentage = '%i' WHERE auth = '%s'", C_pourcentage[client], steamId);
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
		"CREATE TABLE IF NOT EXISTS medic_client_prefs (id int(64) NOT NULL AUTO_INCREMENT, auth varchar(32) UNIQUE, pourcentage int(12) NOT NULL default 30, PRIMARY KEY (id)) ENGINE=InnoDB DEFAULT CHARSET=utf8;"
	};

	for (int i = 0; i < 1; i++)
	{
		if (!DoQuery(client, db, queries[i]))
		{
			return;
		}
	}

	ReplyToCommand(client, "%s Medic tables have been created.", TAG_CHAT);
}

/***********************************************************/
/******************** CREATE SQLITE ************************/
/***********************************************************/
void CreateSQLite(int client, Handle db)
{
	char queries[1][] = 
	{
		"CREATE TABLE IF NOT EXISTS medic_client_prefs (id int(64) NOT NULL AUTO_INCREMENT, auth varchar(32) UNIQUE, pourcentage int(12) NOT NULL default 30, PRIMARY KEY (id)) ENGINE=InnoDB DEFAULT CHARSET=utf8;"
	};

	for (int i = 0; i < 1; i++)
	{
		if (!DoQuery(client, db, queries[i]))
		{
			return;
		}
	}

	ReplyToCommand(client, "%s Medic tables have been created.", TAG_CHAT);
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
		data_medic_time[INT_TOTAL_DAY] 							= KvGetNum(kvDays, 		"medic_time", H_medic_timer);
		data_medic_kill[INT_TOTAL_DAY] 							= KvGetNum(kvDays, 		"medic_kill", H_medic_kill_zombie);
		
		//LogMessage("%s [DAY%i] - Time: %i, Kill: %i", TAG_CHAT, INT_TOTAL_DAY, data_medic_time[INT_TOTAL_DAY], data_medic_kill[INT_TOTAL_DAY]);
		
		INT_TOTAL_DAY++;
	} 
	while (KvGotoNextKey(kvDays));
}

/***********************************************************/
/******************** GET DAY MEDIC TIME *******************/
/***********************************************************/
int GetDayMedicTime(int day)
{
    return data_medic_time[day];
}

/***********************************************************/
/******************** GET DAY MEDIC TIME *******************/
/***********************************************************/
int GetDayMedicKill(int day)
{
    return data_medic_kill[day];
}

/***********************************************************/
/********************* LOAD FILE SETTING *******************/
/***********************************************************/
/*
public LoadSettings()
{
	new String:hc[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, hc, sizeof(hc), "configs/zombie_riot/medic/maps.cfg");
	
	Handle kv = CreateKeyValues("Maps");
	FileToKeyValues(kv, hc);
	
	new max_map = 0;
	
	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			if(KvGotoFirstSubKey(kv))
			{
				do
				{
					KvGetSectionName(kv, S_mapname[max_map], 64);
					LogMessage("%s Map: %s", TAG_CHAT, S_mapname[max_map]);
					
					KvGetString(kv, "kill", S_mapname_kill[max_map], 64);
					LogMessage("%s Kill: %s", TAG_CHAT, S_mapname_kill[max_map]);
					
					KvGetString(kv, "time", S_mapname_timer[max_map], 64);
					LogMessage("%s Timer: %s", TAG_CHAT, S_mapname_timer[max_map]);
					
					decl String:Mapname[64];
					GetCurrentMap(Mapname, sizeof(Mapname));
					
					if(strlen(S_mapname[max_map]) && StrEqual(Mapname, S_mapname[max_map], false))
					{
						H_current_map_kill = StringToInt(S_mapname_kill[max_map]);
						LogMessage("%s Current Map: %s, config find: %s, kill: %s", TAG_CHAT, Mapname, S_mapname[max_map], S_mapname_kill[max_map]);
						
						H_current_map_timer = StringToInt(S_mapname_timer[max_map]);
						LogMessage("%s Current Map: %s, config find: %s, timer: %s", TAG_CHAT, Mapname, S_mapname[max_map], S_mapname_timer[max_map]);
					}
					max_map++;
				}
				while (KvGotoNextKey(kv));
			}
			
			KvGoBack(kv);
			
		}
		while (KvGotoNextKey(kv));
	}
	CloseHandle(kv);
	
	if(H_current_map_kill == 0)
	{
		H_current_map_kill = H_medic_kill_zombie;
		LogMessage("%s No config found, kill zombie: %i", TAG_CHAT, H_current_map_kill);
		
	}
	
	if(H_current_map_timer == 0)
	{
		H_current_map_timer = H_medic_timer;
		LogMessage("%s No config found, timer: %i", TAG_CHAT, H_current_map_timer);
		
	}
}
*/


