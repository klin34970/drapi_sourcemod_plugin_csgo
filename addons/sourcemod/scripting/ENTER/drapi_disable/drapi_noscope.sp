/*     <DR.API NO SCOPE> (c) by <De Battista Clint - (http://doyou.watch)    */
/*                                                                           */
/*                    <DR.API NO SCOPE> is licensed under a                  */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//******************************DR.API NO SCOPE******************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[NO SCOPE] -"
#define MENU_ACTIONS_ALL_EX				view_as<MenuAction>(0xFFFFFFFF)
#define	SNDCHAN_NOSCOPE					100

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <autoexec>
#include <emitsoundany>
#include <csgocolors>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_noscope_dev;
Handle cvar_noscope_timer_vote;
Handle cvar_noscope_timer_countdown;
Handle cvar_noscope_timer_end;
Handle cvar_noscope_menu_time;
Handle cvar_noscope_show_hint;

Handle H_Timer_RoundNoScope 								= INVALID_HANDLE;
Handle H_Timer_RoundNoScopeCountDown						= INVALID_HANDLE;
Handle H_Timer_RoundNoScopeStart							= INVALID_HANDLE;

//Bool
bool B_cvar_active_noscope_dev								= false;
bool B_noscope_show_hint									= false;

bool B_NoScope 												= false;

//Floats
float F_noscope_timer_vote;

//Strings  
char S_sound_noscope[4][]											= 	{	"noscope/countdown.mp3",
																			"noscope/vote_started.mp3",
																			"noscope/vote_success.mp3",
																			"noscope/vote_failed.mp3"
																		};
																  
//Customs
int C_noscope_timer_countdown;
int C_noscope_timer_end;
int C_noscope_menu_time;

int C_RoundNoScopeCountDown;
int C_RoundNoScopeTimer;
int C_HalfTime;

int m_flNextSecondaryAttack;
//Informations plugin
public Plugin myinfo =
{
	name = "DR.API NO SCOPE",
	author = "Dr. Api",
	description = "DR.API NO SCOPE by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://zombie4ever.eu"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	m_flNextSecondaryAttack = FindSendPropOffs("CBaseCombatWeapon", "m_flNextSecondaryAttack");
	
	LoadTranslations("drapi/drapi_noscope.phrases");
	AutoExecConfig_SetFile("drapi_noscope", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_noscope_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_noscope_dev			= AutoExecConfig_CreateConVar("drapi_active_noscope_dev", 			"0", 					"Enable/Disable Dev Mod", 							DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	cvar_noscope_timer_vote			= AutoExecConfig_CreateConVar("drapi_noscope_timer_vote", 			"600.0", 				"Show vote menu each 600s (10min)", 					DEFAULT_FLAGS);
	cvar_noscope_timer_countdown	= AutoExecConfig_CreateConVar("drapi_noscope_timer_countdown", 		"10", 					"Tchat and sounds advertissement before starting", 		DEFAULT_FLAGS);
	cvar_noscope_timer_end			= AutoExecConfig_CreateConVar("drapi_noscope_timer_end", 			"10", 					"Tchat and sounds advertissement before ending", 		DEFAULT_FLAGS);
	cvar_noscope_menu_time			= AutoExecConfig_CreateConVar("drapi_noscope_menu_time", 			"15", 					"How much time the menu vote should remaining", 		DEFAULT_FLAGS);
	cvar_noscope_show_hint			= AutoExecConfig_CreateConVar("drapi_noscope_show_hint", 			"1", 					"Reactive 'sm_vote_progress_hintbox' after the vote", 	DEFAULT_FLAGS, 	true, 0.0, 		true, 1.0);
	
	HookEvent("player_spawn", 	Event_PlayerSpawn);
	HookEvent("weapon_fire", 	Event_WeaponFire);
	
	HookEvents();
	
	AutoExecConfig_ExecuteFile();
	
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			SDKHook(i, SDKHook_WeaponSwitch, 	OnWeaponSwitch);
			SDKHook(i, SDKHook_WeaponEquipPost, OnPostWeaponEquip);
		}
		i++;
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
			SDKUnhook(i, SDKHook_WeaponSwitch, 		OnWeaponSwitch); 
			SDKUnhook(i, SDKHook_WeaponEquipPost, 	OnPostWeaponEquip);	
		}
		i++;
	}
	
	ClearTimer(H_Timer_RoundNoScope);
}

/***********************************************************/
/**************** WHEN CLIENT PUT IN SERVER ****************/
/***********************************************************/
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponSwitch, 		OnWeaponSwitch); 
	SDKHook(client, SDKHook_WeaponEquipPost, 	OnPostWeaponEquip);
}

/***********************************************************/
/***************** WHEN CLIENT DISCONNECT ******************/
/***********************************************************/
public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_WeaponSwitch, 	OnWeaponSwitch);
	SDKUnhook(client, SDKHook_WeaponEquipPost, 	OnPostWeaponEquip);
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEvents()
{
	HookConVarChange(cvar_active_noscope_dev, 				Event_CvarChange);
	
	HookConVarChange(cvar_noscope_timer_vote, 				Event_CvarChange);
	HookConVarChange(cvar_noscope_timer_countdown, 			Event_CvarChange);
	HookConVarChange(cvar_noscope_timer_end, 				Event_CvarChange);
	HookConVarChange(cvar_noscope_menu_time, 				Event_CvarChange);
	HookConVarChange(cvar_noscope_show_hint, 				Event_CvarChange);
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
	B_cvar_active_noscope_dev 					= GetConVarBool(cvar_active_noscope_dev);
	
	F_noscope_timer_vote 						= GetConVarFloat(cvar_noscope_timer_vote);
	C_noscope_timer_countdown 					= GetConVarInt(cvar_noscope_timer_countdown);
	C_noscope_timer_end 						= GetConVarInt(cvar_noscope_timer_end);
	C_noscope_menu_time 						= GetConVarInt(cvar_noscope_menu_time);
	B_noscope_show_hint 						= GetConVarBool(cvar_noscope_show_hint);
}

/***********************************************************/
/******************* WHEN CONFIG EXECUTED ******************/
/***********************************************************/
public void OnConfigsExecuted()
{
	H_Timer_RoundNoScope = CreateTimer(F_noscope_timer_vote, TimerRoundNoScope, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	B_NoScope = false;
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public void OnMapStart()
{
	FakeAndDownloadSound(true, S_sound_noscope, sizeof(S_sound_noscope));
	UpdateState();
}

/***********************************************************/
/******************** WHEN PLAYER SPAWN ********************/
/***********************************************************/
public void Event_PlayerSpawn(Handle event, char[] name, bool dontBroadcast)
{
	if(B_NoScope)
	{
		int client 					= GetClientOfUserId(GetEventInt(event, "userid"));
		
		if(Client_IsIngame(client) && IsPlayerAlive(client) && GetClientTeam(client) > 1)
		{
			SwitchWeapon(client, true, 9999.0, true, false);
		}
	}
}

/***********************************************************/
/******************** WHEN WEAPON FIRE *********************/
/***********************************************************/
public void Event_WeaponFire(Handle event, char[] name, bool dontBroadcast)
{
	int client 					= GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(B_NoScope)
	{
		// We need a timer otherwise not working
		CreateTimer(0.0, Timer_SwitchWeapon, GetClientUserId(client));
	}

}

/***********************************************************/
/****************** TIMER SWITCH WEAPON ********************/
/***********************************************************/
public Action Timer_SwitchWeapon(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	SwitchWeapon(client, false, 9999.0, false, false);
}

/***********************************************************/
/******************** ON WEAPON SWITCH *********************/
/***********************************************************/
public Action OnWeaponSwitch(int client, int weapon)
{	
	/*if(B_NoScope)
	{
		char classname[64];
		
		if (GetEdictClassname(weapon, classname, sizeof(classname)))
		{
			if(StrEqual(classname[7], "ssg08")  
			|| StrEqual(classname[7], "aug") 
			|| StrEqual(classname[7], "sg550")  
			|| StrEqual(classname[7], "sg552") 
			|| StrEqual(classname[7], "sg556") 
			|| StrEqual(classname[7], "awp") 
			|| StrEqual(classname[7], "scar20")  
			|| StrEqual(classname[7], "g3sg1"))
			{
				return Plugin_Continue;
			}
			else
			{	
				return Plugin_Handled;
			}
		}
		return Plugin_Handled;
	}
	else
	{
		return Plugin_Continue;
	}*/
	
	if(B_NoScope)
	{
		ClientCommand(client, "slot1");
	}
}

/***********************************************************/
/****************** ON WEAPON POST EQUIP *******************/
/***********************************************************/
public Action OnPostWeaponEquip(int client, int weapon)
{
	if(B_NoScope)
	{
		SwitchWeapon(client, false, 9999.0, false, false);
	}
	
	if(B_cvar_active_noscope_dev)
	{
		PrintToChatAll("%s OnPostWeaponEquip", TAG_CHAT);
	}
}

/***********************************************************/
/******************** ON WEAPON RELOAD *********************/
/***********************************************************/
public Action OnPostReload(int weapon)
{
	if(B_NoScope)
	{
		int client =  GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
		SwitchWeapon(client, false, 9999.0, false, false);
	}
	
	if(B_cvar_active_noscope_dev)
	{
		PrintToChatAll("%s OnPostReload", TAG_CHAT);
	}
}

/***********************************************************/
/********************* ON WEAPON DROP **********************/
/***********************************************************/
/* better than SDKHook_WeaponDrop for block drop */
public Action CS_OnCSWeaponDrop(int client, int weapon)
{
	if(B_NoScope)
	{
		char classname[64];
		
		if (GetEdictClassname(weapon, classname, sizeof(classname)))
		{
			if(StrEqual(classname[7], "ssg08")  
			|| StrEqual(classname[7], "aug") 
			|| StrEqual(classname[7], "sg550")  
			|| StrEqual(classname[7], "sg552") 
			|| StrEqual(classname[7], "sg556") 
			|| StrEqual(classname[7], "awp") 
			|| StrEqual(classname[7], "scar20")  
			|| StrEqual(classname[7], "g3sg1"))
			{			
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

/***********************************************************/
/************************ TIMER NOSCOPE ********************/
/***********************************************************/
public Action TimerRoundNoScope(Handle timer)
{
	if(!isWarmup() && !B_NoScope && !IsVoteInProgress())
	{
		NoScopeVoteMenu();
		PlaySoundNoscope(S_sound_noscope[1]);
		SetConVarInt(FindConVar("sm_vote_progress_hintbox"), 0, false, false);
		
		if(B_cvar_active_noscope_dev)
		{
			PrintToChatAll("%s Show vote, %f", TAG_CHAT, F_noscope_timer_vote);
		}
	}
}

/***********************************************************/
/********************* NOSCOPE VOTE MENU *******************/
/***********************************************************/
void NoScopeVoteMenu()
{
	if(IsVoteInProgress())
	{
		return;
	}
	
	Menu menu = CreateMenu(NoScopeVoteMenuAction, MENU_ACTIONS_ALL_EX);
	SetVoteResultCallback(menu, NoScopeVoteResults);
	
	menu.AddItem("120", "MenuNoScope_120_MENU_TITLE");
	
	menu.AddItem("240", "MenuNoScope_240_MENU_TITLE");
	
	menu.AddItem("360", "MenuNoScope_360_MENU_TITLE");
	
	menu.AddItem("never", "MenuNoScope_NEVER_MENU_TITLE");
	
	menu.SetTitle("MenuNoScope_TITLE");
	SetMenuExitBackButton(menu, false);
	
	int[] clients = new int[MaxClients];
	int total = 0;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i) && !IsFakeClient(i) && GetClientTeam(i) > 1)
		{
			clients[total++] = i;
		}
	}
	
	if(B_cvar_active_noscope_dev)
	{
		PrintToChatAll("%s Total: %i", TAG_CHAT, total);
	}
		
	if(!total || IsVoteInProgress())
	{
		return;
	}
	
	VoteMenu(menu, clients, total, C_noscope_menu_time);
	
	if(B_noscope_show_hint)
	{
		CreateTimer(float(C_noscope_menu_time) + 5.0, Timer_ResetCvar);
	}
}

/***********************************************************/
/********************** TIMER RESET CVAR *******************/
/***********************************************************/
public Action Timer_ResetCvar(Handle timer)
{
	SetConVarInt(FindConVar("sm_vote_progress_hintbox"), 1, false, false);
}

/***********************************************************/
/****************** NOSCOPE VOTE MENU ACTION ***************/
/***********************************************************/
public int NoScopeVoteMenuAction(Handle menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_VoteEnd)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_DisplayItem) 
	{
		char display[64];
		GetMenuItem(menu, param2, "", 0, _, display, sizeof(display));

		char buffer[255];
		Format(buffer, sizeof(buffer), "%T", display, param1);

		return RedrawMenuItem(buffer);	
	} 
	else if(action == MenuAction_Display) 
	{
		Handle panel = view_as<Handle>(param2);

		char num[64];
		GetMenuItem(menu, 0, num, sizeof(num));

		char buffer[255];
		Format(buffer, sizeof(buffer), "%T", "MenuNoScope_TITLE", param1, num);

		SetPanelTitle(panel, buffer);	
	}
	return 0;
}

/***********************************************************/
/***************** NOSCOPE VOTE MENU RESULTS ***************/
/***********************************************************/
public void NoScopeVoteResults(Handle menu, int num_votes, int num_clients, int[][] client_info, int num_items, int[][] item_info)
{
	int winner = 0;
	if (num_items > 1 && (item_info[0][VOTEINFO_ITEM_VOTES] == item_info[1][VOTEINFO_ITEM_VOTES]))
	{
		winner = GetRandomInt(0, 1);
	}

	char info[64];
	GetMenuItem(menu, item_info[winner][VOTEINFO_ITEM_INDEX], info, sizeof(info));
	
	if(StringToInt(info) > 0)
	{
		int time_decale = 5;
		C_RoundNoScopeCountDown = C_noscope_timer_countdown + time_decale;
		C_RoundNoScopeTimer 	= StringToInt(info);
		C_HalfTime				= StringToInt(info) / 2;
		
		H_Timer_RoundNoScopeCountDown = CreateTimer(1.0, Timer_RoundNoScopeCountDown, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
		/*vote success */
		char S_time_min[40], S_time_sec[40];
		FormatTime(S_time_min, sizeof(S_time_min), "%M", C_RoundNoScopeTimer);  
		FormatTime(S_time_sec, sizeof(S_time_sec), "%S", C_RoundNoScopeTimer);
		
		CPrintToChatAll("%t", "Vote Succes", S_time_min, S_time_sec);
		
		PlaySoundNoscope(S_sound_noscope[2]);
	}
	else
	{
		CPrintToChatAll("%t", "Vote Failed");
		PlaySoundNoscope(S_sound_noscope[3]);
	}
}

/***********************************************************/
/*********** TIMER NOSCOPE COUNT DOWN BEFORE START *********/
/***********************************************************/
public Action Timer_RoundNoScopeCountDown(Handle timer)
{
	C_RoundNoScopeCountDown--;
	
	if(C_RoundNoScopeCountDown > 0 && C_RoundNoScopeCountDown <= C_noscope_timer_countdown)
	{
		CPrintToChatAll("%t", "CountDownBeforeStart", C_RoundNoScopeCountDown);
	}
	else if(C_RoundNoScopeCountDown <= 0)
	{
		B_NoScope = true;
		H_Timer_RoundNoScopeStart = CreateTimer(1.0, Timer_RoundNoScopeStart, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		SwitchWeaponAll(true, 9999.0, true, false);
		
		char S_time_min[40], S_time_sec[40];
		FormatTime(S_time_min, sizeof(S_time_min), "%M", C_RoundNoScopeTimer);  
		FormatTime(S_time_sec, sizeof(S_time_sec), "%S", C_RoundNoScopeTimer); 
		
		CPrintToChatAll("%t", "Start", S_time_min, S_time_sec);
		
		ClearTimer(H_Timer_RoundNoScopeCountDown);
	}
	
	if(C_RoundNoScopeCountDown == C_noscope_timer_countdown)
	{
		PlaySoundNoscope(S_sound_noscope[0]);
	}
}

/***********************************************************/
/***************** TIMER NOSCOPE AFTER START ***************/
/***********************************************************/
public Action Timer_RoundNoScopeStart(Handle timer)
{
	C_RoundNoScopeTimer--;

	if(C_RoundNoScopeTimer > 0 && C_RoundNoScopeTimer <= C_noscope_timer_end)
	{
		if(B_cvar_active_noscope_dev)
		{
			CPrintToChatAll("%t", "CountDownBeforeEnd", C_RoundNoScopeTimer);
		}	
	}
	else if(C_RoundNoScopeTimer == RoundToFloor(float(C_HalfTime)))
	{
		char S_time_min[40], S_time_sec[40];
		FormatTime(S_time_min, sizeof(S_time_min), "%M", C_RoundNoScopeTimer);  
		FormatTime(S_time_sec, sizeof(S_time_sec), "%S", C_RoundNoScopeTimer); 
		
		CPrintToChatAll("%t", "CountDownHalf", S_time_min, S_time_sec);
	}
	else if(C_RoundNoScopeTimer <= 0)
	{	
		B_NoScope = false;
		SwitchWeaponAll(false, 0.0, false, true);
		
		CPrintToChatAll("%t", "End");
		
		ClearTimer(H_Timer_RoundNoScopeStart);
	}
}

/***********************************************************/
/******************** SWITCH WEAPON ALL*********************/
/***********************************************************/
void SwitchWeaponAll(bool switchex, float time, bool hook, bool unhook)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(Client_IsIngame(i) && IsPlayerAlive(i))
		{
			SwitchWeapon(i, switchex, time, hook, unhook);
		}
	}
}

/***********************************************************/
/********************** SWITCH WEAPON **********************/
/***********************************************************/
void SwitchWeapon(int client, bool switchex, float time, bool hook, bool unhook)
{
	int primary 	= GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);

	if(primary != -1)
	{
		char classname[64];
		
		if(GetEdictClassname(primary, classname, sizeof(classname)))
		{
			if(StrEqual(classname[7], "ssg08")  
			|| StrEqual(classname[7], "aug")
			|| StrEqual(classname[7], "sg550")  
			|| StrEqual(classname[7], "sg552")
			|| StrEqual(classname[7], "sg556")  
			|| StrEqual(classname[7], "awp")
			|| StrEqual(classname[7], "scar20") 
			|| StrEqual(classname[7], "g3sg1"))
			{	
				if(switchex)
				{
					ClientCommand(client, "slot1");
				}
				
				if(hook)
				{
					SDKHook(primary, SDKHook_ReloadPost, OnPostReload); 
				}
				else if(unhook)
				{
					SDKUnhook(primary, SDKHook_ReloadPost, OnPostReload); 
				}
				
				SetEntDataFloat(primary, m_flNextSecondaryAttack, GetGameTime() + time);
			}		
			
				
		}
	}
	else
	{
		int awp = GivePlayerItem(client, "weapon_awp");
		if(switchex)
		{
			ClientCommand(client, "slot1");
		}
		
		if(hook)
		{
			SDKHook(awp, SDKHook_ReloadPost, OnPostReload);
		}
		else if(unhook)
		{
			SDKUnhook(awp, SDKHook_ReloadPost, OnPostReload);
		}	
		
		SetEntDataFloat(awp, m_flNextSecondaryAttack, GetGameTime() + time);
	}
}

/***********************************************************/
/******************** PLAY NOSCOPE SOUND *******************/
/***********************************************************/
void PlaySoundNoscope(char[] sound)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			EmitSoundToClientAny(i, sound, i, SNDCHAN_NOSCOPE, _, _, 0.7, _);
		}
	}
}

/***********************************************************/
/********************* IS VALID CLIENT *********************/
/***********************************************************/
stock bool Client_IsValid(int client, bool checkConnected=true)
{
	if (client > 4096) {
		client = EntRefToEntIndex(client);
	}

	if (client < 1 || client > MaxClients) {
		return false;
	}

	if (checkConnected && !IsClientConnected(client)) {
		return false;
	}
	
	return true;
}

/***********************************************************/
/******************** IS CLIENT IN GAME ********************/
/***********************************************************/
stock bool Client_IsIngame(int client)
{
	if (!Client_IsValid(client, false)) {
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

/***********************************************************/
/******************** ADD SOUND TO CACHE *******************/
/***********************************************************/
stock void FakePrecacheSound(const char[] szPath)
{
	AddToStringTable( FindStringTable( "soundprecache" ), szPath );
}

/***********************************************************/
/****************** FAKE AND DOWNLOAD SOUND ****************/
/***********************************************************/
stock void FakeAndDownloadSound(bool log, const char[][] stocksound, int num)
{
	for (int i = 0; i < num; i++)
	{
		char FULL_SOUND_PATH[PLATFORM_MAX_PATH];
		Format(FULL_SOUND_PATH, PLATFORM_MAX_PATH, "sound/%s", stocksound[i]);
		AddFileToDownloadsTable(FULL_SOUND_PATH);
		
		char RELATIVE_SOUND_PATH[PLATFORM_MAX_PATH];
		Format(RELATIVE_SOUND_PATH, PLATFORM_MAX_PATH, "*%s", stocksound[i]);
		FakePrecacheSound(RELATIVE_SOUND_PATH);
		
		if(log)
		{
			LogMessage("AddFileToDownloadsTable: %s, FakePrecacheSound: %s", FULL_SOUND_PATH, RELATIVE_SOUND_PATH);
		}
	}
}