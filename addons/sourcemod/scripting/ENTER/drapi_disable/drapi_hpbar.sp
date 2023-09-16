/*      <DR.API HP BAR> (c) by <De Battista Clint - (http://doyou.watch)     */
/*                                                                           */
/*                     <DR.API HP BAR> is licensed under a                   */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//*******************************DR.API HP BAR*******************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[HP BAR]-"
#define MAX_SKINS						200

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <stocks>
#include <drapi_zombie_riot>
#include <drapi_afk_manager>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_hpbar_dev;
Handle cvar_active_showbar_ct;
Handle cvar_active_showbar_t;
Handle cvar_hpbar_fadeout_ct;
Handle cvar_hpbar_fadeout_t;

Handle cvar_hpbar_hulk_heal;

Handle Timers[MAXPLAYERS + 1];

int H_hpbar_fadeout_ct;
int H_hpbar_fadeout_t;

//Bool
bool B_cvar_active_showbar_ct 					= false;
bool B_cvar_active_showbar_t 					= false;
bool B_cvar_active_hpbar_dev					= false;

bool IsPlayerSpawn								= true;

//String
char S_model_client[PLATFORM_MAX_PATH];
char S_skins[MAX_SKINS][PLATFORM_MAX_PATH];
char S_skins_height[MAX_SKINS][PLATFORM_MAX_PATH];

//Customs
int max_skins;
int icon[MAXPLAYERS + 1];
int life[MAXPLAYERS + 1];
int totallife[MAXPLAYERS + 1];
int health[MAXPLAYERS + 1];

int C_hpbar_hulk_heal;

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API HP BAR",
	author = "Dr. Api",
	description = "DR.API HP BAR by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://doyou.watch"
}

/***********************************************************/
/*********************** PLUGIN LOAD 2 *********************/
/***********************************************************/
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ClearHPBar", Native_ClearHPBar);
	CreateNative("SetHPBar", Native_SetHPBar);

	return APLRes_Success;
}

/***********************************************************/
/********************* NATIVE SET THIRD ********************/
/***********************************************************/
public int Native_ClearHPBar(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	ClearIcon(client);
}

/***********************************************************/
/********************* NATIVE SET THIRD ********************/
/***********************************************************/
public int Native_SetHPBar(Handle plugin, int numParams)
{
	int client 		= GetNativeCell(1);
	int team 		=  GetNativeCell(2);
	int hp 			=  GetNativeCell(3);
	int real_hp 	=  GetNativeCell(4);
	
	if(team == 3)
	{
		icon[client] = CreateIconCT(client, hp);
	}
	else if(team == 2)
	{
		icon[client] = CreateIconT(client, hp);
	}
	else
	{
		icon[client] = CreateIconBoss(client, hp);
	}
	
	life[client] = real_hp;
}

/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	AutoExecConfig_SetFile("drapi_hpbar", "sourcemod/drapi");
	LoadSettings();
	
	AutoExecConfig_CreateConVar("drapi_hp_bar_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_hpbar_dev						= AutoExecConfig_CreateConVar("drapi_hpbar_active_hpbar_dev", 				"0", 					"Enable/Disable Bot Dev Mod", 											DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	cvar_active_showbar_ct 						= AutoExecConfig_CreateConVar("drapi_hpbar_showbar_ct",  					"1", 					"Enable/Disable HP Bar for CT Team (Showing bar on T head)", 			DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	cvar_active_showbar_t 						= AutoExecConfig_CreateConVar("drapi_hpbar_showbar_t",  					"1", 					"Enable/Disable HP Bar for T Team (Showing bar on T head)", 			DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	cvar_hpbar_fadeout_t 						= AutoExecConfig_CreateConVar("drapi_hpbar_fadeout_t", 						"1000", 				"Distance to display health bar for T Team", 							DEFAULT_FLAGS);
	cvar_hpbar_fadeout_ct 						= AutoExecConfig_CreateConVar("drapi_hpbar_fadeout_ct", 					"0", 					"Distance to display health bar for T Team, 0=always", 					DEFAULT_FLAGS);
	
	cvar_hpbar_hulk_heal 						= AutoExecConfig_CreateConVar("drapi_hpbar_hulk_heal", 						"10000", 				"Life of HULK per players anytime", 									DEFAULT_FLAGS);
	
	HookEvent("player_hurt", 	Event_PlayerHurt);
	HookEvent("player_death", 	Event_PlayerDeath);
	HookEvent("player_spawn", 	Event_PlayerSpawn);
	
	HookEvents();
	
	RegAdminCmd("hpbar", HPBARmenu, ADMFLAG_CHANGEMAP, "Show HP Bar.");
	
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			life[i] = GetClientHealth(i);
			icon[i] = 0;
		}
		i++;
	}
	
	AutoExecConfig_ExecuteFile();
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
			ClearIcon(i);
		}
		i++;
	}
}

/***********************************************************/
/**************** WHEN CLIENT PUT IN SERVER ****************/
/***********************************************************/
public void OnClientPutInServer(int client)
{
	if (IsClientInGame(client))
	{
		life[client] = GetClientHealth(client);
		icon[client] = 0;
	}
}

/***********************************************************/
/***************** WHEN CLIENT DISCONNECT ******************/
/***********************************************************/
public void OnClientDisconnect(int client)
{
	ClearTimer(Timers[client]);
	ClearIcon(client);
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEvents()
{
	HookConVarChange(cvar_active_hpbar_dev, 				Event_CvarChange);
	HookConVarChange(cvar_active_showbar_ct, 				Event_CvarChange);
	HookConVarChange(cvar_active_showbar_t, 				Event_CvarChange);
	HookConVarChange(cvar_hpbar_fadeout_t, 					Event_CvarChange);
	HookConVarChange(cvar_hpbar_fadeout_ct, 				Event_CvarChange);
	
	HookConVarChange(cvar_hpbar_hulk_heal, 					Event_CvarChange);
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
	B_cvar_active_hpbar_dev 					= GetConVarBool(cvar_active_hpbar_dev);
	B_cvar_active_showbar_ct 					= GetConVarBool(cvar_active_showbar_ct);
	B_cvar_active_showbar_t 					= GetConVarBool(cvar_active_showbar_t);
	H_hpbar_fadeout_t 							= GetConVarInt(cvar_hpbar_fadeout_t);
	H_hpbar_fadeout_ct 							= GetConVarInt(cvar_hpbar_fadeout_ct);
	
	C_hpbar_hulk_heal 							= GetConVarInt(cvar_hpbar_hulk_heal);
	
	LoadSettings();
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
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar10_orange.vmt");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar20_orange.vmt");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar30_orange.vmt");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar40_orange.vmt");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar50_orange.vmt");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar60_orange.vmt");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar70_orange.vmt");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar80_orange.vmt");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar90_orange.vmt");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar100_orange.vmt");
	
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar10_red.vmt");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar20_red.vmt");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar30_red.vmt");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar40_red.vmt");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar50_red.vmt");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar60_red.vmt");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar70_red.vmt");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar80_red.vmt");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar90_red.vmt");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar100_red.vmt");
	
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar10_blue.vmt");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar20_blue.vmt");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar30_blue.vmt");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar40_blue.vmt");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar50_blue.vmt");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar60_blue.vmt");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar70_blue.vmt");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar80_blue.vmt");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar90_blue.vmt");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar100_blue.vmt");
	
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar10_orange.vtf");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar20_orange.vtf");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar30_orange.vtf");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar40_orange.vtf");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar50_orange.vtf");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar60_orange.vtf");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar70_orange.vtf");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar80_orange.vtf");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar90_orange.vtf");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar100_orange.vtf");
	
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar10_red.vtf");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar20_red.vtf");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar30_red.vtf");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar40_red.vtf");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar50_red.vtf");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar60_red.vtf");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar70_red.vtf");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar80_red.vtf");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar90_red.vtf");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar100_red.vtf");
	
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar10_blue.vtf");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar20_blue.vtf");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar30_blue.vtf");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar40_blue.vtf");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar50_blue.vtf");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar60_blue.vtf");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar70_blue.vtf");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar80_blue.vtf");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar90_blue.vtf");
	AddFileToDownloadsTable("materials/sprites/z4e/hpbar/hp_bar100_blue.vtf");
	
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar10_orange.vmt");
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar20_orange.vmt");
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar30_orange.vmt");
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar40_orange.vmt");
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar50_orange.vmt");
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar60_orange.vmt");
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar70_orange.vmt");
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar80_orange.vmt");
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar90_orange.vmt");
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar100_orange.vmt");
	
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar10_red.vmt");
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar20_red.vmt");
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar30_red.vmt");
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar40_red.vmt");
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar50_red.vmt");
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar60_red.vmt");
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar70_red.vmt");
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar80_red.vmt");
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar90_red.vmt");
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar100_red.vmt");
	
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar10_blue.vmt");
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar20_blue.vmt");
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar30_blue.vmt");
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar40_blue.vmt");
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar50_blue.vmt");
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar60_blue.vmt");
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar70_blue.vmt");
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar80_blue.vmt");
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar90_blue.vmt");
	PrecacheModel("materials/sprites/z4e/hpbar/hp_bar100_blue.vmt");
	
	LoadSettings();
	UpdateState();
}

/***********************************************************/
/******************** WHEN PLAYER HURT *********************/
/***********************************************************/
public void Event_PlayerHurt(Handle event, char[] name, bool dontBroadcast)
{
	int victim 				= GetClientOfUserId(GetEventInt(event, "userid"));
	health[victim] 			= GetEventInt(event, "health");
	
	if(IsClientInGame(victim) && IsPlayerAlive(victim))
	{
		totallife[victim] = RoundToNearest(float(health[victim]) / float(life[victim]) * 100.0);
		
		if (IconValid(victim))
		{
			if(GetClientTeam(victim) == CS_TEAM_CT && B_cvar_active_showbar_t)
			{
				ShowbarCT(victim, totallife[victim]);
			}
			else if(GetClientTeam(victim) == CS_TEAM_T && B_cvar_active_showbar_ct)
			{
				if(ZRiot_GetDayMax() == ZRiot_GetDay())
				{
					ShowbarBoss(victim, totallife[victim]);
				}
				else
				{
					ShowbarT(victim, totallife[victim]);
				}
			}
		}
		else
		{
			if(GetClientTeam(victim) == CS_TEAM_CT && B_cvar_active_showbar_t)
			{
				icon[victim] = CreateIconCT(victim, totallife[victim]);
			}
			else if(GetClientTeam(victim) == CS_TEAM_T && B_cvar_active_showbar_ct)
			{	
				if(ZRiot_GetDayMax() == ZRiot_GetDay())
				{
					icon[victim] = CreateIconBoss(victim, totallife[victim]);
				}
				else
				{
					icon[victim] = CreateIconT(victim, totallife[victim]);
				}
				
			}
		}
		
		PrintToDev(B_cvar_active_hpbar_dev, "%s vie:%i hp / totalvie:%i hp x 100 = vie restante: %i %", TAG_CHAT, health[victim], life[victim], totallife[victim]);
	}
}

/***********************************************************/
/******************** WHEN PLAYER DIE **********************/
/***********************************************************/
public void Event_PlayerDeath(Handle event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	ClearIcon(client);
	ClearTimer(Timers[client]);
	life[client] = 0;
}

/***********************************************************/
/************ WHEN PLAYER IS AFK MOVE TO SPEC **************/
/***********************************************************/
public void AFK_OnMoveToSpec(int userid)
{
	int client = GetClientOfUserId(userid);
	ClearIcon(client);
	ClearTimer(Timers[client]);
	life[client] = 0;
}

/***********************************************************/
/******************** WHEN PLAYER SPAWN ********************/
/***********************************************************/
public void Event_PlayerSpawn(Handle event, char[] name, bool dontBroadcast)
{
	int client 		= GetClientOfUserId(GetEventInt(event, "userid"));
	IsPlayerSpawn 	= true;
	CreateTimer(1.0, Timer_CheckLife, client);
}

/***********************************************************/
/********************** ON GAME FRAME **********************/
/***********************************************************/
public void OnGameFrame()
{
	if(!IsPlayerSpawn)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(Client_IsIngame(i))
			{
				int newlife = GetClientHealth(i);
				int base_heal = C_hpbar_hulk_heal * GetPlayersInGame(CS_TEAM_CT, "both");
				
				if(base_heal == 0)
				{
					base_heal = C_hpbar_hulk_heal;
				}
				
				if(newlife > life[i])
				{
					int oldlife = life[i];
					life[i] = newlife;
					
					if (IconValid(i))
					{
						if(GetClientTeam(i) == CS_TEAM_CT)
						{
							ShowbarCT(i, 100);
						}
						else if(GetClientTeam(i) == CS_TEAM_T)
						{	
							if(ZRiot_GetDayMax() == ZRiot_GetDay())
							{
								ShowbarBoss(i, 100);
							}
							else
							{
								ShowbarT(i, 100);
							}
						}
					}
					else
					{
						if(GetClientTeam(i) == CS_TEAM_CT)
						{
							icon[i] = CreateIconCT(i, 100);
						}
						else if(GetClientTeam(i) == CS_TEAM_T)
						{	
							if(ZRiot_GetDayMax() == ZRiot_GetDay())
							{
								icon[i] = CreateIconBoss(i, 100);
							}
							else
							{
								icon[i] = CreateIconT(i, 100);
							}
						}
					}

					PrintToDev(B_cvar_active_hpbar_dev, "%s We detect hp value changed: old:%i, new:%i", TAG_CHAT, oldlife, newlife);
				}
				
				else if(newlife > health[i])
				{
					totallife[i] = RoundToNearest(float(newlife) / float(life[i]) * 100.0);

					if (IconValid(i))
					{
						if(GetClientTeam(i) == CS_TEAM_CT)
						{
							ShowbarCT(i, totallife[i]);
						}
						else if(GetClientTeam(i) == CS_TEAM_T)
						{	
							if(ZRiot_GetDayMax() == ZRiot_GetDay() && !(base_heal < life[i]))
							{
								ShowbarBoss(i, totallife[i]);
							}
							else
							{
								ShowbarT(i, totallife[i]);
							}
						}
					}
					else
					{
						if(GetClientTeam(i) == CS_TEAM_CT)
						{
							icon[i] = CreateIconCT(i, totallife[i]);
						}
						else if(GetClientTeam(i) == CS_TEAM_T)
						{	
							if(ZRiot_GetDayMax() == ZRiot_GetDay() && !(base_heal < life[i]))
							{
								icon[i] = CreateIconBoss(i, totallife[i]);
							}
							else
							{
								icon[i] = CreateIconT(i, totallife[i]);
							}
						}
					}
					
					PrintToDev(B_cvar_active_hpbar_dev, "%s Base HP:%i, old life: %i, new life: %i, Life: %i %", TAG_CHAT, life[i], health[i], newlife, totallife[i]);
					
					health[i] = newlife;
				}
				else if(base_heal < life[i] && ZRiot_GetDayMax() == ZRiot_GetDay() && newlife < life[i])
				{
					//47 000 / 50 0000 * 100 = 94%
					totallife[i] = RoundToNearest(float(newlife) / float(life[i]) * 100.0);
					
					if (IconValid(i))
					{
						if(GetClientTeam(i) == CS_TEAM_T)
						{	
							if(ZRiot_GetDayMax() == ZRiot_GetDay())
							{
								ShowbarBoss(i, totallife[i]);
							}
						}
					}
					else
					{
						if(GetClientTeam(i) == CS_TEAM_T)
						{	
							if(ZRiot_GetDayMax() == ZRiot_GetDay())
							{
								icon[i] = CreateIconBoss(i, totallife[i]);
							}
						}
					}
					//Max life = 40 000
					life[i] = base_heal;
					
					PrintToDev(B_cvar_active_hpbar_dev, "%s BaseHP HULK Changed:%i, new:%i", TAG_CHAT, life[i], newlife);
				}
			}
		}
	}
}

/***********************************************************/
/********************** !HPBAR MENU ************************/
/***********************************************************/
public Action HPBARmenu(int client, int args)
{
	int hp = GetClientHealth(client);
	CreateIconCT(client, hp);
}

/***********************************************************/
/********************** CREATE HPBAR ***********************/
/***********************************************************/
int CreateIconT(int client, int hp)
{
	if (0 >= hp)
	{
		return false;
	}
	char iTarget[16];
	Format(iTarget, 16, "client%d", client);
	DispatchKeyValue(client, "targetname", iTarget);
	float origin[3];
	GetClientAbsOrigin(client, origin);

	if(SetCorrectBarHp(client))
	{
		origin[2] = origin[2] + SetCorrectBarHp(client);
	}
	else
	{
		origin[2] = origin[2] + 80;
	}
	
	int Ent = CreateEntityByName("env_sprite", -1);
	if (!Ent)
	{
		return false;
	}
	if (hp >= 100)
	{
		DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar100_red.vmt");
	}
	else
	{
		if (hp >= 90)
		{
			DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar90_red.vmt");
		}
		else if (hp >= 80)
		{
			DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar80_red.vmt");
		}
		else if (hp >= 70)
		{
			DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar70_red.vmt");
		}
		else if (hp >= 60)
		{
			DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar60_red.vmt");
		}
		else if (hp >= 50)
		{
			DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar50_red.vmt");
		}
		else if (hp >= 40)
		{
			DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar40_red.vmt");
		}
		else if (hp >= 30)
		{
			DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar30_red.vmt");
		}
		else if (hp >= 20)
		{
			DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar20_red.vmt");
		}
		else
		{
			DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar10_red.vmt");
		}

	}
	
	char fadeout[32];
	IntToString(H_hpbar_fadeout_t, fadeout, 32);
	
	DispatchKeyValue(Ent, "classname", "hpbar");
	DispatchKeyValue(Ent, "fademaxdist", fadeout);
	DispatchKeyValue(Ent, "spawnflags", "1");
	DispatchKeyValue(Ent, "scale", "0.08");
	DispatchKeyValue(Ent, "rendermode", "1");
	DispatchKeyValue(Ent, "rendercolor", "255 255 255");
	DispatchSpawn(Ent);
	TeleportEntity(Ent, origin, NULL_VECTOR, NULL_VECTOR);
	SetVariantString(iTarget);
	AcceptEntityInput(Ent, "SetParent", Ent, Ent, 0);
	
	PrintToDev(B_cvar_active_hpbar_dev, "%s CREATE BAR T :%i", TAG_CHAT, hp);
				
	return EntIndexToEntRef(Ent);
}

/***********************************************************/
/********************* CREATE HPBAR CT *********************/
/***********************************************************/
int CreateIconCT(int client, int hp)
{
	if (0 >= hp)
	{
		return false;
	}
	char iTarget[16];
	Format(iTarget, 16, "client%d", client);
	DispatchKeyValue(client, "targetname", iTarget);
	float origin[3];
	GetClientAbsOrigin(client, origin);
	
	if(SetCorrectBarHp(client))
	{
		origin[2] = origin[2] + SetCorrectBarHp(client);
	}
	else
	{
		origin[2] = origin[2] + 80;
	}
	
	int Ent = CreateEntityByName("env_sprite", -1);
	if (!Ent)
	{
		return false;
	}
	if (hp >= 100)
	{
		DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar100_blue.vmt");
	}
	else
	{
		if (hp >= 90)
		{
			DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar90_blue.vmt");
		}
		else if (hp >= 80)
		{
			DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar80_blue.vmt");
		}
		else if (hp >= 70)
		{
			DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar70_blue.vmt");
		}
		else if (hp >= 60)
		{
			DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar60_blue.vmt");
		}
		else if (hp >= 50)
		{
			DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar50_blue.vmt");
		}
		else if (hp >= 40)
		{
			DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar40_blue.vmt");
		}
		else if (hp >= 30)
		{
			DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar30_blue.vmt");
		}
		else if (hp >= 20)
		{
			DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar20_blue.vmt");
		}
		else
		{
			DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar10_blue.vmt");
		}

	}
	
	char fadeout[32];
	IntToString(H_hpbar_fadeout_ct, fadeout, 32);
	
	DispatchKeyValue(Ent, "classname", "hpbar");
	DispatchKeyValue(Ent, "fademaxdist", fadeout);
	DispatchKeyValue(Ent, "spawnflags", "1");
	DispatchKeyValue(Ent, "scale", "0.08");
	DispatchKeyValue(Ent, "rendermode", "1");
	DispatchKeyValue(Ent, "rendercolor", "255 255 255");
	DispatchSpawn(Ent);
	TeleportEntity(Ent, origin, NULL_VECTOR, NULL_VECTOR);
	
	SetVariantString(iTarget);
	AcceptEntityInput(Ent, "SetParent", Ent, Ent, 0);
	
	return EntIndexToEntRef(Ent);
}

/***********************************************************/
/******************** CREATE HPBAR BOSS ********************/
/***********************************************************/
int CreateIconBoss(int client, int hp)
{
	if (0 >= hp)
	{
		return false;
	}
	char iTarget[16];
	Format(iTarget, 16, "client%d", client);
	DispatchKeyValue(client, "targetname", iTarget);
	float origin[3];
	GetClientAbsOrigin(client, origin);
	
	if(SetCorrectBarHp(client))
	{
		origin[2] = origin[2] + SetCorrectBarHp(client);
	}
	else
	{
		origin[2] = origin[2] + 80;
	}
	
	int Ent = CreateEntityByName("env_sprite", -1);
	if (!Ent)
	{
		return false;
	}
	if (hp >= 100)
	{
		DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar100_orange.vmt");
	}
	else
	{
		if (hp >= 90)
		{
			DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar90_orange.vmt");
		}
		else if (hp >= 80)
		{
			DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar80_orange.vmt");
		}
		else if (hp >= 70)
		{
			DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar70_orange.vmt");
		}
		else if (hp >= 60)
		{
			DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar60_orange.vmt");
		}
		else if (hp >= 50)
		{
			DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar50_orange.vmt");
		}
		else if (hp >= 40)
		{
			DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar40_orange.vmt");
		}
		else if (hp >= 30)
		{
			DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar30_orange.vmt");
		}
		else if (hp >= 20)
		{
			DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar20_orange.vmt");
		}
		else
		{
			DispatchKeyValue(Ent, "model", "materials/sprites/z4e/hpbar/hp_bar10_orange.vmt");
		}

	}
	char fadeout[32];
	IntToString(H_hpbar_fadeout_t, fadeout, 32);
	
	DispatchKeyValue(Ent, "classname", "hpbar");
	DispatchKeyValue(Ent, "fademaxdist", fadeout);
	DispatchKeyValue(Ent, "spawnflags", "1");
	//DispatchKeyValue(Ent, "scale", "0.08");
	DispatchKeyValue(Ent, "rendermode", "1");
	DispatchKeyValue(Ent, "rendercolor", "255 255 255");
	DispatchSpawn(Ent);
	TeleportEntity(Ent, origin, NULL_VECTOR, NULL_VECTOR);
	SetVariantString(iTarget);
	AcceptEntityInput(Ent, "SetParent", Ent, Ent, 0);
	return EntIndexToEntRef(Ent);
}

/***********************************************************/
/******************* SET CORRECT HPBAR *********************/
/***********************************************************/
int SetCorrectBarHp(int client)
{
	int height;
	GetClientModel(client, S_model_client, PLATFORM_MAX_PATH);
	
	for (int i = 0; i < max_skins; i++)
	{
		//LogMessage("S_model_client: %s, Model: %s, Height: %s", S_model_client, S_skins[i], S_skins_height[i]);
		
		if(StrEqual(S_model_client, S_skins[i], false))
		{
			height = StringToInt(S_skins_height[i]);
			return height;
		}
	}
	PrintToDev(B_cvar_active_hpbar_dev, "Height: %i, max: %i", height, max_skins);
	return 0;
}

/***********************************************************/
/************************ SHOWBAR T ************************/
/***********************************************************/
void ShowbarT(int client, int hp)
{
	int Ent = EntRefToEntIndex(icon[client]);
	if (hp >= 100)
	{
		SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar100_red.vmt");
	}
	else
	{
		if (hp >= 90)
		{
			SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar90_red.vmt");
		}
		else if (hp >= 80)
		{
			SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar80_red.vmt");
		}
		else if (hp >= 70)
		{
			SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar70_red.vmt");
		}
		else if (hp >= 60)
		{
			SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar60_red.vmt");
		}
		else if (hp >= 50)
		{
			SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar50_red.vmt");
		}
		else if (hp >= 40)
		{
			SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar40_red.vmt");
		}
		else if (hp >= 30)
		{
			SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar30_red.vmt");
		}
		else if (hp >= 20)
		{
			SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar20_red.vmt");
		}
		else
		{
			SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar10_red.vmt");
		}
	}
	PrintToDev(B_cvar_active_hpbar_dev, "%s SHOW BAR T :%i", TAG_CHAT, hp);
}

/***********************************************************/
/************************ SHOWBAR CT ***********************/
/***********************************************************/
void ShowbarCT(int client, int hp)
{
	int Ent = EntRefToEntIndex(icon[client]);
	if (hp >= 100)
	{
		SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar100_blue.vmt");
	}
	else
	{
		if (hp >= 90)
		{
			SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar90_blue.vmt");
		}
		else if (hp >= 80)
		{
			SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar80_blue.vmt");
		}
		else if (hp >= 70)
		{
			SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar70_blue.vmt");
		}
		else if (hp >= 60)
		{
			SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar60_blue.vmt");
		}
		else if (hp >= 50)
		{
			SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar50_blue.vmt");
		}
		else if (hp >= 40)
		{
			SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar40_blue.vmt");
		}
		else if (hp >= 30)
		{
			SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar30_blue.vmt");
		}
		else if (hp >= 20)
		{
			SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar20_blue.vmt");
		}
		else
		{
			SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar10_blue.vmt");
		}
	}
}

/***********************************************************/
/*********************** SHOWBAR BOSS **********************/
/***********************************************************/
void ShowbarBoss(int client, int hp)
{
	int Ent = EntRefToEntIndex(icon[client]);
	if (hp >= 100)
	{
		SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar100_orange.vmt");
	}
	else
	{
		if (hp >= 90)
		{
			SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar90_orange.vmt");
		}
		else if (hp >= 80)
		{
			SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar80_orange.vmt");
		}
		else if (hp >= 70)
		{
			SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar70_orange.vmt");
		}
		else if (hp >= 60)
		{
			SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar60_orange.vmt");
		}
		else if (hp >= 50)
		{
			SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar50_orange.vmt");
		}
		else if (hp >= 40)
		{
			SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar40_orange.vmt");
		}
		else if (hp >= 30)
		{
			SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar30_orange.vmt");
		}
		else if (hp >= 20)
		{
			SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar20_orange.vmt");
		}
		else
		{
			SetEntityModel(Ent, "materials/sprites/z4e/hpbar/hp_bar10_orange.vmt");
		}
	}
}
/***********************************************************/
/********************** CLEAR HP BAR ***********************/
/***********************************************************/
void ClearIcon(int client)
{
	if(icon[client])
	{
		int entity = EntRefToEntIndex(icon[client]);
		if (entity != -1)
		{
			AcceptEntityInput(entity, "Kill", -1, -1, 0);
		}
		icon[client] = 0;
	}
}

/***********************************************************/
/******************** CHECK ICON VALID *********************/
/***********************************************************/
bool IconValid(int client)
{
	if(icon[client])
	{
		int entity = EntRefToEntIndex(icon[client]);
		if (entity != -1)
		{
			return true;
		}
	}
	return false;
}

/***********************************************************/
/******************** TIMER CHECK LIFE *********************/
/***********************************************************/
public Action Timer_CheckLife(Handle timer, any client)
{
	if(Client_IsIngame(client))
	{
		life[client] = GetClientHealth(client);
		if (IconValid(client))
		{
			if(GetClientTeam(client) == CS_TEAM_CT && B_cvar_active_showbar_t)
			{
				ShowbarCT(client, 100);
			}
			else if(GetClientTeam(client) == CS_TEAM_T && B_cvar_active_showbar_ct)
			{	
				if(ZRiot_GetDayMax() == ZRiot_GetDay())
				{
					ShowbarBoss(client, 100);
				}
				else
				{
					ShowbarT(client, 100);
				}
			}
		}
		else
		{
			if(GetClientTeam(client) == CS_TEAM_CT && B_cvar_active_showbar_t)
			{
				icon[client] = CreateIconCT(client, 100);
			}
			else if(GetClientTeam(client) == CS_TEAM_T && B_cvar_active_showbar_ct)
			{	
				if(ZRiot_GetDayMax() == ZRiot_GetDay())
				{
					icon[client] = CreateIconBoss(client, 100);
				}
				else
				{
					icon[client] = CreateIconT(client, 100);
				}
			}
		}
	}
	
	IsPlayerSpawn = false;
	PrintToDev(B_cvar_active_hpbar_dev, "%s Client spawn, totalvie:%i hp", TAG_CHAT, life[client]);
	return Plugin_Continue;
}

/***********************************************************/
/********************** RESET ALL ************************/
/***********************************************************/
public Action ResetAll(Handle timer, any client)
{
	Timers[client] = INVALID_HANDLE;
	ClearIcon(client);
	return Plugin_Continue;
}

/***********************************************************/
/********************* LOAD FILE SETTING *******************/
/***********************************************************/
public void LoadSettings()
{
	char hc[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, hc, sizeof(hc), "configs/drapi/hpbar.cfg");
	
	Handle kv = CreateKeyValues("Skins");
	FileToKeyValues(kv, hc);
	
	max_skins = 0;
	
	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			if(KvGotoFirstSubKey(kv))
			{
				do
				{
					KvGetSectionName(kv, S_skins[max_skins], PLATFORM_MAX_PATH);
					//LogMessage("%s [%i]-Skins: %s", TAG_CHAT, max_skins, S_skins[max_skins]);
					
					KvGetString(kv, "height", S_skins_height[max_skins], PLATFORM_MAX_PATH);
					//LogMessage("%s [%i]-Height: %s", TAG_CHAT, max_skins, S_skins_height[max_skins]);
					
					max_skins++;
				}
				while (KvGotoNextKey(kv));
			}
			KvGoBack(kv);
		}
		while (KvGotoNextKey(kv));
	}
	CloseHandle(kv);
}

