#include <amxmodx>
#include <sklep_sms>
#include <colorchat>

native diablo_get_classes_num();
native diablo_get_class_name(klasa, Return[], len);
native diablo_get_user_class(id);
native diablo_get_user_exp(id);
native diablo_set_user_exp(id, wartosc);
native diablo_set_user_class(id, klasa);

#define TASK_CHECK_FIRST 1000
#define TASK_CHECK_SECOND 2000

new const service_id[MAX_ID] = "dm_exp_transfer";
#define PLUGIN "Sklep-SMS: Usluga DM Exp Transfer"
#define AUTHOR "O'Zone"

new fromClass[33], toClass[33], currentClass[33], fromClassExp[33];

public plugin_natives() {
	set_native_filter("native_filter");
}

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
}

public plugin_cfg() {
	ss_register_service(service_id);
}

public ss_service_addingtolist(id) {
	return diablo_get_classes_num() >= 2 ? ITEM_ENABLED : ITEM_OFF
}

public ss_service_chosen(id) {
	fromClass[id] = toClass[id] = currentClass[id] = fromClassExp[id] = 0;

	new menu = menu_create("Z jakiej klasy chcesz przeniesc exp?","fromClassMenu_handle")
	for(new i = 1; i <= diablo_get_classes_num(); ++i) {
		new name[64]
		diablo_get_class_name(i,name,sizeof(name))

		menu_additem(menu,name)
	}

	menu_setprop(menu, MPROP_BACKNAME, "Poprzednia strona");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepna strona");
	menu_setprop(menu,MPROP_EXITNAME,"Wyjdz")

	menu_display(id,menu);

	return SS_STOP;
}

public fromClassMenu_handle(id, menu, item) {
	if(item < 0) {
		// Niszczymy poprzednie menu
		menu_destroy(menu)
		return;
	}

	// +1 poniewaz klasy zaczynaja sie od id: 1
	fromClass[id] = item+1;

	new menu2 = menu_create("Na jaka klase chcesz przeniesc exp?","toClassMenu_handle")
	new menu_callback = menu_makecallback("toClassMenu_callback");
	for(new i = 1; i <= diablo_get_classes_num(); ++i) {
		new name[64]
		diablo_get_class_name(i,name,sizeof(name))

		menu_additem(menu2,name,"",0,menu_callback)
	}

	menu_setprop(menu2, MPROP_BACKNAME, "Poprzednia strona");
	menu_setprop(menu2, MPROP_NEXTNAME, "Nastepna strona");
	menu_setprop(menu2,MPROP_EXITNAME,"Wyjdz")

	// Niszczymy poprzednie menu
	menu_destroy(menu)

	menu_display(id,menu2);
}

public toClassMenu_callback(id, menu, item) {
	return fromClass[id] == item+1 ? ITEM_DISABLED : ITEM_ENABLED;
}

public toClassMenu_handle(id, menu, item) {
	if( item < 0 ) {
		menu_destroy(menu)
		return;
	}

	// +1 poniewaz klasy zaczynaja sie od id: 1
	toClass[id] = item+1;

	menu_destroy(menu);

	// Zapisujemy obecna klase
	currentClass[id] = diablo_get_user_class(id);

	// Sprawdzamy czy pierwsza klasa jest dostepna ( nie jest np. klasa VIP )
	diablo_set_user_class(id,fromClass[id]);
	chosen_checkFirstClass(TASK_CHECK_FIRST+id)
}

public chosen_checkFirstClass(id) {
	id -= TASK_CHECK_FIRST;
	if( diablo_get_user_class(id) == fromClass[id] ) { // Prawidlowo ustawilo klase
		diablo_set_user_class(id,toClass[id]);
		chosen_checkSecondClass(TASK_CHECK_SECOND+id)
	}
	else if ( diablo_get_user_class(id) == currentClass[id] ) { // Wciaz nie zmienilo z poprzedniej klasy
		set_task(0.2,"chosen_checkFirstClass",TASK_CHECK_FIRST+id);
	}
	else if( !diablo_get_user_class(id) ) {
		ColorChat(id,RED,"^4[%s] ^1Nie masz uprawnien, aby skorzystac z klasy z ktorej chcesz przeniesc EXP.",PREFIX);
	}
}

public chosen_checkSecondClass(id) {
	id -= TASK_CHECK_SECOND;
	if( diablo_get_user_class(id) == toClass[id] ) { // Prawidlowo ustawilo klase
		// Ustawiamy klase ktora mial gracz przed zakupem
		diablo_set_user_class(id,currentClass[id]);
		ss_show_sms_info(id);
	}
	else if ( diablo_get_user_class(id) == fromClass[id] ) { // Wciaz nie zmienilo z poprzedniej klasy
		set_task(0.2,"chosen_checkSecondClass",TASK_CHECK_SECOND+id);
	}
	else if( !diablo_get_user_class(id) ) {
		ColorChat(id,RED,"^4[%s] ^1Nie masz uprawnien, aby skorzystac z klasy na ktora chcesz przeniesc EXP.",PREFIX);
	}
}

public ss_service_bought(id,amount) {
	// Ustawiamy pierwsza klase
	diablo_set_user_class(id,fromClass[id]);

	// Sprawdzamy czy pierwsza klasa sie prawidlowo zaladowala
	bought_checkFirstClass(TASK_CHECK_FIRST+id);
}

public bought_checkFirstClass(id) {
	id -= TASK_CHECK_FIRST;
	if( diablo_get_user_class(id) == fromClass[id] ) { // Prawidlowo ustawilo klase
		// Zapisujemy EXP pierwszej klasy
		fromClassExp[id] = diablo_get_user_exp(id);

		// Zerujemy EXP pierwszej klasy
		diablo_set_user_exp(id,0);

		new name[32]; get_user_name(id,name,sizeof name);
		new class1[64]; diablo_get_class_name(fromClass[id],class1,sizeof class1);
		ss_log("Zabrano graczowi %s %d EXPa z klasy %s",name,fromClassExp[id],class1);

		// Ustawiamy druga klase
		diablo_set_user_class(id,toClass[id]);
		bought_checkSecondClass(TASK_CHECK_SECOND+id)
	}
	else if( diablo_get_user_class(id) == currentClass[id] ) { // Wciaz nie zmienilo z poprzedniej klasy
		set_task(0.2,"bought_checkFirstClass",TASK_CHECK_FIRST+id);
	}
}

public bought_checkSecondClass(id) {
	id -= TASK_CHECK_SECOND;
	if( diablo_get_user_class(id) == toClass[id] ) { // Prawidlowo ustawilo klase
		// Ustawiamy EXP na drugiej klasie
		diablo_set_user_exp(id,diablo_get_user_exp(id)+fromClassExp[id]);

		// Ustawiamy klase ktora mial gracz przed zakupem
		diablo_set_user_class(id,currentClass[id]);

		new name[32]; get_user_name(id,name,sizeof name);
		new class1[64]; diablo_get_class_name(fromClass[id],class1,sizeof class1);
		new class2[64]; diablo_get_class_name(toClass[id],class2,sizeof class2);
		ss_log("Przeniesiono graczowi %s %d EXPa z klasy %s na klase %s",name,fromClassExp[id],class1,class2)
	}
	else if( diablo_get_user_class(id) == fromClass[id] ) { // Wciaz nie zmienilo z poprzedniej klasy
		set_task(0.2,"bought_checkSecondClass",TASK_CHECK_SECOND+id);
	}
}


// Zabezpieczenie, jezeli plugin jest odpalony na serwerze bez odpowiednich funkcji
public native_filter(const native_name[], index, trap) {
	if(trap == 0) {
		register_plugin(PLUGIN, VERSION, AUTHOR); // Rejestrujemy plugin, aby nie bylo na liscie unknown
		pause_plugin();
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}
