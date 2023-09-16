/***********************************************************/
/********************* STRING TO UPPER *********************/
/***********************************************************/
stock int StringToUpper(const char[] input, char[] output)
{
	int x = 0;
	while (input[x] != '\0') 
	{
		if (IsCharLower(input[x])) 
		{
			output[x] = CharToUpper(input[x]);
		}
		else 
		{
			output[x] = input[x];
		}
		x++;
	}
	output[x] = '\0';
	return 0;
}