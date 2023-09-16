/*    <DR.API ZOMBIE RIOT> (c) by <De Battista Clint - (http://doyou.watch)  */
/*                                                                           */
/*                  <DR.API ZOMBIE RIOT> is licensed under a                 */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//***************************DR.API ZOMBIE RIOT CVARS************************//
//***************************************************************************//
//***************************************************************************//

/***********************************************************/
/********************** CREATE CVARS ***********************/
/***********************************************************/
void CreateCvars()
{	
	AutoExecConfig_CreateConVar("z4e_zombie_riot_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_zombie_riot               				=    AutoExecConfig_CreateConVar("zombie_riot", 						"1", 										"Enable/Disable Zombie Riot");
	cvar_active_zombie_riot_dev                			=    AutoExecConfig_CreateConVar("zombie_riot_dev", 					"0", 										"Enable/Disable dev mod");
	
	cvar_zombie_riot_hostname                			=    AutoExecConfig_CreateConVar("zombie_riot_hostname", 				"ZOMBIE RIOT {BETA} ZOMBIE4VER.EU", 		"Server name");
		
	cvar_zombie_riot_remove_objectives           		=    AutoExecConfig_CreateConVar("zombie_riot_remove_objectives", 		"1", 										"Enable/Disable HostageZone/BombZone/C4");
	cvar_zombie_riot_remove_buyzone           			=    AutoExecConfig_CreateConVar("zombie_riot_remove_buyzone", 			"1", 										"Enable/Disable BuyZone");
	
	cvar_zombie_riot_respawn_time           			=    AutoExecConfig_CreateConVar("zombie_riot_respawn_time", 			"10", 										"Respawn time");
	cvar_zombie_riot_cash           					=    AutoExecConfig_CreateConVar("zombie_riot_cash", 					"0", 										"Amount cash for CT");
	cvar_zombie_riot_freeze_time_zombies           		=    AutoExecConfig_CreateConVar("zombie_riot_freeze_time_zombies", 	"20", 										"Freeze time zombies");
	cvar_zombie_riot_remove_radgoll           			=    AutoExecConfig_CreateConVar("zombie_zombie_riot_remove_radgoll", 	"20.0", 									"Timer Remove deadbodies");
	cvar_zombie_riot_hud           						=    AutoExecConfig_CreateConVar("zombie_riot_hud", 					"1", 										"Display HUD with usefull informations");
	cvar_zombie_riot_hud_targeting           			=    AutoExecConfig_CreateConVar("zombie_riot_hud_targeting", 			"1", 										"Display HUD with extra informations");
	cvar_zombie_riot_collision           				=    AutoExecConfig_CreateConVar("zombie_riot_collision", 				"1", 										"Enable = 0/Disable = 1 collision players");
	cvar_zombie_riot_overlays           				=    AutoExecConfig_CreateConVar("zombie_riot_overlays", 				"1", 										"Enable/Disable overlays when players win");
	cvar_zombie_riot_zvision           					=    AutoExecConfig_CreateConVar("zombie_riot_zvision", 				"0.2", 										"Frequency, in seconds, to display zvision on the zombies' screen (Never go below 0.1, 0.2 seems safe");
	cvar_zombie_riot_sounds           					=    AutoExecConfig_CreateConVar("zombie_riot_sounds", 					"1", 										"Enable/Disable sounds");
	
	/*VALVE UPDATE USELESS
	cvar_zombie_riot_ammo_338mag_max					=    AutoExecConfig_CreateConVar("zombie_riot_ammo_338mag_max", 		"80", 										"Awp ammo");
	cvar_zombie_riot_ammo_357sig_max					=    AutoExecConfig_CreateConVar("zombie_riot_ammo_357sig_max", 		"240", 										"CZ75 auto ammo");
	cvar_zombie_riot_ammo_45acp_max						=    AutoExecConfig_CreateConVar("zombie_riot_ammo_45acp_max", 			"180", 										"Ump45, mac10, usp ammo");
	cvar_zombie_riot_ammo_50AE_max						=    AutoExecConfig_CreateConVar("zombie_riot_ammo_50AE_max", 			"120", 										"Deagle ammo");
	cvar_zombie_riot_ammo_556mm_box_max					=    AutoExecConfig_CreateConVar("zombie_riot_ammo_556mm_box_max", 		"240", 										"M249, Negev ammo");
	cvar_zombie_riot_ammo_556mm_max						=    AutoExecConfig_CreateConVar("zombie_riot_ammo_556mm_max", 			"100", 										"Galil, sg552, famas, m4a1, sg550 ammo");
	cvar_zombie_riot_ammo_57mm_max						=    AutoExecConfig_CreateConVar("zombie_riot_ammo_57mm_max", 			"115", 										"P90, fiveseven ammo");
	cvar_zombie_riot_ammo_762mm_max						=    AutoExecConfig_CreateConVar("zombie_riot_ammo_762mm_max", 			"145", 										"Scout, ak47, g3sg1, aug ammo");
	cvar_zombie_riot_ammo_9mm_max						=    AutoExecConfig_CreateConVar("zombie_riot_ammo_9mm_max", 			"150", 										"Mp5navy, tmp, glock, elite ammo");
	cvar_zombie_riot_ammo_buckshot_max					=    AutoExecConfig_CreateConVar("zombie_riot_ammo_buckshot_max", 		"135", 										"m3, xm1014 ammo");
	cvar_zombie_riot_ammo_357sig_small_max				=    AutoExecConfig_CreateConVar("zombie_riot_ammo_357sig_small_max", 	"135", 										"USP-S ammo");
	cvar_zombie_riot_ammo_556mm_small_max				=    AutoExecConfig_CreateConVar("zombie_riot_ammo_556mm_small_max", 	"135", 										"M4A1-S ammo");
	cvar_zombie_riot_ammo_357sig_p250_max				=    AutoExecConfig_CreateConVar("zombie_riot_ammo_357sig_p250_max", 	"135", 										"P250 ammo");
	*/
	
	HookConVarChangeEx();
	GetCvarsValveEx();
}

/***********************************************************/
/*********************** GET CVARS *************************/
/***********************************************************/
void GetCvarsValveEx()
{
	//mp_tagging_scale = block players when they are shooted
	mp_autoteambalance 							= FindConVar("mp_autoteambalance");
	mp_limitteams 								= FindConVar("mp_limitteams");
	mp_freezetime 								= FindConVar("mp_freezetime");
	mp_timelimit								= FindConVar("mp_timelimit");
	mp_roundtime								= FindConVar("mp_roundtime");
	mp_maxrounds								= FindConVar("mp_maxrounds");
	mp_ignore_round_win_conditions				= FindConVar("mp_ignore_round_win_conditions");
	sv_turbophysics								= FindConVar("sv_turbophysics");
	phys_pushscale								= FindConVar("phys_pushscale");
	mp_humanteam								= FindConVar("mp_humanteam");
	bot_join_team								= FindConVar("bot_join_team");
	bot_chatter									= FindConVar("bot_chatter");
	mp_ct_default_melee							= FindConVar("mp_ct_default_melee");
	mp_ct_default_secondary						= FindConVar("mp_ct_default_secondary");
	mp_ct_default_primary						= FindConVar("mp_ct_default_primary");
	mp_t_default_melee							= FindConVar("mp_t_default_melee");
	mp_t_default_secondary						= FindConVar("mp_t_default_secondary");
	mp_t_default_primary						= FindConVar("mp_t_default_primary");
	mp_weapons_glow_on_ground					= FindConVar("mp_weapons_glow_on_ground");
	sv_ignoregrenaderadio						= FindConVar("sv_ignoregrenaderadio");
	
	/*VALVE UPDATE USELESS
	ammo_338mag_max 							= FindConVar("ammo_338mag_max");
	ammo_357sig_max								= FindConVar("ammo_357sig_max");
	ammo_45acp_max								= FindConVar("ammo_45acp_max");
	ammo_50AE_max								= FindConVar("ammo_50AE_max");
	ammo_556mm_box_max							= FindConVar("ammo_556mm_box_max");
	ammo_556mm_max								= FindConVar("ammo_556mm_max");
	ammo_57mm_max								= FindConVar("ammo_57mm_max");
	ammo_762mm_max								= FindConVar("ammo_762mm_max");
	ammo_9mm_max								= FindConVar("ammo_9mm_max");
	ammo_buckshot_max							= FindConVar("ammo_buckshot_max");
	ammo_357sig_small_max						= FindConVar("ammo_357sig_small_max");
	ammo_556mm_small_max						= FindConVar("ammo_556mm_small_max");
	ammo_357sig_p250_max						= FindConVar("ammo_357sig_p250_max");
	*/
	
	backup_mp_autoteambalance  					= GetConVarBool(mp_autoteambalance);
	backup_mp_limitteams  						= GetConVarInt(mp_limitteams);
	backup_mp_freezetime 						= GetConVarInt(mp_freezetime);
	backup_mp_timelimit 						= GetConVarInt(mp_timelimit);
	backup_mp_roundtime 						= GetConVarInt(mp_roundtime);
	backup_mp_maxrounds 						= GetConVarInt(mp_maxrounds);
	backup_mp_ignore_round_win_conditions 		= GetConVarInt(mp_ignore_round_win_conditions);
	backup_sv_turbophysics 						= GetConVarInt(sv_turbophysics);
	backup_phys_pushscale 						= GetConVarInt(phys_pushscale);
	backup_mp_weapons_glow_on_ground			= GetConVarInt(mp_weapons_glow_on_ground);
	backup_sv_ignoregrenaderadio				= GetConVarInt(sv_ignoregrenaderadio);
	
	GetConVarString(mp_humanteam, 				backup_mp_humanteam, 				sizeof(backup_mp_humanteam));
	GetConVarString(bot_join_team, 				backup_bot_join_team, 				sizeof(backup_bot_join_team));
	GetConVarString(bot_chatter, 				backup_bot_chatter, 				sizeof(backup_bot_chatter));
	GetConVarString(mp_ct_default_melee, 		backup_mp_ct_default_melee, 		sizeof(backup_mp_ct_default_melee));
	GetConVarString(mp_ct_default_melee, 		backup_mp_ct_default_melee, 		sizeof(backup_mp_ct_default_melee));
	GetConVarString(mp_ct_default_secondary, 	backup_mp_ct_default_secondary, 	sizeof(backup_mp_ct_default_secondary));
	GetConVarString(mp_ct_default_primary, 		backup_mp_ct_default_primary, 		sizeof(backup_mp_ct_default_primary));
	GetConVarString(mp_t_default_melee, 		backup_mp_t_default_melee, 			sizeof(backup_mp_t_default_melee));
	GetConVarString(mp_t_default_secondary, 	backup_mp_t_default_secondary, 		sizeof(backup_mp_t_default_secondary));
	GetConVarString(mp_t_default_primary, 		backup_mp_t_default_primary, 		sizeof(backup_mp_t_default_primary));

	/*VALVE UPDATE USELESS
	backup_ammo_338mag_max 						= GetConVarInt(ammo_338mag_max);
	backup_ammo_357sig_max						= GetConVarInt(ammo_357sig_max);
	backup_ammo_45acp_max						= GetConVarInt(ammo_45acp_max);
	backup_ammo_50AE_max						= GetConVarInt(ammo_50AE_max);
	backup_ammo_556mm_box_max					= GetConVarInt(ammo_556mm_box_max);
	backup_ammo_556mm_max						= GetConVarInt(ammo_556mm_max);
	backup_ammo_57mm_max						= GetConVarInt(ammo_57mm_max);
	backup_ammo_762mm_max						= GetConVarInt(ammo_762mm_max);
	backup_ammo_9mm_max							= GetConVarInt(ammo_9mm_max);
	backup_ammo_buckshot_max					= GetConVarInt(ammo_buckshot_max);
	backup_ammo_357sig_small_max				= GetConVarInt(ammo_357sig_small_max);
	backup_ammo_556mm_small_max					= GetConVarInt(ammo_556mm_small_max);
	backup_ammo_357sig_p250_max					= GetConVarInt(ammo_357sig_p250_max);
	*/
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookConVarChangeEx()
{
	HookConVarChange(cvar_active_zombie_riot, 							Event_CvarChange);
	HookConVarChange(cvar_active_zombie_riot_dev, 						Event_CvarChange);
	
	HookConVarChange(cvar_zombie_riot_hostname, 						Event_CvarChange);
	
	HookConVarChange(cvar_zombie_riot_remove_objectives, 				Event_CvarChange);
	HookConVarChange(cvar_zombie_riot_remove_buyzone, 					Event_CvarChange);
	
	HookConVarChange(cvar_zombie_riot_respawn_time, 					Event_CvarChange);
	HookConVarChange(cvar_zombie_riot_cash, 							Event_CvarChange);
	HookConVarChange(cvar_zombie_riot_freeze_time_zombies, 				Event_CvarChange);
	HookConVarChange(cvar_zombie_riot_remove_radgoll, 					Event_CvarChange);
	HookConVarChange(cvar_zombie_riot_hud, 								Event_CvarChange);
	HookConVarChange(cvar_zombie_riot_hud_targeting, 					Event_CvarChange);
	HookConVarChange(cvar_zombie_riot_collision, 						Event_CvarChange);
	HookConVarChange(cvar_zombie_riot_overlays, 						Event_CvarChange);
	HookConVarChange(cvar_zombie_riot_zvision, 							Event_CvarChange);
	HookConVarChange(cvar_zombie_riot_sounds, 							Event_CvarChange);
	
	/*VALVE UPDATE USELESS
	HookConVarChange(cvar_zombie_riot_ammo_338mag_max, 					Event_CvarChange);
	HookConVarChange(cvar_zombie_riot_ammo_338mag_max, 					Event_CvarChange);
	HookConVarChange(cvar_zombie_riot_ammo_357sig_max, 					Event_CvarChange);
	HookConVarChange(cvar_zombie_riot_ammo_45acp_max, 					Event_CvarChange);
	HookConVarChange(cvar_zombie_riot_ammo_50AE_max, 					Event_CvarChange);
	HookConVarChange(cvar_zombie_riot_ammo_556mm_box_max, 				Event_CvarChange);
	HookConVarChange(cvar_zombie_riot_ammo_556mm_max, 					Event_CvarChange);
	HookConVarChange(cvar_zombie_riot_ammo_57mm_max, 					Event_CvarChange);
	HookConVarChange(cvar_zombie_riot_ammo_762mm_max, 					Event_CvarChange);
	HookConVarChange(cvar_zombie_riot_ammo_9mm_max, 					Event_CvarChange);
	HookConVarChange(cvar_zombie_riot_ammo_buckshot_max, 				Event_CvarChange);
	HookConVarChange(cvar_zombie_riot_ammo_357sig_small_max, 			Event_CvarChange);
	HookConVarChange(cvar_zombie_riot_ammo_556mm_small_max, 			Event_CvarChange);
	HookConVarChange(cvar_zombie_riot_ammo_357sig_p250_max, 			Event_CvarChange);
	*/

}

/***********************************************************/
/******************** WHEN CVARS CHANGE ********************/
/***********************************************************/
public void Event_CvarChange(Handle cvar, const char[] oldValue, const char[] newValue)
{
	UpdateState();
}

/***********************************************************/
/*********************** UPDATE STATE **********************/
/***********************************************************/
void UpdateState()
{
	B_active_zombie_riot						= GetConVarBool(cvar_active_zombie_riot);
	B_active_zombie_riot_dev 					= GetConVarBool(cvar_active_zombie_riot_dev);
	
	GetConVarString(cvar_zombie_riot_hostname, S_zombie_riot_hostname, sizeof(S_zombie_riot_hostname));
	
	B_zombie_riot_remove_objectives 			= GetConVarBool(cvar_zombie_riot_remove_objectives);
	B_zombie_riot_remove_buyzone 				= GetConVarBool(cvar_zombie_riot_remove_buyzone);
	
	H_zombie_riot_respawn_time 					= GetConVarInt(cvar_zombie_riot_respawn_time);
	H_zombie_riot_cash							= GetConVarInt(cvar_zombie_riot_cash);
	F_zombie_riot_freeze_time_zombies			= GetConVarFloat(cvar_zombie_riot_freeze_time_zombies);
	F_zombie_riot_remove_radgoll				= GetConVarFloat(cvar_zombie_riot_remove_radgoll);
	B_zombie_riot_hud							= GetConVarBool(cvar_zombie_riot_hud);
	B_zombie_riot_hud_targeting					= GetConVarBool(cvar_zombie_riot_hud_targeting);
	B_zombie_riot_collision						= GetConVarBool(cvar_zombie_riot_collision);
	B_zombie_riot_overlays						= GetConVarBool(cvar_zombie_riot_overlays);
	F_zombie_riot_zvision						= GetConVarFloat(cvar_zombie_riot_zvision);
	B_zombie_riot_sounds						= GetConVarBool(cvar_zombie_riot_sounds);
	
	/*VALVE UPDATE USELESS
	H_zombie_riot_ammo_338mag_max				= GetConVarInt(cvar_zombie_riot_ammo_338mag_max);
	H_zombie_riot_ammo_357sig_max				= GetConVarInt(cvar_zombie_riot_ammo_357sig_max);
	H_zombie_riot_ammo_45acp_max				= GetConVarInt(cvar_zombie_riot_ammo_45acp_max);
	H_zombie_riot_ammo_50AE_max					= GetConVarInt(cvar_zombie_riot_ammo_50AE_max);
	H_zombie_riot_ammo_556mm_box_max			= GetConVarInt(cvar_zombie_riot_ammo_556mm_box_max);
	H_zombie_riot_ammo_556mm_max				= GetConVarInt(cvar_zombie_riot_ammo_556mm_max);
	H_zombie_riot_ammo_57mm_max					= GetConVarInt(cvar_zombie_riot_ammo_57mm_max);
	H_zombie_riot_ammo_762mm_max				= GetConVarInt(cvar_zombie_riot_ammo_762mm_max);
	H_zombie_riot_ammo_9mm_max					= GetConVarInt(cvar_zombie_riot_ammo_9mm_max);
	H_zombie_riot_ammo_buckshot_max				= GetConVarInt(cvar_zombie_riot_ammo_buckshot_max);
	H_zombie_riot_ammo_357sig_small_max			= GetConVarInt(cvar_zombie_riot_ammo_357sig_small_max);
	H_zombie_riot_ammo_556mm_small_max			= GetConVarInt(cvar_zombie_riot_ammo_556mm_small_max);
	H_zombie_riot_ammo_357sig_p250_max			= GetConVarInt(cvar_zombie_riot_ammo_357sig_p250_max);
	*/
	
	if(B_active_zombie_riot)
	{
		ChangeCvarsValve();
		
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
		else
		{
			char status[10];
			status = (B_zombie_riot_remove_objectives) ? "Disable" : "Enable";
			SetObjectifMap(status);
		}
		
		/*Remove BuyZone */
		if(B_zombie_riot_remove_buyzone)
		{
			RemoveBuyZoneMap();
		}
	}
	else
	{
		RestoreCvarsValve();
	}

}

/***********************************************************/
/********************** SET CVARS VALVE ********************/
/***********************************************************/
void ChangeCvarsValve()
{
	//UpdateHostname("%s %s", S_zombie_riot_hostname, "[ARE YOU READY?]");
	
	SetConVarBool(mp_autoteambalance, 					false);
	SetConVarInt(mp_limitteams, 						0);
	SetConVarInt(mp_freezetime, 						0);
	SetConVarInt(mp_timelimit, 							800);
	SetConVarInt(mp_roundtime, 							1);
	SetConVarInt(mp_maxrounds, 							0);
	SetConVarInt(mp_ignore_round_win_conditions, 		1);
	SetConVarInt(sv_turbophysics, 						1);
	SetConVarInt(phys_pushscale, 						10);
	SetConVarString(mp_humanteam, 						"CT");
	SetConVarString(bot_join_team, 						"T");
	SetConVarString(bot_chatter, 						"off");
	//SetConVarString(mp_ct_default_melee, 				"weapon_knife");
	//SetConVarString(mp_ct_default_secondary, 			"weapon_deagle");
	//SetConVarString(mp_ct_default_primary, 				"");
	SetConVarString(mp_t_default_melee, 				"weapon_knife");
	SetConVarString(mp_t_default_secondary, 			"");
	SetConVarString(mp_t_default_primary, 				"");
	SetConVarInt(mp_weapons_glow_on_ground, 			1);
	SetConVarInt(sv_ignoregrenaderadio, 				1);
	
	/*VALVE UPDATE USELESS
	SetConVarInt(ammo_338mag_max,						H_zombie_riot_ammo_338mag_max);
	SetConVarInt(ammo_357sig_max,						H_zombie_riot_ammo_357sig_max);
	SetConVarInt(ammo_45acp_max,						H_zombie_riot_ammo_45acp_max);
	SetConVarInt(ammo_50AE_max,							H_zombie_riot_ammo_50AE_max);
	SetConVarInt(ammo_556mm_box_max,					H_zombie_riot_ammo_556mm_box_max);
	SetConVarInt(ammo_556mm_max,						H_zombie_riot_ammo_556mm_max);
	SetConVarInt(ammo_57mm_max,							H_zombie_riot_ammo_57mm_max);
	SetConVarInt(ammo_762mm_max,						H_zombie_riot_ammo_762mm_max);
	SetConVarInt(ammo_9mm_max,							H_zombie_riot_ammo_9mm_max);
	SetConVarInt(ammo_buckshot_max,						H_zombie_riot_ammo_buckshot_max);
	SetConVarInt(ammo_357sig_small_max,					H_zombie_riot_ammo_357sig_small_max);
	SetConVarInt(ammo_556mm_small_max,					H_zombie_riot_ammo_556mm_small_max);
	SetConVarInt(ammo_357sig_p250_max,					H_zombie_riot_ammo_357sig_p250_max);
	*/
}

/***********************************************************/
/******************** RESTORE CVARS VALVE ******************/
/***********************************************************/
void RestoreCvarsValve()
{
	SetConVarInt(mp_autoteambalance, 					backup_mp_autoteambalance);
	SetConVarInt(mp_limitteams, 						backup_mp_limitteams);
	SetConVarInt(mp_freezetime, 						backup_mp_freezetime);
	SetConVarInt(mp_timelimit, 							backup_mp_timelimit);
	SetConVarInt(mp_roundtime, 							backup_mp_roundtime);
	SetConVarInt(mp_maxrounds, 							backup_mp_maxrounds);
	SetConVarInt(mp_ignore_round_win_conditions, 		backup_mp_ignore_round_win_conditions);
	SetConVarInt(sv_turbophysics, 						backup_sv_turbophysics);
	SetConVarInt(phys_pushscale, 						backup_phys_pushscale);
	SetConVarString(mp_humanteam, 						backup_mp_humanteam);
	SetConVarString(bot_join_team, 						backup_bot_join_team);
	SetConVarString(bot_chatter, 						backup_bot_chatter);
	SetConVarString(mp_ct_default_melee, 				backup_mp_ct_default_melee);
	SetConVarString(mp_ct_default_secondary, 			backup_mp_ct_default_secondary);
	SetConVarString(mp_ct_default_primary, 				backup_mp_ct_default_primary);
	SetConVarString(mp_t_default_melee, 				backup_mp_t_default_melee);
	SetConVarString(mp_t_default_secondary, 			backup_mp_t_default_secondary);
	SetConVarString(mp_t_default_primary, 				backup_mp_t_default_primary);
	SetConVarInt(mp_weapons_glow_on_ground, 			backup_mp_weapons_glow_on_ground);
	SetConVarInt(sv_ignoregrenaderadio, 				backup_sv_ignoregrenaderadio);
	
	/*VALVE UPDATE USELESS
	SetConVarInt(ammo_338mag_max,						backup_ammo_338mag_max);
	SetConVarInt(ammo_357sig_max,						backup_ammo_357sig_max);
	SetConVarInt(ammo_45acp_max,						backup_ammo_45acp_max);
	SetConVarInt(ammo_50AE_max,							backup_ammo_50AE_max);
	SetConVarInt(ammo_556mm_box_max,					backup_ammo_556mm_box_max);
	SetConVarInt(ammo_556mm_max,						backup_ammo_556mm_max);
	SetConVarInt(ammo_57mm_max,							backup_ammo_57mm_max);
	SetConVarInt(ammo_762mm_max,						backup_ammo_762mm_max);
	SetConVarInt(ammo_9mm_max,							backup_ammo_9mm_max);
	SetConVarInt(ammo_buckshot_max,						backup_ammo_buckshot_max);
	SetConVarInt(ammo_357sig_small_max,					backup_ammo_357sig_small_max);
	SetConVarInt(ammo_556mm_small_max,					backup_ammo_556mm_small_max);
	SetConVarInt(ammo_357sig_p250_max,					backup_ammo_357sig_p250_max);
	*/
}