/*       <DR.API TIMER COMPETITIVE RANKING> (c) by <De Battista Clint        */
/*                                                                           */
/*          <DR.API TIMER COMPETITIVE RANKING> is licensed under a           */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//*********************DR.API TIMER COMPETITIVE RANKING**********************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[TIMER COMPETITIVE RANKING] -"

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <autoexec>
#include <csgocolors>
#include <timer>
#include <timer>
#include <timer-rankings>
#include <timer-config_loader>
#include <timer-maptier>
#include <timer-mysql>
#include <timer-physics>
#include <timer-worldrecord>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_timer_competitive_ranking_dev;

Handle g_hSQL 							= INVALID_HANDLE;

//Bool
bool B_active_timer_competitive_ranking_dev					= false;

//Strings
char S_CurrentMap[PLATFORM_MAX_PATH];

char sql_SelectPlayerRound[]							= "SELECT * FROM round WHERE  map = '%s' AND track = '%i' AND style = '%i' ORDER BY time ASC";

char sql_SelectPlayerRank[] 							= "SELECT * FROM ranks WHERE auth LIKE \"%%%s%%\"";
char sql_UpdatePlayerRank[] 							= "UPDATE ranks SET points = '%i' WHERE auth LIKE \"%%%s%%\"";

//Informations plugin
public Plugin myinfo =
{
	name = "[TIMER] DR.API TIMER COMPETITIVE RANKING",
	author = "Dr. Api",
	description = "DR.API TIMER COMPETITIVE RANKING by Dr. Api",
	version = PL_VERSION,
	url = "http://zombie4ever.eu"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	LoadPhysics();
	LoadTimerSettings();
	
	LoadTranslations("drapi/drapi_timer_competitive_ranking.phrases");
	AutoExecConfig_SetFile("drapi_timer_competitive_ranking", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_timer_competitive_ranking_version", PL_VERSION, "Version", CVARS);
	
	cvar_active_timer_competitive_ranking_dev			= AutoExecConfig_CreateConVar("drapi_active_timer_competitive_ranking_dev", 			"0", 					"Enable/Disable Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	HookEventsCvars();
	
	AutoExecConfig_ExecuteFile();
	
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
	HookConVarChange(cvar_active_timer_competitive_ranking_dev, 				Event_CvarChange);
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
	B_active_timer_competitive_ranking_dev 					= GetConVarBool(cvar_active_timer_competitive_ranking_dev);
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
	LoadPhysics();
	LoadTimerSettings();
	
	GetCurrentMap(S_CurrentMap, sizeof(S_CurrentMap));
	
	UpdateState();
	
	if(g_hSQL == INVALID_HANDLE)
	{
		ConnectSQL();
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
/******************** ON TIMER RECORD **********************/
/***********************************************************/
public int OnTimerRecord(int client, int track, int style, float time, float lasttime, int currentrank, int newrank)
{
	if(g_Settings[CPointsEnable])
	{
		if(!IsFakeClient(client) && Timer_IsStyleRanked(style))
		{
			float points 		= 0.0;
			float removepoints 	= 0.0;
			
			float tier 			= TierScale(Timer_GetTier(track));
			float style_scale 	= g_Physics[style][StylePointsMulti];
			
			points 				= tier*style_scale;
			removepoints 		= tier*style_scale;
			
			int finishcount 	= Timer_GetFinishCount(style, track, currentrank);
			int totalrecord 	= Timer_GetStyleTotalRank(style, track);
			
			//FINISH 1ST TIME
			if(finishcount == 0)
			{
				points += g_Settings[CPointsFirst];
				
				if(B_active_timer_competitive_ranking_dev)
				{
					PrintToChatAll("FINISH 1ST TIME: tier:%f * style:%f + pts:%f", tier, style_scale, points);
				}
			}
			else
			{
				points = 0.0;
			}
			
			//IMPROVED TIME
			if(lasttime > 0.0 && time < lasttime)
			{
				points += g_Settings[CPointsImprovedTime];
				
				if(B_active_timer_competitive_ranking_dev)
				{
					PrintToChatAll("IMPROVED TIME: tier:%f * style:%f + pts:%f", tier, style_scale, points);
				}
			}
			
			//BREAK WORLD RECORD SELF
			if(newrank == 1 && totalrecord > 0 && currentrank == newrank)
			{
				points += g_Settings[CPointsNewWorldRecordSelf];
				
				if(B_active_timer_competitive_ranking_dev)
				{
					PrintToChatAll("BREAK WORLD RECORD SELF: tier:%f * style:%f + pts:%f", tier, style_scale, points);
				}
			}
			else if(currentrank > newrank || finishcount == 0)
			{
				//BREAK WORLD RECORD
				if(newrank == 1)
				{
					points 			+= g_Settings[CPointsNewWorldRecord];
					removepoints 	+= g_Settings[CPointsNewWorldRecord2];
					
					if(B_active_timer_competitive_ranking_dev)
					{
						PrintToChatAll("BREAK WORLD RECORD: tier:%f * style:%f + pts:%f", tier, style_scale, points);
					}
				}
				//TOP 2
				else if(newrank <= 2 && (currentrank > 2 || finishcount == 0))
				{
					points 			+= g_Settings[CPointsTop2Record];
					removepoints 	+= g_Settings[CPointsTop2Record2];
					
					if(B_active_timer_competitive_ranking_dev)
					{
						PrintToChatAll("[TOP2] %N: tier:%f * style:%f + pts:%f", client, tier, style_scale, points);
					}
				}
				//TOP 3
				else if(newrank <= 3 && (currentrank > 3 || finishcount == 0))
				{
					points 			+= g_Settings[CPointsTop3Record];
					removepoints 	+= g_Settings[CPointsTop3Record2];
					
					if(B_active_timer_competitive_ranking_dev)
					{
						PrintToChatAll("[TOP3] %N: tier:%f * style:%f + pts:%f", client, tier, style_scale, points);
					}
				}
				//TOP 4
				else if(newrank <= 4 && (currentrank > 4 || finishcount == 0))
				{
					points 			+= g_Settings[CPointsTop4Record];
					removepoints 	+= g_Settings[CPointsTop4Record2];
					
					if(B_active_timer_competitive_ranking_dev)
					{
						PrintToChatAll("[TOP4] %N: tier:%f * style:%f + pts:%f", client, tier, style_scale, points);
					}
				}
				//TOP 5
				else if(newrank <= 5 && (currentrank > 5 || finishcount == 0))
				{
					points 			+= g_Settings[CPointsTop5Record];
					removepoints 	+= g_Settings[CPointsTop5Record2];
					
					if(B_active_timer_competitive_ranking_dev)
					{
						PrintToChatAll("[TOP5] %N: tier:%f * style:%f + pts:%f", client, tier, style_scale, points);
					}
				}
				//TOP 6
				else if(newrank <= 6 && (currentrank > 6 || finishcount == 0))
				{
					points 			+= g_Settings[CPointsTop6Record];
					removepoints 	+= g_Settings[CPointsTop6Record2];
					
					if(B_active_timer_competitive_ranking_dev)
					{
						PrintToChatAll("[TOP6] %N: tier:%f * style:%f + pts:%f", client, tier, style_scale, points);
					}
				}
				//TOP 7
				else if(newrank <= 7 && (currentrank > 7 || finishcount == 0))
				{
					points 			+= g_Settings[CPointsTop7Record];
					removepoints 	+= g_Settings[CPointsTop7Record2];
					
					if(B_active_timer_competitive_ranking_dev)
					{
						PrintToChatAll("[TOP7] %N: tier:%f * style:%f + pts:%f", client, tier, style_scale, points);
					}
				}
				//TOP 8
				else if(newrank <= 8 && (currentrank > 8 || finishcount == 0))
				{
					points 			+= g_Settings[CPointsTop8Record];
					removepoints 	+= g_Settings[CPointsTop8Record2];
					
					if(B_active_timer_competitive_ranking_dev)
					{
						PrintToChatAll("[TOP8] %N: tier:%f * style:%f + pts:%f", client, tier, style_scale, points);
					}
				}
				//TOP 9
				else if(newrank <= 9 && (currentrank > 9 || finishcount == 0))
				{
					points 			+= g_Settings[CPointsTop9Record];
					removepoints 	+= g_Settings[CPointsTop9Record2];
					
					if(B_active_timer_competitive_ranking_dev)
					{
						PrintToChatAll("[TOP2] %N: tier:%f * style:%f + pts:%f", client, tier, style_scale, points);
					}
				}
				//TOP 10
				else if(newrank <= 10 && (currentrank > 10 || finishcount == 0))
				{
					points 			+= g_Settings[CPointsTop10Record];
					removepoints 	+= g_Settings[CPointsTop10Record2];
					
					if(B_active_timer_competitive_ranking_dev)
					{
						PrintToChatAll("[TOP10] %N: tier:%f * style:%f + pts:%f", client, tier, style_scale, points);
					}
				}
				
				//TOP 15
				else if(newrank <= 15 && (currentrank > 15 || finishcount == 0))
				{
					points 			+= g_Settings[CPointsTop11To15Record];
					removepoints 	+= g_Settings[CPointsTop11To15Record2];
					
					if(B_active_timer_competitive_ranking_dev)
					{
						PrintToChatAll("[TOP15] %N: tier:%f * style:%f + pts:%f", client, tier, style_scale, points);
					}
				}
				
				//TOP 20
				else if(newrank <= 20 && (currentrank > 20 || finishcount == 0))
				{
					points 			+= g_Settings[CPointsTop16To20Record];
					removepoints 	+= g_Settings[CPointsTop16To20Record2];
					
					if(B_active_timer_competitive_ranking_dev)
					{
						PrintToChatAll("[TOP20] %N: tier:%f * style:%f + pts:%f", client, tier, style_scale, points);
					}
				}
				
				//TOP 25
				else if(newrank <= 25 && (currentrank > 25 || finishcount == 0))
				{
					points 			+= g_Settings[CPointsTop21To25Record];
					removepoints 	+= g_Settings[CPointsTop21To25Record2];
					
					if(B_active_timer_competitive_ranking_dev)
					{
						PrintToChatAll("[TOP25] %N: tier:%f * style:%f + pts:%f", client, tier, style_scale, points);
					}
				}
				
				//TOP 30
				else if(newrank <= 30 && (currentrank > 30 || finishcount == 0))
				{
					points 			+= g_Settings[CPointsTop26To30Record];
					removepoints 	+= g_Settings[CPointsTop26To30Record2];
					
					if(B_active_timer_competitive_ranking_dev)
					{
						PrintToChatAll("[TOP30] %N: tier:%f * style:%f + pts:%f", client, tier, style_scale, points);
					}
				}
				
				//TOP 50
				else if(newrank <= 50 && (currentrank > 50 || finishcount == 0))
				{
					points 			+= g_Settings[CPointsTop31To50Record];
					removepoints 	+= g_Settings[CPointsTop31To50Record2];
					
					if(B_active_timer_competitive_ranking_dev)
					{
						PrintToChatAll("[TOP50] %N: tier:%f * style:%f + pts:%f", client, tier, style_scale, points);
					}
				}
				
				//TOP 100
				else if(newrank <= 100 && (currentrank > 100 || finishcount == 0))
				{
					points 			+= g_Settings[CPointsTop51To100Record];
					removepoints 	+= g_Settings[CPointsTop51To100Record2];
					
					if(B_active_timer_competitive_ranking_dev)
					{
						PrintToChatAll("[TOP100] %N: tier:%f * style:%f + pts:%f", client, tier, style_scale, points);
					}
				}
				
				//TOP 300
				else if(newrank <= 300 && (currentrank > 300 || finishcount == 0))
				{
					points 			+= g_Settings[CPointsTop101To300Record];
					removepoints 	+= g_Settings[CPointsTop101To300Record2];
					
					if(B_active_timer_competitive_ranking_dev)
					{
						PrintToChatAll("[TOP300] %N: tier:%f * style:%f + pts:%f", client, tier, style_scale, points);
					}
				}
				
				//TOP 10000
				else if(newrank <= 10000 && (currentrank > 10000 || finishcount == 0))
				{
					points 			+= g_Settings[CPointsTop301To10000Record];
					removepoints 	+= g_Settings[CPointsTop301To10000Record2];
					
					if(B_active_timer_competitive_ranking_dev)
					{
						PrintToChatAll("[TOP10000] %N: tier:%f * style:%f + pts:%f", client, tier, style_scale, points);
					}
				}
				

				
				//REMOVE POINTS
				if(removepoints > 0.0)
				{
					Handle pack = CreateDataPack();
					WritePackCell(pack, client);
					WritePackCell(pack, newrank);
					WritePackFloat(pack, removepoints);
					
					char szQuery[2048];
					Format(szQuery, 2048, sql_SelectPlayerRound, S_CurrentMap, track, style);
					SQL_TQuery(g_hSQL, SQL_SelectPlayerRound, szQuery, pack, DBPrio_Low);
				}
			}
			
			//ADD POINTS
			if(points > 0.0)
			{
				int value = RoundToFloor(points);
				Timer_AddPoints(client, value);
				Timer_SavePoints(client);
				
				CPrintToChat(client, "%t", "Add points", value);
			}
		}
	}
}
/***********************************************************/
/**************** SQL PLAYER CHECKPOINTS WR ****************/
/***********************************************************/
public void SQL_SelectPlayerRound(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE) LogError("[Timer] SQL_SelectPlayerRound: Error loading ranking competitive (%s)", error);

	Handle pack 	= data;
	ResetPack(pack);
	int client 			= ReadPackCell(pack);
	int newrank 		= ReadPackCell(pack);
	float removepoints 	= ReadPackFloat(pack);
	
	if(SQL_GetRowCount(hndl))
	{
		int row = 0;
		while(SQL_FetchRow(hndl))
		{
			if(row == newrank)
			{	
				char S_steamid[64];
				SQL_FetchString(hndl, 2, S_steamid, 64);
				
				char S_name[64];
				SQL_FetchString(hndl, 7, S_name, 64);

				Handle pack2 = CreateDataPack();
				WritePackCell(pack2, client);
				WritePackFloat(pack2, removepoints);
					
				char szQuery[2048];
				Format(szQuery, 2048, sql_SelectPlayerRank, S_steamid[8]);
				SQL_TQuery(g_hSQL, SQL_SelectPlayerRank, szQuery, pack2, DBPrio_Low);
				
				if(B_active_timer_competitive_ranking_dev)
				{
					PrintToChatAll("[%s] We found %N classé %i", S_steamid[8], S_name, newrank);
				}
			}
			row++;
		}
	}
}

/***********************************************************/
/**************** SQL PLAYER CHECKPOINTS WR ****************/
/***********************************************************/
public void SQL_SelectPlayerRank(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE) LogError("[Timer] SQL_SelectPlayerRound: Error loading ranking competitive (%s)", error);
	
	if(SQL_GetRowCount(hndl))
	{
		while(SQL_FetchRow(hndl))
		{
			Handle pack 	= data;
			ResetPack(pack);
			int client 				= ReadPackCell(pack);
			float removepoints 		= ReadPackFloat(pack);
	
			int currentpoint = SQL_FetchInt(hndl, 1);
			int setpoints = currentpoint - RoundToFloor(removepoints);
			if(setpoints >= 0)
			{
				char S_steamid[64];
				SQL_FetchString(hndl, 0, S_steamid, 64);
				
				char S_name[64];
				SQL_FetchString(hndl, 2, S_name, 64);
				
				char szQuery[2048];
				Format(szQuery, 2048, sql_UpdatePlayerRank, setpoints, S_steamid[8]);
				SQL_TQuery(g_hSQL, SQL_UpdatePlayerRank, szQuery, _, DBPrio_Low);
				
				Timer_RefreshPointsAll();
				
				CPrintToChat(client, "%t", "Remove points", RoundToFloor(removepoints), S_name, setpoints);
				
				for(int i = 1; i <= MaxClients; i++)
				{
					if(IsClientInGame(i))
					{
						char steamId[64];
						GetClientAuthId(i, AuthId_Steam2, steamId, sizeof(steamId));
						
						if(StrEqual(S_steamid, steamId, false))
						{
							CPrintToChat(i, "%t", "Stole points", client, RoundToFloor(removepoints));
						}
					}
				}
				
				if(B_active_timer_competitive_ranking_dev)
				{
					PrintToChatAll("[%s] - Points DB:%i, Remove:%i, Reste:%i ", S_steamid[8], currentpoint, RoundToFloor(removepoints), setpoints);
				}
				
			}
		}
	}
}
	
/***********************************************************/
/*********** SQL UPDATE PLAYER CHECKPOINTS WR **************/
/***********************************************************/
public void SQL_UpdatePlayerRank(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE) LogError("[Timer] SQL_UpdatePlayerRank: Error loading ranking competitive (%s)", error);
	
}

float TierScale(int tier)
{
	float tier_scale = 1.0;
	
	if(tier == 1)
	{
		tier_scale = g_Settings[Tier1Scale];
	}
	else if(tier == 2)
	{
		tier_scale = g_Settings[Tier2Scale];
	}
	else if(tier == 3)
	{
		tier_scale = g_Settings[Tier3Scale];
	}
	else if(tier == 4)
	{
		tier_scale = g_Settings[Tier4Scale];
	}
	else if(tier == 5)
	{
		tier_scale = g_Settings[Tier5Scale];
	}
	else if(tier == 6)
	{
		tier_scale = g_Settings[Tier6Scale];
	}
	else if(tier == 7)
	{
		tier_scale = g_Settings[Tier7Scale];
	}
	else if(tier == 8)
	{
		tier_scale = g_Settings[Tier8Scale];
	}
	else if(tier == 9)
	{
		tier_scale = g_Settings[Tier9Scale];
	}
	else if(tier == 10)
	{
		tier_scale = g_Settings[Tier10Scale];
	}
	return tier_scale;
}