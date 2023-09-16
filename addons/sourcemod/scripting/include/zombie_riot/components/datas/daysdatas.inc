/*    <DR.API ZOMBIE RIOT> (c) by <De Battista Clint - (http://doyou.watch)  */
/*                                                                           */
/*                  <DR.API ZOMBIE RIOT> is licensed under a                 */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//*************************DR.API ZOMBIE RIOT DAY DATAS**********************//
//***************************************************************************//
//***************************************************************************//

/***********************************************************/
/********************* LOAD DAYS DATA **********************/
/***********************************************************/
void LoadDayData(char[] folder, char[] extension)
{
	char path[PLATFORM_MAX_PATH];
	char currentMap[64];
	
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	BuildPath(Path_SM, path, sizeof(path), "%s_%s.%s", folder, currentMap, extension);

	if(!FileExists(path))
	{
		BuildPath(Path_SM, path, sizeof(path), "%s.%s", folder, extension);
	}
	
	ReadDayFile(path);
}

/***********************************************************/
/********************* LOAD DAYS DATA **********************/
/***********************************************************/
void ReadDayFile(char[] path)
{
	if (!FileExists(path))
	{
		return;
	}

	if (kvDays != INVALID_HANDLE)
	{
		CloseHandle(kvDays);
	}

	kvDays = CreateKeyValues("days");
	KvSetEscapeSequences(kvDays, true);

	if (!FileToKeyValues(kvDays, path))
	{
		SetFailState("\"%s\" failed to load", path);
	}

	KvRewind(kvDays);
	if (!KvGotoFirstSubKey(kvDays))
	{
		SetFailState("No day data defined in \"%s\"", path);
	}

	char display[64];
	char storyline[192];
	char zombieoverride[32*MAX_ZOMBIES];
	char overlay_human[32*MAX_ZOMBIES];
	char overlay_zombie[32*MAX_ZOMBIES];
	char sound[PLATFORM_MAX_PATH];
	char ct_default_melee[64], ct_default_secondary[64], ct_default_primary[64];

	INT_TOTAL_DAY = 0;
	do
	{
		KvGetSectionName(kvDays, display, sizeof(display));
		strcopy(data_display[INT_TOTAL_DAY], sizeof(display), display);
		
		KvGetString(kvDays, "storyline", storyline, sizeof(storyline));
		strcopy(data_storyline[INT_TOTAL_DAY], sizeof(storyline), storyline);
		
		KvGetString(kvDays, "zombieoverride", zombieoverride, sizeof(zombieoverride));
		strcopy(data_zombieoverride[INT_TOTAL_DAY], 32*MAX_ZOMBIES, zombieoverride);

		
		data_count[INT_TOTAL_DAY] 							= KvGetNum(kvDays, 		"count", 25);
		data_count2[INT_TOTAL_DAY] 							= KvGetNum(kvDays, 		"count", 25);
		data_healthboost[INT_TOTAL_DAY] 					= KvGetNum(kvDays, 		"healthboost");
		data_respawn[INT_TOTAL_DAY]							= KvGetNum(kvDays, 		"respawn");
		data_admin_respawn_time[INT_TOTAL_DAY]				= KvGetNum(kvDays, 		"admin_respawn_time");
		data_vip_respawn_time[INT_TOTAL_DAY]				= KvGetNum(kvDays, 		"vip_respawn_time");
		data_player_respawn_time[INT_TOTAL_DAY]				= KvGetNum(kvDays, 		"player_respawn_time");
		data_deaths_before_zombie[INT_TOTAL_DAY] 			= KvGetNum(kvDays, 		"deaths_before_zombie");
		data_add_zombies_by_player[INT_TOTAL_DAY] 			= KvGetNum(kvDays, 		"add_zombies_by_player", 0);
		data_regression[INT_TOTAL_DAY] 						= KvGetNum(kvDays, 		"regression", 0);
		data_fademin[INT_TOTAL_DAY] 						= KvGetFloat(kvDays, 	"fademin");
		data_fademax[INT_TOTAL_DAY]							= KvGetFloat(kvDays,	"fademax");
		data_sound_timer[INT_TOTAL_DAY]						= KvGetFloat(kvDays,	"sound_time");
		
		KvGetString(kvDays, "overlay_human", overlay_human, sizeof(overlay_human));
		strcopy(data_overlay_human[INT_TOTAL_DAY], 32*MAX_ZOMBIES, overlay_human);
		
		KvGetString(kvDays, "overlay_zombie", overlay_zombie, sizeof(overlay_zombie));
		strcopy(data_overlay_zombie[INT_TOTAL_DAY], 32*MAX_ZOMBIES, overlay_zombie);
		
		KvGetString(kvDays, "sound", sound, sizeof(sound));
		strcopy(data_sound[INT_TOTAL_DAY], PLATFORM_MAX_PATH, sound);
		
		KvGetString(kvDays, "ct_default_melee", ct_default_melee, sizeof(ct_default_melee));
		strcopy(data_ct_default_melee[INT_TOTAL_DAY], sizeof(ct_default_melee), ct_default_melee);
		
		KvGetString(kvDays, "ct_default_secondary", ct_default_secondary, sizeof(ct_default_secondary));
		strcopy(data_ct_default_secondary[INT_TOTAL_DAY], sizeof(ct_default_secondary), ct_default_secondary);
		
		KvGetString(kvDays, "ct_default_primary", ct_default_primary, sizeof(ct_default_primary));
		strcopy(data_ct_default_primary[INT_TOTAL_DAY], sizeof(ct_default_primary), ct_default_primary);
		
		LogToZombieRiot(B_active_zombie_riot_dev, "%s [DAY %i - %s] - NB: %i,     HEAL: %i, RESPAWN: %i, ZOMBIFY: %i, FADEMIN: %f, FADEMAX: %f, ZOMBIES: %s, OVERRIDES: %s, CT Melee: %s, CT secondary: %s, CT Primary: %s", TAG_CHAT, INT_TOTAL_DAY, data_display[INT_TOTAL_DAY], data_count[INT_TOTAL_DAY], data_healthboost[INT_TOTAL_DAY], data_respawn[INT_TOTAL_DAY], data_deaths_before_zombie[INT_TOTAL_DAY], data_fademin[INT_TOTAL_DAY], data_fademax[INT_TOTAL_DAY], data_zombieoverride[INT_TOTAL_DAY], data_zombieoverride[INT_TOTAL_DAY], data_ct_default_melee[INT_TOTAL_DAY], data_ct_default_secondary[INT_TOTAL_DAY], data_ct_default_primary[INT_TOTAL_DAY]);

		INT_TOTAL_DAY++;
	} 
	while (KvGotoNextKey(kvDays));
}

/***********************************************************/
/************* EXPLODE STRING ZOMBIE OVERRIDES *************/
/***********************************************************/
bool ExplodeZombieOverrides(int day)
{
    if (adtZombies != INVALID_HANDLE)
    {
        CloseHandle(adtZombies);
        adtZombies = INVALID_HANDLE;
    }
    
    char zombieoverride[32*MAX_ZOMBIES];
    GetDayZombieOverride(day, zombieoverride, sizeof(zombieoverride));
    
    if(zombieoverride[0])
    {
        adtZombies = CreateArray();
        
        char sZombies[MAX_ZOMBIES][64];
        ExplodeString(zombieoverride, ",", sZombies, MAX_ZOMBIES, 64);
        
        for(int x = 0; x < MAX_ZOMBIES; x++)
        {
            if(!sZombies[x][0])
                continue;
            
            TrimString(sZombies[x]);
            int zombieid = FindZombieIDByName(sZombies[x]);
            
            if (zombieid == -1)
                continue;
            
            PushArrayCell(adtZombies, zombieid);
        }
        
        return true;
    }
    
    return false;
}

/***********************************************************/
/********************** GET DAY STORY **********************/
/***********************************************************/
void GetDayStoryLine(int day, char[] storyline, int len)
{
    strcopy(storyline, len, data_storyline[day]);
}

/***********************************************************/
/*********************** GET DAY NAME **********************/
/***********************************************************/
void GetDayDisplay(int day, char[] display, int len)
{
    strcopy(display, len, data_display[day]);
}

/***********************************************************/
/*********************** GET DAY ZOMBIES ********************/
/***********************************************************/
void GetDayZombieOverride(int day, char[] zombieoverride , int len)
{
    strcopy(zombieoverride, len, data_zombieoverride[day]);
}

/***********************************************************/
/*********************** GET DAY COUNT *********************/
/***********************************************************/
int GetDayCount(int day)
{
    return data_count[day];
}

/***********************************************************/
/*********************** GET DAY COUNT *********************/
/***********************************************************/
int GetDayAddZombiesByPlayer(int day)
{
    return data_add_zombies_by_player[day];
}

/***********************************************************/
/********************** GET DAY HEALTH *********************/
/***********************************************************/
int GetDayHealthBoost(int day)
{
    return data_healthboost[day];
}

/***********************************************************/
/********************** GET DAY RESPAWN ********************/
/***********************************************************/
int GetDayRespawn(int day)
{
    return data_respawn[day];
}

/***********************************************************/
/***************** GET DAY ADMIN RESPAWN TIME **************/
/***********************************************************/
int GetDayAdminRespawnTime(int day)
{
    return data_admin_respawn_time[day];
}

/***********************************************************/
/****************** GET DAY VIP RESPAWN TIME ***************/
/***********************************************************/
int GetDayVipRespawnTime(int day)
{
    return data_vip_respawn_time[day];
}

/***********************************************************/
/***************** GET DAY PLAYER RESPAWN TIME *************/
/***********************************************************/
int GetDayPlayerRespawnTime(int day)
{
    return data_player_respawn_time[day];
}

/***********************************************************/
/**************** GET DAY DEATH BEFORE ZOMBIE **************/
/***********************************************************/
int GetDayDeathsBeforeZombie(int day)
{
    return data_deaths_before_zombie[day];
}

/***********************************************************/
/**************** GET DAY DEATH BEFORE ZOMBIE **************/
/***********************************************************/
int GetDayRegression(int day)
{
    return data_regression[day];
}

/***********************************************************/
/********************* GET DAY MIN FADE ********************/
/***********************************************************/
float GetDayMinFade(int day)
{
    return data_fademin[day];
}

/***********************************************************/
/********************* GET DAY MAX FADE ********************/
/***********************************************************/
float GetDayMaxFade(int day)
{
    return data_fademax[day];
}

/***********************************************************/
/****************** GET DAY OVERLAY HUMAN ******************/
/***********************************************************/
void GetDayOverlayHuman(int day, char[] overlay_human , int len)
{
    strcopy(overlay_human, len, data_overlay_human[day]);
}

/***********************************************************/
/****************** GET DAY OVERLAY ZOMBIE *****************/
/***********************************************************/
void GetDayOverlayZombie(int day, char[] overlay_zombie , int len)
{
    strcopy(overlay_zombie, len, data_overlay_zombie[day]);
}

/***********************************************************/
/*********************** GET DAY SOUND *********************/
/***********************************************************/
void GetDaySound(int day, char[] sound , int len)
{
    strcopy(sound, len, data_sound[day]);
}

/***********************************************************/
/******************* GET DAY SOUND TIME ********************/
/***********************************************************/
float GetDaySoundTime(int day)
{
    return data_sound_timer[day];
}

/***********************************************************/
/****************** GET DAY CT MELEE WEAPON ****************/
/***********************************************************/
void GetDayCTMeleeWeapon(int day, char[] ct_default_melee , int len)
{
    strcopy(ct_default_melee, len, data_ct_default_melee[day]);
}

/***********************************************************/
/**************** GET DAY CT SECONDARY WEAPON **************/
/***********************************************************/
void GetDayCTSecondaryWeapon(int day, char[] ct_default_secondary , int len)
{
    strcopy(ct_default_secondary, len, data_ct_default_secondary[day]);
}

/***********************************************************/
/**************** GET DAY CT SECONDARY WEAPON **************/
/***********************************************************/
void GetDayCTPrimaryWeapon(int day, char[] ct_default_primary , int len)
{
    strcopy(ct_default_primary, len, data_ct_default_primary[day]);
}