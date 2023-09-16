/*<DR.API TIMER CHECKPOINTS> (c) by <De Battista Clint - (http://doyou.watch)*/
/*                                                                           */
/*             <DR.API TIMER CHECKPOINTS> is licensed under a                */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//*************************DR.API TIMER CHECKPOINTS**************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[TIMER CHECKPOINTS] -"
#define MAX_LEVEL 						100
#define MAX_BONUS 						5
#define MAX_STYLE						20

//***********************************//
//*************INCLUDE***************//
//***********************************//
#include <sourcemod>
#include <clientprefs>


#include <autoexec>
#include <botmimic>

#include <timer>
#include <timer-mysql>
#include <timer-stocks>
#include <timer-mapzones>
#include <timer-config_loader>
#include <timer-scripter_db>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_timer_checkpoint_dev;

Handle g_hSQL 										= INVALID_HANDLE;
Handle CookieTimerCPChat;

//Bool
bool B_active_timer_checkpoint_dev					= false;

bool B_active_hud_backstage[MAXPLAYERS+1]			= false;
bool B_active_hud[MAXPLAYERS+1]						= false;

//Strings
char S_mapname[32];
char sql_SelectPlayerCP[]							= "SELECT * FROM timercheckpoints WHERE steamid = '%s' AND level = '%i' AND map = '%s' AND track = '%i' AND style = '%i'";
char sql_insertPlayerCP[] 							= "INSERT INTO timercheckpoints (steamid, map, level, levelname, time, name, track, style) VALUES ('%s', '%s', %i, '%s', %f, '%s', %i, %i)";
char sql_updatePlayerCP[] 							= "UPDATE timercheckpoints SET time = '%f', name = '%s' WHERE steamid = '%s' AND map = '%s' AND level = '%i' AND track = '%i' AND style = '%i'";

char sql_SelectPlayerCPWR[]							= "SELECT * FROM timercheckpoints_wr WHERE map = '%s' AND level = '%i' AND track = '%i' AND style = '%i'";
char sql_insertPlayerCPWR[] 						= "INSERT INTO timercheckpoints_wr (steamid, map, level, levelname, time, name, track, style) VALUES ('%s', '%s', %i, '%s', %f, '%s', %i, %i)";
char sql_updatePlayerCPWR[] 						= "UPDATE timercheckpoints_wr SET time = '%f', name = '%s', steamid = '%s' WHERE map = '%s' AND level = '%i' AND track = '%i' AND style = '%i'";

char sql_selectWRMap[] 								= "SELECT a.auth, a.name, a.map, a.track, a.style, b.time, b.steamid, b.level, b.map, b.track, b.style FROM round a JOIN timercheckpoints_wr b ON a.map = b.map AND a.track = b.track AND a.style = b.style WHERE a.rank = 1 AND RIGHT(a.auth, 7) = RIGHT(b.steamid, 7) AND b.level = '%i' AND b.map = '%s' AND b.track = '%i' AND b.style = '%i'";

char S_infopanel[MAXPLAYERS+1][MAX_STYLE][64];
char S_infopanelbonus[MAXPLAYERS+1][MAX_STYLE][MAX_BONUS][64];

//Float 
float WRtimeMap[MAX_STYLE][MAX_BONUS][MAX_LEVEL];

float F_infopanel[MAXPLAYERS+1][MAX_STYLE][MAX_LEVEL][3];
float F_infopanelbonus[MAXPLAYERS+1][MAX_STYLE][MAX_BONUS][MAX_LEVEL];
float F_infopanelbonus2[MAXPLAYERS+1][MAX_STYLE][MAX_BONUS][MAX_LEVEL];
float F_infopanelbonus3[MAXPLAYERS+1][MAX_STYLE][MAX_BONUS][MAX_LEVEL];

float F_Timer[MAXPLAYERS + 1];

//Custom
int C_Zonetype[MAXPLAYERS + 1];
int C_LevelID[MAXPLAYERS + 1];

//Informations plugin
public Plugin myinfo =
{
	name = "[TIMER] DR.API TIMER CHECKPOINTS",
	author = "Dr. Api",
	description = "DR.API TIMER CHECKPOINTS by Dr. Api",
	version = PL_VERSION,
	url = "http://zombie4ever.eu"
}

/***********************************************************/
/********************* ASK PLUGIN LOAD *********************/
/***********************************************************/
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("timer-checkppoints");
	CreateNative("Timer_GetCheckpointsWR", Native_GetCheckpointsWR);
	CreateNative("Timer_GetCheckpointsWRBonus", Native_GetCheckpointsWRBonus);
	
	CreateNative("Timer_GetActiveHud", Native_GetActiveHud);
	CreateNative("Timer_SetActiveHud", Native_SetActiveHud);
	
	return APLRes_Success;
}

/***********************************************************/
/******************** NATIVE GET CP WR *********************/
/***********************************************************/
public int Native_GetCheckpointsWR(Handle plugin, int numParams)
{
	int client 	= GetNativeCell(1);
	int style 	= Timer_GetStyle(client);
	int level 	= C_LevelID[client];
	
	SetNativeCellRef(2, B_active_hud_backstage[client]);
	SetNativeCellRef(3, level);
	SetNativeCellRef(4, F_infopanel[client][style][level][0]);
	SetNativeCellRef(5, F_infopanel[client][style][level][2]);
	
	return true;
}

/***********************************************************/
/***************** NATIVE GET CP WR BONUS ******************/
/***********************************************************/
public int Native_GetCheckpointsWRBonus(Handle plugin, int numParams)
{
	int client 	= GetNativeCell(1);
	int bonus 	= Timer_GetTrack(client);
	int style 	= Timer_GetStyle(client);
	int level 	= C_LevelID[client];
	
	SetNativeCellRef(2, B_active_hud_backstage[client]);
	SetNativeCellRef(3, level);
	SetNativeCellRef(4, F_infopanelbonus[client][style][bonus][level]);
	SetNativeCellRef(5, F_infopanelbonus3[client][style][bonus][level]);
	
	return true;
}

/***********************************************************/
/******************** NATIVE ACTIVE HUD ********************/
/***********************************************************/
public int Native_GetActiveHud(Handle plugin, int numParams)
{
	int client 		= GetNativeCell(1);
	return B_active_hud[client];
}

/***********************************************************/
/******************** NATIVE ACTIVE HUD ********************/
/***********************************************************/
public int Native_SetActiveHud(Handle plugin, int numParams)
{
	int client 		= GetNativeCell(1);
	B_active_hud[client] = GetNativeCell(2);
	SetClientCookie(client, CookieTimerCPChat, (B_active_hud[client]) ? "1" : "0");	
	CPrintToChat(client, "[{GREEN}CHECKPOINTS{NORMAL}] CPS chat turn %s", (B_active_hud[client]) ? "{GREEN}On" : "{RED}Off");
}

/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	LoadPhysics();
	
	LoadTranslations("drapi/drapi_timer_checkpoint.phrases");
	AutoExecConfig_SetFile("drapi_timer_checkpoint", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_timer_checkpoint_version", PL_VERSION, "Version", CVARS);
	
	cvar_active_timer_checkpoint_dev			= AutoExecConfig_CreateConVar("drapi_timer_checkpoints_dev", 			"0", 					"Enable/Disable Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	HookEventsCvars();
	
	AutoExecConfig_ExecuteFile();
	
	CookieTimerCPChat 		= RegClientCookie("CookieTimerCPChat", "", CookieAccess_Private);
	
	RegConsoleCmd("togglecps", Command_ToggleCPS, "trun off/on chat cp");
	
	RegConsoleCmd("cpr", Command_PlayerInfoCP, "playerinfo checkpoints");
	RegConsoleCmd("cprb", Command_PlayerInfoCPBonus, "playerinfo checkpoints bonus");
	
	RegConsoleCmd("b1cpr", Command_PlayerInfoCPBonusB1, "playerinfo checkpoints B1");
	RegConsoleCmd("b2cpr", Command_PlayerInfoCPBonusB2, "playerinfo checkpoints B2");
	RegConsoleCmd("b3cpr", Command_PlayerInfoCPBonusB3, "playerinfo checkpoints B3");
	RegConsoleCmd("b4cpr", Command_PlayerInfoCPBonusB4, "playerinfo checkpoints B4");
	RegConsoleCmd("b5cpr", Command_PlayerInfoCPBonusB5, "playerinfo checkpoints B5");
	
	int i = 1;
	while (i <= MaxClients)
	{
		if(IsClientInGame(i))
		{
			if(AreClientCookiesCached(i))
			{
				OnClientCookiesCached(i);
			}
		}
		i++;
	}
	
	if (g_hSQL == INVALID_HANDLE)
	{
		ConnectSQL();
	}
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEventsCvars()
{
	HookConVarChange(cvar_active_timer_checkpoint_dev, 				Event_CvarChange);
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
	B_active_timer_checkpoint_dev 					= GetConVarBool(cvar_active_timer_checkpoint_dev);
}

/***********************************************************/
/******************* WHEN CONFIG EXECUTED ******************/
/***********************************************************/
public void OnConfigsExecuted()
{
	//UpdateState();
}

/***********************************************************/
/**************** WHEN CLIENT PUT IN SERVER ****************/
/***********************************************************/
public void OnClientPutInServer(int client)
{
	B_active_hud_backstage[client] = true;
}

/***********************************************************/
/**************** ON CLIENT COOKIE CACHED ******************/
/***********************************************************/
public void OnClientCookiesCached(int client)
{
	char value[16];
	
	GetClientCookie(client, CookieTimerCPChat, value, sizeof(value));
	if(strlen(value) > 0) 
	{
		B_active_hud[client] 		= view_as<bool>(StringToInt(value));
	}
	else 
	{
		B_active_hud[client] 		= true;
	}
}
/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public void OnMapStart()
{
	LoadPhysics();
	
	UpdateState();
	
	if(g_hSQL == INVALID_HANDLE)
	{
		ConnectSQL();
	}
	
	GetCurrentMap(S_mapname, 32);
	
	for(int i = 1; i < MAXPLAYERS; i++)
	{
		for(int style = 0; style < MAX_STYLE-1; style++)
		{
			for(int level = 0; level < MAX_LEVEL-1; level++)
			{	
				F_infopanel[i][style][level][0] = 0.0;
				F_infopanel[i][style][level][1] = 0.0;
				F_infopanel[i][style][level][2] = 0.0;
				S_infopanel[i][style] = "";
			}
			
			for(int bonus = 0; bonus < MAX_BONUS-1; bonus++)
			{
				for(int level = 0; level < MAX_LEVEL-1; level++)
				{
					F_infopanelbonus[i][style][bonus][level] = 0.0;
					F_infopanelbonus2[i][style][bonus][level] = 0.0;
					F_infopanelbonus3[i][style][bonus][level] = 0.0;
					S_infopanelbonus[i][style][bonus] = "";
					
					WRtimeMap[style][bonus][level] = 0.0;
				}
			}
		}
	}
}

/***********************************************************/
/***************** ON TIMER SQL CONNECTED ******************/
/***********************************************************/
public int OnTimerSqlConnected(Handle sql)
{
	g_hSQL = sql;
	g_hSQL = INVALID_HANDLE;
	CreateTimer(0.1, Timer_SQLReconnect, _ , TIMER_FLAG_NO_MAPCHANGE);
}

/***********************************************************/
/******************** ON TIMER SQL STOP ********************/
/***********************************************************/
public int OnTimerSqlStop()
{
	g_hSQL = INVALID_HANDLE;
	CreateTimer(0.1, Timer_SQLReconnect, _ , TIMER_FLAG_NO_MAPCHANGE);
}

/***********************************************************/
/*********************** SQL CONNECT ***********************/
/***********************************************************/
void ConnectSQL()
{
	g_hSQL = view_as<Handle>(Timer_SqlGetConnection());
	
	if(g_hSQL == INVALID_HANDLE)
	{
		CreateTimer(0.1, Timer_SQLReconnect, _ , TIMER_FLAG_NO_MAPCHANGE);
	}
}

/***********************************************************/
/****************** TIMER SQL RECONNECTED ******************/
/***********************************************************/
public Action Timer_SQLReconnect(Handle timer, any data)
{
	ConnectSQL();
	return Plugin_Stop;
}

/***********************************************************/
/******************** CMD PLAYER CHAT CP *******************/
/***********************************************************/
public Action Command_ToggleCPS(int client, int args)
{
	B_active_hud[client] 		= !B_active_hud[client];
	SetClientCookie(client, CookieTimerCPChat, (B_active_hud[client]) ? "1" : "0");	
	
	char status[64];
	Format(status, sizeof(status), "%T", (B_active_hud[client]) ? "Enabled" : "Disabled", client);
	
	CPrintToChat(client, "%t", "CPS chat", status);
	return Plugin_Handled;
}

/***********************************************************/
/******************** CMD PLAYER INFO CP *******************/
/***********************************************************/
public Action Command_PlayerInfoCP(int client, int args)
{
	int style = Timer_GetStyle(client);
	
	if(S_infopanel[client][style][0])
	{
		Menu menu = CreateMenu(Menu_PlayerInfo_Handler);
		
		char S_title[PLATFORM_MAX_PATH];
		
		//Ðr. A?? vs WR > Style: Normal- WR by: bro
		Format(S_title, sizeof(S_title), "%T", "Title PI", client, client, g_Physics[style][StyleName], S_infopanel[client][style]);
		SetMenuTitle(menu, S_title);
		
		//CP #1: 00.00.00 (+00.00.00) PB: 00.00.00
		for(int level = 0; level < MAX_LEVEL - 1; level++)
		{
			char S_PBtime[64], S_WRtime[64], S_Diff[64], S_Sentence[PLATFORM_MAX_PATH];
			
			if(F_infopanel[client][style][level][0]  > 0.0)
			{
				Timer_SecondsToTime(F_infopanel[client][style][level][0], S_WRtime, sizeof(S_WRtime), 2);
				Timer_SecondsToTime(F_infopanel[client][style][level][1], S_PBtime, sizeof(S_PBtime), 2);
				
				if(F_infopanel[client][style][level][0] > F_infopanel[client][style][level][1])
				{
					Timer_SecondsToTime(F_infopanel[client][style][level][0] - F_infopanel[client][style][level][1], S_Diff, sizeof(S_Diff), 2);
					FormatEx(S_Sentence, PLATFORM_MAX_PATH, "%T", "PI-", client, level, S_WRtime, S_Diff, S_PBtime);
				}
				else if(F_infopanel[client][style][level][0] < F_infopanel[client][style][level][1])
				{
					Timer_SecondsToTime(F_infopanel[client][style][level][1] - F_infopanel[client][style][level][0], S_Diff, sizeof(S_Diff), 2);
					FormatEx(S_Sentence, PLATFORM_MAX_PATH, "%T", "PI+", client, level, S_WRtime, S_Diff, S_PBtime);
				}
				else if(F_infopanel[client][style][level][0] == F_infopanel[client][style][level][1])
				{
					Timer_SecondsToTime(F_infopanel[client][style][level][0] - F_infopanel[client][style][level][1], S_Diff, sizeof(S_Diff), 2);
					FormatEx(S_Sentence, PLATFORM_MAX_PATH, "%T", "PI", client, level, S_WRtime, S_Diff, S_PBtime);
				}
				AddMenuItem(menu, "", S_Sentence, ITEMDRAW_DISABLED);
			}
		}
		
		DisplayMenu(menu, client, MENU_TIME_FOREVER);

	}
	else
	{
		CPrintToChat(client, "%t", "No Data");
	}
	return Plugin_Handled;
}

/***********************************************************/
/******************** CMD PLAYER BONUS  ********************/
/***********************************************************/
public Action Command_PlayerInfoCPBonusB1(int client, int args)
{
	MenuBonus(client, 0);
	return Plugin_Handled;
}

/***********************************************************/
/******************** CMD PLAYER BONUS  ********************/
/***********************************************************/
public Action Command_PlayerInfoCPBonusB2(int client, int args)
{
	MenuBonus(client, 1);
	return Plugin_Handled;
}

/***********************************************************/
/******************** CMD PLAYER BONUS  ********************/
/***********************************************************/
public Action Command_PlayerInfoCPBonusB3(int client, int args)
{
	MenuBonus(client, 2);
	return Plugin_Handled;
}

/***********************************************************/
/******************** CMD PLAYER BONUS  ********************/
/***********************************************************/
public Action Command_PlayerInfoCPBonusB4(int client, int args)
{
	MenuBonus(client, 3);
	return Plugin_Handled;
}

/***********************************************************/
/******************** CMD PLAYER BONUS  ********************/
/***********************************************************/
public Action Command_PlayerInfoCPBonusB5(int client, int args)
{
	MenuBonus(client, 4);
	return Plugin_Handled;
}

/***********************************************************/
/******************** CMD PLAYER BONUS  ********************/
/***********************************************************/
public Action Command_PlayerInfoCPBonus(int client, int args)
{
	char S_args1[256];
	GetCmdArg(1, S_args1, sizeof(S_args1));
	int bonustrack = StringToInt(S_args1);
	MenuBonus(client, bonustrack);

	return Plugin_Handled;
}

/***********************************************************/
/********************* CMD MENU BONUS  *********************/
/***********************************************************/
void MenuBonus(int client, int bonustrack)
{
	int style = Timer_GetStyle(client);
	
	if(bonustrack >= 0 && bonustrack <= 5)
	{
		if(S_infopanelbonus[client][style][bonustrack][0])
		{
			Menu menu = CreateMenu(Menu_PlayerInfo_Handler);
			
			char S_title[PLATFORM_MAX_PATH];
			Format(S_title, sizeof(S_title), "%T", "Title PI Bonus", client, client, bonustrack + 1, g_Physics[style][StyleName], S_infopanel[client][style]);
			SetMenuTitle(menu, S_title);
			
			for(int level = 0; level < MAX_LEVEL - 1; level++)
			{
				char S_PBtime[64], S_WRtime[64], S_Diff[64], S_Sentence[PLATFORM_MAX_PATH];
				
				Timer_SecondsToTime(F_infopanelbonus[client][style][bonustrack][level], S_WRtime, sizeof(S_WRtime), 2);
				Timer_SecondsToTime(F_infopanelbonus2[client][style][bonustrack][level], S_PBtime, sizeof(S_PBtime), 2);
				
				if(F_infopanelbonus[client][style][bonustrack][level] > 0.0)
				{
					if(F_infopanelbonus[client][style][bonustrack][level] > F_infopanelbonus2[client][style][bonustrack][level])
					{
						Timer_SecondsToTime(F_infopanelbonus[client][style][bonustrack][level] - F_infopanelbonus2[client][style][bonustrack][level], S_Diff, sizeof(S_Diff), 2);
						FormatEx(S_Sentence, PLATFORM_MAX_PATH, "%T", "PI- Bonus", client, level, S_WRtime, S_Diff, S_PBtime);
					}
					else if(F_infopanelbonus[client][style][bonustrack][level] < F_infopanelbonus2[client][style][bonustrack][level])
					{
						Timer_SecondsToTime(F_infopanelbonus2[client][style][bonustrack][level] - F_infopanelbonus[client][style][bonustrack][level], S_Diff, sizeof(S_Diff), 2);
						FormatEx(S_Sentence, PLATFORM_MAX_PATH, "%T", "PI+ Bonus", client, level, S_WRtime, S_Diff, S_PBtime);
					}
					else if(F_infopanelbonus[client][style][bonustrack][level] == F_infopanelbonus2[client][style][bonustrack][level])
					{
						Timer_SecondsToTime(F_infopanelbonus[client][style][bonustrack][level] - F_infopanelbonus2[client][style][bonustrack][level], S_Diff, sizeof(S_Diff), 2);
						FormatEx(S_Sentence, PLATFORM_MAX_PATH, "%T", "PI Bonus", client, level, S_WRtime, S_Diff, S_PBtime);
					}
					
					AddMenuItem(menu, "", S_Sentence, ITEMDRAW_DISABLED);
				}
			}
			
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
		}
		else
		{
			CPrintToChat(client, "%t", "No Data");
		}
	}
	else
	{
		CPrintToChat(client, "%t", "sm_cprb");
	}
}

/***********************************************************/
/******************* PLAYER INFO ACTION ********************/
/***********************************************************/
public int Menu_PlayerInfo_Handler(Handle menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

/***********************************************************/
/************* ON CLIENT START TOUCH ZONE TYPE *************/
/***********************************************************/
public int OnClientStartTouchZoneType(int client, MapZoneType type)
{
	if(type == ZtLevel)
	{
		C_Zonetype[client] = 2;
	}
	else if(type == ZtCheckpoint)
	{
		C_Zonetype[client] = 1;
	}
	else if(type == ZtBonusLevel 
	|| type == ZtBonusCheckpoint 
	|| type == ZtBonus2Level 
	|| type == ZtBonus2Checkpoint 
	|| type == ZtBonus3Level 
	|| type == ZtBonus3Checkpoint 
	|| type == ZtBonus4Level 
	|| type == ZtBonus4Checkpoint 
	|| type == ZtBonus5Level 
	|| type == ZtBonusCheckpoint)
	{
		C_Zonetype[client] = 3;
	}
	else
	{
		//NO CHAT AND HUD
		C_Zonetype[client] = 0;
		B_active_hud_backstage[client] = false;
	}
}

/***********************************************************/
/***************** ON TIMER WOLRD RECORD *******************/
/***********************************************************/
public int OnTimerWorldRecord(int client, int track, int style, float time, float lasttime, int currentrank, int newrank)
{
	if(!Timer_IsScripter(client))
	{
		if(Timer_IsStyleRanked(style))
		{
			char wrname[64];
			GetClientName(client, wrname, sizeof(wrname));
			
			if(track == TRACK_BONUS || track == TRACK_BONUS2 || track == TRACK_BONUS3 || track == TRACK_BONUS4 || track == TRACK_BONUS5)
			{
				for(int level = 0; level < MAX_LEVEL-1; level++)
				{
					if(F_infopanelbonus2[client][style][track][level] > 0.0)
					{	
						SetPlayerCPWR(true, client, track, style, level + 1, S_mapname, F_infopanelbonus2[client][style][track][level]);
						for(int i = 1; i < MAXPLAYERS; i++)
						{
							F_infopanelbonus[i][style][track][level] = F_infopanelbonus2[client][style][track][level];
							strcopy(S_infopanelbonus[i][style][track], PLATFORM_MAX_PATH, wrname);
						}
					}
				}	
			}
			else
			{
				for(int level = 0; level < MAX_LEVEL-1; level++)
				{
					if(F_infopanel[client][style][level][2] > 0.0)
					{
						SetPlayerCPWR(false, client, track, style, level + 1, S_mapname, F_infopanel[client][style][level][2]);
						for(int i = 1; i < MAXPLAYERS; i++)
						{
							F_infopanel[i][style][level][0] = F_infopanel[client][style][level][2];
							strcopy(S_infopanel[i][style], PLATFORM_MAX_PATH, wrname);
						}
					}
				}	
			}
		}
	}
}

/***********************************************************/
/****************** ON CLIENT TOUCH LEVEL ******************/
/***********************************************************/
public int OnClientStartTouchLevel(int client, int level, int lastlevel)
{
	if(!Timer_IsScripter(client))
	{
		if((level == lastlevel + 1 && Timer_GetStatus(client)) || IsFakeClient(client))
		{
			CompareWRCPtoPBCP(false, client, level, S_mapname);
			
			B_active_hud_backstage[client] = true;
			bool enabled = false;
			float time;
			int jumps, fpsmax;
			
			Timer_GetClientTimer(client, enabled, time, jumps, fpsmax);
			SetPlayerCP(false, client, level, S_mapname, time);
		}
		else
		{
			B_active_hud_backstage[client] = false;
		}
		
		if(B_active_timer_checkpoint_dev)
		{
			PrintToChatAll("OnClientStartTouchLevel: %N, %i, %i", client, level, lastlevel);
		}
	}
}

/***********************************************************/
/*************** ON CLIENT TOUCH BONUS LEVEL ***************/
/***********************************************************/
public int OnClientStartTouchBonusLevel(int client, int level, int lastlevel)
{
	if((level == lastlevel + 1 && Timer_GetStatus(client)) || IsFakeClient(client))
	{
		CompareWRCPtoPBCP(true, client, level, S_mapname);
		B_active_hud_backstage[client] = true;
		bool enabled = false;
		float time;
		int jumps, fpsmax;
		
		Timer_GetClientTimer(client, enabled, time, jumps, fpsmax);
		SetPlayerCP(true, client, level, S_mapname, time);
	}
	else
	{
		B_active_hud_backstage[client] = false;
	}
	
	if(B_active_timer_checkpoint_dev)
	{
		PrintToChat(client, "OnClientStartTouchBonusLevel: %i, %i", level, lastlevel);
	}
}


/***********************************************************/
/*************** SET PLAYER CHECKPOINTS WR *****************/
/***********************************************************/
public void SetPlayerCPWR(bool bonus, int client, int track, int style, int level, char[] map, float time)
{
	char steamid[32], name[64], levelname[60];
	
	GetClientName(client, name, sizeof(name));
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid), true);
	
	if(bonus)
	{
		Format(levelname, 60, "Bonus %i", level);
	}
	else
	{
		Timer_GetLevelName(level, levelname, sizeof(levelname));
	}

	Handle pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackCell(pack, level);
	WritePackCell(pack, track);
	WritePackCell(pack, style);
	WritePackFloat(pack, time);
	WritePackString(pack, levelname);
	WritePackString(pack, map);
	WritePackString(pack, name);
	WritePackString(pack, steamid);
	
	char szQuery[2048];
	Format(szQuery, 2048, sql_SelectPlayerCPWR, map, level, track, style);
	SQL_TQuery(g_hSQL, SQL_SelectPlayerCPWR, szQuery, pack, DBPrio_High);
	
	if(B_active_timer_checkpoint_dev)
	{
		//PrintToChatAll("%s", szQuery);
	}
}

/***********************************************************/
/**************** SQL PLAYER CHECKPOINTS WR ****************/
/***********************************************************/
public void SQL_SelectPlayerCPWR(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE) LogError("[Timer] SQL_SelectPlayerCPWR: Error loading playerinfo (%s)", error);

	Handle pack 	= data;
	ResetPack(pack);
	int client 		= ReadPackCell(pack);
	int level 		= ReadPackCell(pack);
	int track 		= ReadPackCell(pack);
	int style 		= ReadPackCell(pack);
	float time		= ReadPackFloat(pack);
	char levelname[60];
	ReadPackString(pack, levelname, sizeof(levelname));	
	char map[64];
	ReadPackString(pack, map, sizeof(map));	
	char name[64];
	ReadPackString(pack, name, sizeof(name));
	char steamid[32];
	ReadPackString(pack, steamid, sizeof(steamid));	
	
	if(SQL_GetRowCount(hndl))
	{
		//UPDATE BEST PB TIME
		if(IsClientInGame(client) && !IsFakeClient(client))
		{
			char szQuery[2048], safename[64];
			SQL_EscapeString(g_hSQL, name, safename, sizeof(safename));
			Format(szQuery, 2048, sql_updatePlayerCPWR, time, safename, steamid, map, level, track, style);
			SQL_TQuery(g_hSQL, SQL_UpdatePlayerCPWR, szQuery, _, DBPrio_High);
			
			if(B_active_timer_checkpoint_dev)
			{
				//PrintToChatAll("%s", szQuery);
			}
		}
	}
	else
	{
		//INSERT PB TIME
		if(IsClientInGame(client) && !IsFakeClient(client))
		{
			char szQuery[2048], safename[64];
			SQL_EscapeString(g_hSQL, name, safename, sizeof(safename));
			Format(szQuery, 2048, sql_insertPlayerCPWR, steamid, map, level, levelname, time, safename, track, style);
			SQL_TQuery(g_hSQL, SQL_InsertPlayerCPWR, szQuery, _, DBPrio_High);
			
			if(B_active_timer_checkpoint_dev)
			{
				//PrintToChatAll("%s", szQuery);
			}				
		}
	}
}
/***********************************************************/
/**************** COMPARE WR CP TO YOUR CP *****************/
/***********************************************************/
public void CompareWRCPtoPBCP(bool bonus, int client, int level, char[] map)
{
	char steamid[32], name[64];
	
	GetClientName(client, name, sizeof(name));
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid), true);
	
	int track = Timer_GetTrack(client);
	int style = Timer_GetStyle(client);
	
	Handle pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackCell(pack, bonus);
	WritePackCell(pack, level);
	
	char szQuery[2048];
	Format(szQuery, 2048, sql_selectWRMap, level, map, track, style);
	SQL_TQuery(g_hSQL, SQL_SelectWRMap, szQuery, pack, DBPrio_High);
	
	if(B_active_timer_checkpoint_dev)
	{
		//PrintToChatAll("%s", szQuery);
	}
}

/***********************************************************/
/***************** SQL PLAYER CHECKPOINTS ******************/
/***********************************************************/
public void SQL_SelectWRMap(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE) LogError("[Timer] SQL_SelectWRMap: Error loading playerinfo (%s)", error);
	
	Handle pack 	= data;
	ResetPack(pack);
	int client 		= ReadPackCell(pack);
	bool bonus 		= view_as<bool>(ReadPackCell(pack));
	int level 		= ReadPackCell(pack);
	
	if(SQL_GetRowCount(hndl))
	{
		while(SQL_FetchRow(hndl))
		{
			char wrname[64];
			SQL_FetchString(hndl, 1, wrname, 64); 
			int WRtrack = SQL_FetchInt(hndl, 3);
			int WRstyle = SQL_FetchInt(hndl, 4);
			
			WRtimeMap[WRstyle][WRtrack][level] 	= SQL_FetchFloat(hndl, 5);
			
			if(bonus)
			{
				int bonusid = SQL_FetchInt(hndl, 3);
				strcopy(S_infopanelbonus[client][WRstyle][bonusid-1], PLATFORM_MAX_PATH, wrname);
			}
			else
			{
				strcopy(S_infopanel[client][WRstyle], PLATFORM_MAX_PATH, wrname);
			}
		}
	}
}

/***********************************************************/
/***************** SET PLAYER CHECKPOINTS ******************/
/***********************************************************/
public void SetPlayerCP(bool bonus, int client, int level, char[] map, float time)
{
	char steamid[32], name[64], levelname[60];
	
	GetClientName(client, name, sizeof(name));
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid), true);
	
	if(bonus)
	{
		Format(levelname, 60, "Bonus %i", level);
	}
	else
	{
		Timer_GetLevelName(level, levelname, sizeof(levelname));
	}
	
	int track = Timer_GetTrack(client);
	int style = Timer_GetStyle(client);
	
	if(Timer_IsStyleRanked(style))
	{
		Handle pack = CreateDataPack();
		WritePackCell(pack, client);
		WritePackCell(pack, bonus);
		WritePackCell(pack, level);
		WritePackCell(pack, track);
		WritePackCell(pack, style);
		WritePackFloat(pack, time);
		WritePackString(pack, levelname);
		WritePackString(pack, map);
		WritePackString(pack, name);
		WritePackString(pack, steamid);
		
		char szQuery[2048];
		Format(szQuery, 2048, sql_SelectPlayerCP, steamid, level, map, track, style);
		SQL_TQuery(g_hSQL, SQL_SelectPlayerCP, szQuery, pack, DBPrio_High);
		
		if(B_active_timer_checkpoint_dev)
		{
			//PrintToChatAll("%s", szQuery);
		}
	}
}

/***********************************************************/
/***************** SQL PLAYER CHECKPOINTS ******************/
/***********************************************************/
public void SQL_SelectPlayerCP(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE) LogError("[Timer] SQL_SelectPlayerCP: Error loading playerinfo (%s)", error);
	
	Handle pack 	= data;
	ResetPack(pack);
	int client 		= ReadPackCell(pack);
	bool bonus 		= view_as<bool>(ReadPackCell(pack));
	int level 		= ReadPackCell(pack);
	int track 		= ReadPackCell(pack);
	int style 		= ReadPackCell(pack);
	float time		= ReadPackFloat(pack);
	char levelname[60];
	ReadPackString(pack, levelname, sizeof(levelname));	
	char map[64];
	ReadPackString(pack, map, sizeof(map));	
	char name[64];
	ReadPackString(pack, name, sizeof(name));
	char steamid[32];
	ReadPackString(pack, steamid, sizeof(steamid));	
	
	if(SQL_GetRowCount(hndl))
	{
		while(SQL_FetchRow(hndl))
		{
			float lastime = SQL_FetchFloat(hndl, 5);

			int clevel;
			if(bonus)
			{
				if(track == TRACK_BONUS)
				{
					clevel = level - 1001;
				}
				else if(track == TRACK_BONUS2)
				{
					clevel = level - 2001;
				}
				else if(track == TRACK_BONUS3)
				{
					clevel = level - 3001;
				}
				else if(track == TRACK_BONUS4)
				{
					clevel = level - 4001;
				}
				else if(track == TRACK_BONUS5)
				{
					clevel = level - 5001;
				}
				F_infopanelbonus[client][style][track-1][clevel] = WRtimeMap[style][track][level];
				F_infopanelbonus2[client][style][track-1][clevel] = lastime;
				F_infopanelbonus3[client][style][track-1][clevel] = time;
			}
			else
			{
				clevel = level - 1;
				F_infopanel[client][style][clevel][0] = WRtimeMap[style][track][level];
				F_infopanel[client][style][clevel][1] = lastime;
				F_infopanel[client][style][clevel][2] = time;
			}
			C_LevelID[client] = clevel;
	
			if(time < lastime)
			{
				//UPDATE BEST PB TIME
				if(IsClientInGame(client) && !IsFakeClient(client))
				{
					char szQuery[2048], safename[64];
					SQL_EscapeString(g_hSQL, name, safename, sizeof(safename));
					Format(szQuery, 2048, sql_updatePlayerCP, time, safename, steamid, map, level, track, style);
					SQL_TQuery(g_hSQL, SQL_UpdatePlayerCP, szQuery, _, DBPrio_High);
					
					if(B_active_timer_checkpoint_dev)
					{
						//PrintToChatAll("%s", szQuery);
					}
				}
			}
			
			Handle dataPackHandle;
			CreateDataTimer(0.0, TimerData_ChatUpdate, dataPackHandle);
			WritePackCell(dataPackHandle, client);
			WritePackCell(dataPackHandle, bonus);
			WritePackCell(dataPackHandle, level);
			WritePackCell(dataPackHandle, track);
			WritePackCell(dataPackHandle, style);
			WritePackFloat(dataPackHandle, time);
			WritePackFloat(dataPackHandle, lastime);
			WritePackString(dataPackHandle, name);
			WritePackCell(dataPackHandle, clevel);
		}
	}
	else
	{
		int clevel;
		if(bonus)
		{
			if(track == TRACK_BONUS)
			{
				clevel = level - 1002;
			}
			else if(track == TRACK_BONUS2)
			{
				clevel = level - 2002;
			}
			else if(track == TRACK_BONUS3)
			{
				clevel = level - 3002;
			}
			else if(track == TRACK_BONUS4)
			{
				clevel = level - 4002;
			}
			else if(track == TRACK_BONUS5)
			{
				clevel = level - 5002;
			}
			F_infopanelbonus[client][style][track-1][clevel] = WRtimeMap[style][track][level];
			F_infopanelbonus2[client][style][track-1][clevel] = time;
			F_infopanelbonus3[client][style][track-1][clevel] = time;
		}
		else
		{
			clevel = level - 1;
			F_infopanel[client][style][clevel][0] = WRtimeMap[style][track][level];
			F_infopanel[client][style][clevel][1] = time;
			F_infopanel[client][style][clevel][2] = time;
		}
		
		C_LevelID[client] = clevel;
	
		//INSERT PB TIME
		if(IsClientInGame(client) && !IsFakeClient(client))
		{
			char szQuery[2048], safename[64];
			SQL_EscapeString(g_hSQL, name, safename, sizeof(safename));
			Format(szQuery, 2048, sql_insertPlayerCP, steamid, map, level, levelname, time, safename, track, style);
			SQL_TQuery(g_hSQL, SQL_InsertPlayerCP, szQuery, _, DBPrio_High);
			
			if(B_active_timer_checkpoint_dev)
			{
				PrintToChatAll("%s", szQuery);
			}
		}
		Handle dataPackHandle;
		CreateDataTimer(0.0, TimerData_ChatInsert, dataPackHandle);
		WritePackCell(dataPackHandle, client);
		WritePackCell(dataPackHandle, level);
		WritePackCell(dataPackHandle, track);
		WritePackCell(dataPackHandle, style);
		WritePackFloat(dataPackHandle, time);
		WritePackString(dataPackHandle, name);
		WritePackCell(dataPackHandle, clevel);
	}
}

/***********************************************************/
/******************** TIMER INSERT CHAT ********************/
/***********************************************************/
public Action TimerData_ChatInsert(Handle timer, Handle dataPackHandle)
{
	ResetPack(dataPackHandle);
	int client 		= ReadPackCell(dataPackHandle);
	int level 		= ReadPackCell(dataPackHandle);
	int track 		= ReadPackCell(dataPackHandle);
	int style 		= ReadPackCell(dataPackHandle);
	float time		= ReadPackFloat(dataPackHandle);
	char name[64];
	ReadPackString(dataPackHandle, name, sizeof(name));
	int clevel 		= ReadPackCell(dataPackHandle);
	
	char S_compareWR[PLATFORM_MAX_PATH];
	float WRtime = WRtimeMap[style][track][level];
	
	if(!IsClientInGame(client)) return;
	char S_compareWRStoT[32];
	
	if(IsClientInGame(client) && BotMimic_IsPlayerMimicing(client))
	{
		time = GetGameTime() - F_Timer[client];
	}
	
	if(WRtime > time)
	{
		Timer_SecondsToTime(WRtime - time, S_compareWRStoT, sizeof(S_compareWRStoT), 2);
		FormatEx(S_compareWR, PLATFORM_MAX_PATH, "{GREEN}-%s{NORMAL}", S_compareWRStoT);
	}
	else if(WRtime < time)
	{
		Timer_SecondsToTime(time - WRtime, S_compareWRStoT, sizeof(S_compareWRStoT), 2);
		FormatEx(S_compareWR, PLATFORM_MAX_PATH, "{RED}+%s{NORMAL}", S_compareWRStoT);
	}
	else if(WRtime == time)
	{
		Timer_SecondsToTime(time - WRtime, S_compareWRStoT, sizeof(S_compareWRStoT), 2);
		FormatEx(S_compareWR, PLATFORM_MAX_PATH, "{YELLOW}%s{NORMAL}", S_compareWRStoT);
	}

	char S_currenttime[PLATFORM_MAX_PATH];
	Timer_SecondsToTime(time, S_currenttime, sizeof(S_currenttime), 2);
	
	int zoneid = C_Zonetype[client];
	if(B_active_hud_backstage[client] && B_active_hud[client])
	{
		if(zoneid == 1)
		{
			if(!BotMimic_IsPlayerMimicing(client) && WRtime > 0.0)
			{
				CPrintToChat(client, "%t", "ChatInsertCP", clevel, S_currenttime, S_compareWR);
			}
			else
			{
				CPrintToChat(client, "%t", "ChatInsert2CP", clevel, S_currenttime);
			}
		}
		else if(zoneid == 2)
		{
			if(!BotMimic_IsPlayerMimicing(client) && WRtime > 0.0)
			{
				CPrintToChat(client, "%t", "ChatInsertStage", clevel, S_currenttime, S_compareWR);
			}
			else
			{
				CPrintToChat(client, "%t", "ChatInsertStage2", clevel, S_currenttime);
			}
		}
		else if(zoneid == 3)
		{
			if(!BotMimic_IsPlayerMimicing(client) && WRtime > 0.0)
			{
				CPrintToChat(client, "%t", "ChatInsertBonus", clevel, S_currenttime, S_compareWR);
			}
			else
			{
				CPrintToChat(client, "%t", "ChatInsertBonus2", clevel, S_currenttime);
			}
		}
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && B_active_hud_backstage[client] && B_active_hud[client] && (!IsPlayerAlive(i) || IsClientObserver(i)))
		{
			int iObserverMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
			if(iObserverMode == SPECMODE_FIRSTPERSON || iObserverMode == SPECMODE_3RDPERSON)
			{
				int clienttoshow = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
				if(clienttoshow > 0 && clienttoshow < (MaxClients + 1) && clienttoshow == client)
				{
					if(zoneid == 1)
					{
						if(!BotMimic_IsPlayerMimicing(client) && WRtime > 0.0)
						{
							CPrintToChat(i, "%t", "ChatInsertCPSpec", clevel, name, S_currenttime, S_compareWR);
						}
						else
						{
							CPrintToChat(i, "%t", "ChatInsertCPSpec", clevel, name, S_currenttime);
						}
					}
					else if(zoneid == 2)
					{
						if(!BotMimic_IsPlayerMimicing(client) && WRtime > 0.0)
						{
							CPrintToChat(i, "%t", "ChatInsertStageSpec", clevel, name, S_currenttime, S_compareWR);		
						}
						else
						{
							CPrintToChat(i, "%t", "ChatInsertStageSpec2", clevel, name, S_currenttime);	
						}
					}
					else if(zoneid == 3)
					{
						if(!BotMimic_IsPlayerMimicing(client) && WRtime > 0.0)
						{
							CPrintToChat(i, "%t", "ChatInsertBonusSpec", clevel, name, S_currenttime, S_compareWR);
						}
						else
						{
							CPrintToChat(i, "%t", "ChatInsertBonusSpec2", clevel, name, S_currenttime);
						}
					}
				}
			}
		}
	}
}

/***********************************************************/
/******************** TIMER UPDATE CHAT ********************/
/***********************************************************/
public Action TimerData_ChatUpdate(Handle timer, Handle dataPackHandle)
{
	ResetPack(dataPackHandle);
	int client 		= ReadPackCell(dataPackHandle);
	int bonus 		= view_as<bool>(ReadPackCell(dataPackHandle));
	int level 		= ReadPackCell(dataPackHandle);
	int track 		= ReadPackCell(dataPackHandle);
	int style 		= ReadPackCell(dataPackHandle);
	float time		= ReadPackFloat(dataPackHandle);
	float lastime	= ReadPackFloat(dataPackHandle);
	char name[64];
	ReadPackString(dataPackHandle, name, sizeof(name));
	int clevel 		= ReadPackCell(dataPackHandle);
	
	char S_compareWR[PLATFORM_MAX_PATH], S_comparePB[PLATFORM_MAX_PATH];
	float WRtime = WRtimeMap[style][track][level];

	char S_compareWRStoT[32], S_comparePBStoT[32];

	if(WRtime > time)
	{
		Timer_SecondsToTime(WRtime - time, S_compareWRStoT, sizeof(S_compareWRStoT), 2);
		FormatEx(S_compareWR, PLATFORM_MAX_PATH, "{GREEN}-%s{NORMAL}", S_compareWRStoT);
	}
	else if(WRtime < time)
	{
		Timer_SecondsToTime(time - WRtime, S_compareWRStoT, sizeof(S_compareWRStoT), 2);
		FormatEx(S_compareWR, PLATFORM_MAX_PATH, "{RED}+%s{NORMAL}", S_compareWRStoT);
	}
	else if(WRtime == time)
	{
		Timer_SecondsToTime(time - WRtime, S_compareWRStoT, sizeof(S_compareWRStoT), 2);
		FormatEx(S_compareWR, PLATFORM_MAX_PATH, "{YELLOW}%s{NORMAL}", S_compareWRStoT);
	}

	if(lastime > time)
	{
		Timer_SecondsToTime(lastime - time, S_comparePBStoT, sizeof(S_comparePBStoT), 2);
		FormatEx(S_comparePB, PLATFORM_MAX_PATH, "{GREEN}-%s{NORMAL}", S_comparePBStoT);
	}
	else if(lastime < time)
	{
		Timer_SecondsToTime(time - lastime, S_comparePBStoT, sizeof(S_comparePBStoT), 2);
		FormatEx(S_comparePB, PLATFORM_MAX_PATH, "{RED}+%s{NORMAL}", S_comparePBStoT);
	}
	else if(lastime == time)
	{
		Timer_SecondsToTime(time - lastime, S_comparePBStoT, sizeof(S_comparePBStoT), 2);
		FormatEx(S_comparePB, PLATFORM_MAX_PATH, "{YELLOW}%s{NORMAL}", S_comparePBStoT);
	}

	char S_currenttime[PLATFORM_MAX_PATH];
	Timer_SecondsToTime(time, S_currenttime, sizeof(S_currenttime), 2);
	
	int zoneid = C_Zonetype[client];
	if(B_active_hud_backstage[client] && B_active_hud[client])
	{
		if(zoneid == 1)
		{
			if(!BotMimic_IsPlayerMimicing(client) && WRtime > 0.0)
			{
				CPrintToChat(client, "%t", "ChatUpdateCP", clevel, S_currenttime, S_compareWR, S_comparePB);
			}
			else
			{
				CPrintToChat(client, "%t", "ChatUpdateCP2", clevel, S_currenttime, S_comparePB);
			}
		}
		else if(zoneid == 2)
		{
			if(!BotMimic_IsPlayerMimicing(client) && WRtime > 0.0)
			{
				CPrintToChat(client, "%t", "ChatUpdateStage", clevel, S_currenttime, S_compareWR, S_comparePB);
			}
			else
			{
				CPrintToChat(client, "%t", "ChatUpdateStage2", clevel, S_currenttime, S_comparePB);
			}
		}
		else if(zoneid == 3)
		{
			if(!BotMimic_IsPlayerMimicing(client) && WRtime > 0.0)
			{
				CPrintToChat(client, "%t", "ChatUpdateBonus", clevel, S_currenttime, S_compareWR, S_comparePB);
			}
			else
			{
				CPrintToChat(client, "%t", "ChatUpdateBonus2", clevel, S_currenttime, S_comparePB);
			}
		}
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && B_active_hud_backstage[client] && B_active_hud[client] && (!IsPlayerAlive(i) || IsClientObserver(i)))
		{
			int iObserverMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
			if(iObserverMode == SPECMODE_FIRSTPERSON || iObserverMode == SPECMODE_3RDPERSON)
			{
				int clienttoshow = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
				if(clienttoshow > 0 && clienttoshow < (MaxClients + 1) && clienttoshow == client)
				{
					if(zoneid == 1)
					{
						if(!BotMimic_IsPlayerMimicing(client) && WRtime > 0.0)
						{
							CPrintToChat(i, "%t", "ChatUpdateCPSpec", clevel, name, S_currenttime, S_compareWR, S_comparePB);
						}
						else
						{
							CPrintToChat(i, "%t", "ChatUpdateCPSpec2", clevel, name, S_currenttime, S_comparePB);
						}
					}
					else if(zoneid == 2)
					{
						if(!BotMimic_IsPlayerMimicing(client) && WRtime > 0.0)
						{
							CPrintToChat(i, "%t", "ChatUpdateStageSpec", clevel, name, S_currenttime, S_compareWR, S_comparePB);		
						}
						else
						{
							CPrintToChat(i, "%t", "ChatUpdateStageSpec2", clevel, name, S_currenttime, S_comparePB);		
						}
					}
					else if(zoneid == 3)
					{
						if(!BotMimic_IsPlayerMimicing(client) && WRtime > 0.0)
						{
							CPrintToChat(i, "%t", "ChatUpdateBonusSpec", level - 1001, name, S_currenttime, S_compareWR, S_comparePB);	
						}
						else
						{
							CPrintToChat(i, "%t", "ChatUpdateBonusSpec2", level - 1001, name, S_currenttime, S_comparePB);	
						}
					}
				}
			}
		}
	}

	if(time < lastime)
	{
		if(bonus)
		{
			int bonusid = Timer_GetTrack(client);
			F_infopanelbonus2[client][style][bonusid-1][clevel] = time;
		}
		else
		{
			F_infopanel[client][style][clevel][1] = time;
		}
	}
}

/***********************************************************/
/************* SQL INSERT PLAYER CHECKPOINTS ***************/
/***********************************************************/
public void SQL_InsertPlayerCP(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE) LogError("[Timer] SQL_InsertPlayerCP: Error loading playerinfo (%s)", error);
	
}

/***********************************************************/
/************* SQL UPDATE PLAYER CHECKPOINTS ***************/
/***********************************************************/
public void SQL_UpdatePlayerCP(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE) LogError("[Timer] SQL_UpdatePlayerCP: Error loading playerinfo (%s)", error);
	
}

/***********************************************************/
/************ SQL INSERT PLAYER CHECKPOINTS WR *************/
/***********************************************************/
public void SQL_InsertPlayerCPWR(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE) LogError("[Timer] SQL_InsertPlayerCPWR: Error loading playerinfo (%s)", error);
	
}

/***********************************************************/
/*********** SQL UPDATE PLAYER CHECKPOINTS WR **************/
/***********************************************************/
public void SQL_UpdatePlayerCPWR(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE) LogError("[Timer] SQL_UpdatePlayerCPWR: Error loading playerinfo (%s)", error);
	
}

/***********************************************************/
/********************** BOT START MIMIC ********************/
/***********************************************************/
public Action BotMimic_OnPlayerStartsMimicing(int client, char[] name, char[] category, char[] path)
{
	F_Timer[client] = GetGameTime();
}
/***********************************************************/
/********************** BOT LOOP MIMIC *********************/
/***********************************************************/
public int BotMimic_OnPlayerMimicLoops(int client)
{
	F_Timer[client] = GetGameTime();
}