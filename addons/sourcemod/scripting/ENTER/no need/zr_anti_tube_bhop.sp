#include <sourcemod>
#include <cstrike>
#include <sdktools>

/*
* Version 1.0
*  - init
*/

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

#define JUMP_COOLDOWN 0.2

public Plugin:myinfo = 
{
    name = "ZR Tube Anti BHop",
    author = "Zipcore",
    description = "Stops Bunnyhoppers inside tubes etc.",
    version = PLUGIN_VERSION,
};

new Float:g_fNextJump[MAXPLAYERS+1];

public OnPluginStart()
{
	CreateConVar("sm_zr_anti_tube_bhop", PLUGIN_VERSION, "", FCVAR_NOTIFY); 
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_jump", Event_Jump);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    g_fNextJump[client] = GetGameTime();
    
    return Plugin_Continue;
}

public Action:Event_Jump(Handle:event,const String:name[],bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    g_fNextJump[client] = GetGameTime()+JUMP_COOLDOWN;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    new Float:time = GetGameTime();
    
    //Is player allowed to jump
    if(buttons & IN_JUMP && g_fNextJump[client] > time)
    {
        buttons &= ~IN_JUMP; //block jump
        TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, Float:{0.0,0.0,0.0}); //Set speed to zero
        return Plugin_Changed;
    }
    
    return Plugin_Continue;
}  