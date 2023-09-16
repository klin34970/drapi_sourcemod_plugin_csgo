/*    <DR.API ZOMBIE RIOT> (c) by <De Battista Clint - (http://doyou.watch)  */
/*                                                                           */
/*                  <DR.API ZOMBIE RIOT> is licensed under a                 */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//***********************DR.API ZOMBIE RIOT ZOMBIES DATAS********************//
//***************************************************************************//
//***************************************************************************//

/***********************************************************/
/******************* LISTENING COMMANDS ********************/
/***********************************************************/
void ListeningTeamCommand()
{
	RegConsoleCmd("jointeam", 	Command_JoinTeam);
	RegConsoleCmd("join", 		Command_Join);
	RegConsoleCmd("kill", 		Command_Kill);
	RegConsoleCmd("spectate", 	Command_Spectate);
}

/***********************************************************/
/****************** LISTEN PLAYERS JOIN ********************/
/***********************************************************/
public Action Command_JoinTeam(int client, int args)
{
	if(Client_IsIngame(client))	
	{
		char arg[8];
		GetCmdArgString(arg, sizeof(arg));
		int jointeam = StringToInt(arg);

		int team = GetClientTeam(client);
		if(team == ZOMBIE || team == HUMAN)
		{
			if (jointeam != SPECTATOR)
			{
				return Plugin_Handled;
			}
			else if(IsPlayerAlive(client))
			{
				ChangeClientDeathCount(client, -1);
			}
		}
	}
	return Plugin_Continue;
}

/***********************************************************/
/****************** LISTEN PLAYERS JOIN ********************/
/***********************************************************/
public Action Command_Join(int client, int args)
{
	int deaths_before_zombie = GetDayDeathsBeforeZombie(INT_CURRENT_DAY);
	if(Client_IsIngame(client))
	{
		if(GetClientDeathCount(client) < deaths_before_zombie)
		{
			int team = GetClientTeam(client);
			if(team == SPECTATOR)
			{
				CS_SwitchTeam(client, HUMAN);
				RespawnHuman(client);
			}
		}
	}
}

/***********************************************************/
/*************** LISTEN PLAYERS TRY KILL *******************/
/***********************************************************/
public Action Command_Kill(int client, int args)
{
	if(Client_IsIngame(client) && IsPlayerAlive(client))	
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

/***********************************************************/
/*************** LISTEN PLAYERS TRY KILL *******************/
/***********************************************************/
public Action Command_Spectate(int client, int args)
{
	if(Client_IsIngame(client) && IsPlayerAlive(client))
	{
		ChangeClientDeathCount(client, -1);
	}

	return Plugin_Continue;
}

/***********************************************************/
/******************* TIMER ASSIGN TEAM *********************/
/***********************************************************/
public Action Timer_AssignTeamAll(Handle timer)
{
    AssignTeamAll(false);
}

/***********************************************************/
/********************* RESET ZOMBIES ***********************/
/***********************************************************/
void ResetZombies(bool switchteam)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i))
		{
			B_Force_Player_Is_Zombie[i] = IsFakeClient(i);
			B_Player_Is_Zombie[i] 		= IsFakeClient(i);
			B_Player_Is_Human[i] 		= !IsFakeClient(i);
		}
	}

	if (switchteam)
	{
		AssignTeamAll(false);
	}
}

/***********************************************************/
/********************** ASSIGN TEAM ************************/
/***********************************************************/
void AssignTeam(int[] clients, int numClients, bool spawn)
{
    for (int i = 0; i < numClients; i++)
    {
        if (Client_IsIngame(clients[i]))
        {
        
			int team = GetClientTeam(clients[i]);
			
			if (B_Force_Player_Is_Zombie[clients[i]])
			{
				CS_SwitchTeam(clients[i], ZOMBIE);
			
				if (spawn && team != ZOMBIE)
				{
					CS_RespawnPlayer(clients[i]);
				}
			}
			else
			{
				CS_SwitchTeam(clients[i], HUMAN);
			
				if (spawn && team != HUMAN)
				{
					CS_RespawnPlayer(clients[i]);
				}
			}
		}
	}
}

/***********************************************************/
/******************* ASSIGN TEAM CLIENT ********************/
/***********************************************************/
stock void AssignTeamClient(int client, bool spawn)
{
    if (Client_IsIngame(client))
    {
		int clients[1];
		clients[0] = client;
    
		AssignTeam(clients, 1, spawn);
	}
}

/***********************************************************/
/********************* ASSIGN TEAM ALL *********************/
/***********************************************************/
stock void AssignTeamAll(bool spawn)
{
	int[] clients = new int[MaxClients];
	int count = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!Client_IsIngame(i) || GetClientTeam(i) < ZOMBIE)
		{
			continue;
		}

		clients[count++] = i;
	}

	AssignTeam(clients, count, spawn);
}

/***********************************************************/
/********************* TIMER CHECK TEAM ********************/
/***********************************************************/
public Action Timer_CheckTeam(Handle timer, any client)
{
	if(Client_IsIngame(client))
	{
		AssignTeamClient(client, client);
	}
}

/***********************************************************/
/******************** SET PLAYERS HUMAN ********************/
/***********************************************************/
void SetPlayersNone(char[] event)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(Client_IsIngame(i))
		{
			if(GetClientTeam(i) < ZOMBIE)
			{
				C_Player_Is_Human[i] = 0;
				B_Player_Is_Human[i] = false;
				
				C_Player_Is_Zombie[i] = 0;
				B_Player_Is_Zombie[i] = false;
				
				char player_name[32];
				GetClientName(i, player_name, sizeof(player_name));
				
				LogToZombieRiot(B_active_zombie_riot_dev, "%s [%s] - Player: %s is Spectator", TAG_CHAT, event, player_name);
			}
		}
	}
}

/***********************************************************/
/******************* TIMER REMOVE RADGOLL ******************/
/***********************************************************/
public Action Timer_RemoveRagdoll(Handle timer, any ragdoll)
{
	if(IsValidEdict(ragdoll))
	{
		char classname[64];
		GetEdictClassname(ragdoll, classname, sizeof(classname));

		if (StrEqual(classname, "cs_ragdoll"))
		{
			RemoveEdict(ragdoll);
		}
	}
}