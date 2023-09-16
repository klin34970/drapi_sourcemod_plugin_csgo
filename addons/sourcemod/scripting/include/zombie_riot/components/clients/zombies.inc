/*    <DR.API ZOMBIE RIOT> (c) by <De Battista Clint - (http://doyou.watch)  */
/*                                                                           */
/*                  <DR.API ZOMBIE RIOT> is licensed under a                 */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//**************************DR.API ZOMBIE RIOT ZOMBIES***********************//
//***************************************************************************//
//***************************************************************************//

/***********************************************************/
/******************** CREATE VAR ZOMBIES ********************/
/***********************************************************/
void CreateVarZombies(bool log, char[] event)
{
	GetZombiesInGame();
	GetZombiesAlive();
	SetPlayersZombie(event);
	
	if(log)
	{
		LogToZombieRiot(B_active_zombie_riot_dev, "--");
		LogToZombieRiot(B_active_zombie_riot_dev, "%s [%s] - ZOMBIES", TAG_CHAT, event);
		LogToZombieRiot(B_active_zombie_riot_dev, "%s IN GAME PLAYERS: %i, BOTS: %i, BOTH: %i", TAG_CHAT, INT_NB_ZOMBIES_PLAYER_IN_GAME, INT_NB_ZOMBIES_BOT_IN_GAME, INT_NB_ZOMBIES_BOTH_IN_GAME);
		LogToZombieRiot(B_active_zombie_riot_dev, "%s ALIVE   PLAYERS: %i, BOTS: %i, BOTH: %i", TAG_CHAT, INT_NB_ZOMBIES_PLAYER_ALIVE, INT_NB_ZOMBIES_BOT_ALIVE, INT_NB_ZOMBIES_BOTH_ALIVE);
		LogToZombieRiot(B_active_zombie_riot_dev, "%s [%s] - ZOMBIES", TAG_CHAT, event);
		LogToZombieRiot(B_active_zombie_riot_dev, "--");
	}
}


/***********************************************************/
/******************* GET ZOMBIES IN GAME *******************/
/***********************************************************/
void GetZombiesInGame()
{
	INT_NB_ZOMBIES_PLAYER_IN_GAME 		= GetPlayersInGame(HUMAN, "player");
	INT_NB_ZOMBIES_BOT_IN_GAME 			= GetPlayersInGame(HUMAN, "bot");
	INT_NB_ZOMBIES_BOTH_IN_GAME 		= GetPlayersInGame(HUMAN, "both");
}

/***********************************************************/
/******************** GET ZOMBIES ALIVE ********************/
/***********************************************************/
void GetZombiesAlive()
{
	INT_NB_ZOMBIES_PLAYER_ALIVE 		= GetPlayersAlive(HUMAN, "player");
	INT_NB_ZOMBIES_BOT_ALIVE 			= GetPlayersAlive(HUMAN, "bot");
	INT_NB_ZOMBIES_BOTH_ALIVE			= GetPlayersAlive(HUMAN, "both");
}

/***********************************************************/
/******************** SET PLAYERS ZOMBIE *******************/
/***********************************************************/
void SetPlayersZombie(char[] event)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(Client_IsIngame(i))
		{
			if(!B_Player_Is_Zombie[i])
			{
				if(GetClientTeam(i) == ZOMBIE)
				{
					C_Player_Is_Zombie[i] = i;
					B_Player_Is_Zombie[i] = true;
					
					C_Player_Is_Human[i] = 0;
					B_Player_Is_Human[i] = false;
					
					char player_name[32];
					GetClientName(i, player_name, sizeof(player_name));
					
					LogToZombieRiot(B_active_zombie_riot_dev, "%s [%s] - Player: %s is Zombie", TAG_CHAT, event, player_name);
				}
			}
		}
	}
}

/***********************************************************/
/*********************** ZOMBIES WIN ***********************/
/***********************************************************/
void ZombiesWin()
{
	if(INT_CURRENT_DAY > 0 && GetDayRegression(INT_CURRENT_DAY))
	{
		INT_CURRENT_DAY--;
		
		LogToZombieRiot(B_active_zombie_riot_dev, "%s Regression for this day: %i", TAG_CHAT, INT_CURRENT_DAY + 1);
		PrintToDev(B_active_zombie_riot_dev, "%s Regression for this day: %i", TAG_CHAT, INT_CURRENT_DAY + 1);
	}
	
	if(B_zombie_riot_overlays)
	{
		ShowOverlays(5.0, ZOMBIE);
	}
}

/***********************************************************/
/************************* ZOMBIFY *************************/
/***********************************************************/
void Zombify(int client, int zombieid)
{
	INT_ZOMBIE_ID[client] = zombieid;

	Client_RemoveAllWeapons(client);
	int knife = GivePlayerItem(client, "weapon_knife");

	if(knife != -1)
	{
		SetEntityRenderMode(knife, RENDER_TRANSALPHA);
		SetEntityRenderColor(knife, 255, 255, 255, 0);
	}

	ApplyZombieModel(client, zombieid);
	ApplyZombieHealth(client, zombieid);
	ApplyZombieSpeed(client, zombieid);
	ApplyZombieGravity(client, zombieid);
	ApplyZombieFOV(client, zombieid);

	if(C_show_zvision[client])
	{
		StartZVision(client);
	}
}

/***********************************************************/
/******************** TIMER JOIN ZOMBIE ********************/
/***********************************************************/
public Action Timer_JoinZombie(Handle timer, any client)
{
    if(Client_IsIngame(client))
    {
		 BecomeZombie(client);
    }
}

/***********************************************************/
/********************** BECOME ZOMBIE **********************/
/***********************************************************/
void BecomeZombie(int client)
{
    if(!B_Player_Is_Zombie[client])
    {
		B_Force_Player_Is_Zombie[client] = true;
		AssignTeamClient(client, true);
	}
}

/***********************************************************/
/******************* TIMER ZOMBIE RESPAWN ******************/
/***********************************************************/
public Action Timer_ZombieRespawn(Handle timer, any client)
{
    if(Client_IsIngame(client))
    {
		CS_RespawnPlayer(client);
	}
}

/***********************************************************/
/********************* UN/FREEZE ZOMBIES *******************/
/***********************************************************/
void FreezeZombies(bool status)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(Client_IsIngame(i) && IsPlayerAlive(i) && B_Player_Is_Zombie[i])
		{
			if(status)
			{
				SetPlayerDamage(i, 0);
				SetPlayerMoveType(i, MOVETYPE_NONE);
			}
			else
			{
				SetPlayerDamage(i, 2);
				SetPlayerMoveType(i, MOVETYPE_WALK);
			}
		}
	}
}

/***********************************************************/
/******************* TIMER UNFREEZE ZOMBIES ****************/
/***********************************************************/
public Action Timer_UnfreezeZombies(Handle timer)
{
	FreezeZombies(false);
	H_Timer_Freeze = INVALID_HANDLE;

	LogToZombieRiot(B_active_zombie_riot_dev, "%s Zombies UnFreeze", TAG_CHAT);
	//PrintToDev(B_active_zombie_riot_dev, "%s Zombies UnFreeze", TAG_CHAT);
}

/***********************************************************/
/********************* FREEZE ALL ZOMBIES ******************/
/***********************************************************/
void FreezeAllZombies()
{
	if(H_Timer_Freeze != INVALID_HANDLE)
	{
		CloseHandle(H_Timer_Freeze);
		H_Timer_Freeze = INVALID_HANDLE;
	}

	if(F_zombie_riot_freeze_time_zombies > 0)
	{
		FreezeZombies(true);
		H_Timer_Freeze = CreateTimer(F_zombie_riot_freeze_time_zombies, Timer_UnfreezeZombies);
		
		LogToZombieRiot(B_active_zombie_riot_dev, "%s Zombies Freeze during: %f", TAG_CHAT, F_zombie_riot_freeze_time_zombies);
		//PrintToDev(B_active_zombie_riot_dev, "%s Zombies Freeze during: %f", TAG_CHAT, F_zombie_riot_freeze_time_zombies);
	}
}

/***********************************************************/
/************************ START ZVISION ********************/
/***********************************************************/
void StartZVision(int client)
{
	if (H_Timer_Zvision[client] != INVALID_HANDLE)
	{
		CloseHandle(H_Timer_Zvision[client]);
		H_Timer_Zvision[client] = INVALID_HANDLE;
	}

	bool zvision = ZVision(client);
	if (zvision)
	{
		H_Timer_Zvision[client] = CreateTimer(F_zombie_riot_zvision, Timer_ZVision, client, TIMER_REPEAT);
	}
}
/***********************************************************/
/************************ STOP ZVISION *********************/
/***********************************************************/
void StopZVision(int client)
{
	if (H_Timer_Zvision[client] != INVALID_HANDLE)
	{
		CloseHandle(H_Timer_Zvision[client]);
		H_Timer_Zvision[client] = INVALID_HANDLE;
		DeleteOverlay(client);
	}
}

/***********************************************************/
/************************* SET ZVISION *********************/
/***********************************************************/
bool ZVision(int client)
{
	if(IsFakeClient(client))
	{
		return false;
	}

	char zvision[256];
	GetZombieZVision(INT_ZOMBIE_ID[client], zvision, sizeof(zvision));

	if(zvision[0])
	{
		SetClientOverlay(client, zvision);
		return true;
	}
	return false;
}

/***********************************************************/
/************************ ZVISION TIMER ********************/
/***********************************************************/
public Action Timer_ZVision(Handle timer, any client)
{
	if (!Client_IsIngame(client) || !B_Player_Is_Zombie[client])
	{
		H_Timer_Zvision[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	ZVision(client);
	return Plugin_Continue;
}