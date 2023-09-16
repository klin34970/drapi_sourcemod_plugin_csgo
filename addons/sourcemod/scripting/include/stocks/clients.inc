/***********************************************************/
/********************* IS VALID CLIENT *********************/
/***********************************************************/
stock bool Client_IsValid(int client, bool checkConnected=true)
{
	if (client > 4096) 
	{
		client = EntRefToEntIndex(client);
	}

	if (client < 1 || client > MaxClients) 
	{
		return false;
	}

	if (checkConnected && !IsClientConnected(client)) 
	{
		return false;
	}
	
	return true;
}

/***********************************************************/
/******************** IS CLIENT IN GAME ********************/
/***********************************************************/
stock bool Client_IsIngame(int client)
{
	if (!Client_IsValid(client, false)) 
	{
		return false;
	}

	return IsClientInGame(client);
} 

/***********************************************************/
/******************** CHECK IF IS A VIP ********************/
/***********************************************************/
stock bool IsVip(int client)
{
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM2 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM3 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM4 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM5 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
	{
		return true;
	}
	return false;
}

/***********************************************************/
/****************** CHECK IF IS AN ADMIN *******************/
/***********************************************************/
stock bool IsAdmin(int client)
{
    AdminId admin = GetUserAdmin(client);

    if(admin == INVALID_ADMIN_ID)
	{
        return false;
	}

    return true;
}

/***********************************************************/
/****************** CHECK IF IS AN ADMIN *******************/
/***********************************************************/
stock bool IsAdminEx(int client)
{
	if(GetUserFlagBits(client) & ADMFLAG_CHANGEMAP 
	/*|| GetUserFlagBits(client) & ADMFLAG_RESERVATION*/
	|| GetUserFlagBits(client) & ADMFLAG_GENERIC
	|| GetUserFlagBits(client) & ADMFLAG_KICK
	|| GetUserFlagBits(client) & ADMFLAG_BAN
	|| GetUserFlagBits(client) & ADMFLAG_UNBAN
	|| GetUserFlagBits(client) & ADMFLAG_SLAY
	|| GetUserFlagBits(client) & ADMFLAG_CHANGEMAP
	|| GetUserFlagBits(client) & ADMFLAG_CONVARS
	|| GetUserFlagBits(client) & ADMFLAG_CONFIG
	|| GetUserFlagBits(client) & ADMFLAG_CHAT
	|| GetUserFlagBits(client) & ADMFLAG_VOTE
	|| GetUserFlagBits(client) & ADMFLAG_PASSWORD
	|| GetUserFlagBits(client) & ADMFLAG_RCON
	|| GetUserFlagBits(client) & ADMFLAG_CHEATS
	|| GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		return true;
	}
	return false;
}

/***********************************************************/
/******************** GET PLAYER ALIVE *********************/
/***********************************************************/
stock int GetPlayersAlive(int team, char[] bot)
{
	int iCount; iCount = 0; 

	for(int i = 1; i <= MaxClients; i++) 
	{
		if(StrEqual(bot, "player", false))
		{
			if( Client_IsIngame(i) && !IsFakeClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == team) 
			{
				iCount++; 
			}
		}
		else if(StrEqual(bot, "bot", false))
		{
			if( Client_IsIngame(i) && IsFakeClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == team) 
			{
				iCount++; 
			}
		}
		else if(StrEqual(bot, "both", false))
		{
			if( Client_IsIngame(i) && IsPlayerAlive(i) && GetClientTeam(i) == team) 
			{
				iCount++; 
			}
		}
	}
	
	return iCount; 
}

/***********************************************************/
/******************** GET PLAYER ALIVE *********************/
/***********************************************************/
stock int GetPlayersInGame(int team, char[] bot)
{
	int iCount; iCount = 0; 

	for(int i = 1; i <= MaxClients; i++) 
	{
		if(StrEqual(bot, "player", false))
		{
			if( Client_IsIngame(i) && !IsFakeClient(i) && GetClientTeam(i) == team) 
			{
				iCount++; 
			}
		}
		else if(StrEqual(bot, "bot", false))
		{
			if( Client_IsIngame(i) && IsFakeClient(i) && GetClientTeam(i) == team) 
			{
				iCount++; 
			}
		}
		else if(StrEqual(bot, "both", false))
		{
			if( Client_IsIngame(i) && GetClientTeam(i) == team) 
			{
				iCount++; 
			}
		}
	}
	
	return iCount; 
}

/***********************************************************/
/*********************** RANDOM PLAYER *********************/
/***********************************************************/
stock int GetRandomPlayer(int team) 
{
	int[] clients = new int[MaxClients];
	int clientCount;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i) && (GetClientTeam(i) == team))
		{
			clients[clientCount++] = i;
		}
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}