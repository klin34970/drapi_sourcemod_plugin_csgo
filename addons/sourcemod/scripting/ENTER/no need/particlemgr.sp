#pragma semicolon 1
 
#include <sourcemod>
#include <sdktools>
 
public Plugin:myinfo = {
	name        = "Particle Manager",
	author      = "Nicholas Hastings",
	description = "Handles precaching of particle files",
	version     = "1.0.0",
	url         = "http://scamm.in"
};
 
ArrayList g_ParticleFiles;
 
int g_Sentinel = 0;
int g_ParticleFilesTable;
 
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ParticleMgr_PrecacheFile", Native_PrecacheParticleFile);
 
	RegPluginLibrary("particlemgr");
 
	return APLRes_Success;
}
 
public void OnPluginStart()
{
	g_ParticleFiles = new ArrayList();
 
	g_ParticleFilesTable = FindStringTable("ExtraParticleFilesTable");
	if (g_ParticleFilesTable == INVALID_STRING_TABLE)
	{
		SetFailState("Could not find \"ExtraParticleFilesTable\" string table");
	}
}
 
public void OnMapEnd()
{
	g_ParticleFiles.Clear();
}
 
public void OnClientConnected(int client)
{
	bool save = LockStringTables(false);
 
	char dummy[16];
	int len = IntToString(g_Sentinel++, dummy, sizeof(dummy));
 
	int cnt = g_ParticleFiles.Length;
	for (int i = 0; i < cnt; ++i)
	{
		SetStringTableData(g_ParticleFilesTable, g_ParticleFiles.Get(i), dummy, len);
	}
 
	LockStringTables(save);
}
 
int PrecacheParticleFile(const char[] szParticleFile)
{
	int idx = FindStringIndex(g_ParticleFilesTable, szParticleFile);
	if (idx == INVALID_STRING_INDEX)
	{
		bool save = LockStringTables(false);
		AddToStringTable(g_ParticleFilesTable, szParticleFile);
		LockStringTables(save);
 
		idx = FindStringIndex(g_ParticleFilesTable, szParticleFile);
 
		g_ParticleFiles.Push(idx);
	}
	return idx;
}
 
public int Native_PrecacheParticleFile(Handle plugin, int numParams)
{
	char szFilename[PLATFORM_MAX_PATH];
	GetNativeString(1, szFilename, sizeof(szFilename));
 
	return PrecacheParticleFile(szFilename);
}
 