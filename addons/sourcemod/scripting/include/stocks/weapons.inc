/***********************************************************/
/******************** SET ACTIVE WEAPON ********************/
/***********************************************************/
stock void Client_SetActiveWeapon(int client, int weapon)
{
	SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", weapon);
	ChangeEdictState(client, FindDataMapOffs(client, "m_hActiveWeapon"));
}

/***********************************************************/
/********************** REMOVE WEAPON **********************/
/***********************************************************/
stock bool Client_RemoveWeapon(int client, const char[] className,  bool firstOnly=true)
{
	int offset = Client_GetWeaponsOffset(client) - 4;

	for (int i=0; i < 32; i++) {
		offset += 4;
		
		int weapon = GetEntDataEnt2(client, offset);
		
		if (!Weapon_IsValid(weapon)) {
			continue;
		}
		
		if (!Entity_ClassNameMatches(weapon, className, true)) {
			continue;
		}
			
		if (RemovePlayerItem(client, weapon)) {
			Entity_Kill(weapon);
		}
		
		if (firstOnly){
			return true;
		}
	}
	return false;
}

/***********************************************************/
/******************** REMOVE ALL WEAPONS *******************/
/***********************************************************/
stock int Client_RemoveAllWeapons(int client, const char[] exclude="")
{
	int offset = Client_GetWeaponsOffset(client) - 4;

	int numWeaponsRemoved = 0;
	for (int i=0; i < 32; i++) {
		offset += 4;

		int weapon = GetEntDataEnt2(client, offset);

		if (!Weapon_IsValid(weapon)) {
			continue;
		}
		
		if (exclude[0] != '\0' && Entity_ClassNameMatches(weapon, exclude)) {
			Client_SetActiveWeapon(client, weapon);
			continue;
		}
		
		if (RemovePlayerItem(client, weapon)) {
			Entity_Kill(weapon);
		}
		numWeaponsRemoved++;
	}
	return numWeaponsRemoved;
}

/***********************************************************/
/*********************** HAS WEAPONS ***********************/
/***********************************************************/
stock bool Client_HasWeapon(int client,const char[] className,  bool firstOnly=true)
{
	int offset = Client_GetWeaponsOffset(client) - 4;

	for (int i=0; i < 32; i++) {
		offset += 4;
		
		int weapon = GetEntDataEnt2(client, offset);
		
		if (!Weapon_IsValid(weapon)) {
			continue;
		}
		
		if (!Entity_ClassNameMatches(weapon, className, true)) {
			continue;
		}
		
		if (firstOnly){
			return true;
		}
	}
	return false;
}

/***********************************************************/
/********************* IS VALIS WEAPONS ********************/
/***********************************************************/
stock bool Weapon_IsValid(int weapon)
{
	if (!IsValidEdict(weapon)) {
		return false;
	}
	
	return Entity_ClassNameMatches(weapon, "weapon_", true);
}

/***********************************************************/
/******************** REMOVE WEAPONS MAP *******************/
/***********************************************************/
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

/***********************************************************/
/********************* GET WEAPONS OFFSET ******************/
/***********************************************************/
stock int Client_GetWeaponsOffset(int client)
{
	int offset = -1;

	if (offset == -1) {
		offset = FindDataMapOffs(client, "m_hMyWeapons");
	}
	
	return offset;
}

/***********************************************************/
/********************** SET WEAPONS AMMO *******************/
/***********************************************************/
stock void Client_SetWeaponPlayerAmmoEx(int client, int weapon, int primaryAmmo=-1, int secondaryAmmo=-1)
{
	int offset_ammo = FindDataMapOffs(client, "m_iAmmo");

	if (primaryAmmo != -1) 
	{
		int offset = offset_ammo + (Weapon_GetPrimaryAmmoType(weapon) * 4);
		SetEntData(client, offset, primaryAmmo, 4, true);
	}

	if (secondaryAmmo != -1) 
	{
		int offset = offset_ammo + (Weapon_GetSecondaryAmmoType(weapon) * 4);
		SetEntData(client, offset, secondaryAmmo, 4, true);
	}
}

/***********************************************************/
/******************* GET PRIMARY AMMO TYPE *****************/
/***********************************************************/
stock int Weapon_GetPrimaryAmmoType(int weapon)
{
	return GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
}

/***********************************************************/
/******************* SET PRIMARY AMMO TYPE *****************/
/***********************************************************/
stock Weapon_SetPrimaryAmmoType(weapon,type)
{
	return SetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType", type);
}

/***********************************************************/
/******************* GET SECONDARY AMMO TYPE ***************/
/***********************************************************/
stock int Weapon_GetSecondaryAmmoType(int weapon)
{
	return GetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoType");
}

/***********************************************************/
/******************* SET SECONDARY AMMO TYPE ***************/
/***********************************************************/
stock Weapon_SetSecondaryAmmoType(weapon,type)
{
	return SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoType", type);
}

/***********************************************************/
/*********************** GET PRIMARY CLIP ******************/
/***********************************************************/
stock Weapon_GetPrimaryClip(weapon)
{
	return GetEntProp(weapon, Prop_Data, "m_iClip1");
}

/***********************************************************/
/*********************** SET PRIMARY CLIP ******************/
/***********************************************************/
stock Weapon_SetPrimaryClip(weapon, value)
{
	SetEntProp(weapon, Prop_Data, "m_iClip1", value);
}

/***********************************************************/
/********************** GET SECONDARY CLIP *****************/
/***********************************************************/
stock Weapon_GetSecondaryClip(weapon)
{
	return GetEntProp(weapon, Prop_Data, "m_iClip2");
}

/***********************************************************/
/********************** SET SECONDARY CLIP *****************/
/***********************************************************/
stock Weapon_SetSecondaryClip(weapon, value)
{
	SetEntProp(weapon, Prop_Data, "m_iClip2", value);
}

/***********************************************************/
/********************** GET PRIMARY WEAPONS ****************/
/***********************************************************/
stock GetPrimaryAmmo(client, weapon)
{
    new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
    if(ammotype == -1) return -1;
    
    return GetEntProp(client, Prop_Send, "m_iAmmo", _, ammotype);
}

/***********************************************************/
/********************** SET PRIMARY WEAPONS ****************/
/***********************************************************/
stock SetPrimaryAmmo(client, weapon, ammo)
{
    new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
    if(ammotype == -1) return;
    
    SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, ammotype);
} 

/***********************************************************/
/********************** GET WEAPON ACTIVE ******************/
/***********************************************************/
stock int Client_GetActiveWeapon(int client)
{
	new weapon =  GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	
	if (!IsValidEntity(weapon)) {
		return INVALID_ENT_REFERENCE;
	}
	
	return weapon;
}