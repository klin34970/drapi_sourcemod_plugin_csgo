/* <DR.API TIMER WR PLAYER> (c) by <De Battista Clint - (http://doyou.watch) */
/*                                                                           */
/*               <DR.API TIMER WR PLAYER> is licensed under a                */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//**************************DR.API TIMER WR PLAYER***************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[TIMER WR PLAYER] -"

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <autoexec>
#include <timer>
#include <timer-mysql>
#include <timer-stocks>
#include <timer-config_loader>


//***********************************//
//***********PARAMETERS**************//
//***********************************//
//Enums
enum eTarget
{
	bool:eTarget_Active = false,
    String:eTarget_Name[256],
    String:eTarget_SteamID[32],
	eTarget_Style,
	Handle:eTarget_MainMenu,
	Handle:eTarget_MapMenu,
	String:eTarget_Rank[PLATFORM_MAX_PATH],
	String:eTarget_MapsCompleted[PLATFORM_MAX_PATH],
	String:eTarget_BonusesCompleted[PLATFORM_MAX_PATH],
	String:eTarget_MapsWR[PLATFORM_MAX_PATH],
	String:eTarget_BonuseseWR[PLATFORM_MAX_PATH],
	String:eTarget_StagesWR[PLATFORM_MAX_PATH],
	eTarget_iMapsWR,
	eTarget_iBonuseseWR,
	eTarget_iStagesWR,
	String:eTarget_TotalWR[PLATFORM_MAX_PATH]
}

//Handle
Handle cvar_active_timer_worldrecord_player_dev;

Handle g_hSQL 												= INVALID_HANDLE;
Handle g_hPlayerSearch[MAXPLAYERS+1] 						= {INVALID_HANDLE, ...};
Handle g_hMaps[2] 											= {INVALID_HANDLE, ...};

//Bool
bool B_active_timer_worldrecord_player_dev					= false;

//Strings
char g_MapName[32];

//char sql_QueryPlayerName[] 								= "SELECT name, auth FROM round WHERE name LIKE \"%%%s%%\" ORDER BY `round`.`name` ASC, `round`.`auth` ASC;";
char sql_QueryPlayerName[] 									= "SELECT a.name, a.auth, b.points FROM round a JOIN ranks b ON RIGHT(a.auth, 7) = RIGHT(b.auth, 7) WHERE a.name LIKE \"%%%s%%\" GROUP BY a.auth ORDER BY b.points DESC";
char sql_selectPlayer_Points[] 								= "SELECT auth, lastname, points FROM ranks WHERE auth LIKE \"%%%s%%\" AND points NOT LIKE '0';";
char sql_selectPlayerPRowCount[] 							= "SELECT lastname FROM ranks WHERE points >= (SELECT points FROM ranks WHERE auth LIKE \"%%%s%%\" AND points NOT LIKE '0') AND points NOT LIKE '0' ORDER BY points;";
char sql_selectMaps[] 										= "SELECT map FROM mapzone WHERE type = 0 GROUP BY map ORDER BY map;";
char sql_selectMapsBonus[] 									= "SELECT map FROM mapzone WHERE type = 7 GROUP BY map ORDER BY map;";
char sql_selectPlayerWRs[] 									= "SELECT * FROM (SELECT * FROM (SELECT time, map, auth FROM round WHERE track = '0' AND style = '%d' GROUP BY map, time) AS temp GROUP BY LOWER(map)) AS temp2 WHERE auth LIKE \"%%%s%%\"";
char sql_selectPlayerWRsBonus[] 							= "SELECT * FROM (SELECT * FROM (SELECT time, map, auth, track FROM round WHERE track >= '1' AND style = '%d' GROUP BY time) AS temp GROUP BY track, map) AS temp2 WHERE auth LIKE \"%%%s%%\"";
char sql_selectPlayerWRsStages[] 							= "SELECT * FROM (SELECT * FROM (SELECT time, map, steamid, level FROM timercheckpoints GROUP BY time) AS temp GROUP BY level, map) AS temp2 WHERE steamid LIKE \"%%%s%%\"";
//Customs
int g_PointRowCount[MAXPLAYERS+1];
int g_TargetData[MAXPLAYERS+1][eTarget];

int g_iMapCount[2];
int g_iMapCountComplete[MAXPLAYERS+1];

//Informations plugin
public Plugin myinfo =
{
	name = "[TIMER] DR.API TIMER WR PLAYER",
	author = "Dr. Api",
	description = "DR.API TIMER WR PLAYER by Dr. Api",
	version = PL_VERSION,
	url = "http://zombie4ever.eu"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	LoadTranslations("drapi/drapi_timer_worldrecord_player.phrases");
	AutoExecConfig_SetFile("drapi_timer_worldrecord_player", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_timer_worldrecord_player_version", PL_VERSION, "Version", CVARS);
	
	cvar_active_timer_worldrecord_player_dev			= AutoExecConfig_CreateConVar("drapi_active_timer_worldrecord_player_dev", 			"0", 					"Enable/Disable Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	HookEventsCvars();
	
	AutoExecConfig_ExecuteFile();
	
	
	RegConsoleCmd("pi", Command_PlayerInfo, "playerinfo");
	RegConsoleCmd("playerinfo", Command_PlayerInfo, "playerinfo");
	
	LoadPhysics();
	LoadTimerSettings();
	
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
	HookConVarChange(cvar_active_timer_worldrecord_player_dev, 				Event_CvarChange);
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
	B_active_timer_worldrecord_player_dev 					= GetConVarBool(cvar_active_timer_worldrecord_player_dev);
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
	UpdateState();
	
	LoadPhysics();
	LoadTimerSettings();
	
	GetCurrentMap(g_MapName, 32);
	
	if(g_hSQL == INVALID_HANDLE)
	{
		ConnectSQL();
	}
	else
	{
		countmaps();
		countbonusmaps();
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
	else 
	{
		countmaps();
		countbonusmaps();
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
/*********************** COUNT MAPS ************************/
/***********************************************************/
public countmaps()
{
	char Query[255];
	Format(Query, 255, sql_selectMaps);
	SQL_TQuery(g_hSQL, SQL_CountMapCallback, Query, false, DBPrio_High);
}

/***********************************************************/
/******************** COUNT MAPS BONUS *********************/
/***********************************************************/
public countbonusmaps()
{
	char Query[255];
	Format(Query, 255, sql_selectMapsBonus);
	SQL_TQuery(g_hSQL, SQL_CountMapCallback, Query, true, DBPrio_High);
}

/***********************************************************/
/***************** COUNT MAPS CALLBACK *********************/
/***********************************************************/
public SQL_CountMapCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		return;
	}
	
	if(SQL_GetRowCount(hndl))
	{
		int track = data;
		g_iMapCount[track] = 0;
		
		char sMap[128];
		Handle Kv = CreateKeyValues("data");
		
		while(SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, sMap, sizeof(sMap));
			
			KvJumpToKey(Kv, sMap, true);
			KvRewind(Kv);
			
			g_iMapCount[track]++;
		}
		
		g_hMaps[track] = CloneHandle(Kv);
	}
	
	if(B_active_timer_worldrecord_player_dev)
	{
		char S_date[64];
		FormatTime(S_date, sizeof(S_date), "%r", GetTime());
		PrintToChatAll("SQL_CountMapCallback: %s", S_date);
	}
}

/***********************************************************/
/****************** COMMAND PLAYER INFO ********************/
/***********************************************************/
public Action Command_PlayerInfo(int client, int args)
{
	if(args < 1)
	{
		ClearClient(client);
		char SteamID[64];
		GetClientAuthId(client, AuthId_Steam2, SteamID, 64);
		GetClientName(client, g_TargetData[client][eTarget_Name], 256);
		
		Format(g_TargetData[client][eTarget_SteamID], 32, "%s", SteamID[8]);
		
		g_TargetData[client][eTarget_Style] = g_StyleDefault;
		
		g_TargetData[client][eTarget_Active] = true;
		
		if(g_Settings[MultimodeEnable]) 
		{
			StylePanel(client);
		}
		else 
		{
			ExtraInfo(client);
			Panel_PlayerInfo(client);
			CreateTimer(1.0, Timer_MenuPlayerInfo, client);
		}
	}
	else if(args >= 1)
	{
		ClearClient(client);
		
		char NameBuffer[256];
		GetCmdArgString(NameBuffer, sizeof(NameBuffer));
		int startidx = 0;
		int len = strlen(NameBuffer);
		
		if ((NameBuffer[0] == '"') && (NameBuffer[len-1] == '"'))
		{
			startidx = 1;
			NameBuffer[len-1] = '\0';
		}
		
		Format(g_TargetData[client][eTarget_Name], 256, "%s", NameBuffer[startidx]);
		
		g_TargetData[client][eTarget_Active] = false;
		
		if(g_Settings[MultimodeEnable])
		{
			StylePanel(client);
		}
		else
		{
			g_TargetData[client][eTarget_Style] = g_StyleDefault;
			QueryPlayerName(client, g_TargetData[client][eTarget_Name]);
		}
		
		//PrintToChat(client, "[Surf] Searching DB....");
	}
	
	return Plugin_Handled;
}

/***********************************************************/
/********************** STYLE PANEL ************************/
/***********************************************************/
void StylePanel(client)
{
	if(0 < client < MaxClients)
	{
		Menu menu = CreateMenu(MenuHandler_StylePanel);

		SetMenuTitle(menu, "%T", "Select Style", client, client);
		
		SetMenuExitButton(menu, true);

		for(int i = 0; i < MAX_STYLES-1; i++) 
		{
			if(!g_Physics[i][StyleEnable])
				continue;
			if(g_Physics[i][StyleCategory] != MCategory_Ranked)
				continue;
			
			char buffer[8];
			IntToString(i, buffer, sizeof(buffer));
				
			AddMenuItem(menu, buffer, g_Physics[i][StyleName]);
		}
		
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

/***********************************************************/
/****************** STYLE PANEL ACTION *********************/
/***********************************************************/
public int MenuHandler_StylePanel(Handle menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_Select) 
	{
		char info[8];		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		g_TargetData[client][eTarget_Style] = StringToInt(info);
		
		if(g_TargetData[client][eTarget_Active])
		{
			ExtraInfo(client);
			Panel_PlayerInfo(client);
			CreateTimer(1.0, Timer_MenuPlayerInfo, client);
			
		}
		else 
		{
			QueryPlayerName(client, g_TargetData[client][eTarget_Name]);
		}
	}
}

/***********************************************************/
/******************* QUERY PLAYER NAME *********************/
/***********************************************************/
public void QueryPlayerName(int client, char[] QueryPlayerName)
{
	char Query[255];
	char szName[MAX_NAME_LENGTH*2+1];
	SQL_QuoteString(g_hSQL, QueryPlayerName, szName, MAX_NAME_LENGTH*2+1);
	
	Format(Query, 255, sql_QueryPlayerName, szName);
	
	SQL_TQuery(g_hSQL, SQL_QueryPlayerNameCallback, Query, client, DBPrio_High);
}

/***********************************************************/
/******************* QUERY PLAYER NAME *********************/
/***********************************************************/
public void SQL_QueryPlayerNameCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE)
		LogError("Error loading playername (%s)", error);
		
	int client = data;
	char PlayerName[256];
	char SteamID[32];
	char PlayerSteam[256];
	char PlayerChkDup[256];
	int points;
	PlayerChkDup = "zero";
	
	Menu menu = CreateMenu(Menu_PlayerSearch);
	SetMenuTitle(menu, "%T", "Playersearch", client);
	
	g_hPlayerSearch[client] = CreateKeyValues("data");
	
	if(SQL_HasResultSet(hndl))
	{
		int i = 0;
		while (SQL_FetchRow(hndl))
		{
			if (i <= 99)
			{
				SQL_FetchString(hndl, 0, PlayerName, 256);
				SQL_FetchString(hndl, 1, SteamID, 256);
				points = SQL_FetchInt(hndl, 2);
				
				Format(PlayerSteam, 256, "%T", "pts", client, PlayerName, points);
				
				if(!StrEqual(PlayerChkDup, SteamID, false))
				{
					KvJumpToKey(g_hPlayerSearch[client], SteamID, true);
					
					KvSetString(g_hPlayerSearch[client], "name", PlayerName);
					
					KvRewind(g_hPlayerSearch[client]);
					
					AddMenuItem(menu, SteamID, PlayerSteam);
					
					Format(PlayerChkDup, 256, "%s",SteamID);
					i++;
				}
				else
				{
					Format(PlayerChkDup, 256, "%s",SteamID);
				}
			}
		}
		if((i == 0))
		{
			char info[128];
			Format(info, sizeof(info), "%T", "Not Found", client);
			AddMenuItem(menu, "nope", info, ITEMDRAW_DISABLED);
		}
		if(i > 99)
		{
			char info[128];
			Format(info, sizeof(info), "%T", "More100", client);
			
			char info2[128];
			Format(info2, sizeof(info2), "%T", "Specific", client);
			
			AddMenuItem(menu, "many", info, ITEMDRAW_DISABLED);
			AddMenuItem(menu, "speci", info2, ITEMDRAW_DISABLED);
		}
	}
	else
	{
		char info[128];
		Format(info, sizeof(info), "%T", "Not Found", client);
		AddMenuItem(menu, "nope", info, ITEMDRAW_DISABLED);
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	if(B_active_timer_worldrecord_player_dev)
	{
		char S_date[64];
		FormatTime(S_date, sizeof(S_date), "%r", GetTime());
		PrintToChatAll("SQL_QueryPlayerNameCallback: %s", S_date);
	}
}

/***********************************************************/
/***************** PLAYER SEARCH ACTION ********************/
/***********************************************************/
public int Menu_PlayerSearch(Handle menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char SteamID[256];
		GetMenuItem(menu, param2, SteamID, sizeof(SteamID));
		
		if(!StrEqual(SteamID, "nope") && !StrEqual(SteamID, "many") && !StrEqual(SteamID, "speci"))
		{
			Format(g_TargetData[client][eTarget_SteamID], 32, "%s", SteamID[8]);
			KvJumpToKey(g_hPlayerSearch[client], SteamID, false);
			KvGetString(g_hPlayerSearch[client], "name", g_TargetData[client][eTarget_Name], 256, "Unknown");
			
			ExtraInfo(client);
			Panel_PlayerInfo(client);
			CreateTimer(1.0, Timer_MenuPlayerInfo, client);
			
		}
		
		if(g_hPlayerSearch[client] != INVALID_HANDLE)
		{
			CloseHandle(g_hPlayerSearch[client]);
			g_hPlayerSearch[client] = INVALID_HANDLE;
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

/***********************************************************/
/**************** TIMER MENU PLAYER INFO *******************/
/***********************************************************/
public Action Timer_MenuPlayerInfo(Handle timer, any client)
{
	Panel_PlayerInfo(client);
}

/***********************************************************/
/********************** EXTRA INFOS ************************/
/***********************************************************/
ExtraInfo(int client)
{
	//Global server rank: 54th [13458pts]
	char szQuery[255];
	Format(szQuery, 255, sql_selectPlayer_Points, g_TargetData[client][eTarget_SteamID]);
	char szQuery2[255];
	Format(szQuery2, 255, sql_selectPlayerPRowCount, g_TargetData[client][eTarget_SteamID]);

	Handle pack = CreateDataPack();
	WritePackCell(pack, client);

	SQL_TQuery(g_hSQL, SQL_PRowCountCallback, szQuery2, pack, DBPrio_High);
	SQL_TQuery(g_hSQL, SQL_PlayerPointsCallback, szQuery, pack, DBPrio_High);

	
	//Maps completed: 85/100
	GetIncompleteMaps(g_TargetData[client][eTarget_MainMenu], false, client, g_TargetData[client][eTarget_SteamID], 0, g_TargetData[client][eTarget_Style]);
	
	
	//Bonuses completed: 21/50
	GetIncompleteMaps(g_TargetData[client][eTarget_MainMenu], false, client, g_TargetData[client][eTarget_SteamID], 1, g_TargetData[client][eTarget_Style]);
	
	//Map WRs: 2
	Handle pack2 = CreateDataPack();
	WritePackCell(pack2, client);
	WritePackCell(pack2, 0);
	
	char szQuery3[255];
	Format(szQuery3, 255, sql_selectPlayerWRs, g_TargetData[client][eTarget_Style], g_TargetData[client][eTarget_SteamID]);
	SQL_TQuery(g_hSQL, SQL_ViewPlayerMapsCallback, szQuery3, pack2, DBPrio_High);
	
	//Bonus WRs: 0
	Handle pack3 = CreateDataPack();
	WritePackCell(pack3, client);
	WritePackCell(pack3, 1);
	
	char szQuery4[255];
	Format(szQuery4, 255, sql_selectPlayerWRsBonus, g_TargetData[client][eTarget_Style], g_TargetData[client][eTarget_SteamID]);
	SQL_TQuery(g_hSQL, SQL_ViewPlayerMapsCallback, szQuery4, pack3, DBPrio_High);
	
	//Stages WRs: 0
	Handle pack4 = CreateDataPack();
	WritePackCell(pack4, client);

	char szQuery5[255];
	Format(szQuery5, 255, sql_selectPlayerWRsStages, g_TargetData[client][eTarget_SteamID]);
	SQL_TQuery(g_hSQL, SQL_ViewPlayerMapsStagesCallback, szQuery5, pack4, DBPrio_High);
}

/***********************************************************/
/******************* PANEL PLAYER INFO *********************/
/***********************************************************/
public Panel_PlayerInfo(client)
{
	g_TargetData[client][eTarget_Active] = true;
	
	g_TargetData[client][eTarget_MainMenu] = CreatePanel();
	
	char S_title[PLATFORM_MAX_PATH];
	char S_steamid[32];
	Format(S_steamid, 32, "STEAM_1:%s", g_TargetData[client][eTarget_SteamID]);
	
	Format(S_title, PLATFORM_MAX_PATH, "%s's [%s]", g_TargetData[client][eTarget_Name], S_steamid);
	SetPanelTitle(g_TargetData[client][eTarget_MainMenu], S_title);
		
	if(!g_TargetData[client][eTarget_MapsWR][0] || !g_TargetData[client][eTarget_BonuseseWR][0] || !g_TargetData[client][eTarget_StagesWR][0])
	{
		char info[128];
		Format(info, sizeof(info), "%T", "Loading  Statistics", client);
		DrawPanelItem(g_TargetData[client][eTarget_MainMenu], "", ITEMDRAW_SPACER);	
		DrawPanelItem(g_TargetData[client][eTarget_MainMenu], info, ITEMDRAW_RAWLINE);
		DrawPanelItem(g_TargetData[client][eTarget_MainMenu], "", ITEMDRAW_SPACER);
		
		CreateTimer(1.0, Timer_MenuPlayerInfo, client);
	}
	else if(g_TargetData[client][eTarget_MapsWR][0] && g_TargetData[client][eTarget_BonuseseWR][0] && g_TargetData[client][eTarget_StagesWR][0])
	{
		DrawPanelItem(g_TargetData[client][eTarget_MainMenu], "-------------------------", ITEMDRAW_RAWLINE);	
		DrawPanelItem(g_TargetData[client][eTarget_MainMenu], "", ITEMDRAW_SPACER);	
		
		DrawPanelItem(g_TargetData[client][eTarget_MainMenu], g_TargetData[client][eTarget_Rank], ITEMDRAW_RAWLINE);
		
		DrawPanelItem(g_TargetData[client][eTarget_MainMenu], "", ITEMDRAW_SPACER);
		
		char S_allcompleted[PLATFORM_MAX_PATH];
		int total = g_TargetData[client][eTarget_iMapsWR] + g_TargetData[client][eTarget_iBonuseseWR] + g_TargetData[client][eTarget_iStagesWR];
		
		Format(S_allcompleted, PLATFORM_MAX_PATH, "%T", "Total WR", client, total);
		strcopy(g_TargetData[client][eTarget_TotalWR], PLATFORM_MAX_PATH, S_allcompleted);
		
		DrawPanelItem(g_TargetData[client][eTarget_MainMenu], g_TargetData[client][eTarget_TotalWR], ITEMDRAW_RAWLINE);
		DrawPanelItem(g_TargetData[client][eTarget_MainMenu], g_TargetData[client][eTarget_MapsWR], ITEMDRAW_RAWLINE);
		DrawPanelItem(g_TargetData[client][eTarget_MainMenu], g_TargetData[client][eTarget_BonuseseWR], ITEMDRAW_RAWLINE);
		DrawPanelItem(g_TargetData[client][eTarget_MainMenu], g_TargetData[client][eTarget_StagesWR], ITEMDRAW_RAWLINE);
		
		DrawPanelItem(g_TargetData[client][eTarget_MainMenu], "", ITEMDRAW_SPACER);
		
		DrawPanelItem(g_TargetData[client][eTarget_MainMenu], g_TargetData[client][eTarget_MapsCompleted], ITEMDRAW_RAWLINE);
		DrawPanelItem(g_TargetData[client][eTarget_MainMenu], g_TargetData[client][eTarget_BonusesCompleted], ITEMDRAW_RAWLINE);
		
		DrawPanelItem(g_TargetData[client][eTarget_MainMenu], "", ITEMDRAW_SPACER);	
		DrawPanelItem(g_TargetData[client][eTarget_MainMenu], "-------------------------", ITEMDRAW_RAWLINE);
		
		char info2[128];
		Format(info2, sizeof(info2), "%T", "View Incomplete Maps", client);
		
		char info3[128];
		Format(info3, sizeof(info3), "%T", "View Incomplete Maps (Bonus)", client);
		
		DrawPanelItem(g_TargetData[client][eTarget_MainMenu], info2);
		DrawPanelItem(g_TargetData[client][eTarget_MainMenu], info3);
	
		if(g_Settings[MultimodeEnable]) 
		{
			char buffer[512];
			Format(buffer, sizeof(buffer), "%T", "Change style", client, g_Physics[g_TargetData[client][eTarget_Style]][StyleName]);
			DrawPanelItem(g_TargetData[client][eTarget_MainMenu], buffer);
		}
		
		DrawPanelItem(g_TargetData[client][eTarget_MainMenu], "Exit", ITEMDRAW_CONTROL);	
	}
	SendPanelToClient(g_TargetData[client][eTarget_MainMenu], client, Menu_PlayerInfo_Handler, MENU_TIME_FOREVER);
	CloseHandle(g_TargetData[client][eTarget_MainMenu]);
	
	if(B_active_timer_worldrecord_player_dev)
	{
		PrintToChatAll("map %s", g_TargetData[client][eTarget_MapsWR][0]);
		PrintToChatAll("bonus %s", g_TargetData[client][eTarget_BonuseseWR][0]);
		PrintToChatAll("stage %s", g_TargetData[client][eTarget_StagesWR][0]);
	}
}

/***********************************************************/
/******************* PLAYER INFO ACTION ********************/
/***********************************************************/
public int Menu_PlayerInfo_Handler(Handle menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_Select)
	{
		switch(param2)
		{
			case 5:
			{
				GetIncompleteMaps(_, true, client, g_TargetData[client][eTarget_SteamID], 0, g_TargetData[client][eTarget_Style]);
			}
			case 6:
			{
				GetIncompleteMaps(_, true, client, g_TargetData[client][eTarget_SteamID], 1, g_TargetData[client][eTarget_Style]);
			}
			case 7:
			{
				StylePanel(client);
			}
		}
	}
}

/***********************************************************/
/****************** RANK COUNT CALLBACK ********************/
/***********************************************************/
public SQL_PRowCountCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE) LogError("Error viewing player point rowcount (%s)", error);
	
	Handle pack = data;
	ResetPack(pack);
	
	int client = ReadPackCell(pack);
	
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		g_PointRowCount[client] = SQL_GetRowCount(hndl);
	}
	
	if(B_active_timer_worldrecord_player_dev)
	{
		char S_date[64];
		FormatTime(S_date, sizeof(S_date), "%r", GetTime());
		PrintToChatAll("SQL_PRowCountCallback: %s", S_date);
	}
}

/***********************************************************/
/**************** PLAYER PONNTS CALLBACK *******************/
/***********************************************************/
public SQL_PlayerPointsCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE) LogError("Error loading player points (%s)", error);
	
	Handle pack = data;
	ResetPack(pack);
	
	int client 	= ReadPackCell(pack);
	
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		int points;
		
		points = SQL_FetchInt(hndl, 2);
		
		char S_rank[PLATFORM_MAX_PATH];
		
		if(g_PointRowCount[client] == 1)
		{
			Format(S_rank, PLATFORM_MAX_PATH, "%T", "Rang1", client, g_PointRowCount[client], points);
		}
		else if(g_PointRowCount[client] == 2)
		{
			Format(S_rank, PLATFORM_MAX_PATH, "%T", "Rang2", client, g_PointRowCount[client], points);
		}
		else if(g_PointRowCount[client] == 3)
		{
			Format(S_rank, PLATFORM_MAX_PATH, "%T", "Rang3", client, g_PointRowCount[client], points);
		}
		else
		{
			Format(S_rank, PLATFORM_MAX_PATH, "%T", "Rang4", client, g_PointRowCount[client], points);
		}
		
		strcopy(g_TargetData[client][eTarget_Rank], PLATFORM_MAX_PATH, S_rank);
	}
	
	if(B_active_timer_worldrecord_player_dev)
	{
		char S_date[64];
		FormatTime(S_date, sizeof(S_date), "%r", GetTime());
		PrintToChatAll("SQL_PlayerPointsCallback: %s, %i", S_date, g_PointRowCount[client]);
	}
}

/***********************************************************/
/****************** GET INCOMPLETE MAPS ********************/
/***********************************************************/
GetIncompleteMaps(Handle menu = INVALID_HANDLE, bool newmenu, int client, char[] auth, int track, int style)
{
	Handle pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackString(pack, auth);
	WritePackCell(pack, track);
	WritePackCell(pack, style);
	WritePackCell(pack, newmenu);
	WritePackCell(pack, menu);
	
	char sQuery[255];
	if(style > -1)
	{
		if(track > 0)
		{
			Format(sQuery, sizeof(sQuery), "SELECT DISTINCT map FROM round WHERE track >= 1 AND auth LIKE '%%%s%%' AND style = %d ORDER BY map", auth, style);
		}
		else
		{
			Format(sQuery, sizeof(sQuery), "SELECT DISTINCT map FROM round WHERE track = 0 AND auth LIKE '%%%s%%' AND style = %d ORDER BY map", auth, style);
		}
	}
	else
	{
		if(track > 0)
		{
			Format(sQuery, sizeof(sQuery), "SELECT DISTINCT map FROM round WHERE track = 0 AND auth LIKE '%%%s%%' ORDER BY map", track, auth);
		}
		else
		{
			Format(sQuery, sizeof(sQuery), "SELECT DISTINCT map FROM round WHERE track >= 1 AND auth LIKE '%%%s%%' ORDER BY map", track, auth);
		}
	}
	SQL_TQuery(g_hSQL, CallBack_IncompleteMaps, sQuery, pack, DBPrio_High);
}

/***********************************************************/
/*************** INCOMPLETE MAPS CALLBACK ******************/
/***********************************************************/
public CallBack_IncompleteMaps(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == INVALID_HANDLE)
	{
		return;
	}

	Handle pack 	= data;
	
	ResetPack(pack);
	int client 		= ReadPackCell(pack);
	char sAuth[64];
	ReadPackString(pack, sAuth, sizeof(sAuth));
	int track 		= ReadPackCell(pack);
	int style 		= ReadPackCell(pack);
	bool newmenu 	= ReadPackCell(pack);	
	CloseHandle(pack);
	pack = INVALID_HANDLE;
		
	if(!newmenu)
	{	
		if(!SQL_GetRowCount(hndl))
		{
			LogError("No startzone found.");
		}
		else
		{
			char sMap[128];
			Handle Kv = CreateKeyValues("data");
			
			while(SQL_FetchRow(hndl))
			{
				SQL_FetchString(hndl, 0, sMap, sizeof(sMap));
				
				KvJumpToKey(Kv, sMap, true);
				KvRewind(Kv);
				
				g_iMapCountComplete[client]++;
			}
			
			int iCountIncomplete;
				
			KvRewind(g_hMaps[track]);
			KvGotoFirstSubKey(g_hMaps[track], true);
			do
			{
				KvGetSectionName(g_hMaps[track], sMap, sizeof(sMap));
				if(!KvJumpToKey(Kv, sMap, false))
				{
					iCountIncomplete++;
				}
				KvRewind(Kv);
			} while (KvGotoNextKey(g_hMaps[track], false));
			
			if(track == TRACK_NORMAL)
			{
				char S_mapscompleted[PLATFORM_MAX_PATH];
				Format(S_mapscompleted, PLATFORM_MAX_PATH, "%T", "Maps completed", client, g_iMapCount[track] - iCountIncomplete, g_iMapCount[track]); //113 - (113 - 10)
				strcopy(g_TargetData[client][eTarget_MapsCompleted], PLATFORM_MAX_PATH, S_mapscompleted);
			}
			
			if(track == TRACK_BONUS)
			{
				char S_bonusescompleted[PLATFORM_MAX_PATH];
				Format(S_bonusescompleted, PLATFORM_MAX_PATH, "%T", "Bonuses completed", client, g_iMapCount[track] - iCountIncomplete, g_iMapCount[track]);
				strcopy(g_TargetData[client][eTarget_BonusesCompleted], PLATFORM_MAX_PATH, S_bonusescompleted);
			}
		}
	}
	else
	{
		if(!SQL_GetRowCount(hndl))
		{
			LogError("No startzone found.");
		}
		else
		{
			char sMap[128];
			Handle Kv = CreateKeyValues("data");
			
			while(SQL_FetchRow(hndl))
			{
				SQL_FetchString(hndl, 0, sMap, sizeof(sMap));
				
				KvJumpToKey(Kv, sMap, true);
				KvRewind(Kv);
				
				g_iMapCountComplete[client]++;
			}
			
			int iCountIncomplete;
			
			Menu menu = CreateMenu(MenuHandler_Incompelte);
			
			KvRewind(g_hMaps[track]);
			KvGotoFirstSubKey(g_hMaps[track], true);
			do
			{
				KvGetSectionName(g_hMaps[track], sMap, sizeof(sMap));
				if(!KvJumpToKey(Kv, sMap, false))
				{
					iCountIncomplete++;
					AddMenuItem(menu, "", sMap);
				}
				KvRewind(Kv);
			} while (KvGotoNextKey(g_hMaps[track], false));
			
			if(iCountIncomplete == 0)
			{
				char info[128];
				Format(info, sizeof(info), "%T", "All maps completed", client);
				AddMenuItem(menu, "", info);
			}
			
			if(track == TRACK_BONUS)
			{
				if(style == -1 || !g_Settings[MultimodeEnable])
					SetMenuTitle(menu, "%T", "Bonus Maps incomplete", client, iCountIncomplete, g_iMapCount[track], 100.0*(float(iCountIncomplete)/float(g_iMapCount[track])));
				else
					SetMenuTitle(menu, "%T", "Bonus Maps incomplete style", client, iCountIncomplete, g_iMapCount[track], 100.0*(float(iCountIncomplete)/float(g_iMapCount[track])), g_Physics[style][StyleName]);
			}
			else if(track == TRACK_NORMAL)
			{
				if(style == -1 || !g_Settings[MultimodeEnable])
					SetMenuTitle(menu, "%T", "Maps incomplete", client, iCountIncomplete, g_iMapCount[track], 100.0*(float(iCountIncomplete)/float(g_iMapCount[track])));
				else
					SetMenuTitle(menu, "%T", "Maps incomplete style", client, iCountIncomplete, g_iMapCount[track], 100.0*(float(iCountIncomplete)/float(g_iMapCount[track])), g_Physics[style][StyleName]);
			}
			
			SetMenuExitButton(menu, true);
			SetMenuExitBackButton(menu, true);
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
				
		}
	}
	
	if(B_active_timer_worldrecord_player_dev)
	{
		char S_date[64];
		FormatTime(S_date, sizeof(S_date), "%r", GetTime());
		PrintToChatAll("CallBack_IncompleteMaps: %s", S_date);
	}
}

/***********************************************************/
/*************** INCOMPLETE MAPS ACTION ********************/
/***********************************************************/
public int MenuHandler_Incompelte(Handle menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		if(g_TargetData[client][eTarget_MainMenu] != INVALID_HANDLE) 
		{
			Panel_PlayerInfo(client);
		}
	}
	else if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		Panel_PlayerInfo(client);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public SQL_ViewPlayerMapsCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE) LogError("[Timer] Error loading playerinfo (%s)", error);
	
	Handle pack = data;
	ResetPack(pack);
	
	int client = ReadPackCell(pack);
	int track = ReadPackCell(pack);
	
	CloseHandle(pack);
	pack = INVALID_HANDLE;
	
	new mapscomplete = 0;
	if(SQL_HasResultSet(hndl))
	{
		mapscomplete = SQL_GetRowCount(hndl);
	}
	
	if(!track)
	{
		char S_mapscompleted[PLATFORM_MAX_PATH];
		Format(S_mapscompleted, PLATFORM_MAX_PATH, "%T", "Map WR",client, mapscomplete);
		strcopy(g_TargetData[client][eTarget_MapsWR], PLATFORM_MAX_PATH, S_mapscompleted);
		g_TargetData[client][eTarget_iMapsWR] = mapscomplete;
	}
	else
	{
		char S_bonusescompleted[PLATFORM_MAX_PATH];
		Format(S_bonusescompleted, PLATFORM_MAX_PATH, "%T", "Bonus WR", client, mapscomplete);
		strcopy(g_TargetData[client][eTarget_BonuseseWR], PLATFORM_MAX_PATH, S_bonusescompleted);
		g_TargetData[client][eTarget_iBonuseseWR] = mapscomplete;
	}
	
	if(B_active_timer_worldrecord_player_dev)
	{
		char S_date[64];
		FormatTime(S_date, sizeof(S_date), "%r", GetTime());
		PrintToChatAll("SQL_ViewPlayerMapsCallback: %s", S_date);
	}
}

public SQL_ViewPlayerMapsStagesCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE) LogError("[Timer] Error loading playerinfo (%s)", error);
	
	Handle pack = data;
	ResetPack(pack);
	
	int client = ReadPackCell(pack);
	
	CloseHandle(pack);
	pack = INVALID_HANDLE;
	
	new mapscomplete = 0;
	if(SQL_HasResultSet(hndl))
	{
		mapscomplete = SQL_GetRowCount(hndl);
	}
	
	char S_bonusescompleted[PLATFORM_MAX_PATH];
	Format(S_bonusescompleted, PLATFORM_MAX_PATH, "%T", "Stage WR", client, mapscomplete);
	strcopy(g_TargetData[client][eTarget_StagesWR], PLATFORM_MAX_PATH, S_bonusescompleted);
	g_TargetData[client][eTarget_iStagesWR] = mapscomplete;
	
	if(B_active_timer_worldrecord_player_dev)
	{
		char S_date[64];
		FormatTime(S_date, sizeof(S_date), "%r", GetTime());
		PrintToChatAll("SQL_ViewPlayerMapsStagesCallback: %s", S_date);
	}
}

/***********************************************************/
/********************** CLEAR CLIENT ***********************/
/***********************************************************/
stock ClearClient(client)
{
	g_TargetData[client][eTarget_Rank] = 0;
	g_TargetData[client][eTarget_MapsCompleted] = 0;
	g_TargetData[client][eTarget_BonusesCompleted] = 0;
	g_TargetData[client][eTarget_MapsWR] = 0;
	g_TargetData[client][eTarget_BonuseseWR] = 0;
	g_TargetData[client][eTarget_StagesWR] = 0;
	
	g_TargetData[client][eTarget_iMapsWR] = 0;
	g_TargetData[client][eTarget_iBonuseseWR] = 0;
	g_TargetData[client][eTarget_iStagesWR] = 0;
	g_TargetData[client][eTarget_TotalWR] = 0;
}