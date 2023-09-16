#include <sourcemod>
#include <sdktools>
#include <timer>
#include <timer-physics>

new Float:g_fVelocity[MAXPLAYERS+1][3];
new Float:g_fBlock[MAXPLAYERS+1];

public Plugin:myinfo =
{
name        = "[TIMER] Smooth Ramps",
author      = "Zipcore, Jason Bourne",
description = "[TIMER] Smooth Ramps",
version     = PL_VERSION,
url         = "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnClientApplyDifficulty(client, style)
{
	g_fBlock[client] = GetGameTime()+0.5;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	if(!IsPlayerAlive(client))
		return Plugin_Continue;
	
	decl Float:fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
	new Float:currentspeed = SquareRoot(Pow(fVelocity[0],2.0)+Pow(fVelocity[1],2.0));
	new Float:oldspeed = SquareRoot(Pow(g_fVelocity[client][0],2.0)+Pow(g_fVelocity[client][1],2.0));
	
	if(currentspeed-oldspeed < -100.0 && g_fBlock[client] < GetGameTime())
	{
		decl Float:fOrigin[3];
		GetClientAbsOrigin(client, fOrigin);
		fOrigin[2] += 5.0;
		TeleportEntity(client, fOrigin, NULL_VECTOR, g_fVelocity[client]);
	}
	
	g_fVelocity[client][0] = fVelocity[0];
	g_fVelocity[client][1] = fVelocity[1];
	g_fVelocity[client][2] = fVelocity[2];
	
	return Plugin_Continue;
}