#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY

//***********************************//
//*************INCLUDE***************//
//***********************************//

//Include native
#include <sourcemod>
#include <sdktools>

#pragma newdecls required

bool B_Kill_Model = false;
//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API MAP PROTECTION",
	author = "Dr. Api",
	description = "DR.API MAP PROTECTION by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://doyou.watch"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	CreateConVar("drapi_ze_insanitycity_final_version", PLUGIN_VERSION, "Version", CVARS);
	
	HookEvent("round_start", RoundStart_Event);
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public void OnMapStart()
{
	B_Kill_Model = false;
	char S_map[64];
	GetCurrentMap(S_map, sizeof(S_map));
	
	if(StrEqual(S_map, "ze_insanitycity_final", false))
	{
		B_Kill_Model = true;
	}
}
/***********************************************************/
/******************** WHEN ROUND START *********************/
/***********************************************************/
public void RoundStart_Event(Handle event, const char[] name, bool dB)
{
	if(B_Kill_Model)
	{
		KillModels();
	}
}

/***********************************************************/
/******************* KILL PROTECTION MAP *******************/
/***********************************************************/
void KillModels()
{
		int _iMax = GetMaxEntities();
		for(int i = MaxClients + 1; i <= _iMax; i++)
		{
			if(IsValidEntity(i) && IsValidEdict(i))
			{
				char _sBuffer[64];
				GetEdictClassname(i, _sBuffer, sizeof(_sBuffer));
				if(StrEqual(_sBuffer, "prop_ragdoll"))
				{
					AcceptEntityInput(i, "kill");
					RemoveEdict(i);
				}
			}
		}
}