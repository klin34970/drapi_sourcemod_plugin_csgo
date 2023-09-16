/***********************************************************/
/******************** ADD SOUND TO CACHE *******************/
/***********************************************************/
stock void FakePrecacheSound(const char[] szPath)
{
	AddToStringTable( FindStringTable( "soundprecache" ), szPath );
}

/***********************************************************/
/****************** FAKE AND DOWNLOAD SOUND ****************/
/***********************************************************/
stock void FakeAndDownloadSound(bool log, const char[][] stocksound, int num)
{
	for (int i = 0; i < num; i++)
	{
		char FULL_SOUND_PATH[PLATFORM_MAX_PATH];
		Format(FULL_SOUND_PATH, PLATFORM_MAX_PATH, "sound/%s", stocksound[i]);
		AddFileToDownloadsTable(FULL_SOUND_PATH);
		
		char RELATIVE_SOUND_PATH[PLATFORM_MAX_PATH];
		Format(RELATIVE_SOUND_PATH, PLATFORM_MAX_PATH, "*%s", stocksound[i]);
		FakePrecacheSound(RELATIVE_SOUND_PATH);
		
		if(log)
		{
			LogMessage("AddFileToDownloadsTable: %s, FakePrecacheSound: %s", FULL_SOUND_PATH, RELATIVE_SOUND_PATH);
		}
	}
}