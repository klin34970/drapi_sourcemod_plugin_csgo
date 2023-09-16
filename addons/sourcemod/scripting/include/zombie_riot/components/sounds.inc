/*    <DR.API ZOMBIE RIOT> (c) by <De Battista Clint - (http://doyou.watch)  */
/*                                                                           */
/*                  <DR.API ZOMBIE RIOT> is licensed under a                 */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//**************************DR.API ZOMBIE RIOT SOUNDS************************//
//***************************************************************************//
//***************************************************************************//

/***********************************************************/
/********************* PLAY DEATH SOUND ********************/
/***********************************************************/
void PlaySoundDeath(int client)
{
	int random = GetRandomInt(0, sizeof(S_sound_death) - 1);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && C_play_sound[i])
		{
			EmitSoundToClientAny(i, S_sound_death[random], client, SNDCHAN_DEATH, _, _, 0.7, _);
		}
	}
}

/***********************************************************/
/******************* PLAY AMBIENT SOUND ********************/
/***********************************************************/
void PlayAmbientSoundRoundStart()
{
	for (int i = 1; i <= MaxClients+1; ++i)
	{
		if (H_Timer_Ambient_Sound[i] != INVALID_HANDLE)
		{
			CloseHandle(H_Timer_Ambient_Sound[i]);
			H_Timer_Ambient_Sound[i] = INVALID_HANDLE;
		}
		
		StartPlayAmbientSound(i);
	}
}

/***********************************************************/
/**************** TIMER PLAY AMBIENT SOUND *****************/
/***********************************************************/
public Action Timer_PlayAmbientSound(Handle timer, any client)
{
	AmbientSound(client, 1.0);
}

/***********************************************************/
/********************* AMBIENT SOUND ***********************/
/***********************************************************/
void AmbientSound(int client, float vol)
{
	if(Client_IsIngame(client) && !IsFakeClient(client) && C_play_sound[client])
	{
		char day_sound[PLATFORM_MAX_PATH];
		GetDaySound(INT_CURRENT_DAY, day_sound, sizeof(day_sound));
		
		EmitSoundToClientAny(client, day_sound, SOUND_FROM_PLAYER, SNDCHAN_AMBIENT, _, _, vol, _);
		
		LogToZombieRiot(B_active_zombie_riot_dev, "%s Abient sound play: %s", TAG_CHAT, day_sound);
		PrintToDev(B_active_zombie_riot_dev, "%s Abient sound play: %s", TAG_CHAT, day_sound);
	}
}

/***********************************************************/
/**************** START PLAY AMBIENT SOUND *****************/
/***********************************************************/
void StartPlayAmbientSound(int client)
{
	if (H_Timer_Ambient_Sound[client] != INVALID_HANDLE)
	{
		CloseHandle(H_Timer_Ambient_Sound[client]);
		H_Timer_Ambient_Sound[client] = INVALID_HANDLE;
	}
	
	float time = GetDaySoundTime(INT_CURRENT_DAY);
	H_Timer_Ambient_Sound[client] = CreateTimer(1.0, Timer_PlayAmbientSound, client);
	H_Timer_Ambient_Sound[client] = CreateTimer(time, Timer_PlayAmbientSound, client, TIMER_REPEAT);
}

/***********************************************************/
/**************** STOP PLAY AMBIENT SOUND ******************/
/***********************************************************/
void StopPlayAmbientSound(int client)
{
	if (H_Timer_Ambient_Sound[client] != INVALID_HANDLE)
	{
		CloseHandle(H_Timer_Ambient_Sound[client]);
		H_Timer_Ambient_Sound[client] = INVALID_HANDLE;
	}
	
	AmbientSound(client, 0.0);
}