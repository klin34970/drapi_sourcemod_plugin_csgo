/***********************************************************/
/******************* GET OBJECTIF OF MAP *******************/
/***********************************************************/
stock void GetObjectifMap()
{
	int maxEntities = GetMaxEntities();
	class[24];
	
	for (int i = MaxClients + 1; i < maxEntities; i++)
	{
		if (IsValidEdict(i))
		{
			GetEdictClassname(i, class, sizeof(class));
			if (StrEqual(class, "func_bomb_target", false))
			{
				return 1;			
			}
			else if (StrEqual(class, "func_hostage_rescue", false))
			{
				return 	2;
			}
		}
	}
	return 0;
} 

/***********************************************************/
/******************* SET OBJECTIF OF MAP *******************/
/***********************************************************/
stock void SetObjectifMap(const char[] status)
{
	int maxEntities = GetMaxEntities();
	char class[24];
	
	for (int i = MaxClients + 1; i < maxEntities; i++)
	{
		if (IsValidEdict(i))
		{
			GetEdictClassname(i, class, sizeof(class));
			if (StrEqual(class, "func_bomb_target") || StrEqual(class, "func_hostage_rescue"))
			{
				AcceptEntityInput(i, status);
			}
		}
	}
}

/***********************************************************/
/********************* REMOVE HOSTAGES *********************/
/***********************************************************/
stock void RemoveHostages()
{
	int maxEntities = GetMaxEntities();
	char class[24];
	
	for (int i = MaxClients + 1; i < maxEntities; i++)
	{
		if (IsValidEdict(i))
		{
			GetEdictClassname(i, class, sizeof(class));
			if (StrEqual(class, "hostage_entity"))
			{
				AcceptEntityInput(i, "Kill");
			}
		}
	}
}

/***********************************************************/
/*********************** REMOVE C4 *************************/
/***********************************************************/
stock void RemoveC4()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (StripC4(i))
			break;
	}
}

/***********************************************************/
/************************ STRIP C4 *************************/
/***********************************************************/
stock bool StripC4(int client)
{
	if (Client_IsIngame(client) && GetClientTeam(client) == 2)
	{
		int c4Index = GetPlayerWeaponSlot(client, 4);
		if (c4Index != -1)
		{
			char weapon[24];
			GetClientWeapon(client, weapon, sizeof(weapon));

			if (StrEqual(weapon, "weapon_c4"))
			{
				if (GetPlayerWeaponSlot(client, 0) != -1)
					ClientCommand(client, "slot1");
				else if (GetPlayerWeaponSlot(client, 1) != -1)
					ClientCommand(client, "slot2");
				else
					ClientCommand(client, "slot3");
				
			}
			RemovePlayerItem(client, c4Index);
			AcceptEntityInput(c4Index, "Kill");
			return true;
		}
	}
	return false;
}

/***********************************************************/
/******************** GET BUY ZONE MAP *********************/
/***********************************************************/
stock bool GetBuyZoneMap()
{
	char szClass[65];
	for (new i = MaxClients; i <= GetMaxEntities(); i++)
	{
		if(IsValidEdict(i) && IsValidEntity(i))
		{
			GetEdictClassname(i, szClass, sizeof(szClass));
			if(StrEqual("func_buyzone", szClass))
            {
                return true;
            }
		}
	} 
	return false;
} 

/***********************************************************/
/****************** REMOVE BUYZONE OF MAP ******************/
/***********************************************************/
stock void RemoveBuyZoneMap()
{
	char szClass[65];
	for (int i = MaxClients; i <= GetMaxEntities(); i++)
	{
		if(IsValidEdict(i) && IsValidEntity(i))
		{
			GetEdictClassname(i, szClass, sizeof(szClass));
			if(StrEqual("func_buyzone", szClass))
			{
				RemoveEdict(i);
            }
		}
	} 
}