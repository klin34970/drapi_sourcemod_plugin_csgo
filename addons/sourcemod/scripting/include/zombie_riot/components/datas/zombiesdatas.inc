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
/******************** LOAD ZOMBIE DATA *********************/
/***********************************************************/
void LoadZombieData(char[] folder, char[] extension)
{
	char path[PLATFORM_MAX_PATH];
	char currentMap[64];
	
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	BuildPath(Path_SM, path, sizeof(path), "%s_%s.%s", folder, currentMap, extension);

	if(!FileExists(path))
	{
		BuildPath(Path_SM, path, sizeof(path), "%s.%s", folder, extension);
	}
	
	ReadZombieData(path);
}

/***********************************************************/
/******************** READ ZOMBIE DATA *********************/
/***********************************************************/
void ReadZombieData(char[] path)
{
	if (!FileExists(path))
	{
		return;
	}

	if (kvZombies != INVALID_HANDLE)
	{
		CloseHandle(kvZombies);
	}

	kvZombies = CreateKeyValues("zombies");

	if (!FileToKeyValues(kvZombies, path))
	{
		SetFailState("\"%s\" failed to load", path);
	}

	KvRewind(kvZombies);
	if (!KvGotoFirstSubKey(kvZombies))
	{
		SetFailState("No zombie data defined in \"%s\"", path);
	}

	char name[64];
	char type[32];
	char model[256];
	char zvision[256];
	
	ZOMBIE_COUNT = 0;
	
	do
	{
		KvGetSectionName(kvZombies, name, sizeof(name));
		strcopy(data_name[ZOMBIE_COUNT], sizeof(name), name);

		KvGetString(kvZombies, "type", type, sizeof(type));
		data_override_required[ZOMBIE_COUNT] = (StrEqual(type, "override_required", false));

		KvGetString(kvZombies, "model", model, sizeof(model));
		strcopy(data_model[ZOMBIE_COUNT], 256, model);

		KvGetString(kvZombies, "zvision", zvision, sizeof(zvision));
		strcopy(data_zvision[ZOMBIE_COUNT], 256, zvision);

		data_health[ZOMBIE_COUNT] 		= KvGetNum(kvZombies, "health", 500);
		data_speed[ZOMBIE_COUNT] 		= KvGetFloat(kvZombies, "speed", 300.0);
		data_gravity[ZOMBIE_COUNT]		= KvGetFloat(kvZombies, "gravity", 1.0);
		data_jump[ZOMBIE_COUNT]			= KvGetFloat(kvZombies, "jump", 1.0);
		data_fov[ZOMBIE_COUNT] 			= KvGetNum(kvZombies, "fov", 90);

		LogToZombieRiot(B_active_zombie_riot_dev, "%s [ZOMBIE %i] - Name: %s, Model: %s, Vision: %s, Health: %i, Speed: %f, Gravity: %f, Jump: %f, Fov: %i, Type: %s", TAG_CHAT, ZOMBIE_COUNT, data_name[ZOMBIE_COUNT], data_model[ZOMBIE_COUNT], data_zvision[ZOMBIE_COUNT], data_health[ZOMBIE_COUNT], data_speed[ZOMBIE_COUNT], data_gravity[ZOMBIE_COUNT], data_jump[ZOMBIE_COUNT], data_fov[ZOMBIE_COUNT], data_override_required[ZOMBIE_COUNT]);

		ZOMBIE_COUNT++;
	} 
	while (KvGotoNextKey(kvZombies));
}

/***********************************************************/
/******************** READ ZOMBIE DATA *********************/
/***********************************************************/
void LoadModelData(char[] folder, char[] extension)
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "%s.%s", folder, extension);

	Handle fileModels = OpenFile(path, "r");

	if (fileModels == INVALID_HANDLE)
	{
		SetFailState("\"%s\" missing from server", path);
	}

	if (adtModels != INVALID_HANDLE)
	{
		CloseHandle(adtModels);
	}

	adtModels = CreateArray(256, 0);

	FileLinesToArray(adtModels, fileModels);

	if (!GetArraySize(adtModels))
	{
		SetFailState("No models listed in models.txt, please add some models then restart");
	}

	char model[256];
	char modelpath[256];

	int modelsize = GetArraySize(adtModels);
	for (int x = 0; x < modelsize; x++)
	{
		for (int y = 0; y < 8; y++)
		{
			GetArrayString(adtModels, x, model, sizeof(model));
			Format(modelpath, sizeof(modelpath), "%s%s", model, modelSuffix[y]);

			if (FileExists(modelpath))
			{
				Downloader_AddFileToDownloadsTable(modelpath);
			}
		}
	}

	CloseHandle(fileModels);
}

/***********************************************************/
/**************** FIND ZOMBIE ID BY NAME *******************/
/***********************************************************/
int FindZombieIDByName(const char[] name)
{
    for (int x = 0; x < ZOMBIE_COUNT; x++)
    {
        if (StrEqual(name, data_name[x], false))
        {
            return x;
        }
    }
    
    return -1;
}

/***********************************************************/
/******************* IS VALID ZOMBIE ID ********************/
/***********************************************************/
bool IsValidZombieID(int zombieid)
{
    if (zombieid > -1 && zombieid < ZOMBIE_COUNT)
    {
        return true;
    }
    
    return false;
}

/***********************************************************/
/***************** IS OVERRIDE REQUIRED ********************/
/***********************************************************/
bool IsOverrideRequired(int zombieid)
{
    if (IsValidZombieID(zombieid))
    {
        return data_override_required[zombieid];
    }
    
    return false;
}

/***********************************************************/
/****************** APPLY ZOMBIE MODEL *********************/
/***********************************************************/
void ApplyZombieModel(int client, int zombieid)
{
    if (IsValidZombieID(zombieid))
    {
        char model[256];
        strcopy(model, sizeof(model), data_model[zombieid]);
        
        PrecacheModel(model);
        SetEntityModel(client, model);
    }
}

/***********************************************************/
/******************* GET ZOMBIE VISION *********************/
/***********************************************************/
void GetZombieZVision(int zombieid, char[] zvision, int maxlen)
{
    if (IsValidZombieID(zombieid))
    {
        strcopy(zvision, maxlen, data_zvision[zombieid]);
    }
}

/***********************************************************/
/****************** APPLY ZOMBIE HEALTH ********************/
/***********************************************************/
void ApplyZombieHealth(int client, int zombieid)
{
    if (IsValidZombieID(zombieid))
    {
        SetEntityHealth(client, data_health[zombieid]);
    }
}

/***********************************************************/
/****************** APPLY ZOMBIE SPEED *********************/
/***********************************************************/
void ApplyZombieSpeed(int client, int zombieid)
{
    if (IsValidZombieID(zombieid))
    {
        SetPlayerSpeed(client, data_speed[zombieid]);
    }
}

/***********************************************************/
/***************** APPLY ZOMBIE GRAVITY ********************/
/***********************************************************/
void ApplyZombieGravity(int client, int zombieid)
{
    if (IsValidZombieID(zombieid))
    {
        SetEntityGravity(client, data_gravity[zombieid]);
    }
}

/***********************************************************/
/******************* APPLY ZOMBIE JUMP *********************/
/***********************************************************/
float GetZombieJump(int zombieid)
{
    if (IsValidZombieID(zombieid))
    {
        return data_jump[zombieid];
    }
    
    return 0.0;
}

/***********************************************************/
/****************** APPLY ZOMBIE FOV *********************/
/***********************************************************/
void ApplyZombieFOV(int client, int zombieid)
{
    if (IsValidZombieID(zombieid))
    {
        SetPlayerFOV(client, data_fov[zombieid]);
    }
}

/***********************************************************/
/********************* LINE TO ARRAY ***********************/
/***********************************************************/
void FileLinesToArray(Handle array, const Handle file)
{
    ClearArray(array);
    
    char line[128];
    
    while(!IsEndOfFile(file) && ReadFileLine(file, line, sizeof(line)))
    {
        if (StrContains(line, ";") == -1)
        {
            if (StrContains(line, "//") > -1)
            {
                SplitString(line, "//", line, sizeof(line));
            }
            TrimString(line);
            
            if (!StrEqual(line, "", false))
            {
                PushArrayString(array, line);
            }
        }
    }
}
