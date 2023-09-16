//***********************************//
//***********PARAMETERS**************//
//***********************************//
enum OffsetsSettings
{
	m_vecBaseVelocity,
	m_vecVelocity2,
	m_flLaggedMovementValue,
	m_CollisionGroup,
	m_iAccount,
	m_iDefaultFOV,
	m_bInBuyZone,
	m_fadeMinDist,
	m_fadeMaxDist
}

Offsets[OffsetsSettings];

/***********************************************************/
/*********************** FIND OFFSETS **********************/
/***********************************************************/
stock void FindOffsets()
{
    Offsets[m_vecBaseVelocity] = FindSendPropInfo("CBasePlayer", "m_vecBaseVelocity");
    if (Offsets[m_vecBaseVelocity] == -1)
    {
        SetFailState("%s Couldn't find \"m_vecBaseVelocity\"!", TAG_CHAT);
    }
    
    Offsets[m_vecVelocity2] = FindSendPropInfo("CBasePlayer", "m_vecVelocity[2]");
    if (Offsets[m_vecVelocity2] == -1)
    {
        SetFailState("%s Couldn't find \"m_vecVelocity[2]\"!", TAG_CHAT);
    }
    
    Offsets[m_flLaggedMovementValue] = FindSendPropInfo("CCSPlayer", "m_flLaggedMovementValue");
    if (Offsets[m_flLaggedMovementValue] == -1)
    {
        SetFailState("%s Couldn't find \"m_flLaggedMovementValue\"!", TAG_CHAT);
    }
    
    Offsets[m_CollisionGroup] = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
    if (Offsets[m_CollisionGroup] == -1)
    {
        SetFailState("%s Couldn't find \"m_CollisionGroup\"!", TAG_CHAT);
    }
    
    Offsets[m_iAccount] = FindSendPropInfo("CCSPlayer", "m_iAccount");
    if (Offsets[m_iAccount] == -1)
    {
        SetFailState("%s Couldn't find \"m_iAccount\"!", TAG_CHAT);
    }
    
    Offsets[m_iDefaultFOV] = FindSendPropInfo("CBasePlayer", "m_iDefaultFOV");
    if (Offsets[m_iDefaultFOV] == -1)
    {
        SetFailState("%s Couldn't find \"m_iDefaultFOV\"!", TAG_CHAT);
    }
    
    Offsets[m_bInBuyZone] = FindSendPropInfo("CCSPlayer", "m_bInBuyZone");
    if (Offsets[m_bInBuyZone] == -1)
    {
        SetFailState("%s Couldn't find \"m_bInBuyZone\"!", TAG_CHAT);
    }
    
    Offsets[m_fadeMinDist] = FindSendPropInfo("CCSPlayer", "m_fadeMinDist");
    if (Offsets[m_fadeMinDist] == -1)
    {
        SetFailState("%s Couldn't find \"m_fadeMinDist\"!", TAG_CHAT);
    }
    
    Offsets[m_fadeMaxDist] = FindSendPropInfo("CCSPlayer", "m_fadeMaxDist");
    if (Offsets[m_fadeMaxDist] == -1)
    {
        SetFailState("%s Couldn't find \"m_fadeMaxDist\"!", TAG_CHAT);
    }
}

/***********************************************************/
/******************** SET PLAYER VELOCITY ******************/
/***********************************************************/
stock void SetPlayerVelocity(int client, const float vec[3])
{
    SetEntDataVector(client, Offsets[m_vecBaseVelocity], vec, true);
}

/***********************************************************/
/********************** SET PLAYER SPEED *******************/
/***********************************************************/
stock void SetPlayerSpeed(int client, float speed)
{
    float newspeed = speed / 300.0;
    SetEntDataFloat(client, Offsets[m_flLaggedMovementValue], newspeed, true);
}

/***********************************************************/
/******************** SET PLAYER COLLISION *****************/
/***********************************************************/
stock void NoCollide(int client, bool nocollide)
{
    if (nocollide)
    {
        SetEntData(client, Offsets[m_CollisionGroup], 2, 1, true);
    }
    else
    {
        SetEntData(client, Offsets[m_CollisionGroup], 5, 1, true);
    }
}

/***********************************************************/
/******************** SET PLAYER COLLISION *****************/
/***********************************************************/
stock void SetPlayerMoney(int client, int amount)
{
    SetEntData(client, Offsets[m_iAccount], amount, 4, true);
}

/***********************************************************/
/***************** SET PLAYER FIELD OF VISION **************/
/***********************************************************/
stock void SetPlayerFOV(int client, int fov)
{
    SetEntData(client, Offsets[m_iDefaultFOV], fov, 1, true);
}

/***********************************************************/
/***************** GET CLIENT IS IN BUY ZONE ***************/
/***********************************************************/
stock bool IsClientInBuyZone(int client)
{
    return bool:GetEntData(client, Offsets[m_bInBuyZone]);
}

/***********************************************************/
/************** SET PLAYER FADEOUT MIN DISTANCE ************/
/***********************************************************/
stock void SetPlayerMinDist(int client, float mindist)
{
    SetEntDataFloat(client, Offsets[m_fadeMinDist], mindist);
}

/***********************************************************/
/************** SET PLAYER FADEOUT MAX DISTANCE ************/
/***********************************************************/
stock void SetPlayerMaxDist(int client, float maxdist)
{
    SetEntDataFloat(client, Offsets[m_fadeMaxDist], maxdist);
}

/***********************************************************/
/******************** SET PLAYER MOVE TYPE *****************/
/***********************************************************/
stock void SetPlayerMoveType(int client, MoveType move)
{
    SetEntityMoveType(client, move);
}

/***********************************************************/
/********************* SET PLAYER DAMAGE *******************/
/***********************************************************/
stock void SetPlayerDamage(int client, int type)
{
    SetEntProp(client, Prop_Data, "m_takedamage", type, 1);
}

/***********************************************************/
/********************* SET PLAYER DAMAGE *******************/
/***********************************************************/
stock int GetPlayerRagdoll(int client)
{
    return GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
}