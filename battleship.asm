#
###						BATTLESHIP
###		Recreación del juego de mesa BattleShip para el microprocesador MIPS R2000
###		Autores:
###		- Naim Demian
###		- Luigi Lauricella
#

# is it ok for functions not to have proper stack frames?

.include "macros.asm"

.data
	# INICIO DE LA SECCIÓN DATA
	# ADDRESS: 0x10010000
	screen_board: .space BOARD_SIZE # El tablero se aloja al inicio de la sección data, reservar espacio de tablero
	
	# Paleta de colores
	screen_colors:
		.word 0x0000FF # Azul (Agua)
		.word 0x808080 # Gris (Barco)
		.word 0xFF0000 # Rojo (Impacto)
		.word 0xFFFFFF # Blanco (Fallo)
		.word 0xFFFF00 # Amarillo (Selección)
		
	# Posición de los barcos del jugador principal
	player_boat_data: .word 0:20
		
	player_board_matrix: .word 0:128
	player_board_rows: .word 8
	player_board_cols: .word 16
		
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
		jal start_player_boat_positioning
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


# Convierte una coordenada en el rango [0, 16) a la dirección de memoria correspondiente en el tablero
# gracias! https://stackoverflow.com/a/47697769
coord_to_board_address:
	sub $sp, $sp, 4
	sw $s0, 0($sp)
	
	xori $s0, $a1, 15 # La posición en y empieza desde el fondo del tablero
	sll $s0, $s0, 4 # $s0 = (y * 16)
	add $s0, $s0, $a0 # $s0 = (y * 16) + x
	sll $s0, $s0, 2 # $s0 = ((y * 16) + x) * 4
	
	la $v0, screen_board
	add $v0, $v0, $s0
	
	lw $s0, 0($sp)
	add $sp, $sp, 4
	
	jr $ra

# Verifica si la posición es válida
# $a0 = x
# $a1 = y
# Retorna 0 si la coordenada es inválida, 1 de lo contrario
check_coord_bounds_lower_screen:
	blt $a0, 0, invalid_ccbls
	bgt $a0, 15, invalid_ccbls
	blt $a1, 0, invalid_ccbls
	bgt $a1, 7, invalid_ccbls
	
	li $v0, 1
	
	return_ccbls:
		jr $ra
		
	invalid_ccbls:
		li $v0, 0
		j return_ccbls
		
start_player_boat_positioning:
	# guardar $ra
	sub $sp, $sp, 4
	sw $ra, 0($sp)
	
	jal initialize_player_boat_data
	
	# Empezar con el portaaviones
	li $a0, BOAT_TYPE_CARRIER
	jal position_boat
	
	li $a0, BOAT_TYPE_BATTLESHIP
	jal position_boat
	
	li $a0, BOAT_TYPE_DESTROYER
	jal position_boat
	
	li $a0, BOAT_TYPE_SUBARMINE
	jal position_boat
	
	li $a0, BOAT_TYPE_PATROL_BOAT
	jal position_boat
	
	lw $ra, 0($sp)
	add $sp, $sp, 4
	
	jr $ra

# $a0 = tipo de barco
# FIXME: No borrar un barco ya puesto si el nuevo le pasa por encima
position_boat:
	sub $sp, $sp, 12
	sw $ra, 8($sp)
	sw $s0, 4($sp)
	sw $s1, 0($sp)
	
	move $s1, $a0
	
	beq $s1, BOAT_TYPE_CARRIER, set_carrier_pb
	beq $s1, BOAT_TYPE_BATTLESHIP, set_battleship_pb
	beq $s1, BOAT_TYPE_DESTROYER, set_destroyer_pb
	beq $s1, BOAT_TYPE_SUBMARINE, set_submarine_pb
	beq $s1, BOAT_TYPE_PATROL_BOAT, set_patrol_boat_pb
	
	set_carrier_pb:
		li $t5, 5
		j continue_pb
	set_battleship_pb:
		li $t5, 4
		j continue_pb
	set_destroyer_pb:
	set_submarine_pb:
		li $t5, 3
		j continue_pb
	set_patrol_boat_pb:
		li $t5, 2

continue_pb:
	load_color($t0, 4) # Amarillo
	load_color($t1, 0) # Azul
	load_color($t2, 1) # Gris
	
	# $s0 contiene el eje del barco
	li $s0, 0
	li $a0, 0
	li $a1, 0
	jal coord_to_board_address
	move $s0, $v0
	
	loop_draw_pc:
		jal coord_to_board_address

		sw $t0, ($v0)
		add $a0, $a0, 1
		bne $a0, $t5, loop_draw_pc
	
	# Coordenada inicial
	li $a0, 0
	li $a1, 0
	
	loop_input_pc:
		li $v0, 12 # Read character
		syscall
		
		beq $v0, 'd', move_carrier_right_pc
		beq $v0, 'a', move_carrier_left_pc
		beq $v0, 'w', move_carrier_up_pc
		beq $v0, 's', move_carrier_down_pc
		beq $v0, 'e', place_carrier_pc
		
		j loop_input_pc
		
		move_carrier_right_out_of_bounds:
			sub $a0, $a0, $t5
			j loop_input_pc
			
		move_carrier_right_pc:
			add $a0, $a0, $t5
			jal check_coord_bounds_lower_screen
			beqz $v0, move_carrier_right_out_of_bounds
			
			sw $t1, ($s0)
			
			jal coord_to_board_address
			sw $t0, ($v0)
			
			# Recalcular eje
			sub $t6, $t5, 1			
			sub $a0, $a0, $t6
			jal coord_to_board_address
			move $s0, $v0
			
			j loop_input_pc
		
		move_carrier_left_out_of_bounds:
			add $a0, $a0, 1
			j loop_input_pc
			
		move_carrier_left_pc:
			sub $a0, $a0, 1
			jal check_coord_bounds_lower_screen
			beqz $v0, move_carrier_left_out_of_bounds
			
			add $a0, $a0, $t5
			jal coord_to_board_address
			sw $t1, ($v0)
			
			sub $a0, $a0, $t5
			jal coord_to_board_address
			move $s0, $v0
			sw $t0, ($s0)
			
			j loop_input_pc
			
		redraw_carrier_pc:
			store_ra
			jal coord_to_board_address #redraw
			restore_ra
			
			move $s0, $v0
			sw $t0, ($s0)
			
			move $t4, $a0
			add $t3, $a0, $t5
			add $a0, $a0, 1
			
			redraw_carrier_pc_loop:
				store_ra
				jal coord_to_board_address
				restore_ra
				
				sw $t0, ($v0)
				add $a0, $a0, 1
				beq $a0, $t3, redraw_carrier_pc_loop_done
				
				j redraw_carrier_pc_loop
		
		redraw_carrier_pc_loop_done:
			move $a0, $t4
			jr $ra
		
		undraw_carrier_pc:
			move $t6, $s0 # undraw carrier
			sw $t1, ($t6)
			li $t7, 1
			
			undraw_carrier_pc_loop:
				add $t6, $t6, 4
				sw $t1, ($t6)
				add $t7, $t7, 1
				beq $t7, $t5, undraw_carrier_pc_loop_done
				j undraw_carrier_pc_loop
					
			undraw_carrier_pc_loop_done:
				jr $ra
				
		move_carrier_up_out_of_bounds:
			sub $a1, $a1, 1
			j loop_input_pc
			
		move_carrier_up_pc:
			add $a1, $a1, 1
			jal check_coord_bounds_lower_screen
			beqz $v0, move_carrier_up_out_of_bounds
			
			# Undraw carrier
			jal undraw_carrier_pc
			
			jal redraw_carrier_pc
			
			j loop_input_pc
		
		move_carrier_down_out_of_bounds:
			add $a1, $a1, 1
			j loop_input_pc
			
		move_carrier_down_pc:
			sub $a1, $a1, 1
			jal check_coord_bounds_lower_screen
			beqz $v0, move_carrier_down_out_of_bounds
			
			# Undraw carrier
			jal undraw_carrier_pc
			
			jal redraw_carrier_pc
			
			j loop_input_pc
			
		place_carrier_pc:
			# TODO: Revisar overlapping con otros barcos
			
			move $t3, $s0
			li $t4, 0
			
			place_carrier_draw_pc_loop:
				beq $t4, $t5, place_carrier_draw_pc_loop_done
				sw $t2, ($t3)
				add $t3, $t3, 4
				add $t4, $t4, 1
				j place_carrier_draw_pc_loop
		
		place_carrier_draw_pc_loop_done:
			li $t8, 0
			move $t9, $a0
			add $t8, $t9, $t5
			
			la $a2, player_boat_data
			place_carrier_loop:
				jal set_element_in_board_matrix
				add $a0, $a0, 1
				beq $a0, $t8, loop_input_pc_done
				j place_carrier_loop
			
	loop_input_pc_done:
		lw $s1, 0($sp)
		lw $s0, 4($sp)
		lw $ra, 8($sp)
		add $sp, $sp, 12
	
		jr $ra
	
initialize_player_boat_data:
	la $t0, player_boat_data
	li $t2, BOAT_FACING_RIGHT
	
	# Carrier
	li $t1, BOAT_TYPE_CARRIER
	sw $t1, 0($t0)
	sw $zero, 4($t0)
	sw $zero, 8($t0)
	sw $t2, 12($t0)
	
	# Battleship
	li $t1, BOAT_TYPE_BATTLESHIP
	sw $t1, 16($t0)
	sw $zero, 20($t0)
	sw $zero, 24($t0)
	sw $t2, 28($t0)
	
	# Destroyer
	li $t1, BOAT_TYPE_DESTROYER
	sw $t1, 32($t0)
	sw $zero, 36($t0)
	sw $zero, 40($t0)
	sw $t2, 44($t0)
	
	# Submarine
	li $t1, BOAT_TYPE_SUBMARINE
	sw $t1, 48($t0)
	sw $zero, 52($t0)
	sw $zero, 56($t0)
	sw $t2, 60($t0)
	
	# Patrol Boat
	li $t1, BOAT_TYPE_PATROL_BOAT
	sw $t1, 64($t0)
	sw $zero, 68($t0)
	sw $zero, 72($t0)
	sw $t2, 76($t0)
	
	jr $ra

get_element_in_board_matrix:
	la $t0, player_board_matrix
	lw $t1, player_board_cols
	
	mul $t2, $a1, $t1 # row * columns
	add $t2, $t2, $a0 # (row * columns) + column
	sll $t2, $t2, 2 # ((row * columns) + column) * 4
	add $t0, $t0, $t2 # base + offset
	
	lw $v0, 0($t0)
	jr $ra

set_element_in_board_matrix:
	la $t0, player_board_matrix
	lw $t1, player_board_cols
	
	mul $t2, $a1, $t1 # row * columns
	add $t2, $t2, $a0 # (row * columns) + column
	sll $t2, $t2, 2 # ((row * columns) + column) * 4
	add $t0, $t0, $t2 # base + offset
	
	sw $a2, 0($t0)
	jr $ra
	
exit:
	li $v0, 10
	syscall
