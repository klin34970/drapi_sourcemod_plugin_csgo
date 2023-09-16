#define 		DEVELOPER					"STEAM_1:1:4489913"
#define 		MSG_LENGTH 192

#if !defined CHAT_HIGHLIGHT_INC
#define 		CHAT_HIGHLIGHT_INC 			"\x04"
#endif

#if !defined CHAT_NORMAL_INC
#define 		CHAT_NORMAL_INC 			"\x01"
#endif

#if !defined TAG_CHAT_INC
#define 		TAG_CHAT_INC 				"[DEBUG] - "
#endif


/***********************************************************/
/****************** GET CLIENT BY STEAM ID *****************/
/***********************************************************/
stock int GetClientBySteamID(char[] steamid)
{
	char authid[32];
	for(int i=1;i<=MaxClients;++i)
	{
		if(!Client_IsIngame(i))
			continue;
		if(!IsClientAuthorized(i))
			continue;
		GetClientAuthString(i, authid, sizeof(authid));
		if(strcmp(authid[8], steamid[8])==0)
			return i;
	}
	return 0;
}

/***********************************************************/
/****************** GET CLIENT BY STEAM ID *****************/
/***********************************************************/
stock int GetClientBySteamIDEx(char[] steamid)
{
	char steamId[64];
	for(int i=1;i<=MaxClients;++i)
	{
		if(!Client_IsIngame(i))
			continue;
		if(!IsClientAuthorized(i))
			continue;
		GetClientAuthId(i, AuthId_Steam2, steamId, sizeof(steamId));
		if (StrEqual(steamId, steamid))
			return i;
	}
	return 0;
}

/***********************************************************/
/*********************** PRINT TO DEV **********************/
/***********************************************************/
stock void PrintToDev(bool status, char[] format, any ...)
{
	if(status)
	{
		int client = GetClientBySteamIDEx(DEVELOPER);
		if(client)
		{
			char msg[MSG_LENGTH];
			char msg2[MSG_LENGTH];
			Format(msg, MSG_LENGTH, "%s%s%s%s", CHAT_HIGHLIGHT_INC, TAG_CHAT_INC, CHAT_NORMAL_INC, format);
			VFormat(msg2, MSG_LENGTH, msg, 3);
			
			Handle hBf;
			hBf = StartMessageOne("SayText2", client);
			if (hBf != INVALID_HANDLE)
			{
				if (GetUserMessageType() == UM_Protobuf)
				{
					PbSetInt(hBf, "ent_idx", client);
					PbSetBool(hBf, "chat", false);

					PbSetString(hBf, "msg_name", msg2);
					PbAddString(hBf, "params", "");
					PbAddString(hBf, "params", "");
					PbAddString(hBf, "params", "");
					PbAddString(hBf, "params", "");
				}
				else
				{
					BfWriteByte(hBf, client); 
					BfWriteByte(hBf, 0); 
					BfWriteString(hBf, msg2);
				}
				EndMessage();
			}
		}
	}
}

/***********************************************************/
/******************** LOG TO ZOMBIE RIOT *******************/
/***********************************************************/
stock void LogToZombieRiot(bool status, const char[] format, any ...)
{
	if(status)
	{
		char msg[MSG_LENGTH];
		char msg2[MSG_LENGTH];
		char logfile[MSG_LENGTH];
		Format(msg, MSG_LENGTH, "%s", format);
		VFormat(msg2, MSG_LENGTH, msg, 3);
		
		BuildPath(Path_SM, logfile, sizeof(logfile), "logs/ZOMBIE_RIOT.txt");
		LogToFile(logfile, msg2);
	}
}