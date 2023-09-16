#include <sourcemod>
#include <sdktools>
#include <colors>
#include <clientprefs>
#pragma semicolon 1

#define ABNER_ADMINFLAG ADMFLAG_SLAY
#define PLUGIN_VERSION "2.3"

#define MAX_EDICTS		2048

new g_iSoundEnts[MAX_EDICTS];
new g_iNumSounds;

new Handle:g_hCTPath;
new Handle:g_hTRPath;
new Handle:g_hPlayType;
new Handle:g_AbNeRCookie;
new Handle:g_hStop;

new bool:g_bClientPreference[MAXPLAYERS+1];
new bool:SoundsTRSucess;
new bool:SoundsCTSucess;

new g_SoundsTR = 0;
new g_PlayedTR = 0;
new g_SoundsCT = 0;
new g_PlayedCT = 0;

new String:soundct[128][PLATFORM_MAX_PATH];
new String:soundtr[128][PLATFORM_MAX_PATH];

new String:sCookieValue[11];

public Plugin:myinfo =
{
	name = "[CS:GO/CSS] AbNeR Round End Sounds",
	author = "AbNeR_CSS, DR. API Improvements",
	description = "Round End Sounds",
	version = PLUGIN_VERSION,
	url = "www.tecnohardclan.com/forum"
}

public OnPluginStart()
{  
	//Cvars
	CreateConVar("abner_round_end_version", PLUGIN_VERSION, "Version of the plugin", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	g_hTRPath = CreateConVar("abner_tr_music_path", "misc/tecnohard", "Path off tr sounds in /cstrike/sound", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_hCTPath = CreateConVar("abner_ct_music_path", "misc/tecnohard", "Path off ct sounds in /cstrike/sound", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_hPlayType = CreateConVar("abner_music_play_type", "1", "1 - Random, 2- Play in queue", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_hStop = CreateConVar("abner_stop_map_music", "0", "Stop map musics", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);	
	
	//ClientPrefs
	g_AbNeRCookie = RegClientCookie("AbNeR Round End Sounds", "", CookieAccess_Private);
	new info;
	SetCookieMenuItem(SoundCookieHandler, any:info, "Round End Sounds");
	
	for (new i = MaxClients; i > 0; --i)
    {
        if (!AreClientCookiesCached(i))
        {
            continue;
        }
        OnClientCookiesCached(i);
    }
	
	LoadTranslations("common.phrases");
	LoadTranslations("abner_round_end_sound.phrases");
		
	//Arquivo de configuração
	AutoExecConfig(true, "abner_round_end_sound");

	RegAdminCmd("sound_load", CommandLoad, ABNER_ADMINFLAG);
	//RegConsoleCmd("abnersound", abnermenu);
	
	SoundsCTSucess = false;
	SoundsTRSucess = false;
	
	decl String:theFolder[40];
	GetGameFolderName(theFolder, sizeof(theFolder));
	if(StrEqual(theFolder, "csgo"))
	{
		HookEvent("round_end", RoundEndCSGO);
	}
	else
	{
		HookEvent("round_end", RoundEnd);
	}
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}


stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

public StopMapMusic()
{
	decl String:sSound[PLATFORM_MAX_PATH];
	new entity = INVALID_ENT_REFERENCE;
	for(new i=1;i<=MaxClients;i++){
		if(!IsClientInGame(i)){ continue; }
		for (new u=0; u<g_iNumSounds; u++){
			entity = EntRefToEntIndex(g_iSoundEnts[u]);
			if (entity != INVALID_ENT_REFERENCE){
				GetEntPropString(entity, Prop_Data, "m_iszSound", sSound, sizeof(sSound));
				Client_StopSound(i, entity, SNDCHAN_STATIC, sSound);
			}
		}
	}
}



stock Client_StopSound(client, entity, channel, const String:name[])
{
	EmitSoundToClient(client, name, entity, channel, SNDLEVEL_NONE, SND_STOP, 0.0, SNDPITCH_NORMAL, _, _, _, true);
}


public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(g_hStop) == 1)
	{
		// Ents are recreated every round.
		g_iNumSounds = 0;
		
		// Find all ambient sounds played by the map.
		decl String:sSound[PLATFORM_MAX_PATH];
		new entity = INVALID_ENT_REFERENCE;
		
		while ((entity = FindEntityByClassname(entity, "ambient_generic")) != INVALID_ENT_REFERENCE)
		{
			GetEntPropString(entity, Prop_Data, "m_iszSound", sSound, sizeof(sSound));
			
			new len = strlen(sSound);
			if (len > 4 && (StrEqual(sSound[len-3], "mp3") || StrEqual(sSound[len-3], "wav")))
			{
				g_iSoundEnts[g_iNumSounds++] = EntIndexToEntRef(entity);
			}
		}
	}
}




public SoundCookieHandler(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	OnClientCookiesCached(client);
	abnermenu(client, 0);
} 

public OnClientPutInServer(client)
{
	CreateTimer(3.0, msg, client);
}

public Action:msg(Handle:timer, any:client)
{
	if(IsValidClient(client))
	{
		//CPrintToChat(client, "{green}[AbNeR Round End] {default}%t", "Join msg");
	}
}

public Action:abnermenu(client, args)
{
	GetClientCookie(client, g_AbNeRCookie, sCookieValue, sizeof(sCookieValue));
	new cookievalue = StringToInt(sCookieValue);
	new Handle:g_AbNeRMenu = CreateMenu(AbNeRMenuHandler);
	SetMenuTitle(g_AbNeRMenu, "Round End Sound");
	decl String:Item[128];
	if(cookievalue == 0)
	{
		Format(Item, sizeof(Item), "%t %t", "sounds on", "Enabled"); 
		AddMenuItem(g_AbNeRMenu, "ON", Item);
		Format(Item, sizeof(Item), "%t", "sounds off"); 
		AddMenuItem(g_AbNeRMenu, "OFF", Item);
	}
	else
	{
		Format(Item, sizeof(Item), "%t", "sounds on");
		AddMenuItem(g_AbNeRMenu, "ON", Item);
		Format(Item, sizeof(Item), "%t %t", "sounds off", "Enabled"); 
		AddMenuItem(g_AbNeRMenu, "OFF", Item);
	}
	SetMenuExitBackButton(g_AbNeRMenu, true);
	SetMenuExitButton(g_AbNeRMenu, true);
	DisplayMenu(g_AbNeRMenu, client, 30);
}

public AbNeRMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	new Handle:g_AbNeRMenu = CreateMenu(AbNeRMenuHandler);
	if (action == MenuAction_DrawItem)
	{
		return ITEMDRAW_DEFAULT;
	}
	else if(param2 == MenuCancel_ExitBack)
	{
		ShowCookieMenu(param1);
	}
	else if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 0:
			{
				SetClientCookie(param1, g_AbNeRCookie, "0");
				abnermenu(param1, 0);
			}
			case 1:
			{
				SetClientCookie(param1, g_AbNeRCookie, "1");
				abnermenu(param1, 0);
			}
		}
		CloseHandle(g_AbNeRMenu);
	}
	return 0;
}



public OnClientCookiesCached(client)
{
    decl String:sValue[8];
    GetClientCookie(client, g_AbNeRCookie, sValue, sizeof(sValue));
    
    g_bClientPreference[client] = (sValue[0] != '/0' && StringToInt(sValue));
} 

public OnConfigsExecuted()
{
	LoadSoundsCT();
	LoadSoundsTR();
}

public PathChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{       
	LoadSoundsCT();
	LoadSoundsTR();
}

public OnMapStart()
{
	LoadSoundsCT();
	LoadSoundsTR();
}

 


LoadSoundsTR()
{
	g_PlayedTR = 0;
	new namelen;
	new FileType:type;
	new String:name[64];
	new String:soundname[64];
	new String:soundname2[64];
	decl String:soundpath[32];
	decl String:soundpath2[32];
	GetConVarString(g_hTRPath, soundpath, sizeof(soundpath));
	Format(soundpath2, sizeof(soundpath2), "sound/%s/", soundpath);
	new Handle:pluginsdir = OpenDirectory(soundpath2);
	g_SoundsTR = 0;
	if(pluginsdir != INVALID_HANDLE)
	{
		while(ReadDirEntry(pluginsdir,name,sizeof(name),type))
		{
			namelen = strlen(name) - 4;
			if(StrContains(name,".mp3",false) == namelen)
			{
				g_SoundsTR++;
				Format(soundname, sizeof(soundname), "sound/%s/%s", soundpath, name);
				AddFileToDownloadsTable(soundname);
				Format(soundname2, sizeof(soundname2), "%s/%s", soundpath, name);
				//CPrintToChatAll("{green}[AbNeR Round End] {default}%t", "Loaded TR", soundname2);
				//PrintToServer("[AbNeR Round End] %s - Loaded", soundname2);
				soundtr[g_SoundsTR] = soundname2;
			}
		}
		SoundsTRSucess = true;
	}
	else
	{
		//CPrintToChatAll("{green}[AbNeR Round End] {default}%t", "Loaded TR Fail");
		SoundsTRSucess = false;
	}
}

LoadSoundsCT()
{
	g_PlayedCT = 0;
	new namelen;
	new FileType:type;
	new String:name[64];
	new String:soundname[64];
	new String:soundname2[64];
	decl String:soundpath[32];
	decl String:soundpath2[32];
	GetConVarString(g_hCTPath, soundpath, sizeof(soundpath));
	Format(soundpath2, sizeof(soundpath2), "sound/%s/", soundpath);
	new Handle:pluginsdir = OpenDirectory(soundpath2);
	g_SoundsCT = 0;
	if(pluginsdir != INVALID_HANDLE)
	{
		while(ReadDirEntry(pluginsdir,name,sizeof(name),type))
		{
			namelen = strlen(name) - 4;
			if(StrContains(name,".mp3",false) == namelen)
			{
				g_SoundsCT++;
				Format(soundname, sizeof(soundname), "sound/%s/%s", soundpath, name);
				AddFileToDownloadsTable(soundname);
				Format(soundname2, sizeof(soundname2), "%s/%s", soundpath, name);
				//CPrintToChatAll("{green}[AbNeR Round End] {default}%t", "Loaded CT", soundname2);
				//PrintToServer("[AbNeR Round End] %s - Loaded", soundname2);
				soundct[g_SoundsCT] = soundname2;
			}
		}
		SoundsCTSucess = true;
	}
	else
	{
		//CPrintToChatAll("{green}[AbNeR Round End] {default}%t", "Loaded CT Fail");
		SoundsCTSucess = false;
	}
}



PlaySoundTRCSGO()
{
	if(GetConVarInt(g_hPlayType) == 1)
	{
		new rnd_sound = GetRandomInt(1, g_SoundsTR);
		for (new i = 1; i <= MaxClients; i++)
		{
			GetClientCookie(i, g_AbNeRCookie, sCookieValue, sizeof(sCookieValue));
			new cookievalue = StringToInt(sCookieValue);
			if(IsValidClient(i) && cookievalue == 0)
			{
				ClientCommand(i, "play *%s", soundtr[rnd_sound]);		
				ClientCommand(i, "playgamesound Music.StopAllMusic");
			}
		}
	}
	else
	{
		new soundtoplay = g_PlayedTR + 1;
		if(soundtoplay > g_SoundsTR)
		{
			g_PlayedTR = 0;
			soundtoplay = 1;
		}
		for (new i = 1; i <= MaxClients; i++)
		{
			GetClientCookie(i, g_AbNeRCookie, sCookieValue, sizeof(sCookieValue));
			new cookievalue = StringToInt(sCookieValue);
			if(IsValidClient(i) && cookievalue == 0)
			{
				ClientCommand(i, "playgamesound Music.StopAllMusic");
				ClientCommand(i, "play *%s", soundtr[soundtoplay]);
			}
		}
		g_PlayedTR++;
	}
}

PlaySoundCTCSGO()
{
	if(GetConVarInt(g_hPlayType) == 1)
	{
		new rnd_sound = GetRandomInt(1, g_SoundsCT);
		for (new i = 1; i <= MaxClients; i++)
		{
			GetClientCookie(i, g_AbNeRCookie, sCookieValue, sizeof(sCookieValue));
			new cookievalue = StringToInt(sCookieValue);
			if(IsValidClient(i) && cookievalue == 0)
			{
				ClientCommand(i, "playgamesound Music.StopAllMusic");
				ClientCommand(i, "play *%s", soundct[rnd_sound]);		
			}
		}
	}
	else
	{
		new soundtoplay = g_PlayedCT + 1;
		if(soundtoplay > g_SoundsCT)
		{
			g_PlayedCT = 0;
			soundtoplay = 1;
		}

		for (new i = 1; i <= MaxClients; i++)
		{
			GetClientCookie(i, g_AbNeRCookie, sCookieValue, sizeof(sCookieValue));
			new cookievalue = StringToInt(sCookieValue);
			if(IsValidClient(i) && cookievalue == 0)
			{
				ClientCommand(i, "playgamesound Music.StopAllMusic");
				ClientCommand(i, "play *%s", soundct[soundtoplay]);		
			}
		}
		g_PlayedCT++;
	}
}

PlaySoundTR()
{
	if(GetConVarInt(g_hPlayType) == 1)
	{
		new rnd_sound = GetRandomInt(1, g_SoundsTR);
		for (new i = 1; i <= MaxClients; i++)
		{
			GetClientCookie(i, g_AbNeRCookie, sCookieValue, sizeof(sCookieValue));
			new cookievalue = StringToInt(sCookieValue);
			if(IsValidClient(i) && cookievalue == 0)
			{
				ClientCommand(i, "play %s", soundtr[rnd_sound]);
			}
		}
	}
	else
	{
		new soundtoplay = g_PlayedTR + 1;
		if(soundtoplay > g_SoundsTR)
		{
			g_PlayedTR = 0;
			soundtoplay = 1;
		}
		for (new i = 1; i <= MaxClients; i++)
		{
			GetClientCookie(i, g_AbNeRCookie, sCookieValue, sizeof(sCookieValue));
			new cookievalue = StringToInt(sCookieValue);
			if(IsValidClient(i) && cookievalue == 0)
			{
				ClientCommand(i, "play %s", soundtr[soundtoplay]);
			}
		}
		g_PlayedTR++;
	}
}

PlaySoundCT()
{
	if(GetConVarInt(g_hPlayType) == 1)
	{
		new rnd_sound = GetRandomInt(1, g_SoundsCT);
		for (new i = 1; i <= MaxClients; i++)
		{
			GetClientCookie(i, g_AbNeRCookie, sCookieValue, sizeof(sCookieValue));
			new cookievalue = StringToInt(sCookieValue);
			if(IsValidClient(i) && cookievalue == 0)
			{
				ClientCommand(i, "play %s", soundct[rnd_sound]);
			}
		}
	}
	else
	{
		new soundtoplay = g_PlayedCT + 1;
		if(soundtoplay > g_SoundsCT)
		{
			g_PlayedCT = 0;
			soundtoplay = 1;
		}
		for (new i = 1; i <= MaxClients; i++)
		{
			GetClientCookie(i, g_AbNeRCookie, sCookieValue, sizeof(sCookieValue));
			new cookievalue = StringToInt(sCookieValue);
			if(IsValidClient(i) && cookievalue == 0)
			{
				ClientCommand(i, "play %s", soundct[soundtoplay]);
			}
		}
		g_PlayedCT++;
	}
}


public Action:RoundEndCSGO(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if(GetConVarInt(g_hStop) == 1)
	{
		StopMapMusic();
	}
	new winner = GetEventInt(event, "winner");
	if (winner == 3)
	{
		if(SoundsCTSucess)
		{
			PlaySoundCTCSGO();
		}
		else
		{
			//CPrintToChatAll("{green}[AbNeR Round End] {default}%t", "Loaded CT Fail");
		}
	}
	if (winner == 2)
	{
		if(SoundsTRSucess)
		{
			PlaySoundTRCSGO();
		}
		else
		{
			//CPrintToChatAll("{green}[AbNeR Round End] {default}%t", "Loaded TR Fail");
		}
		
	}
	
	int num = GetRandomInt(0, 1);
	
	if(num)
	{
		if(SoundsCTSucess)
		{
			PlaySoundCTCSGO();
		}
	}
	else
	{
		if(SoundsTRSucess)
		{
			PlaySoundTRCSGO();
		}
	}
	
}

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if(GetConVarInt(g_hStop) == 1)
	{
		StopMapMusic();
	}
	new winner = GetEventInt(event, "winner");
	if (winner == 3)
	{
		if(SoundsCTSucess)
		{
			PlaySoundCT();
		}
		else
		{
			//CPrintToChatAll("{green}[AbNeR Round End] {default}%t", "Loaded CT Fail");
		}
	}
	if (winner == 2)
	{
		if(SoundsTRSucess)
		{
			PlaySoundTR();
		}
		else
		{
			//CPrintToChatAll("{green}[AbNeR Round End] {default}%t", "Loaded TR Fail");
		}
		
	}
	PlaySoundTR();
}
 
	

public Action:CommandLoad(client, args)
{   
	LoadSoundsTR();
	LoadSoundsCT();
	return Plugin_Handled;
}








