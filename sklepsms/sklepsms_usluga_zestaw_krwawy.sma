#include <amxmodx>
#include <sklep_sms>
#include <colorchat>

#define PLUGIN "Sklep-SMS: Usluga Krwawy Zestaw Broni"
#define AUTHOR "O'Zone"

new const service_id[MAX_ID] = "zestaw_krwawy";

native dodaj_zestaw(id, zestaw);
native sprawdz_zestaw(id, zestaw);

enum
{
	NIEBIESKI = 0,
	CZERWONY = 1,
	KRWAWY = 2,
	ZLOTY = 3,
	KONTROWERSYJNY = 4
};

public plugin_init()
	register_plugin(PLUGIN, VERSION, AUTHOR);

public plugin_natives()
	set_native_filter("native_filter");

public plugin_cfg()
	ss_register_service(service_id)

public ss_service_chosen(id)
{
	if(sprawdz_zestaw(id, KRWAWY))
	{
		ColorChat(id, RED,"[SKLEPSMS]^x01 Masz juz ten^x04 zestaw broni^x01.");
		return SS_STOP;
	}
	return SS_OK;
}

public ss_service_bought(id, zestaw)
	dodaj_zestaw(id, zestaw);

public native_filter(const native_name[], index, trap)
{
	if(trap == 0)
	{
		register_plugin(PLUGIN, VERSION, AUTHOR);
		pause_plugin();
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}
