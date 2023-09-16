/*    <DR.API ZOMBIE RIOT> (c) by <De Battista Clint - (http://doyou.watch)  */
/*                                                                           */
/*                  <DR.API ZOMBIE RIOT> is licensed under a                 */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//******************************DR.API ZOMBIE RIOT***************************//
//***************************************************************************//
//***************************************************************************//

/***********************************************************/
/************* INITIALISE CLIENT DEATH COUNT ***************/
/***********************************************************/
void InitClientDeathCount(int client)
{
    if(!IsFakeClient(client))
	{
		char steamId[64];
		GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));

		StrCat(steamId, sizeof(steamId), "_iDeaths");

		SetTrieValue(trie_iDeaths, steamId, 0, false);
	}
}

/***********************************************************/
/**************** CHANGE CLIENT DEATH COUNT ****************/
/***********************************************************/
void ChangeClientDeathCount(int client, int value)
{
    if(!IsFakeClient(client))
	{
		char steamId[64];
		GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));

		StrCat(steamId, sizeof(steamId), "_iDeaths");

		int newvalue = value != 0 ? GetClientDeathCount(client) + value : 0;
		SetTrieValue(trie_iDeaths, steamId, newvalue, true);
	}
}

/***********************************************************/
/***************** GET CLIENT DEATH COUNT ******************/
/***********************************************************/
int GetClientDeathCount(int client)
{
	if(!IsFakeClient(client))
	{
		char steamId[64];
		GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));

		StrCat(steamId, sizeof(steamId), "_iDeaths");

		int value;
		GetTrieValue(trie_iDeaths, steamId, value);

		return value;
	}
	return 0;
}