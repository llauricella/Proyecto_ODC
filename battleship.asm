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
	screen_board: .space BOARD_SIZE # El tablero se aloja al inicio de la sección data, reservar espacio de tablero
	
	# Paleta de colores
	screen_colors:
		.word 0x0000FF # Azul
		.word 0x00FF00 # Verde
		.word 0xFF0000 # Rojo
		 
	# Mensajes del menú
	menu_start_msg: .asciiz "----- BATTLESHIP -----\n\nIntroduce una de las siguientes opciones para continuar:\n\n1 - Jugar contra el CPU\n2 - Jugar contra otro jugador\n3 - Salir\n-> "
	menu_arrow: .asciiz "-> "
	
.text
	.globl main

main:
	jal empty_screen_board
	
	show_menu:
		print_message(menu_start_msg)
		
	process_menu_input:
		read_integer
		
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

# Función para vaciar el tablero en pantalla
empty_screen_board:
	la $a0, screen_colors
	li $a1, 0
	
	store_ra
	jal get_from_array
	restore_ra
	
	li $t0, 0
	
	loop_esb:
		sw $v0, screen_board($t0)
		
		beq $t0, BOARD_SIZE, return_esb
		
		add $t0, $t0, 4
		j loop_esb
		
	return_esb:
		jr $ra

# Almacena $a0($a1 * 4) en $v0
get_from_array:
	# Pushea $s0, $s1 al stack para preservar sus valores
	sub $sp, $sp, 8
	sw $s0, 0($sp)
	sw $s1, 4($sp)

	mul $s0, $a1, 4

	add $s1, $a0, $s0
	lw $v0, ($s1)
	
	# Restaura los registros $s0, $s1 del stack
	lw $s1, 4($sp)
	lw $s0, 0($sp)
	add $sp, $sp, 8
	
	jr $ra

exit:
	li $v0, 10
	syscall
