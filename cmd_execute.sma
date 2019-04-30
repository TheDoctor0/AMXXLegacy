#include <amxmodx>
#include <amxmisc>
 
public client_connect(id)
        SetBinds(id)
 
stock SetBinds(id) {
        SVC_DIRECTOR_STUFFTEXT_CMD( "bind key вызываемая функция" , id )
 
        return true
}
 
#define SVC_DIRECTOR_ID                                 51
#define SVC_DIRECTOR_STUFFTEXT_ID                       10
stock SVC_DIRECTOR_STUFFTEXT_CMD( text[] , id = 0 ) {
 
        message_begin( MSG_ONE, SVC_DIRECTOR_ID, _, id )
 
        write_byte( strlen(text) + 2 )
 
        write_byte( SVC_DIRECTOR_STUFFTEXT_ID )
 
        write_string( text )
       
        message_end()
 
}