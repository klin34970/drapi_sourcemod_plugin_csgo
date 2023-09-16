#include <sourcemod>

public Plugin:myinfo =
{
    name = "Test-OnPluginStart",
    author = "Raska",
    description = "Test OnPluginStart",
    version = "0.1",
    url = ""
}

public OnPluginStart() { LogMessage("OnPluginStart"); }
public OnMapStart() { LogMessage("OnMapStart"); }
public OnMapEnd() { LogMessage("OnMapEnd"); }
public OnPluginEnd() { LogMessage("OnPluginEnd"); }  