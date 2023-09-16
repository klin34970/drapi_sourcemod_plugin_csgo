/*  <DR.API CREDITS TIMER> (c) by <De Battista Clint - (http://doyou.watch)  */
/*                                                                           */
/*                  <DR.API CREDITS TIMER> is licensed under a               */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//****************************DR.API CREDITS TIMER***************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[CREDITS TIMER] -"
#define MAX_DAYS 						25

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <store>
#include <timer>
#include <stocks>
#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_credits_timer_dev;

//Bool
bool B_cvar_active_credits_timer_dev					= false;

//Customs
int credits_winner_ct;
int credits_winner_t;
int timer_world_record;
int timer_personal_record;
int timer_top10_record;
int timer_first_record;
int timer_record;

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API CREDITS TIMER",
	author = "Dr. Api",
	description = "DR.API CREDITS TIMER by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://doyou.watch"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	AutoExecConfig_SetFile("drapi_credits_timer", "sourcemod/drapi");
	LoadTranslations("drapi/drapi_credits_timer.phrases");
	
	AutoExecConfig_CreateConVar("drapi_credits_timer_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_credits_timer_dev			= AutoExecConfig_CreateConVar("drapi_active_credits_timer_dev", 			"0", 				"Enable/Disable Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	HookEvent("round_end",	Event_RoundEnd);
	
	RegAdminCmd("sm_win",			Command_Win,			ADMFLAG_CHANGEMAP,	"");
	
	HookEvents();
	AutoExecConfig_ExecuteFile();
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEvents()
{
	HookConVarChange(cvar_active_credits_timer_dev, 				Event_CvarChange);
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
	B_cvar_active_credits_timer_dev 					= GetConVarBool(cvar_active_credits_timer_dev);
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
	LoadTimerCredits();
	UpdateState();
}

/***********************************************************/
/*********************** COMMAND WIN ***********************/
/***********************************************************/
public Action Command_Win(int client, int args)
{
	if(args == 1)
	{
		char sTemp[64];
		GetCmdArg(1, sTemp, sizeof(sTemp));
		
		if(StrEqual(sTemp, "ct", false))
		{
			CS_TerminateRound(3.0, CSRoundEnd_CTWin);
		}
		else if(StrEqual(sTemp, "t", false))
		{
			CS_TerminateRound(3.0, CSRoundEnd_TerroristWin);
		}
	}
}
/***********************************************************/
/******************** WHEN ROUND START *********************/
/***********************************************************/
public void Event_RoundEnd(Handle event, char[] name, bool dontBroadcast)
{
	CSRoundEndReason reason = view_as<CSRoundEndReason>(GetEventInt(event, "reason"));
	int winner = GetEventInt(event, "winner");
	
	if(winner == CS_TEAM_T || reason == CSRoundEnd_TerroristWin)
	{
		GiveCreditsTeam(credits_winner_t, CS_TEAM_T, "OnTeamTWin");
		PrintToDev(B_cvar_active_credits_timer_dev, "%s CT WIN", TAG_CHAT);
	}
	else if(winner == CS_TEAM_CT || reason == CSRoundEnd_CTWin)
	{
		GiveCreditsTeam(credits_winner_ct, CS_TEAM_CT, "OnTeamCTWin");
		PrintToDev(B_cvar_active_credits_timer_dev, "%s T WIN", TAG_CHAT);
	}
}

/***********************************************************/
/***************** ON TIMER WORLD RECORD *******************/
/***********************************************************/
public int OnTimerWorldRecord(int client, int track, int style, float time, float lasttime, int currentrank, int newrank)
{
	GiveCreditsClient(client, timer_world_record);
	CPrintToChat(client, "%t", "OnTimerWorldRecord", timer_world_record);
}

/***********************************************************/
/*************** ON TIMER PERSONNAL RECORD *****************/
/***********************************************************/
public int OnTimerPersonalRecord(int client, int track, int style, float time, float lasttime, int currentrank, int newrank)
{
	GiveCreditsClient(client, timer_personal_record);
	CPrintToChat(client, "%t", "OnTimerPersonalRecord", timer_personal_record);
}

/***********************************************************/
/***************** ON TIMER TOP10 RECORD *******************/
/***********************************************************/
public int OnTimerTop10Record(int client, int track, int style, float time, float lasttime, int currentrank, int newrank)
{
	GiveCreditsClient(client, timer_top10_record);
	CPrintToChat(client, "%t", "OnTimerTop10Record", timer_top10_record);
}

/***********************************************************/
/***************** ON TIMER FIRST RECORD *******************/
/***********************************************************/
public int OnTimerFirstRecord(int client, int track, int style, float time, float lasttime, int currentrank, int newrank)
{
	GiveCreditsClient(client, timer_first_record);
	CPrintToChat(client, "%t", "OnTimerFirstRecord", timer_first_record);
}

/***********************************************************/
/******************** ON TIMER RECORD **********************/
/***********************************************************/
public int OnTimerRecord(int client, int track, int style, float time, float lasttime, int currentrank, int newrank)
{
	GiveCreditsClient(client, timer_record);
	CPrintToChat(client, "OnTimerRecord", timer_record);
}

/***********************************************************/
/****************** GIVE CREDITS CLIENT ********************/
/***********************************************************/
void GiveCreditsClient(int client, int credits)
{
	if(Client_IsIngame(client) && !IsFakeClient(client) && GetClientTeam(client) > 1)
	{
		int get_credits = Store_GetClientCredits(client);
		Store_SetClientCredits(client, get_credits + credits);
		
		PrintToDev(B_cvar_active_credits_timer_dev, "%s CCredits: %i + %i", TAG_CHAT, get_credits, credits);
	}
}

/***********************************************************/
/******************* GIVE CREDITS TEAM**********************/
/***********************************************************/
void GiveCreditsTeam(int credits, int team, char[] msg)
{
	for(int i = 1; i <= MaxClients; i++) 
	{
		if(Client_IsIngame(i) && !IsFakeClient(i) && GetClientTeam(i) == team)
		{
			int get_credits = Store_GetClientCredits(i);
			Store_SetClientCredits(i, get_credits + credits);
			CPrintToChat(i, "%t", msg, credits);
			PrintToDev(B_cvar_active_credits_timer_dev, "%s TCredits: %i + %i", TAG_CHAT, get_credits, credits);
		}
	}
}

/***********************************************************/
/******************* LOAD TIMER CREDITS ********************/
/***********************************************************/
void LoadTimerCredits()
{
	char sPath[PLATFORM_MAX_PATH];
	char currentMap[64];
	GetCurrentMap(currentMap, 64);
	
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/timer/credits_%s.cfg", currentMap);

	if(!FileExists(sPath))
		BuildPath(Path_SM, sPath, sizeof(sPath), "configs/timer/credits.cfg");
	
	Handle hKv = CreateKeyValues("Credits");
	if (!FileToKeyValues(hKv, sPath))
	{
		CloseHandle(hKv);
		return;
	}

	if (!KvGotoFirstSubKey(hKv))
	{
		CloseHandle(hKv);
		return;
	}
	
	do 
	{
		char sSectionName[32];
		KvGetSectionName(hKv, sSectionName, sizeof(sSectionName));
		
		if(StrEqual(sSectionName, "Team", false))
		{
			credits_winner_ct 		= KvGetNum(hKv, "credits_winner_ct", 0);
			credits_winner_t 		= KvGetNum(hKv, "credits_winner_t", 0);
			
			//LogMessage("%s credits_winner_ct: %i, credits_winner_t: %i", TAG_CHAT, credits_winner_ct, credits_winner_t);
		}		
		else if(StrEqual(sSectionName, "Record", false))
		{
			timer_world_record 		= KvGetNum(hKv, "timer_world_record", 0);
			timer_personal_record 	= KvGetNum(hKv, "timer_personal_record", 0);
			timer_top10_record 		= KvGetNum(hKv, "timer_top10_record", 0);
			timer_first_record 		= KvGetNum(hKv, "timer_first_record", 0);
			timer_record 			= KvGetNum(hKv, "timer_record", 0);
			
			//LogMessage("%s timer_world_record: %i, timer_personal_record: %i, timer_top10_record: %i, timer_first_record: %i, timer_record: %i", TAG_CHAT, timer_world_record, timer_personal_record, timer_top10_record, timer_first_record, timer_record);
		}
	} 
	while (KvGotoNextKey(hKv));
		
	CloseHandle(hKv);
}