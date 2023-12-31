/*   <DR.API THIRDPERSON> (c) by <De Battista Clint - (http://doyou.watch)   */
/*                                                                           */
/*                <DR.API THIRDPERSON> is licensed under a                   */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//***************************DR.API THIRDPERSON******************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[THIRDPERSON]-"

//***********************************//
//*************INCLUDE***************//
//***********************************//

//Include native
#include <sourcemod>
#include <clientprefs>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle sv_allow_thirdperson;
Handle H_cookie_thirdperson;

int C_ThirdPerson[MAXPLAYERS+1] = false;

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API THIRDPERSON",
	author = "Dr. Api",
	description = "DR.API THIRDPERSON by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://doyou.watch"
}

/***********************************************************/
/*********************** PLUGIN LOAD 2 *********************/
/***********************************************************/
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("IsPlayerInTP", Native_IsPlayerInTP);
	CreateNative("TogglePlayerTP", Native_TogglePlayerTP);
	CreateNative("SetPlayerThird", Native_SetPlayerThird);
	CreateNative("SetPlayerFirst", Native_SetPlayerFirst);

	return APLRes_Success;
}

/***********************************************************/
/*********************** NATIVE IS TP **********************/
/***********************************************************/
public int Native_IsPlayerInTP(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return C_ThirdPerson[client];
}

/***********************************************************/
/********************* NATIVE TOGGLE TP ********************/
/***********************************************************/
public int Native_TogglePlayerTP(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	C_ThirdPerson[client] = !C_ThirdPerson[client];
	ToggleThirdPerson(client);
}

/***********************************************************/
/********************* NATIVE SET THIRD ********************/
/***********************************************************/
public int Native_SetPlayerThird(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	SetThirdPerson(client, true);
}

/***********************************************************/
/********************* NATIVE SET FIRST ********************/
/***********************************************************/
public int Native_SetPlayerFirst(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	SetThirdPerson(client, false);
}

/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	CreateConVar("drapi_thirdperson_version", PLUGIN_VERSION, "Version", CVARS);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	sv_allow_thirdperson = FindConVar("sv_allow_thirdperson");
	
	H_cookie_thirdperson = RegClientCookie("ThirdPerson", "Store view", CookieAccess_Private);
	
	RegConsoleCmd("tp", Command_ThirdPerson);
}

/***********************************************************/
/******************** WHEN COOKIE CACHED *******************/
/***********************************************************/
public void OnClientCookiesCached(int client)
{
	char value[16];
	GetClientCookie(client, H_cookie_thirdperson, value, sizeof(value));
	if(strlen(value) > 0) C_ThirdPerson[client] = StringToInt(value);
}

/***********************************************************/
/**************** WHEN CLIENT PUT IN SERVER ****************/
/***********************************************************/
public void OnClientConnected(int client)
{
	C_ThirdPerson[client] = false;
}

/***********************************************************/
/******************* WHEN PLAYER SPAWN *********************/
/***********************************************************/
public void Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(C_ThirdPerson[client])
		{
			SetThirdPerson(client, true);
		}
	}
	
	return Plugin_Handled;
}

/***********************************************************/
/******************** COMMAND THIRDPERSON ******************/
/***********************************************************/
public Action Command_ThirdPerson(int client, int args)
{
	C_ThirdPerson[client] = !C_ThirdPerson[client];
	ToggleThirdPerson(client);
	return Plugin_Handled;
}

/***********************************************************/
/******************** TOGGLE THIRDPERSON *******************/
/***********************************************************/
stock void ToggleThirdPerson(int client)
{
	if(C_ThirdPerson[client])
	{
		SetThirdPerson(client, true);
	}
	else
	{
		SetThirdPerson(client, false);
	}
}

/***********************************************************/
/********************* SET THIRDPERSON *********************/
/***********************************************************/
stock void SetThirdPerson(int client, bool tp)
{
	SetConVarInt(sv_allow_thirdperson, 1);
	
	if(tp)
	{
		ClientCommand(client, "thirdperson");
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
		//SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
		//SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
		C_ThirdPerson[client] = true;
		SetClientCookie(client, H_cookie_thirdperson, "1");
	}
	else
	{
		ClientCommand(client, "firstperson");
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", client);
		//SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
		//SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		C_ThirdPerson[client] = false;
		SetClientCookie(client, H_cookie_thirdperson, "0");
	}
}