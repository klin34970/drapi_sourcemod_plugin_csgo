/***********************************************************/
/******************** IS VALID ENTITY **********************/
/***********************************************************/
stock bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}

/***********************************************************/
/*********************** LIMIT ENTITY **********************/
/***********************************************************/
stock bool IsEntLimitReached()
{
	int maxents = GetMaxEntities();
	int i, c = 0;
	
	for(i = MaxClients; i <= maxents; i++)
	{
	 	if(IsValidEntity(i) || IsValidEdict(i))
			c += 1;
		
	}
	
	if (c >= (maxents-300))
	{
		return true;
	}
	else
		return false;
}

/***********************************************************/
/********************* ENTITY IS PLAYER ********************/
/***********************************************************/
stock bool Entity_IsPlayer(int entity)
{
	if (entity < 1 || entity > MaxClients) {
		return false;
	}
	
	return true;
}

/***********************************************************/
/********************* ENTITY CLASSNAME ********************/
/***********************************************************/
stock bool Entity_ClassNameMatches(int entity, const char[] className, bool partialMatch=false)
{
	char entity_className[64];
	Entity_GetClassName(entity, entity_className, sizeof(entity_className));

	if (partialMatch) {
		return (StrContains(entity_className, className) != -1);
	}

	return StrEqual(entity_className, className);
}

/***********************************************************/
/******************* ENTITY GET CLASSNAME ******************/
/***********************************************************/
stock int Entity_GetClassName(int entity, char[] buffer, int size)
{
	return GetEntPropString(entity, Prop_Data, "m_iClassname", buffer, size);	
}