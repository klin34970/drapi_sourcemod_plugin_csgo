/*    <DR.API ZOMBIE RIOT> (c) by <De Battista Clint - (http://doyou.watch)  */
/*                                                                           */
/*                  <DR.API ZOMBIE RIOT> is licensed under a                 */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//*************************DR.API ZOMBIE RIOT VARIABLES**********************//
//***************************************************************************//
//***************************************************************************//


/***********************************************************/
/*********************** CREATE NATIVE *********************/
/***********************************************************/
void CreateNatives()
{
	CreateNative("ZRiot_IsClientZombie", Native_IsClientZombie);
	CreateNative("ZRiot_Zombie", Native_Zombie);
	CreateNative("ZRiot_Human", Native_Human);
	
	CreateNative("ZRiot_GetDay", Native_GetDay);
	CreateNative("ZRiot_GetDayMax", Native_GetDayMax);
	
	CreateNative("ZRiot_GetMenu", __Native_GetMenu);
	
	RegPluginLibrary("zombie_riot");
}

/***********************************************************/
/********************** CREATE FORWARDS ********************/
/***********************************************************/
void CreateForwards()
{
	hOnMenuZombieRiotReady 			= CreateGlobalForward("ZRiot_OnMenuReady", ET_Ignore, Param_Cell);
}

/***********************************************************/
/**************** NATIVE IS CLIENT ZOMBIE ******************/
/***********************************************************/
public int Native_IsClientZombie(Handle plugin, int args)
{
	int client = GetNativeCell(1);
	if (!client)
		ThrowNativeError(SP_ERROR_INDEX, "Client index %d is not in the game", client);

	return B_Player_Is_Zombie[GetNativeCell(1)];
}

/***********************************************************/
/***************** NATIVE BECOME ZOMBIE ********************/
/***********************************************************/
public int Native_Zombie(Handle plugin, int args)
{
	int client = GetNativeCell(1);
	if (!client)
		ThrowNativeError(SP_ERROR_INDEX, "Client index %d is not in the game", client);

	BecomeZombie(client);
}

/***********************************************************/
/****************** NATIVE BECOME HUMAN ********************/
/***********************************************************/
public int Native_Human(Handle plugin, int args)
{
	int client = GetNativeCell(1);
	if (!client)
		ThrowNativeError(SP_ERROR_INDEX, "Client index %d is not in the game", client);

	if (IsFakeClient(client))
		ThrowNativeError(SP_ERROR_INDEX, "Bots cannot be moved to the human team");

	BecomeHuman(client);
}

/***********************************************************/
/******************** NATIVE GET DAY ***********************/
/***********************************************************/
public int Native_GetDay(Handle plugin, int args)
{
    return INT_CURRENT_DAY + 1;
}

/***********************************************************/
/****************** NATIVE GET DAY MAX *********************/
/***********************************************************/
public int Native_GetDayMax(Handle plugin, int args)
{
    return INT_TOTAL_DAY;
}

/***********************************************************/
/****************** NATIVE GET DAY MAX *********************/
/***********************************************************/
public int __Native_GetMenu(Handle plugin, int args)
{
    return  view_as<int>(MenuZombieRiot);
}





/***********************************************************/
/*************** CREATE NATIVE COMMAND MENU ****************/
/***********************************************************/
void CreateNativeCommandMenu()
{
	RegConsoleCmd("sm_zrsettings",		Command_NativeMenuZombieRiot, 		"Native Zombie riot menu general");
}

/***********************************************************/
/****************** ACTION NATIVE MENU *********************/
/***********************************************************/
public Action Command_NativeMenuZombieRiot(int client, int args) 
{
	DisplayTopMenu(MenuZombieRiot, client, TopMenuPosition_Start);
}

/***********************************************************/
/******************* CREATE NATIVE MENU ********************/
/***********************************************************/
void CreateNativeMenu()
{
	MenuZombieRiot = new TopMenu(DefaultCategoryHandler);
	
	obj_menu_zombie_riot = AddToTopMenu(MenuZombieRiot, 
							"menu_zombie_riot",
							TopMenuObject_Category,
							DefaultCategoryHandler,
							INVALID_TOPMENUOBJECT);
							
	TopMenuObject menu = FindTopMenuCategory(MenuZombieRiot, "menu_zombie_riot_base");
	
	if (menu == INVALID_TOPMENUOBJECT)
	{
		menu = AddToTopMenu(
		MenuZombieRiot,				// Menu
		"menu_zombie_riot_base",	// Name
		TopMenuObject_Category,		// Type
		Handle_CategoryNative,		// Callback
		INVALID_TOPMENUOBJECT		// Parent
		);
	}
	
	AddToTopMenu(MenuZombieRiot, "sm_menu_zombie_riot_hud", 		TopMenuObject_Item, Menu_ZombieRiotHUD, 			menu, "sm_menu_zombie_riot_hud");
	AddToTopMenu(MenuZombieRiot, "sm_menu_zombie_riot_overlays", 	TopMenuObject_Item, Menu_ZombieRiotOVERLAYS, 		menu, "sm_menu_zombie_riot_overlays");
	AddToTopMenu(MenuZombieRiot, "sm_menu_zombie_riot_sounds", 		TopMenuObject_Item, Menu_ZombieRiotSOUNDS, 			menu, "sm_menu_zombie_riot_sounds");
	AddToTopMenu(MenuZombieRiot, "sm_menu_zombie_riot_zvision", 	TopMenuObject_Item, Menu_ZombieRiotZVISION, 		menu, "sm_menu_zombie_riot_zvision");
	
	Call_StartForward(hOnMenuZombieRiotReady);
	Call_PushCell(MenuZombieRiot);
	Call_Finish();
}

/***********************************************************/
/******************* HANDLE CATEGORY ***********************/
/***********************************************************/
public void Handle_CategoryNative(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayTitle:
			Format(buffer, maxlength, "%T", "MenuZombieRiot_TITLE_NATIVE_SUBMENU", param);
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "%T", "MenuZombieRiot_TITLE_NATIVE_SUBMENU", param);
	}
}

/***********************************************************/
/**************** DEFAULT CATEGORY HANDLER *****************/
/***********************************************************/
public void DefaultCategoryHandler(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayTitle)
	{
		if (object_id == INVALID_TOPMENUOBJECT)
		{
			Format(buffer, maxlength, "%T:", "MenuZombieRiot_TITLE_NATIVE", param);
		}
		else if (object_id == obj_menu_zombie_riot)
		{
			Format(buffer, maxlength, "%T", "MenuZombieRiot_TITLE_NATIVE", param);
		}
	}
	else if (action == TopMenuAction_DisplayOption)
	{
		if (object_id == obj_menu_zombie_riot)
		{
			Format(buffer, maxlength, "%T", "MenuZombieRiot_TITLE_NATIVE_SUBMENU", param);
		}
	}
}

/***********************************************************/
/********************** ON  MENU HUD ***********************/
/***********************************************************/
public void Menu_ZombieRiotHUD(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "%T", "MenuZombieRiot_HUD_MENU_TITLE", param);
		case TopMenuAction_SelectOption:
		{
			BuildMenuZombieRiot_HUD(param);
		}
	}
}

/***********************************************************/
/******************* ON  MENU OVERLAYS *********************/
/***********************************************************/
public void Menu_ZombieRiotOVERLAYS(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "%T", "MenuZombieRiot_OVERLAYS_MENU_TITLE", param);
		case TopMenuAction_SelectOption:
		{
			BuildMenuZombieRiot_OVERLAYS(param);
		}
	}
}

/***********************************************************/
/******************** ON  MENU SOUNDS **********************/
/***********************************************************/
public void Menu_ZombieRiotSOUNDS(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "%T", "MenuZombieRiot_SOUNDS_MENU_TITLE", param);
		case TopMenuAction_SelectOption:
		{
			BuildMenuZombieRiot_SOUNDS(param);
		}
	}
}

/***********************************************************/
/******************** ON  MENU ZVISION **********************/
/***********************************************************/
public void Menu_ZombieRiotZVISION(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "%T", "MenuZombieRiot_ZVISION_MENU_TITLE", param);
		case TopMenuAction_SelectOption:
		{
			BuildMenuZombieRiot_ZVISION(param);
		}
	}
}