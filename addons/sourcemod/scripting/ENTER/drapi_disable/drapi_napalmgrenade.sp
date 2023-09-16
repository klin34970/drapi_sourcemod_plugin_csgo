#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"

new Handle:g_hSlowDowns[MAXPLAYERS+1]={INVALID_HANDLE,...};
new Handle:g_hNapalmTime = INVALID_HANDLE;
new Handle:g_hNapalmRadius = INVALID_HANDLE;

new g_iBeamSprite;


public Plugin:myinfo = 
{
	name = "Equinox Napalm Grenade",
	author = "Zephyrus, ./Moriss, version RIOT by Dr. Api",
	description = "Turns HE Grenade into a napalm grenade.",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	g_hNapalmTime = CreateConVar("sm_napalmgrenade_time", "10.0", "Napalm grenade time");
	g_hNapalmRadius = CreateConVar("sm_napalmgrenade_radius", "600.0", "Napalm grenade radius");

	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("hegrenade_detonate", Event_HEGDetonate);
	for (new client = 1; client <= MaxClients; client++) 
	if (IsClientInGame(client)) 
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	AutoExecConfig(true, "drapi_napalm_grenade", "sourcemod/drapi");
}

public OnMapStart() 
{
	g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public OnClientPutInServer(client)
{
	KillSlowdown(client);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientDisconnect(client)
{
	if (client)
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	new String:class[64];
	if(IsValidEdict(inflictor))
	{
		GetEdictClassname(inflictor, class, 64);
		if(strcmp(class, "entityflame") == 0)
		{
			if(GetClientTeam(victim) == 3)
			{
				damage = 0.0;
				return Plugin_Changed;
			}
			else
			{
				KillSlowdown(victim);
				g_hSlowDowns[victim]=CreateTimer(0.3, Slowdown, victim);
				SetEntPropFloat(victim, Prop_Data, "m_flLaggedMovementValue", 0.75);
				damage = 4.0;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new flags = GetEntityFlags(client);
	if (!(flags & FL_ONFIRE))
		ExtinguishPlayer(client);
}

public Event_HEGDetonate(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new Float:origin[3];
	origin[0] = GetEventFloat(event, "x");
	origin[1] = GetEventFloat(event, "y");
	origin[2] = GetEventFloat(event, "z");
	
	new index = MaxClients+1; decl Float:xyz[3];
	while ((index = FindEntityByClassname(index, "hegrenade_projectile")) != -1)
	{
		GetEntPropVector(index, Prop_Send, "m_vecOrigin", xyz);
		if (xyz[0] == origin[0] && xyz[1] == origin[1] && xyz[2] == origin[2])
			AcceptEntityInput(index, "Kill");
	}
	
	origin[2] += 10.0;
	
	new Float:targetOrigin[3];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || IsClientInGame(i) && GetClientTeam(i) == 3)
			continue;
		
		GetClientAbsOrigin(i, targetOrigin);
		targetOrigin[2] += 2.0;
		if (GetVectorDistance(origin, targetOrigin) <= GetConVarFloat(g_hNapalmRadius))
		{
			new Handle:trace = TR_TraceRayFilterEx(origin, targetOrigin, MASK_SOLID, RayType_EndPoint, FilterTarget, i);
		
			if ((TR_DidHit(trace) && TR_GetEntityIndex(trace) == i) || (GetVectorDistance(origin, targetOrigin) <= 100.0))
			{
				NapalmIgnite(i, GetConVarFloat(g_hNapalmTime));
				CloseHandle(trace);
			}
			else
			{
				CloseHandle(trace);
				
				GetClientEyePosition(i, targetOrigin);
				targetOrigin[2] -= 2.0;
		
				trace = TR_TraceRayFilterEx(origin, targetOrigin, MASK_SOLID, RayType_EndPoint, FilterTarget, i);
			
				if ((TR_DidHit(trace) && TR_GetEntityIndex(trace) == i) || (GetVectorDistance(origin, targetOrigin) <= 100.0))
					NapalmIgnite(i, GetConVarFloat(g_hNapalmTime));
				
				CloseHandle(trace);
			}
		}
	}
	
	TE_SetupBeamRingPoint(origin, 10.0, 600.0, g_iBeamSprite, 0, 1, 1, 1.0, 50.0, 1.0, {255, 64, 64, 64}, 0, 0);
	TE_SendToAll();
}

public bool:FilterTarget(entity, contentsMask, any:data)
{
	return (data == entity);
}

public OnEntityCreated(entity, const String:classname[])
{
	if (IsValidEntity(entity) && IsValidEdict(entity) && strcmp(classname, "hegrenade_projectile")==0)
		SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
}

public OnEntitySpawned(entity)
{
	if (!IsValidEntity(entity))
		return;
	IgniteEntity(entity, 3.0);
	return;
}

bool:NapalmIgnite(client, Float:time)
{
	new flags = GetEntityFlags(client);
	if (flags & FL_ONFIRE)
		ExtinguishPlayer(client);
	IgniteEntity(client, time);
	return true;
}

public ExtinguishPlayer(client)
{
	ExtinguishEntity(client);
	new iFireEnt = GetEntPropEnt(client, Prop_Data, "m_hEffectEntity");
	if (IsValidEntity(iFireEnt))
	{
		decl String:szClassName[64];
		GetEdictClassname(iFireEnt, szClassName, sizeof(szClassName));
		if (StrEqual(szClassName, "entityflame", false))
		{
			SetEntPropFloat(iFireEnt, Prop_Data, "m_flLifetime", 0.0);
		}
	}
}

public Action:Slowdown(Handle:timer, any:client)
{
	g_hSlowDowns[client] = INVALID_HANDLE;
	
	if(!IsClientInGame(client))
		return Plugin_Stop;
	
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	return Plugin_Stop;
}

KillSlowdown(client)
{
	if(g_hSlowDowns[client]!=INVALID_HANDLE)
		KillTimer(g_hSlowDowns[client]);
	g_hSlowDowns[client]=INVALID_HANDLE;
}