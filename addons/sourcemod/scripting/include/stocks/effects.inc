/***********************************************************/
/************************* SHAKE ***************************/
/***********************************************************/
stock void Shake(int client, float time, float frequency, float amplitude)
{
	Handle message = StartMessageOne("Shake", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);

	if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf) 
	{
		PbSetInt(message, "command", 0);
		PbSetFloat(message, "local_amplitude", amplitude);
		PbSetFloat(message, "frequency", frequency);
		PbSetFloat(message, "duration", time);
	}
	else
	{
		BfWriteByte(message, 0);
		BfWriteFloat(message, amplitude);
		BfWriteFloat(message, frequency);
		BfWriteFloat(message, time);
	}
	
	EndMessage();	
}

/***********************************************************/
/************************** FADE ***************************/
/***********************************************************/
stock void Fade(int client, int speed, int hold, int type, int red, int green, int blue, int alpha)
{
    Handle hFade = INVALID_HANDLE;
    
    if (client)
    {
	   hFade = StartMessageOne("Fade", client);
	}
	else
	{
	   hFade = StartMessageAll("Fade");
	}
	
    if (hFade != INVALID_HANDLE)
	{
        if (GetUserMessageType() == UM_Protobuf)
        {
            new clr[4];
            clr[0]=red;
            clr[1]=green;
            clr[2]=blue;
            clr[3]=alpha;
            PbSetInt(hFade, "duration", speed);
            PbSetInt(hFade, "hold_time", hold);
            PbSetInt(hFade, "flags", type);
            PbSetColor(hFade, "clr", clr);
        }
        else
        {
        	BfWriteShort(hFade, speed);
        	BfWriteShort(hFade, hold);
        	BfWriteShort(hFade, type);
        	BfWriteByte(hFade, red);
        	BfWriteByte(hFade, green);
        	BfWriteByte(hFade, blue);	
        	BfWriteByte(hFade, alpha);
        }
    	EndMessage();
    }
}