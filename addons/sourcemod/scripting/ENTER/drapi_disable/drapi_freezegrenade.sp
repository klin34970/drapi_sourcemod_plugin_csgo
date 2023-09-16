#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>


#define PLUGIN_VERSION "1.0"

#define SOUND_FREEZE	"physics/glass/glass_impact_bullet4.wav"
#define SOUND_FREEZE_EXPLODE	"ui/freeze_cam.wav"


new Handle:g_hTimers[MAXPLAYERS+1];
new Handle:g_hPredict = INVALID_HANDLE;
new Handle:g_hFreezeTime = INVALID_HANDLE;
new Handle:g_hFreezeRadius = INVALID_HANDLE;

new g_iBeamSprite;
new g_iGlowSprite;

new Float:NULL_VELOCITY[3] = {0.0, 0.0, 0.0};

public Plugin:myinfo = 
{
	name = "Equinox Freeze Grenade, modified by Dr. Api",
	author = "Zephyrus, version RIOT by Dr. Api",
	description = "Turns smoke into a freeze grenade.",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("smokegrenade_detonate", Event_SmokeDetonate, EventHookMode_Pre);

	g_hFreezeTime = CreateConVar("sm_freezegrenade_time", "2.0", "Freeze grenade time");
	g_hFreezeRadius = CreateConVar("sm_freezegrenade_radius", "100.0", "Freeze grenade radius");
	
	for(new i=1;i<=MaxClients;++i)
	{
		if(!IsClientInGame(i))
			continue;
		SDKHook(i, SDKHook_PreThink, Hooks_PreThink);
	}
	
	g_hPredict = FindConVar("sv_client_predict");

	AddNormalSoundHook(NormalSHook);
	
	AddTempEntHook("EffectDispatch", TE_EffectDispatch);
	
	AutoExecConfig(true, "drapi_freeze_grenade", "sourcemod/drapi");
}

public OnMapStart() 
{
	g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iGlowSprite = PrecacheModel("sprites/blueglow2.vmt");
	
	PrecacheSound(SOUND_FREEZE);
	PrecacheSound(SOUND_FREEZE_EXPLODE);
}

public OnClientPutInServer(client)
{
	if (g_hTimers[client] != INVALID_HANDLE)
	{
		KillTimer(g_hTimers[client]);
		g_hTimers[client] = INVALID_HANDLE;
	}
	
	SDKHook(client, SDKHook_PreThink, Hooks_PreThink);
}

public OnClientDisconnect(client)
{
	if (g_hTimers[client] != INVALID_HANDLE)
	{
		KillTimer(g_hTimers[client]);
		g_hTimers[client] = INVALID_HANDLE;
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_hTimers[client] != INVALID_HANDLE)
	{
		KillTimer(g_hTimers[client]);
		g_hTimers[client] = INVALID_HANDLE;
	}
	
	CreateTimer(0.1, Timer_PlayerSpawnPost, GetClientUserId(client));
}

public Action:Timer_PlayerSpawnPost(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(!client)
		return Plugin_Stop;
		
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client);
	if(!IsFakeClient(client))
		SendConVarValue(client, g_hPredict, "1");
		
	return Plugin_Stop;
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_hTimers[client] != INVALID_HANDLE)
	{
		KillTimer(g_hTimers[client]);
		g_hTimers[client] = INVALID_HANDLE;
	}
}

public Action:Event_SmokeDetonate(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new Float:origin[3];
	origin[0] = GetEventFloat(event, "x");
	origin[1] = GetEventFloat(event, "y");
	origin[2] = GetEventFloat(event, "z");
	
	new index = MaxClients+1; decl Float:xyz[3];
	while ((index = FindEntityByClassname(index, "smokegrenade_projectile")) != -1)
	{
		GetEntPropVector(index, Prop_Send, "m_vecOrigin", xyz);
		if (xyz[0] == origin[0] && xyz[1] == origin[1] && xyz[2] == origin[2])
			AcceptEntityInput(index, "Kill");
	}
	
	origin[2] += 10.0;
	
	new Float:targetOrigin[3];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) == 3)
			continue;
		
		GetClientAbsOrigin(i, targetOrigin);
		targetOrigin[2] += 2.0;
		if (GetVectorDistance(origin, targetOrigin) <= GetConVarFloat(g_hFreezeRadius))
		{
			new Handle:trace = TR_TraceRayFilterEx(origin, targetOrigin, MASK_SOLID, RayType_EndPoint, FilterTarget, i);
		
			if ((TR_DidHit(trace) && TR_GetEntityIndex(trace) == i) || (GetVectorDistance(origin, targetOrigin) <= 100.0))
			{
				Freeze(i, GetConVarFloat(g_hFreezeTime));
				CloseHandle(trace);
			}
			else
			{
				CloseHandle(trace);
				
				GetClientEyePosition(i, targetOrigin);
				targetOrigin[2] -= 2.0;
		
				trace = TR_TraceRayFilterEx(origin, targetOrigin, MASK_SOLID, RayType_EndPoint, FilterTarget, i);
			
				if ((TR_DidHit(trace) && TR_GetEntityIndex(trace) == i) || (GetVectorDistance(origin, targetOrigin) <= 100.0))
					Freeze(i, GetConVarFloat(g_hFreezeTime));
				
				CloseHandle(trace);
			}
		}
	}
	
	TE_SetupBeamRingPoint(origin, 10.0, 500.0, g_iBeamSprite, 0, 1, 1, 1.0, 50.0, 1.0, {64, 64, 255, 64}, 0, 0);
	TE_SendToAll();

	dontBroadcast = true;
	return Plugin_Changed;
}

public bool:FilterTarget(entity, contentsMask, any:data)
{
	return (data == entity);
}

bool:Freeze(client, Float:time)
{	
	if (g_hTimers[client] != INVALID_HANDLE)
	{
		KillTimer(g_hTimers[client]);
		g_hTimers[client] = INVALID_HANDLE;
	}
	
	//SetEntityMoveType(client, MOVETYPE_NONE);
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, NULL_VELOCITY);
	
	new Float:vec[3];
	GetClientEyePosition(client, vec);
	vec[2] -= 50.0;
	
	ClientCommand(client, "playgamesound %s", SOUND_FREEZE);

	SetEntityRenderColor(client, 0, 0, 255);
	
	TE_SetupGlowSprite(vec, g_iGlowSprite, time, 2.0, 50);
	TE_SendToAll();
	
	g_hTimers[client] = CreateTimer(time, Unfreeze, client, TIMER_FLAG_NO_MAPCHANGE);
	if(!IsFakeClient(client))
		SendConVarValue(client, g_hPredict, "0");
	return true;
}

public Action:Unfreeze(Handle:timer, any:client)
{
	if (g_hTimers[client] != INVALID_HANDLE)
	{
		//SetEntityMoveType(client, MOVETYPE_WALK);
		g_hTimers[client] = INVALID_HANDLE;
	}
	if(IsClientInGame(client))
	{
		SetEntityRenderColor(client, 255, 255, 255);
		if(!IsFakeClient(client))
		{
			SendConVarValue(client, g_hPredict, "1");
		}
	}
	return Plugin_Stop;
}

public OnEntityCreated(entity, const String:classname[])
{
	if (!strcmp(classname, "smokegrenade_projectile"))
		CreateTimer(1.0, CreateEvent_SmokeDetonate, entity, TIMER_FLAG_NO_MAPCHANGE);
	else if(!strcmp(classname, "env_particlesmokegrenade"))
		AcceptEntityInput(entity, "Kill");
}

public Action:CreateEvent_SmokeDetonate(Handle:timer, any:entity)
{
	if (!IsValidEdict(entity))
		return Plugin_Stop;
	
	decl String:g_szClassname[64];
	GetEdictClassname(entity, g_szClassname, sizeof(g_szClassname));
	if (!strcmp(g_szClassname, "smokegrenade_projectile", false))
	{
		new Float:origin[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
		new userid = GetClientUserId(GetEntPropEnt(entity, Prop_Send, "m_hThrower"));
	
		new Handle:event = CreateEvent("smokegrenade_detonate");
		SetEventInt(event, "userid", userid);
		SetEventFloat(event, "x", origin[0]);
		SetEventFloat(event, "y", origin[1]);
		SetEventFloat(event, "z", origin[2]);
		FireEvent(event, true);
	}
	
	return Plugin_Stop;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:ang[3], &weapon)
{
	if(g_hTimers[client]!=INVALID_HANDLE)
	{
		buttons = 0;
		vel = Float:{0.0, 0.0, 0.0};
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Hooks_PreThink(client)
{
	if(g_hTimers[client]!=INVALID_HANDLE)
		SetEntProp(client, Prop_Data, "m_nButtons", 0);
}


public Action:NormalSHook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	// Block the explosion sound.
	if(StrEqual(sample, ")weapons/smokegrenade/sg_explode.wav"))
	{
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action:TE_EffectDispatch(const String:te_name[], const Players[], numClients, Float:delay)
{
	new iEffectIndex = TE_ReadNum("m_iEffectName");
	new String:sEffectName[64];
	GetEffectName(iEffectIndex, sEffectName, sizeof(sEffectName));
	
	// The particle effect index is stored in m_nHitBox when dispatching a ParticleEffect.
	new nHitBox = TE_ReadNum("m_nHitBox");
	
	if(StrEqual(sEffectName, "ParticleEffect"))
	{
		new String:sParticleEffectName[64];
		GetParticleEffectName(nHitBox, sParticleEffectName, sizeof(sParticleEffectName));
		// Don't show the smoke!
		if(StrEqual(sParticleEffectName, "explosion_smokegrenade", false))
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

stock GetEffectName(index, String:sEffectName[], maxlen)
{
	static table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("EffectDispatch");
	}
	
	ReadStringTable(table, index, sEffectName, maxlen);
}

stock GetParticleEffectName(index, String:sEffectName[], maxlen)
{
	static table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("ParticleEffectNames");
	}
	
	ReadStringTable(table, index, sEffectName, maxlen);
}