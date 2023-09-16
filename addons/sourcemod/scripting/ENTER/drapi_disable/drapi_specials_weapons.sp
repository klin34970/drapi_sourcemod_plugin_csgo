/*<DR.API SPECIALS WEAPONS> (c) by <De Battista Clint - (http://doyou.watch) */
/*                                                                           */
/*             <DR.API SPECIALS WEAPONS> is licensed under a                 */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//**************************DR.API SPECIALS WEAPONS**************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[SPECIALS WEAPONS]-"

#define KATANA							"models/weapons/melee/w_katana.mdl"
#define RIOTSHIELD						"models/weapons/melee/w_riotshield.mdl"
#define MAX_SKINS						200
#define MAX_DAYS 						25

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <stocks>
#include <drapi_afk_manager>
#include <drapi_zombie_riot>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handles
Handle cvar_active_specials_weapons_dev;
Handle cvar_specials_weapons_katana_dmg;
Handle cvar_specials_weapons_riotshield_reduce_dmg;
Handle cvar_specials_weapons_melee_increase_dmg_timer_min;
Handle cvar_specials_weapons_melee_increase_dmg_timer_max;
Handle cvar_specials_weapons_melee_increase_dmg_timer;

Handle TimerMeleeIncreaseDamage								= INVALID_HANDLE;
Handle kvDays 												= INVALID_HANDLE;

//Bools
bool B_active_specials_weapons_dev							= false;
bool B_Melee_increase_damage								= false;

//Float
float F_specials_weapons_katana_dmg;
float F_specials_weapons_melee_increase_dmg_timer_min;
float F_specials_weapons_melee_increase_dmg_timer_max;
float F_specials_weapons_melee_increase_dmg_timer;

float F_Katana_ang[3]										= {-10.0, 0.0, 0.0};
float F_RiotShield_ang[3]									= {280.0, 90.0, 0.0};

float last_time;
float data_specials_weapons_katana_dmg[MAX_DAYS];
float data_specials_weapons_melee_increase_dmg_timer_min[MAX_DAYS];
float data_specials_weapons_melee_increase_dmg_timer_max[MAX_DAYS];
float data_specials_weapons_melee_increase_dmg_timer[MAX_DAYS];

//Strings
char SND_START_INCREASE_DAMAGE[] 							= "UI/armsrace_become_leader_match.wav";
char SND_END_INCREASE_DAMAGE[] 								= "UI/armsrace_become_leader_team.wav";
char S_model_client[PLATFORM_MAX_PATH];
char S_skins[MAX_SKINS][PLATFORM_MAX_PATH];
char S_skins_allowed[MAX_SKINS][PLATFORM_MAX_PATH];

//Customs
int INT_TOTAL_DAY;
int H_specials_weapons_riotshield_reduce_dmg;
int data_specials_weapons_riotshield_reduce_dmg[MAX_DAYS];
int max_skins;
int C_weapons_katana[MAXPLAYERS+1];
int C_weapons_riotshield[MAXPLAYERS+1];

int C_Knife[MAXPLAYERS+1];
int C_Weapon[MAXPLAYERS+1];

int C_State[MAXPLAYERS+1];

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API SPECIALS WEAPONS",
	author = "Dr. Api",
	description = "DR.API SPECIALS WEAPONS by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://doyou.watch"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	AutoExecConfig_SetFile("drapi_specials_weapons", "sourcemod/drapi");
	LoadTranslations("drapi/drapi_specials_weapons.phrases");
	
	AutoExecConfig_CreateConVar("drapi_specials_weapons_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_specials_weapons_dev					= AutoExecConfig_CreateConVar("drapi_active_specials_weapons_dev",								"0",		"Enable/Disable Dev Mod",							DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	cvar_specials_weapons_katana_dmg 					= AutoExecConfig_CreateConVar("drapi_specials_weapons_katana_dmg", 								"200.0", 	"Damage of Katana", 								DEFAULT_FLAGS);
	cvar_specials_weapons_riotshield_reduce_dmg 		= AutoExecConfig_CreateConVar("drapi_specials_weapons_riotshield_reduce_dmg", 					"2", 		"Divide damage", 									DEFAULT_FLAGS);
	
	cvar_specials_weapons_melee_increase_dmg_timer_min 	= AutoExecConfig_CreateConVar("drapi_specials_weapons_melee_increase_dmg_timer_min", 			"30.0", 	"Min time random to increase melee damage weapons", DEFAULT_FLAGS);
	cvar_specials_weapons_melee_increase_dmg_timer_max 	= AutoExecConfig_CreateConVar("drapi_specials_weapons_melee_increase_dmg_timer_max", 			"60.0", 	"Max time random to increase melee damage weapons", DEFAULT_FLAGS);
	cvar_specials_weapons_melee_increase_dmg_timer 		= AutoExecConfig_CreateConVar("drapi_specials_weapons_melee_increase_dmg_timer", 				"20.0", 	"Time to increase melee damage weapons", 			DEFAULT_FLAGS);
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	
	HookEvents();
	
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKHook(i, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
		}
		i++;
	}
	
	AutoExecConfig_ExecuteFile();
}

public Action Command_FX(int client, int args)
{
	float clientpos[3], endpos[3];
	GetClientAbsOrigin(client, clientpos);
	
	endpos[0] = clientpos[0];
	endpos[1] = clientpos[1];
	endpos[2] = clientpos[2];
	
	TE_SetupArmorRicochet(clientpos, endpos);
	TE_SendToAll();
	return Plugin_Handled;
}
/***********************************************************/
/*********************** PLUGIN END **********************/
/***********************************************************/
public void OnPluginEnd()
{
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKUnhook(i, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
		}
		i++;
	}
}

/***********************************************************/
/**************** WHEN CLIENT PUT IN SERVER ****************/
/***********************************************************/
public void OnClientPutInServer(int client)
{
	if (IsClientInGame(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
	}
}

/***********************************************************/
/***************** WHEN CLIENT DISCONNECT ******************/
/***********************************************************/
public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKUnhook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEvents()
{
	HookConVarChange(cvar_active_specials_weapons_dev, 						Event_CvarChange);
	
	HookConVarChange(cvar_specials_weapons_katana_dmg, 						Event_CvarChange);
	HookConVarChange(cvar_specials_weapons_riotshield_reduce_dmg, 			Event_CvarChange);
	
	HookConVarChange(cvar_specials_weapons_melee_increase_dmg_timer_min, 	Event_CvarChange);
	HookConVarChange(cvar_specials_weapons_melee_increase_dmg_timer_max, 	Event_CvarChange);
	HookConVarChange(cvar_specials_weapons_melee_increase_dmg_timer, 		Event_CvarChange);
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
	B_active_specials_weapons_dev 								= GetConVarBool(cvar_active_specials_weapons_dev);
	
	F_specials_weapons_katana_dmg 								= GetConVarFloat(cvar_specials_weapons_katana_dmg);
	H_specials_weapons_riotshield_reduce_dmg 					= GetConVarInt(cvar_specials_weapons_riotshield_reduce_dmg);
	
	F_specials_weapons_melee_increase_dmg_timer_min 			= GetConVarFloat(cvar_specials_weapons_melee_increase_dmg_timer_min);
	F_specials_weapons_melee_increase_dmg_timer_max 			= GetConVarFloat(cvar_specials_weapons_melee_increase_dmg_timer_max);
	F_specials_weapons_melee_increase_dmg_timer 				= GetConVarFloat(cvar_specials_weapons_melee_increase_dmg_timer);
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
	LoadDayData("configs/drapi/zombie_riot/days", "cfg");
	
	AddFileToDownloadsTable("models/weapons/melee/w_katana.mdl");
	AddFileToDownloadsTable("models/weapons/melee/w_katana.phy");
	AddFileToDownloadsTable("models/weapons/melee/w_katana.vvd");
	AddFileToDownloadsTable("models/weapons/melee/w_katana.dx90.vtx");
	AddFileToDownloadsTable("materials/models/weapons/melee/katana.vmt");
	AddFileToDownloadsTable("materials/models/weapons/melee/katana.vtf");
	AddFileToDownloadsTable("materials/models/weapons/melee/katana_normal.vtf");
	
	AddFileToDownloadsTable("models/weapons/melee/w_riotshield.mdl");
	AddFileToDownloadsTable("models/weapons/melee/w_riotshield.phy");
	AddFileToDownloadsTable("models/weapons/melee/w_riotshield.vvd");
	AddFileToDownloadsTable("models/weapons/melee/w_riotshield.dx90.vtx");
	
	AddFileToDownloadsTable("materials/models/weapons/melee/riotshield_metal.vmt");
	AddFileToDownloadsTable("materials/models/weapons/melee/riotshield_metal.vtf");
	AddFileToDownloadsTable("materials/models/weapons/melee/riotshield_metal_normal.vtf");
	AddFileToDownloadsTable("materials/models/weapons/melee/riotshield_plastic.vmt");
	AddFileToDownloadsTable("materials/models/weapons/melee/riotshield_plastic.vtf");
	
	PrecacheModel("models/weapons/melee/w_katana.mdl");
	PrecacheModel("models/weapons/melee/w_riotshield.mdl");
	
	PrecacheSound(SND_START_INCREASE_DAMAGE, true);
	PrecacheSound(SND_END_INCREASE_DAMAGE, true);
	
	LoadSettings();
	UpdateState();
}

/***********************************************************/
/******************** WHEN ROUND START *********************/
/***********************************************************/
public void Event_RoundStart(Handle event, char[] name, bool dontBroadcast)
{	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	B_Melee_increase_damage = false;
	C_State[client] = 0;
}

/***********************************************************/
/********************* WHEN ROUND END **********************/
/***********************************************************/
public void Event_RoundEnd(Handle event, char[] name, bool dontBroadcast)
{	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	ClearTimer(TimerMeleeIncreaseDamage);
	B_Melee_increase_damage = false;
	C_State[client] = 0;
}

/***********************************************************/
/******************* WHEN PLAYER SPAWN *********************/
/***********************************************************/
public void Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_CT && !IsFakeClient(client))
	{

		ChangeWeaponsSkins(client, 1.0, KATANA, "weapon_hand_R", F_Katana_ang);
		ChangeWeaponsSkins(client, 1.5, RIOTSHIELD, "weapon_hand_L", F_RiotShield_ang);
	}
	
	if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_T)
	{
		if(IsValidEntRef(C_weapons_katana[client]))
		{
			RemoveWeaponsSkins(client, 1);
		}
		
		if(IsValidEntRef(C_weapons_riotshield[client]))
		{
			RemoveWeaponsSkins(client, 2);
		}	
	}
}

/***********************************************************/
/******************* WHEN PLAYER SPAWN *********************/
/***********************************************************/
public void Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidEntRef(C_weapons_katana[client]))
	{
		RemoveWeaponsSkins(client, 1);
	}
	
	if(IsValidEntRef(C_weapons_riotshield[client]))
	{
		RemoveWeaponsSkins(client, 2);
	}
	
	C_State[client] = 0;
}

/***********************************************************/
/************ WHEN PLAYER IS AFK MOVE TO SPEC **************/
/***********************************************************/
public void AFK_OnMoveToSpec(int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(IsValidEntRef(C_weapons_katana[client]))
	{
		RemoveWeaponsSkins(client, 1);
	}
	
	if(IsValidEntRef(C_weapons_riotshield[client]))
	{
		RemoveWeaponsSkins(client, 2);
	}
	
	C_State[client] = 0;
}

/***********************************************************/
/******************** ON TAKE DAMAGE ***********************/
/***********************************************************/
public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(Client_IsValid(victim) && Client_IsValid(attacker))
	{
		if(IsValidEntRef(C_weapons_katana[attacker]) && C_Weapon[attacker] == C_Knife[attacker] && GetClientTeam(victim) != GetClientTeam(attacker) && GetClientTeam(victim) == CS_TEAM_T && GetClientTeam(attacker) == CS_TEAM_CT && B_Melee_increase_damage)
		{
			PrintToDev(B_active_specials_weapons_dev, "%sBEFORE DMG KATANA :%f", TAG_CHAT, damage);
			
			damage = GetDayKatanaDamage(ZRiot_GetDay() - 1);
			
			PrintToDev(B_active_specials_weapons_dev, "%sAFTER DMG KATANA :%f", TAG_CHAT, damage);
			
			return Plugin_Changed;
		}
	}

	if(Client_IsValid(victim) && Client_IsValid(attacker))
	{
		if(IsValidEntRef(C_weapons_riotshield[victim]) && C_Weapon[victim] == C_Knife[victim] && GetClientTeam(victim) != GetClientTeam(attacker) && GetClientTeam(attacker) == CS_TEAM_T && GetClientTeam(victim) == CS_TEAM_CT && B_Melee_increase_damage)
		{
			PrintToDev(B_active_specials_weapons_dev, "%sBEFORE DMG SHIELD :%f", TAG_CHAT, damage);
			
			damage = (damage/GetDayShieldReduceDamage(ZRiot_GetDay() - 1));
			
			if(B_active_specials_weapons_dev)
			{
				PrintToChat(victim, "%sAFTER  DMG SHIELD :%f", TAG_CHAT, damage);
			}
			
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

/***********************************************************/
/****************** WHEN PLAYER HOLD KEYS ******************/
/***********************************************************/
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(IsClientInGame(client) && IsPlayerAlive(client) && IsValidEntRef(C_weapons_riotshield[client]) && C_Weapon[client] == C_Knife[client])
	{
		float vAng[3];
		float vAngOld[3];
		
		int entity = C_weapons_riotshield[client];
		
		if( IsValidEntRef(entity) )
		{
			GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);
			vAngOld[0] = vAng[0];
			
			if( ((buttons & IN_FORWARD) || (GetClientButtons(client) & IN_BACK) || (GetClientButtons(client) & IN_MOVERIGHT) || (GetClientButtons(client) & IN_MOVELEFT)) && !(GetClientButtons(client) & IN_DUCK) && C_State[client] != 1)
			{
				vAng[0] = 245.0;
				TeleportEntity(entity, NULL_VECTOR, vAng, NULL_VECTOR);
				C_State[client] = 1;
				PrintToDev(B_active_specials_weapons_dev, "%sMove", TAG_CHAT);
			}
			else if( ((buttons & IN_FORWARD) || (GetClientButtons(client) & IN_BACK) || (GetClientButtons(client) & IN_MOVERIGHT) || (GetClientButtons(client) & IN_MOVELEFT)) && (GetClientButtons(client) & IN_DUCK) && C_State[client] != 2)
			{
				vAng[0] = 300.0;
				TeleportEntity(entity, NULL_VECTOR, vAng, NULL_VECTOR);
				C_State[client] = 2;
				
				PrintToDev(B_active_specials_weapons_dev, "%sDuck", TAG_CHAT);
			}
			else if( ( !(buttons & IN_FORWARD) && !(GetClientButtons(client) & IN_BACK) && !(GetClientButtons(client) & IN_MOVERIGHT) && !(GetClientButtons(client) & IN_MOVELEFT)) && C_State[client] != 3)
			{
				vAng[0] = 280.0;
				TeleportEntity(entity, NULL_VECTOR, vAng, NULL_VECTOR);
				C_State[client] = 3;
				
				PrintToDev(B_active_specials_weapons_dev, "%sUnmove", TAG_CHAT);
			}
		}
	}
}

/***********************************************************/
/********************** ON GAME FRAME **********************/
/***********************************************************/
public void OnGameFrame()
{
	MeleeIncreaseDamage();
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
		{
			if(IsValidEntRef(C_weapons_katana[i]))
			{
				RemoveWeaponsSkins(i, 1);
			}
			
			if(IsValidEntRef(C_weapons_riotshield[i]))
			{
				RemoveWeaponsSkins(i, 2);
			}
		}
		else if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT)
		{
			C_Knife[i] = GetPlayerWeaponSlot(i, 2);
			
			if(IsValidEntity(C_Knife[i]) && C_Weapon[i] == C_Knife[i] && IsValidEntRef(C_weapons_katana[i]))
			{
				if(GetEntityRenderMode(C_Knife[i]) != RENDER_NONE)
				{
					SetEntityRenderMode(C_Knife[i], RENDER_NONE);
				}
			}
		}
	}
}

/***********************************************************/
/**************** WHEN PLAYER SWITCH WEAPON ****************/
/***********************************************************/
public void OnWeaponSwitchPost(int client, int weapon) 
{
	if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_CT)
	{
		C_Weapon[client] = weapon;
		
		PrintToDev(B_active_specials_weapons_dev, "%s Weapon: %i", TAG_CHAT, C_Weapon[client]);
		
		C_Knife[client] = GetPlayerWeaponSlot(client, 2);
		
		PrintToDev(B_active_specials_weapons_dev, "%s Knife: %i", TAG_CHAT, C_Knife[client]);
		
		if(IsValidEntRef(C_weapons_riotshield[client]))
		{
			if(C_Weapon[client] == C_Knife[client])
			{
				AcceptEntityInput(C_weapons_riotshield[client], "EnableCollision");
			}
			else
			{
				AcceptEntityInput(C_weapons_riotshield[client], "DisableCollision");
			}
		}
	}
}

/***********************************************************/
/***************** CHANGE WEAPONS SKINS ********************/
/***********************************************************/
public Action ChangeWeaponsSkins(int client, float scale, char[] model, char[] position, float angle[3])
{
	int ent = CreateEntityByName("prop_dynamic_override");
	if (ent == -1)
	{
		return Plugin_Handled;
	}
	SetEntityModel(ent, model);
	 
	DispatchSpawn(ent);

	//client that spawned this spider
	SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
	
	float or[3];
	float ang[3];
	float fForward[3];
	float fRight[3];
	float fUp[3];
	GetClientAbsOrigin(client, or);
	GetClientAbsAngles(client, ang);
	
	ang[0] += angle[0];
	ang[1] += angle[1];
	ang[2] += angle[2];

	float fOffset[3];
	fOffset[0] = 0.0;
	fOffset[1] = 0.0;
	fOffset[2] = 0.0;

	GetAngleVectors(ang, fForward, fRight, fUp);

	or[0] += fRight[0]*fOffset[0]+fForward[0]*fOffset[1]+fUp[0]*fOffset[2];
	or[1] += fRight[1]*fOffset[0]+fForward[1]*fOffset[1]+fUp[1]*fOffset[2];
	or[2] += fRight[2]*fOffset[0]+fForward[2]*fOffset[1]+fUp[2]*fOffset[2];
	
	TeleportEntity(ent, or, ang, NULL_VECTOR);


	//name the spider
	char iTarget[16];
	Format(iTarget, 16, "client%d", client);
	DispatchKeyValue(client, "targetname", iTarget);
	
	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", client, ent, 0);
	
	SetVariantString(position);
	AcceptEntityInput(ent, "SetParentAttachmentMaintainOffset", ent, ent, 0);

	SetEntProp(ent, Prop_Send, "m_usSolidFlags", 12); //FSOLID_NOT_SOLID|FSOLID_TRIGGER
	SetEntProp(ent, Prop_Data, "m_nSolidType", 6); // SOLID_VPHYSICS
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 2); //COLLISION_GROUP_DEBRIS 
	SetEntProp(ent, Prop_Data, "m_MoveCollide", 0);
	
	AcceptEntityInput( ent, "DisableCollision" );
	AcceptEntityInput( ent, "EnableCollision" );
	
	SetEntPropFloat(ent , Prop_Send,"m_flModelScale", scale);
	
	if(StrEqual(model, KATANA, false))
	{
		C_weapons_katana[client] 	= EntIndexToEntRef(ent);
		
		int knife = GetPlayerWeaponSlot(client, 2);
		if(knife != -1 && SetView(client) != 0)
		{
			SetEntityRenderMode(knife , RENDER_NONE);
		}
		
	}
	else if(StrEqual(model, RIOTSHIELD, false))
	{
		C_weapons_riotshield[client] 	= EntIndexToEntRef(ent);
	}
	
	SDKHook(ent, SDKHook_SetTransmit, ShouldHideMelee);
	
	return Plugin_Handled;  
}

/***********************************************************/
/********************** SHOULD HIDE ************************/
/***********************************************************/
public Action ShouldHideMelee(int ent, int client)
{
	if(IsClientInGame(client))
	{
		int owner 				= GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		int m_hObserverTarget 	= GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
		int knife 				= GetPlayerWeaponSlot(client, 2);
		int weapon 				= GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		
		char S_client[128], S_owner[128];
		GetClientName(client, S_client, sizeof(S_client));
		GetClientName(owner, S_owner, sizeof(S_owner));
		
		if(SetView(owner)==0)
		{
			if(knife != -1)
			{
				SetEntityRenderMode(knife , RENDER_NORMAL);
			}
			return Plugin_Handled;
		}
		else
		{
			/*int katana 		= EntRefToEntIndex(C_weapons_katana[owner]);
			if(IsValidEdict(katana))
			{
				SetVariantString("weapon_hand_R");
				AcceptEntityInput(katana, "SetParentAttachmentMaintainOffset", katana, katana, 0);
			}
			
			if(knife != -1)
			{
				SetEntityRenderMode(knife , RENDER_NONE);
			}
			
			int riotshield 	= EntRefToEntIndex(C_weapons_riotshield[owner]);
			if(IsValidEdict(riotshield))
			{
				SetVariantString("weapon_hand_L");
				AcceptEntityInput(riotshield, "SetParentAttachmentMaintainOffset", riotshield, riotshield, 0);
			}*/
		}
		
		if(IsValidEntRef(C_weapons_katana[owner]) && owner != client)
		{
			int knife_owner 		= GetPlayerWeaponSlot(owner, 2);
			int weapon_owner		= GetEntPropEnt(owner, Prop_Data, "m_hActiveWeapon");
			if(weapon_owner != knife_owner)
			{
				//PrintToChat(owner, "entity: %i, client: %s, owner: %s, knife: %i", ent, S_client, S_owner, knife_owner);
				return Plugin_Handled;			
			}
		}
		else if(IsValidEntRef(C_weapons_katana[owner]) && owner == client)
		{
			if(m_hObserverTarget != 0 || weapon != knife)
			{
				return Plugin_Handled;
			}
		}
		
		if(IsValidEntRef(C_weapons_riotshield[owner]) && owner != client)
		{
			int knife_owner 		= GetPlayerWeaponSlot(owner, 2);
			int weapon_owner		= GetEntPropEnt(owner, Prop_Data, "m_hActiveWeapon");
			if(weapon_owner != knife_owner)
			{
				return Plugin_Handled;			
			}
		}
		else if(IsValidEntRef(C_weapons_riotshield[owner]) && owner == client)
		{
			if(m_hObserverTarget != 0 || weapon != knife)
			{
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}
/***********************************************************/
/****************** REMOVE WEAPONS SKIN ********************/
/***********************************************************/
void RemoveWeaponsSkins(int client, int weapons)
{
	if(C_weapons_katana[client] && weapons == 1)
	{
		int entity = EntRefToEntIndex(C_weapons_katana[client]);
		
		if (entity != -1)
		{
			SDKUnhook(entity, SDKHook_SetTransmit, ShouldHideMelee);
			int knife = GetPlayerWeaponSlot(client, 2);
			if(IsValidEntRef(knife))
			{
				SetEntityRenderMode(knife , RENDER_NORMAL);
			}
			AcceptEntityInput(entity, "Kill");
		}
	}
	else if(IsValidEntRef(C_weapons_riotshield[client]) && weapons == 2)
	{
		int entity = EntRefToEntIndex(C_weapons_riotshield[client]);
		
		if (entity != -1)
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
		
}

/***********************************************************/
/***************** MELEE INCREASE DAMAGE *******************/
/***********************************************************/
void MeleeIncreaseDamage()
{
	float now = GetEngineTime();
	if(now >= last_time)
	{
		last_time = now + GetRandomFloat(GetDayTimerMin(ZRiot_GetDay() - 1), GetDayTimerMax(ZRiot_GetDay() - 1));
		B_Melee_increase_damage = true;
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT)
			{
				float clientpos[3], angle[3];
				GetClientAbsOrigin(i, clientpos);
				
				TE_SetupEnergySplash(clientpos, angle, true);
				TE_SendToAll();	
				ClientCommand(i, "play %s", SND_START_INCREASE_DAMAGE);
			}
		}
		
		TimerMeleeIncreaseDamage = CreateTimer(GetDayTimer(ZRiot_GetDay() - 1), Timer_DeleteMeleeIncreaseDamage);
		CPrintToChatAll("%t", "Increase Damage", RoundFloat(GetDayTimer(ZRiot_GetDay() - 1)));
	}
}

public Action Timer_DeleteMeleeIncreaseDamage(Handle timer)
{
	B_Melee_increase_damage = false;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT)
		{
			ClientCommand(i, "play %s", SND_END_INCREASE_DAMAGE);
		}
	}
	CPrintToChatAll("%t", "Normal Damage", F_specials_weapons_melee_increase_dmg_timer);
	ClearTimer(TimerMeleeIncreaseDamage);
}

/***********************************************************/
/************************ SET VIEW *************************/
/***********************************************************/
int SetView(int client)
{
	int allow;
	GetClientModel(client, S_model_client, PLATFORM_MAX_PATH);
	
	for (int i = 0; i < max_skins; i++)
	{
		if(StrEqual(S_model_client, S_skins[i], false))
		{
			allow = StringToInt(S_skins_allowed[i]);
			return allow;
		}
	}
	return 1;
}

/***********************************************************/
/********************* LOAD FILE SETTING *******************/
/***********************************************************/
public void LoadSettings()
{
	char hc[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, hc, sizeof(hc), "configs/drapi/specials_weapons.cfg");
	
	Handle kv = CreateKeyValues("Skins");
	FileToKeyValues(kv, hc);
	
	max_skins = 0;
	
	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			if(KvGotoFirstSubKey(kv))
			{
				do
				{
					KvGetSectionName(kv, S_skins[max_skins], PLATFORM_MAX_PATH);
					//LogMessage("%s [%i]-Skins: %s", TAG_CHAT, max_skins, S_skins[max_skins]);
					
					KvGetString(kv, "allow", S_skins_allowed[max_skins], PLATFORM_MAX_PATH);
					//LogMessage("%s [%i]-Allow: %s", TAG_CHAT, max_skins, S_skins_allowed[max_skins]);
					
					max_skins++;
				}
				while (KvGotoNextKey(kv));
			}
			KvGoBack(kv);
		}
		while (KvGotoNextKey(kv));
	}
	CloseHandle(kv);
}

/***********************************************************/
/********************* LOAD DAYS DATA **********************/
/***********************************************************/
void LoadDayData(char[] folder, char[] extension)
{
	char path[PLATFORM_MAX_PATH];
	char currentMap[64];
	
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	BuildPath(Path_SM, path, sizeof(path), "%s_%s.%s", folder, currentMap, extension);

	if(!FileExists(path))
	{
		BuildPath(Path_SM, path, sizeof(path), "%s.%s", folder, extension);
	}
		
	ReadDayFile(path);
}

/***********************************************************/
/********************* LOAD DAYS DATA **********************/
/***********************************************************/
void ReadDayFile(char[] path)
{
	if (!FileExists(path))
	{
		return;
	}

	if (kvDays != INVALID_HANDLE)
	{
		CloseHandle(kvDays);
	}

	kvDays = CreateKeyValues("days");
	KvSetEscapeSequences(kvDays, true);

	if (!FileToKeyValues(kvDays, path))
	{
		SetFailState("\"%s\" failed to load", path);
	}

	KvRewind(kvDays);
	if (!KvGotoFirstSubKey(kvDays))
	{
		SetFailState("No day data defined in \"%s\"", path);
	}
	
	INT_TOTAL_DAY = 0;
	do
	{
		data_specials_weapons_katana_dmg[INT_TOTAL_DAY] 									= KvGetFloat(kvDays, 		"katana_damage", 				F_specials_weapons_katana_dmg);
		data_specials_weapons_riotshield_reduce_dmg[INT_TOTAL_DAY] 							= KvGetNum(kvDays, 			"riotshield_reduce_damage", 	H_specials_weapons_riotshield_reduce_dmg);
		
		data_specials_weapons_melee_increase_dmg_timer_min[INT_TOTAL_DAY] 					= KvGetFloat(kvDays, 		"melee_timer_min", 				F_specials_weapons_melee_increase_dmg_timer_min);
		data_specials_weapons_melee_increase_dmg_timer_max[INT_TOTAL_DAY] 					= KvGetFloat(kvDays, 		"melee_timer_max", 				F_specials_weapons_melee_increase_dmg_timer_max);
		data_specials_weapons_melee_increase_dmg_timer[INT_TOTAL_DAY] 						= KvGetFloat(kvDays, 		"melee_timer", 					F_specials_weapons_melee_increase_dmg_timer);
		
		//LogMessage("%s [DAY%i] - Katana damage:%f, Shield reduce damage: %i", TAG_CHAT, INT_TOTAL_DAY, data_specials_weapons_katana_dmg[INT_TOTAL_DAY], data_specials_weapons_riotshield_reduce_dmg[INT_TOTAL_DAY]);
		
		INT_TOTAL_DAY++;
	} 
	while (KvGotoNextKey(kvDays));
}

/***********************************************************/
/******************* GET DAY KATANA DAMAGE *****************/
/***********************************************************/
float GetDayKatanaDamage(int day)
{
    return data_specials_weapons_katana_dmg[day];
}

/***********************************************************/
/*************** GET DAY SHIELD REDUCE DAMAGE **************/
/***********************************************************/
int GetDayShieldReduceDamage(int day)
{
    return data_specials_weapons_riotshield_reduce_dmg[day];
}

/***********************************************************/
/********************* GET DAY TIMER MIN *******************/
/***********************************************************/
float GetDayTimerMin(int day)
{
    return data_specials_weapons_melee_increase_dmg_timer_min[day];
}

/***********************************************************/
/********************* GET DAY TIMER MAX *******************/
/***********************************************************/
float GetDayTimerMax(int day)
{
    return data_specials_weapons_melee_increase_dmg_timer_max[day];
}

/***********************************************************/
/*********************** GET DAY TIMER *********************/
/***********************************************************/
float GetDayTimer(int day)
{
    return data_specials_weapons_melee_increase_dmg_timer[day];
}

/***********************************************************/
/********************* KATANA ANGLE ************************/
/***********************************************************/
public Action Command_KatanaAng(int client, int args)
{

	BuildKatanaAngMenu(client);
	return Plugin_Handled;
}

void BuildKatanaAngMenu(int client)
{
	Menu menu = CreateMenu(KatanaAngMenuHandler);

	AddMenuItem(menu, "", "X + 10.0");
	AddMenuItem(menu, "", "Y + 10.0");
	AddMenuItem(menu, "", "Z + 10.0");
	AddMenuItem(menu, "", "");
	AddMenuItem(menu, "", "X - 10.0");
	AddMenuItem(menu, "", "Y - 10.0");
	AddMenuItem(menu, "", "Z - 10.0");

	SetMenuTitle(menu, "Set hat angles.");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int KatanaAngMenuHandler(Handle menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_End )
		CloseHandle(menu);
	else if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			BuildKatanaAngMenu(client);
	}
	else if( action == MenuAction_Select )
	{
		BuildKatanaAngMenu(client);
		float vAng[3];
		int entity = C_weapons_katana[client];
		if( IsValidEntRef(entity) )
		{
			GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);
			if( index == 0 ) vAng[0] += 10.0;
			else if( index == 1 ) vAng[1] += 10.0;
			else if( index == 2 ) vAng[2] += 10.0;
			else if( index == 4 ) vAng[0] -= 10.0;
			else if( index == 5 ) vAng[1] -= 10.0;
			else if( index == 6 ) vAng[2] -= 10.0;
			TeleportEntity(entity, NULL_VECTOR, vAng, NULL_VECTOR);
		}
		PrintToChat(client, "%f, %f, %f", vAng[0], vAng[1], vAng[2]);
	}
}

/***********************************************************/
/******************* RIOTSHIELD ANGLE **********************/
/***********************************************************/
public Action Command_RiotShieldAng(int client, int args)
{

	BuildRiotShieldAngMenu(client);
	return Plugin_Handled;
}

void BuildRiotShieldAngMenu(int client)
{
	Menu menu = CreateMenu(RiotShieldAngMenuHandler);

	AddMenuItem(menu, "", "X + 10.0");
	AddMenuItem(menu, "", "Y + 10.0");
	AddMenuItem(menu, "", "Z + 10.0");
	AddMenuItem(menu, "", "");
	AddMenuItem(menu, "", "X - 10.0");
	AddMenuItem(menu, "", "Y - 10.0");
	AddMenuItem(menu, "", "Z - 10.0");

	SetMenuTitle(menu, "Set hat angles.");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int RiotShieldAngMenuHandler(Handle menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_End )
		CloseHandle(menu);
	else if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			BuildRiotShieldAngMenu(client);
	}
	else if( action == MenuAction_Select )
	{
		BuildRiotShieldAngMenu(client);
		float vAng[3];
		int entity = C_weapons_riotshield[client];
		if( IsValidEntRef(entity) )
		{
			GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);
			if( index == 0 ) vAng[0] += 10.0;
			else if( index == 1 ) vAng[1] += 10.0;
			else if( index == 2 ) vAng[2] += 10.0;
			else if( index == 4 ) vAng[0] -= 10.0;
			else if( index == 5 ) vAng[1] -= 10.0;
			else if( index == 6 ) vAng[2] -= 10.0;
			TeleportEntity(entity, NULL_VECTOR, vAng, NULL_VECTOR);
		}
		PrintToChat(client, "%f, %f, %f", vAng[0], vAng[1], vAng[2]);
	}
}