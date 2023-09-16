#pragma semicolon 1 
#include <sourcemod> 
#include <sdktools> 
#include <cstrike> 

new String:g_sArmsModel[MAXPLAYERS+1][128]; 

public OnPluginStart()  
{ 
    HookEvent("item_pickup", Event_ItemPickup); 
    HookEvent("player_spawn", Event_PlayerSpawn); 
     
    HookEvent("round_start", Event_RoundStatusChange); 
    HookEvent("round_end", Event_RoundStatusChange); 
     
    for(new i = 1; i <= MaxClients; i++) 
        if(IsClientInGame(i))  
            OnClientPutInServer(i); 
} 

public OnClientPutInServer(client) 
    ResetStoredArmsModel(client); 

public OnMapStart() 
    CacheAndDownload(); 

public Action:Event_ItemPickup(Handle:event, const String:name[], bool:dontBroadcast)  
{ 
    decl String:sWeapon[64]; 
    GetEventString(event, "item", sWeapon, sizeof(sWeapon)); 
    if (StrEqual(sWeapon, "knife", false))  
    { 
        new client = GetClientOfUserId(GetEventInt(event, "userid")); 
         
        new iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE); 
        if (iWeapon != -1)  
        { 
                SetZombieArmsModel(client); 
        } 
    } 

    return Plugin_Continue; 
}  

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)  
{ 
    new client = GetClientOfUserId(GetEventInt(event, "userid")); 
        StoreArmsModel(client); 
} 

public Action:Event_RoundStatusChange(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
    for (new i = 1; i < MaxClients; i++) 
    { 
        if(!IsClientInGame(i) || !IsPlayerAlive(i)) 
            continue; 
             
        RestoreArmsModel(i); 
         
        if(GetClientTeam(i) == CS_TEAM_T) 
        { 
            CS_SwitchTeam(i, CS_TEAM_CT); 
            CS_SwitchTeam(i, CS_TEAM_T); 
        } 
    } 
} 

CacheAndDownload() 
{ 
    PrecacheModel("models/weapons/ct_arms_gign.mdl"); 
    PrecacheModel("models/player/colateam/zombie1/arms.mdl"); 
     
    AddFileToDownloadsTable("models/player/colateam/zombie1/arms.dx90.vtx"); 
    AddFileToDownloadsTable("models/player/colateam/zombie1/arms.mdl"); 
    AddFileToDownloadsTable("models/player/colateam/zombie1/arms.vvd"); 
     
    AddFileToDownloadsTable("materials/models/player/colateam/zombie1/slow_body.vmt"); 
    AddFileToDownloadsTable("materials/models/player/colateam/zombie1/slow_body.vtf"); 
    AddFileToDownloadsTable("materials/models/player/colateam/zombie1/slow_body_bump.vtf"); 
    AddFileToDownloadsTable("materials/models/player/colateam/zombie1/slow_pants.vmt"); 
    AddFileToDownloadsTable("materials/models/player/colateam/zombie1/slow_pants.vtf"); 
} 

SetZombieArmsModel(client) 
    SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/colateam/zombie1/arms.mdl"); 

StoreArmsModel(client) 
    GetEntPropString(client, Prop_Send, "m_szArmsModel", g_sArmsModel[client], 128); 

RestoreArmsModel(client) 
    SetEntPropString(client, Prop_Send, "m_szArmsModel", g_sArmsModel[client]); 

ResetStoredArmsModel(client) 
    Format(g_sArmsModel[client], 128, "models/weapons/ct_arms_gign.mdl");