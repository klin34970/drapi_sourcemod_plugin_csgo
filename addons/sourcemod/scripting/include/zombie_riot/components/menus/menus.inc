/*    <DR.API ZOMBIE RIOT> (c) by <De Battista Clint - (http://doyou.watch)  */
/*                                                                           */
/*                  <DR.API ZOMBIE RIOT> is licensed under a                 */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//***************************DR.API ZOMBIE RIOT MENUS************************//
//***************************************************************************//
//***************************************************************************//

void CreateCommands()
{
	//RegConsoleCmd("sm_zr",		Command_MenuZombieRiot, 		"Zombie riot menu general");
}
/***********************************************************/
/*************** COMMAND ZOMBIE RIOT MENU ******************/
/***********************************************************/
public Action Command_MenuZombieRiot(int client, int args) 
{
	BuildMenuZombieRiot(client);
	return Plugin_Handled;
}

/***********************************************************/
/**************** BUILD ZOMBIE RIOT MENU *******************/
/***********************************************************/
void BuildMenuZombieRiot(int client)
{
	char title[40]; 
	char hud[40];
	char death[40];
	char overlay[40];
	char zvision[40];
	char sound[40];
	Menu menu = CreateMenu(MenuZombieRiotAction);
	
	int deathcount = GetClientDeathCount(client);
	int deaths_before_zombie = GetDayDeathsBeforeZombie(INT_CURRENT_DAY);
	
	if(deaths_before_zombie > 0)
	{
		Format(death, sizeof(death), "%T", "MenuZombieRiot_ZOMBIFY_MENU_TITLE", client, deathcount, deaths_before_zombie);
		AddMenuItem(menu, "M_deaths_before_zombie", death, ITEMDRAW_DISABLED);
	}
	
	if(B_zombie_riot_hud)
	{
		Format(hud, sizeof(hud), "%T", "MenuZombieRiot_HUD_MENU_TITLE", client);
		AddMenuItem(menu, "M_hud", hud);
	}
	
	if(B_zombie_riot_overlays)
	{
		Format(overlay, sizeof(overlay), "%T", "MenuZombieRiot_OVERLAYS_MENU_TITLE", client);
		AddMenuItem(menu, "M_overlays", overlay);
	}
	
	if(F_zombie_riot_zvision > 0.0)
	{
		Format(zvision, sizeof(zvision), "%T", "MenuZombieRiot_ZVISION_MENU_TITLE", client);
		AddMenuItem(menu, "M_zvision", zvision);
	}
	
	if(B_zombie_riot_sounds)
	{
		Format(sound, sizeof(sound), "%T", "MenuZombieRiot_SOUNDS_MENU_TITLE", client);
		AddMenuItem(menu, "M_sounds", sound);
	}
	
	
	Format(title, sizeof(title), "%T", "MenuZombieRiot_TITLE", client);
	menu.SetTitle(title);
	SetMenuExitBackButton(menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
}

/***********************************************************/
/*************** ZOMBIE RIOT MENU ACTIONS ******************/
/***********************************************************/
public int MenuZombieRiotAction(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);	
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && MenuZombieRiot != INVALID_HANDLE)
			{
				DisplayTopMenu(MenuZombieRiot, param1, TopMenuPosition_Start);
			}		
		}
		case MenuAction_Select:
		{
			char menu1[56];
			menu.GetItem(param2, menu1, sizeof(menu1));
			
			if(StrEqual(menu1, "M_hud"))
			{
				BuildMenuZombieRiot_HUD(param1);
			}
			else if(StrEqual(menu1, "M_overlays"))
			{
				BuildMenuZombieRiot_OVERLAYS(param1);
			}
			else if(StrEqual(menu1, "M_sounds"))
			{
				BuildMenuZombieRiot_SOUNDS(param1);
			}
			else if(StrEqual(menu1, "M_zvision"))
			{
				BuildMenuZombieRiot_ZVISION(param1);
			}
		}
	}
}

/***********************************************************/
/******************** BUILD HUD MENU ***********************/
/***********************************************************/
void BuildMenuZombieRiot_HUD(int client)
{
	char title[40]; 
	char hud[40]; 
	char status[40];
	Menu menu = CreateMenu(BuildMenuZombieRiot_HUD_ACTION);
	SetMenuExitBackButton(menu, true);

	Format(status, sizeof(status), "%T", (C_show_hud[client]) ? "Enabled" : "Disabled", client);
	
	Format(hud, sizeof(hud), "%T", "HUD_STATUS_MENU_TITLE", client, status);
	AddMenuItem(menu, "M_hud_status", hud);
	
	Format(title, sizeof(title), "%T", "HUD_TITLE", client);
	menu.SetTitle(title);
	menu.Display(client, MENU_TIME_FOREVER);
}

/***********************************************************/
/******************* HUD MENU ACTIONS **********************/
/***********************************************************/
public int BuildMenuZombieRiot_HUD_ACTION(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);	
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{	
				BuildMenuZombieRiot(param1);
			}
		}
		case MenuAction_Select:
		{
			char menu1[56];
			menu.GetItem(param2, menu1, sizeof(menu1));
			if(StrEqual(menu1, "M_hud_status"))
			{
				if(C_show_hud[param1])
				{
					C_show_hud[param1] = 0;
					BuildMenuZombieRiot_HUD(param1);
				}
				else
				{
					C_show_hud[param1] = 1;
					BuildMenuZombieRiot_HUD(param1);
				}
				
				if(IsClientAuthorized(param1))
				{
					Database db = Connect();
					if (db != null)
					{
						char steamId[64];
						GetClientAuthId(param1, AuthId_Steam2, steamId, sizeof(steamId));
						
						char strQuery[256];
						Format(strQuery, sizeof(strQuery), "SELECT hud FROM zr_client_prefs WHERE auth = '%s'", steamId);
						SQL_TQuery(db, SQLQuery_HUD, strQuery, GetClientUserId(param1), DBPrio_High);
					}
				}
			}	
		}
	}
}

/***********************************************************/
/***************** BUILD OVERLAYS MENU *********************/
/***********************************************************/
void BuildMenuZombieRiot_OVERLAYS(int client)
{
	char title[40]; 
	char overlay[40]; 
	char status[40];
	Menu menu = CreateMenu(BuildMenuZombieRiot_OVERLAYS_ACTION);
	SetMenuExitBackButton(menu, true);

	Format(status, sizeof(status), "%T", (C_show_overlays[client]) ? "Enabled" : "Disabled", client);
	
	Format(overlay, sizeof(overlay), "%T", "OVERLAYS_STATUS_MENU_TITLE", client, status);
	AddMenuItem(menu, "M_overlays_status", overlay);
	
	Format(title, sizeof(title), "%T", "OVERLAYS_TITLE", client);
	menu.SetTitle(title);
	menu.Display(client, MENU_TIME_FOREVER);
}

/***********************************************************/
/**************** OVERLAYS MENU ACTIONS ********************/
/***********************************************************/
public int BuildMenuZombieRiot_OVERLAYS_ACTION(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);	
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{	
				BuildMenuZombieRiot(param1);
			}
		}
		case MenuAction_Select:
		{
			char menu1[56];
			menu.GetItem(param2, menu1, sizeof(menu1));
			if(StrEqual(menu1, "M_overlays_status"))
			{
				if(C_show_overlays[param1])
				{
					C_show_overlays[param1] = 0;
					BuildMenuZombieRiot_OVERLAYS(param1);
				}
				else
				{
					C_show_overlays[param1] = 1;
					BuildMenuZombieRiot_OVERLAYS(param1);
				}
				
				if(IsClientAuthorized(param1))
				{
					Database db = Connect();
					if (db != null)
					{
						char steamId[64];
						GetClientAuthId(param1, AuthId_Steam2, steamId, sizeof(steamId));
						
						char strQuery[256];
						Format(strQuery, sizeof(strQuery), "SELECT overlays FROM zr_client_prefs WHERE auth = '%s'", steamId);
						SQL_TQuery(db, SQLQuery_OVERLAYS, strQuery, GetClientUserId(param1), DBPrio_High);
					}
				}
			}	
		}
	}
}

/***********************************************************/
/****************** BUILD ZVISION MENU *********************/
/***********************************************************/
void BuildMenuZombieRiot_ZVISION(int client)
{
	char title[40]; 
	char zvision[40]; 
	char status[40];
	Menu menu = CreateMenu(BuildMenuZombieRiot_ZVISION_ACTION);
	SetMenuExitBackButton(menu, true);

	Format(status, sizeof(status), "%T", (C_show_zvision[client]) ? "Enabled" : "Disabled", client);
	
	Format(zvision, sizeof(zvision), "%T", "ZVISION_STATUS_MENU_TITLE", client, status);
	AddMenuItem(menu, "M_zvision_status", zvision);
	
	Format(title, sizeof(title), "%T", "ZVISION_TITLE", client);
	menu.SetTitle(title);
	menu.Display(client, MENU_TIME_FOREVER);
}

/***********************************************************/
/***************** ZVISION MENU ACTIONS ********************/
/***********************************************************/
public int BuildMenuZombieRiot_ZVISION_ACTION(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);	
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{	
				BuildMenuZombieRiot(param1);
			}
		}
		case MenuAction_Select:
		{
			char menu1[56];
			menu.GetItem(param2, menu1, sizeof(menu1));
			if(StrEqual(menu1, "M_zvision_status"))
			{
				if(C_show_zvision[param1])
				{
					C_show_zvision[param1] = 0;
					StopZVision(param1);
					BuildMenuZombieRiot_ZVISION(param1);
				}
				else
				{
					C_show_zvision[param1] = 1;
					StartZVision(param1);
					BuildMenuZombieRiot_ZVISION(param1);
				}
				
				if(IsClientAuthorized(param1))
				{
					Database db = Connect();
					if (db != null)
					{
						char steamId[64];
						GetClientAuthId(param1, AuthId_Steam2, steamId, sizeof(steamId));
						
						char strQuery[256];
						Format(strQuery, sizeof(strQuery), "SELECT zvision FROM zr_client_prefs WHERE auth = '%s'", steamId);
						SQL_TQuery(db, SQLQuery_ZVISION, strQuery, GetClientUserId(param1), DBPrio_High);
					}
				}
			}	
		}
	}
}

/***********************************************************/
/****************** BUILD SOUNDS MENU **********************/
/***********************************************************/
void BuildMenuZombieRiot_SOUNDS(int client)
{
	char title[40]; 
	char sound[40]; 
	char status[40];
	Menu menu = CreateMenu(BuildMenuZombieRiot_SOUNDS_ACTION);
	SetMenuExitBackButton(menu, true);

	Format(status, sizeof(status), "%T", (C_play_sound[client]) ? "Enabled" : "Disabled", client);
	
	Format(sound, sizeof(sound), "%T", "SOUNDS_STATUS_MENU_TITLE", client, status);
	AddMenuItem(menu, "M_sounds_status", sound);
	
	Format(title, sizeof(title), "%T", "SOUNDS_TITLE", client);
	menu.SetTitle(title);
	menu.Display(client, MENU_TIME_FOREVER);
}

/***********************************************************/
/***************** SOUNDS MENU ACTIONS *********************/
/***********************************************************/
public int BuildMenuZombieRiot_SOUNDS_ACTION(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);	
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{	
				BuildMenuZombieRiot(param1);
			}
		}
		case MenuAction_Select:
		{
			char menu1[56];
			menu.GetItem(param2, menu1, sizeof(menu1));
			if(StrEqual(menu1, "M_sounds_status"))
			{
				if(C_play_sound[param1])
				{
					C_play_sound[param1] = 0;
					StopPlayAmbientSound(param1);
					BuildMenuZombieRiot_SOUNDS(param1);
				}
				else
				{
					C_play_sound[param1] = 1;
					StartPlayAmbientSound(param1);
					BuildMenuZombieRiot_SOUNDS(param1);
				}
				
				if(IsClientAuthorized(param1))
				{
					Database db = Connect();
					if (db != null)
					{
						char steamId[64];
						GetClientAuthId(param1, AuthId_Steam2, steamId, sizeof(steamId));
						
						char strQuery[256];
						Format(strQuery, sizeof(strQuery), "SELECT sounds FROM zr_client_prefs WHERE auth = '%s'", steamId);
						SQL_TQuery(db, SQLQuery_SOUNDS, strQuery, GetClientUserId(param1), DBPrio_High);
					}
				}
			}	
		}
	}
}