/*  <DR.API CREDITS ROUND> (c) by <De Battista Clint - (http://doyou.watch)  */
/*                                                                           */
/*                  <DR.API CREDITS ROUND> is licensed under a               */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//****************************DR.API CREDITS ROUND***************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[CREDITS ROUND] -"
#define MAX_DAYS 						25

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <store>
#include <stocks>
#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_credits_round_dev;

//Bool
bool B_cvar_active_credits_round_dev					= false;

//Customs
int credits_winner_ct;
int credits_winner_t;

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API CREDITS ROUND",
	author = "Dr. Api",
	description = "DR.API CREDITS ROUND by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://doyou.watch"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	AutoExecConfig_SetFile("drapi_credits_round", "sourcemod/drapi");
	LoadTranslations("drapi/drapi_credits_round.phrases");
	
	AutoExecConfig_CreateConVar("drapi_credits_round_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_credits_round_dev			= AutoExecConfig_CreateConVar("drapi_active_credits_round_dev", 			"0", 				"Enable/Disable Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
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
	HookConVarChange(cvar_active_credits_round_dev, 				Event_CvarChange);
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
	B_cvar_active_credits_round_dev 					= GetConVarBool(cvar_active_credits_round_dev);
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
		PrintToDev(B_cvar_active_credits_round_dev, "%s CT WIN", TAG_CHAT);
	}
	else if(winner == CS_TEAM_CT || reason == CSRoundEnd_CTWin)
	{
		GiveCreditsTeam(credits_winner_ct, CS_TEAM_CT, "OnTeamCTWin");
		PrintToDev(B_cvar_active_credits_round_dev, "%s T WIN", TAG_CHAT);
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
			PrintToDev(B_cvar_active_credits_round_dev, "%s TCredits: %i + %i", TAG_CHAT, get_credits, credits);
		}
	}
}

/***********************************************************/
/******************* LOAD ROUND CREDITS ********************/
/***********************************************************/
void LoadTimerCredits()
{
	char sPath[PLATFORM_MAX_PATH];
	char currentMap[64];
	GetCurrentMap(currentMap, 64);
	
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/drapi/credits_%s.cfg", currentMap);

	if(!FileExists(sPath))
		BuildPath(Path_SM, sPath, sizeof(sPath), "configs/drapi/credits.cfg");
	
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
	} 
	while (KvGotoNextKey(hKv));
		
	CloseHandle(hKv);
}