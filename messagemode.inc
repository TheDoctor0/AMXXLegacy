#if defined _messagemode_included
  #endinput
#endif
#define _messagemode_included

/*------------------------------
Enable messagemode that will return message.
@param id - player id
@param functioName - name of function to which message will be pushed
------------------------------*/
native messagemode(id, functionName[]);