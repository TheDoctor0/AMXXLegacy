#include <amxmodx>
#include <sklep_sms>
#include <colorchat>

#define PLUGIN "Sklep-SMS: Usluga ZP Exp Transfer"
#define AUTHOR "O'Zone"

#define TASK_CHECK_FIRST 1000
#define TASK_CHECK_SECOND 2000

native zp_get_classes_num();
native zp_get_class_name(klasa, Return[], len);
native zp_get_user_class(id);
native zp_get_user_exp(id);
native zp_set_user_exp(id, wartosc);
native zp_set_user_class(id, klasa);

new const serviceID[MAX_ID] = "zp_exp_transfer";

new fromClass[33], toClass[33], currentClass[33], fromClassExp[33];

public plugin_init()
	register_plugin(PLUGIN, VERSION, AUTHOR);

public plugin_cfg()
	ss_register_service(serviceID);

public plugin_natives()
	set_native_filter("native_filter");

public ss_service_addingtolist(id)
	return zp_get_classes_num() >= 2 ? ITEM_ENABLED : ITEM_DISABLED;

public ss_service_chosen(id)
{
	fromClass[id] = toClass[id] = currentClass[id] = fromClassExp[id] = 0;

	new name[64], menu = menu_create("Z jakiej klasy chcesz przeniesc exp?", "fromClassMenu_handle");

	for(new i = 1; i <= zp_get_classes_num(); ++i)
	{
		zp_get_class_name(i, name, sizeof(name));
		
		menu_additem(menu, name);
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednia strona");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepna strona");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	
	menu_display(id,menu);
	
	return SS_STOP;
}

public fromClassMenu_handle(id, menu, item)
{
	if(item < 0) 
	{
		menu_destroy(menu);

		return;
	}
	
	fromClass[id] = item + 1;
		
	new name[64], menu2 = menu_create("Na jaka klase chcesz przeniesc exp?","toClassMenu_handle"), menu_callback = menu_makecallback("toClassMenu_callback");

	for(new i = 1; i <= zp_get_classes_num(); ++i)
	{
		zp_get_class_name(i, name, sizeof(name));
			
		menu_additem(menu2, name, _, _, menu_callback);
	}
		
	menu_setprop(menu2, MPROP_BACKNAME, "Poprzednia strona");
	menu_setprop(menu2, MPROP_NEXTNAME, "Nastepna strona");
	menu_setprop(menu2, MPROP_EXITNAME, "Wyjdz");
	
	menu_destroy(menu);
	
	menu_display(id, menu2);
}

public toClassMenu_callback(id, menu, item)
	return fromClass[id] == item + 1 ? ITEM_DISABLED : ITEM_ENABLED;

public toClassMenu_handle(id, menu, item)
{
	if(item < 0)
	{
		menu_destroy(menu);

		return;
	}

	toClass[id] = item + 1;
		
	menu_destroy(menu);
	
	currentClass[id] = zp_get_user_class(id);
	
	zp_set_user_class(id, fromClass[id]);

	chosen_checkFirstClass(TASK_CHECK_FIRST + id);
}

public chosen_checkFirstClass(id)
{
	id -= TASK_CHECK_FIRST;

	if(zp_get_user_class(id) == fromClass[id])
	{
		zp_set_user_class(id,toClass[id]);

		chosen_checkSecondClass(TASK_CHECK_SECOND + id);
	}
	else if(zp_get_user_class(id) == currentClass[id]) set_task(0.2, "chosen_checkFirstClass",TASK_CHECK_FIRST+id);
	else if(!zp_get_user_class(id)) ColorChat(id, GREEN, "^x04[SKLEP-SMS]^x01 Nie masz uprawnien, aby skorzystac z klasy z ktorej chcesz przeniesc EXP.");
}

public chosen_checkSecondClass(id)
{
	id -= TASK_CHECK_SECOND;

	if(zp_get_user_class(id) == toClass[id])
	{
		zp_set_user_class(id,currentClass[id]);

		ss_show_sms_info(id);
	}
	else if(zp_get_user_class(id) == fromClass[id]) set_task(0.2, "chosen_checkSecondClass", TASK_CHECK_SECOND + id);
	else if(!zp_get_user_class(id)) ColorChat(id, GREEN, "^x04[SKLEP-SMS]^x01 Nie masz uprawnien, aby skorzystac z klasy z ktorej chcesz przeniesc EXP.");
}

public ss_service_bought(id, amount)
{	
	zp_set_user_class(id,fromClass[id]);
	
	bought_checkFirstClass(TASK_CHECK_FIRST + id);
}

public bought_checkFirstClass(id)
{
	id -= TASK_CHECK_FIRST;

	if(zp_get_user_class(id) == fromClass[id])
	{
		fromClassExp[id] = zp_get_user_exp(id);
		
		zp_set_user_exp(id, 0);
		
		zp_set_user_class(id,toClass[id]);
		bought_checkSecondClass(TASK_CHECK_SECOND + id);
	}
	else if(zp_get_user_class(id) == currentClass[id]) set_task(0.2, "bought_checkFirstClass", TASK_CHECK_FIRST + id);
}

public bought_checkSecondClass(id)
{
	id -= TASK_CHECK_SECOND;

	if(zp_get_user_class(id) == toClass[id])
	{
		zp_set_user_exp(id, zp_get_user_exp(id) + fromClassExp[id]);

		zp_set_user_class(id, currentClass[id]);
	}
	else if(zp_get_user_class(id) == fromClass[id]) set_task(0.2, "bought_checkSecondClass", TASK_CHECK_SECOND + id);
}

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