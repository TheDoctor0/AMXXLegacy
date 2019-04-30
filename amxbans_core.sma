/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * 
 * AMX Bans - http://www.amxbans.net
 *  Plugin - Core
 * 
 * Copyright (C) 2014  Ryan "YamiKaitou" LeBlanc
 * Copyright (C) 2009, 2010  Thomas Kurz
 * Forked from "Admin Base (SQL)" in AMX Mod X (version 1.8.1)
 * 
 * 
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License as published by the
 *  Free Software Foundation; either version 2 of the License, or (at
 *  your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful, but
 *  WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 *  General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software Foundation,
 *  Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 *
 *  In addition, as a special exception, the author gives permission to
 *  link the code of this program with the Half-Life Game Engine ("HL
 *  Engine") and Modified Game Libraries ("MODs") developed by Valve,
 *  L.L.C ("Valve"). You must obey the GNU General Public License in all
 *  respects for all of the code used other than the HL Engine and MODs
 *  from Valve. If you modify this file, you may extend this exception
 *  to your version of the file, but you are not obligated to do so. If
 *  you do not wish to do so, delete this exception statement from your
 *  version.
 * 
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#define PLUGINNAME "AMXBans Core"
#define PLUGINAUTHOR "YamiKaitou"
new const PLUGINVERSION[] = "6.13";

#include <amxmodx>
#include <amxmisc>
#include <sqlx>

new AdminCount;

#define ADMIN_LOOKUP	(1<<0)
#define ADMIN_NORMAL	(1<<1)
#define ADMIN_STEAM		(1<<2)
#define ADMIN_IPADDR	(1<<3)
#define ADMIN_NAME		(1<<4)

new g_cmdLoopback[16]
new bool:g_CaseSensitiveName[33];

// pcvars
new amx_mode;
new amx_password_field;
new amx_default_access;

//amxbans
new pcvarip
new pcvarprefix
new pcvaradminsfile
new g_ServerAddr[100]
new g_dbPrefix[32]
new g_AdminsFromFile
new g_szAdminNick[33][32]
new g_iAdminUseStaticBantime[33]
new Array:g_AdminNick
new Array:g_AdminUseStaticBantime

//multi forward handles
new bool:g_isAdmin[33]
enum MFHANDLE_TYPES {
	Amxbans_Sql_Initialized=0,
	Admin_Connect,
	Admin_Disconnect
}
new MFHandle[MFHANDLE_TYPES]

new Handle:info

public plugin_init()
{
	register_plugin(PLUGINNAME, PLUGINVERSION, PLUGINAUTHOR);

	register_dictionary("admin.txt")
	register_dictionary("common.txt")
	amx_mode=register_cvar("amx_mode", "1")
	amx_password_field=register_cvar("amx_password_field", "_pw")
	amx_default_access=register_cvar("amx_default_access", "")

	register_cvar("amx_vote_ratio", "0.02")
	register_cvar("amx_vote_time", "10")
	register_cvar("amx_vote_answers", "1")
	register_cvar("amx_vote_delay", "60")
	register_cvar("amx_last_voting", "0")
	register_cvar("amx_show_activity", "2")
	register_cvar("amx_votekick_ratio", "0.40")
	register_cvar("amx_voteban_ratio", "0.40")
	register_cvar("amx_votemap_ratio", "0.40")

	set_cvar_float("amx_last_voting", 0.0)


	register_srvcmd("amx_sqladmins", "adminSql")
	register_cvar("amx_sql_table", "admins")
// amxbans
	pcvarip=register_cvar("amxbans_server_address","")
	pcvarprefix=register_cvar("amx_sql_prefix", "amx")
	pcvaradminsfile=register_cvar("amxbans_use_admins_file","0")
	
	g_AdminNick=ArrayCreate(32,32)
	g_AdminUseStaticBantime=ArrayCreate(1,32)
//
	register_cvar("amx_sql_host", "127.0.0.1")
	register_cvar("amx_sql_user", "root")
	register_cvar("amx_sql_pass", "")
	register_cvar("amx_sql_db", "amx")
	register_cvar("amx_sql_type", "mysql")

	register_concmd("amx_reloadadmins", "cmdReload", ADMIN_CFG)
	//register_concmd("amx_addadmin", "addadminfn", ADMIN_RCON, "<playername|auth> <accessflags> [password] [authtype] - add specified player as an admin to users.ini")

	format(g_cmdLoopback, 15, "amxauth%c%c%c%c", random_num('A', 'Z'), random_num('A', 'Z'), random_num('A', 'Z'), random_num('A', 'Z'))

	register_clcmd(g_cmdLoopback, "ackSignal")

	remove_user_flags(0, read_flags("z"))		// Remove 'user' flag from server rights

	new configsDir[64]
	get_configsdir(configsDir, 63)
	
	server_cmd("exec %s/amxx.cfg", configsDir)	// Execute main configuration file
	server_cmd("exec %s/sql.cfg", configsDir)
	//server_cmd("exec %s/amxbans.cfg", configsDir)

}

public client_connect(id)
{
	g_CaseSensitiveName[id] = false;
}

public plugin_cfg()
{
	//fixx to be sure cfgs are loaded
	create_forwards()
	set_task(0.1,"delayed_plugin_cfg")
}

create_forwards()
{
	MFHandle[Amxbans_Sql_Initialized]=CreateMultiForward("amxbans_sql_initialized",ET_IGNORE,FP_CELL,FP_STRING)
	MFHandle[Admin_Connect]=CreateMultiForward("amxbans_admin_connect",ET_IGNORE,FP_CELL)
	MFHandle[Admin_Disconnect]=CreateMultiForward("amxbans_admin_disconnect",ET_IGNORE,FP_CELL)
}

public delayed_plugin_cfg()
{
	//check if amxbans plugins are the first plugins and default admin plugins are disabled
	//added for admins who cant read the docs
	if(find_plugin_byfile("admin.amxx") != INVALID_PLUGIN_ID)
	{
		log_amx("[AMXBans] WARNING: admin.amxx plugin running! stopped.")
		pause("acd","admin.amxx")
	}
	if(find_plugin_byfile("admin_sql.amxx") != INVALID_PLUGIN_ID)
	{
		log_amx("[AMXBans] WARNING: admin_sql.amxx plugin running! stopped.")
		pause("acd","admin_sql.amxx")
	}
	//if(find_plugin_byfile("amxbans_core.amxx") != 0) log_amx("[AMXBans] WARNING: amxbans_core.amxx should be the fist entry in your plugins.ini!")
	//if(find_plugin_byfile("amxbans_main.amxx") != 1) log_amx("[AMXBans] WARNING: amxbans_main.amxx should be the second entry in your plugins.ini!")
		
	get_pcvar_string(pcvarprefix,g_dbPrefix,charsmax(g_dbPrefix))
	get_pcvar_string(pcvarip,g_ServerAddr,charsmax(g_ServerAddr))
	g_AdminsFromFile=get_pcvar_num(pcvaradminsfile)
	
	if(strlen(g_ServerAddr) < 9)
	{
		new ip[32]
		get_user_ip(0,ip,sizeof ip)
		formatex(g_ServerAddr,sizeof g_ServerAddr,"%s",ip)
	}
	if(get_cvar_num("amxbans_debug") >= 1) server_print("[AMXBans] plugin_cfg: ip %s / prefix %s",g_ServerAddr,g_dbPrefix)
	
	server_cmd("amx_sqladmins")
	server_exec();

	set_task(6.1, "delayed_load")
}

public delayed_load()
{
	new configFile[128], curMap[64], configDir[128]

	get_configsdir(configDir, sizeof configDir)
	get_mapname(curMap, sizeof curMap)

	new i=0;
	
	while (curMap[i] != '_' && curMap[i++] != '^0') {}
	
	if (curMap[i]=='_')
	{
		// this map has a prefix
		curMap[i]='^0';
		formatex(configFile, sizeof(configFile)-1, "%s/maps/prefix_%s.cfg", configDir, curMap);

		if (file_exists(configFile))
		{
			server_cmd("exec %s", configFile);
		}
	}

	get_mapname(curMap, sizeof curMap)

	formatex(configFile, sizeof configFile, "%s/maps/%s.cfg", configDir, curMap)

	if (file_exists(configFile))
	{
		server_cmd("exec %s", configFile)
	}
}

loadSettings(szFilename[])
{
	new File=fopen(szFilename,"r");
	
	if (File)
	{
		new Text[512];
		new Flags[32];
		new Access[32]
		new AuthData[44];
		new Password[32];
		new Name[32];
		new Static[2];
		
		while (!feof(File))
		{
			fgets(File,Text,sizeof Text);
			
			trim(Text);
			
			// comment
			if (Text[0]==';')
			{
				continue;
			}
			
			Flags[0]=0;
			Access[0]=0;
			AuthData[0]=0;
			Password[0]=0;
			Name[0] = 0;
			Static[0] = 0;
			
			// not enough parameters
			if (parse(Text, AuthData, sizeof AuthData, Password, sizeof Password, Access, sizeof Access, Flags, sizeof Flags, Name, sizeof Name, Static, sizeof Static) < 2)
			{
				continue;
			}
			
			admins_push(AuthData,Password,read_flags(Access),read_flags(Flags));
			ArrayPushString(g_AdminNick, Name);
			ArrayPushCell(g_AdminUseStaticBantime, str_to_num(Static));
			
			AdminCount++;
		}
		
		fclose(File);
	}

	if (AdminCount == 1)
	{
		server_print("[AMXBans] %L", LANG_SERVER, "LOADED_ADMIN");
	}
	else
	{
		server_print("[AMXBans] %L", LANG_SERVER, "LOADED_ADMINS", AdminCount);
	}
	
	return 1;
}

public adminSql()
{
	new table[32], error[128], errno
	AdminCount = 0;
	admins_flush();
	
	SQL_SetAffinity("mysql")
	info = SQL_MakeStdTuple()
	new Handle:sql = SQL_Connect(info, errno, error, 127)
	
	get_cvar_string("amx_sql_table", table, 31)	
	
	//sql error or amxbans_use_admins_file == 1
	if (sql == Empty_Handle || g_AdminsFromFile > 0)
	{
		if(!g_AdminsFromFile) server_print("[AMXBans] %L", LANG_SERVER, "SQL_CANT_CON", error)
		
		//backup to users.ini
		new configsDir[64]
		
		get_configsdir(configsDir, sizeof configsDir)
		format(configsDir, sizeof configsDir, "%s/users.ini", configsDir)
		loadSettings(configsDir) // Load admins accounts
		
		new players[32], num, pv
		new name[32]
		get_players(players, num)
		for (new i=0; i<num; i++)
		{
			pv = players[i]
			get_user_name(pv, name, sizeof name)
			accessUser(pv, name)
		}
		
		new ret
		ExecuteForward(MFHandle[Amxbans_Sql_Initialized],ret,info,g_dbPrefix)
		
		if (sql != Empty_Handle)
		{
			// Fix by EpicMorg: 
			SQL_FreeHandle(sql)
			//server_print("[amxbans_core.amxx] [AMXBans] SQL Connection closed.")
		} 
		return PLUGIN_CONTINUE
	}
	if(g_AdminsFromFile > 1)
	{
		if (sql != Empty_Handle)
		{
			//Fix by EpicMorg:  
			SQL_FreeHandle(sql)
			server_print("[amxbans_core.amxx] [AMXBans] SQL Connection closed.")
		}
		return PLUGIN_CONTINUE
	}
	
	ArrayClear(g_AdminNick)
	ArrayClear(g_AdminUseStaticBantime)
	
	new Handle:query
	
//amxbans	
	new pquery[1024]
	
	formatex(pquery,1023,"SELECT aa.steamid,aa.password,aa.access,aa.flags,aa.nickname,ads.custom_flags,ads.use_static_bantime \
		FROM %s_amxadmins as aa, %s_admins_servers as ads, %s_serverinfo as si \
		WHERE ((ads.admin_id=aa.id) AND (ads.server_id=si.id) AND \
		((aa.days=0) OR (aa.expired>UNIX_TIMESTAMP(NOW()))) AND (si.address='%s'))", g_dbPrefix, g_dbPrefix, g_dbPrefix, g_ServerAddr)
	
	query = SQL_PrepareQuery(sql,pquery)
	
	SQL_Execute(query)
//
	
	if(SQL_NumRows(query))
	{
		/* do this incase people change the query order and forget to modify below */
		new qcolAuth = SQL_FieldNameToNum(query, "steamid")
		new qcolPass = SQL_FieldNameToNum(query, "password")
		new qcolAccess = SQL_FieldNameToNum(query, "access")
		new qcolFlags = SQL_FieldNameToNum(query, "flags")
		new qcolNick = SQL_FieldNameToNum(query, "nickname")
		new qcolCustom = SQL_FieldNameToNum(query, "custom_flags")
		new qcolStatic = SQL_FieldNameToNum(query, "use_static_bantime")
	
	
		new AuthData[44];
		new Password[44];
		new Access[32];
		new Flags[32];
		new Nick[32];
		new Static[5]
		new iStatic
		
		while (SQL_MoreResults(query))
		{
			SQL_ReadResult(query, qcolAuth, AuthData, sizeof(AuthData)-1);
			SQL_ReadResult(query, qcolPass, Password, sizeof(Password)-1);
			SQL_ReadResult(query, qcolStatic, Static, sizeof(Static)-1);
			SQL_ReadResult(query, qcolCustom, Access, sizeof(Access)-1);
			SQL_ReadResult(query, qcolNick, Nick, sizeof(Nick)-1);
			SQL_ReadResult(query, qcolFlags, Flags, sizeof(Flags)-1);
			
			//if custom access not set get the global
			trim(Access)
			if(equal(Access,"")) SQL_ReadResult(query, qcolAccess, Access, sizeof(Access)-1);
			
			admins_push(AuthData,Password,read_flags(Access),read_flags(Flags));
			
			//save nick
			ArrayPushString(g_AdminNick,Nick)
			
			//save static bantime
			iStatic=1
			if(equal(Static,"no")) iStatic=0
			ArrayPushCell(g_AdminUseStaticBantime,iStatic)
			
			++AdminCount;
			SQL_NextRow(query)
		}
	}

	if (AdminCount == 1)
	{
		server_print("[AMXBans] %L", LANG_SERVER, "SQL_LOADED_ADMIN")
	}
	else
	{
		server_print("[AMXBans] %L", LANG_SERVER, "SQL_LOADED_ADMINS", AdminCount)
	}
	
	SQL_FreeHandle(query)
	SQL_FreeHandle(sql)
	
	new players[32], num, pv
	new name[32]
	get_players(players, num)
	for (new i=0; i<num; i++)
	{
		pv = players[i]
		get_user_name(pv, name, sizeof name)
		accessUser(pv, name)
	}
	
	new ret
	ExecuteForward(MFHandle[Amxbans_Sql_Initialized],ret,info,g_dbPrefix)
	
	return PLUGIN_CONTINUE
}

public plugin_end()
{
	if(info != Empty_Handle) SQL_FreeHandle(info)
}

public cmdReload(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	//strip original flags (patch submitted by mrhunt)
	remove_user_flags(0, read_flags("z"))
	
	AdminCount = 0
	adminSql()

	if (id != 0)
	{
		if (AdminCount == 1)
			console_print(id, "[AMXBans] %L", LANG_SERVER, "SQL_LOADED_ADMIN")
		else
			console_print(id, "[AMXBans] %L", LANG_SERVER, "SQL_LOADED_ADMINS", AdminCount)
	}

	return PLUGIN_CONTINUE
}

getAccess(id, name[], authid[], ip[], password[], password2[])
{
	new index = -1, result = 0;
	static Count, Flags, AuthData[44];
	
	g_CaseSensitiveName[id] = false;

	Count=admins_num();
	for (new i = 0; i < Count; ++i)
	{
		Flags = admins_lookup(i,AdminProp_Flags);
		admins_lookup(i,AdminProp_Auth,AuthData,sizeof(AuthData)-1);
		
		if (Flags & FLAG_AUTHID)
		{
			if (equal(authid, AuthData))
			{
				index = i
				result |= checkAccess(id,index,name,ip,authid,AuthData,Flags,password,password2);
				continue;
			}
		}
		else if (Flags & FLAG_IP)
		{
			new c = strlen(AuthData)
			
			if (AuthData[c - 1] == '.')	/* check if this is not a xxx.xxx. format */
			{
				if (equal(AuthData, ip, c))
				{
					index = i
					result |= checkAccess(id,index,name,ip,authid,AuthData,Flags,password,password2);
					continue;
				}
			}				/* in other case an IP must just match */
			else if (equal(ip, AuthData))
			{
				index = i
				result |= checkAccess(id,index,name,ip,authid,AuthData,Flags,password,password2);
				continue;
			}
		} 
		else 
		{
			if (Flags & FLAG_CASE_SENSITIVE)
			{
				if (Flags & FLAG_TAG)
				{
					if (contain(name, AuthData) != -1)
					{
						index = i
						result |= checkAccess(id,index,name,ip,authid,AuthData,Flags,password,password2);
						g_CaseSensitiveName[id] = true
						continue;
					}
				}
				else if (equal(name, AuthData))
				{
					index = i
					result |= checkAccess(id,index,name,ip,authid,AuthData,Flags,password,password2);
					g_CaseSensitiveName[id] = true
					continue;
				}
			}
			else
			{
				if (Flags & FLAG_TAG)
				{
					if (containi(name, AuthData) != -1)
					{
						index = i
						result |= checkAccess(id,index,name,ip,authid,AuthData,Flags,password,password2);
						continue;
					}
				}
				else if (equali(name, AuthData))
				{
					index = i
					result |= checkAccess(id,index,name,ip,authid,AuthData,Flags,password,password2);
					continue;
				}
			}
		}
	}

	if( index == -1 )
		result |= checkAccess(id,index,name,ip,authid,AuthData,Flags,password,password2);
	
	return result
}

checkAccess(id, index, name[], ip[], authid[], AuthData[], Flags, password[], password2[]) {
	new result = 0;

	if (index != -1)
	{
		static Access;
		Access = admins_lookup(index,AdminProp_Access);
		
		if( index < ArraySize(g_AdminNick) )
			ArrayGetString(g_AdminNick,index,g_szAdminNick[id],31)
		else
			setc(g_szAdminNick[id],31,0)
			
		if( index < ArraySize(g_AdminUseStaticBantime) )
			g_iAdminUseStaticBantime[id]=ArrayGetCell(g_AdminUseStaticBantime,index)
		else
			g_iAdminUseStaticBantime[id] = 0;
		
		if (Flags & FLAG_NOPASS)
		{
			result |= 8
			new sflags[32]
			
			get_flags(Access, sflags, 31)
			set_user_flags(id, Access)
			
			new ret
			if(!g_isAdmin[id])
				ExecuteForward(MFHandle[Admin_Connect],ret,id)
			g_isAdmin[id] = true
			
			log_amx("Login: ^"%s<%d><%s><>^" became an admin (account ^"%s^") (access ^"%s^") (address ^"%s^") (nick ^"%s^") (static %d)",
				name, get_user_userid(id), authid, AuthData, sflags, ip,g_szAdminNick[id],g_iAdminUseStaticBantime[id])
		}
		else
		{
			new password3[32], md5_password[34], md5_password2[34];
			admins_lookup(index,AdminProp_Password,password3,sizeof password3);
			
			hash_string(password, Hash_Md5, md5_password, charsmax(md5_password));
			hash_string(password2, Hash_Md5, md5_password2, charsmax(md5_password2));

			//log_amx("%s %s %s %s %s",password,md5_password,password2,md5_password2,password3);
			if ( equal(password, password3) || equal(md5_password, password3) || equal(password2, password3) || equal(md5_password2, password3) )
			{
				result |= 12
				set_user_flags(id, Access)
				
				new sflags[32]
				get_flags(Access, sflags, 31)
				
				new ret
				if(!g_isAdmin[id]) ExecuteForward(MFHandle[Admin_Connect],ret,id)
				g_isAdmin[id] = true
				
				log_amx("Login: ^"%s<%d><%s><>^" became an admin (account ^"%s^") (access ^"%s^") (address ^"%s^") (nick ^"%s^") (static %d)",
					name, get_user_userid(id), authid, AuthData, sflags, ip,g_szAdminNick[id],g_iAdminUseStaticBantime[id])
			}
			else
			{
				result |= 1
				
				if (Flags & FLAG_KICK)
				{
					result |= 2
					g_isAdmin[id] = false
					log_amx("Login: ^"%s<%d><%s><>^" kicked due to invalid password (account ^"%s^") (address ^"%s^")",
					name, get_user_userid(id), authid, AuthData, ip)
				}
			}
		}
	}
	else if (get_pcvar_num(amx_mode) == 2)
	{
		result |= 2
	}
	else
	{
		new defaccess[32]
		
		get_pcvar_string(amx_default_access, defaccess, 31)
		
		if (!strlen(defaccess))
		{
			copy(defaccess, 32, "z")
		}
		
		new idefaccess = read_flags(defaccess)
		
		if (idefaccess)
		{
			result |= 8
			set_user_flags(id, idefaccess)
		}
	}
	
	return result;
}

accessUser(id, name[] = "")
{
	remove_user_flags(id)
	
	new userip[32], userauthid[32], password[32], password2[32], passfield[32], username[32]
	
	get_user_ip(id, userip, 31, 1)
	get_user_authid(id, userauthid, 31)
	
	if (name[0])
	{
		copy(username, 31, name)
	}
	else
	{
		get_user_name(id, username, 31)
	}
	
	get_pcvar_string(amx_password_field, passfield, 31)
	get_user_info(id, passfield, password, 31)
	get_user_info(id, "_ss", password2, sizeof password2)
	
	new result = getAccess(id, username, userauthid, userip, password, password2)
	
	if (result & 1)
	{
		client_cmd(id, "echo ^"* %L^"", id, "INV_PAS")
	}
	
	if (result & 2)
	{
		client_cmd(id, "%s", g_cmdLoopback)
		return PLUGIN_HANDLED
	}
	
	if (result & 4)
	{
		client_cmd(id, "echo ^"* %L^"", id, "PAS_ACC")
	}
	
	if (result & 8)
	{
		client_cmd(id, "echo ^"* %L^"", id, "PRIV_SET")
	}
	
	return PLUGIN_CONTINUE
}

public client_infochanged(id)
{
	if (!is_user_connected(id) || !get_pcvar_num(amx_mode))
	{
		return PLUGIN_CONTINUE
	}

	new newname[32], oldname[32]
	
	get_user_name(id, oldname, 31)
	get_user_info(id, "name", newname, 31)

	if (g_CaseSensitiveName[id])
	{
		if (!equal(newname, oldname))
		{
			accessUser(id, newname)
		}
	}
	else
	{
		if (!equali(newname, oldname))
		{
			accessUser(id, newname)
		}
	}
	return PLUGIN_CONTINUE
}

public client_disconnected(id)
{
	if(g_isAdmin[id])
	{
		new ret
		ExecuteForward(MFHandle[Admin_Disconnect],ret,id)
	}
	g_isAdmin[id]=false
}

public ackSignal(id)
{
	server_cmd("kick #%d ^"%L^"", get_user_userid(id), id, "NO_ENTRY")
	return PLUGIN_HANDLED
}

public client_authorized(id)
	return get_pcvar_num(amx_mode) ? accessUser(id) : PLUGIN_CONTINUE

public client_putinserver(id)
{
	if (!is_dedicated_server() && id == 1)
		return get_pcvar_num(amx_mode) ? accessUser(id) : PLUGIN_CONTINUE
	
	return PLUGIN_CONTINUE
}

//natives
public plugin_natives()
{
	register_library("AMXBansCore")
	
	register_native("amxbans_get_db_prefix","native_amxbans_get_prefix")
	register_native("amxbans_get_admin_nick","native_amxbans_get_nick")
	register_native("amxbans_get_static_bantime","native_amxbans_static_bantime")
}

public native_amxbans_get_prefix()
{
	new len= get_param(2)
	set_array(1,g_dbPrefix,len)
}

public native_amxbans_get_nick()
{
	
	new id = get_param(1)
	new len= get_param(3)
	
	set_array(2,g_szAdminNick[id],len)
}

public native_amxbans_static_bantime()
{
	new id = get_param(1)
	if(get_cvar_num("amxbans_debug") >= 3) log_amx("[AMXBans Core] Native static bantime: id: %d | result: %d",id,g_iAdminUseStaticBantime[id])
	return g_iAdminUseStaticBantime[id]
}
