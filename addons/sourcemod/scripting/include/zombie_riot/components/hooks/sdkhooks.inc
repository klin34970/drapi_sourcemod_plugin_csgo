/*    <DR.API ZOMBIE RIOT> (c) by <De Battista Clint - (http://doyou.watch)  */
/*                                                                           */
/*                  <DR.API ZOMBIE RIOT> is licensed under a                 */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//*************************DR.API ZOMBIE RIOT SDKHOOKS***********************//
//***************************************************************************//
//***************************************************************************//

void SDKHooksAll(bool hook)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(Client_IsIngame(i))
		{
			if(hook)
			{
				SDKHook(i, SDKHook_WeaponCanUse, OnWeaponCanUse); 
			}
			else
			{
				SDKUnhook(i, SDKHook_WeaponCanUse, OnWeaponCanUse); 
			}
		}
	}
}

/***********************************************************/
/********************* WEAPON CAN USE **********************/
/***********************************************************/
public Action OnWeaponCanUse(int client, int weapon)
{
    if(B_Player_Is_Zombie[client])
    {
        char weaponString[64];
        GetEdictClassname(weapon, weaponString, sizeof(weaponString));
        if (!StrEqual(weaponString, "weapon_knife"))
		{
            return Plugin_Handled;
		}
    }

    return Plugin_Continue;
}