/*   <DR.API DOWNLOADER> (c) by <De Battista Clint - (http://doyou.watch)    */
/*                                                                           */
/*                 <DR.API DOWNLOADER> is licensed under a                   */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//****************************DR.API DOWNLOADER******************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY

//***********************************//
//*************INCLUDE***************//
//***********************************//

//Include native
#include <sourcemod>
#include <sdktools>

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Informations plugin
public Plugin:myinfo =
{
	name = "DR.API DOWNLOADER",
	author = "Dr. Api",
	description = "DR.API DOWNLOADER by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://doyou.watch"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public OnPluginStart()
{
	CreateConVar("drapi_downloader_version", PLUGIN_VERSION, "Version", CVARS);
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public OnMapStart()
{

	//SKIN MODEL BUG
	AddFileToDownloadsTable("materials/models/player/kuristaja/octabrain/octabrain_lightwarp.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/octabrain/octabrain.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/octabrain/octaking.vmt");
	
	
	AddFileToDownloadsTable("materials/models/player/slow/chainsaw/part1.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/chainsaw/part1.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/chainsaw/part1_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/chainsaw/part2.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/chainsaw/part3.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/chainsaw/part3.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/chainsaw/part3_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/chainsaw/part4.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/chainsaw/part4.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/chainsaw/part4_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/chainsaw/part5.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/chainsaw/part5.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/chainsaw/part5_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/chainsaw/part6.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/chainsaw/part6.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/chainsaw/part6_normal.vtf");
	
	AddFileToDownloadsTable("materials/models/player/mapeadores/morell/amnesia/grunt/servant_grunt.vmt");
	AddFileToDownloadsTable("materials/models/player/mapeadores/morell/amnesia/grunt/servant_grunt.vtf");
	AddFileToDownloadsTable("materials/models/player/mapeadores/morell/amnesia/grunt/servant_grunt_hair.vtf");
	AddFileToDownloadsTable("materials/models/player/mapeadores/morell/amnesia/grunt/servant_grunt_hair_nrm.vtf");
	AddFileToDownloadsTable("materials/models/player/mapeadores/morell/amnesia/grunt/servant_grunt_nrm.vtf");
	
	AddFileToDownloadsTable("materials/models/player/mapeadores/morell/l4d/spitter/coach_head_wrp.vtf");
	AddFileToDownloadsTable("materials/models/player/mapeadores/morell/l4d/spitter/spitter.vmt");
	AddFileToDownloadsTable("materials/models/player/mapeadores/morell/l4d/spitter/spitter_color.vtf");
	AddFileToDownloadsTable("materials/models/player/mapeadores/morell/l4d/spitter/spitter_exponent.vtf");
	AddFileToDownloadsTable("materials/models/player/mapeadores/morell/l4d/spitter/spitter_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/mapeadores/morell/l4d/spitter/spitterenvmap.vmt");
	
	AddFileToDownloadsTable("materials/models/player/mapeadores/morell/masterchief/red/light.vmt");
	AddFileToDownloadsTable("materials/models/player/mapeadores/morell/masterchief/red/MKVI.vmt");
	AddFileToDownloadsTable("materials/models/player/mapeadores/morell/masterchief/red/MKVI.vtf");
	AddFileToDownloadsTable("materials/models/player/mapeadores/morell/masterchief/red/MKVIvisor.vmt");
	
	AddFileToDownloadsTable("materials/models/player/custom/SF/seth/seth.vmt");
	AddFileToDownloadsTable("materials/models/player/custom/SF/seth/seth.vtf");
	AddFileToDownloadsTable("materials/models/player/custom/SF/seth/seth_n.vtf");
	
	AddFileToDownloadsTable("materials/skybox/sky_day01_09_hdrbk.vmt");
	AddFileToDownloadsTable("materials/skybox/sky_day01_09_hdrbk.vtf");
	AddFileToDownloadsTable("materials/skybox/sky_day01_09_hdrdn.vmt");
	AddFileToDownloadsTable("materials/skybox/sky_day01_09_hdrdn.vtf");
	AddFileToDownloadsTable("materials/skybox/sky_day01_09_hdrft.vmt");
	AddFileToDownloadsTable("materials/skybox/sky_day01_09_hdrft.vtf");
	AddFileToDownloadsTable("materials/skybox/sky_day01_09_hdrlf.vmt");
	AddFileToDownloadsTable("materials/skybox/sky_day01_09_hdrlf.vtf");
	AddFileToDownloadsTable("materials/skybox/sky_day01_09_hdrrt.vmt");
	AddFileToDownloadsTable("materials/skybox/sky_day01_09_hdrrt.vtf");
	AddFileToDownloadsTable("materials/skybox/sky_day01_09_hdrup.vmt");
	AddFileToDownloadsTable("materials/skybox/sky_day01_09_hdrup.vtf");
	AddFileToDownloadsTable("materials/skybox/sky_day01_09_ldrbk.vmt");
	AddFileToDownloadsTable("materials/skybox/sky_day01_09_ldrbk.vtf");
	AddFileToDownloadsTable("materials/skybox/sky_day01_09_ldrdn.vmt");
	AddFileToDownloadsTable("materials/skybox/sky_day01_09_ldrdn.vtf");
	AddFileToDownloadsTable("materials/skybox/sky_day01_09_ldrft.vmt");
	AddFileToDownloadsTable("materials/skybox/sky_day01_09_ldrft.vtf");
	AddFileToDownloadsTable("materials/skybox/sky_day01_09_ldrlf.vmt");
	AddFileToDownloadsTable("materials/skybox/sky_day01_09_ldrlf.vtf");
	AddFileToDownloadsTable("materials/skybox/sky_day01_09_ldrrt.vmt");
	AddFileToDownloadsTable("materials/skybox/sky_day01_09_ldrrt.vtf");
	AddFileToDownloadsTable("materials/skybox/sky_day01_09_ldrup.vmt");
	AddFileToDownloadsTable("materials/skybox/sky_day01_09_ldrup.vtf");
}