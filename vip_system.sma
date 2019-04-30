#include <amxmodx>
#include <amxmisc>

new amx_password_field_string[31]
enum _:database_items
{
	auth[50],
	password[50],
	day[3],
	month[3],
	year[5]
}
new vips_database[database_items]
new Array:database_holder
new g_vip[33], g_day[33], g_month[33], g_year[33]

public plugin_init() {
	get_cvar_string("amx_password_field", amx_password_field_string, 30)
	reload_vips()
}

public plugin_natives()
{
	register_native("vip_get", "natvie_vip_get",1)
	register_native("vip_get_day", "natvie_vip_day",1)
	register_native("vip_get_month", "natvie_vip_month",1)
	register_native("vip_get_year", "natvie_vip_year",1)
}

public reload_vips() {
	
	if(database_holder) ArrayDestroy(database_holder)
	database_holder = ArrayCreate(database_items)
	new configsDir[64]
	get_configsdir(configsDir, 63)
	format(configsDir, 63, "%s/vips.ini", configsDir)
	
	new todaysmonth[32]
	new todaysday[32]
	new todaysyear[32]
	get_time("%m",todaysmonth,31)
	get_time("%d",todaysday,31)
	get_time("%Y",todaysyear,31)
	new todaysdaynum = str_to_num(todaysday)
	new todaysmonthnum = str_to_num(todaysmonth)
	new todaysyearnum = str_to_num(todaysyear)
	
	new File=fopen(configsDir,"rt")
	new iLineCount=0
	
	if (File)
	{
		static Text[512], AuthData[50], Password[50], Day[3], Month[3], Year[5],
		DayNum, MonthNum, YearNum
		while (!feof(File)&&file_exists(configsDir))
		{
			iLineCount++
			fgets(File,Text,sizeof(Text)-1);
			
			trim(Text);
			
			if (Text[0]==';')  {
				continue;
			}
			
			AuthData[0]=0;
			Password[0]=0;
			Day[0]=0
			Month[0]=0
			Year[0]=0
			
			// not enough parameters
			if (parse(Text,AuthData,charsmax(AuthData),Password,charsmax(Password),Day,charsmax(Day),Month,charsmax(Month),Year,charsmax(Year)) < 1)
				continue;
				
			DayNum=str_to_num(Day)
			MonthNum=str_to_num(Month)
			YearNum=str_to_num(Year)
				
			if((DayNum<todaysdaynum&&MonthNum==todaysmonthnum&&YearNum==todaysyearnum)
			|| (MonthNum<todaysmonthnum&&YearNum==todaysyearnum)
			|| (YearNum < todaysyearnum)){
				fclose(File);
				DeleteLine(configsDir, iLineCount)
				break;
			}

			vips_database[auth] = AuthData
			vips_database[password] = Password
			vips_database[day] = Day
			vips_database[month] = Month
			vips_database[year] =Year
			ArrayPushArray(database_holder, vips_database)
		}
		
		fclose(File);
	}
}

public DeleteLine( const szFilename[ ], const iLine )
{
	new iFile = fopen( szFilename, "rt" );
	if( !iFile )
	{
		return;
	}
	static const szTempFilename[ ] = "delete_line.txt";
	new iTempFile = fopen( szTempFilename, "wt" );
    
	new szData[ 256 ], iLineCount, bool:bReplaced = false;
	while( !feof( iFile ) )
	{
		iLineCount++
		fgets( iFile, szData, 255 );

		if( iLineCount == iLine ) bReplaced = true;
		else fputs( iTempFile, szData );
	}
    
	fclose( iFile );
	fclose( iTempFile );
    
	if( bReplaced )
	{
		delete_file( szFilename );
        
		rename_file( szTempFilename, szFilename, 1 ) 
		
		reload_vips()
	}
	else
	{
		delete_file( szTempFilename );
	}
}

public set_flags(id) {
	
	static authid[31], ip[31], name[51], index, client_password[31], size
	get_user_authid(id, authid, 30)
	get_user_ip(id, ip, 30, 1)
	get_user_name(id, name, 50)
	get_user_info(id, amx_password_field_string, client_password, 30)
	
	g_vip[id] = 0
	size = ArraySize(database_holder)
	for(index=0; index < size ; index++) {
		ArrayGetArray(database_holder, index, vips_database)
		if(equali(name, vips_database[auth]))
		{
			if(!equal(client_password, vips_database[password])) 
			{
				server_cmd("kick #%d ^"Invalid password^"", get_user_userid(id))
				break
			}
			
			g_vip[id] = 1
			g_day[id]=str_to_num(vips_database[day])
			g_month[id]=str_to_num(vips_database[month])
			g_year[id]=str_to_num(vips_database[year])
			log_amx("[Vip] %s (%s %s) connecting", name, authid, ip)
			break
		}
	}
}

public client_connect(id)set_flags(id)

public natvie_vip_get(id) return g_vip[id]
public natvie_vip_day(id) return g_day[id]
public natvie_vip_month(id) return g_month[id]
public natvie_vip_year(id) return g_year[id]