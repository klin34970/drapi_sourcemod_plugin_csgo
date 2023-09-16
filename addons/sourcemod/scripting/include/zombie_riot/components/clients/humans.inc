/*    <DR.API ZOMBIE RIOT> (c) by <De Battista Clint - (http://doyou.watch)  */
/*                                                                           */
/*                  <DR.API ZOMBIE RIOT> is licensed under a                 */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//**************************DR.API ZOMBIE RIOT HUMANS************************//
//***************************************************************************//
//***************************************************************************//

/***********************************************************/
/******************** CREATE VAR HUMANS ********************/
/***********************************************************/
void CreateVarHumans(bool log, char[] event)
{
	GetHumansInGame();
	GetHumansAlive();
	SetPlayersHuman(event);
	
	if(log)
	{
		LogToZombieRiot(B_active_zombie_riot_dev, "--");
		LogToZombieRiot(B_active_zombie_riot_dev, "%s [%s] - HUMANS", TAG_CHAT, event);
		LogToZombieRiot(B_active_zombie_riot_dev, "%s IN GAME PLAYERS: %i, BOTS: %i, BOTH: %i", TAG_CHAT, INT_NB_HUMANS_PLAYER_IN_GAME, INT_NB_HUMANS_BOT_IN_GAME, INT_NB_HUMANS_BOTH_IN_GAME);
		LogToZombieRiot(B_active_zombie_riot_dev, "%s ALIVE   PLAYERS: %i, BOTS: %i, BOTH: %i", TAG_CHAT, INT_NB_HUMANS_PLAYER_ALIVE, INT_NB_HUMANS_BOT_ALIVE, INT_NB_HUMANS_BOTH_ALIVE);
		LogToZombieRiot(B_active_zombie_riot_dev, "%s [%s] - HUMANS", TAG_CHAT, event);
		LogToZombieRiot(B_active_zombie_riot_dev, "--");
	}
}


/***********************************************************/
/******************* GET HUMANS IN GAME ********************/
/***********************************************************/
void GetHumansInGame()
{
	INT_NB_HUMANS_PLAYER_IN_GAME 	= GetPlayersInGame(HUMAN, "player");
	INT_NB_HUMANS_BOT_IN_GAME 		= GetPlayersInGame(HUMAN, "bot");
	INT_NB_HUMANS_BOTH_IN_GAME 		= GetPlayersInGame(HUMAN, "both");
}

/***********************************************************/
/******************** GET HUMANS ALIVE *********************/
/***********************************************************/
void GetHumansAlive()
{
	INT_NB_HUMANS_PLAYER_ALIVE 		= GetPlayersAlive(HUMAN, "player");
	INT_NB_HUMANS_BOT_ALIVE 		= GetPlayersAlive(HUMAN, "bot");
	INT_NB_HUMANS_BOTH_ALIVE		= GetPlayersAlive(HUMAN, "both");
}

/***********************************************************/
/******************** SET PLAYERS HUMAN ********************/
/***********************************************************/
void SetPlayersHuman(char[] event)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(Client_IsIngame(i))
		{
			if(!B_Player_Is_Human[i])
			{
				if(GetClientTeam(i) == HUMAN)
				{
					C_Player_Is_Human[i] = i;
					B_Player_Is_Human[i] = true;
					
					C_Player_Is_Zombie[i] = 0;
					B_Player_Is_Zombie[i] = false;
					
					char player_name[32];
					GetClientName(i, player_name, sizeof(player_name));
					
					LogToZombieRiot(B_active_zombie_riot_dev, "%s [%s] - Player: %s is Human", TAG_CHAT, event, player_name);
				}
			}
		}
	}
}

/***********************************************************/
/*********************** HUMANS WIN ************************/
/***********************************************************/
void HumansWin()
{
	INT_CURRENT_DAY++;
	
	if (INT_CURRENT_DAY + 1> INT_TOTAL_DAY)
	{
		INT_CURRENT_DAY = 0;
		GotoNextMap();
	}
	
	if(B_zombie_riot_overlays)
	{
		ShowOverlays(5.0, HUMAN);
	}
}

/***********************************************************/
/********************** BECOME ZOMBIE **********************/
/***********************************************************/
void BecomeHuman(int client)
{
    if(!B_Player_Is_Human[client])
    {
		B_Force_Player_Is_Zombie[client] = false;
		AssignTeamClient(client, true);
	}
}
/***********************************************************/
/********************** RESPAWN HUMAN **********************/
/***********************************************************/
void RespawnHuman(int client)
{
	int timer;
	
	if(IsAdmin(client))
	{
		timer = GetDayAdminRespawnTime(INT_CURRENT_DAY);
	}
	else if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM2 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM3 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM4 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM5 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
	{
		timer = GetDayVipRespawnTime(INT_CURRENT_DAY);
	}
	else if(IsAdmin(client))
	{
		timer = GetDayAdminRespawnTime(INT_CURRENT_DAY);
	}
	else if(GetDayPlayerRespawnTime(INT_CURRENT_DAY))
	{
		timer = GetDayPlayerRespawnTime(INT_CURRENT_DAY);
	}
	else
	{
		timer = H_zombie_riot_respawn_time;
	}
	
	if (H_Timer_Respawn[client] != INVALID_HANDLE)
	{
		CloseHandle(H_Timer_Respawn[client]);
	}
	
	Timer_Respawn[client] 		= timer;
	H_Timer_Respawn[client] 	= CreateTimer(1.0, Timer_RespawnHuman, client, TIMER_REPEAT);
}

/***********************************************************/
/******************* TIMER RESPAWN HUMAN *******************/
/***********************************************************/
public Action Timer_RespawnHuman(Handle timer, any client)
{
	if (!IsClientInGame(client))
	{
		H_Timer_Respawn[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	int team = GetClientTeam(client);
	if (team == ZOMBIE || team == HUMAN)
	{
		Timer_Respawn[client]--;
	}

	if(C_show_hud[client])
	{
		int timeremaining = (Timer_Respawn[client] < 0) ? 0 : Timer_Respawn[client];
		PrintCenterText(client, "%t", "RespawnHuman", timeremaining);
		
		//char S_human_name[32];
		//GetClientName(client, S_human_name, sizeof(S_human_name));
		//LogToZombieRiot(B_active_zombie_riot_dev, "%s Player die: %s, RespawnTimer: %i", TAG_CHAT, S_human_name, timeremaining);
		//PrintToDev(B_active_zombie_riot_dev, "%s Player die: %s, RespawnTimer: %i", TAG_CHAT, S_human_name, timeremaining);
	}
	
	if (Timer_Respawn[client] > 0)
	{
		return Plugin_Continue;
	}

	H_Timer_Respawn[client] = INVALID_HANDLE;

	CS_RespawnPlayer(client);

	return Plugin_Stop;
}