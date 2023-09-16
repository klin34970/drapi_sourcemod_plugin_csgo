/*   <ZE4 MAP PROTECTION> (c) by <De Battista Clint - (http://doyou.watch)   */
/*                                                                           */
/*                <ZE4 MAP PROTECTION> is licensed under a                   */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//****************************ZE4 MAP PROTECTION*****************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[Z4E - MAP PROTECTION]-"
#define MAX_MAPS						100

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

//Bools
bool B_Disable_Protection		= false;

//Strings
char S_Map[MAX_MAPS][64];

//Customs
int max_map;
//Informations plugin
public Plugin myinfo =
{
	name = "ZE4 MAP PROTECTION",
	author = "Dr. Api",
	description = "ZE4 MAP PROTECTION by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://doyou.watch"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	LoadSettings();
	return APLRes_Success;
}

/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	LoadSettings();
	KillProtection();
	
	CreateConVar("z4e_map_protection_version", PLUGIN_VERSION, "Version", CVARS);
	
	HookEvent("round_start", Event_RoundStart);
}

/***********************************************************/
/******************** WHEN ROUND START *********************/
/***********************************************************/
public void Event_RoundStart(Handle event, char[] name, bool dontBroadcast)
{	
	LoadSettings();
	KillProtection();
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public void OnMapStart()
{
	LoadSettings();
	KillProtection();
}

/***********************************************************/
/********************* KILL PROTECTION *********************/
/***********************************************************/
void KillProtection()
{
	if(B_Disable_Protection)
	{
		int timer;
		while((timer = FindEntityByClassname(timer, "logic_timer")) != -1)
		{
			AcceptEntityInput(timer, "Disable");
			AcceptEntityInput(timer, "Kill");
			//LogMessage("%s Map: %s kill protect", TAG_CHAT, S_Map[max_map]);
		}
	}
}

/***********************************************************/
/********************* LOAD FILE SETTING *******************/
/***********************************************************/
public void LoadSettings()
{
	char hc[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, hc, sizeof(hc), "configs/protectmap/maps.cfg");
	
	Handle kv = CreateKeyValues("Maps");
	FileToKeyValues(kv, hc);
	
	max_map = 0;
	B_Disable_Protection = false;
	
	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			if(KvGotoFirstSubKey(kv))
			{
				do
				{
					KvGetSectionName(kv, S_Map[max_map], 64);
					//LogMessage("%s Map: %s", TAG_CHAT, S_Map[max_map]);

					char Mapname[64];
					GetCurrentMap(Mapname, sizeof(Mapname));
					
					if(strlen(S_Map[max_map]) && StrEqual(Mapname, S_Map[max_map], false))
					{
						B_Disable_Protection = true;
						//LogMessage("%s B_Disable_Protection = true", TAG_CHAT);
					}
					
					max_map++;
				}
				while (KvGotoNextKey(kv));
			}
			
			KvGoBack(kv);
			
		}
		while (KvGotoNextKey(kv));
	}
	CloseHandle(kv);
}