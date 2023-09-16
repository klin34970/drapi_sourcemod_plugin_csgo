/*   <DR.API CREDITS DAYS> (c) by <De Battista Clint - (http://doyou.watch)  */
/*                                                                           */
/*                   <DR.API CREDITS DAY> is licensed under a                */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//****************************DR.API CREDITS DAYS****************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[CREDITS DAYS] -"
#define MAX_DAYS 						25

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <store>

#include <stocks>
#include <drapi_zombie_riot>
#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle kvDays;
Handle cvar_active_credits_days_dev;

//Bool
bool B_cvar_active_credits_days_dev					= false;

//Customs
int INT_TOTAL_DAY;
int data_credits[MAX_DAYS];

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API CREDITS DAYS",
	author = "Dr. Api",
	description = "DR.API CREDITS DAYS by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://doyou.watch"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	AutoExecConfig_SetFile("drapi_credits_days", "sourcemod/drapi");
	LoadTranslations("drapi/drapi_credits_days.phrases");
	
	AutoExecConfig_CreateConVar("drapi_credits_days_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_credits_days_dev			= AutoExecConfig_CreateConVar("drapi_active_credits_days_dev", 			"0", 				"Enable/Disable Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	HookEvent("round_end",	Event_RoundEnd, 	EventHookMode_Pre);
	
	HookEvents();
	AutoExecConfig_ExecuteFile();
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEvents()
{
	HookConVarChange(cvar_active_credits_days_dev, 				Event_CvarChange);
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
	B_cvar_active_credits_days_dev 					= GetConVarBool(cvar_active_credits_days_dev);
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
	LoadDayData("configs/drapi/zombie_riot/days", "cfg");
	UpdateState();
}

/***********************************************************/
/******************** WHEN ROUND START *********************/
/***********************************************************/
public void Event_RoundEnd(Handle event, char[] name, bool dontBroadcast)
{
	int day 		= ZRiot_GetDay() - 1;
	int credits 	= GetDayCredits(day);
	
	CSRoundEndReason reason = view_as<CSRoundEndReason>(GetEventInt(event, "reason"));
	int winner = GetEventInt(event, "winner");
	
	if(reason == CSRoundEnd_CTWin)
	{
		if (winner == CS_TEAM_CT)
		{
			GiveCredits(credits);
		}
	}
}

/***********************************************************/
/********************** GIVE CREDITS ***********************/
/***********************************************************/
void GiveCredits(int credits)
{

	for(int i = 1; i <= MaxClients; i++) 
	{
		if(Client_IsIngame(i) && !IsFakeClient(i) && GetClientTeam(i) > 1)
		{
			int get_credits = Store_GetClientCredits(i);
			Store_SetClientCredits(i, get_credits + credits);
			
			PrintToDev(B_cvar_active_credits_days_dev, "%s Credits: %i + %i", TAG_CHAT, get_credits, credits);
			CPrintToChat(i, "%t", "Give Credits Days", credits);
		}
	}
	
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
		data_credits[INT_TOTAL_DAY] 							= KvGetNum(kvDays, 		"credits", 0);
		
		LogMessage("%s [DAY%i] - Credits: %i", TAG_CHAT, INT_TOTAL_DAY, data_credits[INT_TOTAL_DAY]);
		
		INT_TOTAL_DAY++;
	} 
	while (KvGotoNextKey(kvDays));
}

/***********************************************************/
/******************** GET DAY MEDIC TIME *******************/
/***********************************************************/
int GetDayCredits(int day)
{
    return data_credits[day];
}