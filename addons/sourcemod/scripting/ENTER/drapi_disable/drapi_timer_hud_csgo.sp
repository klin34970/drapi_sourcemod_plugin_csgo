#pragma semicolon 1
 
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>
#include <smlib>
#include <timer>
#include <timer-logging>
#include <timer-stocks>
#include <timer-config_loader>
 
#undef REQUIRE_PLUGIN
#include <timer-mapzones>
#include <timer-teams>
#include <timer-maptier>
#include <timer-rankings>
#include <timer-worldrecord>
#include <timer-physics>
#include <js_ljstats>
#include <drapi_timer_checkpoints>
 
#define THINK_INTERVAL					1.0
 
enum Hud
{
		Master,
		Main,
		Time,
		Speed,
		Mode,
		PB,
		Level,
		WRCP
}
 
/**
 * Global Variables
 */
new String:g_currentMap[64];
 
new Handle:g_cvarTimeLimit		= INVALID_HANDLE;
 
//module check
new bool:g_timerPhysics = false;
new bool:g_timerMapzones = false;
new bool:g_timerWorldRecord = false;
new bool:g_timerWorldRecordCheckpoints = false;
 
new bool:spec[MAXPLAYERS+1];
new bool:hidemyass[MAXPLAYERS+1];
 
new g_iButtonsPressed[MAXPLAYERS+1] = {0,...};
new g_iJumps[MAXPLAYERS+1] = {0,...};
new Handle:g_hDelayJump[MAXPLAYERS+1] = {INVALID_HANDLE,...};
 
new Handle:g_hThink_Map = INVALID_HANDLE;
new g_iMap_TimeLeft = 1200;
 
new bool:rankLoaded = false;
new playerRank[MAXPLAYERS+1];
new mapRankTotal = 0;
 
new Handle:cookieHudPref;
new Handle:cookieHudMainPref;
new Handle:cookieHudMainTimePref;
new Handle:cookieHudMainSpeedPref;
new Handle:cookieHudMainPBPref;
new Handle:cookieHudSideModePref;
new Handle:cookieHudSideLevelPref;
new Handle:cookieHudSideWRCPPref;
 
new hudSettings[Hud][MAXPLAYERS+1];
 
//Here we save the last touched zone.
new MapZoneType:lastStartTouched[MAXPLAYERS+1] = {ZtStart,...};
new bool:g_MapFinished[MAXPLAYERS+1] = {false,...};
new String:g_TimeString[MAXPLAYERS+1][32];
new String:g_PBString[MAXPLAYERS+1][32];
new String:g_BonusPBString[MAXPLAYERS+1][32];
new bool:g_ClientReady[MAXPLAYERS+1];
 
public Plugin:myinfo =
{
	name		= "[TIMER] HUD, DR. API modifications",
	author		= "Zipcore, Alongub",
	description = "[Timer] Player HUD with optional details to show and cookie support",
	version		= PL_VERSION,
	url			= "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnPluginStart()
{
		if(GetEngineVersion() != Engine_CSGO)
		{
				Timer_LogError("Don't use this plugin for other games than CS:GO.");
				SetFailState("Check timer error logs.");
				return;
		}
	   
		g_timerPhysics = LibraryExists("timer-physics");
		g_timerMapzones = LibraryExists("timer-mapzones");
		g_timerWorldRecord = LibraryExists("timer-worldrecord");
		g_timerWorldRecordCheckpoints = LibraryExists("timer-checkppoints");
	   
		LoadPhysics();
		LoadTimerSettings();
	   
		LoadTranslations("timer.phrases");
	   
		if(g_Settings[HUDMasterEnable])
		{
				HookEvent("player_jump", Event_PlayerJump);
			   
				HookEvent("player_death", Event_Reset);
				HookEvent("player_team", Event_Reset);
				HookEvent("player_spawn", Event_Reset);
				HookEvent("player_disconnect", Event_Reset);
			   
				RegConsoleCmd("sm_hidemyass", Cmd_HideMyAss);
				RegConsoleCmd("sm_hud", MenuHud);
				RegConsoleCmd("sm_specinfo", Cmd_SpecInfo);
			   
				g_cvarTimeLimit = FindConVar("mp_timelimit");
			   
				AutoExecConfig(true, "timer/timer-hud");
			   
				//cookies yummy :)
				cookieHudPref = RegClientCookie("timer_hud_master", "Turn on or off all hud components", CookieAccess_Private);
				cookieHudMainPref = RegClientCookie("timer_hud_main", "Turn on or off main hud components", CookieAccess_Private);
				cookieHudMainTimePref = RegClientCookie("timer_hud_main_time", "Turn on or off time component", CookieAccess_Private);
				cookieHudMainSpeedPref = RegClientCookie("timer_hud_speed", "Turn on or off speed component", CookieAccess_Private);
				cookieHudMainPBPref = RegClientCookie("timer_hud_pb", "Turn on or off PB on hud", CookieAccess_Private);
				cookieHudSideModePref = RegClientCookie("timer_hud_side_mode", "Turn on or off mode component", CookieAccess_Private);
				cookieHudSideLevelPref = RegClientCookie("timer_hud_side_level", "Turn on or off level component", CookieAccess_Private);
				cookieHudSideWRCPPref = RegClientCookie("timer_hud_side_wr_cp", "Turn on or off wr component", CookieAccess_Private);
		}
}
 
public OnLibraryAdded(const String:name[])
{
		if (StrEqual(name, "timer-physics"))
		{
				g_timerPhysics = true;
		}	   
		else if (StrEqual(name, "timer-mapzones"))
		{
				g_timerMapzones = true;
		}			   
		else if (StrEqual(name, "timer-worldrecord"))
		{
				g_timerWorldRecord = true;
		}
		else if (StrEqual(name, "timer-checkppoints"))
		{
				g_timerWorldRecordCheckpoints = true;
		}
}
 
public OnLibraryRemoved(const String:name[])
{	   
		if (StrEqual(name, "timer-physics"))
		{
				g_timerPhysics = false;
		}	   
		else if (StrEqual(name, "timer-mapzones"))
		{
				g_timerMapzones = false;
		}							   
		else if (StrEqual(name, "timer-worldrecord"))
		{
				g_timerWorldRecord = false;
		}
		else if (StrEqual(name, "timer-checkppoints"))
		{
				g_timerWorldRecordCheckpoints = false;
		}
}
 
public OnMapStart()
{
		for (new client = 1; client <= MaxClients; client++)
		{
				g_hDelayJump[client] = INVALID_HANDLE;
				playerRank[client] = 0;
				g_PBString[client][0] = '\0';
				g_BonusPBString[client][0] = '\0';
				g_ClientReady[client] = false;
		}
	   
		GetCurrentMap(g_currentMap, sizeof(g_currentMap));
	   
		if(GetEngineVersion() == Engine_CSGO)
		{
				CreateTimer(0.1, HUDTimer_CSGO, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		}
	   
		RestartMapTimer();
	   
		LoadPhysics();
		LoadTimerSettings();
}
 
public OnMapEnd()
{
		if(g_hThink_Map != INVALID_HANDLE)
		{
				CloseHandle(g_hThink_Map);
				g_hThink_Map = INVALID_HANDLE;
		}
}
 
public OnClientDisconnect(client)
{
		g_PBString[client][0] = '\0';
		g_BonusPBString[client][0] = '\0';
		g_ClientReady[client] = false; 
		g_iButtonsPressed[client] = 0;
		playerRank[client] = 0;
		if (g_hDelayJump[client] != INVALID_HANDLE)
		{
				CloseHandle(g_hDelayJump[client]);
				g_hDelayJump[client] = INVALID_HANDLE;
		}
}
 
public OnClientCookiesCached(client)
{
		// Initializations and preferences loading
		if(IsClientInGame(client) && !IsFakeClient(client))
		{
				loadClientCookiesFor(client);  
		}
}
 
loadClientCookiesFor(client)
{
		if(cookieHudPref == INVALID_HANDLE)
				return;
	   
		decl String:buffer[5];
	   
		//Master HUD
		GetClientCookie(client, cookieHudPref, buffer, 5);
		if(!StrEqual(buffer, ""))
		{
				hudSettings[Master][client] = StringToInt(buffer);
		}
 
		//Main HUD
		GetClientCookie(client, cookieHudMainPref, buffer, 5);
		if(!StrEqual(buffer, ""))
		{
				hudSettings[Main][client] = StringToInt(buffer);
		}
	   
		//Show Time?
		GetClientCookie(client, cookieHudMainTimePref, buffer, 5);
		if(!StrEqual(buffer, ""))
		{
				hudSettings[Time][client] = StringToInt(buffer);
		}
	   
		//Show Speed?
		GetClientCookie(client, cookieHudMainSpeedPref, buffer, 5);
		if(!StrEqual(buffer, ""))
		{
				hudSettings[Speed][client] = StringToInt(buffer);
		}
 
		//Show PB?
		GetClientCookie(client, cookieHudMainPBPref, buffer, 5);
		if(!StrEqual(buffer, ""))
		{
				hudSettings[PB][client] = StringToInt(buffer);
		}	   
	   
		//Show Side Mode?
		GetClientCookie(client, cookieHudSideModePref, buffer, 5);
		if(!StrEqual(buffer, ""))
		{
				hudSettings[Mode][client] = StringToInt(buffer);
		}
	   
		//Show Side Level?
		GetClientCookie(client, cookieHudSideLevelPref, buffer, 5);
		if(!StrEqual(buffer, ""))
		{
				hudSettings[Level][client] = StringToInt(buffer);
		}
		
		//Show Side Level?
		GetClientCookie(client, cookieHudSideWRCPPref, buffer, 5);
		if(!StrEqual(buffer, ""))
		{
				hudSettings[WRCP][client] = StringToInt(buffer);
		}
}
 
//	This selects or disables the Hud
public MenuHandlerHud(Handle:menu, MenuAction:action, client, itemNum)
{
		if ( action == MenuAction_Select )
		{
				decl String:info[100], String:info2[100];
				new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
				if(found)
				{
						if(StrEqual(info, "master"))
						{
								if (hudSettings[Master][client] == 0)
								{
										hudSettings[Master][client] = 1;
								}
								else if (hudSettings[Master][client] == 1)
								{
										hudSettings[Master][client] = 0;
								}
							   
								decl String:buffer[5];
								IntToString(hudSettings[Master][client], buffer, 5);
								SetClientCookie(client, cookieHudPref, buffer);		   
						}
					   
						if(StrEqual(info, "main"))
						{
								if (hudSettings[Main][client] == 0)
								{
										hudSettings[Main][client] = 1;
								}
								else if (hudSettings[Main][client] == 1)
								{
										hudSettings[Main][client] = 0;
								}
							   
								decl String:buffer[5];
								IntToString(hudSettings[Main][client], buffer, 5);
								SetClientCookie(client, cookieHudMainPref, buffer);			   
						}
					   
						if(StrEqual(info, "time"))
						{
								if (hudSettings[Time][client] == 0)
								{
										hudSettings[Time][client] = 1;
								}
								else if (hudSettings[Time][client] == 1)
								{
										hudSettings[Time][client] = 0;
								}
							   
								decl String:buffer[5];
								IntToString(hudSettings[Time][client], buffer, 5);
								SetClientCookie(client, cookieHudMainTimePref, buffer);		   
						}
					   
						if(StrEqual(info, "speed"))
						{
								if (hudSettings[Speed][client] == 0)
								{
										hudSettings[Speed][client] = 1;
								}
								else if (hudSettings[Speed][client] == 1)
								{
										hudSettings[Speed][client] = 0;
								}
							   
								decl String:buffer[5];
								IntToString(hudSettings[Speed][client], buffer, 5);
								SetClientCookie(client, cookieHudMainSpeedPref, buffer);			   
						}
 
						if(StrEqual(info, "pb"))
						{
								if (hudSettings[PB][client] == 0)
								{
										hudSettings[PB][client] = 1;
								}
								else if (hudSettings[PB][client] == 1)
								{
										hudSettings[PB][client] = 0;
								}
							   
								decl String:buffer[5];
								IntToString(hudSettings[PB][client], buffer, 5);
								SetClientCookie(client, cookieHudMainPBPref, buffer);		   
						}					   
					   
						if(StrEqual(info, "mode"))
						{
								if (hudSettings[Mode][client] == 0)
								{
										hudSettings[Mode][client] = 1;
								}
								else if (hudSettings[Mode][client] == 1)
								{
										hudSettings[Mode][client] = 0;
								}
							   
								decl String:buffer[5];
								IntToString(hudSettings[Mode][client], buffer, 5);
								SetClientCookie(client, cookieHudSideModePref, buffer);		   
						}
					   
						if(StrEqual(info, "level"))
						{
								if (hudSettings[Level][client] == 0)
								{
										hudSettings[Level][client] = 1;
								}
								else if (hudSettings[Level][client] == 1)
								{
										hudSettings[Level][client] = 0;
								}
							   
								decl String:buffer[5];
								IntToString(hudSettings[Level][client], buffer, 5);
								SetClientCookie(client, cookieHudSideLevelPref, buffer);			   
						}
						if(StrEqual(info, "wrcp"))
						{
								if (hudSettings[WRCP][client] == 0)
								{
										hudSettings[WRCP][client] = 1;
								}
								else if (hudSettings[WRCP][client] == 1)
								{
										hudSettings[WRCP][client] = 0;
								}
							   
								decl String:buffer[5];
								IntToString(hudSettings[WRCP][client], buffer, 5);
								SetClientCookie(client, cookieHudSideWRCPPref, buffer);			   
						}
						if(StrEqual(info, "wrcpchat"))
						{
								if (!Timer_GetActiveHud(client))
								{
										Timer_SetActiveHud(client, 1);
								}
								else if (Timer_GetActiveHud(client))
								{
										Timer_SetActiveHud(client, 0);
								}   
						}
				}
				if(IsClientInGame(client)) ShowHudMenu(client, GetMenuSelectionPosition());
		}
		else if(action == MenuAction_End)
		{
				CloseHandle(menu);
		}
}
 
//	This creates the Hud Menu
public Action:MenuHud(client, args)
{
		ShowHudMenu(client, 1);
		return Plugin_Handled;
}
 
ShowHudMenu(client, start_item)
{
		if(g_Settings[HUDMasterOnlyEnable] && g_Settings[HUDMasterEnable])
		{
				if(hudSettings[Master][client] == 1)
				{
						hudSettings[Master][client] = 0;
						CPrintToChat(client, "%s HUD disabled.", PLUGIN_PREFIX2);
				}
				else
				{
						hudSettings[Master][client] = 1;
						CPrintToChat(client, "%s HUD enabled.", PLUGIN_PREFIX2);
				}
		}
		else if(g_Settings[HUDMasterEnable])
		{
				new Handle:menu = CreateMenu(MenuHandlerHud);
				decl String:buffer[100];
			   
				FormatEx(buffer, sizeof(buffer), "Customize your HUD");
				SetMenuTitle(menu, buffer);
			   
				if(hudSettings[Master][client] == 0)
				{
						AddMenuItem(menu, "master", "Enable HUD Master Switch");	   
				}
				else
				{
						AddMenuItem(menu, "master", "Disable HUD Master Switch");	   
				}
			   
				if(g_Settings[HUDCenterEnable])
				{
						if(hudSettings[Main][client] == 0)
						{
								AddMenuItem(menu, "main", "Enable HUD");	   
						}
						else
						{
								AddMenuItem(menu, "main", "Disable HUD");	   
						}
				}
			   
				if(hudSettings[Time][client] == 0)
				{
						AddMenuItem(menu, "time", "View Time");
				}
				else
				{
						AddMenuItem(menu, "time", "Hide Time");
				}
	   
				if(g_Settings[HUDSpeedEnable])
				{
						if(hudSettings[Speed][client] == 0)
						{
								AddMenuItem(menu, "speed", "View Speed");	   
						}
						else
						{
								AddMenuItem(menu, "speed", "Hide Speed");	   
						}
				}
 
				if(g_Settings[HUDSpeedEnable])
				{
						if(hudSettings[PB][client] == 0)
						{
								AddMenuItem(menu, "pb", "View PB");	   
						}
						else
						{
								AddMenuItem(menu, "pb", "Hide PB");	   
						}
				}			   
			   
				if(g_Settings[HUDStyleEnable])
				{
						if(hudSettings[Mode][client] == 0)
						{
								AddMenuItem(menu, "mode", "View Style ");	   
						}
						else
						{
								AddMenuItem(menu, "mode", "Hide Style");	   
						}
				}
			   
				if(g_Settings[HUDLevelEnable])
				{
						if(hudSettings[Level][client] == 0)
						{
								AddMenuItem(menu, "level", "View Level");	   
						}
						else
						{
								AddMenuItem(menu, "level", "Hide Level");	   
						}
				}
				
				if(g_Settings[HUDWRCPEnable])
				{
						if(hudSettings[WRCP][client] == 0)
						{
								AddMenuItem(menu, "wrcp", "View HUD WR checkpoints");	   
						}
						else
						{
								AddMenuItem(menu, "wrcp", "Hide HUD WR checkpoints");	   
						}
						
						if(!Timer_GetActiveHud(client))
						{
								AddMenuItem(menu, "wrcpchat", "View Chat WR checkpoints");	   
						}
						else
						{
								AddMenuItem(menu, "wrcpchat", "Hide Chat WR checkpoints");	   
						}
				}
			   
				SetMenuExitButton(menu, true);
 
				DisplayMenuAtItem(menu, client, start_item, MENU_TIME_FOREVER );
		}
}
 
//End Custom Cookie and Menu Stuff
 
public Action:Cmd_HideMyAss(client, args)
{
		if(IsClientConnected(client) && IsClientInGame(client) && Client_IsAdmin(client))
		{
				if(hidemyass[client])
				{
						hidemyass[client] = false;
						PrintToChat(client, "Hide My Ass: Disabled.");
				}
				else
				{
						hidemyass[client] = true;
						PrintToChat(client, "Hide My Ass: Enabled.");
				}
		}
		return Plugin_Handled; 
}
 
public OnConfigsExecuted()
{
		if(g_cvarTimeLimit != INVALID_HANDLE) HookConVarChange(g_cvarTimeLimit, ConVarChange_TimeLimit);
}
 
public ConVarChange_TimeLimit(Handle:cvar, const String:oldVal[], const String:newVal[])
{
		RestartMapTimer();
}
 
stock RestartMapTimer()
{
		//Map Timer
		if(g_hThink_Map != INVALID_HANDLE)
		{
				CloseHandle(g_hThink_Map);
				g_hThink_Map = INVALID_HANDLE;
		}
	   
		new bool:gotTimeLeft = GetMapTimeLeft(g_iMap_TimeLeft);
	   
		if(gotTimeLeft && g_iMap_TimeLeft > 0)
		{
				g_hThink_Map = CreateTimer(THINK_INTERVAL, Timer_Think_Map, INVALID_HANDLE, TIMER_REPEAT);
		}
}
 
public Action:Timer_Think_Map(Handle:timer)
{
		g_iMap_TimeLeft--;
		return Plugin_Continue;
}
 
public OnClientPutInServer(client)
{
		// Initializations and preferences loading
		if(!IsFakeClient(client))
		{
				hudSettings[Master][client] = 1;
				hudSettings[Main][client] = 1;
				hudSettings[Time][client] = 1;
				hudSettings[Speed][client] = 1;
				hudSettings[Mode][client] = 1;
				hudSettings[Level][client] = 1;
				hudSettings[PB][client] = 1;
				hudSettings[WRCP][client] = 1;
			   
				if (AreClientCookiesCached(client))
				{
						loadClientCookiesFor(client);
				}
				lastStartTouched[client] = MapZoneType:ZtStart;		   
		}
	   
		if(g_hThink_Map == INVALID_HANDLE && IsServerProcessing())
		{
				RestartMapTimer();
		}
}
 
/*
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
		g_iButtonsPressed[client] = buttons;
}
*/
 
public Action:Event_PlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
 
		g_iJumps[client]++;
		g_hDelayJump[client] = CreateTimer(0.3, Timer_DelayJumpHud, client, TIMER_FLAG_NO_MAPCHANGE);
	   
		return Plugin_Continue;
}
 
//extends display time of jump keys
public Action:Timer_DelayJumpHud(Handle:timer, any:client)
{
		g_hDelayJump[client] = INVALID_HANDLE;
		return Plugin_Stop;
}
 
public Action:Event_Reset(Handle:event, const String:name[], bool:dontBroadcast)
{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
	   
		g_iJumps[client] = 0;
	   
		if (g_hDelayJump[client] != INVALID_HANDLE)
		{
				CloseHandle(g_hDelayJump[client]);
				g_hDelayJump[client] = INVALID_HANDLE;
		}
		return Plugin_Continue;
}
 
public Action:HUDTimer_CSGO(Handle:timer)
{
		for (new client = 1; client <= MaxClients; client++)
		{
				spec[client] = false;
		}
	   
		for (new client = 1; client <= MaxClients; client++)
		{
				if (!IsClientInGame(client))
						continue;
			   
				if(hidemyass[client])
						continue;
			   
				// Get target he's spectating
				if(!IsPlayerAlive(client) || IsClientObserver(client))
				{
						new iObserverMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
						if(iObserverMode == SPECMODE_FIRSTPERSON || iObserverMode == SPECMODE_3RDPERSON)
						{
								new clienttoshow = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
								if(clienttoshow > 0)
								{
										spec[clienttoshow] = true;
								}
						}
				}
		}
	   
		for (new client = 1; client <= MaxClients; client++)
		{
				if (IsClientInGame(client))
				{
						UpdateHUD_CSGO(client);
				}
					   
		}
 
		return Plugin_Continue;
}
 
UpdateHUD_Bot(client, hudClient)
{
		new String:centerText[512];
		new Float:fspeed;
		new speed;
 
		Timer_GetCurrentSpeed(client, fspeed);
		speed = RoundToNearest(fspeed);
 
		new style = Timer_GetStyle(client);	   
		new track = Timer_GetTrack(client);	   
 
		new bool:enabled;
		new jumps;
		new fpsmax;
		new Float:time; //current time
 
		new RecordId;
		new Float:RecordTime;
		new RankTotal;
 
		new stagecount;
	   
		if(track == TRACK_BONUS)
		{
				stagecount = Timer_GetMapzoneCount(ZtBonusLevel)+1;
		}
		else if(track == TRACK_BONUS2)
		{
				stagecount = Timer_GetMapzoneCount(ZtBonus2Level)+Timer_GetMapzoneCount(ZtBonus2Checkpoint)+1;
		}
		else if(track == TRACK_BONUS3)
		{
				stagecount = Timer_GetMapzoneCount(ZtBonus3Level)+Timer_GetMapzoneCount(ZtBonus3Checkpoint)+1;
		}
		else if(track == TRACK_BONUS4)
		{
				stagecount = Timer_GetMapzoneCount(ZtBonus4Level)+Timer_GetMapzoneCount(ZtBonus4Checkpoint)+1;
		}
		else if(track == TRACK_BONUS5)
		{
				stagecount = Timer_GetMapzoneCount(ZtBonus5Level)+Timer_GetMapzoneCount(ZtBonus5Checkpoint)+1;
		}
		else
		{
				stagecount = Timer_GetMapzoneCount(ZtLevel)+1;
		}
 
		new currentLevel = Timer_GetClientLevelID(client);
		if(currentLevel < 1) currentLevel = 1;
 
		if(currentLevel > 1000) currentLevel -= 1000;
		if(currentLevel == 999) currentLevel = stagecount;
	   
		Timer_GetClientTimer(client, enabled, time, jumps, fpsmax);
		Timer_GetStyleRecordWRStats(style, track, RecordId, RecordTime, RankTotal);
 
		decl String:mapInfoString[128];
 
		decl String:timeString[64];
		Timer_SecondsToTime(time, timeString, sizeof(timeString), 2);
 
		decl String:wrTimeString[64];
		Timer_SecondsToTime(RecordTime, wrTimeString, sizeof(wrTimeString), 2);
 
		timeString[7] = '0';
 
		new bool:inStartZone = false;
		if(Timer_IsPlayerTouchingZoneType(client, ZtStart))
		{
				Format(mapInfoString, sizeof(mapInfoString), "Map Start");
				inStartZone = true;
		}
		else if(Timer_IsPlayerTouchingZoneType(client, ZtBonusStart))
		{
				Format(mapInfoString, sizeof(mapInfoString), "Bonus 1 Start");
				inStartZone = true;
		}
		else if(Timer_IsPlayerTouchingZoneType(client, ZtBonus2Start))
		{
				Format(mapInfoString, sizeof(mapInfoString), "Bonus 2 Start");
				inStartZone = true;
		}
		else if(Timer_IsPlayerTouchingZoneType(client, ZtBonus3Start))
		{
				Format(mapInfoString, sizeof(mapInfoString), "Bonus 3 Start");
				inStartZone = true;
		}
		else if(Timer_IsPlayerTouchingZoneType(client, ZtBonus4Start))
		{
				Format(mapInfoString, sizeof(mapInfoString), "Bonus 4 Start");
				inStartZone = true;
		}
		else if(Timer_IsPlayerTouchingZoneType(client, ZtBonus5Start))
		{
				Format(mapInfoString, sizeof(mapInfoString), "Bonus 5 Start");
				inStartZone = true;
		}
	   
		if(!inStartZone)
		{
				switch(lastStartTouched[client])
				{
						case ZtStart:
						{
								if(stagecount <= 1)
								{
										Format(mapInfoString, sizeof(mapInfoString), "Linear Map");
								}
								else
								{
										Format(mapInfoString, sizeof(mapInfoString), "Stage: %d / %d", currentLevel, stagecount);
								}
						}
						case ZtBonusStart: Format(mapInfoString, sizeof(mapInfoString), "Bonus 1");
						case ZtBonus2Start: Format(mapInfoString, sizeof(mapInfoString), "Bonus 2");
						case ZtBonus3Start: Format(mapInfoString, sizeof(mapInfoString), "Bonus 3");
						case ZtBonus4Start: Format(mapInfoString, sizeof(mapInfoString), "Bonus 4");
						case ZtBonus5Start: Format(mapInfoString, sizeof(mapInfoString), "Bonus 5");
				}
		}
 
		Format(centerText, sizeof(centerText), " <font size='17'>Replay [Normal]\n \
																						Time: <font color='#ffff00'>%s</font>	(WR: %s)\n \
																						%s			  Speed: <font color='#ff6633'>%d</font>", timeString, wrTimeString, mapInfoString, speed);
 
		PrintHintText(hudClient, centerText);
 
		return;
}
 
UpdateHUD_CSGO(client)
{
		if(!hudSettings[Master][client])
		{
				return;
		}
	   
		if(!g_Settings[HUDMasterEnable])
		{
				return;
		}
 
		if(g_PBString[client][0] == '\0') {
				GetPBString(client);
		}			   
 
		new iClientToShow, iObserverMode;
		//new iButtons;
 
		// Show own buttons by default
		iClientToShow = client;
	   
		// Get target he's spectating
		if(!IsPlayerAlive(client) || IsClientObserver(client))
		{
				iObserverMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
				if(iObserverMode == SPECMODE_FIRSTPERSON || iObserverMode == SPECMODE_3RDPERSON)
				{
						iClientToShow = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget"); 
						// Check client index
						if(iClientToShow <= 0 || iClientToShow > MaxClients)
								return;
				}
				else
				{
						return; // don't proceed, if in freelook..
				}
		}
 
		if(IsFakeClient(iClientToShow))
		{
				UpdateHUD_Bot(iClientToShow, client);
				return;
		}
 
		//start building HUD
		new String:centerText[512]; //HUD buffer	   
	   
		//collect player stats
		decl String:buffer[32]; //time format buffer
		//decl String:bestbuffer[32]; //time format buffer
		new bool:enabled; //tier running
		//new Float:bestTime; //best round time
		//new bestJumps; //best round jumps
		new jumps; //current jump count
		new fpsmax; //fps settings
		new track; //track timer running
		new Float:time; //current time
		new RecordId;
		new Float:RecordTime;
		new RankTotal;
		new bool:isbonus = false;
	   
		if(g_timerWorldRecord) Timer_GetClientTimer(iClientToShow, enabled, time, jumps, fpsmax);
	   
		new style;	   
		if(g_timerPhysics) style = Timer_GetStyle(iClientToShow);	   
		new ranked;
		if(g_timerPhysics) ranked = Timer_IsStyleRanked(style);
			   
		//get current player level
		new currentLevel = 0;
		if(g_timerMapzones) currentLevel = Timer_GetClientLevelID(iClientToShow);
		if(currentLevel < 1) currentLevel = 1;
	   
		track = Timer_GetTrack(iClientToShow);
 
		if(track > 0)
		{
				if(g_BonusPBString[client][0] == '\0') {
						GetPBString(client);
				}					   
 
				isbonus = true;
		}
	   
		//get bhop mode
		if (g_timerPhysics)
		{
				Timer_GetStyleRecordWRStats(style, track, RecordId, RecordTime, RankTotal);
				//correct fail format
				Timer_SecondsToTime(time, buffer, sizeof(buffer), 2);
		}
 
		//get speed
		new Float:currentspeed;
		if(g_timerPhysics)
		{
				Timer_GetCurrentSpeed(iClientToShow, currentspeed);
		}
 
		//start format center HUD
	   
		new stagecount;
	   
		if(g_timerMapzones)
		{
				if(track == TRACK_BONUS)
				{
						stagecount = Timer_GetMapzoneCount(ZtBonusLevel)+1;
				}
				else if(track == TRACK_BONUS2)
				{
						stagecount = Timer_GetMapzoneCount(ZtBonus2Level)+Timer_GetMapzoneCount(ZtBonus2Checkpoint)+1;
				}
				else if(track == TRACK_BONUS3)
				{
						stagecount = Timer_GetMapzoneCount(ZtBonus3Level)+Timer_GetMapzoneCount(ZtBonus3Checkpoint)+1;
				}
				else if(track == TRACK_BONUS4)
				{
						stagecount = Timer_GetMapzoneCount(ZtBonus4Level)+Timer_GetMapzoneCount(ZtBonus4Checkpoint)+1;
				}
				else if(track == TRACK_BONUS5)
				{
						stagecount = Timer_GetMapzoneCount(ZtBonus5Level)+Timer_GetMapzoneCount(ZtBonus5Checkpoint)+1;
				}
				else
				{
						stagecount = Timer_GetMapzoneCount(ZtLevel)+1;
				}
		}
	   
		if(currentLevel > 1000) currentLevel -= 1000;
		if(currentLevel == 999) currentLevel = stagecount;
	   
		decl String:timeString[64];
		Timer_SecondsToTime(time, timeString, sizeof(timeString), 2);
	   
		//if(StrEqual(timeString, "00:-0.0")) Format(timeString, sizeof(timeString), "00:00.0");
		timeString[7] = '0';
	   
		if(hudSettings[Time][client])
		{
				if(Timer_GetPauseStatus(iClientToShow))
				{
						Format(centerText, sizeof(centerText), "<font size='16'><font color='#ff8000'>%sTimer Paused</font>", centerText, timeString);
				}
				else if (enabled)
				{
						if(RecordTime == 0.0 || RecordTime > time)
						{
								Format(centerText, sizeof(centerText), "%s<font size='16'>Time: <font color='#00ff66'>%s</font>", centerText, timeString);
						}
						else
						{
								Format(centerText, sizeof(centerText), "%s<font size='16'>Time: <font color='#ff0033'>%s</font>", centerText, timeString);
						}
				}
				else Format(centerText, sizeof(centerText), "<font size='16'><font color='#ff0000'>%sTimer Stopped</font>", centerText);
 
		}
		
		if(g_timerWorldRecordCheckpoints && hudSettings[WRCP][client])
		{
			float wrtime, pbtime;
			char S_compareWRStoT[32], S_compareWR[32];
			
			if(track == TRACK_BONUS || track == TRACK_BONUS2 || track == TRACK_BONUS3 || track == TRACK_BONUS4 || track == TRACK_BONUS5)
			{
				bool enable;
				int level;
				Timer_GetCheckpointsWRBonus(iClientToShow, enable, level, wrtime, pbtime);
				
				if(enable)
				{
					if(wrtime > 0.0)
					{
						if(wrtime > pbtime)
						{
							Timer_SecondsToTime(wrtime - pbtime, S_compareWRStoT, sizeof(S_compareWRStoT), 2);
							FormatEx(S_compareWR, PLATFORM_MAX_PATH, "CP%i WR: <font color='#00ff66'>-%s</font>", level, S_compareWRStoT);
						}
						else if(wrtime < pbtime)
						{
							Timer_SecondsToTime(pbtime - wrtime, S_compareWRStoT, sizeof(S_compareWRStoT), 2);
							FormatEx(S_compareWR, PLATFORM_MAX_PATH, "CP%i WR: <font color='#ff0033'>+%s</font>", level, S_compareWRStoT);
						}
						else if(wrtime == pbtime)
						{
							Timer_SecondsToTime(pbtime - wrtime, S_compareWRStoT, sizeof(S_compareWRStoT), 2);
							FormatEx(S_compareWR, PLATFORM_MAX_PATH, "CP%i WR: %s", level, S_compareWRStoT);
						}
					}
				}
			}
			else
			{
				bool enable;
				int level;
				Timer_GetCheckpointsWR(iClientToShow, enable, level, wrtime, pbtime);
				if(enable)
				{
					if(stagecount <= 1)
					{
						if(wrtime > 0.0)
						{
							if(wrtime > pbtime)
							{
								Timer_SecondsToTime(wrtime - pbtime, S_compareWRStoT, sizeof(S_compareWRStoT), 2);
								FormatEx(S_compareWR, PLATFORM_MAX_PATH, "CP%i WR: <font color='#00ff66'>-%s</font>", level, S_compareWRStoT);
							}
							else if(wrtime < pbtime)
							{
								Timer_SecondsToTime(pbtime - wrtime, S_compareWRStoT, sizeof(S_compareWRStoT), 2);
								FormatEx(S_compareWR, PLATFORM_MAX_PATH, "CP%i WR: <font color='#ff0033'>+%s</font>", level, S_compareWRStoT);
							}
							else if(wrtime == pbtime)
							{
								Timer_SecondsToTime(pbtime - wrtime, S_compareWRStoT, sizeof(S_compareWRStoT), 2);
								FormatEx(S_compareWR, PLATFORM_MAX_PATH, "CP%i WR: %s", level, S_compareWRStoT);
							}
						}
					}
					else
					{
						if(wrtime > 0.0)
						{
							if(wrtime > pbtime)
							{
								Timer_SecondsToTime(wrtime - pbtime, S_compareWRStoT, sizeof(S_compareWRStoT), 2);
								FormatEx(S_compareWR, PLATFORM_MAX_PATH, "WR: <font color='#00ff66'>-%s</font>", S_compareWRStoT);
							}
							else if(wrtime < pbtime)
							{
								Timer_SecondsToTime(pbtime - wrtime, S_compareWRStoT, sizeof(S_compareWRStoT), 2);
								FormatEx(S_compareWR, PLATFORM_MAX_PATH, "WR: <font color='#ff0033'>+%s</font>", S_compareWRStoT);
							}
							else if(wrtime == pbtime)
							{
								Timer_SecondsToTime(pbtime - wrtime, S_compareWRStoT, sizeof(S_compareWRStoT), 2);
								FormatEx(S_compareWR, PLATFORM_MAX_PATH, "WR: %s", S_compareWRStoT);
							}
						}				
					}
				}
			}
			
			if(S_compareWR[0] && Timer_GetStatus(iClientToShow))
			{
				Format(centerText, sizeof(centerText), "%s %s", centerText, S_compareWR);
			}
		}
		
	// ---------------------- SECOND LINE ------------------
		Format(centerText, sizeof(centerText), "%s\n", centerText);
 
		/* print pb on hud */
		if(hudSettings[PB][iClientToShow]) {
 
				if(isbonus == false)
				{
						if(g_PBString[iClientToShow][5] == '.') {
								g_PBString[iClientToShow][5] = ':';
						}
						if(g_PBString[iClientToShow][0] == '\0' || StrEqual(g_PBString[iClientToShow], "00:00:00")) {
								Format(centerText, sizeof(centerText), "%s⌊PB: None⌋", centerText);
						}
						else {
								Format(centerText, sizeof(centerText), "%s⌊PB: %s⌋", centerText, g_PBString[iClientToShow]);
						}					   
				}
				else
				{
						if(g_BonusPBString[iClientToShow][5] == '.') {
								g_BonusPBString[iClientToShow][5] = ':';
						}
						if(g_BonusPBString[iClientToShow][0] == '\0' || StrEqual(g_BonusPBString[iClientToShow], "00:00:00")) {
								Format(centerText, sizeof(centerText), "%s⌊PB: None⌋", centerText);
						}
						else {
								Format(centerText, sizeof(centerText), "%s⌊PB: %s⌋", centerText, g_BonusPBString[iClientToShow]);
						}					   
				}
		}	   
				if(ranked && g_timerWorldRecord )
		{
				//First we check if the player is on any of the 6 start zones (normal one plus 5 bonus)
				new bool:inStartZone = false;
				if (hudSettings[Level][client])
	   {
			   
				if(Timer_IsPlayerTouchingZoneType(iClientToShow,ZtStart))
				{
						Format(centerText, sizeof(centerText), "%s⌊Map Start⌋  ", centerText);
						inStartZone = true;
				}
				if(Timer_IsPlayerTouchingZoneType(iClientToShow,ZtBonusStart))
				{
						Format(centerText, sizeof(centerText), "%s⌊Bonus 1 Start⌋  ", centerText);
						inStartZone = true;
				}
				if(Timer_IsPlayerTouchingZoneType(iClientToShow,ZtBonus2Start))
				{
						Format(centerText, sizeof(centerText), "%s⌊Bonus 2 Start⌋  ", centerText);
						inStartZone = true;
				}
				if(Timer_IsPlayerTouchingZoneType(iClientToShow,ZtBonus3Start))
				{
						Format(centerText, sizeof(centerText), "%s⌊Bonus 3 Start⌋  ", centerText);
						inStartZone = true;
				}
				if(Timer_IsPlayerTouchingZoneType(iClientToShow,ZtBonus4Start))
				{
						Format(centerText, sizeof(centerText), "%s⌊Bonus 4 Start⌋  ", centerText);
						inStartZone = true;
				}
				if(Timer_IsPlayerTouchingZoneType(iClientToShow,ZtBonus5Start))
				{
						Format(centerText, sizeof(centerText), "%s⌊Bonus 5 Start⌋  ", centerText);
						inStartZone = true;
				}
				}
				if(!inStartZone && hudSettings[Level][client])
				{
						switch(lastStartTouched[iClientToShow])
						{
								case ZtStart:
								{	   
										if(stagecount <= 1)
										{
												Format(centerText, sizeof(centerText), "%s⌊Linear Map⌋	", centerText);
										}
										else
										{
												Format(centerText, sizeof(centerText), "%s⌊Stage: %d/%d⌋  ", centerText, currentLevel, stagecount);
										}
								}
								case ZtBonusStart: Format(centerText, sizeof(centerText), "%s⌊Bonus 1⌋	", centerText);
								case ZtBonus2Start: Format(centerText, sizeof(centerText), "%s⌊Bonus 2⌋	 ", centerText);
								case ZtBonus3Start: Format(centerText, sizeof(centerText), "%s⌊Bonus 3⌋	 ", centerText);
								case ZtBonus4Start: Format(centerText, sizeof(centerText), "%s⌊Bonus 4⌋	 ", centerText);
								case ZtBonus5Start: Format(centerText, sizeof(centerText), "%s⌊Bonus 5⌋	 ", centerText);
							   
					   
						}
				}
		}	   
		// THIRD LINE
				{	   
				Format(centerText, sizeof(centerText), "%s\n", centerText);
				}	   
				if(hudSettings[Speed][client])
				Format(centerText, sizeof(centerText), "%s⌊Speed: %d u/s⌋", centerText, RoundToNearest(currentspeed));
	// STYLE
				if (hudSettings[Mode][client] && g_Settings[MultimodeEnable])
		{
				Format(centerText, sizeof(centerText), "%s⌊Mode: %s⌋</font>", centerText, g_Physics[style][StyleName]);
		}	   
		if (g_Settings[HUDCenterEnable] && hudSettings[Main][client])
		{
//				if(!IsVoteInProgress())
						if(g_MapFinished[client])
						{
								Format(centerText, sizeof(centerText), "Map completed!\nTime: %s",g_TimeString[client]);
								PrintToChatAll("Map completed!\nTime: %s",g_TimeString[client]);
						}
						PrintHintText(client, centerText);
		}
}
 
 
//Used to check if the last start zone was a normal one or a bonus
public OnClientEndTouchZoneType(client, MapZoneType:type)
{
		switch(type)
		{
				case ZtStart: {lastStartTouched[client] = ZtStart; g_MapFinished[client] = false;}
				case ZtBonusStart: {lastStartTouched[client] = ZtBonusStart; g_MapFinished[client] = false;}
				case ZtBonus2Start: {lastStartTouched[client] = ZtBonus2Start; g_MapFinished[client] = false;}
				case ZtBonus3Start: {lastStartTouched[client] = ZtBonus3Start; g_MapFinished[client] = false;}
				case ZtBonus4Start: {lastStartTouched[client] = ZtBonus4Start; g_MapFinished[client] = false;}
				case ZtBonus5Start: {lastStartTouched[client] = ZtBonus5Start; g_MapFinished[client] = false;}
			   
				default: {lastStartTouched[client] = ZtStart; g_MapFinished[client] = false;}
	   
		}
}
 
public OnTimerRecord(client, track, style, Float:time, Float:lasttime, currentrank, newrank)
{
		if(track == TRACK_BONUS || track == TRACK_BONUS2 || track == TRACK_BONUS3 || track == TRACK_BONUS4 || track == TRACK_BONUS5 || track == TRACK_NORMAL )
		{
				g_MapFinished = true;
				Timer_SecondsToTime(time, g_TimeString[client], sizeof(g_TimeString[]), 2);
		}
 
		CreateTimer(2.5, GetPBStringDelayed, client);
}
 
 
public Action:Cmd_SpecInfo(client, args)
{
		new owner = client;
		if(!IsPlayerAlive(client) || IsClientObserver(client))
		{
				new iObserverMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
				if(iObserverMode == SPECMODE_FIRSTPERSON || iObserverMode == SPECMODE_3RDPERSON)
				{
						new iTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
						if(iTarget > 0)
						{
								Print_Specinfo(iTarget, owner);
						}
				}
		}
		else
		{
				Print_Specinfo(client, owner);
		}
	   
		return Plugin_Handled; 
}
 
Print_Specinfo(client, owner)
{
		new String:buffer[1024];
	   
		new spec_count = GetSpecCount(client);
		new count = 0;
	   
		for(new j = 1; j <= MaxClients; j++)
		{
				if (!IsClientInGame(j) || !IsClientObserver(j))
						continue;
			   
				if (IsClientSourceTV(j))
						continue;
					   
				new iSpecMode = GetEntProp(j, Prop_Send, "m_iObserverMode");
			   
				// The client isn't spectating any one person, so ignore them.
				if (iSpecMode != SPECMODE_FIRSTPERSON && iSpecMode != SPECMODE_3RDPERSON)
						continue;
			   
				// Find out who the client is spectating.
				new iTarget = GetEntPropEnt(j, Prop_Send, "m_hObserverTarget");
			   
				// Are they spectating the same player as User?
				if (iTarget == client && j != client && !hidemyass[j])
				{
						count++;
						if(spec_count == count)
						{
								Format(buffer, sizeof(buffer), "%s %N", buffer, j);
						}
						else
						{
								Format(buffer, sizeof(buffer), "%s %N,", buffer, j);
						}
				}
		}
	   
		CPrintToChat(owner, "%s {red}%N {olive}has {red}%d {olive}spectators:{red}%s.", PLUGIN_PREFIX2, client, count, buffer);
}
 
public OnPlayerRankLoaded(client, rank)
{
		new track = 0;
		new RecordId;
		new Float:RecordTime;
		new style = 0;
		playerRank[client] = Timer_GetStyleRank(client, track, style);
 
 
		if(rankLoaded == false)
		{
				Timer_GetStyleRecordWRStats(style, track, RecordId, RecordTime, mapRankTotal);
				rankLoaded = true;
		}
 
		g_ClientReady[client] = true;
}
 
stock GetPBString(client)
{
 
		if(client <= 0 || !IsClientInGame(client) || IsFakeClient(client) || IsClientObserver(client) || !IsPlayerAlive(client))
		{
				return;
		}
 
		if(g_ClientReady[client] == false)
				return;
 
		new Float:bestTime;
		new bestJumps;
		new track;
		new style;
 
		style = Timer_GetStyle(client);
		track = Timer_GetTrack(client);
 
		Timer_GetBestRound(client, style, track, bestTime, bestJumps);
 
		if(track == 0)
		{
				Timer_SecondsToTime(bestTime, g_PBString[client], sizeof(g_PBString[]), 2);
		}
		else
		{
				Timer_SecondsToTime(bestTime, g_BonusPBString[client], sizeof(g_BonusPBString[]), 2);
		}
	   
}
 
public Action:GetPBStringDelayed(Handle:timer, any:client)
{
		GetPBString(client);
}
 
stock GetSpecCount(client)
{
		new count = 0;
	   
		for(new j = 1; j <= MaxClients; j++)
		{
				if (!IsClientInGame(j) || !IsClientObserver(j))
						continue;
			   
				if (IsClientSourceTV(j))
						continue;
					   
				new iSpecMode = GetEntProp(j, Prop_Send, "m_iObserverMode");
			   
				// The client isn't spectating any one person, so ignore them.
				if (iSpecMode != SPECMODE_FIRSTPERSON && iSpecMode != SPECMODE_3RDPERSON)
						continue;
			   
				// Find out who the client is spectating.
				new iTarget = GetEntPropEnt(j, Prop_Send, "m_hObserverTarget");
			   
				// Are they spectating the same player as User?
				if (iTarget == client && j != client && !hidemyass[j])
				{
						count++;
				}
		}
	   
		return count;
}