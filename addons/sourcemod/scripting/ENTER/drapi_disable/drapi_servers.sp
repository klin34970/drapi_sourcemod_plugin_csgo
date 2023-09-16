/*     <DR.API SERVERS> (c) by <De Battista Clint - (http://doyou.watch)     */
/*                                                                           */
/*                     <DR.API SERVERS> is licensed under a                  */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//******************************DR.API SERVERS*******************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[SERVERS] -"
#define MAX_SERVERS						20

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <messagebot>
#include <stocks>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_servers_dev;

//Bool
bool B_cvar_active_servers_dev					= false;

bool B_Menu_Used 								= false;

//Strings
char S_servername[MAX_SERVERS][64];
char S_ipname[MAX_SERVERS][64];
char S_portname[MAX_SERVERS][64];

//Customs
int max_servers;

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API SERVERS",
	author = "Dr. Api",
	description = "DR.API SERVERS by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://doyou.watch"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	AutoExecConfig_SetFile("drapi_servers", "sourcemod/drapi");
	LoadTranslations("drapi/drapi_servers.phrases");
	
	AutoExecConfig_CreateConVar("drapi_servers_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_servers_dev			= AutoExecConfig_CreateConVar("drapi_active_servers_dev", 			"0", 					"Enable/Disable Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	HookEvents();
	
	RegConsoleCmd("sm_server", 			Command_BuildMenuServers);
	RegConsoleCmd("sm_servers", 		Command_BuildMenuServers);
	
	MessageBot_ClearRecipients();
	
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
	HookConVarChange(cvar_active_servers_dev, 				Event_CvarChange);
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
	B_cvar_active_servers_dev 					= GetConVarBool(cvar_active_servers_dev);
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
	LoadSettings();
	UpdateState();
}

/***********************************************************/
/********************** MENU SPRITES ***********************/
/***********************************************************/
public Action Command_BuildMenuServers(int client, int args)
{
	if(!B_Menu_Used)
	{
		BuildMenuServers(client);
		B_Menu_Used = true;
		CPrintToChat(client, "%t", "Warning MSG");
	}
	else
	{
		CPrintToChat(client, "%t", "Warning MSG2");
	}
}

/***********************************************************/
/******************* BUILD MENU SPRITES ********************/
/***********************************************************/
void BuildMenuServers(int client)
{
	char title[40];
	
	Menu menu = CreateMenu(MenuServersAction);
	
	for(int servers = 0; servers <= max_servers-1; ++servers)
	{
		AddMenuItem(menu, S_servername[servers], S_servername[servers]);
	}
	
	Format(title, sizeof(title), "%T", "MenuServer_TITLE", client);
	menu.SetTitle(title);
	SetMenuExitBackButton(menu, true);
	menu.Display(client, 30);
}

/***********************************************************/
/****************** MENU ACTION SPRITES ********************/
/***********************************************************/
public int MenuServersAction(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
			B_Menu_Used = false;
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{	
				FakeClientCommand(param1, "sm_settings");
				B_Menu_Used = false;
			}
		}
		case MenuAction_Select:
		{
			char menu1[56];
			char S_steamid[64];
			menu.GetItem(param2, menu1, sizeof(menu1));
			
			GetClientAuthId(param1, AuthId_Steam2, S_steamid, sizeof(S_steamid));
			
			MessageBot_ClearRecipients();
			
			for(int servers = 0; servers <= max_servers; ++servers)
			{
				if(StrEqual(menu1, S_servername[servers]))
				{
					MessageBot_SetSendMethod(SEND_METHOD_ONLINEAPI);
					MessageBot_SetLoginData("zombie4everbot", "RoMaIn1234");
					MessageBot_AddRecipient(S_steamid);
					
					char sMessage[4096];
					Format(sMessage, sizeof(sMessage), "steam://connect/%s:%s", S_ipname[servers] , S_portname[servers]);
						 
					MessageBot_SendMessage(OnMessageResultReceived, sMessage);
					
					CPrintToChat(param1, "%t", "Send MSG");
					
				}
			}
		}
	}
}

public int OnMessageResultReceived(MessageBotResult result, int error)
{
	if(result != RESULT_NO_ERROR)
	{
		LogMessage("Failed to send message, result was: (%d, %d)", result, error);
	}
}
/***********************************************************/
/********************** LOAD SETTINGS **********************/
/***********************************************************/
public void LoadSettings()
{
	char hc[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, hc, sizeof(hc), "configs/drapi/servers.cfg");
	
	Handle kv = CreateKeyValues("Servers");
	FileToKeyValues(kv, hc);
	
	max_servers 		= 0;	
	
	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			KvGetSectionName(kv, S_servername[max_servers], 64);
			//LogMessage("%s Name: %s", TAG_CHAT, S_servername[max_servers]);
			
			KvGetString(kv, "ip", S_ipname[max_servers], 64);
			//LogMessage("%s IP: %s", TAG_CHAT, S_ipname[max_servers]);
			
			KvGetString(kv, "port", S_portname[max_servers], 64);
			//LogMessage("%s PORT: %s", TAG_CHAT, S_portname[max_servers]);
				
			max_servers++;
		}
		while (KvGotoNextKey(kv));
	}
	CloseHandle(kv);
	
}