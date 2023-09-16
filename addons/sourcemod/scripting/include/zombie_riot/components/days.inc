/*    <DR.API ZOMBIE RIOT> (c) by <De Battista Clint - (http://doyou.watch)  */
/*                                                                           */
/*                  <DR.API ZOMBIE RIOT> is licensed under a                 */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//****************************DR.API ZOMBIE RIOT DATA************************//
//***************************************************************************//
//***************************************************************************//

/***********************************************************/
/*********************** START DAY *************************/
/***********************************************************/
void StartDay()
{
	B_day_start = true;
	INT_ZOMBIE_KILLED = 0;
	SetCorrectDayCount(true);
	SetWeaponsDay();
	ServerCommand("bot_knives_only");
	PlayAmbientSoundRoundStart();

	char storyline[192];
	GetDayStoryLine(INT_CURRENT_DAY, storyline, sizeof(storyline));

	bool override = ExplodeZombieOverrides(INT_CURRENT_DAY);
	
	if(INT_TOTAL_DAY - (INT_CURRENT_DAY + 1) == 1)
	{
		ServerCommand("sm_mapvote");
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(Client_IsIngame(i))
		{
			ChangeClientDeathCount(i, 0);
			ChangeClientDayCount("ROUND START", i, 0);
			
			char storyday_translate[129];
			Format(storyday_translate, sizeof(storyday_translate),"%T", storyline, i);
			if(storyday_translate[0])
			{
				CPrintToChat(i, storyday_translate);
			}

			if(B_Player_Is_Zombie[i])
			{
				if(override)
				{
					int size = GetArraySize(adtZombies);
					if(size)
					{
						int zombieid = GetRandomInt(0, size - 1);
									
						Zombify(i, GetArrayCell(adtZombies, zombieid));
						
						char S_zombie_name[64];
						GetClientName(i, S_zombie_name, sizeof(S_zombie_name));
						LogToZombieRiot(B_active_zombie_riot_dev, "%s DAY STARTED, ZOMBIFY: %s", TAG_CHAT, S_zombie_name);
						//PrintToDev(B_active_zombie_riot_dev, "%s DAY STARTED, ZOMBIFY: %s", TAG_CHAT, S_zombie_name);
					}
				}
			}
		}
	}
	CreateTimer(3.0, Timer_SetStateDay);
}

/***********************************************************/
/************************ END DAY **************************/
/***********************************************************/
void EndDay()
{
	Disarm();
}

/***********************************************************/
/********************* SET STATE DAY ***********************/
/***********************************************************/
public Action Timer_SetStateDay(Handle timer)
{
	B_day_start = false;
	CPrintToChatAll("%t", "Round start advert");
}

/***********************************************************/
/******************* MAP CHANGE CLEAN **********************/
/***********************************************************/
void MapChangeCleanup()
{
	INT_CURRENT_DAY = 0;
	
	ClearTrie(trie_iDeaths);
	ClearTrie(trie_countDay);
	
	H_Timer_HUD 	= INVALID_HANDLE;
	H_Timer_Freeze = INVALID_HANDLE;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (H_Timer_Zvision[i] != INVALID_HANDLE)
		{
			CloseHandle(H_Timer_Zvision[i]);
			H_Timer_Zvision[i] = INVALID_HANDLE;
		}
		
		if (H_Timer_Respawn[i] != INVALID_HANDLE)
		{
			CloseHandle(H_Timer_Respawn[i]);
			H_Timer_Respawn[i] = INVALID_HANDLE;
		}
	}
}

/***********************************************************/
/********************* ZOMBIE RIOT END *********************/
/***********************************************************/
void ZombieRiotEND()
{
	CS_TerminateRound(3.0, CSRoundEnd_GameStart);
	
	UnhookEvents();
	SDKHooksAll(false);

	ServerCommand("bot_all_weapons");
	ServerCommand("bot_kick");

	for (int i = 1; i <= MaxClients; i++)
	{
		if (H_Timer_Zvision[i] != INVALID_HANDLE)
		{
			CloseHandle(H_Timer_Zvision[i]);
			H_Timer_Zvision[i] = INVALID_HANDLE;
		}
		
		if (H_Timer_Respawn[i] != INVALID_HANDLE)
		{
			CloseHandle(H_Timer_Respawn[i]);
			H_Timer_Respawn[i] = INVALID_HANDLE;
		}
	}
}

/***********************************************************/
/******************** SET CORRECT DAY **********************/
/***********************************************************/
void SetCorrectDayCount(bool roundstart)
{
	int zombie_to_kill 				= data_count2[INT_CURRENT_DAY];//25
	int zombie_extra				= GetDayAddZombiesByPlayer(INT_CURRENT_DAY);//+3
	
	if(roundstart)
	{	
		int zombie_to_add_by_player 	= zombie_extra * (INT_NB_HUMANS_PLAYER_IN_GAME - 1) * (INT_CURRENT_DAY + 1);// 3 *(4player -1) == 9
		int zombie_to_add 				= zombie_to_kill + zombie_to_add_by_player;//25 + 9
		
		
		if(zombie_to_add > zombie_to_kill && INT_NB_HUMANS_PLAYER_IN_GAME > 0)
		{
			data_count[INT_CURRENT_DAY] = zombie_to_add;//34
			
			LogToZombieRiot(B_active_zombie_riot_dev, "%s [ROUND START] - Total Zombies: %i, base: %i, added: %i", TAG_CHAT, data_count[INT_CURRENT_DAY], zombie_to_kill, zombie_to_add_by_player);
			PrintToDev(B_active_zombie_riot_dev, "%s [ROUND START] - Total Zombies: %i, base: %i, added: %i", TAG_CHAT, data_count[INT_CURRENT_DAY], zombie_to_kill, zombie_to_add_by_player);
		}
	}
}

/***********************************************************/
/************* SET CORRECT CLIENT DAY COUNT ****************/
/***********************************************************/
void SetCorrectDayCountClient()
{
	int zombie_extra				= GetDayAddZombiesByPlayer(INT_CURRENT_DAY);//3
	int zombie_to_add_by_player 	= zombie_extra * (INT_CURRENT_DAY + 1);//3 * 1
	
	if(zombie_to_add_by_player)
	{
		data_count[INT_CURRENT_DAY] = data_count[INT_CURRENT_DAY] + zombie_to_add_by_player;
		
		LogToZombieRiot(B_active_zombie_riot_dev, "%s [PUT IN SERVER] - Zombies added: %i", TAG_CHAT, zombie_to_add_by_player);
		PrintToDev(B_active_zombie_riot_dev, "%s [PUT IN SERVER] - Zombies added: %i", TAG_CHAT, zombie_to_add_by_player);
	}
}

/***********************************************************/
/************** INITIALISE CLIENT DAY COUNT ****************/
/***********************************************************/
void InitClientDayCount(int client)
{
    if(!IsFakeClient(client))
	{
		char steamId[64];
		GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
		
		StrCat(steamId, sizeof(steamId), "_countDay");
		
		SetTrieValue(trie_countDay, steamId, 0, false);
	}
}

/***********************************************************/
/***************** CHANGE CLIENT DAY COUNT *****************/
/***********************************************************/
void ChangeClientDayCount(char[] event, int client, int value)
{
    if(!IsFakeClient(client))
	{
		char steamId[64];
		GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));

		StrCat(steamId, sizeof(steamId), "_countDay");

		int newvalue = value != 0 ? GetClientDayCount(event, client) + value : 0;
		
		SetTrieValue(trie_countDay, steamId, newvalue, true);
		
		LogToZombieRiot(B_active_zombie_riot_dev, "%s [%s] - Player count day: %i", TAG_CHAT, event, newvalue);
		PrintToDev(B_active_zombie_riot_dev, "%s [%s] - Player count day: %i", TAG_CHAT, event, newvalue);
	}
}

/***********************************************************/
/****************** GET CLIENT DAY COUNT *******************/
/***********************************************************/
int GetClientDayCount(char[] event, int client)
{
	if(!IsFakeClient(client))
	{
		char steamId[64];
		GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));

		StrCat(steamId, sizeof(steamId), "_countDay");
		
		int value;
		GetTrieValue(trie_countDay, steamId, value);

		LogToZombieRiot(B_active_zombie_riot_dev, "%s [%s] - Player count day: %i", TAG_CHAT, event, value);
		PrintToDev(B_active_zombie_riot_dev, "%s [%s] - Player count day: %i", TAG_CHAT, event, value);
		
		return value;
	}
	return 0;
}

/***********************************************************/
/********************* GO TO NEXT MAP **********************/
/***********************************************************/
stock void GotoNextMap()
{
	Handle timelimit = FindConVar("mp_timelimit");

	if (timelimit == INVALID_HANDLE)
	{
		return;
	}

	int flags = GetConVarFlags(timelimit) & FCVAR_NOTIFY;
	SetConVarFlags(timelimit, flags);

	SetConVarInt(timelimit, 1);
}

/***********************************************************/
/******************** SET WEAPONS DAYS *********************/
/***********************************************************/
void SetWeaponsDay()
{
	char ct_default_melee[64], ct_default_secondary[64], ct_default_primary[64];
	
	GetDayCTMeleeWeapon(INT_CURRENT_DAY, ct_default_melee, sizeof(ct_default_melee));
	GetDayCTSecondaryWeapon(INT_CURRENT_DAY, ct_default_secondary, sizeof(ct_default_secondary));
	GetDayCTPrimaryWeapon(INT_CURRENT_DAY, ct_default_primary, sizeof(ct_default_primary));
	
	SetConVarString(mp_ct_default_melee, 				ct_default_melee);
	SetConVarString(mp_ct_default_secondary, 			ct_default_secondary);
	SetConVarString(mp_ct_default_primary, 				ct_default_primary);
}

/***********************************************************/
/******************** SET WEAPONS DAYS *********************/
/***********************************************************/
void WeaponsDayMessage(int client)
{
	char ct_default_melee[64], ct_default_secondary[64], ct_default_primary[64];
	char melee[64], secondary[64], primary[64];
	
	GetDayCTMeleeWeapon(INT_CURRENT_DAY, ct_default_melee, sizeof(ct_default_melee));
	GetDayCTSecondaryWeapon(INT_CURRENT_DAY, ct_default_secondary, sizeof(ct_default_secondary));
	GetDayCTPrimaryWeapon(INT_CURRENT_DAY, ct_default_primary, sizeof(ct_default_primary));
	
	if(ct_default_melee[0])
	{
		ReplaceString(ct_default_melee, sizeof(ct_default_melee), "weapon_", "", false); 
		StringToUpper(ct_default_melee, melee);
		
		CPrintToChat(client, "%t", "Player Spawn Weapons Melee", melee);
	}
	
	if(ct_default_secondary[0])
	{
		ReplaceString(ct_default_secondary, sizeof(ct_default_secondary), "weapon_", "", false); 
		StringToUpper(ct_default_secondary, secondary);
		
		CPrintToChat(client, "%t", "Player Spawn Weapons Secondary", secondary);
	}
	
	if(ct_default_primary[0])
	{
		ReplaceString(ct_default_primary, sizeof(ct_default_primary), "weapon_", "", false); 
		StringToUpper(ct_default_primary, primary);
		
		CPrintToChat(client, "%t", "Player Spawn Weapons Primary", primary);
	}
}

/***********************************************************/
/************************* DISARM **************************/
/***********************************************************/
void Disarm()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(Client_IsIngame(i) && IsPlayerAlive(i))
		{
			Client_RemoveAllWeapons(i, "weapon_knife");
		}
	}
}