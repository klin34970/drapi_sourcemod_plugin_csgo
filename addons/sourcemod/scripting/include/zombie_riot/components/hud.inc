/*    <DR.API ZOMBIE RIOT> (c) by <De Battista Clint - (http://doyou.watch)  */
/*                                                                           */
/*                  <DR.API ZOMBIE RIOT> is licensed under a                 */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//******************************DR.API ZOMBIE RIOT***************************//
//***************************************************************************//
//***************************************************************************//

/***********************************************************/
/**************** SHOW HUD WHEN DAY BEGIN ******************/
/***********************************************************/
void BeginDayStartHUD()
{
	if (H_Timer_HUD != INVALID_HANDLE)
	{
		CloseHandle(H_Timer_HUD);
		H_Timer_HUD = INVALID_HANDLE;
	}
	
	if (B_zombie_riot_hud)
	{
		H_Timer_HUD = CreateTimer(5.0, Timer_HUD, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		UpdateHUDAll();
	}
}

/***********************************************************/
/*********************** TIMER HUD *************************/
/***********************************************************/
public Action Timer_HUD(Handle timer)
{
    UpdateHUDAll();
}

/***********************************************************/
/********************** UPDATE HUD *************************/
/***********************************************************/
void UpdateHUD(int[] clients, int numClients)
{

	if (H_Timer_HUD == INVALID_HANDLE || !B_zombie_riot_hud)
	{
		return;
	}
	
	char display[32];
	char targetname[64];

	GetDayDisplay(INT_CURRENT_DAY, display, sizeof(display));
	
	for (int i = 0; i < numClients; i++)
	{
		if (!Client_IsIngame(clients[i]) || IsFakeClient(clients[i]) || GetClientTeam(clients[i]) == NONE || !C_show_hud[clients[i]])
		{
			continue;
		}
		
		int target 		= GetClientTarget(clients[i]);
		int zombie_left = GetDayCount(INT_CURRENT_DAY) - INT_ZOMBIE_KILLED;
		
		char day_translate[40];
		Format(day_translate, sizeof(day_translate),"%T", display, clients[i]);
		
		if (B_zombie_riot_hud_targeting && target != -1 && B_Player_Is_Zombie[target] && GetClientTeam(clients[i]) != SPECTATOR)
		{
			GetClientName(target, targetname, sizeof(targetname));
			
			int health = GetClientHealth(target);
			health = (health >= 0) ? health : 0;
			
			if(INT_CURRENT_DAY + 1 == INT_TOTAL_DAY)
			{
				targetname = "HULK";
			}
			PrintHintText(clients[i], "%t", "HUD Targeting extra", INT_CURRENT_DAY + 1, INT_TOTAL_DAY, day_translate, zombie_left, INT_NB_HUMANS_BOTH_ALIVE, targetname, health);

		}
		else
		{
			PrintHintText(clients[i], "%t", "HUD Targeting", INT_CURRENT_DAY + 1, INT_TOTAL_DAY, day_translate, zombie_left, INT_NB_HUMANS_BOTH_ALIVE);
		}
	}
}

/***********************************************************/
/******************* UPDATE HUD CLIENT *********************/
/***********************************************************/
stock void UpdateHUDClient(int client)
{
	if (!IsClientInGame(client) || GetClientTeam(x) == NONE)
	{
		return;
	}

	int clients[1];
	clients[0] = client;

	UpdateHUD(clients, 1);
}

/***********************************************************/
/******************** UPDATE HUD ALL ***********************/
/***********************************************************/
stock void UpdateHUDAll()
{
	int[] clients = new int[MaxClients + 1];
	int count = 0;

	for(int i = 1; i <= MaxClients; i++)
	{
		if (!Client_IsIngame(i) || GetClientTeam(i) == NONE)
		{
			continue;
		}

		clients[count++] = i;
	}

	UpdateHUD(clients, count);
}

/***********************************************************/
/********************* TARGET PLAYER ***********************/
/***********************************************************/
void TargetPlayer(int attacker, int client)
{
	if(!Client_IsIngame(attacker) || !Client_IsIngame(client))
	{
		return;
	}

	C_Target[attacker] = client;

	B_Target[client][attacker] = true;
}

/***********************************************************/
/****************** GET CLIENT TARGET **********************/
/***********************************************************/
int GetClientTarget(int client)
{
	if(C_Target[client] == -1 || !Client_IsIngame(C_Target[client]))
	{
		return -1;
	}

	return C_Target[client];
}

/***********************************************************/
/**************** GET CLIENT TARGETERS *********************/
/***********************************************************/
int GetClientTargeters(int client, int[] clients, int maxClients)
{
    int count = 0;
    for(int i = 1; i <= maxClients; i++)
    {
        if(!Client_IsIngame(i) || !B_Target[client][i])
        {
            continue;
        }
        
        clients[count++] = i;
    }
    
    return count;
}

/***********************************************************/
/****************** FIND NEXT TARGET ***********************/
/***********************************************************/
int FindClientNextTarget(int client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!Client_IsIngame(i))
		{
			continue;
		}

		if(B_Target[i][client])
		{
			return i;
		}
	}

	return -1;
}

/***********************************************************/
/****************** REMOVE TARGETERS ***********************/
/***********************************************************/
void RemoveTargeters(int client)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        B_Target[client][i] = false;
        
        if(C_Target[i] == client)
        {
            C_Target[i] = FindClientNextTarget(i);
        }
    }
}