/*     <DR.API SPRITES> (c) by <De Battista Clint - (http://doyou.watch)     */
/*                                                                           */
/*                    <DR.API SPRITES> is licensed under a                   */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//******************************DR.API ADVERTS*******************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[SPRITES] -"
#define MAX_SPRITES						20
#define MAX_STEAMID						64 * MAX_SPRITES

//***********************************//
//*************INCLUDE***************//
//***********************************//
#include <clientprefs>
#include <sourcemod>
#include <autoexec>
#include <csgocolors>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_sprites_dev;

Handle CookieSprites;
Handle CookieSpritesHide;

//Bool
bool B_cvar_active_sprites_dev						= false;

bool B_Sprites_SteamID[MAXPLAYERS+1][MAX_SPRITES];

//Strings
char S_spritename[MAX_SPRITES][64];
char S_spritepath[MAX_SPRITES][64];
char S_spriteflag[MAX_SPRITES][64];
char S_spritedistance_x[MAX_SPRITES][64];
char S_spritedistance_y[MAX_SPRITES][64];
char S_spritedistance_z[MAX_SPRITES][64];
char S_spriteangle_x[MAX_SPRITES][64];
char S_spriteangle_y[MAX_SPRITES][64];
char S_spriteangle_z[MAX_SPRITES][64];
char S_spritesteamid[MAX_SPRITES][MAX_STEAMID][64];

//Customs
int max_sprites;
int max_sprites_steamid[MAX_SPRITES];

int sprite[MAXPLAYERS+1];

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API SPRITES",
	author = "Dr. Api",
	description = "DR.API SPRITES by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://doyou.watch"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	AutoExecConfig_SetFile("drapi_sprites", "sourcemod/drapi");
	LoadTranslations("drapi/drapi_sprites.phrases");
	
	AutoExecConfig_CreateConVar("z4e_sprites_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_sprites_dev			= AutoExecConfig_CreateConVar("active_sprites_dev", 			"1", 					"Enable/Disable Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	HookEvents();
	
	RegAdminCmd("sm_reloadsprites", 				Command_ReloadSprites, 			ADMFLAG_CHANGEMAP, "");
	RegAdminCmd("sm_resetsprites", 					Command_ResetSprites, 			ADMFLAG_CHANGEMAP, "");
	RegAdminCmd("sm_resetspriteshide", 				Command_ResetSpritesHide, 		ADMFLAG_CHANGEMAP, "");
	//RegAdminCmd("sm_sprites", 						Command_BuildMenuSprites, 		ADMFLAG_CHANGEMAP, "");
	RegConsoleCmd("sm_sprites", Command_BuildMenuSprites);
	RegConsoleCmd("sm_sprite", Command_BuildMenuSprites);
	
	CookieSprites 		= RegClientCookie("Sprites", "", CookieAccess_Private);
	CookieSpritesHide 	= RegClientCookie("Sprites Hide", "", CookieAccess_Private);
	int info;
	SetCookieMenuItem(SpritesCookieHandler, info, "Sprites");
	
	HookEvent("player_spawn", 	Event_PlayerSpawn);
	HookEvent("player_death", 	Event_PlayerDeath);
	HookEvent("player_team", 	PlayerTeam_Post, EventHookMode_Post);
	
	AutoExecConfig_ExecuteFile();
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEvents()
{
	HookConVarChange(cvar_active_sprites_dev, 				Event_CvarChange);
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
	B_cvar_active_sprites_dev 					= GetConVarBool(cvar_active_sprites_dev);
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
/******************* WHEN CLIENT CONNECT ********************/
/***********************************************************/
public void OnClientPutInServer(int client)
{
	sprite[client] = -1;
}

/***********************************************************/
/***************** WHEN CLIENT DISCONNECT ******************/
/***********************************************************/
public void OnClientDisconnect(int client)
{
	ClearSprite(client);
}

/***********************************************************/
/****************** CLIENT COOKIE CACHED *******************/
/***********************************************************/
public void OnClientCookiesCached(int client)
{
	char sValue[8];
	GetClientCookie(client, CookieSpritesHide, sValue, sizeof(sValue));
	
	if(strlen(sValue) > 0) 
	{
	}
	else 
	{
		SetClientCookie(client, CookieSpritesHide, "0"); 
	}
} 

/***********************************************************/
/******************* WHEN PLAYER SPAWN *********************/
/***********************************************************/
public void Event_PlayerSpawn(Handle event, char[] name, bool dontBroadcast)
{
	int client 				= GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsClientInGame(client) && IsPlayerAlive(client) &&  GetClientTeam(client) > 1)
	{
		char sValue[8];
		GetClientCookie(client, CookieSprites, sValue, sizeof(sValue));
		if(StrEqual(sValue, "0", false))
		{
			if(!SpriteValid(client))
			{
				return;
			}
			else
			{	
				ClearSprite(client);
			}
		}
		else
		{
			ClearSprite(client);
			sprite[client] = CreateSprite(client, StringToInt(sValue));
		}
	}
}

/***********************************************************/
/******************* WHEN PLAYER DEATH *********************/
/***********************************************************/
public void Event_PlayerDeath(Handle event, char[] name, bool dontBroadcast)
{
	int victim 				= GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(SpriteValid(victim))
	{
		ClearSprite(victim);
	}
}

/***********************************************************/
/********************** PLAYER TEAM POST *******************/
/***********************************************************/
public Action PlayerTeam_Post(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int team = GetEventInt(event, "team");
	
	if(team <= 1)
	{
		ClearSprite(client);
	}
}
/***********************************************************/
/********************** MENU SETTINGS **********************/
/***********************************************************/
public void SpritesCookieHandler(int client, CookieMenuAction action, any info, char [] buffer, int maxlen)
{
	BuildMenuSprites(client);
} 

/***********************************************************/
/********************* RELOAD SPRITES **********************/
/***********************************************************/
public Action Command_ReloadSprites(int client, int args)
{
	LoadSettings();
}

/***********************************************************/
/********************* RELOAD SPRITES **********************/
/***********************************************************/
public Action Command_ResetSprites(int client, int args)
{
	char S_args1[256];
	GetCmdArg(1, S_args1, sizeof(S_args1));
	
	for(int i = 1; i <= MaxClients; i++)
	{
		SetClientCookie(i, CookieSprites, S_args1);
	}
}

/***********************************************************/
/********************* RELOAD SPRITES **********************/
/***********************************************************/
public Action Command_ResetSpritesHide(int client, int args)
{
	char S_args1[256];
	GetCmdArg(1, S_args1, sizeof(S_args1));
	
	for(int i = 1; i <= MaxClients; i++)
	{
		SetClientCookie(i, CookieSpritesHide, S_args1);
	}
}

/***********************************************************/
/********************** MENU SPRITES ***********************/
/***********************************************************/
public Action Command_BuildMenuSprites(int client, int args)
{
	BuildMenuSprites(client);
}

/***********************************************************/
/******************* BUILD MENU SPRITES ********************/
/***********************************************************/
void BuildMenuSprites(int client)
{
	char title[40], unequiped[40], showsprites[40], hidesprites[40], thirdperson[40], buysprites[40], menusprites[40];
	
	char S_steamid[64];
	char sValue[8];
	Menu menu = CreateMenu(MenuSpritesAction);
	
	GetClientAuthId(client, AuthId_Steam2, S_steamid, sizeof(S_steamid));
	GetClientCookie(client, CookieSpritesHide, sValue, sizeof(sValue));
	
	if(SpriteValid(client))
	{
		Format(unequiped, sizeof(unequiped), "%T", "MenuSprites_UNEQUIPED_MENU_TITLE", client);
		AddMenuItem(menu, "M_unequiped", unequiped);
	}
	
	if(StrEqual(sValue, "0", false))
	{
		Format(hidesprites, sizeof(hidesprites), "%T", "MenuSprites_HIDESPRITES_MENU_TITLE", client);
		AddMenuItem(menu, "M_showsprites", hidesprites);
	}
	else
	{
		Format(showsprites, sizeof(showsprites), "%T", "MenuSprites_SHOWSPRITES_MENU_TITLE", client);
		AddMenuItem(menu, "M_showsprites", showsprites);
	}
	
	Format(thirdperson, sizeof(thirdperson), "%T", "MenuSprites_THIRDPERSON_MENU_TITLE", client);
	AddMenuItem(menu, "M_thirdperson", thirdperson);
	
	Format(buysprites, sizeof(buysprites), "%T", "MenuSprites_BUYSPRITES_MENU_TITLE", client);
	AddMenuItem(menu, "M_buysprites", buysprites);
	
	for(int sprites = 1; sprites <= max_sprites-1; ++sprites)
	{
		for(int steamid = 1; steamid <= max_sprites_steamid[sprites]; ++steamid)
		{
			
			if(StrEqual(S_spritesteamid[sprites][steamid], S_steamid ,false))
			{
				B_Sprites_SteamID[client][sprites] = true;
			}
		}
		
		if( (B_Sprites_SteamID[client][sprites] == true && StrEqual(S_spriteflag[sprites], "steamid", false)) 						//Steamid only
			|| (IsAdminEx(client) && StrEqual(S_spriteflag[sprites], "admin", false) || B_Sprites_SteamID[client][sprites] == true)	//Admin + steamid 
			|| (IsVip(client) && StrEqual(S_spriteflag[sprites], "vip", false) || B_Sprites_SteamID[client][sprites] == true) 		//Vip + steamid
			|| StrEqual(S_spriteflag[sprites], "public", false) )																	//Public
			{
				if(sprites == 1)
				{
					Format(menusprites, sizeof(menusprites), "%T", "MenuSprites_SEPARATEPRITES_MENU_TITLE", client);
					AddMenuItem(menu, "", menusprites, ITEMDRAW_DISABLED);
				}
				AddMenuItem(menu, S_spritename[sprites], S_spritename[sprites]);
			}
		
		/*if(StringToInt(S_spriteflag[sprites]) != -1 && (GetUserFlagBits(client) & ReadFlagString(S_spriteflag[sprites]))) 
		{
			AddMenuItem(menu, S_spritename[sprites], S_spritename[sprites]);
		}*/
	}
	
	Format(title, sizeof(title), "%T", "MenuSprites_TITLE", client);
	menu.SetTitle(title);
	SetMenuExitBackButton(menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
}

/***********************************************************/
/****************** MENU ACTION SPRITES ********************/
/***********************************************************/
public int MenuSpritesAction(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);	
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{	
				FakeClientCommand(param1, "sm_settings");
			}
		}
		case MenuAction_Select:
		{
			char menu1[56];
			char S_steamid[64];
			char sValue[8];
			menu.GetItem(param2, menu1, sizeof(menu1));
			GetClientAuthId(param1, AuthId_Steam2, S_steamid, sizeof(S_steamid));
			GetClientCookie(param1, CookieSpritesHide, sValue, sizeof(sValue));
			
			if(StrEqual(menu1, "M_unequiped"))
			{
				ClearSprite(param1);
				SetClientCookie(param1, CookieSprites, "0");

				CPrintToChat(param1, "%t", "Delete Sprite");
				//PrintToDev(B_cvar_active_sprites_dev, "%s Sprite ID: 0", TAG_CHAT);
			}
			else if(StrEqual(menu1, "M_thirdperson"))
			{
				FakeClientCommand(param1, "say /tp");
			}
			else if(StrEqual(menu1, "M_buysprites"))
			{
				FakeClientCommand(param1, "sm_buysprites");
			}
			else if(StrEqual(menu1, "M_showsprites"))
			{
				if(StrEqual(sValue, "0", false))
				{
					SetClientCookie(param1, CookieSpritesHide, "1");
				}
				else
				{
					SetClientCookie(param1, CookieSpritesHide, "0");
				}
			}
			
			
			for(int sprites = 1; sprites <= max_sprites; ++sprites)
			{
				if(StrEqual(menu1, S_spritename[sprites]))
				{
					if(IsPlayerAlive(param1))
					{
						if(SpriteValid(param1))
						{
							ClearSprite(param1);
							sprite[param1] = CreateSprite(param1, sprites);
							
							char spriteid[64];
							IntToString(sprites, spriteid, sizeof(spriteid));
							SetClientCookie(param1, CookieSprites, spriteid);
							
							CPrintToChat(param1, "%t", "Replace Sprite", S_spritename[sprites]);
							//PrintToDev(B_cvar_active_sprites_dev, "%s Delete Menu: %s, Sprite ID: %s", TAG_CHAT, menu1, spriteid);
							
						}
						else
						{
							sprite[param1] = CreateSprite(param1, sprites);
							
							char spriteid[64];
							IntToString(sprites, spriteid, sizeof(spriteid));
							SetClientCookie(param1, CookieSprites, spriteid);
							
							CPrintToChat(param1, "%t", "New Sprite", S_spritename[sprites]);
							//PrintToDev(B_cvar_active_sprites_dev, "%s Create Menu: %s, Client ID: %i, Sprite ID: %s", TAG_CHAT, menu1, param1, spriteid);
						}
					}
					else
					{
						char spriteid[64];
						IntToString(sprites, spriteid, sizeof(spriteid));
						SetClientCookie(param1, CookieSprites, spriteid);
						
						CPrintToChat(param1, "%t", "Alive Sprite", S_spritename[sprites]);
						//PrintToDev(B_cvar_active_sprites_dev, "%s Not alive will appear round start", TAG_CHAT, menu1);
					}
				}
			}
			BuildMenuSprites(param1);
		}
	}
}

/***********************************************************/
/********************** CREATE SPRITE **********************/
/***********************************************************/
int CreateSprite(int client, int index) 
{
	char iTarget[16];
	Format(iTarget, 16, "client%d", client);
	DispatchKeyValue(client, "targetname", iTarget);

	float origin[3], angle[3];

	GetClientAbsOrigin(client, origin);            
	GetClientAbsAngles(client, angle);

	origin[0] 	= origin[0] + StringToFloat(S_spritedistance_x[index]);
	origin[1] 	= origin[1] + StringToFloat(S_spritedistance_y[index]);
	origin[2] 	= origin[2] + StringToFloat(S_spritedistance_z[index]);
	angle[0] 	= angle[0] + StringToFloat(S_spriteangle_x[index]);
	angle[1] 	= angle[1] + StringToFloat(S_spriteangle_y[index]);
	angle[2] 	= angle[2] + StringToFloat(S_spriteangle_z[index]);

	if(!IsModelPrecached(S_spritepath[index]))
	{
		PrecacheModel(S_spritepath[index]);
	}
	int ent = CreateEntityByName("env_sprite");
	if(!ent) return -1;

	char temp[64];
	Format(temp, 64, S_spritepath[index]);
	ReplaceString(temp, 64, "materials/", "");

	DispatchKeyValue(ent, "model", temp);
	DispatchKeyValue(ent, "classname", "env_sprite");
	DispatchKeyValue(ent, "spawnflags", "1");
	DispatchKeyValue(ent, "scale", "0.08");
	DispatchKeyValue(ent, "rendermode", "1");
	DispatchKeyValue(ent, "rendercolor", "255 255 255");
	DispatchSpawn(ent);
	TeleportEntity(ent, origin, angle, NULL_VECTOR);
	SetVariantString(iTarget);
	AcceptEntityInput(ent, "SetParent", ent, ent, 0);
	
	SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
	
	SDKHook(ent, SDKHook_SetTransmit, ShouldHideMelee);
	
	//PrintToDev(B_cvar_active_sprites_dev, "%s Ent ID: %i", TAG_CHAT, EntIndexToEntRef(ent));
	return EntIndexToEntRef(ent);
}

/***********************************************************/
/********************** SHOULD HIDE ************************/
/***********************************************************/
public Action ShouldHideMelee(int ent, int client)
{
	if(IsClientInGame(client))
	{
		int owner 				= GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		
		char sValue[8];
		GetClientCookie(client, CookieSpritesHide, sValue, sizeof(sValue));
		
		if(client != owner && StrEqual(sValue, "1", false))
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}
/***********************************************************/
/********************** CLEAR HP BAR ***********************/
/***********************************************************/
void ClearSprite(int client)
{
	if(sprite[client])
	{
		int entity = EntRefToEntIndex(sprite[client]);
		if (entity != -1)
		{
			AcceptEntityInput(entity, "Kill", -1, -1, 0);
		}
		sprite[client] = 0;
	}
}

/***********************************************************/
/******************** CHECK ICON VALID *********************/
/***********************************************************/
bool SpriteValid(int client)
{
	if(sprite[client])
	{
		int entity = EntRefToEntIndex(sprite[client]);
		if (entity != -1)
		{
			return true;
		}
	}
	return false;
}

/***********************************************************/
/********************** LOAD SETTINGS **********************/
/***********************************************************/
public void LoadSettings()
{
	char hc[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, hc, sizeof(hc), "configs/drapi/sprites.cfg");
	
	Handle kv = CreateKeyValues("Sprites");
	FileToKeyValues(kv, hc);
	
	max_sprites 		= 1;	
	
	if(KvGotoFirstSubKey(kv))
	{
		max_sprites_steamid[max_sprites] = 1;
		do
		{
			KvGetSectionName(kv, S_spritename[max_sprites], 64);
			//LogMessage("%s Sprite: %s", TAG_CHAT, S_spritename[max_sprites]);
			
			KvGetString(kv, "path", S_spritepath[max_sprites], 64);
			//LogMessage("%s Path: %s", TAG_CHAT, S_spritepath[max_sprites]);
			
			KvGetString(kv, "flags", S_spriteflag[max_sprites], 64);
			//LogMessage("%s Flags: %s", TAG_CHAT, S_spriteflag[max_sprites]);
			
			KvGetString(kv, "distance_x", S_spritedistance_x[max_sprites], 64);
			//LogMessage("%s Distance X: %s", TAG_CHAT, S_spritedistance_x[max_sprites]);
			
			KvGetString(kv, "distance_y", S_spritedistance_y[max_sprites], 64);
			//LogMessage("%s Distance Y: %s", TAG_CHAT, S_spritedistance_y[max_sprites]);
			
			KvGetString(kv, "distance_z", S_spritedistance_z[max_sprites], 64);
			//LogMessage("%s Distance Z: %s", TAG_CHAT, S_spritedistance_z[max_sprites]);					
			
			KvGetString(kv, "angle_x", S_spriteangle_x[max_sprites], 64);
			//LogMessage("%s Angle X: %s", TAG_CHAT, S_spriteangle_x[max_sprites]);
			
			KvGetString(kv, "angle_y", S_spriteangle_y[max_sprites], 64);
			//LogMessage("%s Angle Y: %s", TAG_CHAT, S_spriteangle_y[max_sprites]);
			
			KvGetString(kv, "angle_z", S_spriteangle_z[max_sprites], 64);
			//LogMessage("%s Angle Z: %s", TAG_CHAT, S_spriteangle_z[max_sprites]);
			
			if(KvJumpToKey(kv, "SteamIDs"))
			{
				for(int i = 1; i <= MAX_STEAMID; ++i)
				{
					char key[64];
					IntToString(i, key, 64);
					
					if(KvGetString(kv, key, S_spritesteamid[max_sprites][i], 64) && strlen(S_spritesteamid[max_sprites][i]))
					{
						//LogMessage("%s [SPRITE%i] - ID: %i, STEAMID: %s", TAG_CHAT, max_sprites, i, S_spritesteamid[max_sprites][i]);
						max_sprites_steamid[max_sprites] = i;
					}
					else
					{
						break;
					}
					
				}
				KvGoBack(kv);
			}
			AddFileToDownloadsTable(S_spritepath[max_sprites]);
			PrecacheModel(S_spritepath[max_sprites]);
			ReplaceString(S_spritepath[max_sprites], 64, ".vmt", ".vtf", false);
			AddFileToDownloadsTable(S_spritepath[max_sprites]);
			ReplaceString(S_spritepath[max_sprites], 64, ".vtf", ".vmt", false);
				
			max_sprites++;
		}
		while (KvGotoNextKey(kv));
	}
	CloseHandle(kv);
	
}

/***********************************************************/
/****************** CHECK IF IS AN ADMIN *******************/
/***********************************************************/
stock bool IsAdminEx(int client)
{
	if(GetUserFlagBits(client) & ADMFLAG_CHANGEMAP 
	/*|| GetUserFlagBits(client) & ADMFLAG_RESERVATION*/
	|| GetUserFlagBits(client) & ADMFLAG_GENERIC
	|| GetUserFlagBits(client) & ADMFLAG_KICK
	|| GetUserFlagBits(client) & ADMFLAG_BAN
	|| GetUserFlagBits(client) & ADMFLAG_UNBAN
	|| GetUserFlagBits(client) & ADMFLAG_SLAY
	|| GetUserFlagBits(client) & ADMFLAG_CHANGEMAP
	|| GetUserFlagBits(client) & ADMFLAG_CONVARS
	|| GetUserFlagBits(client) & ADMFLAG_CONFIG
	|| GetUserFlagBits(client) & ADMFLAG_CHAT
	|| GetUserFlagBits(client) & ADMFLAG_VOTE
	|| GetUserFlagBits(client) & ADMFLAG_PASSWORD
	|| GetUserFlagBits(client) & ADMFLAG_RCON
	|| GetUserFlagBits(client) & ADMFLAG_CHEATS
	|| GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		return true;
	}
	return false;
}

/***********************************************************/
/******************** CHECK IF IS A VIP ********************/
/***********************************************************/
stock bool IsVip(int client)
{
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM2 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM3 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM4 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM5 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
	{
		return true;
	}
	return false;
}