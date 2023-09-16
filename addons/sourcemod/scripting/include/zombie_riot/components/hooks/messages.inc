/*    <DR.API ZOMBIE RIOT> (c) by <De Battista Clint - (http://doyou.watch)  */
/*                                                                           */
/*                  <DR.API ZOMBIE RIOT> is licensed under a                 */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//***************************DR.API ZOMBIE RIOT MSG**************************//
//***************************************************************************//
//***************************************************************************//

/***********************************************************/
/****************** CREATE HOOK MESSAGES *******************/
/***********************************************************/
void CreateHookMessages()
{
	TextMsg  					= GetUserMessageId("TextMsg");
	SayText  					= GetUserMessageId("SayText");
	SayText2 					= GetUserMessageId("SayText2");
	RadioText 					= GetUserMessageId("RadioText");
	
	HookUserMessage(TextMsg,  	UserMessagesHook, true);
	HookUserMessage(SayText,  	UserMessagesHook, true);
	HookUserMessage(SayText2, 	UserMessagesHook, true);
	HookUserMessage(RadioText, 	UserMessagesHook, true);
	
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say2");
	AddCommandListener(Command_Say, "say_team");
	
	RegAdminCmd("sm_co", Command_TestConnect, ADMFLAG_CHANGEMAP, "");
}

/***********************************************************/
/****************** COMMAND TEST CONNECT *******************/
/***********************************************************/
public Action Command_TestConnect(int client, int args)
{
	ShowMessage(client, false);
	ShowMessage(client, true);
	return Plugin_Handled;
}

/***********************************************************/
/********************** SHOW MESSAGES **********************/
/***********************************************************/
void ShowMessage(int client, bool connect)
{
	char S_country[32];
	char S_address[32];	
	char S_name[64];
	GetClientIP(client, S_address, 32);
	GetClientName(client, S_name, sizeof(S_name));
	Format(S_country, 100, "Unknown");
	
	if(!IsFakeClient(client))
	{
		if(connect)
		{
			GeoipCountry(S_address, S_country, 100);
			CPrintToChatAll("%t", "Connected", S_name, S_country);
		}
		else
		{
			CPrintToChatAll("%t", "Disconnected", S_name);
		}
	}
}

/***********************************************************/
/*********************** COMMAND SAY ***********************/
/***********************************************************/
public Action Command_Say(int client, const char[] command, int args)
{
	char text[192];
	int startidx = 0;
	
	if(GetCmdArgString(text, sizeof(text)) < 1)
	{
		return Plugin_Continue;
	}

	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}

	if(strcmp(command, "say2", false) == 0)
	{
		startidx += 4;
	}

	if(PLUGIN_AIRDROP)
	{
		if(
		strcmp(text[startidx], "gun", false) 			== 0 ||
		strcmp(text[startidx], "guns", false) 			== 0 ||
		strcmp(text[startidx], "weapons", false) 		== 0 ||
		strcmp(text[startidx], "weapon", false) 		== 0 ||
		strcmp(text[startidx], "!gun", false) 			== 0 ||
		strcmp(text[startidx], "!guns", false) 			== 0 ||
		strcmp(text[startidx], "!weapons", false) 		== 0 ||
		strcmp(text[startidx], "!weapon", false) 		== 0
		)
		{
			
			CPrintToChat(client, "%t", "Helico round start warning");
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}
/***********************************************************/
/******************* WHEN PLAYER MESSAGE *******************/
/***********************************************************/
public Action UserMessagesHook(UserMsg msg_id, Handle msg, const int[] players, int playersNum, bool reliable, bool init)
{
	if(B_active_zombie_riot)
	{
		char buffer[PLATFORM_MAX_PATH], szMsgId[32];
		for (int i; i < PbGetRepeatedFieldCount(msg, "params"); i++)
		{
			PbReadString(msg, "params", buffer, sizeof(buffer), i);

			if (msg_id == TextMsg)
			{
				Format(szMsgId, sizeof(szMsgId), "TextMsg");
			}
			
			if (msg_id == SayText)
			{
				Format(szMsgId, sizeof(szMsgId), "SayText");
			}
			
			if (msg_id == SayText2)
			{
				Format(szMsgId, sizeof(szMsgId), "SayText2");
			}
			
			if (msg_id == RadioText)
			{
				Format(szMsgId, sizeof(szMsgId), "RadioText");
			}
			
			//LogMessage("msg_id: %s, params: %s", szMsgId, buffer);
		}

		if(msg_id == RadioText)
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}