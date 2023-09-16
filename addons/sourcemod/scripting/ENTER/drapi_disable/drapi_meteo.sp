/*       <DR.API METEO> (c) by <De Battista Clint - (http://doyou.watch)     */
/*                                                                           */
/*                     <DR.API METEO> is licensed under a                    */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//*******************************DR.API METEO********************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[METEO] -"
#define MAX_HOURS 						24
#define MAX_FOG							16

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <autoexec>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_meteo_dev;

Handle KvHours 													= INVALID_HANDLE;
Handle sv_skyname;

//Bool
bool B_cvar_active_meteo_dev									= false;

bool B_FogOn;

//Strings
char data_light[MAX_HOURS][64];
char data_fog_color[MAX_HOURS][64];
char data_background_color[MAX_HOURS][12];

char S_FogFromMap[MAX_FOG][64];

//Floats
float INT_GET_TIME;
float data_time[MAX_HOURS];
float data_fog_opaque_idle[MAX_HOURS];
float data_fog_opaque_storm[MAX_HOURS];
float data_fog_sky_opaque[MAX_HOURS];
float F_FogFromMap[MAX_FOG][9]; 


//Customs
int INT_TOTAL_HOURS;
int INT_CURRENT_HOURS;
int C_Fog														= INVALID_ENT_REFERENCE;
int C_LogicIn													= INVALID_ENT_REFERENCE;
int C_LogicOut													= INVALID_ENT_REFERENCE;
int C_SkyCamera													= INVALID_ENT_REFERENCE;
int C_PostProcess												= INVALID_ENT_REFERENCE;
int C_FogVolume													= INVALID_ENT_REFERENCE;
int C_SkyNoise													= INVALID_ENT_REFERENCE;
int C_FogFromMap[MAX_FOG][5];
int C_SkyCam[2];

int data_fog_blend[MAX_HOURS];
int data_fog_farz[MAX_HOURS];
int data_far_z_storm[MAX_HOURS];
int data_fog_storm[MAX_HOURS];
int data_fog_storm_start[MAX_HOURS];
int data_fog_idle_start[MAX_HOURS];
int data_fog_idle[MAX_HOURS];
int data_fog_sky_start[MAX_HOURS];		
int data_fog_sky[MAX_HOURS];


//Informations plugin
public Plugin myinfo =
{
	name = "DR.API METEO",
	author = "Dr. Api",
	description = "DR.API METEO by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://doyou.watch"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	AutoExecConfig_SetFile("drapi_meteo", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_meteo_version", PLUGIN_VERSION, "Version", CVARS);
	
	sv_skyname = FindConVar("sv_skyname");
	
	cvar_active_meteo_dev			= AutoExecConfig_CreateConVar("drapi_active_meteo_dev", 			"1", 					"Enable/Disable Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	HookEvents();
	
	RegAdminCmd(	"sm_maplight",			Command_MapLight,			ADMFLAG_CHANGEMAP,	"Set the maps lighting");
	RegAdminCmd(	"sm_sky",				Command_MapSky,				ADMFLAG_CHANGEMAP,	"Set the maps sky");
	RegAdminCmd(	"sm_background",		Command_MapBackGround,		ADMFLAG_CHANGEMAP,	"Set the maps background");
	RegAdminCmd(	"sm_farz",				Command_MapFarZ,			ADMFLAG_CHANGEMAP,	"Set the maps farz");
	RegAdminCmd(	"sm_fog",				Command_MapFog,				ADMFLAG_CHANGEMAP,	"Set the maps fog");
	RegAdminCmd(	"sm_middle",			Command_MapMiddle,			ADMFLAG_CHANGEMAP,	"Set the maps middle");
	
	RegAdminCmd(	"sm_hour",				Command_MapHour,			ADMFLAG_CHANGEMAP,	"Set the maps hour");
	
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
		}
		i++;
	}
}

/***********************************************************/
/**************** WHEN CLIENT PUT IN SERVER ****************/
/***********************************************************/
public void OnClientPutInServer(int client)
{

}

/***********************************************************/
/***************** WHEN CLIENT DISCONNECT ******************/
/***********************************************************/
public void OnClientDisconnect(int client)
{

}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEvents()
{
	HookConVarChange(cvar_active_meteo_dev, 				Event_CvarChange);
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
	B_cvar_active_meteo_dev 					= GetConVarBool(cvar_active_meteo_dev);
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
	LoadDayData(true, "configs/drapi");
	InitialiseMeteo();
	UpdateState();
}

/***********************************************************/
/********************** ON GAME FRAME **********************/
/***********************************************************/
public void OnGameFrame()
{
	//ChangeMeteo();
}


/**************************************************************LIGHTMAP**************************************************************/
void ChangeLightStyle(char[] lightstring, int client = 0)
{
	int style = 1;
	if(strcmp(lightstring, "") != 0)
	{
		SetLightStyle(0, lightstring);

		// This refreshes and updates the entire map with the new light style.
		int entity = CreateEntityByName("light_dynamic");

		DispatchKeyValue(entity, "_light", "0 0 0 0");
		DispatchKeyValue(entity, "brightness", "0");
		DispatchKeyValue(entity, "style", "13");
		DispatchKeyValue(entity, "distance", "19999");
		DispatchSpawn(entity);

		if(client)
		{
			SetEntProp(entity, Prop_Data, "m_iHammerID", client);
			SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmitLight);
		}

		if(style == 0)
		{
			float vPos[3], vMins[3], vMaxs[3];
			GetEntPropVector(0, Prop_Data, "m_WorldMins", vMins);
			GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vMaxs);
			vPos[0] = (vMins[0] + vMaxs[0]) / 2;
			vPos[1] = (vMins[1] + vMaxs[1]) / 2;
			vPos[2] = vMaxs[2] + 2000.0;
			TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

			AcceptEntityInput(entity, "TurnOn");
			SetVariantString("OnUser1 !self:TurnOff::0.2:-1");
			AcceptEntityInput(entity, "AddOutput");
			SetVariantString("OnUser1 !self:TurnOff::0.3:-1");
			AcceptEntityInput(entity, "AddOutput");
			SetVariantString("OnUser1 !self:TurnOff::0.4:-1");
			AcceptEntityInput(entity, "AddOutput");
			SetVariantString("OnUser1 !self:Kill::0.5:-1");
			AcceptEntityInput(entity, "AddOutput");
			AcceptEntityInput(entity, "FireUser1");
		}
		else
		{
			if(style == 1)
			{
				SetVariantString("OnUser1 !self:TurnOff::0.7:-1");
				AcceptEntityInput(entity, "AddOutput");
				SetVariantString("OnUser1 !self:TurnOff::0.8:-1");
				AcceptEntityInput(entity, "AddOutput");
				SetVariantString("OnUser1 !self:Kill::1.0:-1");
				AcceptEntityInput(entity, "AddOutput");
				AcceptEntityInput(entity, "FireUser1");

				SetVariantString("OnUser3 !self:FireUser2::0.05:-1");
				AcceptEntityInput(entity, "AddOutput");
				SetVariantString("OnUser3 !self:FireUser2::0.10:-1");
				AcceptEntityInput(entity, "AddOutput");
				SetVariantString("OnUser3 !self:FireUser2::0.15:-1");
				AcceptEntityInput(entity, "AddOutput");
				SetVariantString("OnUser3 !self:FireUser2::0.20:-1");
				AcceptEntityInput(entity, "AddOutput");
				SetVariantString("OnUser3 !self:FireUser2::0.25:-1");
				AcceptEntityInput(entity, "AddOutput");
				SetVariantString("OnUser3 !self:FireUser2::0.30:-1");
				AcceptEntityInput(entity, "AddOutput");
				SetVariantString("OnUser3 !self:FireUser2::0.35:-1");
				AcceptEntityInput(entity, "AddOutput");
				SetVariantString("OnUser3 !self:FireUser2::0.40:-1");
				AcceptEntityInput(entity, "AddOutput");
				SetVariantString("OnUser3 !self:FireUser2::0.45:-1");
				AcceptEntityInput(entity, "AddOutput");
			}
			else
			{
				SetVariantString("OnUser1 !self:TurnOff::1.2:-1");
				AcceptEntityInput(entity, "AddOutput");
				SetVariantString("OnUser1 !self:TurnOff::1.3:-1");
				AcceptEntityInput(entity, "AddOutput");
				SetVariantString("OnUser1 !self:Kill::1.5:-1");
				AcceptEntityInput(entity, "AddOutput");
				AcceptEntityInput(entity, "FireUser1");

				SetVariantString("OnUser3 !self:FireUser2::0.1:-1");
				AcceptEntityInput(entity, "AddOutput");
				SetVariantString("OnUser3 !self:FireUser2::0.2:-1");
				AcceptEntityInput(entity, "AddOutput");
				SetVariantString("OnUser3 !self:FireUser2::0.3:-1");
				AcceptEntityInput(entity, "AddOutput");
				SetVariantString("OnUser3 !self:FireUser2::0.4:-1");
				AcceptEntityInput(entity, "AddOutput");
				SetVariantString("OnUser3 !self:FireUser2::0.5:-1");
				AcceptEntityInput(entity, "AddOutput");
				SetVariantString("OnUser3 !self:FireUser2::0.6:-1");
				AcceptEntityInput(entity, "AddOutput");
				SetVariantString("OnUser3 !self:FireUser2::0.7:-1");
				AcceptEntityInput(entity, "AddOutput");
				SetVariantString("OnUser3 !self:FireUser2::0.8:-1");
				AcceptEntityInput(entity, "AddOutput");
				SetVariantString("OnUser3 !self:FireUser2::0.9:-1");
				AcceptEntityInput(entity, "AddOutput");
			}

			SetEntProp(entity, Prop_Data, "m_iHealth", 1);
			HookSingleEntityOutput(entity, "OnUser2", OnUser2);
			AcceptEntityInput(entity, "FireUser3");
		}
	}
}

public Action Hook_SetTransmitLight(int entity, int client)
{
	if(GetEntProp(entity, Prop_Data, "m_iHammerID") == client)
	{
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

public void OnUser2(const char[] output, int entity, int activator, float delay)
{
	int corner = GetEntProp(entity, Prop_Data, "m_iHealth");
	SetEntProp(entity, Prop_Data, "m_iHealth", corner + 1);


	float vPos[3], vMins[3], vMaxs[3];
	GetEntPropVector(0, Prop_Data, "m_WorldMins", vMins);
	GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vMaxs);

	if(corner == 1)
	{
		AcceptEntityInput(entity, "TurnOff");
		vPos[0] = (vMins[0] + vMaxs[0]) / 2;
		vPos[1] = (vMins[1] + vMaxs[1]) / 2;
		vPos[2] = vMaxs[2] += 2000.0;
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "TurnOn");
	}
	else if(corner == 2)
	{
		AcceptEntityInput(entity, "TurnOff");
		vPos[0] = vMins[0];
		vPos[1] = vMins[1];
		vPos[2] = vMins[2];
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "TurnOn");
	}
	else if(corner == 3)
	{
		AcceptEntityInput(entity, "TurnOff");
		vPos[0] = vMaxs[0];
		vPos[1] = vMins[1];
		vPos[2] = vMins[2];
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "TurnOn");
	}
	else if(corner == 4)
	{
		AcceptEntityInput(entity, "TurnOff");
		vPos[0] = vMins[0];
		vPos[1] = vMaxs[1];
		vPos[2] = vMins[2];
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "TurnOn");
	}
	else if(corner == 5)
	{
		AcceptEntityInput(entity, "TurnOff");
		vPos[0] = vMins[0];
		vPos[1] = vMins[1];
		vPos[2] = vMaxs[2];
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "TurnOn");
	}
	else if(corner == 6)
	{
		AcceptEntityInput(entity, "TurnOff");
		vPos[0] = vMaxs[0];
		vPos[1] = vMaxs[1];
		vPos[2] = vMins[2];
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "TurnOn");
	}
	else if(corner == 7)
	{
		AcceptEntityInput(entity, "TurnOff");
		vPos[0] = vMins[0];
		vPos[1] = vMaxs[1];
		vPos[2] = vMaxs[2];
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "TurnOn");
	}
	else if(corner == 8)
	{
		AcceptEntityInput(entity, "TurnOff");
		vPos[0] = vMaxs[0];
		vPos[1] = vMins[1];
		vPos[2] = vMaxs[2];
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "TurnOn");
	}

	if(corner == 9)
	{
		AcceptEntityInput(entity, "TurnOff");
		vPos[0] = vMaxs[0];
		vPos[1] = vMaxs[1];
		vPos[2] = vMaxs[2];
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "TurnOn");

		corner = 0;
		SetVariantString("OnUser4 !self:TurnOff::0.2:-1");
		AcceptEntityInput(entity, "AddOutput");
		SetVariantString("OnUser4 !self:TurnOff::0.3:-1");
		AcceptEntityInput(entity, "AddOutput");
		SetVariantString("OnUser4 !self:Kill::0.5:-1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser4");
	}
}

stock void CheckDynamicLightStyle()
{
	int entity = -1;
	while((entity = FindEntityByClassname(entity, "light_dynamic")) != INVALID_ENT_REFERENCE)
	{
		if(GetEntProp(entity, Prop_Send, "m_LightStyle") == 0)
		{
			SetEntProp(entity, Prop_Send, "m_LightStyle", 13); // Style non-defined, appears just like 0.
		}
	}
}

public int OnEntityCreated(int entity, const char[] classname)
{
	if(strcmp(classname, "light_dynamic") == 0)
	{
		CreateTimer(0.0, TimerLight, EntIndexToEntRef(entity));
	}
}

public Action TimerLight(Handle timer, any entity)
{
	if(EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE)
	{
		if(GetEntProp(entity, Prop_Send, "m_LightStyle") == 0)
		{
			SetEntProp(entity, Prop_Send, "m_LightStyle", 13); // Style non-defined, appears just like 0.
		}
	}
}

void InitialiseMeteo()
{
	INT_CURRENT_HOURS = 0;
	char light[64];
	GetHourLight(INT_CURRENT_HOURS, light, sizeof(light));
	ChangeLightStyle(light);
	
	INT_GET_TIME = GetHourTime(INT_CURRENT_HOURS) + GetEngineTime();
}

void ChangeMeteo()
{
	float time = GetEngineTime();
	
	if(time >= INT_GET_TIME)
	{
		INT_GET_TIME = GetHourTime(INT_CURRENT_HOURS) + time + 20.0;
		
		//LIGHT
		char light[64];
		GetHourLight(INT_CURRENT_HOURS, light, sizeof(light));
		ChangeLightStyle(light);
		
		INT_CURRENT_HOURS++;
		
		if(INT_CURRENT_HOURS == INT_TOTAL_HOURS)
		{
			INT_CURRENT_HOURS 	= 0;
			INT_GET_TIME		= 0.0;
		}
		PrintToChatAll("%s Hour: %i, timeday: %i, EngineTimer: %f", TAG_CHAT, INT_CURRENT_HOURS, INT_GET_TIME, time);
	}
}

/**************************************************************SKY**************************************************************/
void SetSkyname(char[] skyname)
{
	if(strcmp(skyname, "") != 0)
	{
		SetConVarString(sv_skyname, skyname);
	}
}

/**************************************************************FOG**************************************************************/
void CreateFog()
{
	if(B_FogOn)
	{
		return;
	}
	B_FogOn = true;
	
	char sTemp[8];
	int entity = -1;
	int count;
	
	int fog_blend 				= GetHourFogBlend(INT_CURRENT_HOURS);
		
	char color[64];
	GetHourFogColor(INT_CURRENT_HOURS, color, sizeof(color));
		
	int far_z_idle 				= GetHourFogFarz(INT_CURRENT_HOURS);
		

	entity = -1;
	while((entity = FindEntityByClassname(entity, "env_fog_controller")) != INVALID_ENT_REFERENCE)
	{
		if(count < MAX_FOG)
		{
			GetEntPropString(entity, Prop_Data, "m_iName", S_FogFromMap[count], 64);
			C_FogFromMap[count][0] = EntIndexToEntRef(entity);
			C_FogFromMap[count][1] = GetEntProp(entity, Prop_Send, "m_fog.colorPrimary");
			C_FogFromMap[count][2] = GetEntProp(entity, Prop_Send, "m_fog.colorSecondary");
			C_FogFromMap[count][3] = GetEntProp(entity, Prop_Send, "m_fog.colorPrimaryLerpTo");
			C_FogFromMap[count][4] = GetEntProp(entity, Prop_Send, "m_fog.colorSecondaryLerpTo");
			F_FogFromMap[count][0] = GetEntPropFloat(entity, Prop_Send, "m_fog.start");
			F_FogFromMap[count][1] = GetEntPropFloat(entity, Prop_Send, "m_fog.end");
			F_FogFromMap[count][2] = GetEntPropFloat(entity, Prop_Send, "m_fog.maxdensity");
			F_FogFromMap[count][3] = GetEntPropFloat(entity, Prop_Send, "m_fog.farz");
			F_FogFromMap[count][5] = GetEntPropFloat(entity, Prop_Send, "m_fog.startLerpTo");
			F_FogFromMap[count][6] = GetEntPropFloat(entity, Prop_Send, "m_fog.endLerpTo");
			F_FogFromMap[count][7] = GetEntPropFloat(entity, Prop_Send, "m_fog.maxdensityLerpTo");
			F_FogFromMap[count][8] = GetEntPropFloat(entity, Prop_Send, "m_fog.duration");
			count++;
		}

		DispatchKeyValue(entity, "targetname", "stolen_fog_storm");
		DispatchKeyValue(entity, "use_angles", "1");
		DispatchKeyValue(entity, "fogstart", "1");
		DispatchKeyValue(entity, "fogmaxdensity", "1");
		DispatchKeyValue(entity, "heightFogStart", "0.0");
		DispatchKeyValue(entity, "heightFogMaxDensity", "1.0");
		DispatchKeyValue(entity, "heightFogDensity", "0.0");
		DispatchKeyValue(entity, "fogdir", "1 0 0");
		DispatchKeyValue(entity, "angles", "0 180 0");

		if(fog_blend != -1)
		{
			IntToString(fog_blend, sTemp, sizeof(sTemp));
			DispatchKeyValue(entity, "foglerptime", sTemp);
		}

		if(strcmp(color, ""))
		{
			DispatchKeyValue(entity, "fogcolor", color);
			DispatchKeyValue(entity, "fogcolor2", color);
			SetVariantString(color);
			AcceptEntityInput(entity, "SetColorLerpTo");
		}
		
		PrintToChatAll("%s Fog color: %s", TAG_CHAT, color);
	}

	if(count == 0)
	{
		C_Fog = CreateEntityByName("env_fog_controller");
		if(C_Fog != -1)
		{
			DispatchKeyValue(C_Fog, "targetname", "silver_fog_storm");
			DispatchKeyValue(C_Fog, "use_angles", "1");
			DispatchKeyValue(C_Fog, "fogstart", "1");
			DispatchKeyValue(C_Fog, "fogmaxdensity", "1");
			DispatchKeyValue(C_Fog, "heightFogStart", "0.0");
			DispatchKeyValue(C_Fog, "heightFogMaxDensity", "1.0");
			DispatchKeyValue(C_Fog, "heightFogDensity", "0.0");
			DispatchKeyValue(C_Fog, "fogenable", "1");
			DispatchKeyValue(C_Fog, "fogdir", "1 0 0");
			DispatchKeyValue(C_Fog, "angles", "0 180 0");

			if(fog_blend != -1)
			{
				IntToString(fog_blend, sTemp, sizeof(sTemp));
				DispatchKeyValue(C_Fog, "foglerptime", sTemp);
			}

			if(far_z_idle)
			{
				IntToString(far_z_idle, sTemp, sizeof(sTemp));
				DispatchKeyValue(C_Fog, "farz", sTemp);
			}

			if(strcmp(color, ""))
			{
				DispatchKeyValue(C_Fog, "fogcolor", color);
				DispatchKeyValue(C_Fog, "fogcolor2", color);
			}

			DispatchSpawn(C_Fog);
			ActivateEntity(C_Fog);
			
			float angles[3];
			angles[0] = 10.0;
			angles[1] = 15.0;
			angles[2] = 20.0;
			
			TeleportEntity(C_Fog, angles, NULL_VECTOR, NULL_VECTOR);
			C_Fog = EntIndexToEntRef(C_Fog);
			
			PrintToChatAll("%s Fog color: %s", TAG_CHAT, color);
		}
	}
}

void ResetFog()
{
	if(!B_FogOn)
	{
		return;
	}
	B_FogOn = false;
	
	if(IsValidEntRef(C_Fog))
	{
		AcceptEntityInput(C_Fog, "Kill");
		C_Fog  = 0;
	}

	int entity = -1;
	while((entity = FindEntityByClassname(entity, "env_fog_controller")) != INVALID_ENT_REFERENCE)
	{
		for(int i = 0; i < MAX_FOG; i++)
		{
			if( EntIndexToEntRef(entity) == C_FogFromMap[i][0] )
			{
				char temps[64];
				GetEntPropString(entity, Prop_Data,"m_iName", temps, 64);

				if( F_FogFromMap[i][1] == 0 )
					F_FogFromMap[i][1] = 10000.0;

				SetEntProp(entity, Prop_Data, "m_nNextThinkTick", -1);
	
				DispatchKeyValue(entity, "targetname", S_FogFromMap[i]);
				SetEntProp(entity, Prop_Send, "m_fog.colorPrimary", C_FogFromMap[i][1]);
				SetEntProp(entity, Prop_Send, "m_fog.colorSecondary", C_FogFromMap[i][2]);
				SetEntProp(entity, Prop_Send, "m_fog.colorPrimaryLerpTo", C_FogFromMap[i][3]);
				SetEntProp(entity, Prop_Send, "m_fog.colorSecondaryLerpTo", C_FogFromMap[i][4]);
				SetEntPropFloat(entity, Prop_Send, "m_fog.start", F_FogFromMap[i][0]);
				SetEntPropFloat(entity, Prop_Send, "m_fog.end", F_FogFromMap[i][1]);
				SetEntPropFloat(entity, Prop_Send, "m_fog.maxdensity", F_FogFromMap[i][2]);
				SetEntPropFloat(entity, Prop_Send, "m_fog.farz", F_FogFromMap[i][3]);
				SetEntPropFloat(entity, Prop_Send, "m_fog.startLerpTo", F_FogFromMap[i][5]);
				SetEntPropFloat(entity, Prop_Send, "m_fog.endLerpTo", F_FogFromMap[i][6]);
				SetEntPropFloat(entity, Prop_Send, "m_fog.maxdensityLerpTo", F_FogFromMap[i][7]);
				SetEntPropFloat(entity, Prop_Send, "m_fog.duration", F_FogFromMap[i][8]);
				SetEntPropFloat(entity, Prop_Send, "m_fog.lerptime", 1.0);

				strcopy(S_FogFromMap[i], 64, "");
				C_FogFromMap[i][0] = 0;
				C_FogFromMap[i][1] = 0;
				C_FogFromMap[i][2] = 0;
				C_FogFromMap[i][3] = 0;
				C_FogFromMap[i][4] = 0;
				F_FogFromMap[i][0] = 0.0;
				F_FogFromMap[i][1] = 0.0;
				F_FogFromMap[i][2] = 0.0;
				F_FogFromMap[i][3] = 0.0;
				F_FogFromMap[i][4] = 0.0;
				F_FogFromMap[i][5] = 0.0;
				F_FogFromMap[i][6] = 0.0;
				F_FogFromMap[i][7] = 0.0;
				F_FogFromMap[i][8] = 0.0;
				break;
			}
		}
	}
}

/**************************************************************LOGIC**************************************************************/
void CreateLogics()
{
	char sTemp[64];
	
	int fog_blend 				= GetHourFogBlend(INT_CURRENT_HOURS);
	
	int far_z_idle 				= GetHourFogFarz(INT_CURRENT_HOURS);
	int far_z_storm				= GetHourFogFarzStorm(INT_CURRENT_HOURS);

	int fog_idle_start			= GetHourFogIdleStart(INT_CURRENT_HOURS);
	int fog_idle				= GetHourFogIdle(INT_CURRENT_HOURS);
	float fog_opaque_idle		= GetHourFogOpaqueIdle(INT_CURRENT_HOURS);
	
	int fog_storm_start 		= GetHourFogStormStart(INT_CURRENT_HOURS);
	int fog_storm 				= GetHourFogStorm(INT_CURRENT_HOURS);
	float fog_opaque_storm 		= GetHourFogOpaqueStorm(INT_CURRENT_HOURS);	
	
	// ====================================================================================================
	// logic_relay - FADE IN
	// ====================================================================================================
	C_LogicIn = CreateEntityByName("logic_relay");
	if(C_LogicIn != -1)
	{
		DispatchKeyValue(C_LogicIn, "spawnflags", "2");
		DispatchKeyValue(C_LogicIn, "targetname", "silver_relay_storm_blendin");

		// SILVER
		if(fog_storm)
		{
			Format(sTemp, sizeof(sTemp), "OnTrigger silver_fog_storm:SetEndDistLerpTo:%d:0:-1", fog_storm);
			SetVariantString(sTemp);
			AcceptEntityInput(C_LogicIn, "AddOutput");
		}
		if(fog_storm_start)
		{
			Format(sTemp, sizeof(sTemp), "OnTrigger silver_fog_storm:SetStartDistLerpTo:%d:0:-1", fog_storm_start);
			SetVariantString(sTemp);
			AcceptEntityInput(C_LogicIn, "AddOutput");
		}
		if(fog_opaque_storm)
		{
			Format(sTemp, sizeof(sTemp), "OnTrigger silver_fog_storm:Setmaxdensitylerpto:%f:0:-1", fog_opaque_storm);
			SetVariantString(sTemp);
			AcceptEntityInput(C_LogicIn, "AddOutput");
		}
		if(far_z_idle && far_z_storm)
		{
			Format(sTemp, sizeof(sTemp), "OnTrigger silver_fog_storm:SetFarZ:%d:%d:-1", far_z_storm, fog_blend - 1);
			SetVariantString(sTemp);
			AcceptEntityInput(C_LogicIn, "AddOutput");
		}
		SetVariantString("OnTrigger silver_fog_storm:Set2DSkyboxFogFactorLerpTo:1:0:-1");
		AcceptEntityInput(C_LogicIn, "AddOutput");
		SetVariantString("OnTrigger silver_fog_storm:StartFogTransition::0.1:-1");
		AcceptEntityInput(C_LogicIn, "AddOutput");

		// STOLEN
		if(fog_storm)
		{
			Format(sTemp, sizeof(sTemp), "OnTrigger stolen_fog_storm:SetEndDistLerpTo:%d:0:-1", fog_storm);
			SetVariantString(sTemp);
			AcceptEntityInput(C_LogicIn, "AddOutput");
		}
		if(fog_storm_start)
		{
			Format(sTemp, sizeof(sTemp), "OnTrigger stolen_fog_storm:SetStartDistLerpTo:%d:0:-1", fog_storm_start);
			SetVariantString(sTemp);
			AcceptEntityInput(C_LogicIn, "AddOutput");
		}
		if(fog_opaque_storm)
		{
			Format(sTemp, sizeof(sTemp), "OnTrigger stolen_fog_storm:Setmaxdensitylerpto:%f:0:-1", fog_opaque_storm);
			SetVariantString(sTemp);
			AcceptEntityInput(C_LogicIn, "AddOutput");
		}
		if(far_z_idle && far_z_storm)
		{
			Format(sTemp, sizeof(sTemp), "OnTrigger stolen_fog_storm:SetFarZ:%d:%d:-1", far_z_storm, fog_blend - 1);
			SetVariantString(sTemp);
			AcceptEntityInput(C_LogicIn, "AddOutput");
		}
		SetVariantString("OnTrigger stolen_fog_storm:Set2DSkyboxFogFactorLerpTo:1:0:-1");
		AcceptEntityInput(C_LogicIn, "AddOutput");
		SetVariantString("OnTrigger stolen_fog_storm:StartFogTransition::0.1:-1");
		AcceptEntityInput(C_LogicIn, "AddOutput");




		// OUTHER OUTPUTS
		SetVariantString("OnTrigger silver_fx_settings_storm:FireUser1::0:-1");
		AcceptEntityInput(C_LogicIn, "AddOutput");

		DispatchSpawn(C_LogicIn);
		ActivateEntity(C_LogicIn);	
	}
	else
	{
		LogError("Failed to create C_LogicIn 'logic_relay'");
	}


	// ====================================================================================================
	// logic_relay - FADE OUT
	// ====================================================================================================
	C_LogicOut = CreateEntityByName("logic_relay");
	if(C_LogicOut != -1)
	{
		DispatchKeyValue(C_LogicOut, "spawnflags", "2");
		DispatchKeyValue(C_LogicOut, "targetname", "silver_relay_storm_blendout");

		// SILVER
		if(fog_idle_start)
		{
			Format(sTemp, sizeof(sTemp), "OnTrigger silver_fog_storm:SetStartDistLerpTo:%d:0:-1", fog_idle_start);
			SetVariantString(sTemp);
			AcceptEntityInput(C_LogicOut, "AddOutput");
		}
		if(fog_idle)
		{
			Format(sTemp, sizeof(sTemp), "OnTrigger silver_fog_storm:SetEndDistLerpTo:%d:0:-1", fog_idle);
			SetVariantString(sTemp);
			AcceptEntityInput(C_LogicOut, "AddOutput");
		}
		if(fog_opaque_idle)
		{
			Format(sTemp, sizeof(sTemp), "OnTrigger silver_fog_storm:Setmaxdensitylerpto:%f:0:-1", fog_opaque_idle);
			SetVariantString(sTemp);
			AcceptEntityInput(C_LogicOut, "AddOutput");
		}
		if(far_z_idle && far_z_storm)
		{
			Format(sTemp, sizeof(sTemp), "OnTrigger silver_fog_storm:SetFarZ:%d:1:-1", far_z_idle);
			SetVariantString(sTemp);
			AcceptEntityInput(C_LogicOut, "AddOutput");
		}
		SetVariantString("OnTrigger silver_fog_storm:Set2DSkyboxFogFactorLerpTo:0:0:-1");
		AcceptEntityInput(C_LogicOut, "AddOutput");
		SetVariantString("OnTrigger silver_fog_storm:StartFogTransition::0.1:-1");
		AcceptEntityInput(C_LogicOut, "AddOutput");

		// STOLEN
		if(fog_idle_start)
		{
			Format(sTemp, sizeof(sTemp), "OnTrigger stolen_fog_storm:SetStartDistLerpTo:%d:0:-1", fog_idle_start);
			SetVariantString(sTemp);
			AcceptEntityInput(C_LogicOut, "AddOutput");
		}
		if(fog_idle)
		{
			Format(sTemp, sizeof(sTemp), "OnTrigger stolen_fog_storm:SetEndDistLerpTo:%d:0:-1", fog_idle);
			SetVariantString(sTemp);
			AcceptEntityInput(C_LogicOut, "AddOutput");
		}
		if(fog_opaque_idle)
		{
			Format(sTemp, sizeof(sTemp), "OnTrigger stolen_fog_storm:Setmaxdensitylerpto:%f:0:-1", fog_opaque_idle);
			SetVariantString(sTemp);
			AcceptEntityInput(C_LogicOut, "AddOutput");
		}
		if(far_z_idle && far_z_storm)
		{
			Format(sTemp, sizeof(sTemp), "OnTrigger stolen_fog_storm:SetFarZ:%d:1:-1", far_z_idle);
			SetVariantString(sTemp);
			AcceptEntityInput(C_LogicOut, "AddOutput");
		}
		SetVariantString("OnTrigger stolen_fog_storm:Set2DSkyboxFogFactorLerpTo:0:0:-1");
		AcceptEntityInput(C_LogicOut, "AddOutput");
		SetVariantString("OnTrigger stolen_fog_storm:StartFogTransition::0.1:-1");
		AcceptEntityInput(C_LogicOut, "AddOutput");

		DispatchSpawn(C_LogicOut);
		ActivateEntity(C_LogicOut);
		AcceptEntityInput(C_LogicOut, "Trigger");
	}
	else
	{
		LogError("Failed to create C_LogicOut 'logic_relay'");
	}
}

void DeleteLogics()
{
	if(IsValidEntRef(C_LogicIn))
	{
		AcceptEntityInput(C_LogicIn, "CancelPending");
		AcceptEntityInput(C_LogicIn, "Kill");
	}
	C_LogicIn = 0;

	if( IsValidEntRef(C_LogicOut) )
	{
		AcceptEntityInput(C_LogicOut, "CancelPending");
		AcceptEntityInput(C_LogicOut, "Kill");
	}
	C_LogicOut = 0;
}

/**************************************************************BACKGROUND**************************************************************/
void SetBackground(bool resetsky, int color)
{
	if(IsValidEntRef(C_SkyCamera) == false)
	{
		PrintToChatAll("%s C_SkyCamera invalid", TAG_CHAT);
		
		C_SkyCamera = FindEntityByClassname(-1, "sky_camera");
		if(C_SkyCamera == -1)
		{
			return;
		}
		C_SkyCam[0] = GetEntProp(C_SkyCamera, Prop_Data, "m_skyboxData.fog.colorPrimary");
		C_SkyCam[1] = GetEntProp(C_SkyCamera, Prop_Data, "m_skyboxData.fog.colorSecondary");
		PrintToChatAll("%s C_SkyCamera find", TAG_CHAT);
	}

	if(resetsky == true)
	{
		CreateSkyCamera(C_SkyCam[0], C_SkyCam[1]);
	}
	else
	{
		CreateSkyCamera(color, color);
	}
}

void CreateSkyCamera(int color1=0, int color2=0)
{
	if(IsValidEntRef(C_SkyCamera) == true)
	{
		/*
		int iSkyCamData[5];
		float fSkyCamData[5];

		iSkyCamData[0] = GetEntProp(C_SkyCamera, Prop_Data, "m_bUseAngles");
		iSkyCamData[1] = GetEntProp(C_SkyCamera, Prop_Data, "m_skyboxData.scale");
		iSkyCamData[3] = GetEntProp(C_SkyCamera, Prop_Data, "m_skyboxData.fog.blend");
		iSkyCamData[4] = GetEntProp(C_SkyCamera, Prop_Data, "m_skyboxData.fog.enable");
		fSkyCamData[0] = GetEntPropFloat(C_SkyCamera, Prop_Data, "m_skyboxData.fog.start");
		fSkyCamData[1] = GetEntPropFloat(C_SkyCamera, Prop_Data, "m_skyboxData.fog.end");
		fSkyCamData[2] = GetEntPropFloat(C_SkyCamera, Prop_Data, "m_skyboxData.fog.maxdensity");
		fSkyCamData[3] = GetEntPropFloat(C_SkyCamera, Prop_Data, "m_skyboxData.fog.HDRColorScale");
		*/
		
		float vAng[3], vPos[3];
		GetEntPropVector(C_SkyCamera, Prop_Data, "m_vecOrigin", vPos);
		GetEntPropVector(C_SkyCamera, Prop_Data, "m_angRotation", vAng);
		AcceptEntityInput(C_SkyCamera, "Kill");


		C_SkyCamera = CreateEntityByName("sky_camera");
		
		/*
		SetEntProp(C_SkyCamera, Prop_Data, "m_skyboxData.fog.colorPrimary", color1);
		SetEntProp(C_SkyCamera, Prop_Data, "m_skyboxData.fog.colorSecondary", color2);
		SetEntProp(C_SkyCamera, Prop_Data, "m_bUseAngles", iSkyCamData[0]);
		SetEntProp(C_SkyCamera, Prop_Data, "m_skyboxData.scale", iSkyCamData[1]);
		SetEntProp(C_SkyCamera, Prop_Data, "m_skyboxData.fog.blend", iSkyCamData[3]);
		SetEntProp(C_SkyCamera, Prop_Data, "m_skyboxData.fog.enable", iSkyCamData[4]);
		SetEntPropFloat(C_SkyCamera, Prop_Data, "m_skyboxData.fog.start", fSkyCamData[0]);
		SetEntPropFloat(C_SkyCamera, Prop_Data, "m_skyboxData.fog.end", fSkyCamData[1]);
		SetEntPropFloat(C_SkyCamera, Prop_Data, "m_skyboxData.fog.maxdensity", fSkyCamData[2]);
		SetEntPropFloat(C_SkyCamera, Prop_Data, "m_skyboxData.fog.HDRColorScale", fSkyCamData[3]);
		*/
		
		int fog_sky_start 			= GetHourFogSkyStart(INT_CURRENT_HOURS);
		int fog_sky 				= GetHourFogSky(INT_CURRENT_HOURS);
		float fog_opaque_sky		= GetHourFogSkyOpaque(INT_CURRENT_HOURS);
		
		char S_fog_sky[64];
		Format(S_fog_sky, sizeof(S_fog_sky), "%i", fog_sky);
		
		char S_fog_sky_start[64];
		Format(S_fog_sky_start, sizeof(S_fog_sky_start), "%i", fog_sky_start);
		
		char S_fog_opaque_sky[64];
		Format(S_fog_opaque_sky, sizeof(S_fog_opaque_sky), "%f", fog_opaque_sky);
		
		DispatchKeyValue(C_SkyCamera, "use_angles", "0");
		DispatchKeyValue(C_SkyCamera, "scale", "16");
		DispatchKeyValue(C_SkyCamera, "fogstart", S_fog_sky_start);
		DispatchKeyValue(C_SkyCamera, "fogend", S_fog_sky);
		DispatchKeyValue(C_SkyCamera, "fogmaxdensity", S_fog_opaque_sky);
		DispatchKeyValue(C_SkyCamera, "fogenable", "1");
		DispatchKeyValue(C_SkyCamera, "fogdir", "1 0 0");
		DispatchKeyValue(C_SkyCamera, "angles", "0 0 0");
		
		
		char background_color[12];
		GetHourBackgroundColor(INT_CURRENT_HOURS, background_color, sizeof(background_color));
	
		if(strcmp(background_color, ""))
		{
			DispatchKeyValue(C_SkyCamera, "fogcolor", background_color);
			DispatchKeyValue(C_SkyCamera, "fogcolor2", background_color);
		}
		
		TeleportEntity(C_SkyCamera, vPos, vAng, NULL_VECTOR);
		DispatchSpawn(C_SkyCamera);
		ActivateEntity(C_SkyCamera);
		//AcceptEntityInput(C_SkyCamera, "ActivateSkyBox");
		
		PrintToChatAll("%s C_SkyCamera valid", TAG_CHAT);
	}
}

public Action Timer_SetSkyCam(Handle timer)
{
	char background_color[12];
	GetHourBackgroundColor(INT_CURRENT_HOURS, background_color, sizeof(background_color));
	
	int background			= GetColor(background_color);
	SetBackground(false, background);
		
	char light[64];
	GetHourLight(INT_CURRENT_HOURS, light, sizeof(light));
	ChangeLightStyle(light);
}
/**************************************************************PROCESS**************************************************************/

void CreatePostProcess()
{
	float vPos[3];
	int client;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			client = i;
			break;
		}
	}

	if(client == 0)
	{
		return;
	}

	GetClientAbsOrigin(client, vPos);

	C_PostProcess = CreateEntityByName("postprocess_controller");
	if( C_PostProcess == -1 )
	{
		LogError("Failed to create 'postprocess_controller'");
		return;
	}
	else
	{
		char sTemp[16];
		DispatchKeyValue(C_PostProcess, "targetname", "silver_fx_settings_storm");
		DispatchKeyValue(C_PostProcess, "vignettestart", "1");
		DispatchKeyValue(C_PostProcess, "vignetteend", "4");
		DispatchKeyValue(C_PostProcess, "vignetteblurstrength", "0");
		DispatchKeyValue(C_PostProcess, "topvignettestrength", "1");
		DispatchKeyValue(C_PostProcess, "spawnflags", "1");
		Format(sTemp, sizeof(sTemp), "%f", -0.25);
		DispatchKeyValue(C_PostProcess, "localcontraststrength", sTemp);
		DispatchKeyValue(C_PostProcess, "localcontrastedgestrength", "-.3");
		DispatchKeyValue(C_PostProcess, "grainstrength", "1");
		DispatchKeyValue(C_PostProcess, "fadetime", "3");

		DispatchSpawn(C_PostProcess);
		ActivateEntity(C_PostProcess);
		TeleportEntity(C_PostProcess, vPos, NULL_VECTOR, NULL_VECTOR);
		C_PostProcess = EntIndexToEntRef(C_PostProcess);
	}

	ToggleFogVolume(false);

	C_FogVolume = CreateEntityByName("fog_volume");
	if( C_FogVolume == -1 )
	{
		LogError("Failed to create 'fog_volume'");
	}
	else
	{
		DispatchKeyValue(C_FogVolume, "PostProcessName", "silver_fx_settings_storm");
		DispatchKeyValue(C_FogVolume, "spawnflags", "0");

		DispatchSpawn(C_FogVolume);
		ActivateEntity(C_FogVolume);

		float vMins[3] = { -5000.0, -5000.0, -5000.0 };
		float vMaxs[3] = { 5000.0, 5000.0, 5000.0 };
		SetEntPropVector(C_FogVolume, Prop_Send, "m_vecMins", vMins);
		SetEntPropVector(C_FogVolume, Prop_Send, "m_vecMaxs", vMaxs);
		TeleportEntity(C_FogVolume, vPos, NULL_VECTOR, NULL_VECTOR);
	}

	ToggleFogVolume(true);
}

void ToggleFogVolume(bool enable)
{
	if(enable == true)
	{
		if(IsValidEntRef(C_FogVolume))
		{
			AcceptEntityInput(C_FogVolume, "Disable");
			AcceptEntityInput(C_FogVolume, "Enable");
		}
	}

	int m_bDisabled, entity = -1;

	while((entity = FindEntityByClassname(entity, "fog_volume")) != INVALID_ENT_REFERENCE)
	{
		if(C_FogVolume == entity)
		{
			break;
		}

		if(enable == true)
		{
			m_bDisabled = GetEntProp(entity, Prop_Data, "m_bDisabled");
			if(m_bDisabled == 0)
				AcceptEntityInput(entity, "Enable");
		}
		else if(enable == false)
		{
			m_bDisabled = GetEntProp(entity, Prop_Data, "m_bDisabled");
			SetEntProp(entity, Prop_Data, "m_iHammerID", m_bDisabled);
			AcceptEntityInput(entity, "Disable");
		}
	}
}

int GetColor(char[] sTemp)
{
	if(strcmp(sTemp, "") == 0)
	{
		return 0;
	}

	char sColors[3][4];
	ExplodeString(sTemp, " ", sColors, 3, 4);

	int color;
	color = StringToInt(sColors[0]);
	color += 256 * StringToInt(sColors[1]);
	color += 65536 * StringToInt(sColors[2]);
	
	PrintToChatAll("%s color: %i", TAG_CHAT, color);
	return color;
}

/***********************************************************/
/********************* LOAD DAYS DATA **********************/
/***********************************************************/
void LoadDayData(bool defaultconfig, char[] folder)
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), folder);
	ReadDayFile(defaultconfig, path);
}

/***********************************************************/
/********************* LOAD DAYS DATA **********************/
/***********************************************************/
void ReadDayFile(bool defaultconfig, char[] folder)
{
	char path[PLATFORM_MAX_PATH];
	Format(path, sizeof(path), "%s/meteo.cfg", folder);

	if (!defaultconfig && !FileExists(path))
	{
		return;
	}

	if (KvHours != INVALID_HANDLE)
	{
		CloseHandle(KvHours);
	}

	KvHours = CreateKeyValues("meteo");
	KvSetEscapeSequences(KvHours, true);

	if (!FileToKeyValues(KvHours, path))
	{
		SetFailState("\"%s\" failed to load", path);
	}

	KvRewind(KvHours);
	if (!KvGotoFirstSubKey(KvHours))
	{
		SetFailState("No day data defined in \"%s\"", path);
	}
	
	char light[64];
	char fog_color[64];
	char background_color[12];
	
	INT_TOTAL_HOURS = 0;
	do
	{
		//TIME
		data_time[INT_TOTAL_HOURS] 								= KvGetFloat(KvHours, 		"time");
		
		//LIGHT
		KvGetString(KvHours, "light", light, sizeof(light));
		strcopy(data_light[INT_TOTAL_HOURS], sizeof(light), light);
		
		//FOG
		data_fog_blend[INT_TOTAL_HOURS] 								= KvGetNum(KvHours, 		"fog_blend");
		
		data_fog_farz[INT_TOTAL_HOURS] 									= KvGetNum(KvHours, 		"far_z_idle");
		data_far_z_storm[INT_TOTAL_HOURS] 								= KvGetNum(KvHours, 		"far_z_storm");
		
		KvGetString(KvHours, "fog_color", fog_color, sizeof(fog_color));
		strcopy(data_fog_color[INT_TOTAL_HOURS], sizeof(fog_color), fog_color);
		
		KvGetString(KvHours, "background", background_color, sizeof(background_color));
		strcopy(data_background_color[INT_TOTAL_HOURS], sizeof(background_color), background_color);
		
		data_fog_idle_start[INT_TOTAL_HOURS] 							= KvGetNum(KvHours, 		"fog_idle_start");
		data_fog_idle[INT_TOTAL_HOURS] 									= KvGetNum(KvHours, 		"fog_idle");
		data_fog_opaque_idle[INT_TOTAL_HOURS] 							= KvGetFloat(KvHours, 		"fog_opaque_idle");
		
		data_fog_storm_start[INT_TOTAL_HOURS] 							= KvGetNum(KvHours, 		"fog_storm_start");		
		data_fog_storm[INT_TOTAL_HOURS] 								= KvGetNum(KvHours, 		"fog_storm");
		data_fog_opaque_storm[INT_TOTAL_HOURS] 							= KvGetFloat(KvHours, 		"fog_opaque_storm");
		
		data_fog_sky_start[INT_TOTAL_HOURS] 							= KvGetNum(KvHours, 		"fog_sky_start");		
		data_fog_sky[INT_TOTAL_HOURS] 									= KvGetNum(KvHours, 		"fog_sky");
		data_fog_sky_opaque[INT_TOTAL_HOURS] 							= KvGetFloat(KvHours, 		"fog_opaque_sky");

		
		LogMessage("%s [HOURS%i] - Time: %i, Light: %s", TAG_CHAT, INT_TOTAL_HOURS, data_time[INT_TOTAL_HOURS], data_light[INT_TOTAL_HOURS]);
		
		INT_TOTAL_HOURS++;
	} 
	while (KvGotoNextKey(KvHours));
}

/***********************************************************/
/*********************** GET HOUR TIME *********************/
/***********************************************************/
float GetHourTime(int hour)
{
    return data_time[hour];
}

/***********************************************************/
/********************* GET HOUR LIGHT **********************/
/***********************************************************/
void GetHourLight(int hour, char[] light, int len)
{
    strcopy(light, len, data_light[hour]);
}

/***********************************************************/
/******************** GET HOUR FOG BLEND *******************/
/***********************************************************/
int GetHourFogBlend(int hour)
{
    return data_fog_blend[hour];
}

/***********************************************************/
/********************* GET HOUR FOG FARZ *******************/
/***********************************************************/
int GetHourFogFarz(int hour)
{
    return data_fog_farz[hour];
}

/***********************************************************/
/******************* GET HOUR FOG COLOR ********************/
/***********************************************************/
void GetHourFogColor(int hour, char[] color, int len)
{
    strcopy(color, len, data_fog_color[hour]);
}

/***********************************************************/
/****************** GET HOUR FOG FARZ STORM ****************/
/***********************************************************/
int GetHourFogFarzStorm(int hour)
{
    return data_far_z_storm[hour];
}

/***********************************************************/
/******************** GET HOUR FOG STORM *******************/
/***********************************************************/
int GetHourFogStorm(int hour)
{
    return data_fog_storm[hour];
}

/***********************************************************/
/***************** GET HOUR FOG STORM START ****************/
/***********************************************************/
int GetHourFogStormStart(int hour)
{
    return data_fog_storm_start[hour];
}

/***********************************************************/
/****************** GET HOUR FOG IDLE START ****************/
/***********************************************************/
int GetHourFogIdleStart(int hour)
{
    return data_fog_idle_start[hour];
}

/***********************************************************/
/********************* GET HOUR FOG IDLE *******************/
/***********************************************************/
int GetHourFogIdle(int hour)
{
    return data_fog_idle[hour];
}

/***********************************************************/
/***************** GET HOUR FOG OPAQUE STORM ***************/
/***********************************************************/
float GetHourFogOpaqueStorm(int hour)
{
    return data_fog_opaque_storm[hour];
}

/***********************************************************/
/***************** GET HOUR FOG OPAQUE IDLE ****************/
/***********************************************************/
float GetHourFogOpaqueIdle(int hour)
{
    return data_fog_opaque_idle[hour];
}

/***********************************************************/
/***************** GET HOUR BACKGROUND COLOR ***************/
/***********************************************************/
void GetHourBackgroundColor(int hour, char[] color, int len)
{
    strcopy(color, len, data_background_color[hour]);
}

/***********************************************************/
/******************* GET HOUR FOG SKY START ****************/
/***********************************************************/
int GetHourFogSkyStart(int hour)
{
    return data_fog_sky_start[hour];
}

/***********************************************************/
/********************** GET HOUR FOG SKY *******************/
/***********************************************************/
int GetHourFogSky(int hour)
{
    return data_fog_sky[hour];
}

/***********************************************************/
/******************* GET HOUR FOG SKY OPAQUE ***************/
/***********************************************************/
float GetHourFogSkyOpaque(int hour)
{
    return data_fog_sky_opaque[hour];
}

/**************************************************************COMMANDS**************************************************************/
public Action Command_MapLight(int client, int args)
{
	if(args)
	{
		char sTemp[64];
		GetCmdArg(1, sTemp, sizeof(sTemp));
		ChangeLightStyle(sTemp);
	}
	return Plugin_Handled;
}

public Action Command_MapSky(int client, int args)
{
	if(args)
	{
		char sTemp[64];
		GetCmdArg(1, sTemp, sizeof(sTemp));
		SetSkyname(sTemp);
	}
	return Plugin_Handled;
}

public Action Command_MapBackGround(int client, int args)
{
	if(args == 3)
	{
		if(IsValidEntRef(C_SkyCamera) == false)
		{
			C_SkyCamera = FindEntityByClassname(-1, "sky_camera");
			if(C_SkyCamera == -1)
			{
				PrintToChat(client, "%sBackground error: Cannot find the \x01sky_camera\x06 entity. Was never created or has been deleted.", TAG_CHAT);
				return Plugin_Handled;
			}

			C_SkyCam[0] = GetEntProp(C_SkyCamera, Prop_Data, "m_skyboxData.fog.colorPrimary");
			C_SkyCam[1] = GetEntProp(C_SkyCamera, Prop_Data, "m_skyboxData.fog.colorSecondary");
		}

		char sTemp[12];
		GetCmdArgString(sTemp, sizeof(sTemp));
		int color = GetColor(sTemp);
		CreateSkyCamera(color, color);
	}
	else
	{
		PrintToChat(client, "%sUsage: sm_background <no args = reset, or string from a-z.", TAG_CHAT);
	}
	return Plugin_Handled;
}

public Action Command_MapFarZ(int client, int args)
{
	if(args == 1)
	{
		int entity = -1;
		char sTemp[16];
		GetCmdArg(1, sTemp, sizeof(sTemp));

		while((entity = FindEntityByClassname(entity, "env_fog_controller")) != INVALID_ENT_REFERENCE)
		{
			SetVariantString(sTemp);
			AcceptEntityInput(entity, "SetFarZ");
		}
	}
	else
	{
		PrintToChat(client, "%sUsage: sm_farz <distance in game units>.", TAG_CHAT);
	}
	return Plugin_Handled;
}

public Action Command_MapFog(int client, int args)
{
	if(!B_FogOn)
	{
		CreateFog();
		ReplyToCommand(client, "Fog Create.");
	}
	else if( args == 0 )
	{
		ResetFog();
		ReplyToCommand(client, "Fog Reset.");
	}
	
	if(args == 3)
	{
		char sTemp[12];
		GetCmdArgString(sTemp, sizeof(sTemp));
		
		int entity = -1;
		while((entity = FindEntityByClassname(entity, "env_fog_controller")) != INVALID_ENT_REFERENCE)
		{
			DispatchKeyValue(entity, "fogcolor", sTemp);
			DispatchKeyValue(entity, "fogcolor2", sTemp);

			SetVariantString(sTemp);
			AcceptEntityInput(entity, "SetColorLerpTo");
			
			ReplyToCommand(client, "Fog OK.");
		}
		
	}
	return Plugin_Handled;
}

public Action Command_MapMiddle(int client, int args)
{
	if(args)
	{
		C_SkyNoise = CreateEntityByName("prop_dynamic_override");
		
		if(C_SkyNoise != -1)
		{
			float vPos[3], vMins[3], vMaxs[3];
			GetEntPropVector(0, Prop_Data, "m_WorldMins", vMins);
			GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vMaxs);
			vPos[0] = (vMins[0] + vMaxs[0]) / 2;
			vPos[1] = (vMins[1] + vMaxs[1]) / 2;
			vPos[2] = vMaxs[2];
			
			DispatchKeyValue(C_SkyNoise, "model", "models/props_urban/metal_plate001.mdl");
			
			
			DispatchSpawn(C_SkyNoise);
			TeleportEntity(C_SkyNoise, vPos, NULL_VECTOR, NULL_VECTOR);			
			SetEntPropFloat(C_SkyNoise , Prop_Send, "m_flModelScale", 10000.0);
			
			
			PrintToChatAll("%s min: %f, max: %f", TAG_CHAT, vMins, vMaxs);
		}
	}
	else
	{
		if(IsValidEntRef(C_SkyNoise))
		{
			AcceptEntityInput(C_SkyNoise, "Kill");
		}
	}
	
	
	return Plugin_Handled;
}

public Action Command_MapHour(int client, int args)
{
	if(args)
	{
		char sTemp[64];
		GetCmdArg(1, sTemp, sizeof(sTemp));
		
		INT_CURRENT_HOURS = StringToInt(sTemp);
		

		//LOGIC FOG
		int fog_idle				= GetHourFogIdle(INT_CURRENT_HOURS);
		int fog_storm 				= GetHourFogStorm(INT_CURRENT_HOURS);
		
		ResetFog();
		DeleteLogics();
		
		if(fog_idle && fog_storm)
		{
			CreateFog();
			CreateLogics();
		}

		CreatePostProcess();
		if(IsValidEntRef(C_LogicIn))
		{
			AcceptEntityInput(C_LogicIn, "Trigger");
		}
		
		CreateTimer(0.1, Timer_SetSkyCam);
		 
		SendConVarValue(client, FindConVar("mat_showlowresimage"), "1");
		FakeClientCommandEx(client, "mat_showlowresimage 1");

	}
	return Plugin_Handled;
}

/***********************************************************/
/******************** IS VALID ENTITY **********************/
/***********************************************************/
stock bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}
