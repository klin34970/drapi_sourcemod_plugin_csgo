#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>
 
public Plugin:myinfo =
{
        name = "ZR Custom CS:GO Arms, modified by Dr. Api",
        author = "Franc1sco franug, Zombie riot version by Dr. Api",
        description = "",
        version = "3.0",
        url = "http://www.zeuszombie.com"
};
 
new String:manos[MAXPLAYERS+1][128];
 
public OnPluginStart()
{
        //array_manos = CreateArray();
        HookEvent("item_pickup", OnItemPickup);
        HookEvent("player_spawn", OnSpawn);
       
        HookEvent("round_start", Event_Round_End);
        HookEvent("round_end", Event_Round_End);
       
        for(new i = 1; i <= MaxClients; i++)
                if(IsClientInGame(i)) OnClientPutInServer(i);
}
 
public OnClientPutInServer(client)
{
        Format(manos[client], 128, "models/weapons/ct_arms_gign.mdl");
}
 
public OnMapStart()
{
    PrecacheModel("models/weapons/ct_arms_gign.mdl");
     
    AddFileToDownloadsTable("models/player/bbs_93x_net/zombie/zm_arms_normal.dx90.vtx");
    AddFileToDownloadsTable("models/player/bbs_93x_net/zombie/zm_arms_normal.mdl");
    AddFileToDownloadsTable("models/player/bbs_93x_net/zombie/zm_arms_normal.vvd");
 
 
    AddFileToDownloadsTable("materials/models/player/bbs_93x_net/zombie/hand/zombie_fp.vmt");
    AddFileToDownloadsTable("materials/models/player/bbs_93x_net/zombie/hand/zombie_fp.vtf");
    AddFileToDownloadsTable("materials/models/player/bbs_93x_net/zombie/hand/zombie_fp_nm.vtf");
    AddFileToDownloadsTable("materials/models/player/bbs_93x_net/zombie/hand/zombie_fp2.vmt");
    PrecacheModel("models/player/bbs_93x_net/zombie/zm_arms_normal.mdl");
}
 
public Action:OnItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
        decl String:sWeapon[64];
        GetEventString(event, "item", sWeapon, sizeof(sWeapon));
        if (StrEqual(sWeapon, "knife", false))
        {
                new client = GetClientOfUserId(GetEventInt(event, "userid"));
               
                new iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
                if (iWeapon != -1)
                {
                        if(GetClientTeam(client) == CS_TEAM_T)
                        {
                                SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/bbs_93x_net/zombie/zm_arms_normal.mdl");
                        }
                        else
                        {
                                ManosHumanas(client);
                        }
                }
        }
 
        return Plugin_Continue;
}
 
public Action:OnSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        if(GetClientTeam(client) == CS_TEAM_T)
            {
                SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/bbs_93x_net/zombie/zm_arms_normal.mdl");
            }  
}
 
public Action:Event_Round_End(Handle:event, const String:name[], bool:dontBroadcast)
{
        for (new i = 1; i <= MaxClients; i++)
                if(IsClientInGame(i) && IsPlayerAlive(i))
                {
                        ManosHumanas(i);
                       /* if(GetClientTeam(i) == CS_TEAM_T)
                        {
                                CS_SwitchTeam(i, CS_TEAM_CT);
                                CS_SwitchTeam(i, CS_TEAM_T);
                        }*/
                }
}
 
ManosHumanas(client)
{
        SetEntPropString(client, Prop_Send, "m_szArmsModel", manos[client]);
}