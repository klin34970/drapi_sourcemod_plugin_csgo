/*   <DR.API GIFTS EVENTS> (c) by <De Battista Clint - (http://doyou.watch)  */
/*                                                                           */
/*                  <DR.API GIFTS EVENTS> is licensed under a                */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//****************************DR.API GIFTS EVENTS****************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[GIFTS EVENTS] -"
#define MAX_GIFTS						1000
#define SND_GIFTS						103

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools>
#include <autoexec>
#include <emitsoundany>
#include <csgocolors>
#include <store>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_gifts_events_dev;

Handle cvar_gifts_events_timer_check;
Handle cvar_gifts_events_timer_give_min;
Handle cvar_gifts_events_timer_give_max;

Handle cvar_gifts_events_vip_gifts_reset;
Handle cvar_gifts_events_nonvip_gifts_reset;

Handle Array_GiftsVip;
Handle Array_GiftsOthers;
Handle Array_GiftsWinners;
Handle H_TimerGifts;

//Bool
bool B_active_gifts_events_dev					= false;

//Floats
float F_gifts_events_timer_check;
float F_gifts_events_timer_give_min;
float F_gifts_events_timer_give_max;

float F_TimerGiveGifts;

//Strings
char S_giftseventsvip[MAX_GIFTS][PLATFORM_MAX_PATH];
char S_giftseventsothers[MAX_GIFTS][PLATFORM_MAX_PATH];

char S_Sounds[3][PLATFORM_MAX_PATH] 			= {
													"gifts_events/gifts_win.mp3",
													"gifts_events/gifts_end.mp3",
													"gifts_events/gifts_start.mp3"
												};
												
char S_date_start[40];
char S_last_log[PLATFORM_MAX_PATH];

//Customs
int C_gifts_events_vip_gifts_reset;
int C_gifts_events_nonvip_gifts_reset;

int C_RepeatWin[MAXPLAYERS + 1];

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API GIFTS EVENTS",
	author = "Dr. Api",
	description = "DR.API GIFTS EVENTS by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://zombie4ever.eu"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	LoadTranslations("drapi/drapi_gifts_events.phrases");
	AutoExecConfig_SetFile("drapi_gifts_events", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_gifts_events_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_gifts_events_dev			= AutoExecConfig_CreateConVar("drapi_active_gifts_events_dev", 			"0", 					"Enable/Disable Dev Mod", 						DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	cvar_gifts_events_timer_check			= AutoExecConfig_CreateConVar("drapi_gifts_events_timer_check", 		"60.0", 				"Timer repeat to check when to give gifts", 	DEFAULT_FLAGS);
	cvar_gifts_events_timer_give_min		= AutoExecConfig_CreateConVar("drapi_gifts_events_timer_give_min", 		"900.0", 				"Min. time to give gifts", 						DEFAULT_FLAGS);
	cvar_gifts_events_timer_give_max		= AutoExecConfig_CreateConVar("drapi_gifts_events_timer_give_max", 		"2400.0", 				"Max. time to give gifts", 						DEFAULT_FLAGS);
	
	cvar_gifts_events_vip_gifts_reset		= AutoExecConfig_CreateConVar("drapi_gifts_events_vip_gifts_reset", 	"4", 					"VIP cannot win 4 times in a row", 				DEFAULT_FLAGS);
	cvar_gifts_events_nonvip_gifts_reset	= AutoExecConfig_CreateConVar("drapi_gifts_events_nonvip_gifts_reset", 	"1", 					"VIP cannot win 1 time in a row", 				DEFAULT_FLAGS);
	
	HookEvents();
	
	AutoExecConfig_ExecuteFile();
	
	RegAdminCmd("sm_gifts",			Command_Gifts, 				ADMFLAG_CHANGEMAP, "");
	RegAdminCmd("sm_sgifts",		Command_StopGifts, 			ADMFLAG_CHANGEMAP, "");
	RegAdminCmd("sm_creditsall",	Command_GiveCredits, 		ADMFLAG_CHANGEMAP, "");
	
	RegConsoleCmd("sm_winners", 	Command_Winners, "");
	RegConsoleCmd("sm_myprizes", 	Command_MyPrizes, "");
	
	char logspath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, logspath, sizeof(logspath), "logs/gifts");
	if(!DirExists(logspath))
	{
		CreateDirectory(logspath, 511);
	}
	
	char backuppath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, backuppath, sizeof(backuppath), "logs/gifts/backup");
	if(!DirExists(backuppath))
	{
		CreateDirectory(backuppath, 511);
	}
	
	char winnersppath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, winnersppath, sizeof(winnersppath), "logs/gifts/winners");
	if(!DirExists(winnersppath))
	{
		CreateDirectory(winnersppath, 511);
	}
}

/***********************************************************/
/************************ PLUGIN END ***********************/
/***********************************************************/
public void OnPluginEnd()
{
	if(Array_GiftsVip == INVALID_HANDLE && Array_GiftsOthers == INVALID_HANDLE)
	{
		PrintWinnersLogs();
		ClearTimer(H_TimerGifts);
		CreateTimer(5.0, Timer_EndGifts);
	}
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEvents()
{
	HookConVarChange(cvar_active_gifts_events_dev, 				Event_CvarChange);
	
	HookConVarChange(cvar_gifts_events_timer_check, 			Event_CvarChange);
	HookConVarChange(cvar_gifts_events_timer_give_min, 			Event_CvarChange);
	HookConVarChange(cvar_gifts_events_timer_give_max, 			Event_CvarChange);
	
	HookConVarChange(cvar_gifts_events_vip_gifts_reset, 		Event_CvarChange);
	HookConVarChange(cvar_gifts_events_nonvip_gifts_reset, 		Event_CvarChange);
	
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
	B_active_gifts_events_dev 				= GetConVarBool(cvar_active_gifts_events_dev);
	
	F_gifts_events_timer_check 				= GetConVarFloat(cvar_gifts_events_timer_check);
	F_gifts_events_timer_give_min 			= GetConVarFloat(cvar_gifts_events_timer_give_min);
	F_gifts_events_timer_give_max 			= GetConVarFloat(cvar_gifts_events_timer_give_max);
	
	C_gifts_events_vip_gifts_reset 			= GetConVarInt(cvar_gifts_events_vip_gifts_reset);
	C_gifts_events_nonvip_gifts_reset 		= GetConVarInt(cvar_gifts_events_nonvip_gifts_reset);
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public void OnMapStart()
{
	FakeAndDownloadSound(true, S_Sounds, sizeof(S_Sounds));
	UpdateState();
}

/***********************************************************/
/********************** CMD PRIZES *************************/
/***********************************************************/
public Action Command_GiveCredits(int client, int args)
{
	if(args == 1)
	{
		char sTemp[64];
		GetCmdArg(1, sTemp, sizeof(sTemp));
		GiveCreditsAll(StringToInt(sTemp), "GiveCredits");
	}
}

/***********************************************************/
/********************** CMD PRIZES *************************/
/***********************************************************/
public Action Command_MyPrizes(int client, int args)
{
	PrintPrizes(client);
}

/***********************************************************/
/*********************** CMD WINNER *************************/
/***********************************************************/
public Action Command_Winners(int client, int args)
{
	PrintWinners(client);
}

public Action Command_Gifts(int client, int args)
{
	BuildMenuGifts(client);
}

/***********************************************************/
/**************** BUILD ZOMBIE RIOT MENU *******************/
/***********************************************************/
void BuildMenuGifts(int client)
{
	char title[40]; 
	char newgifts[40];
	char backupgifts[40];
	Menu menu = CreateMenu(MenuGiftsAction);
	
	Format(newgifts, sizeof(newgifts), "%T", "MenuGifts_NEW_MENU_TITLE", client);
	AddMenuItem(menu, "M_newgifts", newgifts);
	
	Format(backupgifts, sizeof(backupgifts), "%T", "MenuGifts_BACKUP_MENU_TITLE", client);
	AddMenuItem(menu, "M_backupgifts", backupgifts);
	
	
	
	Format(title, sizeof(title), "%T", "MenuGifts_TITLE", client);
	menu.SetTitle(title);
	SetMenuExitBackButton(menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
}

/***********************************************************/
/*************** ZOMBIE RIOT MENU ACTIONS ******************/
/***********************************************************/
public int MenuGiftsAction(Menu menu, MenuAction action, int param1, int param2)
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
			
			}		
		}
		case MenuAction_Select:
		{
			char menu1[56];
			menu.GetItem(param2, menu1, sizeof(menu1));
			
			if(StrEqual(menu1, "M_newgifts"))
			{
				LoadGifts(false);
			}
			else if(StrEqual(menu1, "M_backupgifts"))
			{
				LoadGifts(true);
			}
		}
	}
}
/***********************************************************/
/********************** LOAD GIFTS *************************/
/***********************************************************/
void LoadGifts(bool backup)
{
	FormatTime(S_date_start, sizeof(S_date_start), "%F", GetTime());
	
	if(Array_GiftsVip != INVALID_HANDLE)
	{
		CloseHandle(Array_GiftsVip);
		Array_GiftsVip = INVALID_HANDLE;
	}
	
	if(Array_GiftsOthers != INVALID_HANDLE)
	{
		CloseHandle(Array_GiftsOthers);
		Array_GiftsOthers = INVALID_HANDLE;
	}
	
	if(Array_GiftsWinners != INVALID_HANDLE)
	{
		CloseHandle(Array_GiftsWinners);
		Array_GiftsWinners = INVALID_HANDLE;
	}
	
	Array_GiftsVip		= CreateArray(PLATFORM_MAX_PATH / 2);
	Array_GiftsOthers	= CreateArray(PLATFORM_MAX_PATH / 2);
	Array_GiftsWinners	= CreateArray(PLATFORM_MAX_PATH);
	
	LoadSettings();
	
	if(backup)
	{
		LoadBackup();
	}

	ClearTimer(H_TimerGifts);
	H_TimerGifts = CreateTimer(F_gifts_events_timer_check, Timer_Gifts,_, TIMER_REPEAT);
	
	char S_time_min[40], S_time_sec[40];
	FormatTime(S_time_min, sizeof(S_time_min), "%M", RoundToFloor(F_gifts_events_timer_check));  
	FormatTime(S_time_sec, sizeof(S_time_sec), "%S", RoundToFloor(F_gifts_events_timer_check));
		
	CPrintToChatAll("%t", "Begin Event");
	CPrintToChatAll("%t", "Begin Event First Gifts", S_time_min, S_time_sec);
	PrintHintTextToAll("%t", "Begin Event Hint");
	
	PlaySound(S_Sounds[2], SOUND_FROM_PLAYER, 1.0, _, SND_NOFLAGS);
	
	if(Array_GiftsVip != INVALID_HANDLE)
	{
		CPrintToChatAll("%t", "VIP Gifts", GetArraySize(Array_GiftsVip));
	}
	
	if(Array_GiftsOthers != INVALID_HANDLE)
	{
		CPrintToChatAll("%t", "NO-VIP Gifts", GetArraySize(Array_GiftsOthers));
	}
	
	if(!backup)
	{
		GetFiles("logs/gifts", 				true, "logs/gifts/backup/drapi_backup_gifts_events");
		GetFiles("logs/gifts/winners", 		true, "logs/gifts/backup/drapi_backup_winners_events");
	}
}

/***********************************************************/
/********************* LOAD BACKUP *************************/
/***********************************************************/
void LoadBackup()
{
	GetFiles("logs/gifts", false);
	
	Handle file = OpenFile(S_last_log, "r");
	if (file == INVALID_HANDLE) return;
	
	char buffer[256];
	char parts[2][PLATFORM_MAX_PATH], info[5][64], S_line[MAX_GIFTS][PLATFORM_MAX_PATH], S_info_array_vip[PLATFORM_MAX_PATH], S_info_array_nonvip[PLATFORM_MAX_PATH];
	
	int count = 0;
	while(!IsEndOfFile(file) && ReadFileLine(file, buffer, sizeof(buffer)))
	{
		ExplodeString(buffer, "[WINNER] - ", parts, 2, PLATFORM_MAX_PATH);
		
		
		strcopy(S_line[count], PLATFORM_MAX_PATH, parts[1]);
		count++;
	}
	
	CloseHandle(file);
	
	for(int line = 0; line < count; line++)
	{
		ExplodeString(S_line[line], " | ", info, 5, 64);
		
		if(Array_GiftsVip != INVALID_HANDLE)
		{
			int arrayGiftsVip 		= GetArraySize(Array_GiftsVip);

			if(arrayGiftsVip)
			{
				for(int i = 0; i < arrayGiftsVip; i++)
				{
					GetArrayString(Array_GiftsVip, i, S_info_array_vip, sizeof(S_info_array_vip));
					
					char S_fusion[2][64];
					ExplodeString(S_info_array_vip, " | ", S_fusion, 2, 64);
					
					if(StrEqual(S_fusion[0], info[3]))
					{
						if(Array_GiftsWinners != INVALID_HANDLE)
						{
							char S_injectinfo[PLATFORM_MAX_PATH];
							Format(S_injectinfo, sizeof(S_injectinfo), "%s; %s; %s; %s | %s", info[0], info[1], info[2], info[3], info[4]);
							
							LogMessage("[%i]: %s | %s | %s | %s | %s", count, info[0], info[1], info[2], info[3], info[4]);
							PushArrayString(Array_GiftsWinners, S_injectinfo);
						}
						RemoveFromArray(Array_GiftsVip, i);
						break;
					}
				}
			}
		}	
	}
			
		
	for(int line = 0; line < count; line++)
	{
		ExplodeString(S_line[line], " | ", info, 5, 64);
		
		if(Array_GiftsOthers != INVALID_HANDLE)
		{
			int arrayGiftsOthers 		= GetArraySize(Array_GiftsOthers);

			if(arrayGiftsOthers)
			{
				for(int i = 0; i < arrayGiftsOthers; i++)
				{
					GetArrayString(Array_GiftsOthers, i, S_info_array_nonvip, sizeof(S_info_array_nonvip));
					
					char S_fusion[2][64];
					ExplodeString(S_info_array_nonvip, " | ", S_fusion, 2, 64);
					
					if(StrEqual(S_fusion[0], info[3]))
					{
						if(Array_GiftsWinners != INVALID_HANDLE)
						{
							char S_injectinfo[PLATFORM_MAX_PATH];
							Format(S_injectinfo, sizeof(S_injectinfo), "%s; %s; %s; %s | %s", info[0], info[1], info[2], info[3], info[4]);
							
							LogMessage("[%i]: %s | %s | %s | %s | %s", count, info[0], info[1], info[2], info[3], info[4]);
							PushArrayString(Array_GiftsWinners, S_injectinfo);
						}
						RemoveFromArray(Array_GiftsOthers, i);
						break;
					}
				}
			}
		}	
	}
}

/***********************************************************/
/*********************** CMD GIFTS *************************/
/***********************************************************/
public Action Command_StopGifts(int client, int args)
{
	if(Array_GiftsVip != INVALID_HANDLE)
	{
		CloseHandle(Array_GiftsVip);
		Array_GiftsVip = INVALID_HANDLE;
	}
	
	if(Array_GiftsOthers != INVALID_HANDLE)
	{
		CloseHandle(Array_GiftsOthers);
		Array_GiftsOthers = INVALID_HANDLE;
	}

	PrintWinnersLogs();
	ClearTimer(H_TimerGifts);
	CreateTimer(5.0, Timer_EndGifts);
		
	/*	
	if(Array_GiftsWinners != INVALID_HANDLE)
	{
		CloseHandle(Array_GiftsWinners);
		Array_GiftsWinners = INVALID_HANDLE;
	}
	*/
}

/***********************************************************/
/********************** TIMER GIFTS ************************/
/***********************************************************/
public Action Timer_Gifts(Handle timer)
{
	float now = GetEngineTime();
	if(now >= F_TimerGiveGifts)
	{
		if(isWarmup())
		{
			F_TimerGiveGifts = now + GetConVarFloat(FindConVar("mp_warmuptime"));
			
			char S_time_min[40], S_time_sec[40];
			FormatTime(S_time_min, sizeof(S_time_min), "%M", RoundToFloor(F_TimerGiveGifts - now));  
			FormatTime(S_time_sec, sizeof(S_time_sec), "%S", RoundToFloor(F_TimerGiveGifts - now));
			
			CPrintToChatAll("%t", "Next Gifts Warmup", S_time_min, S_time_sec);
			return;
		}
		else
		{
			F_TimerGiveGifts = now + GetRandomFloat(F_gifts_events_timer_give_min, F_gifts_events_timer_give_max);
		}
		
		int vip = 0;
		if(Array_GiftsVip != INVALID_HANDLE)
		{
			vip					= GetRandomPlayerVip();
			if(vip > 0)
			{
				GiveGiftsVip(vip);
			}
		}
		
		int player = 0;
		if(Array_GiftsOthers != INVALID_HANDLE)
		{
			player				= GetRandomPlayer();
			if(player > 0)
			{
				GiveGiftsOthers(player);
			}
		}
		
		char S_time_min[40], S_time_sec[40];
		FormatTime(S_time_min, sizeof(S_time_min), "%M", RoundToFloor(F_TimerGiveGifts - now));  
		FormatTime(S_time_sec, sizeof(S_time_sec), "%S", RoundToFloor(F_TimerGiveGifts - now));
	
		if( 
			(vip > 0 && Array_GiftsVip != INVALID_HANDLE && GetArraySize(Array_GiftsVip)) 
			&& 
			(player > 0 && Array_GiftsOthers != INVALID_HANDLE && GetArraySize(Array_GiftsOthers)) 
		)
		{
			CPrintToChatAdmin("Next Gifts NVIP", S_time_min, S_time_sec);
			PlaySound(S_Sounds[0], SOUND_FROM_PLAYER, 1.0, _, SND_NOFLAGS);
		}
		else if( 
			(vip <= 0 || Array_GiftsVip == INVALID_HANDLE || !GetArraySize(Array_GiftsVip)) 
			&& 
			(player > 0 && Array_GiftsOthers != INVALID_HANDLE && GetArraySize(Array_GiftsOthers))
		)
		{
			CPrintToChatAdmin("Next Gifts N", S_time_min, S_time_sec);
			PlaySound(S_Sounds[0], SOUND_FROM_PLAYER, 1.0, _, SND_NOFLAGS);
		}
		else if(
			(vip > 0 && Array_GiftsVip != INVALID_HANDLE && GetArraySize(Array_GiftsVip)) 
			&& 
			(player <= 0 || Array_GiftsOthers == INVALID_HANDLE || !GetArraySize(Array_GiftsOthers))
		)
		{
			CPrintToChatAdmin("Next Gifts VIP", S_time_min, S_time_sec);
			PlaySound(S_Sounds[0], SOUND_FROM_PLAYER, 1.0, _, SND_NOFLAGS);
		}
	}
	
	if(Array_GiftsVip == INVALID_HANDLE && Array_GiftsOthers == INVALID_HANDLE)
	{
		PrintWinnersLogs();
		ClearTimer(H_TimerGifts);
		CreateTimer(5.0, Timer_EndGifts);
	}
}

/***********************************************************/
/****************** TIMER END GIVE AWAYS *******************/
/***********************************************************/
public Action Timer_EndGifts(Handle timer)
{
	CPrintToChatAll("%t", "End Event");
	PrintHintTextToAll("%t", "End Event Hint");
	
	PlaySound(S_Sounds[1], SOUND_FROM_PLAYER, 1.0, _, SND_NOFLAGS);
}

/***********************************************************/
/********************* GIVE GIFTS VIP **********************/
/***********************************************************/
void GiveGiftsVip(int vip)
{
	if(Array_GiftsVip != INVALID_HANDLE)
	{
		int arrayGiftsVip 		= GetArraySize(Array_GiftsVip);

		if(arrayGiftsVip)
		{
			for(int i = 0; i < arrayGiftsVip; i++)
			{
				int gift = GetRandomInt(0, arrayGiftsVip - 1);
				char S_gift[64];
				GetArrayString(Array_GiftsVip, gift, S_gift, sizeof(S_gift));
				
				AddWinner("VIP", vip, S_gift);
				
				RemoveFromArray(Array_GiftsVip, gift);
				ShowTheWinner("VIP", vip, S_gift);
				
				if(!GetArraySize(Array_GiftsVip))
				{
					ClearArray(Array_GiftsVip);
					if(Array_GiftsVip != INVALID_HANDLE)
					{
						CloseHandle(Array_GiftsVip);
						Array_GiftsVip = INVALID_HANDLE;
						CPrintToChatAll("%t", "No VIP Gifts");
						return;
					}
				}
				return;
			}
		}
	}
}

/***********************************************************/
/******************* GIVE GIFTS OTHERS *********************/
/***********************************************************/
void GiveGiftsOthers(int player)
{
	if(Array_GiftsOthers != INVALID_HANDLE)
	{
		int arrayGiftsOthers 	= GetArraySize(Array_GiftsOthers);

		if(arrayGiftsOthers)
		{
			for(int i = 0; i < arrayGiftsOthers; i++)
			{
				int gift = GetRandomInt(0, arrayGiftsOthers - 1);
				char S_gift[64];
				GetArrayString(Array_GiftsOthers, gift, S_gift, sizeof(S_gift));
				
				AddWinner("NON-VIP", player, S_gift);
				
				RemoveFromArray(Array_GiftsOthers, gift);
				ShowTheWinner("NON-VIP", player, S_gift);
				
				if(!GetArraySize(Array_GiftsOthers))
				{
					ClearArray(Array_GiftsOthers);
					if(Array_GiftsOthers != INVALID_HANDLE)
					{
						CloseHandle(Array_GiftsOthers);
						Array_GiftsOthers = INVALID_HANDLE;
						CPrintToChatAll("%t", "No NON-VIP Gifts");
						return;
					}
				}
				return;				
			}	
		}
	}
}


/***********************************************************/
/******************* GIVE GIFTS OTHERS *********************/
/***********************************************************/
bool CheckWinner(int client)
{
	if(Array_GiftsWinners != INVALID_HANDLE)
	{
		int arrayGiftsWinners 	= GetArraySize(Array_GiftsWinners);

		if(arrayGiftsWinners)
		{
			char steamId[64], info[PLATFORM_MAX_PATH];
			GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
	
			for(int i = 0; i < arrayGiftsWinners; i++)
			{
				GetArrayString(Array_GiftsWinners, i, info, sizeof(info)); 
				
				char explode[4][64];
				ExplodeString(info, "; ", explode, 4, 64, true);
				
				if(StrEqual(explode[2], steamId, false))
				{
					return true;
				}
			}	
		}
	}
	return false;
}

/***********************************************************/
/******************** SHOW THE WINNER **********************/
/***********************************************************/
void ShowTheWinner(char[] vip, int winner, char[] gift)
{
	char sCodeLang[3], sNameLang[3];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i))
		{
			int idLang = GetClientLanguage(i);
			GetLanguageInfo(idLang, sCodeLang, sizeof(sCodeLang), sNameLang, sizeof(sNameLang));
			
			char explode[2][64], S_gift[64];
			ExplodeString(gift, " | ", explode, 2, 64, true);
			
			if(StrEqual(sCodeLang, "fr", false))
			{
				strcopy(S_gift, sizeof(S_gift), explode[0]);
			}
			else
			{
				strcopy(S_gift, sizeof(S_gift), explode[1]);
			}
			
			CPrintToChat(i, "%t", "Winner", winner, S_gift);
			//PrintHintText(i, "%t", "Winner Hint", winner, S_gift);
		}
	}
	
	char steamId[64];
	GetClientAuthId(winner, AuthId_Steam2, steamId, sizeof(steamId));
	
	char S_log[PLATFORM_MAX_PATH];
	Format(S_log, sizeof(S_log), "logs/gifts/drapi_gifts_events-%s.txt", S_date_start);
	
	LogToGiftsEvents(S_log, true, "[WINNER] - %N | %s | %s | %s", winner, vip, steamId, gift);
}

/***********************************************************/
/********************* PRINT WINNERS ***********************/
/***********************************************************/
void PrintWinnersLogs()
{
	if(Array_GiftsWinners != INVALID_HANDLE)
	{
		char S_log[PLATFORM_MAX_PATH];
		int arrayGiftsWinners 		= GetArraySize(Array_GiftsWinners);

		char S_date_head[40];
		FormatTime(S_date_head, sizeof(S_date_head), "%c", GetTime()); 
		Format(S_log, sizeof(S_log), "logs/gifts/winners/drapi_gifts_winner-%s.txt", S_date_start);
			
		LogToGiftsEvents(S_log, true, "--------------------%s--------------------", S_date_head);
		
		for(int i = 0; i < arrayGiftsWinners; i++)
		{
			char S_info[PLATFORM_MAX_PATH];
			GetArrayString(Array_GiftsWinners, i, S_info, sizeof(S_info));
			
			char info_explode[4][PLATFORM_MAX_PATH];
			ExplodeString(S_info, "; ", info_explode, 4, PLATFORM_MAX_PATH, true);

			LogToGiftsEvents(S_log, true, "[WINNER] - %s | %s | %s | %s", info_explode[0], info_explode[1], info_explode[2], info_explode[3]);
		}
		
		LogToGiftsEvents(S_log, true, "----------------------------------------------------------------");
		LogToGiftsEvents(S_log, true, "----------------------------------------------------------------");
		
	}
}

/***********************************************************/
/********************* PRINT WINNERS ***********************/
/***********************************************************/
void PrintWinners(int client)
{
	if(Array_GiftsWinners != INVALID_HANDLE)
	{
		char sCodeLang[3], sNameLang[3], S_info[PLATFORM_MAX_PATH], NoWinner[40], S_panel_title[64];
		int arrayGiftsWinners 		= GetArraySize(Array_GiftsWinners);


		int idLang  = GetClientLanguage(client);
		
		GetLanguageInfo(idLang, sCodeLang, sizeof(sCodeLang), sNameLang, sizeof(sNameLang));
	
	
		Menu PrintWinnersMenu = CreateMenu(PrintWinnersMenuAction);
		Format(S_panel_title, sizeof(S_panel_title), "%T", "Panel Title Winners", client, arrayGiftsWinners, S_date_start);
		SetMenuTitle(PrintWinnersMenu, S_panel_title);
		
		if(arrayGiftsWinners)
		{
			for(int i = 0; i < arrayGiftsWinners; i++)
			{
				GetArrayString(Array_GiftsWinners, i, S_info, sizeof(S_info));
				
				char info_explode[4][PLATFORM_MAX_PATH];
				ExplodeString(S_info, "; ", info_explode, 4, PLATFORM_MAX_PATH, true);
				
				char gift_explode[2][64];
				ExplodeString(info_explode[3], " | ", gift_explode, 2, 64, true);
				
				char S_gift[64];
				if(StrEqual(sCodeLang, "fr", false))
				{
					strcopy(S_gift, sizeof(S_gift), gift_explode[0]);
				}
				else
				{
					strcopy(S_gift, sizeof(S_gift), gift_explode[1]);
				}
				
				char S_panel_info[128];
				Format(S_panel_info, sizeof(S_panel_info), "%s: %s", info_explode[0], S_gift);
				AddMenuItem(PrintWinnersMenu, "", S_panel_info, ITEMDRAW_DISABLED);
			}	
		}
		else
		{
			Format(NoWinner, sizeof(NoWinner), "%T", "NoWinner", client);
			AddMenuItem(PrintWinnersMenu, "", NoWinner, ITEMDRAW_DISABLED);
		}
		
		SetMenuExitBackButton(PrintWinnersMenu, true);
		DisplayMenu(PrintWinnersMenu, client, MENU_TIME_FOREVER);
	}
}

/***********************************************************/
/******************* ACTION PRIZES WIN *********************/
/***********************************************************/
public int PrintWinnersMenuAction(Handle menu, MenuAction action, int param1, int param2) 
{
	if(action == MenuAction_End) 
	{
		CloseHandle(menu);
	} 
	else if(menu == INVALID_HANDLE && action == MenuAction_Select && param2 == 8)
	{
		PrintWinners(param1);
	} 
	else if(action == MenuAction_Cancel) 
	{
		if (param2 == MenuCancel_ExitBack)
		{
			PrintWinners(param1);
		}
	}
}

/***********************************************************/
/******************* PRINT PRIZES WIN **********************/
/***********************************************************/
void PrintPrizes(int client)
{
	if(Array_GiftsWinners != INVALID_HANDLE)
	{
		char sCodeLang[3], sNameLang[3], steamId[64], S_info[PLATFORM_MAX_PATH], NoGift[40], S_panel_title[64];
		int arrayGiftsWinners 		= GetArraySize(Array_GiftsWinners);


		int idLang  = GetClientLanguage(client);
		
		GetLanguageInfo(idLang, sCodeLang, sizeof(sCodeLang), sNameLang, sizeof(sNameLang));		
		
		GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
	
	
		Menu PrintPrizesMenu = CreateMenu(PrintPrizesMenuAction);
		
		Format(S_panel_title, sizeof(S_panel_title), "%T", "Panel Title Prizes", client, client, S_date_start);
		SetMenuTitle(PrintPrizesMenu, S_panel_title);
		
		if(arrayGiftsWinners)
		{
			for(int i = 0; i < arrayGiftsWinners; i++)
			{
				GetArrayString(Array_GiftsWinners, i, S_info, sizeof(S_info));
				
				char info_explode[4][PLATFORM_MAX_PATH];
				ExplodeString(S_info, "; ", info_explode, 4, PLATFORM_MAX_PATH, true);
				
				if(StrEqual(info_explode[2], steamId, false))
				{
					char gift_explode[2][64];
					ExplodeString(info_explode[3], " | ", gift_explode, 2, 64, true);
					
					char S_gift[64];
					if(StrEqual(sCodeLang, "fr", false))
					{
						strcopy(S_gift, sizeof(S_gift), gift_explode[0]);
					}
					else
					{
						strcopy(S_gift, sizeof(S_gift), gift_explode[1]);
					}
					
					AddMenuItem(PrintPrizesMenu, "", S_gift, ITEMDRAW_DISABLED);
				}
				else
				{
					Format(NoGift, sizeof(NoGift), "%T", "NoGift", client);
					AddMenuItem(PrintPrizesMenu, "", NoGift, ITEMDRAW_DISABLED);
					break;
				}
			}	
		}
		else
		{
			Format(NoGift, sizeof(NoGift), "%T", "NoGift", client);
			AddMenuItem(PrintPrizesMenu, "", NoGift, ITEMDRAW_DISABLED);
		}
		
		SetMenuExitBackButton(PrintPrizesMenu, true);
		DisplayMenu(PrintPrizesMenu, client, MENU_TIME_FOREVER);
	}
}

/***********************************************************/
/******************* ACTION PRIZES WIN *********************/
/***********************************************************/
public int PrintPrizesMenuAction(Handle menu, MenuAction action, int param1, int param2) 
{
	if(action == MenuAction_End) 
	{
		CloseHandle(menu);
	} 
	else if(menu == INVALID_HANDLE && action == MenuAction_Select && param2 == 8)
	{
		PrintPrizes(param1);
	} 
	else if(action == MenuAction_Cancel) 
	{
		if (param2 == MenuCancel_ExitBack)
		{
			PrintPrizes(param1);
		}
	}
}

/***********************************************************/
/********************** ADD WINNER *************************/
/***********************************************************/
void AddWinner(char[] vip, int client, char[] gift)
{
	char steamId[64], info[PLATFORM_MAX_PATH];
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
	
	Format(info, sizeof(info), "%N; %s; %s; %s", client, vip, steamId, gift);
	PushArrayString(Array_GiftsWinners, info);
}

/***********************************************************/
/*********************** GET FILES *************************/
/***********************************************************/
void GetFiles(char[] giftspath, bool move, char[] newfolder = "")
{
	char path[PLATFORM_MAX_PATH], buffer[PLATFORM_MAX_PATH], tmp_path[PLATFORM_MAX_PATH], newpath[PLATFORM_MAX_PATH];
	Handle folder;
	FileType type = FileType_Unknown;
	int len;
	
	
	BuildPath(Path_SM, path, sizeof(path), giftspath);
	
	int count = 0;
	
	if(DirExists(path))
	{
		folder = OpenDirectory(path);
		
		while(ReadDirEntry(folder, buffer, sizeof(buffer), type))
		{
			len = strlen(buffer);
			
			if(buffer[len-1] == '\n') buffer[--len] = '\0';
			
			TrimString(buffer);
			
			if(!StrEqual(buffer,"",false) && !StrEqual(buffer,".",false) && !StrEqual(buffer,"..",false))
			{
				if(type == FileType_File)
				{
					strcopy(tmp_path, PLATFORM_MAX_PATH, path);
					StrCat(tmp_path, PLATFORM_MAX_PATH, "/");
					StrCat(tmp_path, PLATFORM_MAX_PATH, buffer);
					
					if(move)
					{
						Format(newpath, sizeof(newpath), "%s%i", newfolder, count);
						MoveLogs(tmp_path, newpath);
					}
					else
					{
						strcopy(S_last_log, sizeof(S_last_log), tmp_path);
					}
					count++;
				}
			}
			
		}
	}
	
	if(folder != INVALID_HANDLE)
	{
		CloseHandle(folder);
	}
}

/***********************************************************/
/*********************** MOVE LOGS *************************/
/***********************************************************/
void MoveLogs(char[] oldpath, char[] newpath)
{
	if(FileExists(oldpath))
	{
		char newS_date[40], newS_log[PLATFORM_MAX_PATH], newlogfile[PLATFORM_MAX_PATH];
		
		FormatTime(newS_date, sizeof(newS_date), "%c", GetTime()); 
		Format(newS_log, sizeof(newS_log), "%s-%s.txt", newpath, newS_date);
		BuildPath(Path_SM, newlogfile, sizeof(newlogfile), newS_log);
		
		RenameFile(newlogfile ,oldpath);
	}
}
/***********************************************************/
/********************** LOAD SETTINGS **********************/
/***********************************************************/
public void LoadSettings()
{
	char hc[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, hc, sizeof(hc), "configs/drapi/gifts_events.cfg");
	
	Handle kv = CreateKeyValues("Gifts");
	FileToKeyValues(kv, hc);

	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			if(KvJumpToKey(kv, "Vip"))
			{
				for(int i = 1; i <= MAX_GIFTS; ++i)
				{
					char key[64];
					IntToString(i, key, 64);
					
					if(KvGetString(kv, key, S_giftseventsvip[i], PLATFORM_MAX_PATH) && strlen(S_giftseventsvip[i]))
					{
						PushArrayString(Array_GiftsVip, S_giftseventsvip[i]);
						
						if(B_active_gifts_events_dev)
						{
							LogMessage("%s Gifts: %s", TAG_CHAT, S_giftseventsvip[i]);
						}
					}
					else
					{
						break;
					}
					
				}
				KvGoBack(kv);
			}
			
			if(KvJumpToKey(kv, "Others"))
			{
				for(int i = 1; i <= MAX_GIFTS; ++i)
				{
					char key[64];
					IntToString(i, key, 64);
					
					if(KvGetString(kv, key, S_giftseventsothers[i], PLATFORM_MAX_PATH) && strlen(S_giftseventsothers[i]))
					{
						PushArrayString(Array_GiftsOthers, S_giftseventsothers[i]);
						
						if(B_active_gifts_events_dev)
						{
							LogMessage("%s Gifts: %s", TAG_CHAT, S_giftseventsothers[i]);
						}
					}
					else
					{
						break;
					}
					
				}
				KvGoBack(kv);
			}
		}
		while (KvGotoNextKey(kv));
	}
	CloseHandle(kv);
	
	if(!GetArraySize(Array_GiftsOthers))
	{
		if(Array_GiftsOthers != INVALID_HANDLE)
		{
			CloseHandle(Array_GiftsOthers);
			Array_GiftsOthers = INVALID_HANDLE;
		}
	}
	
	if(!GetArraySize(Array_GiftsVip))
	{
		if(Array_GiftsVip != INVALID_HANDLE)
		{
			CloseHandle(Array_GiftsVip);
			Array_GiftsVip = INVALID_HANDLE;
		}
	}
	
}

/***********************************************************/
/******************* GIVE CREDITS TEAM**********************/
/***********************************************************/
void GiveCreditsAll(int credits, char[] msg)
{
	for(int i = 1; i <= MaxClients; i++) 
	{
		if(Client_IsIngame(i) && !IsFakeClient(i))
		{
			int get_credits = Store_GetClientCredits(i);
			Store_SetClientCredits(i, get_credits + credits);
			CPrintToChat(i, "%t", msg, credits);
		}
	}
}

/***********************************************************/
/********************** PRINT TO ADMIN *********************/
/***********************************************************/
stock void CPrintToChatAdmin(char[] format, char[] min, char[] sec)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(Client_IsIngame(i) && IsAdminEx(i))
		{
			CPrintToChat(i, "%t", format, min, sec);
		}
	}
}

/***********************************************************/
/*********************** LOG TO GIFTS **********************/
/***********************************************************/
stock void LogToGiftsEvents(char[] path, bool status, const char[] format, any ...)
{
	if(status)
	{
		char msg[PLATFORM_MAX_PATH];
		char msg2[PLATFORM_MAX_PATH];
		char logfile[PLATFORM_MAX_PATH];
		Format(msg, PLATFORM_MAX_PATH, "%s", format);
		VFormat(msg2, PLATFORM_MAX_PATH, msg, 4);
		
		BuildPath(Path_SM, logfile, sizeof(logfile), path);
		LogToFileEx(logfile, msg2);
	}
}

/***********************************************************/
/******************** CHECK IF IS A VIP ********************/
/***********************************************************/
stock bool IsVip(int client)
{
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM2 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM3 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM4 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM5 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
	{
		return true;
	}
	return false;
}

/***********************************************************/
/****************** CHECK IF IS AN ADMIN *******************/
/***********************************************************/
stock bool IsAdminEx(int client)
{
	if(
	/*|| GetUserFlagBits(client) & ADMFLAG_RESERVATION*/
	GetUserFlagBits(client) & ADMFLAG_GENERIC
	|| GetUserFlagBits(client) & ADMFLAG_KICK
	|| GetUserFlagBits(client) & ADMFLAG_BAN
	|| GetUserFlagBits(client) & ADMFLAG_UNBAN
	|| GetUserFlagBits(client) & ADMFLAG_SLAY
	|| GetUserFlagBits(client) & ADMFLAG_CHANGEMAP
	|| GetUserFlagBits(client) & ADMFLAG_CONVARS
	|| GetUserFlagBits(client) & ADMFLAG_CONFIG
	|| GetUserFlagBits(client) & ADMFLAG_CHAT
	|| GetUserFlagBits(client) & ADMFLAG_VOTE
	|| GetUserFlagBits(client) & ADMFLAG_PASSWORD
	|| GetUserFlagBits(client) & ADMFLAG_RCON
	|| GetUserFlagBits(client) & ADMFLAG_CHEATS
	|| GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		return true;
	}
	return false;
}
/***********************************************************/
/*********************** RANDOM PLAYER *********************/
/***********************************************************/
stock int GetRandomPlayer() 
{
	int[] clients = new int[MaxClients];
	int clientCount;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(Client_IsIngame(i) && GetClientTeam(i) > 1 && !IsVip(i) && !IsAdminEx(i))
		{
			if(CheckWinner(i))
			{
				C_RepeatWin[i]++;
				if(C_RepeatWin[i] > C_gifts_events_nonvip_gifts_reset)
				{
					C_RepeatWin[i] = 0;
				}
			}
			
			if(C_RepeatWin[i] == 0)
			{
				clients[clientCount++] = i;
			}
		}
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}

/***********************************************************/
/********************* RANDOM PLAYER VIP *******************/
/***********************************************************/
stock int GetRandomPlayerVip() 
{
	int[] clients = new int[MaxClients];
	int clientCount;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(Client_IsIngame(i) && GetClientTeam(i) > 1 && IsVip(i) && !IsAdminEx(i))
		{
			if(CheckWinner(i))
			{
				C_RepeatWin[i]++;
				if(C_RepeatWin[i] > C_gifts_events_vip_gifts_reset)
				{
					C_RepeatWin[i] = 0;
				}
			}

			if(C_RepeatWin[i] == 0)
			{
				clients[clientCount++] = i;
			}
		}
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}

/***********************************************************/
/********************* IS VALID CLIENT *********************/
/***********************************************************/
stock bool Client_IsValid(int client, bool checkConnected=true)
{
	if(client > 4096) 
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
/********************* WARMUP TIMER ************************/
/***********************************************************/
stock bool isWarmup()
{
        return (GameRules_GetProp("m_bWarmupPeriod") == 1);
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

/***********************************************************/
/********************** PLAY SOUND *************************/
/***********************************************************/
void PlaySound(char[] sound, int entity = SOUND_FROM_PLAYER, float vol, const float position[3] = NULL_VECTOR, int flags)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i))
		{
			EmitSoundToClientAny(i, sound, entity, SND_GIFTS, _, flags, vol, _, _,position);
		}
	}
}