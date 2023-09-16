/***********************************************************/
/***************** ATTACHE PARTICLE SYSTEM******************/
/***********************************************************/
stock void AttachTempParticle(int entity, char[] particleType, char[] targetName, float lifetime, bool parent, char[] parentName, float zOffset, bool randOffset)
{
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{	
		//set the bloods entity
		DispatchKeyValue(particle, "targetname", targetName);
		SetEntPropEnt(particle, Prop_Data, "m_hOwnerEntity", entity);
		
		float particlePos[3];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", particlePos);
		
		float particleAng[3];
		GetEntPropVector(entity, Prop_Data, "m_angRotation", particleAng);
		if(randOffset)
		{
			particlePos[0] += GetRandomInt(-40,40);
			particlePos[1] += GetRandomInt(-40,40);
			particlePos[2] += GetRandomInt(-40,40);
		}else
		{
			particlePos[2] += zOffset;
		}
		
		TeleportEntity(particle, particlePos, particleAng, NULL_VECTOR);
		
		DispatchKeyValue(particle, "effect_name", particleType);
		
		DispatchKeyValue(particle, "parentname", parentName);
		DispatchSpawn(particle);
		
		if(parent)
		{
			SetVariantString(parentName);
			AcceptEntityInput(particle, "SetParent");
			
			//for the medic, lets get this point outta here
			//DispatchKeyValue(particle, "cpoint1", parentName);
			//DispatchKeyValue(particle, "cpoint2", parentName);
		}
		
		
		// send "kill" event to the event queue
		killEntityIn(particle, lifetime);
		
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
	}
	
	return particle;
}
/***********************************************************/
/********************** KILL ENTITY ************************/
/***********************************************************/
stock void killEntityIn(int entity, float seconds)
{
	if(IsValidEdict(entity))
	{
		// send "kill" event to the event queue
		char addoutput[64];
		Format(addoutput, sizeof(addoutput), "OnUser1 !self:kill::%f:1",seconds);
		
		SetVariantString(addoutput);
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
}

/***********************************************************/
/************************ ENTITY KILL **********************/
/***********************************************************/
stock bool Entity_Kill(int kenny, bool killChildren=false)
{
	if (Entity_IsPlayer(kenny)) {
		// Oh My God! They Killed Kenny!!
		ForcePlayerSuicide(kenny);
		return true;
	}
	
	if(killChildren){
		return AcceptEntityInput(kenny, "KillHierarchy");
	}
	else {
		return AcceptEntityInput(kenny, "Kill");
	}
}

/***********************************************************/
/******************** PRECACHE EFFECT **********************/
/***********************************************************/
stock void PrecacheEffect(const char[] sEffectName)
{
	static table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("EffectDispatch");
	}
	
	bool save = LockStringTables(false);
	AddToStringTable(table, sEffectName);
	LockStringTables(save);
}

/***********************************************************/
/*************** GET PARTICLE EFFECT INDEX *****************/
/***********************************************************/
stock void GetEffectIndex(const char[] sEffectName)
{
	static table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("EffectDispatch");
	}
	
	int iIndex = FindStringIndex(table, sEffectName);
	if(iIndex != INVALID_STRING_INDEX)
		return iIndex;
	
	// This is the invalid string index
	return 0;
}

/***********************************************************/
/******************** GET EFFECT NAME **********************/
/***********************************************************/
stock void GetEffectName(int index, char[] sEffectName, int maxlen)
{
	static table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("EffectDispatch");
	}
	
	ReadStringTable(table, index, sEffectName, maxlen);
}

/***********************************************************/
/*************** PRECACHE PARTICLE EFFECT ******************/
/***********************************************************/
stock void PrecacheParticleEffect(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("ParticleEffectNames");
	}
	
	bool save = LockStringTables(false);
	AddToStringTable(table, sEffectName);
	LockStringTables(save);
}

/***********************************************************/
/*************** GET PARTICLE EFFECT INDEX *****************/
/***********************************************************/
stock int GetParticleEffectIndex(const char[] sEffectName)
{
	static table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("ParticleEffectNames");
	}
	
	int iIndex = FindStringIndex(table, sEffectName);
	if(iIndex != INVALID_STRING_INDEX)
		return iIndex;
	
	// This is the invalid string index
	return 0;
}

/***********************************************************/
/*************** GET PARTICLE EFFECT NAME ******************/
/***********************************************************/
stock void GetParticleEffectName(int index, char[] sEffectName, int maxlen)
{
	static table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("ParticleEffectNames");
	}
	
	ReadStringTable(table, index, sEffectName, maxlen);
}