/*    <DR.API ZOMBIE RIOT> (c) by <De Battista Clint - (http://doyou.watch)  */
/*                                                                           */
/*                  <DR.API ZOMBIE RIOT> is licensed under a                 */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//****************************DR.API ZOMBIE RIOT SQL*************************//
//***************************************************************************//
//***************************************************************************//


/***********************************************************/
/****************** CREATE SQL COMMANDS ********************/
/***********************************************************/
void CreateSQLCommands()
{
	RegServerCmd("sm_create_zr_tables", Command_CreateTables);
}

/***********************************************************/
/************* SQL LOAD PREFS ALL CLIENTS ******************/
/***********************************************************/
void SQL_LoadPrefAllClients()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(Client_IsIngame(i))
		{
			SQL_LoadPrefClients(i);
		}	
	}
}
/***********************************************************/
/*************** SQL LOAD PREFS CLIENTS ********************/
/***********************************************************/
public Action SQL_LoadPrefClients(int client)
{
	if(IsClientAuthorized(client) && !IsFakeClient(client))
	{
		Database db = Connect();
		if (db == null)
		{
			ReplyToCommand(client, "%s Could not connect to database", TAG_CHAT);
			return Plugin_Handled;
		}
		
		char steamId[64];
		GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
		
		char strQuery[256];
		Format(strQuery, sizeof(strQuery), "SELECT hud, overlays, zvision, sounds FROM zr_client_prefs WHERE auth = '%s'", steamId);
		SQL_TQuery(db, SQLQuery_LoadPrefClients, strQuery, GetClientUserId(client), DBPrio_High);
	}
	return Plugin_Handled;
}

/***********************************************************/
/************* SQL QUERY LOAD PREFS CLIENTS ****************/
/***********************************************************/
public void SQLQuery_LoadPrefClients(Handle hOwner, Handle hQuery, const char[] strError, any data)
{
	int client = GetClientOfUserId(data);
	if(!Client_IsValid(client))
		return;

	if(hOwner == INVALID_HANDLE || hQuery == INVALID_HANDLE)
	{
		LogToZombieRiot(true, "%s SQL Error: %s", TAG_CHAT, strError);
		return;
	}
	
	if(SQL_FetchRow(hQuery) && SQL_GetRowCount(hQuery) != 0)
	{
		C_show_hud[client] 			= SQL_FetchInt(hQuery, 0);
		C_show_overlays[client] 	= SQL_FetchInt(hQuery, 1);
		C_show_zvision[client] 		= SQL_FetchInt(hQuery, 2);
		C_play_sound[client] 		= SQL_FetchInt(hQuery, 3);
	}
	else
	{
		Database db = Connect();
		if (db == null)
		{
			return;
		}
		
		int zvsion = 0;
		if(F_zombie_riot_zvision > 0.0)
		{
			zvsion = 1;
		}
		char steamId[64];
		GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
		
		char strQuery[256];
		Format(strQuery, sizeof(strQuery), "INSERT INTO zr_client_prefs (hud, overlays, zvision, sounds, auth) VALUES (%i, %i, %i, %i, '%s')", B_zombie_riot_hud, B_zombie_riot_overlays, zvsion, B_zombie_riot_sounds, steamId);
		SQL_TQuery(db, SQLQuery_Update, strQuery, _, DBPrio_High);
		
		SQL_LoadPrefClients(client);
	}
}

/***********************************************************/
/***************** SQL QUERY HUD PREFS *********************/
/***********************************************************/
public void SQLQuery_HUD(Handle hOwner, Handle hQuery, const char[] strError, any data)
{
	int client = GetClientOfUserId(data);
	if(!Client_IsValid(client))
		return;

	if(hOwner == INVALID_HANDLE || hQuery == INVALID_HANDLE)
	{
		LogToZombieRiot(true, "%s SQL Error: %s", TAG_CHAT, strError);
		return;
	}
	
	Database db = Connect();
	if (db == null)
	{
		ReplyToCommand(client, "%s Could not connect to database", TAG_CHAT);
		return;
	}
	
	char steamId[64];
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
	
	if(SQL_GetRowCount(hQuery) == 0)
	{
		char strQuery[256];
		Format(strQuery, sizeof(strQuery), "INSERT INTO zr_client_prefs (hud, auth) VALUES (%i, '%s')", C_show_hud[client], steamId);
		SQL_TQuery(db, SQLQuery_Update, strQuery, _, DBPrio_High);
	}
	else
	{
		char strQuery[256];
		Format(strQuery, sizeof(strQuery), "UPDATE zr_client_prefs SET hud = '%i' WHERE auth = '%s'", C_show_hud[client], steamId);
		SQL_TQuery(db, SQLQuery_Update, strQuery, _, DBPrio_Normal);
	}
}

/***********************************************************/
/*************** SQL QUERY OVERLAYS PREFS ******************/
/***********************************************************/
public void SQLQuery_OVERLAYS(Handle hOwner, Handle hQuery, const char[] strError, any data)
{
	int client = GetClientOfUserId(data);
	if(!Client_IsValid(client))
		return;

	if(hOwner == INVALID_HANDLE || hQuery == INVALID_HANDLE)
	{
		LogToZombieRiot(true, "%s SQL Error: %s", TAG_CHAT, strError);
		return;
	}
	
	Database db = Connect();
	if (db == null)
	{
		ReplyToCommand(client, "%s Could not connect to database", TAG_CHAT);
		return;
	}
	
	char steamId[64];
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
	
	if(SQL_GetRowCount(hQuery) == 0)
	{
		char strQuery[256];
		Format(strQuery, sizeof(strQuery), "INSERT INTO zr_client_prefs (overlays, auth) VALUES (%i, '%s')", C_show_overlays[client], steamId);
		SQL_TQuery(db, SQLQuery_Update, strQuery, _, DBPrio_High);
	}
	else
	{
		char strQuery[256];
		Format(strQuery, sizeof(strQuery), "UPDATE zr_client_prefs SET overlays = '%i' WHERE auth = '%s'", C_show_overlays[client], steamId);
		SQL_TQuery(db, SQLQuery_Update, strQuery, _, DBPrio_Normal);
	}
}

/***********************************************************/
/**************** SQL QUERY ZVISION PREFS ******************/
/***********************************************************/
public void SQLQuery_ZVISION(Handle hOwner, Handle hQuery, const char[] strError, any data)
{
	int client = GetClientOfUserId(data);
	if(!Client_IsValid(client))
		return;

	if(hOwner == INVALID_HANDLE || hQuery == INVALID_HANDLE)
	{
		LogToZombieRiot(true, "%s SQL Error: %s", TAG_CHAT, strError);
		return;
	}
	
	Database db = Connect();
	if (db == null)
	{
		ReplyToCommand(client, "%s Could not connect to database", TAG_CHAT);
		return;
	}
	
	char steamId[64];
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
	
	if(SQL_GetRowCount(hQuery) == 0)
	{
		char strQuery[256];
		Format(strQuery, sizeof(strQuery), "INSERT INTO zr_client_prefs (zvision, auth) VALUES (%i, '%s')", C_show_zvision[client], steamId);
		SQL_TQuery(db, SQLQuery_Update, strQuery, _, DBPrio_High);
	}
	else
	{
		char strQuery[256];
		Format(strQuery, sizeof(strQuery), "UPDATE zr_client_prefs SET zvision = '%i' WHERE auth = '%s'", C_show_zvision[client], steamId);
		SQL_TQuery(db, SQLQuery_Update, strQuery, _, DBPrio_Normal);
	}
}

/***********************************************************/
/**************** SQL QUERY SOUNDS PREFS *******************/
/***********************************************************/
public void SQLQuery_SOUNDS(Handle hOwner, Handle hQuery, const char[] strError, any data)
{
	int client = GetClientOfUserId(data);
	if(!Client_IsValid(client))
		return;

	if(hOwner == INVALID_HANDLE || hQuery == INVALID_HANDLE)
	{
		LogToZombieRiot(true, "%s SQL Error: %s", TAG_CHAT, strError);
		return;
	}
	
	Database db = Connect();
	if (db == null)
	{
		ReplyToCommand(client, "%s Could not connect to database", TAG_CHAT);
		return;
	}
	
	char steamId[64];
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
	
	if(SQL_GetRowCount(hQuery) == 0)
	{
		char strQuery[256];
		Format(strQuery, sizeof(strQuery), "INSERT INTO zr_client_prefs (sounds, auth) VALUES (%i, '%s')", C_play_sound[client], steamId);
		SQL_TQuery(db, SQLQuery_Update, strQuery, _, DBPrio_High);
	}
	else
	{
		char strQuery[256];
		Format(strQuery, sizeof(strQuery), "UPDATE zr_client_prefs SET sounds = '%i' WHERE auth = '%s'", C_play_sound[client], steamId);
		SQL_TQuery(db, SQLQuery_Update, strQuery, _, DBPrio_Normal);
	}
}
/***********************************************************/
/******************* SQL QUERY UPDATE **********************/
/***********************************************************/
public void SQLQuery_Update(Handle hOwner, Handle hQuery, const char[] strError, any data)
{
	if(hQuery == INVALID_HANDLE)
	{
		LogToZombieRiot(true, "%s SQL Error: %s", TAG_CHAT, strError);
	}
}

/***********************************************************/
/******************* DATABASE CONNECT **********************/
/***********************************************************/
Database Connect()
{
	char error[255];
	Database db;

	if (SQL_CheckConfig("zombieriot"))
	{
		db = SQL_Connect("zombieriot", true, error, sizeof(error));
	} 
	else 
	{
		db = SQL_Connect("default", true, error, sizeof(error));
	}

	if (db == null)
	{
		LogToZombieRiot(true, "%s Could not connect to database: %s", TAG_CHAT, error);
	}

	return db;
}

/***********************************************************/
/**************** COMMAND CREATE TABLES ********************/
/***********************************************************/
public Action Command_CreateTables(int args)
{
	int client = 0;
	Database db = Connect();
	if (db == null)
	{
		ReplyToCommand(client, "%s Could not connect to database", TAG_CHAT);
		return Plugin_Handled;
	}

	char ident[16];
	db.Driver.GetIdentifier(ident, sizeof(ident));

	if (strcmp(ident, "mysql") == 0)
	{
		CreateMySQL(client, db);
	} 
	else if (strcmp(ident, "sqlite") == 0) 
	{
		CreateSQLite(client, db);
	} else 
	{
		ReplyToCommand(client, "%s Unknown driver type '%s', cannot create tables.", TAG_CHAT, ident);
	}

	delete db;

	return Plugin_Handled;
}

/***********************************************************/
/********************* CREATE MYSQL ************************/
/***********************************************************/
void CreateMySQL(int client, Handle db)
{
	char queries[2][] = 
	{
		"CREATE TABLE IF NOT EXISTS zr_infos (zr_infos_version_key varchar(32) NOT NULL, zr_infos_version_value varchar(255) NOT NULL, PRIMARY KEY (zr_infos_version_key)) ENGINE=InnoDB DEFAULT CHARSET=utf8;",
		"CREATE TABLE IF NOT EXISTS zr_client_prefs (id int(64) NOT NULL AUTO_INCREMENT, auth varchar(32) UNIQUE, hud int(12) NOT NULL default 1, overlays int(12) NOT NULL default 1, zvision int(12) NOT NULL default 1, sounds int(12) NOT NULL default 1, PRIMARY KEY (id)) ENGINE=InnoDB DEFAULT CHARSET=utf8;"
	};

	for (int i = 0; i < 2; i++)
	{
		if (!DoQuery(client, db, queries[i]))
		{
			return;
		}
	}

	char query[256];
	Format(query, sizeof(query), "INSERT INTO zr_infos (zr_infos_version_key, zr_infos_version_value) VALUES ('zr_infos_version', '%s') ON DUPLICATE KEY UPDATE zr_infos_version_value = '%s'", PLUGIN_VERSION, PLUGIN_VERSION);

	if (!DoQuery(client, db, query))
	{
		return;
	}

	ReplyToCommand(client, "%s Zombie Riot tables have been created.", TAG_CHAT);
}

/***********************************************************/
/******************** CREATE SQLITE ************************/
/***********************************************************/
void CreateSQLite(int client, Handle db)
{
	char queries[2][] = 
	{
		"CREATE TABLE IF NOT EXISTS zr_infos (zr_infos_version_key varchar(32) NOT NULL, zr_infos_version_value varchar(255) NOT NULL, PRIMARY KEY (zr_infos_version_key)) ENGINE=InnoDB DEFAULT CHARSET=utf8;",
		"CREATE TABLE IF NOT EXISTS zr_client_prefs (id int(64) NOT NULL AUTO_INCREMENT, auth varchar(32) UNIQUE, hud int(12) NOT NULL default 1, overlays int(12) NOT NULL default 1, zvision int(12) NOT NULL default 1, sounds int(12) NOT NULL default 1, PRIMARY KEY (id)) ENGINE=InnoDB DEFAULT CHARSET=utf8;"
	};

	for (int i = 0; i < 2; i++)
	{
		if (!DoQuery(client, db, queries[i]))
		{
			return;
		}
	}

	char query[256];
	Format(query, sizeof(query), "REPLACE INTO zr_infos (zr_infos_version_key, zr_infos_version_value) VALUES ('zr_infos_version', '%s')", PLUGIN_VERSION);

	if (!DoQuery(client, db, query))
	{
		return;
	}

	ReplyToCommand(client, "%s Zombie Riot tables have been created.", TAG_CHAT);
}

/***********************************************************/
/*********************** DO QUERY **************************/
/***********************************************************/
stock bool DoQuery(int client, Handle db, const char[] query)
{
	if (!SQL_FastQuery(db, query))
	{
		char error[255];
		SQL_GetError(db, error, sizeof(error));
		LogToZombieRiot(true, "%s Query failed: %s", TAG_CHAT, error);
		LogToZombieRiot(true, "%s Query dump: %s", TAG_CHAT, query);
		ReplyToCommand(client, "%s Failed to query database", TAG_CHAT);
		return false;
	}

	return true;
}

/***********************************************************/
/*********************** DO ERROR **************************/
/***********************************************************/
stock Action DoError(int client, Handle db, const char[] query, const char[] msg)
{
		char error[255];
		SQL_GetError(db, error, sizeof(error));
		LogToZombieRiot(true, "%s %s: %s", TAG_CHAT, msg, error);
		LogToZombieRiot(true, "%s Query dump: %s", TAG_CHAT, query);
		delete db;
		ReplyToCommand(client, "%s Failed to query database", TAG_CHAT);
		return Plugin_Handled;
}

/***********************************************************/
/********************* DO SMT ERROR ************************/
/***********************************************************/
stock Action DoStmtError(int client, Handle db, const char[] query, const char[] error, const char[] msg)
{
		LogToZombieRiot(true, "%s %s: %s", TAG_CHAT, msg, error);
		LogToZombieRiot(true, "%s Query dump: %s", TAG_CHAT, query);
		delete db;
		ReplyToCommand(client, "%s Failed to query database", TAG_CHAT);
		return Plugin_Handled;
}
