/*   <DR.API ZOMBIE RIOT> (c) by <De Battista Clint - (http://doyou.watch)   */
/*                                                                           */
/*                 <DR.API ZOMBIE RIOT> is licensed under a                  */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//*****************************DR.API ZOMBIE RIOT****************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[ZOMBIE RIOT] -"

//***********************************//
//*************INCLUDE***************//
//***********************************//
#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <geoip>
#include <drapi_hpbar>

#include <stocks>
#pragma newdecls required
#include <zombie_riot/loader>




//Informations plugin
public Plugin myinfo = 
{
	name = "DR.API ZOMBIE RIOT", 
	author = "Dr. Api", 
	description = "DR.API ZOMBIE RIOT by Dr. Api, thanks to Greyscale for the base", 
	version = PLUGIN_VERSION, 
	url = "http://doyou.watch"
}

/***********************************************************/
/***************** BEFORE ON PLUGIN START ******************/
/***********************************************************/
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNatives();
	return APLRes_Success;
}

/***********************************************************/
/******************* ALL PLUGINS LOADED ********************/
/***********************************************************/
public void OnAllPluginsLoaded()
{
	CreateNativeMenu();
	
	Handle Airdrop = FindPluginByFile("drapi_airdrop.smx");
	if(Airdrop != INVALID_HANDLE) 
	{
		LogToZombieRiot(B_active_zombie_riot_dev, "%s drapi_airdrop.smx found", TAG_CHAT);
		
		if(GetPluginStatus(Airdrop) == Plugin_Running)
		{
			LogToZombieRiot(B_active_zombie_riot_dev, "%s drapi_airdrop.smx run", TAG_CHAT);
			PLUGIN_AIRDROP = true;
		}
		else
		{
			PLUGIN_AIRDROP = false;
		}
	}
	else
	{
		LogToZombieRiot(B_active_zombie_riot_dev, "%s drapi_airdrop.smx not found", TAG_CHAT);
		PLUGIN_AIRDROP = false;
	}
}

/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	AutoExecConfig_SetFile("drapi_zombie_riot", "sourcemod/drapi");
	
	LoadTranslations("drapi/drapi_zombie_riot_hud.phrases");
	LoadTranslations("drapi/drapi_zombie_riot_days.phrases");
	LoadTranslations("drapi/drapi_zombie_riot_menus.phrases");
	LoadTranslations("drapi/drapi_zombie_riot_chat.phrases");
	
	CreateForwards();
	CreateNativeCommandMenu();
	CreateCvars();
	CreateVarHumans(false, "PLUGIN START");
	CreateVarZombies(false, "PLUGIN START");
	
	CreateSQLCommands();
	CreateAdminsCommands();
	CreateCommands();
	CreateCommandsHelp();
	HookEvents();
	FindOffsets();
	ListeningTeamCommand();
	CreateHookMessages();
	
	FakeAndDownloadSound(true, data_sound, INT_TOTAL_DAY);
	
	trie_iDeaths 	= CreateTrie();
	trie_countDay 	= CreateTrie();
	Array_Map		= CreateArray(32);
	
	
	Handle topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
	
	SQL_LoadPrefAllClients();
	
	SDKHooksAll(true);
	AutoExecConfig_ExecuteFile();
	
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
}

/***********************************************************/
/************************ PLUGIN END ***********************/
/***********************************************************/
public void OnPluginEnd()
{
	if (B_active_zombie_riot)
	{
		ZombieRiotEND();
	}
}

/***********************************************************/
/**************** WHEN CLIENT PUT IN SERVER ****************/
/***********************************************************/
public void OnClientPutInServer(int client)
{
	if (B_active_zombie_riot)
	{
		SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
		
		CreateVarHumans(false, "PLAYER PUT IN SERVER");
		CreateVarZombies(false, "PLAYER PUT IN SERVER");
		SetPlayersNone("PLAYER PUT IN SERVER");
		
		bool fakeclient = IsFakeClient(client);
		InitClientDeathCount(client);
		InitClientDayCount(client);
	
		int deathcount = GetClientDeathCount(client);
		int deaths_before_zombie = GetDayDeathsBeforeZombie(INT_CURRENT_DAY);
		
		B_Force_Player_Is_Zombie[client] = !fakeclient?((deaths_before_zombie > 0) && (fakeclient || (deathcount >= deaths_before_zombie))):true;
		
		C_Target[client] = -1;
		INT_ZOMBIE_ID[client] = -1;
		RemoveTargeters(client);
		
		H_Timer_Respawn[client] = INVALID_HANDLE;
		
		if (B_Force_Player_Is_Zombie[client])
		{
			char S_human_name[32];
			GetClientName(client, S_human_name, sizeof(S_human_name));
			LogToZombieRiot(B_active_zombie_riot_dev, "%s Is Zombie: %s", TAG_CHAT, S_human_name);
		}
	}
}

/***********************************************************/
/************** WHEN CLIENT POST ADMIN CHECK ***************/
/***********************************************************/
public void OnClientPostAdminCheck(int client)
{
	SQL_LoadPrefClients(client);
	ShowMessage(client, true);
}

/***********************************************************/
/***************** WHEN CLIENT DISCONNECT ******************/
/***********************************************************/
public void OnClientDisconnect(int client)
{
	if(B_active_zombie_riot)
	{
		SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
		
		CreateVarHumans(false, "PLAYER DISCONNECT");
		CreateVarZombies(false, "PLAYER DISCONNECT");
		SetPlayersNone("PLAYER DISCONNECT");
		
		ChangeClientDayCount("PLAYER DISCONNECT", client, 1);
		
		if(INT_NB_HUMANS_PLAYER_IN_GAME <= 0 && H_Timer_HUD != INVALID_HANDLE)
		{
			CS_TerminateRound(5.0, CSRoundEnd_TerroristWin);
			
			INT_CURRENT_DAY = 0;
			UpdateHostname("%s - [%i/%i]", S_zombie_riot_hostname, INT_CURRENT_DAY + 1, INT_TOTAL_DAY);
			
			LogToZombieRiot(B_active_zombie_riot_dev, "Terro win: OnClientDisconnect", TAG_CHAT);
			PrintToDev(B_active_zombie_riot_dev, "Terro win: OnClientDisconnect", TAG_CHAT);
		}
		
		ShowMessage(client, false);
	}
}

/***********************************************************/
/******************* WHEN CONFIG EXECUTED ******************/
/***********************************************************/
public void OnConfigsExecuted()
{
	if(B_active_zombie_riot)
	{
		UpdateHostname("%s - [%i/%i]", S_zombie_riot_hostname, INT_CURRENT_DAY + 1, INT_TOTAL_DAY);
	}
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public void OnMapStart()
{
	MapChangeCleanup();
	
	ClearTrie(trie_iDeaths);
	ClearTrie(trie_countDay);
	
	LoadModelData("configs/drapi/zombie_riot/models", "txt");
	LoadZombieData("configs/drapi/zombie_riot/zombies", "cfg");
	LoadDayData("configs/drapi/zombie_riot/days", "cfg");
	
	H_Timer_HUD = INVALID_HANDLE;
	
	FakeAndDownloadSound(false, data_sound, INT_TOTAL_DAY);
	FakeAndDownloadSound(false, S_sound_death, 7);

	UpdateState();
} 