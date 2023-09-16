/*   <DR.API ANIMATIONS> (c) by <De Battista Clint - (http://doyou.watch)    */
/*                                                                           */
/*                  <DR.API ANIMATIONS> is licensed under a                  */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//*****************************DR.API ANIMATIONS*****************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[ANIMATIONS] -"
#define EF_BONEMERGE					1
#define EF_BONEMERGE_FASTCULL			128
#define EF_NOSHADOW						16
#define EF_PARENT_ANIMATES				512
#define DEVELOPER						"STEAM_1:1:4489913"
#define MSG_LENGTH 192

#if !defined CHAT_HIGHLIGHT_INC
#define CHAT_HIGHLIGHT_INC 				"\x04"
#endif

#if !defined CHAT_NORMAL_INC
#define CHAT_NORMAL_INC 				"\x01"
#endif

#if !defined TAG_CHAT_INC
#define TAG_CHAT_INC 					"[DEBUG] - "
#endif

//***********************************//
//*************INCLUDE***************//
//***********************************//
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <autoexec>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_animations_dev;

Handle TimerResetState[MAXPLAYERS+1]				= INVALID_HANDLE;

//Bool
bool B_cvar_active_animations_dev					= false;

//Strings
char S_ClientModel[MAXPLAYERS+1][PLATFORM_MAX_PATH];

//Customs
C_State[MAXPLAYERS+1];
C_Clone[MAXPLAYERS+1]								= INVALID_ENT_REFERENCE;

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API ANIMATIONS",
	author = "Dr. Api",
	description = "DR.API ANIMATIONS by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://zombie4ever.eu"
}

/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	AutoExecConfig_SetFile("drapi_animations", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_animations_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_animations_dev			= AutoExecConfig_CreateConVar("drapi_active_animations_dev", 			"0", 					"Enable/Disable Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	HookEvents();
	
	AutoExecConfig_ExecuteFile();
	
	RegAdminCmd("sm_model", Command_Model, ADMFLAG_CHANGEMAP, "");
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
			if(IsValidEntRef(C_Clone[i]))
			{
				ClearClone(i);
			}
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
	HookConVarChange(cvar_active_animations_dev, 				Event_CvarChange);
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
	B_cvar_active_animations_dev 					= GetConVarBool(cvar_active_animations_dev);
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
/************************ CMD MODEL ************************/
/***********************************************************/
public Action Command_Model(int client, int args)
{
	if(IsValidEntRef(C_Clone[client]))
	{
		ClearClone(client);
	}
	else
	{
		CreateClone(client, "models/infected/anim_boomer.mdl", "models/player/zombie_fast.mdl", "idle_standing");
	}
	return Plugin_Handled;
}

/***********************************************************/
/********************* CREATE CLONE ************************/
/***********************************************************/
public bool CreateClone(int client, char[] client_model, char[] prop_model, char[] idle_anim)
{
	int ent = CreateEntityByName("prop_dynamic_override");

	if(!IsModelPrecached(client_model))
	{
    	if(!PrecacheModel(client_model))
    	{
    		return false;
    	}
    }
	
	if(!IsModelPrecached(prop_model))
	{
    	if(!PrecacheModel(prop_model))
    	{
    		return false;
    	}
    }
	
	if(IsValidEntity(ent))
	{
		GetClientModel(client, S_ClientModel[client], PLATFORM_MAX_PATH);
		SetEntityModel(client, client_model);
		SetEntityModel(ent, prop_model);
		
		DispatchSpawn(ent);
		
		SetEntProp(ent, Prop_Data, "m_takedamage", 0);
		SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
		SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client);
		SetEntProp(ent, Prop_Data, "m_iMaxHealth", 1000000);
		SetEntProp(ent, Prop_Data, "m_iHealth", 1000000);

		AcceptEntityInput(ent, "DisableCollision" );
		AcceptEntityInput(client, "DisableCollision" );

		SetVariantString(idle_anim);
		AcceptEntityInput(ent, "SetAnimation", -1, -1, 0); 

		float pos[3], angle[3];
		GetClientAbsOrigin(client, pos);
		GetClientAbsAngles(client, angle);
		

		TeleportEntity(ent, pos, angle, NULL_VECTOR);


		char iTarget[16];
		Format(iTarget, 16, "client%d", client);
		DispatchKeyValue(client, "targetname", iTarget);

		SetVariantString(iTarget);
		AcceptEntityInput(ent, "SetParent");
		
		
		SDKHook(ent, SDKHook_SetTransmit, ShouldHide);
		
		C_Clone[client] = EntIndexToEntRef(ent);
		return true;
	}
	
	return false;
}

/***********************************************************/
/********************** CLEAR CLONE ************************/
/***********************************************************/
stock bool ClearClone(int client)
{
	if(IsValidEntRef(C_Clone[client]))
	{
		int entity = EntRefToEntIndex(C_Clone[client]);
		
		AcceptEntityInput(entity, "Kill");
		C_Clone[client]		= INVALID_ENT_REFERENCE;
		if(IsPlayerAlive(client))
		{
			SetBackEntityModel(client);
		}
		return true;
	}

	return false;
}

/***********************************************************/
/***************** SET BACK ENTITY MODEL *******************/
/***********************************************************/
bool SetBackEntityModel(int client)
{
	SetEntityModel(client, S_ClientModel[client]);
}

/***********************************************************/
/********************** SHOULD HIDE ************************/
/***********************************************************/
public Action ShouldHide(int ent, int client)
{
	if(IsClientInGame(client))
	{
		int owner 				= GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		int m_hObserverTarget 	= GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
		
		if(owner == client)
		{
			if(m_hObserverTarget != 0)
			{
				return Plugin_Handled;
			}
		}
	
	}
	return Plugin_Continue;
}

/***********************************************************/
/****************** WHEN PLAYER HOLD KEYS ******************/
/***********************************************************/
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	//0 			= IDLE
	//2 			= JUMP
	//10            = RUN + JUMP
	//4 			= CROUCH
	//8 			= RUN FRONT
	//16 			= RUN BACK
	//512 			= LEFT
	//1024 			= RIGHT
	//131080 		= WALK FRONT
	//131088 		= WALK BACK
	//132096 		= WALK RIGH
	//131584 		= WALK LEFT
	//1 			= CLICK LEFT
	//2048 			= CLICK RIGHT
	
	//(GetClientButtons(client) & IN_FORWARD)
	//(GetClientButtons(client) & IN_BACK)
	//(GetClientButtons(client) & IN_MOVERIGHT)
	//(GetClientButtons(client) & IN_MOVELEFT)
	//(GetClientButtons(client) & IN_JUMP)
	
	//float m_flPlaybackRate		= GetEntPropFloat(C_Clone[client], Prop_Send, "m_flPlaybackRate");
	//float m_flCycle 				= GetEntPropFloat(C_Clone[client], Prop_Send, "m_flCycle");
	//int m_nSequence 				= GetEntProp(C_Clone[client], Prop_Send, "m_nSequence");
	//int m_flAnimTime 				= GetEntProp(C_Clone[client], Prop_Send, "m_flAnimTime");
	//int m_bAnimatedEveryTick 		= GetEntProp(C_Clone[client], Prop_Send, "m_bAnimatedEveryTick");
	
	//PrintToDev(B_cvar_active_animations_dev, "%i", m_nSequence);
	
	if(IsValidEntRef(C_Clone[client]))
	{
		if(IsIdle(client))
		{
				SetVariantString("idle_standing");
				AcceptEntityInput(C_Clone[client], "SetAnimation");				
				ClearTimer(TimerResetState[client]);
		}
		
		if(!InTheAir(client))
		{
			if(MoveForward(client) 
			|| MoveForwardRight(client) 
			|| MoveForwardLeft(client))
			{
				SetVariantString("zombie_leap_mid");
				AcceptEntityInput(C_Clone[client], "SetAnimation");
				//ClearTimer(TimerResetState[client]);				
				//TimerResetState[client] = CreateTimer(1.0, Timer_ResetState, client);
				
			}
			
			if(MoveBackward(client)
			|| MoveBackwardRight(client)
			|| MoveBackwardLeft(client))
			{
				SetVariantString("shoved_backward");
				AcceptEntityInput(C_Clone[client], "SetAnimation");	
				ClearTimer(TimerResetState[client]);				
				TimerResetState[client] = CreateTimer(0.5, Timer_ResetState, client);				
			}


			if(MoveRight(client))
			{
				SetVariantString("shoved_rightward");
				AcceptEntityInput(C_Clone[client], "SetAnimation");	
				ClearTimer(TimerResetState[client]);				
				TimerResetState[client] = CreateTimer(0.5, Timer_ResetState, client);
			}
			else if(MoveLeft(client))
			{
				SetVariantString("shoved_leftward");
				AcceptEntityInput(C_Clone[client], "SetAnimation");		
				ClearTimer(TimerResetState[client]);				
				TimerResetState[client] = CreateTimer(0.5, Timer_ResetState, client);
			}
			
		}
		if(Jump(client))
		{
				SetVariantString("jump");
				AcceptEntityInput(C_Clone[client], "SetAnimation");	
				ClearTimer(TimerResetState[client]);			
		}
	}
}

public Action Timer_ResetState(Handle timer, any client)
{
	C_State[client] = 0;
	TimerResetState[client] = INVALID_HANDLE;
}

/***********************************************************/
/********************* MOVE FORWARD ************************/
/***********************************************************/
bool MoveForward(int client)
{
	if((GetClientButtons(client) & IN_FORWARD) && !(GetClientButtons(client) & IN_BACK) && !(GetClientButtons(client) & IN_MOVERIGHT) && !(GetClientButtons(client) & IN_MOVELEFT) && C_State[client] != 2)
	{
		PrintToDev(B_cvar_active_animations_dev, "MoveForward");
		C_State[client] = 2;
		return true;
	}
	return false;
}

/***********************************************************/
/******************** MOVE BACKWARD ************************/
/***********************************************************/
bool MoveBackward(int client)
{
	if(!(GetClientButtons(client) & IN_FORWARD) && (GetClientButtons(client) & IN_BACK) && !(GetClientButtons(client) & IN_MOVERIGHT) && !(GetClientButtons(client) & IN_MOVELEFT) && C_State[client] != 4)
	{
		PrintToDev(B_cvar_active_animations_dev, "MoveBackward");
		C_State[client] = 4;
		return true;
	}
	return false;
}

/***********************************************************/
/********************** MOVE RIGHT *************************/
/***********************************************************/
bool MoveRight(int client)
{
	if(!(GetClientButtons(client) & IN_FORWARD) && !(GetClientButtons(client) & IN_BACK) && (GetClientButtons(client) & IN_MOVERIGHT) && !(GetClientButtons(client) & IN_MOVELEFT) && C_State[client] != 8)
	{
		PrintToDev(B_cvar_active_animations_dev, "MoveRight");
		C_State[client] = 8;
		return true;
	}
	return false;
}

/***********************************************************/
/********************** MOVE LEFT **************************/
/***********************************************************/
bool MoveLeft(int client)
{
	if(!(GetClientButtons(client) & IN_FORWARD) && !(GetClientButtons(client) & IN_BACK) && !(GetClientButtons(client) & IN_MOVERIGHT) && (GetClientButtons(client) & IN_MOVELEFT) && C_State[client] != 16)
	{
		PrintToDev(B_cvar_active_animations_dev, "MoveLeft");
		C_State[client] = 16;
		return true;
	}
	return false;
}

/***********************************************************/
/****************** MOVE FORWARD RIGHT *********************/
/***********************************************************/
bool MoveForwardRight(int client)
{
	if((GetClientButtons(client) & IN_FORWARD) && !(GetClientButtons(client) & IN_BACK) && (GetClientButtons(client) & IN_MOVERIGHT) && !(GetClientButtons(client) & IN_MOVELEFT) && C_State[client] != 32)
	{
		PrintToDev(B_cvar_active_animations_dev, "MoveForwardRight");
		C_State[client] = 32;
		return true;
	}
	return false;
}

/***********************************************************/
/******************* MOVE FORWARD LEFT**********************/
/***********************************************************/
bool MoveForwardLeft(int client)
{
	if((GetClientButtons(client) & IN_FORWARD) && !(GetClientButtons(client) & IN_BACK) && !(GetClientButtons(client) & IN_MOVERIGHT) && (GetClientButtons(client) & IN_MOVELEFT) && C_State[client] != 64)
	{
		PrintToDev(B_cvar_active_animations_dev, "MoveForwardLeft");
		C_State[client] = 64;
		return true;
	}
	return false;
}

/***********************************************************/
/****************** MOVE BACKWARD RIGHT ********************/
/***********************************************************/
bool MoveBackwardRight(int client)
{
	if(!(GetClientButtons(client) & IN_FORWARD) && (GetClientButtons(client) & IN_BACK) && (GetClientButtons(client) & IN_MOVERIGHT) && !(GetClientButtons(client) & IN_MOVELEFT) && C_State[client] != 128)
	{
		PrintToDev(B_cvar_active_animations_dev, "MoveBackwardRight");
		C_State[client] = 128;
		return true;
	}
	return false;
}

/***********************************************************/
/****************** MOVE BACKWARD LEFT *********************/
/***********************************************************/
bool MoveBackwardLeft(int client)
{
	if(!(GetClientButtons(client) & IN_FORWARD) && (GetClientButtons(client) & IN_BACK) && !(GetClientButtons(client) & IN_MOVERIGHT) && (GetClientButtons(client) & IN_MOVELEFT) && C_State[client] != 256)
	{
		PrintToDev(B_cvar_active_animations_dev, "MoveBackwardLeft");
		C_State[client] = 256;
		return true;
	}
	return false;
}

/***********************************************************/
/************************* JUMP ****************************/
/***********************************************************/
bool Jump(int client)
{
	if((GetClientButtons(client) & IN_JUMP) && InTheAir(client) && C_State[client] != 512)
	{
		PrintToDev(B_cvar_active_animations_dev, "Jump");
		C_State[client] = 512;
		return true;
	}
	return false;
}

/***********************************************************/
/********************** IN THE AIR *************************/
/***********************************************************/
bool InTheAir(int client)
{
	if(!(GetEntityFlags(client) & FL_ONGROUND))
	{
		return true;
	}
	return false;
}

bool IsIdle(int client)
{
	if(!InTheAir(client) && GetClientButtons(client) == 0 && C_State[client] != 1024)
	{
		PrintToDev(B_cvar_active_animations_dev, "Idle");
		C_State[client] = 1024;
		return true;
	}
	return false;
}

/***********************************************************/
/****************** GET CLIENT BY STEAM ID *****************/
/***********************************************************/
stock int GetClientBySteamIDEx(char[] steamid)
{
	char steamId[64];
	for(int i=1;i<=MaxClients;++i)
	{
		if(!Client_IsIngame(i))
			continue;
		if(!IsClientAuthorized(i))
			continue;
		GetClientAuthId(i, AuthId_Steam2, steamId, sizeof(steamId));
		if (StrEqual(steamId, steamid))
			return i;
	}
	return 0;
}

/***********************************************************/
/*********************** PRINT TO DEV **********************/
/***********************************************************/
stock void PrintToDev(bool status, char[] format, any ...)
{
	if(status)
	{
		int client = GetClientBySteamIDEx(DEVELOPER);
		if(client)
		{
			char msg[MSG_LENGTH];
			char msg2[MSG_LENGTH];
			Format(msg, MSG_LENGTH, "%s%s%s%s", CHAT_HIGHLIGHT_INC, TAG_CHAT_INC, CHAT_NORMAL_INC, format);
			VFormat(msg2, MSG_LENGTH, msg, 3);
			
			Handle hBf;
			hBf = StartMessageOne("SayText2", client);
			if (hBf != INVALID_HANDLE)
			{
				if (GetUserMessageType() == UM_Protobuf)
				{
					PbSetInt(hBf, "ent_idx", client);
					PbSetBool(hBf, "chat", false);

					PbSetString(hBf, "msg_name", msg2);
					PbAddString(hBf, "params", "");
					PbAddString(hBf, "params", "");
					PbAddString(hBf, "params", "");
					PbAddString(hBf, "params", "");
				}
				else
				{
					BfWriteByte(hBf, client); 
					BfWriteByte(hBf, 0); 
					BfWriteString(hBf, msg2);
				}
				EndMessage();
			}
		}
	}
}

/***********************************************************/
/******************** LOG TO ZOMBIE RIOT *******************/
/***********************************************************/
stock void LogToAnimations(bool status, const char[] format, any ...)
{
	if(status)
	{
		char msg[MSG_LENGTH];
		char msg2[MSG_LENGTH];
		char logfile[MSG_LENGTH];
		Format(msg, MSG_LENGTH, "%s", format);
		VFormat(msg2, MSG_LENGTH, msg, 3);
		
		BuildPath(Path_SM, logfile, sizeof(logfile), "logs/drapi_animations.txt");
		LogToFile(logfile, msg2);
	}
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

/***********************************************************/
/******************** IS VALID ENTITY **********************/
/***********************************************************/
stock bool IsValidEntRef(int entity)
{
	if(entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE)
	{
		return true;
	}
	return false;
}

/***********************************************************/
/********************** CLEAR TIMER ************************/
/***********************************************************/
stock void ClearTimer(Handle &timer)
{
    if (timer != INVALID_HANDLE)
    {
        KillTimer(timer);
        timer = INVALID_HANDLE;
    }     
}