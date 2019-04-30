#if defined _reason_checker_included
	#endinput
#endif

#define _reason_checker_included

#include <amxmodx>
#include <amxmisc>

stock load_replaces()
{
	new inifile[128], pos	
	get_configsdir(inifile, 127)
	add(inifile, 127, "/amxbans.ini")
	
	if(!file_exists(inifile))
	{
		return 0
	}
	
	new buffer[128], temp1[64], temp2[64], len, line
	while((line = read_file(inifile, line, buffer, 64, len)))
	{
		if(buffer[0] == '[' && buffer[1] == 'R')
		{
			pos = 1
			continue
		}
		if(buffer[0] == ';' || (buffer[0] == '/' && buffer[1] == '/') || !strlen(buffer))
		{
			continue
		}
		parse(buffer, temp1, 63, temp2, 63)
		ArrayPushString(pos ? g_ReplaceInd : g_AReplaceInd, temp1)
		ArrayPushString(pos ? g_Replace : g_AReplace, temp2)
	}
	
	return 1
}

stock check_reason(reason[], len, output[], len2)
{
	new temp[64], temp2[64], arrsize
	
	arrsize = ArraySize(g_ReplaceInd)
	
	for(new i; i < arrsize; i++)
	{
		ArrayGetString(g_ReplaceInd, i, temp, 63)
		if(contain(reason, temp) != -1)
		{
			ArrayGetString(g_Replace, i, temp2, 63)
			replace_all(reason, len, temp, temp2)
		}
	}
	
	arrsize = ArraySize(g_AReplaceInd)
	
	for(new i; i < arrsize; i++)
	{
		ArrayGetString(g_AReplaceInd, i, temp, 63)
		if(contain(reason, temp) != -1)
		{
			ArrayGetString(g_AReplace, i, output, len2)
			return 1
		}
	}
	
	return 0
}