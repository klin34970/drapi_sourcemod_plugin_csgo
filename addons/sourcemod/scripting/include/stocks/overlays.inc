/***********************************************************/
/****************** DISPLAY SCREEN OVERLAY *****************/
/***********************************************************/
stock void SetClientOverlay(int client, char[] strOverlay)
{
	if (Client_IsIngame(client))
	{
		int iFlags = GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT);
		SetCommandFlags("r_screenoverlay", iFlags);	
		ClientCommand(client, "r_screenoverlay \"%s\"", strOverlay);
	}
}

/***********************************************************/
/****************** DELETE SCREEN OVERLAY ******************/
/***********************************************************/
stock void DeleteOverlay(int client)
{
	if (Client_IsIngame(client))
	{
		SetClientOverlay(client, "");
	}
}