#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <clientprefs>
 
public Plugin:myinfo =
{
        name = "Knifes",
        author = "Franc1sco franug remake by Dr. Api",
        description = "",
        version = "1.0",
        url = ""
};
 
new knife[MAXPLAYERS+1];
new zrknife[MAXPLAYERS+1];
 
new Handle:c_knife;
new Handle:c_zrknife;
 
public OnPluginStart()
{
		c_knife = RegClientCookie("hknife", "", CookieAccess_Private);
		c_zrknife = RegClientCookie("zrknife", "", CookieAccess_Private);
		//HookEvent("item_pickup", OnItemPickup);
		
		RegConsoleCmd("sm_knife", DID);
		RegConsoleCmd("sm_knifes", DID);
		RegConsoleCmd("sm_ctknife", eligeknife);
		RegConsoleCmd("sm_tknife", eligezrknife);
       
		for (new i = 1; i <= MaxClients; i++) 
		{
				if (IsClientInGame(i) && !IsFakeClient(i)) 
				{
					if(AreClientCookiesCached(i))
					{
						OnClientCookiesCached(i);
					}
					SDKHook(i, SDKHook_WeaponEquip, OnPostWeaponEquip);
				}
		}
 
}

public OnClientPutInServer(client)
{
        SDKHook(client, SDKHook_WeaponEquip, OnPostWeaponEquip);
}
 
public Action:OnPostWeaponEquip(client, iWeapon)
{
        decl String:Classname[64];
        if(!GetEdictClassname(iWeapon, Classname, 64) || StrContains(Classname, "weapon_knife", false) != 0)
        {
                return;
        }
       
        if(GetClientTeam(client) == CS_TEAM_T)
        {
                                if(zrknife[client] < 1)
                                {
                                        new weaponindex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
                                        if (weaponindex == 42 || weaponindex == 59) SetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex", 507);
                                }
                                else SetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex", zrknife[client]);
                               
        }
        else
        {
                                if(knife[client] < 1)
                                {
                                        new weaponindex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
                                        if (weaponindex == 42 || weaponindex == 59) SetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex", 509);
                                }
                                else SetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex", knife[client]);
                               
        }
}

public Action:DID(clientId, args)
{
        new Handle:menu = CreateMenu(DIDMenuHandler);
        SetMenuTitle(menu, "Choose a category");
        AddMenuItem(menu, "option1", "Select CT knife");
        AddMenuItem(menu, "option2", "Select T knife");
        SetMenuExitButton(menu, true);
        DisplayMenu(menu, clientId, 0);
       
        return Plugin_Handled;
}
 
public DIDMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
        if ( action == MenuAction_Select )
        {
                new String:info[32];
               
                GetMenuItem(menu, itemNum, info, sizeof(info));
 
                if ( strcmp(info,"option1") == 0 )
                {    
                        eligeknife(client, 0);
                }
           
                else if ( strcmp(info,"option2") == 0 )
                {
                        eligezrknife(client, 0);
                }
        }
        else if (action == MenuAction_End)
        {
                CloseHandle(menu);
        }
}
 
public Action:eligeknife(clientId, args)
{
        new Handle:menu = CreateMenu(DIDMenuHandler_h);
        SetMenuTitle(menu, "Choose you knife for CT");
       
        AddMenuItem(menu, "0", "Default knife");
        AddMenuItem(menu, "509", "Huntsman");
        AddMenuItem(menu, "507", "Karambit");
        AddMenuItem(menu, "506", "Gut");
        AddMenuItem(menu, "505", "Flip");
        AddMenuItem(menu, "508", "M9 Bayonet");
        AddMenuItem(menu, "500", "Bayonet");
		AddMenuItem(menu, "512", "Falchion");
        AddMenuItem(menu, "515", "Butterfly");
       
        SetMenuExitButton(menu, true);
        DisplayMenu(menu, clientId, 0);
       
        return Plugin_Handled;
}
 
public Action:eligezrknife(clientId, args)
{
        new Handle:menu = CreateMenu(DIDMenuHandler_zr);
        SetMenuTitle(menu, "Choose you knife for T");
 
        AddMenuItem(menu, "0", "Default knife");
        AddMenuItem(menu, "509", "Huntsman");
        AddMenuItem(menu, "507", "Karambit");
        AddMenuItem(menu, "506", "Gut");
        AddMenuItem(menu, "505", "Flip");
        AddMenuItem(menu, "508", "M9 Bayonet");
        AddMenuItem(menu, "500", "Bayonet");
		AddMenuItem(menu, "512", "Falchion");
        AddMenuItem(menu, "515", "Butterfly");
       
        SetMenuExitButton(menu, true);
        DisplayMenu(menu, clientId, 0);
       
        return Plugin_Handled;
}
 
public DIDMenuHandler_h(Handle:menu, MenuAction:action, client, itemNum)
{
        if ( action == MenuAction_Select )
        {
                new String:info[32];
               
                GetMenuItem(menu, itemNum, info, sizeof(info));
 
                knife[client] = StringToInt(info);
               
                new String:cookie[8];
                IntToString(knife[client], cookie, 8);
                SetClientCookie(client, c_knife, cookie);
               
                DarKnife(client);
               
                DID(client, 0);
        }
        else if (action == MenuAction_End)
        {
                CloseHandle(menu);
        }
}
 
public DIDMenuHandler_zr(Handle:menu, MenuAction:action, client, itemNum)
{
        if ( action == MenuAction_Select )
        {
                new String:info[32];
               
                GetMenuItem(menu, itemNum, info, sizeof(info));
 
                zrknife[client] = StringToInt(info);
               
                new String:cookie[8];
                IntToString(zrknife[client], cookie, 8);
                SetClientCookie(client, c_zrknife, cookie);
               
                DarKnife(client);
               
                DID(client, 0);
        }
        else if (action == MenuAction_End)
        {
                CloseHandle(menu);
        }
}
 
public OnClientCookiesCached(client)
{
        new String:value[16];
        GetClientCookie(client, c_knife, value, sizeof(value));
        if(strlen(value) > 0) knife[client] = StringToInt(value);
        else knife[client] = 0;
       
        new String:value2[16];
        GetClientCookie(client, c_zrknife, value2, sizeof(value2));
        if(strlen(value2) > 0) zrknife[client] = StringToInt(value2);
        else zrknife[client] = 0;
}
 
/*
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
                                if(zrknife[client] < 1)
                                {
                                        new weaponindex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
                                        if (weaponindex == 42 || weaponindex == 59) SetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex", 507);
                                }
                                else SetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex", zrknife[client]);
                               
                        }
                        else
                        {
                                if(knife[client] < 1)
                                {
                                        new weaponindex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
                                        if (weaponindex == 42 || weaponindex == 59) SetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex", 509);
                                }
                                else SetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex", knife[client]);
                               
                        }
                        //PrintToChatAll("fijado %s", manos[client]);
                }
        }
 
        return Plugin_Continue;
}
*/
 
DarKnife(client)
{
        if(!IsPlayerAlive(client)) return;
       
        new iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
        if (iWeapon != -1)
        {
                RemovePlayerItem(client, iWeapon);
                AcceptEntityInput(iWeapon, "Kill");
               
                GivePlayerItem(client, "weapon_knife");
        }
}