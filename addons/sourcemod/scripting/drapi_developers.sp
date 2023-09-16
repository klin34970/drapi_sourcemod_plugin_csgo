/*    <DR.API DEVELOPERS> (c) by <De Battista Clint - (http://doyou.watch)   */
/*                                                                           */
/*                   <DR.API DEVELOPERS> is licensed under a                 */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//*****************************DR.API DEVELOPERS*****************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[DEVELOPERS] -"

//***********************************//
//*************INCLUDE***************//
//***********************************//

//Include native
#undef REQUIRE_PLUGIN
#include <stocks>
#include <drapi_zombie_riot>
#include <customplayerskins>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_developers_dev;

//Bool
bool B_cvar_active_developers_dev					= false;

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API DEVELOPERS",
	author = "Dr. Api",
	description = "DR.API DEVELOPERS by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://doyou.watch"
}

/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	FindOffsets();
	CreateConVar("drapi_developers_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_developers_dev						= CreateConVar("drapi_active_developers_dev", 			"1", 					"Enable/Disable Bot Dev Mod", 											DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	RegAdminCmd("sm_health", 	Command_Health, ADMFLAG_CHANGEMAP, "");
	RegAdminCmd("sm_windex", 	Command_WeaponsIndex, ADMFLAG_CHANGEMAP, "");
	
	RegAdminCmd("sm_ct", 		Command_CT, ADMFLAG_CHANGEMAP, "");
	RegAdminCmd("sm_t", 		Command_T, ADMFLAG_CHANGEMAP, "");
	
	RegAdminCmd("sm_myskin", 	Command_GetSkin, ADMFLAG_CHANGEMAP, "");
	
	RegAdminCmd("sm_crazy", 	Command_Crazy, ADMFLAG_CHANGEMAP, "");
	
	RegAdminCmd("sm_entity", 	Command_Entities, ADMFLAG_CHANGEMAP, "");
	
	RegAdminCmd("sm_sky", 		Command_Sky, ADMFLAG_CHANGEMAP, "");
	
	RegAdminCmd("sm_speed", 	Command_Speed, ADMFLAG_CHANGEMAP, "");
	
	RegAdminCmd("sm_sm", 		Command_Slowmotion, ADMFLAG_CHANGEMAP, "");
	
	RegAdminCmd("sm_proto", 	Command_Proto, ADMFLAG_CHANGEMAP, "");
	
	RegAdminCmd("sm_tmenu", 	Command_Tmenu, ADMFLAG_CHANGEMAP, "");
	
	HookEvents();
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEvents()
{
	HookConVarChange(cvar_active_developers_dev, 				Event_CvarChange);
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
	B_cvar_active_developers_dev 					= GetConVarBool(cvar_active_developers_dev);
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
	PrecacheModel("models/player/me3/collector_drone/collector_drone.mdl", true);
	UpdateState();
}

/***********************************************************/
/**************************** PROTO ************************/
/***********************************************************/
public Action Command_Tmenu(int client, int args)
{
	Menu menu = CreateMenu(MenuActionTest);

	menu.SetTitle("1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890");
	AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
	SetMenuExitBackButton(menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
}
public int MenuActionTest(Menu menu, MenuAction action, int param1, int param2)
{

}
/***********************************************************/
/**************************** PROTO ************************/
/***********************************************************/
public Action Command_Proto(int client, int args)
{
	
	Handle hFade = INVALID_HANDLE;
	hFade = StartMessageOne("MarkAchievement", client);
	if (hFade != INVALID_HANDLE)
	{
		PbSetString(hFade, "achievement", "WR");
		EndMessage();
	}
}

/***********************************************************/
/************************** SET LIGHT **********************/
/***********************************************************/
public Action Command_Slowmotion(int client, int args)
{
	char S_args1[256];
	GetCmdArg(1, S_args1, sizeof(S_args1));
	
	SendConVarValue(client, FindConVar("host_timescale"), S_args1);
}

/***********************************************************/
/************************** SET LIGHT **********************/
/***********************************************************/
public Action Command_Speed(int client, int args)
{
	char S_args1[256];
	GetCmdArg(1, S_args1, sizeof(S_args1));
	
	SetPlayerSpeed(client, StringToFloat(S_args1));
}

/***********************************************************/
/*************************** SET SKY ***********************/
/***********************************************************/
public Action Command_Sky(int client, int args)
{
	char S_args1[256];
	GetCmdArg(1, S_args1, sizeof(S_args1));
	
	ServerCommand("sv_skyname %s", S_args1);
}

/***********************************************************/
/************************* SET HEALTH **********************/
/***********************************************************/
public Action Command_Health(int client, int args)
{
	if(args)
	{
		char S_args1[256];
		GetCmdArg(1, S_args1, sizeof(S_args1));
		
		SetEntProp(client, Prop_Data, "m_iHealth", StringToInt(S_args1));
		SetEntProp(client, Prop_Data, "m_iMaxHealth", StringToInt(S_args1));
	}
	return Plugin_Handled;
}

/***********************************************************/
/********************* GET WEAPON INDEX ********************/
/***********************************************************/
public Action Command_WeaponsIndex(int client, int args)
{
	//int iItem = GivePlayerItem(client, "weapon_knife_falchion");
	//EquipPlayerWeapon(client, iItem);
	int weapon 				= GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	int index 				= GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	
	PrintToChat(client, "index: %i", index);
	return Plugin_Handled;
}

/***********************************************************/
/************************** SET CT *************************/
/***********************************************************/
public Action Command_CT(int client, int args)
{
	ZRiot_Human(client);
	return Plugin_Handled;
}

/***********************************************************/
/*************************** SET T *************************/
/***********************************************************/
public Action Command_T(int client, int args)
{
	ZRiot_Zombie(client);
	return Plugin_Handled;
}

/***********************************************************/
/*************************** SET T *************************/
/***********************************************************/
public Action Command_GetSkin(int client, int args)
{
	char S_name_skin[256];
	GetClientModel(client, S_name_skin, sizeof(S_name_skin));
	
	PrintToChat(client, "%s Your skin: %s", TAG_CHAT, S_name_skin);
	return Plugin_Handled;
}

/***********************************************************/
/*************************** CRAZY *************************/
/***********************************************************/
public Action Command_Crazy(int client, int args)
{
	SetEntityModel(client, "models/player/me3/collector_drone/collector_drone.mdl");
	CreateTimer(0.5, Timer_Color, client, TIMER_REPEAT);
}

public Action Timer_Color(Handle timer, any client)
{
	if(Client_IsIngame(client) && IsPlayerAlive(client))
	{
		int red 	= GetRandomInt(0, 100);
		int green 	= GetRandomInt(0, 100);
		int blue 	= GetRandomInt(200, 255);
		
		SetEntityRenderColor(client, red, green, blue, 255);
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Handled;
}

/***********************************************************/
/*********************** FIND ENTITIES *********************/
/***********************************************************/
public Action Command_Entities(int client, int args)
{
	FindMapEntities();
}

void FindMapEntities() 
{ 
	int maxEnts = GetMaxEntities(); 
	char classname[128]; 
	int count = 0;
	for(int i = MaxClients; i < maxEnts; i++) 
	{ 
		if(IsValidEdict(i)) 
		{ 
			GetEdictClassname(i, classname, sizeof(classname)); 
			LogMessage("%sEntities found: %s", TAG_CHAT, classname); 
			count++;			
		} 
	} 
	LogMessage("%s Entities: %i", TAG_CHAT, count); 
} 