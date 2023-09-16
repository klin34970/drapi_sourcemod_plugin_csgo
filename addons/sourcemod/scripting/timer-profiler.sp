#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <profiler>
#include <timer>
 
public Plugin myinfo =
{
        name = "Plugin profiler for Tim3r",
        author = "Eddy (proted to new syntax by zipcore)",
        description = "profiler plugin",
        version = "1.0",
        url = ""
}
 
#if defined USE_PROFILING then
 
Handle g_Prof[MAX_CONCURENT_PROFILERS];
char g_ProfName[MAX_PROFILERS][MAX_PRFOILER_NAME];
float g_ProfTotal[MAX_PROFILERS];
float g_ProfMax[MAX_PROFILERS];
float g_ProfMin[MAX_PROFILERS];
int g_ProfCalls[MAX_PROFILERS];
int g_ProfConIndex[MAX_PROFILERS];
int g_ProfIndex = 0;
int g_ProfNr = 0;
 
int profiler1ID;
bool startedCounting;
 
public int ProfilerRegister(char name[MAX_PRFOILER_NAME])
{
        if(g_ProfIndex >= MAX_PROFILERS)
        {
                LogMessage("Maximum number of profilers exceeded please increase MAX_PROFILERS");
        }
 
        g_ProfName[g_ProfIndex] = name;
        g_ProfTotal[g_ProfIndex] = 0.0;
        g_ProfMax[g_ProfIndex] = 0.0;
        g_ProfMin[g_ProfIndex] = 10000000.0;
        g_ProfCalls[g_ProfIndex] = 0;
        g_ProfIndex++;
        return g_ProfIndex - 1;
}
 
 
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
   CreateNative("Tim3r_RegisterProfiler", Native_RegisterProfiler);
   CreateNative("Tim3r_StartProfiling", Native_StartProfiling);
   CreateNative("Tim3r_EndProfiling", Native_EndProfiling);
   return APLRes_Success;
}
 
public int Native_RegisterProfiler(Handle plugin, int intnumParams)
{
        char map[MAX_PRFOILER_NAME];
        GetNativeString(1, map, sizeof(map));
        return ProfilerRegister(map);
}
 
public int Native_StartProfiling(Handle plugin, int numParams)
{
        ProfilerStart(GetNativeCell(1));
}
 
public int Native_EndProfiling(Handle plugin, int numParams)
{
        ProfilerEnd(GetNativeCell(1));
}
 
public Action CMDInfo(int client, int args)
{    
        PrintToConsole(client, "commands:");
        PrintToConsole(client, "sm_profiler : show profiler log");
        PrintToConsole(client, "sm_profiler_clear : set all counters to zero");
        PrintToConsole(client, "log: total nr of profilers %i concurrent %i", g_ProfIndex, g_ProfNr);
        ProfilerLogData(client);
}
 
public Action CMDClear(int client, int args)
{    
        ProfilerClearData();
}
 
public void ProfilerStart(int profileId)
{
        if(g_ProfNr >= MAX_CONCURENT_PROFILERS)
        {
                LogMessage("Profiling exceeded max number of nested profilers");
                return;
        }
        StartProfiling(g_Prof[g_ProfNr]);
        g_ProfConIndex[profileId] = g_ProfNr;  
        g_ProfNr ++;
}
 
public void ProfilerEnd(int profileId)
{
        int currProfIndex = g_ProfConIndex[profileId];
        StopProfiling(g_Prof[currProfIndex]);
        float timeSpend = GetProfilerTime(g_Prof[currProfIndex]);
       
        //LogMessage("End profiling %i time spend %f", profileId, timeSpend);
       
        g_ProfTotal[profileId] = g_ProfTotal[profileId] + timeSpend;
        g_ProfCalls[profileId] = g_ProfCalls[profileId] + 1;
       
        if(timeSpend > g_ProfMax[profileId])
                g_ProfMax[profileId] = timeSpend;
        if(timeSpend < g_ProfMin[profileId])
                g_ProfMin[profileId] = timeSpend;
       
        g_ProfNr --;
}
 
public void ProfilerClearData()
{
        for(int i=0; i<g_ProfIndex; i++)
        {
                g_ProfTotal[i] = 0.0;
                g_ProfMax[i] = 0.0;
                g_ProfMin[i] = 10000000.0;
                g_ProfCalls[i] = 0;
        }
}
 
public void ProfilerLogData(int client)
{
        PrintToConsole(client, "name                           calls    total        avg         min        max   variance ");
       
        float avg = 0.0;
        float varianceLow = 0.0;
        float varianceHigh = 0.0;
        float variance = 0.0;
        for(int i=0; i<g_ProfIndex; i++)
        {
                avg = (g_ProfTotal[i]/g_ProfCalls[i]);
                varianceLow = (g_ProfMax[i] - avg) / avg * 100.0;
                varianceHigh = (g_ProfMax[i] - avg) / avg * 100.0;
                if(varianceHigh > varianceLow)
                        variance = varianceHigh;
                else
                        variance = varianceLow;
                PrintToConsole(client, "%25s %10i %8.4f %4.8f %4.8f %4.8f %8.2f", g_ProfName[i], g_ProfCalls[i], g_ProfTotal[i], avg, g_ProfMin[i], g_ProfMax[i], variance);
        }
}
 
public void OnGameFrame()
{
        if(!startedCounting)
                startedCounting = true;
        else
                ProfilerEnd(profiler1ID);
               
        ProfilerStart(profiler1ID);
}
 
public void OnPluginStart()
{
        RegAdminCmd("sm_profiler", CMDInfo, ADMFLAG_GENERIC, "");
        RegAdminCmd("sm_profiler_clear", CMDClear, ADMFLAG_GENERIC, "");
       
        for(int i=0; i<MAX_CONCURENT_PROFILERS; i++)
        {
                g_Prof[i] = CreateProfiler();
        }
       
        startedCounting = false;
        profiler1ID = ProfilerRegister("timer-rankings_points_skill.smx Timer_CalcPoints");
}
 
#endif