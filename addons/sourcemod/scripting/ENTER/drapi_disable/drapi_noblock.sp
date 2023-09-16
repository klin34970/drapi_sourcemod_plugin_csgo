/*    <DR.API NO BLOCK> (c) by <De Battista Clint - (http://doyou.watch)     */
/*                                                                           */
/*                    <DR.API NO BLOCK> is licensed under a                  */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//******************************DR.API NO BLOCK******************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[NO BLOCK] -"

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

//Handle
Handle cvar_active_no_block_dev;

Handle cvar_no_block_grenade;

//Bool
bool B_cvar_active_no_block_dev					= false;

bool B_no_block_grenade							= false;

bool B_NoBlock									= false;
bool B_Collide[MAXPLAYERS + 1]					= false;

//Customs
int m_CollisionGroupEx;

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API NO BLOCK",
	author = "Dr. Api",
	description = "DR.API NO BLOCK by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://doyou.watch"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	m_CollisionGroupEx = FindSendPropInfo("CBaseEntity", "m_CollisionGroup"); 
	
	AutoExecConfig_SetFile("drapi_no_block", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_no_block_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_no_block_dev			= AutoExecConfig_CreateConVar("drapi_active_no_block_dev", 				"0", 					"Enable/Disable Dev Mod", 					DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	cvar_no_block_grenade				= AutoExecConfig_CreateConVar("drapi_no_block_grenade", 				"1", 					"Enable/Disable Collision for grenades", 	DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	HookEvent("round_start",	Event_RoundStart);
	HookEvent("player_spawn", 	Event_PlayerSpawn);	
	
	HookEvents();
	
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			SDKHook(i, SDKHook_StartTouch, StartTouch);
			//SDKHook(i, SDKHook_EndTouch, EndTouch);
		}
		i++;
	}
	
	AutoExecConfig_ExecuteFile();
}

/***********************************************************/
/*********************** PLUGIN END **********************/
/***********************************************************/
public void OnPluginEnd()
{
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			SDKUnhook(i, SDKHook_StartTouch, StartTouch);
			//SDKUnhook(i, SDKHook_EndTouch, EndTouch);
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
		SDKHook(client, SDKHook_StartTouch, StartTouch);
		//SDKHook(client, SDKHook_EndTouch, EndTouch);		
	}
}

/***********************************************************/
/***************** WHEN CLIENT DISCONNECT ******************/
/***********************************************************/
public void OnClientDisconnect(int client)
{	
	SDKUnhook(client, SDKHook_StartTouch, StartTouch);
	//SDKUnhook(client, SDKHook_EndTouch, EndTouch);
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEvents()
{
	HookConVarChange(cvar_active_no_block_dev, 				Event_CvarChange);
	
	HookConVarChange(cvar_no_block_grenade, 				Event_CvarChange);
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
	B_cvar_active_no_block_dev 					= GetConVarBool(cvar_active_no_block_dev);
	
	B_no_block_grenade 							= GetConVarBool(cvar_no_block_grenade);
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
}

/***********************************************************/
/******************** WHEN ROUND START *********************/
/***********************************************************/
public void Event_RoundStart(Handle event, char[] name, bool dontBroadcast)
{
	AllowNoBlock();
}

/***********************************************************/
/*********************** PLAYER SPAWN **********************/
/***********************************************************/
public void Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	SetEntData(client, m_CollisionGroupEx, 2, 4, true);
	B_Collide[client] = false;
}

/***********************************************************/
/************************ START TOUCH **********************/
/***********************************************************/
public void StartTouch(int entity, int other)
{
	if(B_NoBlock)
	{
		if(Client_IsIngame(entity) && IsPlayerAlive(entity))
		{
			if(Client_IsIngame(other) && IsPlayerAlive(other))
			{
				if(GetClientTeam(entity) != GetClientTeam(other))
				{
					if(!B_Collide[entity])
					{
						SetEntData(entity, m_CollisionGroupEx, 5, 4, true);
						B_Collide[entity] = true;
						
						PrintToDev(B_cvar_active_no_block_dev, "%s ME START TOUCH TEAM DIFF", TAG_CHAT);
					}
					
					if(!B_Collide[other])
					{
						SetEntData(other, m_CollisionGroupEx, 5, 4, true);
						B_Collide[other] = true;
						
						PrintToDev(B_cvar_active_no_block_dev, "%s OTHER START TOUCH TEAM DIFF", TAG_CHAT);
					}
					
					
				}
				else
				{
					if(B_Collide[entity])
					{
						SetEntData(entity, m_CollisionGroupEx, 2, 1, true);
						B_Collide[entity] = false;
						
						PrintToDev(B_cvar_active_no_block_dev, "%s ME START TOUCH TEAM SAME", TAG_CHAT);
					}
					
					if(B_Collide[other])
					{
						SetEntData(other, m_CollisionGroupEx, 2, 1, true);
						B_Collide[other] = false;
						
						PrintToDev(B_cvar_active_no_block_dev, "%s OTHER START TOUCH TEAM SAME", TAG_CHAT);
					}
					
				}
			}
		}
	}
}

/***********************************************************/
/************************* END TOUCH ***********************/
/***********************************************************/
/*
public void EndTouch(int entity, int other)
{
	if(B_NoBlock)
	{
		if(Client_IsIngame(entity) && IsPlayerAlive(entity))
		{
			if(Client_IsIngame(other) && IsPlayerAlive(other))
			{
				if(GetClientTeam(entity) != GetClientTeam(other))
				{
					SetEntData(entity, m_CollisionGroupEx, 2, 1, true);
					SetEntData(other, m_CollisionGroupEx, 2, 1, true);
					
					PrintToDev(B_cvar_active_no_block_dev, "%s END TOUCH", TAG_CHAT);
				}
			}
		}
	}
}
*/
/***********************************************************/
/******************** ON ENTITY CREATED ********************/
/***********************************************************/
public int OnEntityCreated(int entity, const char[] classname)
{
	if (B_no_block_grenade)
	{
		if (StrEqual(classname, "hegrenade_projectile"))
		{
			SetEntData(entity, m_CollisionGroupEx, 2, 1, true);
			SDKHook(entity, SDKHook_ShouldCollide, ShouldCollide);
		}

		if (StrEqual(classname, "flashbang_projectile"))
		{
			SetEntData(entity, m_CollisionGroupEx, 2, 1, true);
			SDKHook(entity, SDKHook_ShouldCollide, ShouldCollide);
		}

		if (StrEqual(classname, "smokegrenade_projectile"))
		{
			SetEntData(entity, m_CollisionGroupEx, 2, 1, true);
			SDKHook(entity, SDKHook_ShouldCollide, ShouldCollide);
		}

		if (StrEqual(classname, "decoy_projectile"))
		{
			SetEntData(entity, m_CollisionGroupEx, 2, 1, true);
			SDKHook(entity, SDKHook_ShouldCollide, ShouldCollide);
		}

		if (StrEqual(classname, "molotov_projectile"))
		{
			SetEntData(entity, m_CollisionGroupEx, 2, 1, true);
			SDKHook(entity, SDKHook_ShouldCollide, ShouldCollide);
		}
		
		//PrintToDev(B_cvar_active_no_block_dev, "%s Create: %s", TAG_CHAT, classname);
	}
}

/***********************************************************/
/********************** SHOULD COLLIDE *********************/
/***********************************************************/
public bool ShouldCollide(int entity, int collisiongroup, int contentsmask, bool originalResult)
{
        return false;
}
 
/***********************************************************/
/******************** ALLOW ZOMBIES POWERS *****************/
/***********************************************************/
void AllowNoBlock()
{
	if(ZRiot_GetDayMax() == ZRiot_GetDay())
	{
		B_NoBlock = false;
	}
	else
	{
		B_NoBlock = true;
	}
}