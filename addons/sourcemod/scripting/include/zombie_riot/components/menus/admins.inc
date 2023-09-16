/*    <DR.API ZOMBIE RIOT> (c) by <De Battista Clint - (http://doyou.watch)  */
/*                                                                           */
/*                  <DR.API ZOMBIE RIOT> is licensed under a                 */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//****************************DR.API ZOMBIE RIOT SQL*************************//
//***************************************************************************//
//***************************************************************************//

/***********************************************************/
/***************** CREATE ADMINS COMMANDS ******************/
/***********************************************************/
void CreateAdminsCommands()
{
	RegAdminCmd("sm_zradmin",		Command_MenuAdminZombieRiot,	ADMFLAG_GENERIC,		"Zombie riot menu admin");
	RegAdminCmd("sm_setday", 		Command_SetDay, 				ADMFLAG_GENERIC, 		"Sets the game to a certain day");

	RegAdminCmd("sm_zombie", 		Command_Zombie,					ADMFLAG_GENERIC, 		"Turns player into zombie");
	RegAdminCmd("sm_human", 		Command_Human, 					ADMFLAG_GENERIC, 		"Turns player into human");
}

/************************************************************ CALL ADMIN MENU ************************************************************/
/***********************************************************/
/*************** ON ADMIN MENU CREATED *********************/
/***********************************************************/
public void OnAdminMenuCreated(Handle topmenu)
{
	if (topmenu == hAdminMenu && obj_admin_menu_zombie_riot != INVALID_TOPMENUOBJECT)
	{
		return;
	}

	obj_admin_menu_zombie_riot = AddToTopMenu(topmenu, "admin_menu_zombie_riot", TopMenuObject_Category, Handle_Category, INVALID_TOPMENUOBJECT);
}

/***********************************************************/
/******************* HANDLE CATEGORY ***********************/
/***********************************************************/
public void Handle_Category(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayTitle:
			Format(buffer, maxlength, "%T", "MenuAdminZombieRiot_TITLE", param);
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "%T", "MenuAdminZombieRiot_TITLE", param);
	}
}

/***********************************************************/
/***************** ON ADMIN MENU READY *********************/
/***********************************************************/
public void OnAdminMenuReady(Handle topmenu)
{

	if(obj_admin_menu_zombie_riot == INVALID_TOPMENUOBJECT)
	{
		OnAdminMenuCreated(topmenu);
	}
	
	if (topmenu == hAdminMenu)
	{
		return;
	}
	
	hAdminMenu = topmenu;
	
	TopMenuObject menu = FindTopMenuCategory(hAdminMenu, "admin_menu_zombie_riot");
	
	AddToTopMenu(hAdminMenu, "sm_zrhuman", 		TopMenuObject_Item, AdminMenu_ZombieRiotHuman, 		menu, "sm_zrhuman", 	ADMFLAG_GENERIC);
	AddToTopMenu(hAdminMenu, "sm_zrzombie", 	TopMenuObject_Item, AdminMenu_ZombieRiotZombie, 	menu, "sm_zrzombie", 	ADMFLAG_GENERIC);
}

/***********************************************************/
/**************** ON ADMIN MENU HUMANIFY *******************/
/***********************************************************/
public void AdminMenu_ZombieRiotHuman(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "%T", "MenuAdminZombieRiot_HUMANIFY_MENU_TITLE", param);
		case TopMenuAction_SelectOption:
		{
			BuildMenuAdminZombieRiot_HUMANIFY(param);
		}
	}
}

/***********************************************************/
/**************** ON ADMIN MENU ZOMBIFY ********************/
/***********************************************************/
public void AdminMenu_ZombieRiotZombie(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "%T", "MenuAdminZombieRiot_ZOMBIFY_MENU_TITLE", param);
		case TopMenuAction_SelectOption:
		{
			BuildMenuAdminZombieRiot_ZOMBIFY(param);
		}
	}
}

/****************************************************** CALL ZOMBIE RIOT ADMIN MENU ******************************************************/
/***********************************************************/
/************ COMMAND ZOMBIE RIOT MENU ADMIN ***************/
/***********************************************************/
public Action Command_MenuAdminZombieRiot(int client, int args) 
{
	BuildMenuAdminZombieRiot(client);
	return Plugin_Handled;
}

/***********************************************************/
/************* BUILD ZOMBIE RIOT MENU ADMIN ****************/
/***********************************************************/
void BuildMenuAdminZombieRiot(int client)
{
	char title[40]; 
	char humanify[40];
	char zombify[40];
	Menu menu = CreateMenu(MenuAdminZombieRiotAction);
	
	Format(humanify, sizeof(humanify), "%T", "MenuAdminZombieRiot_HUMANIFY_MENU_TITLE", client);
	AddMenuItem(menu, "M_humanify", humanify);
	
	Format(zombify, sizeof(zombify), "%T", "MenuAdminZombieRiot_ZOMBIFY_MENU_TITLE", client);
	AddMenuItem(menu, "M_zombify", zombify);
	
	
	Format(title, sizeof(title), "%T", "MenuAdminZombieRiot_TITLE", client);
	menu.SetTitle(title);
	SetMenuExitBackButton(menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
}

/***********************************************************/
/************ ZOMBIE RIOT MENU ADMIN ACTIONS ***************/
/***********************************************************/
public int MenuAdminZombieRiotAction(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);	
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
			}		
		}
		case MenuAction_Select:
		{
			char menu1[56];
			menu.GetItem(param2, menu1, sizeof(menu1));
			
			if(StrEqual(menu1, "M_humanify"))
			{
				BuildMenuAdminZombieRiot_HUMANIFY(param1);
			}
			else if(StrEqual(menu1, "M_zombify"))
			{
				BuildMenuAdminZombieRiot_ZOMBIFY(param1);
			}
		}
	}
}

/***********************************************************/
/*********** ZOMBIE RIOT MENU ADMIN HUMANIFY ***************/
/***********************************************************/
void BuildMenuAdminZombieRiot_HUMANIFY(int client)
{
	Menu menu = CreateMenu(BuildMenuAdminZombieRiot_HUMANIFY_ACTION);

	char title[100];

	Format(title, sizeof(title), "%T", "MenuAdminZombieRiot_HUMANIFY_MENU_TITLE", client);

	menu.SetTitle(title);
	menu.ExitBackButton = true;

	AddTargetsToMenu(menu, client, true, true);

	menu.Display(client, MENU_TIME_FOREVER);

}

/***********************************************************/
/******** ZOMBIE RIOT MENU ADMIN HUMANIFY ACTION ***********/
/***********************************************************/
public int BuildMenuAdminZombieRiot_HUMANIFY_ACTION(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			BuildMenuAdminZombieRiot(param1);
		}
	}
	else if (action == MenuAction_Select)
	{
		char info[32];
		int userid, target;
		menu.GetItem(param2, info, sizeof(info));
		userid = StringToInt(info);
		
		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "%t", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "%t", "Unable to target");
		}
		else
		{
			char name[32];
			GetClientName(target, name, sizeof(name));
			BecomeHuman(target);
			ChangeClientDeathCount(target, 0);
		}
		/* Re-draw the menu if they're still valid */
		if (Client_IsIngame(param1) && !IsClientInKickQueue(param1))
		{
			BuildMenuAdminZombieRiot_HUMANIFY(param1);
		}
	}
}

/***********************************************************/
/*********** ZOMBIE RIOT MENU ADMIN ZOMBIFY ****************/
/***********************************************************/
void BuildMenuAdminZombieRiot_ZOMBIFY(int client)
{
	Menu menu = CreateMenu(BuildMenuAdminZombieRiot_ZOMBIFY_ACTION);

	char title[100];

	Format(title, sizeof(title), "%T", "MenuAdminZombieRiot_ZOMBIFY_MENU_TITLE", client);

	menu.SetTitle(title);
	menu.ExitBackButton = true;

	AddTargetsToMenu(menu, client, true, true);

	menu.Display(client, MENU_TIME_FOREVER);

}

/***********************************************************/
/******** ZOMBIE RIOT MENU ADMIN ZOMBIFY ACTION ************/
/***********************************************************/
public int BuildMenuAdminZombieRiot_ZOMBIFY_ACTION(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			BuildMenuAdminZombieRiot(param1);
		}
	}
	else if (action == MenuAction_Select)
	{
		char info[32];
		int userid, target;
		menu.GetItem(param2, info, sizeof(info));
		userid = StringToInt(info);
		
		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "%t", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "%t", "Unable to target");
		}
		else
		{
			char name[32];
			GetClientName(target, name, sizeof(name));
			BecomeZombie(target);
		}
		/* Re-draw the menu if they're still valid */
		if (Client_IsIngame(param1) && !IsClientInKickQueue(param1))
		{
			BuildMenuAdminZombieRiot_ZOMBIFY(param1);
		}
	}
}

/********************************************************** COMMANDS ADMIN CHAT **********************************************************/
/***********************************************************/
/******************* COMMANDS SET DAY **********************/
/***********************************************************/
public Action Command_SetDay(int client, int args)
{
    if(args)
	{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		
		char name[32];
		GetClientName(client, name, sizeof(name));

		int day = StringToInt(arg1) - 1;
		day = (day >= 0) ? day : 0;

		INT_CURRENT_DAY = day;
		INT_CURRENT_DAY = (INT_CURRENT_DAY + 1 > INT_TOTAL_DAY) ? INT_TOTAL_DAY - 1 : INT_CURRENT_DAY;

		CPrintToChatAll("%t", "Admin skipday", name, INT_CURRENT_DAY + 1);

		if (H_Timer_HUD == INVALID_HANDLE)
		{
			return Plugin_Handled;
		}

		CS_TerminateRound(3.0, CSRoundEnd_Draw);
	}
    
    return Plugin_Handled;
}

/***********************************************************/
/******************** COMMANDS ZOMBIE **********************/
/***********************************************************/
public Action Command_Zombie(int client, int args)
{

	if(args)
	{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));

		char target_name[MAX_TARGET_LENGTH];
		int[] targets = new int[MAXPLAYERS];
		bool tn_is_ml;

		int tcount = ProcessTargetString(arg1, client, targets, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml);
		if (tcount <= 0)
		{
			ReplyToTargetError(client, tcount);
			return Plugin_Handled;
		}

		for (int i = 0; i < tcount; i++)
		{
			ClearHPBar(targets[i]);
			BecomeZombie(targets[i]);
		}

		if (INT_NB_HUMANS_BOTH_ALIVE <= 0)
		{
			CS_TerminateRound(5.0, CSRoundEnd_TerroristWin);
		}
	}

	return Plugin_Handled;
}

/***********************************************************/
/******************** COMMANDS HUMAN ***********************/
/***********************************************************/
public Action Command_Human(int client, int args)
{
	if(args)
	{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));

		char target_name[MAX_TARGET_LENGTH];
		int[] targets = new int[MAXPLAYERS];
		bool tn_is_ml;

		int tcount = ProcessTargetString(arg1, client, targets, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml);
		if (tcount <= 0)
		{
			ReplyToTargetError(client, tcount);
			return Plugin_Handled;
		}

		for (int i = 0; i < tcount; i++)
		{
			ClearHPBar(targets[i]);
			BecomeHuman(targets[i]);
		}
	}

	return Plugin_Handled;
}