/*    <DR.API ZOMBIE RIOT> (c) by <De Battista Clint - (http://doyou.watch)  */
/*                                                                           */
/*                  <DR.API ZOMBIE RIOT> is licensed under a                 */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//**************************DR.API ZOMBIE RIOT ZRHELP************************//
//***************************************************************************//
//***************************************************************************//

/***********************************************************/
/***************** CREATE COMMANDS HELP ********************/
/***********************************************************/
void CreateCommandsHelp()
{
	RegConsoleCmd("sm_zrhelp",		Command_MenuZombieRiotHelp, 		"Zombie riot help menu");
	RegConsoleCmd("sm_help",		Command_MenuZombieRiotHelp, 		"Zombie riot help menu");
}

/***********************************************************/
/***************** LOAD HELP MENU CONFIG********************/
/***********************************************************/
void LoadHelpMenuConfig(int client, char[] folder, char[] extension)
{
	char path[PLATFORM_MAX_PATH];
	char sCodeLang[3], sNameLang[3];
	int idLang = GetClientLanguage(client);
	
	GetLanguageInfo(idLang, sCodeLang, sizeof(sCodeLang), sNameLang, sizeof(sNameLang));
	
	BuildPath(Path_SM, path, sizeof(path), "%s_%s.%s", folder, sCodeLang, extension);

	if(!FileExists(path))
	{
		BuildPath(Path_SM, path, sizeof(path), "%s.%s", folder, extension);
	}
	
	ParseConfigFile(path);
}

/***********************************************************/
/************ COMMAND ZOMBIE RIOT HELP MENU ****************/
/***********************************************************/
public Action Command_MenuZombieRiotHelp(int client, int args) 
{
	LoadHelpMenuConfig(client, "configs/drapi/zombie_riot/help/menu", "cfg");
	Help_ShowMainMenu(client);
	return Plugin_Handled;
}

void Help_ShowMainMenu(int client) 
{
	Menu menu = CreateMenu(Help_MainMenuHandler);
	SetMenuExitBackButton(menu, false);
	
	char title[40], day[40], map[40], admin[40], death[40];
	Format(title, sizeof(title), "%T", "MenuHelpZombieRiot_TITLE", client);
	SetMenuTitle(menu, title);
	
	int msize = GetArraySize(Array_Helpmenus);
	int hmenu[HelpMenu];
	char menuid[10];

	int deathcount = GetClientDeathCount(client);
	int deaths_before_zombie = GetDayDeathsBeforeZombie(INT_CURRENT_DAY);
	
	Format(death, sizeof(death), "%T", "MenuZombieRiot_ZOMBIFY_MENU_TITLE", client, deathcount, deaths_before_zombie);
	AddMenuItem(menu, "M_deaths_before_zombie", death, ITEMDRAW_DISABLED);
	
	Format(day, sizeof(day), "%T", "MenuHelpZombieRiot_DAY_MENU_TITLE", client);
	AddMenuItem(menu, "day", day);
	
	for(int i = 0; i < msize; ++i)
	{
		Format(menuid, sizeof(menuid), "helpmenu_%d", i);
		GetArrayArray(Array_Helpmenus, i, hmenu[0]);
		AddMenuItem(menu, menuid, hmenu[Hname]);
	}
	
	Format(map, sizeof(map), "%T", "MenuHelpZombieRiot_MAP_MENU_TITLE", client);
	AddMenuItem(menu, "maplist", map);
	
	Format(admin, sizeof(admin), "%T", "MenuHelpZombieRiot_ADMIN_MENU_TITLE", client);
	AddMenuItem(menu, "admins", admin);
	
	DisplayMenu(menu, client, 30);
}

/***********************************************************/
/************* ZOMBIE RIOT HELP MENU ACTION ****************/
/***********************************************************/
public int Help_MainMenuHandler(Handle menu, MenuAction action, int param1, int param2) 
{
	if(action == MenuAction_End) 
	{
		CloseHandle(menu);
	} 
	else if(action == MenuAction_Select) 
	{
		char buf[64];
		int msize = GetArraySize(Array_Helpmenus);
		//PrintToChatAll("%i, %i", param2, msize);
		
		if(param2 == 1) 
		{ 
			// DAYS
			Handle dayMenu = CreateMenu(Help_MenuHandler);
			SetMenuExitBackButton(dayMenu, true);
			Format(buf, sizeof(buf), "%T", "MenuHelpZombieRiot_DAY_MENU_TITLE", param1);
			SetMenuTitle(dayMenu, buf);

			char storyline[192];
			GetDayStoryLine(INT_CURRENT_DAY, storyline, sizeof(storyline));
			char storyday_translate[129];
			Format(storyday_translate, sizeof(storyday_translate),"%T", storyline, param1);
			if(storyday_translate[0])
			{
				ReplaceString(storyday_translate, sizeof(storyday_translate), "[{GREEN}ZOMBIE RIOT{NORMAL}] ", "", false);
				AddMenuItem(dayMenu, "1", storyday_translate, ITEMDRAW_DISABLED);
			}
			
			int count = GetDayCount(INT_CURRENT_DAY);
			char help_count[129];
			Format(help_count, sizeof(help_count),"%T", "MenuHelpZombieRiot_HELP_COUNT", param1, count);
			AddMenuItem(dayMenu, "2", help_count, ITEMDRAW_DISABLED);
			
			int count_player = GetDayAddZombiesByPlayer(INT_CURRENT_DAY);
			char help_count_player[129];
			Format(help_count_player, sizeof(help_count_player),"%T", "MenuHelpZombieRiot_HELP_COUNT_PLAYER", param1, count_player);
			AddMenuItem(dayMenu, "3", help_count_player, ITEMDRAW_DISABLED);
			
			int death = GetDayDeathsBeforeZombie(INT_CURRENT_DAY);
			char help_death[129];
			Format(help_death, sizeof(help_death),"%T", "MenuHelpZombieRiot_HELP_DEATH", param1, death);
			AddMenuItem(dayMenu, "4", help_death, ITEMDRAW_DISABLED);
			
			int regression = GetDayRegression(INT_CURRENT_DAY);
			if(regression)
			{
				char help_regression[129];
				Format(help_regression, sizeof(help_regression),"%T", "MenuHelpZombieRiot_HELP_REGRESSION", param1);
				AddMenuItem(dayMenu, "5", help_regression, ITEMDRAW_DISABLED);
			}
			
			
			if(!regression)
			{
				AddMenuItem(dayMenu, "", "", ITEMDRAW_DISABLED);
			}
			if(!storyday_translate[0])
			{
				AddMenuItem(dayMenu, "", "", ITEMDRAW_DISABLED);
			}
			
			AddMenuItem(dayMenu, "", "", ITEMDRAW_DISABLED);
			
			//ZOMBIEDATA
			bool override = ExplodeZombieOverrides(INT_CURRENT_DAY);
			if(override)
			{
				int size = GetArraySize(adtZombies);
				if(size)
				{
					for(int i = 0; i < size; ++i) 
					{
						int id = GetArrayCell(adtZombies, i);
						char help_zombie[129];

						Format(help_zombie, sizeof(help_zombie),"%T", "MenuHelpZombieRiot_HELP_ZOMBIE_NAME", param1, data_name[id]);
						AddMenuItem(dayMenu, "", help_zombie, ITEMDRAW_DISABLED);	
						
						Format(help_zombie, sizeof(help_zombie),"%T", "MenuHelpZombieRiot_HELP_ZOMBIE_HEALTH", param1, data_health[id]);
						AddMenuItem(dayMenu, "", help_zombie, ITEMDRAW_DISABLED);	

						Format(help_zombie, sizeof(help_zombie),"%T", "MenuHelpZombieRiot_HELP_ZOMBIE_SPEED", param1, data_speed[id]);
						AddMenuItem(dayMenu, "", help_zombie, ITEMDRAW_DISABLED);

						Format(help_zombie, sizeof(help_zombie),"%T", "MenuHelpZombieRiot_HELP_ZOMBIE_GRAVITY", param1, data_gravity[id]);
						AddMenuItem(dayMenu, "", help_zombie, ITEMDRAW_DISABLED);	

						Format(help_zombie, sizeof(help_zombie),"%T", "MenuHelpZombieRiot_HELP_ZOMBIE_JUMP", param1, data_jump[id]);
						AddMenuItem(dayMenu, "", help_zombie, ITEMDRAW_DISABLED);	

						Format(help_zombie, sizeof(help_zombie),"%T", "MenuHelpZombieRiot_HELP_ZOMBIE_FOV", param1, data_fov[id]);
						AddMenuItem(dayMenu, "", help_zombie, ITEMDRAW_DISABLED);						
					}
				}
			}
			DisplayMenu(dayMenu, param1, 30);
		} 
		
		else if(param2 == msize+2) 
		{ 
			// Maps
			Handle mapMenu = CreateMenu(Help_MenuHandler);
			SetMenuExitBackButton(mapMenu, true);
			ReadMapList(Array_Map, C_mapSerial, "default");
			Format(buf, sizeof(buf), "%T", "MenuHelpZombieRiot_MAP_CURRENT_MENU_TITLE", param1, GetArraySize(Array_Map));
			SetMenuTitle(mapMenu, buf);

			if(Array_Map != INVALID_HANDLE)
			{
				int mapct = GetArraySize(Array_Map);
				char mapname[64];
				
				for(int i = 0; i < mapct; ++i) 
				{
					GetArrayString(Array_Map, i, mapname, sizeof(mapname));
					AddMenuItem(mapMenu, mapname, mapname, ITEMDRAW_DISABLED);
				}
			}

			DisplayMenu(mapMenu, param1, 30);
		} 
		else if(param2 == msize+3)
		{ 
			// Admins
			Handle adminMenu = CreateMenu(Help_MenuHandler);
			SetMenuExitBackButton(adminMenu, true);
			
			char title[40];
			Format(title, sizeof(title), "%T", "MenuHelpZombieRiot_TITLE", param1);
			SetMenuTitle(adminMenu, title);
			
			int maxc = GetMaxClients();
			char aname[64];

			for(int i = 1; i < maxc; ++i) 
			{
				if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && (GetUserFlagBits(i) & ADMFLAG_GENERIC) == ADMFLAG_GENERIC) 
				{
					GetClientName(i, aname, sizeof(aname));
					AddMenuItem(adminMenu, aname, aname, ITEMDRAW_DISABLED);
				}
			}

			DisplayMenu(adminMenu, param1, 30);

		} 
		else 
		{ 
			// Menu from config file
			if(param2 <= msize + 2)
			{
				int hmenu[HelpMenu];
				GetArrayArray(Array_Helpmenus, param2 - 2, hmenu[0]);
				char mtitle[512], Back[40], Exit[40];
				Format(mtitle, sizeof(mtitle), "%s\n ", hmenu[Htitle]);
				if(hmenu[Htype] == HelpMenuType_Text)
				{
					Handle cpanel = CreatePanel();
					SetPanelTitle(cpanel, mtitle);
					char text[128];
					char junk[128];

					for(int i = 0; i < hmenu[itemct]; ++i) 
					{
						ReadPackString(hmenu[Hitems], junk, sizeof(junk));
						ReadPackString(hmenu[Hitems], text, sizeof(text));
						DrawPanelText(cpanel, text);
					}

					for (int j = 0; j < 7; ++j)
					{
						DrawPanelItem(cpanel, " ", ITEMDRAW_NOTEXT);
					}

					DrawPanelText(cpanel, " ");
					
					Format(Back, sizeof(Back), "%T", "Back", param1);
					DrawPanelItem(cpanel, Back, ITEMDRAW_CONTROL);
					
					DrawPanelItem(cpanel, " ", ITEMDRAW_NOTEXT);
					DrawPanelText(cpanel, " ");
					
					Format(Exit, sizeof(Exit), "%T", "Exit", param1);
					DrawPanelItem(cpanel, Exit, ITEMDRAW_CONTROL);
					
					ResetPack(hmenu[Hitems]);
					SendPanelToClient(cpanel, param1, Help_MenuHandler, 30);
					CloseHandle(cpanel);
				} 
				else 
				{
					Handle cmenu = CreateMenu(Help_CustomMenuHandler);
					SetMenuExitBackButton(cmenu, true);
					SetMenuTitle(cmenu, mtitle);
					char cmd[128];
					char desc[128];

					for(int i = 0; i < hmenu[itemct]; ++i) 
					{
						ReadPackString(hmenu[Hitems], cmd, sizeof(cmd));
						ReadPackString(hmenu[Hitems], desc, sizeof(desc));
						int drawstyle = ITEMDRAW_DEFAULT;
						if(strlen(cmd) == 0)
						{
							drawstyle = ITEMDRAW_DISABLED;
						}
						AddMenuItem(cmenu, cmd, desc, drawstyle);
					}

					ResetPack(hmenu[Hitems]);
					DisplayMenu(cmenu, param1, 30);
				}
			}
		}
	}
}

/***********************************************************/
/************* ZOMBIE RIOT HELP MENU ACTION ****************/
/***********************************************************/
public int Help_MenuHandler(Handle menu, MenuAction action, int param1, int param2) 
{
	if(action == MenuAction_End) 
	{
		CloseHandle(menu);
	} 
	else if(menu == INVALID_HANDLE && action == MenuAction_Select && param2 == 8)
	{
		Help_ShowMainMenu(param1);
	} 
	else if(action == MenuAction_Cancel) 
	{
		if (param2 == MenuCancel_ExitBack)
		{
			Help_ShowMainMenu(param1);
		}
	}
}

/***********************************************************/
/************* ZOMBIE RIOT HELP MENU ACTION ****************/
/***********************************************************/
public int Help_CustomMenuHandler(Handle menu, MenuAction action, int param1, int param2) 
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	} 
	else if(action == MenuAction_Select) 
	{
		char itemval[32];
		GetMenuItem(menu, param2, itemval, sizeof(itemval));

		if (strlen(itemval) > 0)
		{
			FakeClientCommand(param1, itemval);
		}
	} 
	else if(action == MenuAction_Cancel) 
	{
		if (param2 == MenuCancel_ExitBack)
		{
			Help_ShowMainMenu(param1);
		}
	}
}

/***********************************************************/
/**************** PARSE HELP MENU CONFIG *******************/
/***********************************************************/
bool ParseConfigFile(const char[] file) 
{
	if(Array_Helpmenus != INVALID_HANDLE) 
	{
		ClearArray(Array_Helpmenus);
		CloseHandle(Array_Helpmenus);
		Array_Helpmenus = INVALID_HANDLE;
	}

	Handle parser = SMC_CreateParser();
	SMC_SetReaders(parser, Config_NewSection, Config_KeyValue, Config_EndSection);
	SMC_SetParseEnd(parser, Config_End);

	int line = 0;
	int col = 0;
	char error[128];
	SMCError result = SMC_ParseFile(parser, file, line, col);
	CloseHandle(parser);

	if(result != SMCError_Okay) 
	{
		SMC_GetErrorString(result, error, sizeof(error));
		LogError("%s on line %d, col %d of %s", error, line, col, file);
	}

	return (result == SMCError_Okay);
}

/***********************************************************/
/****************** NEW SECTION CONFIG *********************/
/***********************************************************/
public SMCResult Config_NewSection(Handle parser, const char[] section, bool quotes) 
{
	C_configLevel++;
	
	if(C_configLevel == 1) 
	{
		int hmenu[HelpMenu];
		strcopy(hmenu[Hname], sizeof(hmenu[Hname]), section);
		hmenu[Hitems] = CreateDataPack();
		hmenu[itemct] = 0;
		
		if (Array_Helpmenus == INVALID_HANDLE)
		{
			Array_Helpmenus = CreateArray(sizeof(hmenu));
		}
		
		PushArrayArray(Array_Helpmenus, hmenu[0]);
	}
	return SMCParse_Continue;
}

/***********************************************************/
/******************* KEY VALUE CONFIG **********************/
/***********************************************************/
public SMCResult Config_KeyValue(Handle parser, const char[] key, const char[] value, bool key_quotes, bool value_quotes) 
{
	int msize = GetArraySize(Array_Helpmenus);
	int hmenu[HelpMenu];
	GetArrayArray(Array_Helpmenus, msize-1, hmenu[0]);
	switch(C_configLevel) 
	{
		case 1: 
		{
			if(strcmp(key, "title", false) == 0)
			{
				strcopy(hmenu[Htitle], sizeof(hmenu[Htitle]), value);
			}
			if(strcmp(key, "type", false) == 0) 
			{
				if(strcmp(value, "text", false) == 0)
				{
					hmenu[Htype] = HelpMenuType_Text;
				}
				else
				{
					hmenu[Htype] = HelpMenuType_List;
				}
			}
		}
		case 2: 
		{
			WritePackString(hmenu[Hitems], key);
			WritePackString(hmenu[Hitems], value);
			hmenu[itemct]++;
		}
	}
	SetArrayArray(Array_Helpmenus, msize-1, hmenu[0]);
	return SMCParse_Continue;
}

/***********************************************************/
/****************** END SECTION CONFIG *********************/
/***********************************************************/
public SMCResult Config_EndSection(Handle parser) 
{
	C_configLevel--;
	if(C_configLevel == 1) 
	{
		int hmenu[HelpMenu];
		int msize = GetArraySize(Array_Helpmenus);
		GetArrayArray(Array_Helpmenus, msize-1, hmenu[0]);
		ResetPack(hmenu[Hitems]);
	}
	return SMCParse_Continue;
}

/***********************************************************/
/********************** END CONFIG *************************/
/***********************************************************/
public void Config_End(Handle parser, bool halted, bool failed) 
{
	if(failed)
	{
		SetFailState("Plugin configuration error");
	}
}

