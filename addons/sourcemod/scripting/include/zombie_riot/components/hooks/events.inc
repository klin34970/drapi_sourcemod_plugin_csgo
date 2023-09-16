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
/************************ HOOK EVENTS **********************/
/***********************************************************/
void HookEvents()
{
	HookEvent("player_connect", PlayerConnect, EventHookMode_Pre);
	HookEvent("player_disconnect", PlayerDisconnect, EventHookMode_Pre);
	
	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundEnd);
	
	HookEvent("player_spawn", PlayerSpawn);	
	HookEvent("player_death", PlayerDeath);
	HookEvent("player_team", PlayerTeam_Pre, EventHookMode_Pre);
	HookEvent("player_team", PlayerTeam_Post, EventHookMode_Post);	
	HookEvent("player_jump", PlayerJump);
	HookEvent("player_hurt", PlayerHurt);

}

/***********************************************************/
/*********************** UNHOOK EVENTS *********************/
/***********************************************************/
void UnhookEvents()
{
	UnhookEvent("player_connect", PlayerConnect, EventHookMode_Pre);
	UnhookEvent("player_disconnect", PlayerDisconnect, EventHookMode_Pre);
	
	UnhookEvent("round_start", RoundStart);
	UnhookEvent("round_end", RoundEnd);
	
	UnhookEvent("player_spawn", PlayerSpawn);
	UnhookEvent("player_death", PlayerDeath);
	UnhookEvent("player_team", PlayerTeam_Pre, EventHookMode_Pre);
	UnhookEvent("player_team", PlayerTeam_Post, EventHookMode_Post);
	UnhookEvent("player_jump", PlayerJump);	
	UnhookEvent("player_hurt", PlayerHurt);
}

/***********************************************************/
/********************** PLAYER CONNECT *********************/
/***********************************************************/
public Action PlayerConnect(Handle event, const char[] name, bool dontBroadcast)
{
	if(B_active_zombie_riot)
	{
		if(!dontBroadcast)
		{
			char S_name[32], networkID[22], address[26];
			GetEventString(event, "name", S_name, sizeof(S_name)-1);
			GetEventString(event, "networkid", networkID, sizeof(networkID)-1);
			GetEventString(event, "address", address, sizeof(address)-1);
			
			Handle new_event = CreateEvent("player_connect", true);
			SetEventString(new_event, "name", S_name);
			SetEventInt(new_event, "index", GetEventInt(event, "index"));
			SetEventInt(new_event, "userid", GetEventInt(event, "userid"));
			SetEventString(new_event, "networkid", networkID);
			SetEventString(new_event, "address", address);
			
			FireEvent(new_event, true);
			
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

/***********************************************************/
/********************* PLAYER DISCONNECT *******************/
/***********************************************************/
public Action PlayerDisconnect(Handle event, const char[] name, bool dontBroadcast)
{
	if(B_active_zombie_riot)
	{
		if(!dontBroadcast)
		{
			char S_name[32], networkID[22], address[26];
			GetEventString(event, "name", S_name, sizeof(S_name)-1);
			GetEventString(event, "networkid", networkID, sizeof(networkID)-1);
			GetEventString(event, "address", address, sizeof(address)-1);
			
			Handle new_event = CreateEvent("player_disconnect", true);
			SetEventString(new_event, "name", S_name);
			SetEventInt(new_event, "index", GetEventInt(event, "index"));
			SetEventInt(new_event, "userid", GetEventInt(event, "userid"));
			SetEventString(new_event, "networkid", networkID);
			SetEventString(new_event, "address", address);
			
			FireEvent(new_event, true);
			
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

/***********************************************************/
/************************ ROUND START **********************/
/***********************************************************/
public Action RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if(B_active_zombie_riot)
	{
		UpdateHostname("%s - [%i/%i]", S_zombie_riot_hostname, INT_CURRENT_DAY + 1, INT_TOTAL_DAY);
		
		CreateVarHumans(false, "ROUND START");
		CreateVarZombies(false, "ROUND START");
		SetPlayersNone("ROUND START");
		
		/*Remove Objectives */
		if(B_zombie_riot_remove_objectives)
		{
			char status[10];
			status = (B_zombie_riot_remove_objectives) ? "Disable" : "Enable";
			SetObjectifMap(status);
			RemoveC4();
			RemoveHostages();
			
			LogToZombieRiot(B_active_zombie_riot_dev, "%s Remove objectives: %s", TAG_CHAT, status);
		}
		
		/*Remove BuyZone */
		if(B_zombie_riot_remove_buyzone)
		{
			RemoveBuyZoneMap();
		}
		
		StartDay();
		//FreezeAllZombies();
		
		if (H_Timer_HUD != INVALID_HANDLE)
		{
			CloseHandle(H_Timer_HUD);
			H_Timer_HUD = INVALID_HANDLE;
		}
		BeginDayStartHUD();
	}
}

/***********************************************************/
/************************* ROUND END ***********************/
/***********************************************************/
public Action RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if(B_active_zombie_riot)
	{
		CreateVarHumans(false, "ROUND START");
		CreateVarZombies(false, "ROUND START");
		SetPlayersNone("PROUND START");
			
		ClearTrie(trie_iDeaths);
		ResetZombies(false);
		CreateTimer(0.0, Timer_AssignTeamAll);
		
		CSRoundEndReason reason = view_as<CSRoundEndReason>(GetEventInt(event, "reason"));
		int winner = GetEventInt(event, "winner");
		
		if(reason == CSRoundEnd_CTWin || reason == CSRoundEnd_TerroristWin)
		{
			if (winner == ZOMBIE)
			{
				ZombiesWin();
				//FreezeAllZombies();
			}
			else if (winner == HUMAN)
			{
				HumansWin();
				//FreezeAllZombies();
			}
		}
		else
		{
			if (H_Timer_Freeze != INVALID_HANDLE)
			{
				CloseHandle(H_Timer_Freeze);
				H_Timer_Freeze = INVALID_HANDLE;
			}
		}
		
		if (H_Timer_HUD != INVALID_HANDLE)
		{
			CloseHandle(H_Timer_HUD);
			H_Timer_HUD = INVALID_HANDLE;
		}
		
		LogToZombieRiot(B_active_zombie_riot_dev, "%s Winner is: %i, next day: %i", TAG_CHAT, winner, INT_CURRENT_DAY + 1);
		PrintToDev(B_active_zombie_riot_dev, "%s Winner is: %i, next day: %i", TAG_CHAT, winner, INT_CURRENT_DAY +1 );
	}
	EndDay();
	B_day_start = true;
	
}
/***********************************************************/
/*********************** PLAYER SPAWN **********************/
/***********************************************************/
public Action PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if(B_active_zombie_riot)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		CreateVarHumans(false, "PLAYER SPAWN");
		CreateVarZombies(false, "PLAYER SPAWN");
		SetPlayersNone("PLAYER SPAWN");
		
		
		if(!B_zombie_riot_collision)
		{
			NoCollide(client, true);
		}
		
		INT_ZOMBIE_ID[client] = -1;
		if(B_Player_Is_Zombie[client])
		{
			RemoveTargeters(client);
			InitClientDeathCount(client);
			SetPlayerMoney(client, 0);

			char zombieoverride[4];
			GetDayZombieOverride(INT_CURRENT_DAY, zombieoverride, sizeof(zombieoverride));

			int zombieid;

			if(adtZombies != INVALID_HANDLE && zombieoverride[0])
			{
				int size = GetArraySize(adtZombies);
				if(size)
				{
					zombieid = GetRandomInt(0, size - 1);
					Zombify(client, GetArrayCell(adtZombies, zombieid));
				}
			}
			else
			{
				do
				{
					zombieid = GetRandomInt(0, ZOMBIE_COUNT - 1);
				} 
				while(IsOverrideRequired(zombieid));

				Zombify(client, zombieid);
			}

			int health = GetClientHealth(client);
			SetEntityHealth(client, health + GetDayHealthBoost(INT_CURRENT_DAY));

			float fademin = GetDayMinFade(INT_CURRENT_DAY);
			float fademax = GetDayMaxFade(INT_CURRENT_DAY);

			SetPlayerMinDist(client, fademin);
			SetPlayerMaxDist(client, fademax);

			int knife = GetPlayerWeaponSlot(client, KNIFE);

			if (knife != -1)
			{
				SetEntityRenderMode(knife, RENDER_TRANSALPHA);
				SetEntityRenderColor(knife, 255, 255, 255, 0);
			}
		}
		else
		{
			SetPlayerMinDist(client, 0.0);
			SetPlayerMaxDist(client, 0.0);
			
			SetPlayerFOV(client, DEFAULT_FOV);
			SetEntityGravity(client, DEFAULT_GRAVITY);
			
			SetPlayerMoney(client, H_zombie_riot_cash);
			
			RemoveTargeters(client);
			UpdateHUDAll();
		
			if(!B_day_start)
			{
				WeaponsDayMessage(client);
			}
			
			if(H_Timer_Zvision[client] != INVALID_HANDLE)
			{
				CloseHandle(H_Timer_Zvision[client]);
				H_Timer_Zvision[client] = INVALID_HANDLE;
			}
			
			if(H_Timer_Respawn[client] != INVALID_HANDLE)
			{
				CloseHandle(H_Timer_Respawn[client]);
				H_Timer_Respawn[client] = INVALID_HANDLE;
			}
		}
	}
}

/***********************************************************/
/*********************** PLAYER DEATH **********************/
/***********************************************************/
public Action PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	if(B_active_zombie_riot)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		int respawn = GetDayRespawn(INT_CURRENT_DAY);
		
		CreateVarHumans(false, "PLAYER DEATH");
		CreateVarZombies(false, "PLAYER DEATH");
		SetPlayersNone("PLAYER DEATH");
		
		if(B_Player_Is_Zombie[client])
		{
			INT_ZOMBIE_KILLED++;
			
			RemoveTargeters(client);
			UpdateHUDAll();
			
			if(INT_ZOMBIE_KILLED < GetDayCount(INT_CURRENT_DAY) && respawn)
			{
				CreateTimer(1.0, Timer_ZombieRespawn, client, TIMER_FLAG_NO_MAPCHANGE);
			}
			else if (INT_ZOMBIE_KILLED >= GetDayCount(INT_CURRENT_DAY))
			{
				CS_TerminateRound(5.0, CSRoundEnd_CTWin);
				LogToZombieRiot(B_active_zombie_riot_dev, "CT win: INT_ZOMBIE_KILLED >= GetDayCount(INT_CURRENT_DAY)", TAG_CHAT);
				PrintToDev(B_active_zombie_riot_dev, "CT win: INT_ZOMBIE_KILLED >= GetDayCount(INT_CURRENT_DAY)", TAG_CHAT);
			}
			
			PlaySoundDeath(client);
			
			LogToZombieRiot(B_active_zombie_riot_dev, "%s Zombie Killed: %i/%i", TAG_CHAT, INT_ZOMBIE_KILLED, GetDayCount(INT_CURRENT_DAY));
			PrintToDev(B_active_zombie_riot_dev, "%s Zombie Killed: %i/%i", TAG_CHAT, INT_ZOMBIE_KILLED, GetDayCount(INT_CURRENT_DAY));
		}
		else
		{
			ChangeClientDeathCount(client, 1);
			int deaths_before_zombie = GetDayDeathsBeforeZombie(INT_CURRENT_DAY);

			if (deaths_before_zombie > 0 && GetClientDeathCount(client) >= deaths_before_zombie && INT_NB_HUMANS_PLAYER_ALIVE > 0)
			{
				CreateTimer(0.5, Timer_JoinZombie, client);
			}
			else if(deaths_before_zombie > 0 && INT_NB_HUMANS_PLAYER_ALIVE > 0)
			{
				RespawnHuman(client);
				
				char S_human_name[32];
				GetClientName(client, S_human_name, sizeof(S_human_name));
				LogToZombieRiot(B_active_zombie_riot_dev, "%s Player die: %s, Respawn time: %i, Become Zombie: %i/%i", TAG_CHAT, S_human_name, Timer_Respawn[client], GetClientDeathCount(client), deaths_before_zombie);
				PrintToDev(B_active_zombie_riot_dev, "%s Player die: %s, Respawn time: %i, Become Zombie: %i/%i,", TAG_CHAT, S_human_name, Timer_Respawn[client], GetClientDeathCount(client), deaths_before_zombie);
			}

			if (INT_NB_HUMANS_BOTH_ALIVE <= 0)
			{
				CS_TerminateRound(5.0, CSRoundEnd_TerroristWin);
				LogToZombieRiot(B_active_zombie_riot_dev, "Terro win: INT_NB_HUMANS_BOTH_ALIVE <= 0", TAG_CHAT);
				PrintToDev(B_active_zombie_riot_dev, "Terro win: INT_NB_HUMANS_BOTH_ALIVE <= 0", TAG_CHAT);
			}
			
			RemoveTargeters(client);
			UpdateHUDAll();
		}
		
		if (F_zombie_riot_remove_radgoll > 0.0)
		{
			int ragdoll = GetPlayerRagdoll(client);
			CreateTimer(F_zombie_riot_remove_radgoll, Timer_RemoveRagdoll, ragdoll);
		}
	}
}

/***********************************************************/
/*********************** PLAYER TEAM PRE********************/
/***********************************************************/
public Action PlayerTeam_Pre(Handle event, const char[] name, bool dontBroadcast)
{
	if(B_active_zombie_riot)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		int team = GetEventInt(event, "team");
		
		char S_name[64];
		GetClientName(client, S_name, sizeof(S_name));
		
		if(!dontBroadcast)
		{
			Handle new_event = CreateEvent("player_team", true);
			
			SetEventInt(new_event, "userid", GetEventInt(event, "userid"));
			SetEventInt(new_event, "team", GetEventInt(event, "team"));
			SetEventInt(new_event, "oldteam", GetEventInt(event, "oldteam"));
			SetEventBool(new_event, "disconnect", GetEventBool(event, "disconnect"));
			
			FireEvent(new_event, true);
			
			return Plugin_Handled;
		}
		
		if(!IsFakeClient(client))
		{
			if(team == CS_TEAM_CT)
			{
				CPrintToChatAll("%t", "Team CT", S_name);
			}
			else if(team == CS_TEAM_T)
			{
				int deaths_before_zombie = GetDayDeathsBeforeZombie(INT_CURRENT_DAY);
				
				if(GetClientDeathCount(client) >= deaths_before_zombie)
				{
					CPrintToChatAll("%t", "Team T ZOMBIFY", S_name);
				}
				else
				{
					CPrintToChatAll("%t", "Team T", S_name);
				}
			}
		}
		
		CreateVarHumans(false, "PLAYER TEAM");
		CreateVarZombies(false, "PLAYER TEAM");
		SetPlayersNone("PLAYER TEAM");
	}
	return Plugin_Continue;
}

/***********************************************************/
/********************** PLAYER TEAM POST *******************/
/***********************************************************/
public Action PlayerTeam_Post(Handle event, const char[] name, bool dontBroadcast)
{
	if(B_active_zombie_riot)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		int oldteam = GetEventInt(event, "oldteam");
		int team = GetEventInt(event, "team");
		
		if(team != SPECTATOR && oldteam == NONE || oldteam == SPECTATOR)
		{
			CreateTimer(1.0, Timer_CheckTeam, client);
		}

		if(team == HUMAN)
		{
			StopZVision(client);
			SetPlayerFOV(client, DEFAULT_FOV);
			SetEntityGravity(client, DEFAULT_GRAVITY);

			if (IsPlayerAlive(client) || H_Timer_Respawn[client] != INVALID_HANDLE || H_Timer_HUD == INVALID_HANDLE)
			{
				return;
			}

			RespawnHuman(client);
			if(!IsFakeClient(client))
			{
				int daycount = GetClientDayCount("PLAYER TEAM", client);
				if(daycount == 0)
				{
					SetCorrectDayCountClient();
					ChangeClientDayCount("PLAYER TEAM + ADD", client, 1);
				}
			}	
		}	
	}
}

/***********************************************************/
/*********************** PLAYER DEATH **********************/
/***********************************************************/
public Action PlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
	int victim 		= GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker 	= GetClientOfUserId(GetEventInt(event, "attacker"));

	if(!B_Player_Is_Zombie[victim])
	{
		return;
	}

	if (attacker)
	{
		TargetPlayer(attacker, victim);
	}

	int maxplayers = GetMaxClients();
	int[] clients = new int[maxplayers];
	int numClients = GetClientTargeters(victim, clients, maxplayers);

	UpdateHUD(clients, numClients);
}

/***********************************************************/
/*********************** PLAYER DEATH **********************/
/***********************************************************/
public Action PlayerJump(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (B_Player_Is_Zombie[client])
	{
		float vel[3] = {0.0, 0.0, 0.0};
		vel[2] = GetZombieJump(INT_ZOMBIE_ID[client]);

		SetPlayerVelocity(client, vel);
	}
}