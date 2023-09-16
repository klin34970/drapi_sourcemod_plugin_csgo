/*   <DR.API BOT QUOTA> (c) by <De Battista Clint - (http://doyou.watch)     */
/*                                                                           */
/*                 <DR.API BOT QUOTA> is licensed under a                    */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//****************************DR.API DOWNLOADER******************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[BOT QUOTA] -"
#define MAX_DAYS 						25
#define MENU_ACTIONS_ALL_EX				view_as<MenuAction>(0xFFFFFFFF)

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

//Handles
Handle cvar_active_bot_quota_dev;
Handle cvar_bot_quota_default;
Handle cvar_bot_per_player;


Handle bot_quota;
Handle kvDays 												= INVALID_HANDLE;

int H_bot_quota_default;
int H_bot_per_player;

//Bools
bool B_active_bot_quota_dev;
bool B_AllowToVote											= false;

//Customs
int INT_TOTAL_DAY;
int data_bot_quota[MAX_DAYS];
int data_bot_quota_player[MAX_DAYS];

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API BOT QUOTA",
	author = "Dr. Api",
	description = "DR.API BOT QUOTA by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://doyou.watch"
}

/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	CreateConVar("drapi_bots_quota_version", PLUGIN_VERSION, "Version", CVARS);
	LoadTranslations("drapi/drapi_bot_quota.phrases");
	
	bot_quota 									= FindConVar("bot_quota");
	
	cvar_active_bot_quota_dev					= CreateConVar("drapi_active_bot_quota_dev",							"0",		"Enable/Disable Dev Mod",								DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	cvar_bot_quota_default 						= CreateConVar("drapi_bot_quota_default", 								"3", 		"Default bot quota", 									DEFAULT_FLAGS);
	cvar_bot_per_player 						= CreateConVar("drapi_bot_per_player", 									"1", 		"Bot for one player", 									DEFAULT_FLAGS);
	
	HookEvent("player_team", 	Event_PlayerTeamPost);
	HookEvent("round_start", 	Event_RoundStart);
	HookEvent("server_cvar", 	Event_Cvar, 			EventHookMode_Pre);
	
	RegConsoleCmd("sm_voteaddbots", Command_VoteAddBots);
	
	RegAdminCmd("sm_addbot", 	Command_AddBot, 	ADMFLAG_CHANGEMAP, "Spawn Bot");
	RegAdminCmd("sm_kickbot", 	Command_KickBot, 	ADMFLAG_CHANGEMAP, "Kick Bot");
		
	AutoExecConfig(true, "drapi_bot_quota", "sourcemod/drapi");
	
	HookEvents();
	
	B_AllowToVote = true;
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEvents()
{
	HookConVarChange(cvar_active_bot_quota_dev, 			Event_CvarChange);
	HookConVarChange(cvar_bot_quota_default, 				Event_CvarChange);
	HookConVarChange(cvar_bot_per_player, 					Event_CvarChange);
}

/***********************************************************/
/******************** WHEN CVARS CHANGE ********************/
/***********************************************************/
public void Event_CvarChange(Handle cvar, const char[] oldValue, const char[] newValue)
{
	UpdateState();
}

/***********************************************************/
/******************** WHEN CVARS CHANGE ********************/
/***********************************************************/
public Action Event_Cvar(Handle event, const char[] name, bool dontBroadcast)
{
	SetEventBroadcast(event, true);
	return Plugin_Continue;
}

/***********************************************************/
/*********************** UPDATE STATE **********************/
/***********************************************************/
void UpdateState()
{
	B_active_bot_quota_dev 									= GetConVarBool(cvar_active_bot_quota_dev);
	
	H_bot_quota_default 									= GetConVarInt(cvar_bot_quota_default);
	H_bot_per_player 										= GetConVarInt(cvar_bot_per_player);
	
	PrintToDev(B_active_bot_quota_dev, "%s cvar changed, bot :%i", TAG_CHAT, GetConVarInt(bot_quota));
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public void OnMapStart()
{
	LoadDayData("configs/drapi/zombie_riot/days", "cfg");
	UpdateState();

	int bot_quota_day 			= GetDayBotQuota(ZRiot_GetDay() - 1);	
	SetConVarInt(bot_quota, bot_quota_day);
}

/***********************************************************/
/******************** WHEN ROUND START *********************/
/***********************************************************/
public void Event_RoundStart(Handle event, char[] name, bool dontBroadcast)
{
	int bot_quota_day 			= GetDayBotQuota(ZRiot_GetDay() - 1);
	int bot_quota_player_day 	= GetDayBotQuotaPlayer(ZRiot_GetDay() - 1);	
	int player_alive			= GetPlayersAlive(CS_TEAM_CT, "player");
	int bot_to_add				= bot_quota_player_day * player_alive;
	
	SetConVarInt(bot_quota, bot_quota_day + bot_to_add);
	
	B_AllowToVote = true;
}

/***********************************************************/
/********************** PLAYER TEAM POST *******************/
/***********************************************************/
public void Event_PlayerTeamPost(Handle event, const char[] name, bool dontBroadcast)
{
	int bot_quota_player_day 	= GetDayBotQuotaPlayer(ZRiot_GetDay() - 1);
	
	if(bot_quota_player_day)
	{
		int client 					= GetClientOfUserId(GetEventInt(event, "userid"));
		int team 					= GetEventInt(event, "team");
		int bot_quota_day 			= GetDayBotQuota(ZRiot_GetDay() - 1);
		
		if(!IsFakeClient(client))
		{
			if(team == CS_TEAM_CT)
			{
				SpawnFakeClient(bot_quota_player_day);
				PrintToDev(B_active_bot_quota_dev, "%s Player went CT", TAG_CHAT);
			}
			else
			{
				if(GetConVarInt(bot_quota) > bot_quota_day)
				{
					KickFakeClient(bot_quota_player_day);
					PrintToDev(B_active_bot_quota_dev, "%s Player went T/SPEC/DECO", TAG_CHAT);
				}
			}
		}
	}
}

/***********************************************************/
/************************* ADD BOTS ************************/
/***********************************************************/
public Action Command_AddBot(int client, int args)
{
	if(ZRiot_GetDayMax() == ZRiot_GetDay())return Plugin_Stop;
	
	int num;
	if(args)
	{
		char S_args1[256];
		GetCmdArg(1, S_args1, sizeof(S_args1));
		num = StringToInt(S_args1);
	}
	else
	{
		num = 1;
	}
	
	SpawnFakeClient(num);
	return Plugin_Handled;
}

/***********************************************************/
/************************* KICK BOTS ***********************/
/***********************************************************/
public Action Command_KickBot(int client, int args)
{
	if(ZRiot_GetDayMax() == ZRiot_GetDay())return Plugin_Stop;
	
	int num;
	if(args)
	{
		char S_args1[256];
		GetCmdArg(1, S_args1, sizeof(S_args1));
		num = StringToInt(S_args1);
	}
	else
	{
		num = 1;
	}
	
	KickFakeClient(num);
	return Plugin_Handled;

}

/***********************************************************/
/********************* SPWAN FAKE CLIENT *******************/
/***********************************************************/
void SpawnFakeClient(int num)
{
	for(int n = 1; n <= num; n++)
	{
		SetConVarInt(bot_quota, GetConVarInt(bot_quota) + 1);
		
		PrintToDev(B_active_bot_quota_dev, "%s bot: %i", TAG_CHAT, GetConVarInt(bot_quota));
	}
	
	CreateTimer(2.0, Timer_CheckBots);
	CreateTimer(5.0, Timer_CheckBots);
}

/***********************************************************/
/********************* KICK FAKE CLIENT ********************/
/***********************************************************/
void KickFakeClient(int num)
{
	for(int n = 1; n <= num; n++)
	{
		SetConVarInt(bot_quota, GetConVarInt(bot_quota) - 1);
		
		PrintToDev(B_active_bot_quota_dev, "%s bot: %i", TAG_CHAT, GetConVarInt(bot_quota));
	}
}

/***********************************************************/
/********************* FORCE SPAWN CLIENT ******************/
/***********************************************************/
public Action Timer_CheckBots(Handle timer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsFakeClient(i) && !IsPlayerAlive(i))
		{
			CS_RespawnPlayer(i);
		}
	}
}

/***********************************************************/
/********************** VOTE ADD BOTS **********************/
/***********************************************************/
public Action Command_VoteAddBots(int client, int args)
{
	if(B_AllowToVote)
	{
		if(args)
		{
			char S_args1[256];
			GetCmdArg(1, S_args1, sizeof(S_args1));	
			int num = StringToInt(S_args1);
			
			if(num <= 5 && num > 0)
			{
				BotVoteMenu(S_args1);
			}
			else
			{
				CPrintToChat(client , "%t", "Wrong num");
			}
		}
		else
		{
			CPrintToChat(client , "%t", "Missing args");
		}
	}
	else
	{
		CPrintToChat(client , "%t", "Not allow to vote");
	}
}
/***********************************************************/
/*********************** BOT VOTE MENU *********************/
/***********************************************************/
void BotVoteMenu(const char[] num)
{
	if(IsVoteInProgress())
	{
		return;
	}
	
	Menu menu = CreateMenu(BotVoteMenuAction, MENU_ACTIONS_ALL_EX);
	
	menu.AddItem(num, "Yes");
	menu.AddItem("no", "No");
	
	menu.SetTitle("MENU_ADDBOTVOTE");
	SetMenuExitBackButton(menu, false);
	
	int[] clients = new int[MaxClients];
	int total = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i) && !IsFakeClient(i) && IsPlayerAlive(i))
		{
			clients[total++] = i;
		}
	}
	if(!total || IsVoteInProgress())
	{
		return;
	}
	
	VoteMenu(menu, clients, total, 20);
}

/***********************************************************/
/******************** BOT VOTE MENU ACTION *****************/
/***********************************************************/
public int BotVoteMenuAction(Handle menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	} 
	else if(action == MenuAction_VoteEnd) 
	{
		if(param1 == 0)
		{
			char num[64];
			GetMenuItem(menu, param1, num, sizeof(num));
			SpawnFakeClient(StringToInt(num));
			CPrintToChatAll("%t", "Spawn bots", num);
			B_AllowToVote = false;
		}
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
		Format(buffer, sizeof(buffer), "%T", "MENU_ADDBOTVOTE", param1, num);

		SetPanelTitle(panel, buffer);	
	}
	return 0;
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
		data_bot_quota[INT_TOTAL_DAY] 									= KvGetNum(kvDays, 		"bot_quota", 			H_bot_quota_default);
		data_bot_quota_player[INT_TOTAL_DAY] 							= KvGetNum(kvDays, 		"bot_quota_player", 	H_bot_per_player);
		
		//LogMessage("%s [DAY%i] - Bot: %i, Bot/Player: %i", TAG_CHAT, INT_TOTAL_DAY, data_bot_quota[INT_TOTAL_DAY], data_bot_quota_player[INT_TOTAL_DAY]);
		
		INT_TOTAL_DAY++;
	} 
	while (KvGotoNextKey(kvDays));
}

/***********************************************************/
/********************* GET DAY BOT QUOTA *******************/
/***********************************************************/
int GetDayBotQuota(int day)
{
    return data_bot_quota[day];
}

/***********************************************************/
/***************** GET DAY BOT QUOTA PLAYER ****************/
/***********************************************************/
int GetDayBotQuotaPlayer(int day)
{
    return data_bot_quota_player[day];
}