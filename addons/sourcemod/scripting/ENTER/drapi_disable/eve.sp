#include <sourcemod>
#include <smlib>
#include <sdkhooks>
#include <sdktools>
 
public void OnPluginStart()
{
    RegConsoleCmd("sm_eve", Cmd_Eve);
}
 
public Action Cmd_Eve(int client, int args)
{
        Eve(client);
        return Plugin_Handled;
}
 
Eve(client)
{
        float vec[3];
        GetClientAbsOrigin(client, vec);
       
        float playerangle[3];
        GetClientEyeAngles(client, playerangle);
        playerangle[0] = 0.0;
       
        float vec_start[3];
        float vec_end[3];
       
        AddInFrontOf(vec, playerangle, 16.0, vec_start);
        vec_start[2] += 0;
       
        AddInFrontOf(vec, playerangle, -16.0, vec_end);
        vec_end[2] += 16;
       
        char sStart[30];
        Format(sStart, 30, "start");
       Eve_Parent(client, vec_start, sStart);
       
        char sEnd[30];
        Format(sEnd, 30, "end");
        Eve_Parent(client, vec_end, sEnd);
       
        Eve_Beam(client, sStart, sEnd);
}
 
int Eve_Parent(int client, float vec[3], char sName[30])
{
        int iEntity = CreateEntityByName("prop_dynamic");
       
        char fullPath[] = "models/chicken/chicken.mdl";
       
        PrecacheModel(fullPath, true);
        SetEntityModel(iEntity, fullPath);
       
        Format(sName, 30, "%s%d", sName, iEntity);
        DispatchKeyValue(iEntity, "targetname", sName);
       
        DispatchKeyValue(iEntity, "solid", "0");
       
        DispatchSpawn(iEntity);
        ActivateEntity(iEntity);
       
        SetEntityMoveType(iEntity, MOVETYPE_NONE);
        SetEntityRenderMode(iEntity, RENDER_NONE);
       
        TeleportEntity(iEntity, vec, NULL_VECTOR, NULL_VECTOR);
       
        ClientParentEntity(client, iEntity);
       
        return iEntity;
}
 
int Eve_Beam(int client, char sStart[30], char sEnd[30])
{
        float vec[3];
        GetClientAbsOrigin(client, vec);
       
        int beament  = CreateEntityByName("env_beam");
        if (IsValidEntity(beament))
        {
                        char beamindex[30];
                        Format(beamindex, sizeof(beamindex), "Beam%d", beament);
                        DispatchKeyValue(beament, "targetname", beamindex);
                       
                        DispatchKeyValue(beament, "LightningStart", sStart);
                        DispatchKeyValue(beament, "LightningEnd", sEnd);
                       
                        DispatchKeyValue(beament, "damage", "0");
                        DispatchKeyValue(beament, "framestart", "0");
                        DispatchKeyValue(beament, "BoltWidth", "5");
                        DispatchKeyValue(beament, "renderfx", "0");
                        DispatchKeyValue(beament, "TouchType", "3");
                        DispatchKeyValue(beament, "framerate", "0");
                        DispatchKeyValue(beament, "decalname", "Bigshot");
                        DispatchKeyValue(beament, "TextureScroll", "35");
                        DispatchKeyValue(beament, "HDRColorScale", "1.0");
                        DispatchKeyValue(beament, "texture", "materials/sprites/laserbeam.vmt");
                        DispatchKeyValue(beament, "life", "0");
                       
                        DispatchKeyValue(beament, "StrikeTime", "10");
                        DispatchKeyValue(beament, "spawnflags", "8");
                        DispatchKeyValue(beament, "NoiseAmplitude", "0");
                        DispatchKeyValue(beament, "Radius", "64");
                        DispatchKeyValue(beament, "rendercolor", "35 35 255");
                        DispatchKeyValue(beament, "renderamt", "100");
                   
                        DispatchSpawn(beament);
                        ActivateEntity(beament);
                       
                        TeleportEntity(beament, vec, NULL_VECTOR, NULL_VECTOR);
                        CreateTimer(0.5, beam_enable, beament);
        }
       
        return beament;
}
 
stock void ClientParentEntity(client, entity)
{
        SetVariantString("!activator");
        AcceptEntityInput(entity, "SetParent", client, entity, 0);
       
        SetVariantString("IchLiebeDichPandora");
        AcceptEntityInput(entity, "SetParentAttachmentMaintainOffset", entity, entity, 0);
}
 
public Action beam_enable(Handle timer, any beam)
{
        AcceptEntityInput(beam, "TurnOn");
}
 
stock void AddInFrontOf(float vecOrigin[3], float vecAngle[3], float units, float output[3])
{
        float vecAngVectors[3];
        vecAngVectors = vecAngle; //Don't change input
        GetAngleVectors(vecAngVectors, vecAngVectors, NULL_VECTOR, NULL_VECTOR);
       
        for (int i; i < 3; i++)
                output[i] = vecOrigin[i] + (vecAngVectors[i] * units);
}