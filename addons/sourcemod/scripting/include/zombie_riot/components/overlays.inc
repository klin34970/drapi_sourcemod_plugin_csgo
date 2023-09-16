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
/********************* SHOW OVERLAYS ***********************/
/***********************************************************/
void ShowOverlays(float time, int winner)
{
	char overlay[64];
	
	if(winner == ZOMBIE)
	{
		GetDayOverlayZombie(INT_CURRENT_DAY, overlay, sizeof(overlay));
	}
	else if(winner == HUMAN)
	{
		GetDayOverlayHuman(INT_CURRENT_DAY, overlay, sizeof(overlay));
	}

	for(int i = 1; i <= MaxClients; i++)
	{
		if(Client_IsIngame(i) && C_show_overlays[i])
		{
			SetClientOverlay(i, overlay);
			CreateTimer(time, Timer_KillOverlays, i);
		}
	}
}

/***********************************************************/
/********************* KILL OVERLAYS ***********************/
/***********************************************************/
public Action Timer_KillOverlays(Handle timer, any client)
{
	DeleteOverlay(client);
}