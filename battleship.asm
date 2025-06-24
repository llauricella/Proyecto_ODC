#
###						BATTLESHIP
###		Recreación del juego de mesa BattleShip para el microprocesador MIPS R2000
###		Autores:
###		- Naim Demian
###		- Luigi Lauricella
#

.include "macros.asm"

.data
	# INICIO DE LA SECCIÓN DATA
	# ADDRESS: 0x10010000
	screen_board: .space 512 # El tablero se aloja al inicio de la sección data, reservar espacio de tablero
	
	# Mensajes del menú
	menu_start_msg: .asciiz "----- BATTLESHIP -----\n\nIntroduce una de las siguientes opciones para continuar:\n\n1 - Jugar contra el CPU\n2 - Jugar contra otro jugador\n3 - Salir\n-> "
	menu_arrow: .asciiz "-> "
	
.text
	.globl main
	
main:
	show_menu:
		print_message(menu_start_msg)
		
	process_menu_input:
		read_integer
		
		li $t0, 1 # Lower bound
		li $t1, 3 # Upper bound
		
		# Validar input
		blt $v0, 1, invalid_menu_input
		bgt $v0, 3, invalid_menu_input
		b continue_menu_input
		
	invalid_menu_input:
		print_message(menu_arrow)
		b process_menu_input
		
	continue_menu_input:
		beq $v0, 1, menu_option_1
		beq $v0, 2, menu_option_2
		beq $v0, 3, menu_option_3
		
	menu_option_1:
	menu_option_2:
	menu_option_3:
		b exit
		
exit:
	li $v0, 10
	syscall