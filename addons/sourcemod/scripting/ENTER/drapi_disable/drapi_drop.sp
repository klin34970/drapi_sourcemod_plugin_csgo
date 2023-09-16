#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PL_VERSION "1.0.0"

#pragma semicolon 1
#pragma newdecls required

ConVar g_cEnable;
ConVar g_cTaser;
ConVar g_cHEGrenade;
ConVar g_cFlash;
ConVar g_cSmoke;
ConVar g_cIncGrenade;
ConVar g_cMolotov;
ConVar g_cDecoy;
float F_buytime;
B_AllowToDrop[MAXPLAYERS+1];


public Plugin myinfo =
{
	name = "Drop",
	author = "Bara, modified by Dr.Api",
	version = PL_VERSION,
	description = "",
	url = ""
};

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_CSS && GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("Only CSS and CSGO Support");
		return ;
	}
	
	CreateConVar("cs_drop_version", PL_VERSION, "With this Plugin you can drop your grenades and knives.", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	
	g_cEnable = CreateConVar("drop_enable", "1", "Should be enabled this plugin?");
	g_cTaser = CreateConVar("drop_taser", "1", "Enable \"taser\" drop?");
	g_cHEGrenade = CreateConVar("drop_hegrenade", "1", "Enable \"hegrenade\" drop?");
	g_cFlash = CreateConVar("drop_flashbang", "1", "Enable \"flashbang\" drop?");
	g_cSmoke = CreateConVar("drop_smokegrenade", "1", "Enable \"smokegrenade\" drop?");
	g_cIncGrenade = CreateConVar("drop_incgrenace", "1", "Enable \"incgrenade\" drop?");
	g_cMolotov = CreateConVar("drop_molotov", "1", "Enable \"molotov\" drop?");
	g_cDecoy = CreateConVar("drop_decoy", "1", "Enable \"decoy\" drop?");
	
	HookEvent("round_start",	Event_RoundStart);
	
	AutoExecConfig();

	AddCommandListener(Command_Drop, "drop");
}

public void Event_RoundStart(Handle event, char[] name, bool dontBroadcast)
{
	F_buytime = GetConVarFloat(FindConVar("mp_buytime"));
	AllowToDrop(false);
	CreateTimer(F_buytime, Timer_UnlockDrop);
	
	//PrintToChatAll("F_buytime: %f", F_buytime);
}

public Action Timer_UnlockDrop(Handle timer)
{
	AllowToDrop(true);
	//PrintToChatAll("AllowToDrop true");
}

void AllowToDrop(bool drop)
{
	for(int i = 1; i <= MaxClients; i++) 
	{
		if(IsClientInGame(i))
		{
			if(drop)
			{
				B_AllowToDrop[i] = true;
			}
			else
			{
				B_AllowToDrop[i] = false;
			}
		}
	}
}

public Action Command_Drop(int client, const char[] command, int args)
{
	if(!g_cEnable.BoolValue)
		return Plugin_Continue;
	
	if (IsClientInGame(client))
	{
		char sName[32];
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(!IsValidEdict(weapon))
		{
			return Plugin_Stop;
		}

		GetEdictClassname(weapon, sName, sizeof(sName));

		if (StrEqual("weapon_taser", sName, false) && g_cTaser.BoolValue)
		{
			if (GetEntProp(weapon, Prop_Data, "m_iClip1") > 0)
			{
				int iSequence = GetEntProp(weapon, Prop_Data, "m_nSequence");
				if((GetEngineVersion() == Engine_CSS && iSequence != 5) || (GetEngineVersion() == Engine_CSGO && iSequence != 2))
				{
					if(!B_AllowToDrop[client]) return Plugin_Stop;
					SDKHooks_DropWeapon(client, weapon);
					return Plugin_Handled;
				}
			}
		}
		else if (StrEqual("weapon_hegrenade", sName, false) && g_cHEGrenade.BoolValue ||
				StrEqual("weapon_flashbang", sName, false) && g_cFlash.BoolValue ||
				StrEqual("weapon_smokegrenade", sName, false) && g_cSmoke.BoolValue ||
				StrEqual("weapon_incgrenade", sName, false) && g_cIncGrenade.BoolValue ||
				StrEqual("weapon_molotov", sName, false) && g_cMolotov.BoolValue ||
				StrEqual("weapon_decoy", sName, false) && g_cDecoy.BoolValue ||
				StrEqual("weapon_knife", sName, false))
		{
			int iSequence = GetEntProp(weapon, Prop_Data, "m_nSequence");
			if((GetEngineVersion() == Engine_CSS && iSequence != 5) || (GetEngineVersion() == Engine_CSGO && iSequence != 2))
			{
				if(!B_AllowToDrop[client]) return Plugin_Stop;
				SDKHooks_DropWeapon(client, weapon);
				return Plugin_Handled;
			}
		}
		
	}
	return Plugin_Continue;
	
}