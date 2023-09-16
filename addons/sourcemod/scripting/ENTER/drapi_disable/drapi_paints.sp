/*     <DR.API PAINTS> (c) by <De Battista Clint - (http://doyou.watch)      */
/*                                                                           */
/*                    <DR.API PAINTS> is licensed under a                    */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//******************************DR.API PAINTS********************************//
//***************************************************************************//
//***************************************************************************//

/*
"weapon_usp_silencer", 			//61
"weapon_glock", 				//4
"weapon_p250", 					//36
"weapon_fiveseven", 			//3
"weapon_deagle", 				//1
"weapon_elite", 				//2
"weapon_hkp2000",				//32
"weapon_tec9" 					//30


"weapon_nova", 					//35
"weapon_xm1014", 				//25
"weapon_mag7", 					//27
"weapon_sawedoff" 				//29

"weapon_mp9", 					//34
"weapon_mac10", 				//17
"weapon_mag7", 					//27
"weapon_mp7", 					//33
"weapon_ump45", 				//24
"weapon_p90", 					//19
"weapon_bizon" 					//26

"weapon_famas", 				//10
"weapon_m4a1", 					//16
"weapon_m4a1_silencer", 		//60
"weapon_galilar", 				//13
"weapon_ak47", 					//7
"weapon_ssg08", 				//40
"weapon_aug", 					//8
"weapon_sg556", 				//39
"weapon_awp", 					//9
"weapon_scar20", 				//38
"weapon_g3sg1" 					//11
																	
*/
																	
#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[PAINTS] -"
#define MAX_WEAPONS						48
#define MAX_WEAPONS_INDEX				600

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <autoexec>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_paints_dev;

//Bool
bool B_cvar_active_paints_dev										= false;

//Customs
int C_Weapon_kill[MAXPLAYERS + 1][MAX_WEAPONS_INDEX];

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API PAINTS",
	author = "Dr. Api",
	description = "DR.API PAINTS by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://zombie4ever.eu"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	AutoExecConfig_SetFile("drapi_paints", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_paints_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_paints_dev			= AutoExecConfig_CreateConVar("drapi_active_paints_dev", 			"0", 					"Enable/Disable Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	HookEvent("player_death", 	Event_PlayerDeath);
	HookEvent("weapon_fire", 	Event_WeaponFire);
	
	HookEvents();
	
	AutoExecConfig_ExecuteFile();
	
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			SDKHook(i, SDKHook_WeaponEquipPost, OnPostWeaponEquip);
		}
		i++;
	}
	
	RegConsoleCmd("sm_paint", 				Command_Paint, 			"");
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
			SDKUnhook(i, SDKHook_WeaponEquipPost, OnPostWeaponEquip);
		}
		i++;
	}
}

/***********************************************************/
/**************** WHEN CLIENT PUT IN SERVER ****************/
/***********************************************************/
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponEquipPost, OnPostWeaponEquip);
}

/***********************************************************/
/***************** WHEN CLIENT DISCONNECT ******************/
/***********************************************************/
public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_WeaponEquipPost, OnPostWeaponEquip);
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEvents()
{
	HookConVarChange(cvar_active_paints_dev, 				Event_CvarChange);
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
	B_cvar_active_paints_dev 					= GetConVarBool(cvar_active_paints_dev);
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
/********************** WHEN MAP END ***********************/
/***********************************************************/
public void OnMapEnd()
{

}

public Action Command_Paint(int client, int args)
{
	char S_args1[256];
	GetCmdArg(1, S_args1, sizeof(S_args1));
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	SetSkin(client, weapon, StringToInt(S_args1), 0);
}

/***********************************************************/
/******************** WHEN ROUND START *********************/
/***********************************************************/
public void Event_WeaponFire(Handle event, char[] name, bool dontBroadcast)
{
	int client 					= GetClientOfUserId(GetEventInt(event, "userid"));
	int weapon 					= GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	char S_Weaponname[64];
	if(GetEdictClassname(weapon, S_Weaponname, sizeof(S_Weaponname)) && StrEqual(S_Weaponname, "weapon_knife") == false)
	{
		/*
		int ammo 					= GetPrimaryAmmo(client, weapon);
		int clip 					= Weapon_GetPrimaryClip(weapon);
		
		int ammoreserve				= GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount");
		int ammoreserve2			= GetEntProp(weapon, Prop_Send, "m_iSecondaryReserveAmmoCount");
		
		int m_iItemIDHigh			= GetEntProp(weapon, Prop_Send, "m_iItemIDHigh");
		int m_iItemIDLow			= GetEntProp(weapon, Prop_Send, "m_iItemIDLow");
			
		int id						= GetEntProp(weapon, Prop_Send, "m_OriginalOwnerXuidLow");
		int id2						= GetEntProp(weapon, Prop_Send, "m_OriginalOwnerXuidHigh");
		
		int paintkit 				= GetEntProp(weapon, Prop_Send, "m_iEntityQuality");
		*/	
		
		int m_zoomLevel 	= GetEntProp(weapon, Prop_Send, "m_zoomLevel");
		int m_iFOV 			= GetEntProp(client, Prop_Send, "m_iFOV");
		int m_bIsScoped 	= GetEntProp(client, Prop_Send, "m_bIsScoped");
		int m_bResumeZoom 	= GetEntProp(client, Prop_Send, "m_bResumeZoom");
		
		PrintToChat(client, "Zoom: %i, Fov: %i; scope: %i, resume: %i", m_zoomLevel, m_iFOV, m_bIsScoped, m_bResumeZoom);
	}
}

/***********************************************************/
/******************* WHEN PLAYER SPAWN *********************/
/***********************************************************/
public void Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int attacker 			= GetClientOfUserId(GetEventInt(event, "attacker"));
	int weapon 				= GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	
	if(weapon != -1)
	{
		int weaponindex 	= GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		int ammo 			= GetPrimaryAmmo(attacker, weapon);
		int clip1 			= Weapon_GetPrimaryClip(weapon) - 1;
		
		C_Weapon_kill[attacker][weaponindex]++;
		
		Handle dataPackHandle;
		CreateDataTimer(0.0, TimerData_OnPlayerDeath, dataPackHandle);
		WritePackCell(dataPackHandle, EntIndexToEntRef(weapon));
		WritePackCell(dataPackHandle, GetClientUserId(attacker));
		WritePackCell(dataPackHandle, ammo);
		WritePackCell(dataPackHandle, clip1);
	}
}

/***********************************************************/
/************ TIMER DATA ON POST WEAPON EQUIP **************/
/***********************************************************/
public Action TimerData_OnPlayerDeath(Handle timer, Handle dataPackHandle)
{	

	ResetPack(dataPackHandle);
	int weapon 		= EntRefToEntIndex(ReadPackCell(dataPackHandle));
	int client 		= GetClientOfUserId(ReadPackCell(dataPackHandle));
	int ammo 		= ReadPackCell(dataPackHandle);
	int clip1 		= ReadPackCell(dataPackHandle);
	int paintkit 	= GetEntProp(weapon, Prop_Send, "m_nFallbackPaintKit");
	int kill		= GetEntProp(weapon, Prop_Send, "m_nFallbackStatTrak");

	if(weapon == INVALID_ENT_REFERENCE || !IsClientInGame(client) || !IsPlayerAlive(client)) return;
	
	if(weapon < 1 || !IsValidEdict(weapon) || !IsValidEntity(weapon)) return;
	
	if(kill == -1)
	{
		kill = 0;
	}
	
	int weaponindex 	= GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	SetKill(client, weapon, paintkit, C_Weapon_kill[client][weaponindex], ammo, clip1);
}

/***********************************************************/
/****************** ON POST WEAPON EQUIP *******************/
/***********************************************************/
public Action OnPostWeaponEquip(int client, int weapon)
{
	if(weapon != -1)
	{
		Handle dataPackHandle;
		CreateDataTimer(0.0, TimerData_OnPostWeaponEquip, dataPackHandle);
		WritePackCell(dataPackHandle, EntIndexToEntRef(weapon));
		WritePackCell(dataPackHandle, GetClientUserId(client));
	}
}

/***********************************************************/
/************ TIMER DATA ON POST WEAPON EQUIP **************/
/***********************************************************/
public Action TimerData_OnPostWeaponEquip(Handle timer, Handle dataPackHandle)
{
	ResetPack(dataPackHandle);
	int weapon 		= EntRefToEntIndex(ReadPackCell(dataPackHandle));
	int client 		= GetClientOfUserId(ReadPackCell(dataPackHandle));
	
	if(weapon == INVALID_ENT_REFERENCE || !IsClientInGame(client) || !IsPlayerAlive(client)) return;
	
	if(weapon < 1 || !IsValidEdict(weapon) || !IsValidEntity(weapon)) return;

	int weaponindex 	= GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");

	SetSkin(client, weapon, 8, C_Weapon_kill[client][weaponindex]);
}

/***********************************************************/
/******************** SET KNIFE SKIN ***********************/
/***********************************************************/
void SetSkin(int client, int weapon, int paintkit, int kill)
{
	if(GetEntProp(weapon, Prop_Send, "m_hPrevOwner") > 0 || (GetEntProp(weapon, Prop_Send, "m_iItemIDHigh") == 0 && GetEntProp(weapon, Prop_Send, "m_iItemIDLow") == 2048))
	{
		return;
	}
	
	int weaponindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	
	//31 = Taser - 42 = CT knife default - 59 = T knife default
	if(weaponindex == 31 || weaponindex == 42 || weaponindex == 59)
	{
		return;
	}
	
	if(GetPlayerWeaponSlot(client, CS_SLOT_KNIFE) == weapon
	||GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == weapon
	||GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == weapon
	/*||GetPlayerWeaponSlot(client, CS_SLOT_C4) == weapon*/)
	{
		int silenceron 	= GetEntProp(weapon, Prop_Send, "m_bSilencerOn");
		
		char S_Classname[64];
		if(GetEdictClassname(weapon, S_Classname, sizeof(S_Classname)))
		{
		
			char S_Weaponname_2[64];
			if(StrEqual(S_Classname, "weapon_hkp2000") == false)
			{
				if(silenceron)
				{
					Format(S_Weaponname_2, sizeof(S_Weaponname_2), "%s_silencer", S_Classname);
				}
				else
				{
					Format(S_Weaponname_2, sizeof(S_Weaponname_2), "%s", S_Classname);
				}
			}
			else
			{
				if(silenceron)
				{
					Format(S_Weaponname_2, sizeof(S_Weaponname_2), "weapon_usp_silencer");
				}
				else
				{
					Format(S_Weaponname_2, sizeof(S_Weaponname_2), "weapon_hkp2000");
				}			
			}
			
			RemovePlayerItem(client, weapon);
			AcceptEntityInput(weapon, "Kill");
			
			int new_weapon = GivePlayerItem(client, S_Weaponname_2);
			EquipPlayerWeapon(client, new_weapon);
			FakeClientCommand(client, "use %s", S_Weaponname_2);
			
			int m_iItemIDHigh						= GetEntProp(new_weapon, Prop_Send, "m_iItemIDHigh");
			int m_iItemIDLow						= GetEntProp(new_weapon, Prop_Send, "m_iItemIDLow");

			SetEntProp(new_weapon, Prop_Send, "m_iItemIDLow", 2048);
			SetEntProp(new_weapon, Prop_Send, "m_iItemIDHigh", 0);

			SetEntProp(new_weapon, Prop_Send, "m_nFallbackPaintKit", paintkit);
			
			/* 1.0 pattern invisible, 0.5 = 50% visible*/
			SetEntPropFloat(new_weapon, Prop_Send, "m_flFallbackWear", 0.0);
			
			/* Kill number visible on knife */
			SetEntProp(new_weapon, Prop_Send, "m_nFallbackStatTrak", kill);
			
			/* 1 = Authentic, 2 = Retro, 3 = (*) */
			SetEntProp(new_weapon, Prop_Send, "m_iEntityQuality", 3);
			
			
			Handle dataPackHandle2;
			CreateDataTimer(0.004, TimerData_RestoreItemID, dataPackHandle2);
			WritePackCell(dataPackHandle2, EntIndexToEntRef(new_weapon));
			WritePackCell(dataPackHandle2, m_iItemIDHigh);
			WritePackCell(dataPackHandle2, m_iItemIDLow);
		}
	}
}

/***********************************************************/
/******************** SET KNIFE SKIN ***********************/
/***********************************************************/
void SetKill(int client, int weapon, int paintkit, int kill, int ammo, int clip1)
{
	if(GetEntProp(weapon, Prop_Send, "m_OriginalOwnerXuidLow") != 0)
	{
		int weaponindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		
		//31 = Taser - 42 = CT knife default - 59 = T knife default
		if(weaponindex == 31 || weaponindex == 42 || weaponindex == 59)
		{
			return;
		}
		
		if(GetPlayerWeaponSlot(client, CS_SLOT_KNIFE) == weapon
		||GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == weapon
		||GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == weapon
		/*||GetPlayerWeaponSlot(client, CS_SLOT_C4) == weapon*/)
		{
			char S_Classname[64];
			if(GetEdictClassname(weapon, S_Classname, sizeof(S_Classname)))
			{
				int silenceron 	= GetEntProp(weapon, Prop_Send, "m_bSilencerOn");
				
				char S_Weaponname_2[64];
				if(StrEqual(S_Classname, "weapon_hkp2000") == false)
				{
					if(silenceron)
					{
						Format(S_Weaponname_2, sizeof(S_Weaponname_2), "%s_silencer", S_Classname);
					}
					else
					{
						Format(S_Weaponname_2, sizeof(S_Weaponname_2), "%s", S_Classname);
					}
				}
				else
				{
					if(silenceron)
					{
						Format(S_Weaponname_2, sizeof(S_Weaponname_2), "weapon_usp_silencer");
					}
					else
					{
						Format(S_Weaponname_2, sizeof(S_Weaponname_2), "weapon_hkp2000");
					}			
				}
				
				int m_zoomLevel 	= GetEntProp(weapon, Prop_Send, "m_zoomLevel");
				int m_iFOV 			= GetEntProp(client, Prop_Send, "m_iFOV");
				int m_bIsScoped 	= GetEntProp(client, Prop_Send, "m_bIsScoped");
				int m_bResumeZoom 	= GetEntProp(client, Prop_Send, "m_bResumeZoom");
					
				RemovePlayerItem(client, weapon);
				AcceptEntityInput(weapon, "Kill");
				
				int new_weapon = GivePlayerItem(client, S_Weaponname_2);
				EquipPlayerWeapon(client, new_weapon);
				FakeClientCommand(client, "use %s", S_Weaponname_2);
				
				float time = 0.0;
				/* AWP and SCOUT need some time when they fire */
				if(StrEqual(S_Weaponname_2, "weapon_awp", false) 
				|| StrEqual(S_Weaponname_2, "weapon_ssg08", false))
				{
					time = 1.20;
				}
				/* Others sniper doesn't need time and should reset the sates */
				else if(StrEqual(S_Weaponname_2, "weapon_scar20", false) 
				|| StrEqual(S_Weaponname_2, "weapon_aug", false)
				|| StrEqual(S_Weaponname_2, "weapon_g3sg1", false)
				|| StrEqual(S_Weaponname_2, "weapon_sg556", false))
				{
					SetEntProp(weapon, Prop_Send, "m_zoomLevel", m_zoomLevel);
					SetEntProp(client, Prop_Send, "m_iFOV", m_iFOV);
					SetEntProp(client, Prop_Send, "m_bIsScoped", m_bIsScoped);
					SetEntProp(client, Prop_Send, "m_bResumeZoom", m_bResumeZoom);
				}	
				
				if(StrContains(S_Weaponname_2, "weapon_knife", false) == -1 || StrContains(S_Weaponname_2, "weapon_bayonet", false) == -1) 
				{
					Handle dataPackHandle;
					CreateDataTimer(0.0, TimerData_SetCorrectAmmo, dataPackHandle);
					WritePackCell(dataPackHandle, EntIndexToEntRef(new_weapon));
					WritePackCell(dataPackHandle, GetClientUserId(client));
					WritePackCell(dataPackHandle, ammo);
					WritePackCell(dataPackHandle, clip1);
				}
				
				int m_iItemIDHigh	= GetEntProp(new_weapon, Prop_Send, "m_iItemIDHigh");
				int m_iItemIDLow	= GetEntProp(new_weapon, Prop_Send, "m_iItemIDLow");

				SetEntProp(new_weapon, Prop_Send, "m_iItemIDLow", 2048);
				SetEntProp(new_weapon, Prop_Send, "m_iItemIDHigh", 0);

				SetEntProp(new_weapon, Prop_Send, "m_nFallbackPaintKit", paintkit);
				
				/* 1.0 pattern invisible, 0.5 = 50% visible*/
				SetEntPropFloat(new_weapon,Prop_Send, "m_flFallbackWear", 0.0);
				
				/* Kill number visible on knife */
				SetEntProp(new_weapon, Prop_Send, "m_nFallbackStatTrak", kill);
				
				/* 1 = Authentic, 2 = Retro, 3 = (*) */
				SetEntProp(new_weapon, Prop_Send, "m_iEntityQuality", 3);
				
				/* fast next primary attack for the weapon */
				SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", time);
				
				/* fast next attack for the player */
				SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime() + time);
				
				/* Shot Fired 1 or 0 does nothing */
				SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
		
				Handle dataPackHandle2;
				CreateDataTimer(0.004 + time, TimerData_RestoreItemIDKill, dataPackHandle2);
				WritePackCell(dataPackHandle2, EntIndexToEntRef(new_weapon));
				WritePackCell(dataPackHandle2, GetClientUserId(client));
				WritePackCell(dataPackHandle2, m_iItemIDHigh);
				WritePackCell(dataPackHandle2, m_iItemIDLow);
				WritePackCell(dataPackHandle2, m_zoomLevel);
				WritePackCell(dataPackHandle2, m_iFOV);
				WritePackCell(dataPackHandle2, m_bIsScoped);
				WritePackCell(dataPackHandle2, m_bResumeZoom);
			}
		}
	}
}

/***********************************************************/
/************** TIMER DATA SET CORRECT AMMO ****************/
/***********************************************************/
public Action TimerData_SetCorrectAmmo(Handle timer, Handle dataPackHandle)
{
	ResetPack(dataPackHandle);
	int weapon 		= EntRefToEntIndex(ReadPackCell(dataPackHandle));
	int client 		= GetClientOfUserId(ReadPackCell(dataPackHandle));
	int ammo 		= ReadPackCell(dataPackHandle);
	int clip1 		= ReadPackCell(dataPackHandle);
	
	char S_Classname[64];
	if(GetEdictClassname(weapon, S_Classname, sizeof(S_Classname)))
	{
		SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
		Client_SetWeaponAmmo(client, S_Classname, ammo, _, clip1, _);
	}
}

/***********************************************************/
/************** TIMER DATA RESTORE ITEM ID *****************/
/***********************************************************/
public Action TimerData_RestoreItemID(Handle timer, Handle dataPackHandle)
{
	ResetPack(dataPackHandle);
	int weapon 								= EntRefToEntIndex(ReadPackCell(dataPackHandle));
	int m_iItemIDHigh 						= ReadPackCell(dataPackHandle);
	int m_iItemIDLow 						= ReadPackCell(dataPackHandle);

	if(weapon != INVALID_ENT_REFERENCE)
	{
		SetEntProp(weapon, Prop_Send, "m_iItemIDHigh", m_iItemIDHigh);
		SetEntProp(weapon, Prop_Send, "m_iItemIDLow", m_iItemIDLow);
	}
}

/***********************************************************/
/************** TIMER DATA RESTORE ITEM ID *****************/
/***********************************************************/
public Action TimerData_RestoreItemIDKill(Handle timer, Handle dataPackHandle)
{
	ResetPack(dataPackHandle);
	int weapon 								= EntRefToEntIndex(ReadPackCell(dataPackHandle));
	int client 								= GetClientOfUserId(ReadPackCell(dataPackHandle));
	int m_iItemIDHigh 						= ReadPackCell(dataPackHandle);
	int m_iItemIDLow 						= ReadPackCell(dataPackHandle);
			
	int m_zoomLevel							= ReadPackCell(dataPackHandle);
	int m_iFOV								= ReadPackCell(dataPackHandle);
	int m_bIsScoped 						= ReadPackCell(dataPackHandle);
	int m_bResumeZoom 						= ReadPackCell(dataPackHandle);

	if(weapon != INVALID_ENT_REFERENCE)
	{
		SetEntProp(weapon, Prop_Send, "m_iItemIDHigh", m_iItemIDHigh);
		SetEntProp(weapon, Prop_Send, "m_iItemIDLow", m_iItemIDLow);
		
		/* This is for sniper weapons */
		SetEntProp(weapon, Prop_Send, "m_zoomLevel", m_zoomLevel);
		SetEntProp(client, Prop_Send, "m_iFOV", m_iFOV);
		SetEntProp(client, Prop_Send, "m_bIsScoped", m_bIsScoped);
		SetEntProp(client, Prop_Send, "m_bResumeZoom", m_bResumeZoom);
	}
}

/***********************************************************/
/**************** CLIENT SET WEAPON AMMO *******************/
/***********************************************************/
stock bool Client_SetWeaponAmmo(int client, const char[] className, int primaryAmmo=-1, int secondaryAmmo=-1, int primaryClip=-1, int secondaryClip=-1)
{
	int weapon = Client_GetWeapon(client, className);
	
	if (weapon == INVALID_ENT_REFERENCE) 
	{
		return false;
	}
	
	if (primaryClip != -1) 
	{
		Weapon_SetPrimaryClip(weapon, primaryClip);
	}
	if(secondaryClip != -1) 
	{
		Weapon_SetSecondaryClip(weapon, secondaryClip);
	}
	Client_SetWeaponPlayerAmmoEx(client, weapon, primaryAmmo, secondaryAmmo);
	
	return true;
}

/***********************************************************/
/******************* CLIENT GET WEAPON *********************/
/***********************************************************/
stock int Client_GetWeapon(int client, const char[] className)
{
	int offset = Client_GetWeaponsOffset(client) - 4;
	int weapon = INVALID_ENT_REFERENCE;
	for (int i=0; i < MAX_WEAPONS; i++) 
	{
		offset += 4;
		
		weapon = GetEntDataEnt2(client, offset);
		
		if (!Weapon_IsValid(weapon)) 
		{
			continue;
		}
		
		if (Entity_ClassNameMatches(weapon, className)) 
		{
			return weapon;
		}
	}

	return INVALID_ENT_REFERENCE;
}

/***********************************************************/
/*************** ENTITY CLASSNAME MATCHES ******************/
/***********************************************************/
stock bool Entity_ClassNameMatches(int entity, const char[] className, bool partialMatch=false)
{
	char entity_className[64];
	Entity_GetClassName(entity, entity_className, sizeof(entity_className));

	if (partialMatch) 
	{
		return (StrContains(entity_className, className) != -1);
	}

	return StrEqual(entity_className, className);
}

/***********************************************************/
/***************** ENTITY GET CLASSNAME ********************/
/***********************************************************/
stock int Entity_GetClassName(int entity, char[] buffer, int size)
{
	return GetEntPropString(entity, Prop_Data, "m_iClassname", buffer, size);	
}

/***********************************************************/
/******************** WEAPON IS VALID **********************/
/***********************************************************/
stock int Weapon_IsValid(int weapon)
{
	if (!IsValidEdict(weapon)) 
	{
		return false;
	}
	
	return Entity_ClassNameMatches(weapon, "weapon_", true);
}

/***********************************************************/
/*************** GET WEAPON CLIENT OFFSET ******************/
/***********************************************************/
stock int Client_GetWeaponsOffset(int client)
{
	int offset = -1;

	if (offset == -1) 
	{
		offset = FindDataMapOffs(client, "m_hMyWeapons");
	}
	
	return offset;
}

/***********************************************************/
/**************** GET PRIMARY CLIP WEAPON ******************/
/***********************************************************/
stock int Weapon_GetPrimaryClip(int weapon)
{
	return GetEntProp(weapon, Prop_Data, "m_iClip1");
}

/***********************************************************/
/**************** GET PRIMARY CLIP WEAPON ******************/
/***********************************************************/
stock int Weapon_GetSecondaryClip(int weapon)
{
	return GetEntProp(weapon, Prop_Data, "m_iClip2");
}

/***********************************************************/
/**************** SET PRIMARY CLIP WEAPON ******************/
/***********************************************************/
stock int Weapon_SetPrimaryClip(int weapon, int value)
{
	SetEntProp(weapon, Prop_Data, "m_iClip1", value);
}

/***********************************************************/
/************** SET SECONDARY CLIP WEAPON ******************/
/***********************************************************/
stock int Weapon_SetSecondaryClip(int weapon, int value)
{
	SetEntProp(weapon, Prop_Data, "m_iClip2", value);
}

/***********************************************************/
/**************** SET AMMO PLAYER WEAPON *******************/
/***********************************************************/
stock void Client_SetWeaponPlayerAmmoEx(int client, int weapon, int primaryAmmo=-1, int secondaryAmmo=-1)
{
	int offset_ammo = FindDataMapOffs(client, "m_iAmmo");

	if (primaryAmmo != -1) 
	{
		int offset = offset_ammo + (Weapon_GetPrimaryAmmoType(weapon) * 4);
		SetEntData(client, offset, primaryAmmo, 4, true);
	}

	if (secondaryAmmo != -1) 
	{
		int offset = offset_ammo + (Weapon_GetSecondaryAmmoType(weapon) * 4);
		SetEntData(client, offset, secondaryAmmo, 4, true);
	}
}

/***********************************************************/
/***************** GET PRIMARY AMMO TYPE *******************/
/***********************************************************/
stock int Weapon_GetPrimaryAmmoType(int weapon)
{
	return GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
}

/***********************************************************/
/**************** GET SECONDARY AMMO TYPE ******************/
/***********************************************************/
stock int Weapon_GetSecondaryAmmoType(int weapon)
{
	return GetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoType");
}

/***********************************************************/
/******************** GET PRIMARY AMMO *********************/
/***********************************************************/
stock int GetPrimaryAmmo(int client, int weapon)
{
    int ammotype = Weapon_GetPrimaryAmmoType(weapon);
    if(ammotype == -1) 
	{
		return -1;
	}
    
    return GetEntProp(client, Prop_Send, "m_iAmmo", _, ammotype);
}

/***********************************************************/
/********************* IS VALID CLIENT *********************/
/***********************************************************/
stock bool Client_IsValid(int client, bool checkConnected=true)
{
	if (client > 4096) {
		client = EntRefToEntIndex(client);
	}

	if (client < 1 || client > MaxClients) {
		return false;
	}

	if (checkConnected && !IsClientConnected(client)) {
		return false;
	}
	
	return true;
}

/***********************************************************/
/******************** IS CLIENT IN GAME ********************/
/***********************************************************/
stock bool Client_IsIngame(int client)
{
	if (!Client_IsValid(client, false)) {
		return false;
	}

	return IsClientInGame(client);
} 

