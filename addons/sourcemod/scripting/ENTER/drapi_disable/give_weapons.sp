#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <csgocolors>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

new weaponIndex;
new m_hOwnerEntity;

#define MAX_WEAPONS     31   

public Plugin:myinfo = 
{
	name = "[TIMER] Weapon Give By command", 
	author = "SynysteR, DR. API Improvements", 
	description = "type in chat for example: !awp and you will get an awp, works for all weapons", 
	version = PLUGIN_VERSION
}

new const String:weaponList[MAX_WEAPONS][] =  {
													"[{GREEN}TIMER{NORMAL}] The weapon commands are:", 
													"sm_m4a1_silencer", 
													"sm_usp_silencer", 
													"sm_ak47", 
													"sm_awp", 
													"sm_aug", 
													"sm_bizon", 
													"sm_deagle", 
													"sm_elite", 
													"sm_famas", 
													"sm_fiveseven", 
													"sm_g3sg1", 
													"sm_galilar", 
													"sm_glock", 
													"sm_hkp2000", 
													"sm_m249", 
													"sm_m4a1", 
													"sm_mac10", 
													"sm_mp7", 
													"sm_mp9", 
													"sm_negev", 
													"sm_nova", 
													"sm_p250", 
													"sm_p90", 
													"sm_sawedoff", 
													"sm_scar20", 
													"sm_sg556", 
													"sm_ssg08", 
													"sm_taser", 
													"sm_tec9", 
													"sm_ump45"
												};

public OnPluginStart()
{
	m_hOwnerEntity 		= FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
	
	RegConsoleCmd("sm_awp", Command_Awp, "Gives player an awp.");
	RegConsoleCmd("sm_m4a1", Command_M4A1, "Gives player an m4a1.");
	RegConsoleCmd("sm_ak47", Command_Ak47, "Gives player an ak47");
	RegConsoleCmd("sm_deagle", Command_Deagle, "Gives player a deagle.");
	RegConsoleCmd("sm_aug", Command_Aug, "Gives player an aug.");
	RegConsoleCmd("sm_elite", Command_Elite, "Gives player an elite pistols.");
	RegConsoleCmd("sm_famas", Command_Famas, "Gives player a famas.");
	RegConsoleCmd("sm_fiveseven", Command_FiveSeven, "Gives player a fiveseven pistol.");
	RegConsoleCmd("sm_g3sg1", Command_G3sg1, "Gives player a g3sg1 (auto-sniper).");
	RegConsoleCmd("sm_galilar", Command_galilar, "Gives player a galilar.");
	RegConsoleCmd("sm_glock", Command_Glock, "Gives player a glock.");
	RegConsoleCmd("sm_m249", Command_M249, "Gives player a m249.");
	RegConsoleCmd("sm_mac10", Command_Mac10, "Gives player a mac10.");
	RegConsoleCmd("sm_mp7", Command_mp7, "Gives player a mp7.");
	RegConsoleCmd("sm_p250", Command_p250, "Gives player a p250.");
	RegConsoleCmd("sm_p90", Command_P90, "Gives player a p90.");
	RegConsoleCmd("sm_scar20", Command_scar20, "Gives player a scar20.");
	RegConsoleCmd("sm_sg556", Command_sg556, "Gives player a sg556.");
	RegConsoleCmd("sm_ssg08", Command_ssg08, "Gives player a ssg08.");
	RegConsoleCmd("sm_negev", Command_negev, "Gives player a negev.");
	RegConsoleCmd("sm_ump45", Command_Ump45, "Gives player an ump45.");
	RegConsoleCmd("sm_sawedoff", Command_sawedoff, "Gives player a sawedoff.");
	RegConsoleCmd("sm_bizon", Command_bizon, "Gives player an bizon.");
	RegConsoleCmd("sm_hkp2000", Command_hkp2000, "Gives player an hkp2000.");
	RegConsoleCmd("sm_mp9", Command_mp9, "Gives player an mp9.");
	RegConsoleCmd("sm_nova", Command_nova, "Gives player an nova.");
	RegConsoleCmd("sm_taser", Command_taser, "Gives player an taser.");
	RegConsoleCmd("sm_tec9", Command_tec9, "Gives player an tec9.");
	RegConsoleCmd("sm_m4a1_silencer", Command_m4s, "Gives player an M4a1-S.");
	RegConsoleCmd("sm_usp_silencer", Command_usps, "Gives player an Usp-S.");
	RegConsoleCmd("sm_weaponlist", Command_weaponList);
	
	CreateTimer(5.0, Timer_RemoveWeapons, _, TIMER_REPEAT);

}
enum WeaponsSlot
{
	Slot_Invalid = -1, /** Invalid weapon (slot). */
	Slot_Primary = 0, /** Primary weapon slot. */
	Slot_Secondary = 1, /** Secondary weapon slot. */
	Slot_Melee = 2, /** Melee (knife) weapon slot. */
	Slot_Projectile = 3, /** Projectile (grenades, flashbangs, etc) weapon slot. */
	Slot_Explosive = 4, /** Explosive (c4) weapon slot. */
}

public Action:Command_Awp(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_awp");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}]You gained Awp.");
	}
	return Plugin_Handled;
}
public Action:Command_M4A1(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_m4a1");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] \x03 You gained M4a1.");
	}
	return Plugin_Handled;
}
public Action:Command_Ak47(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_ak47");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] \x03 You gained Ak47.");
	}
	return Plugin_Handled;
}
public Action:Command_Deagle(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 1)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_deagle");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] \x03 You gained Deagle.");
	}
	return Plugin_Handled;
}
public Action:Command_Aug(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_aug");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] \x03 You gained Aug.");
	}
	return Plugin_Handled;
}
public Action:Command_Elite(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 1)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_elite");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] \x03 You gained Elite Pistols.");
	}
	return Plugin_Handled;
}
public Action:Command_Famas(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_famas");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] \x03 You gained Famas.");
	}
	return Plugin_Handled;
}
public Action:Command_FiveSeven(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 1)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_fiveseven");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] \x03 You gained FIve-Seven.");
	}
	return Plugin_Handled;
}
public Action:Command_G3sg1(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_g3sg1");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] \x03 You gained g3sg1.");
	}
	return Plugin_Handled;
}
public Action:Command_galilar(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_galilar");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] \x03 You gained galilar.");
	}
	return Plugin_Handled;
}
public Action:Command_Glock(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 1)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_glock");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] \x03 You gained Glock.");
	}
	return Plugin_Handled;
}
public Action:Command_M249(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_m249");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] \x03 You gained M249.");
	}
	return Plugin_Handled;
}
public Action:Command_Mac10(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_mac10");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] \x03 You gained Mac10.");
	}
	return Plugin_Handled;
}
public Action:Command_mp7(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_mp7");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] \x03 You gained mp7.");
	}
	return Plugin_Handled;
}
public Action:Command_p250(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 1)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_p250");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] \x03 You gained p250.");
	}
	return Plugin_Handled;
}
public Action:Command_P90(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_p90");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] \x03 You gained P90.");
	}
	return Plugin_Handled;
}
public Action:Command_scar20(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_scar20");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] \x03 You gained scar20.");
	}
	return Plugin_Handled;
}
public Action:Command_sg556(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_sg556");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] \x03 You gained sg556.");
	}
	return Plugin_Handled;
}
public Action:Command_ssg08(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_ssg08");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] \x03 You gained ssg08.");
	}
	return Plugin_Handled;
}
public Action:Command_negev(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_negev");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] \x03 You gained negev.");
	}
	return Plugin_Handled;
}
public Action:Command_Ump45(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_ump45");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] \x03 You gained Ump45.");
	}
	return Plugin_Handled;
}
public Action:Command_sawedoff(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 1)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_sawedoff");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] \x03 You gained sawedoff.");
	}
	return Plugin_Handled;
}
public Action:Command_bizon(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_bizon");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] \x03 You gained bizon.");
	}
	return Plugin_Handled;
}
public Action:Command_hkp2000(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_hkp2000");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] \x03 You gained hkp2000.");
	}
	return Plugin_Handled;
}
public Action:Command_mp9(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_mp9");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] \x03 You gained mp9.");
	}
	return Plugin_Handled;
}
public Action:Command_nova(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_nova");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] \x03 You gained nova.");
	}
	return Plugin_Handled;
}
public Action:Command_taser(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_taser");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] \x03 You gained taser.");
	}
	return Plugin_Handled;
}
public Action:Command_tec9(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_tec9");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] \x03 You gained tec9.");
	}
	return Plugin_Handled;
}
public Action:Command_m4s(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_m4a1_silencer");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] \x03 You gained M4a1 Silencer.");
	}
	return Plugin_Handled;
}
public Action:Command_usps(client, args)
{
	if (!IsPlayerAlive(client))
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] You can't use this command while you are dead.");
	else
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
		
		GivePlayerItem(client, "weapon_usp_silencer");
		CPrintToChat(client, "[{GREEN}TIMER{NORMAL}] \x03 You gained Usp Silencer.");
	}
	return Plugin_Handled;
}
public Action:Command_weaponList(client, args)
{
	new i;
	for (i = 0; i < MAX_WEAPONS; ++i)
	CPrintToChat(client, "%s", weaponList[i]);
	return Plugin_Handled;
} 


public Action Timer_RemoveWeapons(Handle timer)
{
	RemoveWeaponsOnMap(m_hOwnerEntity);
}

stock void RemoveWeaponsOnMap(int owner)
{
	int maxent = GetMaxEntities(); 
	char weapon[64];
	
	for (int i = GetMaxClients(); i< maxent; i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, weapon, sizeof(weapon));
			if((StrContains(weapon, "weapon_") != -1 || StrContains(weapon, "item_") != -1) && GetEntDataEnt2(i, owner) == -1)
			{
				RemoveEdict(i);
			}
		}
	}
}