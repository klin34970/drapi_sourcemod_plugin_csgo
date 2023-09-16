/* <DR.API MAP PROTECTION> (c) by <De Battista Clint - (http://doyou.watch)  */
/*                                                                           */
/*              <DR.API MAP PROTECTION> is licensed under a                  */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//**************************DR.API MAP PROTECTION****************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[MAP PROTECTION]-"

//***********************************//
//*************INCLUDE***************//
//***********************************//

//Include native
#include <sourcemod>
#include <sdktools>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//bool
bool B_protection_active 							= true;

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
	CreateConVar("drapi_map_protection_version", PLUGIN_VERSION, "Version", CVARS);
	
	HookEvent("round_start", RoundStart_Event);
	RegAdminCmd("kpm", KPMMenu, ADMFLAG_CHANGEMAP, "Kill protection map manually.");
}

/***********************************************************/
/******************** WHEN ROUND START *********************/
/***********************************************************/
public void RoundStart_Event(Handle event, const char[] name, bool dB)
{
	CheckProtection();
	if(B_protection_active)
	{
		KillProtection();
	}
}

/***********************************************************/
/**************** KILL PROTECTION MAP MENU *****************/
/***********************************************************/
public Action KPMMenu(int client, int args)
{
	if(B_protection_active)
	{
		KillProtection();
		PrintToChat(client, "Protection map Off");
	}
	else
	{
		PrintToChat(client, "Protection map already Off");
	}
}

/***********************************************************/
/******************** CHECK PROTECTION *********************/
/***********************************************************/
void CheckProtection()
{
		int _iMax = GetMaxEntities();
		for(int i = MaxClients + 1; i <= _iMax; i++)
		{
			if(IsValidEntity(i) && IsValidEdict(i))
			{
				char _sBuffer[64];
				GetEdictClassname(i, _sBuffer, sizeof(_sBuffer));
				if(StrEqual(_sBuffer, "trigger_hurt"))
				{
					//LogMessage("Protection map found");
					char name[64];
					GetEntPropString(i, Prop_Data, "m_iName", name, sizeof(name));
					if(StrEqual(name, "zombie4ever", false))
					{
						B_protection_active = true;
						LogMessage("%s There is a protection map: %s", TAG_CHAT, name);
					}
					
				}
			}
		}
}

/***********************************************************/
/******************* KILL PROTECTION MAP *******************/
/***********************************************************/
void KillProtection()
{
		int _iMax = GetMaxEntities();
		for(int i = MaxClients + 1; i <= _iMax; i++)
		{
			if(IsValidEntity(i) && IsValidEdict(i))
			{
				char _sBuffer[64];
				GetEdictClassname(i, _sBuffer, sizeof(_sBuffer));
				if(StrEqual(_sBuffer, "trigger_hurt"))
				{
					char name[64];
					GetEntPropString(i, Prop_Data, "m_iName", name, sizeof(name));
					if(StrEqual(name, "zombie4ever", false))
					{
						B_protection_active = false;
						AcceptEntityInput(i, "kill");
						RemoveEdict(i);
						LogMessage("%s, Protection map: %s OFF", TAG_CHAT, name);
					}
					
				}
			}
		}
}