/*    <DR.API ZOMBIE RIOT> (c) by <De Battista Clint - (http://doyou.watch)  */
/*                                                                           */
/*                  <DR.API ZOMBIE RIOT> is licensed under a                 */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//**************************DR.API ZOMBIE RIOT HOSTNAME**********************//
//***************************************************************************//
//***************************************************************************//

/***********************************************************/
/********************** UPDATE HOSTNAME ********************/
/***********************************************************/
void UpdateHostname(char[] format, any ...)
{
	char name[MSG_LENGTH];
	char name2[MSG_LENGTH];
	Format(name, MSG_LENGTH, "%s", format);
	VFormat(name2, MSG_LENGTH, name, 2);
	
	SetGlobalTransTarget(LANG_SERVER);
	ServerCommand("hostname \"%s\"", name2);
}