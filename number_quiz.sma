/*
	Cvars: 
	quiz_type  (default = 1)  Sets the type of quiz
		-> 0 = No quiz
		-> 1 = Two number addtion/subtraction
		-> 2 = Three number addition/subtraction
		-> 3 = Two number multiplication/division
		-> 4 = Three number multiplication/division + addition/subtraction
	quiz_random  (default = 0)  If set to 1 and if quiz_type is not 0, it will put random types of quizes irrespective of the quiz_type value
	
*/

#include <amxmodx>
#include <fun>
#include <hamsandwich>

#define PLUGIN "Number Quiz"
#define VERSION "1.3"
#define AUTHOR "connoisseur & O'Zone"

#define TAG "[Quiz]"

#define TASK_END 9545
#define TASK_CHECK 4643

native zp_get_user_ammo_packs(id)
native zp_set_user_ammo_packs(id, amount)

new g_iAnswer
new bool:g_answered
new bool:g_quiz
static Array:g_DivisorsArray

new time_cvar
new type_cvar
new random_cvar

new last_quiz

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	random_cvar = register_cvar("quiz_random", "0")
	type_cvar = register_cvar("quiz_type", "2")
	time_cvar = register_cvar("quiz_time", "300")
	
	set_task(60.0, "CheckQuiz", TASK_CHECK, _, _, "b");
	
	register_clcmd("say", "hookSay")
	register_clcmd("say_team", "hookSay")
	
	g_DivisorsArray = ArrayCreate(1)
}

public plugin_cfg()
	last_quiz = 0
	
public CheckQuiz()
{
	if(last_quiz + get_pcvar_num(time_cvar) < get_gametime() && get_playersnum() > 4)
	{
		new quiz_time = random_num(5, 15)
		set_task(float(quiz_time), "Quiz")
	}
}

public Quiz()
{
	g_answered = false
	g_quiz = true
	new Quiz[20]
	formatex(Quiz, 19, generateQuiz())
	if(get_pcvar_num(type_cvar) > 0){
		if(get_playersnum() != 0){
			client_print_color(0, print_team_red, "^x03%s^x01 Oblicz:^x04 %s = ?", TAG, Quiz)
			client_print_color(0, print_team_red, "^x03%s^x01 Na odpowiedz masz 30s!", TAG)
		}
		set_task(30.0, "EndQuiz", TASK_END)
	}
}

public EndQuiz()
{
	g_answered = true
	g_quiz = false
	if(get_playersnum() != 0)
		client_print_color(0, print_team_red, "^x03%s^x01 Niestety, nikt nie odpowiedzial poprawnie. Prawidlowa odpowiedz:^x04 %i^x01.", TAG, g_iAnswer)
	last_quiz += get_pcvar_num(time_cvar)
}

public hookSay(id)
{
	if(!g_answered && g_quiz)
	{
		new szArgs[7]
		new szAns[7]
		
		read_args(szArgs, charsmax(szArgs))
		remove_quotes(szArgs)
		
		num_to_str(g_iAnswer, szAns, charsmax(szAns))
		
		if(!strcmp(szArgs, szAns) && is_user_connected(id))
		{
			g_answered = true
			remove_task(TASK_END)
			
			new szNick[32]
			get_user_name(id, szNick, charsmax(szNick))
				
			client_print_color(0, print_team_red, "^x03%s^x04 %s^x01 odpowiedzial poprawnie:^x04 ^"%i^"^x01. W nagrode dostaje 50 AmmoPackow!", TAG, szNick, g_iAnswer)		
			zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + 50);
			last_quiz += get_pcvar_num(time_cvar)
			
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_CONTINUE
}

generateQuiz()
{
	new szQuiz[20]
	new iType = get_pcvar_num(random_cvar) ? random_num(1, 4) : get_pcvar_num(type_cvar)
	
	switch(iType)
	{
		case 2:									// 3 number addition/subtraction
		{
			new iOperand[3]
			new charOP[2]
			
			iOperand[0] = random_num(1, 100)
			iOperand[1] = random_num(1, 100)
			iOperand[2] = random_num(1, 100)
			
			charOP[0] = random_num(0, 1) ? '+' : '-'
			charOP[1] = random_num(0, 1) ? '+' : '-'
			
			if(charOP[0] == '+' && charOP[1] == '+')
				g_iAnswer = iOperand[0] + iOperand[1] + iOperand[2]
			else if(charOP[0] == '+' && charOP[1] == '-')
				g_iAnswer = iOperand[0] + iOperand[1] - iOperand[2]
			else if(charOP[0] == '-' && charOP[1] == '+')
				g_iAnswer = iOperand[0] - iOperand[1] + iOperand[2]
			else
				g_iAnswer = iOperand[0] - iOperand[1] - iOperand[2]
				
			formatex(szQuiz, charsmax(szQuiz), "%i %c %i %c %i", iOperand[0], charOP[0], iOperand[1], charOP[1], iOperand[2])
		}
		case 3:									// 2 number multiply/divide
		{
			new iOperand[2]
			new charOP
			
			charOP = random_num(0, 1) ? '*' : '/'
			
			if (charOP == '*')
			{
				iOperand[0] = random_num(4, 99)
				iOperand[1] = random_num(3, 9)
				
				g_iAnswer = iOperand[0] * iOperand[1]
			}
			else
			{
				iOperand[0] = random_num(8, 99)
				while(isPrime(iOperand[0]))
					iOperand[0] = random_num(8, 99)
				iOperand[1] = getRandomDivisor(iOperand[0])
				
				g_iAnswer = iOperand[0] / iOperand[1]
			}
			
			formatex(szQuiz, charsmax(szQuiz), "%i %c %i", iOperand[0], charOP, iOperand[1])
		}
		case 4:									// 3 num add, minus, mult, divide
		{
			new iOperand[3]
			new charOP[2]
			
			charOP[0] = random_num(0, 1) ? '*' : '/'
			charOP[1] = random_num(0, 1) ? '+' : '-'
			iOperand[2] = random_num(1, 100)
			
			if (charOP[0] == '*')
			{
				iOperand[0] = random_num(4, 99)
				iOperand[1] = random_num(3, 9)
				
				g_iAnswer = iOperand[0] * iOperand[1]
			}
			else
			{
				iOperand[0] = random_num(8, 99)
				while(isPrime(iOperand[0]))
					iOperand[0] = random_num(8, 99)
				iOperand[1] = getRandomDivisor(iOperand[0])
				
				g_iAnswer = iOperand[0] / iOperand[1]
			}
			
			if (charOP[1] == '+')
				g_iAnswer += iOperand[2]
			else
				g_iAnswer -= iOperand[2]
				
			formatex(szQuiz, charsmax(szQuiz), "%i %c %i %c %i", iOperand[0], charOP[0], iOperand[1], charOP[1], iOperand[2])
		}
		default:
		{
			new iOperand[2]
			new charOP
			
			iOperand[0] = random_num(1, 100)
			iOperand[1] = random_num(1, 100)
			charOP = random_num(0, 1) ? '+' : '-'
			
			if (charOP == '+')
				g_iAnswer = iOperand[0] + iOperand[1]
			else
				g_iAnswer = iOperand[0] - iOperand[1]	
				
			formatex(szQuiz, charsmax(szQuiz), "%i %c %i", iOperand[0], charOP, iOperand[1])
		}
	}
	return szQuiz
}
getRandomDivisor(iNum)
{
	for(new i = 2; i <= iNum/2 ; i++)	//get all divisors
	{
		if(iNum % i == 0)
			ArrayPushCell(g_DivisorsArray, i)
	}
	 
	new iDiv =  ArrayGetCell(g_DivisorsArray, random_num(0, ArraySize(g_DivisorsArray) - 1))
	
	ArrayClear(g_DivisorsArray)
	
	return iDiv
}

isPrime(iNum)
{
	new bool:prime = true
	for(new i = 2; i <= iNum/2 ; i++)
	{
		if(iNum % i == 0)
		{
			prime = false
			break
		}
	}
	return prime
}

public plugin_end()
{
	ArrayDestroy(g_DivisorsArray)
}
