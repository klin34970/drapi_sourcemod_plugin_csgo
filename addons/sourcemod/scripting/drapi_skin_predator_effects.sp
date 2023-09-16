/*          <DR.API SKIN PREDATOR EFFECTS> (c) by <De Battista Clint         */
/*                                                                           */
/*             <DR.API SKIN PREDATOR EFFECTS> is licensed under a            */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//***********************DR.API SKIN PREDATOR EFFECTS************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[SKIN PREDATOR EFFECTS] -"

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <autoexec>
#include <cstrike>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_skin_predator_effects_dev;

//Bool
bool B_active_skin_predator_effects_dev											= false;

//Strings
static char M_PURPLELASER[] 											= "materials/sprites/purplelaser1.vmt";

//Customs
int M_PURPLELASER_PRECACHED;

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API SKIN PREDATOR EFFECTS",
	author = "Dr. Api",
	description = "DR.API SKIN PREDATOR EFFECTS by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://zombie4ever.eu"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	AutoExecConfig_SetFile("drapi_skin_predator_effects", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_skin_predator_effects_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_skin_predator_effects_dev			= AutoExecConfig_CreateConVar("drapi_active_skin_predator_effects_dev", 			"0", 					"Enable/Disable Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	HookEventsCvars();
	
	AutoExecConfig_ExecuteFile();
	
	HookEvent("bullet_impact", 	Event_BulletImpact, EventHookMode_Pre);
	
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if(IsClientInGame(i)) 
			{
				SDKHook(i, SDKHook_WeaponSwitch, OnWeaponSwitch);
			}
		}
		i++;
	}
	
	SetConVarBool(FindConVar("sv_disable_immunity_alpha"), true);
	
}

/***********************************************************/
/************************ PLUGIN END ***********************/
/***********************************************************/
public void OnPluginEnd()
{
	int i = 1;
	while(i <= MaxClients)
	{
		if(IsClientInGame(i))
		{
			SDKUnhook(i, SDKHook_WeaponSwitch, OnWeaponSwitch);
		}
		i++;
	}
}

/***********************************************************/
/**************** WHEN CLIENT PUT IN SERVER ****************/
/***********************************************************/
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}

/***********************************************************/
/***************** WHEN CLIENT DISCONNECT ******************/
/***********************************************************/
public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEventsCvars()
{
	HookConVarChange(cvar_active_skin_predator_effects_dev, 				Event_CvarChange);
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
	B_active_skin_predator_effects_dev 					= GetConVarBool(cvar_active_skin_predator_effects_dev);
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public void OnMapStart()
{
	SetConVarBool(FindConVar("sv_disable_immunity_alpha"), true);
	M_PURPLELASER_PRECACHED = PrecacheModel(M_PURPLELASER);
	UpdateState();
}

/***********************************************************/
/******************** ON WEAPON SWITCH *********************/
/***********************************************************/
public Action OnWeaponSwitch(int client, int weapon)
{
	char model[PLATFORM_MAX_PATH];
	GetClientModel(client, model, sizeof(model));
	
	if(StrEqual(model, "models/player/custom/predatormkx/predatormkx.mdl", false))
	{
		char Sweapon[64];
		if(GetEdictClassname(weapon, Sweapon, sizeof(Sweapon)))
		{
			if(StrEqual(Sweapon, "weapon_knife", false))
			{
				SetEntityRenderColor(client, 150, 150, 150, 50);
				SetEntityRenderMode(client, RENDER_GLOW);
			}
			else
			{
				SetEntityRenderColor(client, 255, 255, 255, 255);
				SetEntityRenderMode(client, RENDER_NORMAL);
			}
		}
	}
}

/***********************************************************/
/********************** BULLET IMPACT **********************/
/***********************************************************/
public void Event_BulletImpact(Handle event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	char model[PLATFORM_MAX_PATH];
	GetClientModel(client, model, sizeof(model));
	
	if(StrEqual(model, "models/player/custom/predatormkx/predatormkx.mdl", false))
	{	
		float x = GetEventFloat(event, "x");
		float y = GetEventFloat(event, "y");
		float z = GetEventFloat(event, "z");

		float start[3];
		start[0] = x;
		start[1] = y;
		start[2] = z;

		float end[3];
		end[0] = x;
		end[1] = y;
		end[2] = z;

		Setlaser(client, start, end);
	}
	
	
}

/***********************************************************/
/************************ SET LASER ************************/
/***********************************************************/
void Setlaser(int client, float start[3], float end[3])
{
	// Current player's EYE position
	float playerPos[3];
	GetClientEyePosition(client, playerPos);

	float lineVector[3];
	SubtractVectors(playerPos, start, lineVector);
	NormalizeVector(lineVector, lineVector);

	// Offset
	ScaleVector(lineVector, 20.0);
	// Find starting point to draw line from
	SubtractVectors(playerPos, lineVector, start);
	
	TE_SetupBeamPoints(start, end, M_PURPLELASER_PRECACHED, 0, 0, 0, 1.0, 1.0, 1.0, 1, 0.0, {255,0,0,255}, 0);
	TE_SendToAll();
	
	TE_SetupExplosion(end, M_PURPLELASER_PRECACHED, 10.0, 1, 0, 600, 5000);
	TE_SendToClient(client);
	
}



