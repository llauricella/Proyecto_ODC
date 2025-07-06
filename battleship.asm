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
		.word 0x7700FF # Morado (superposiciòn)
	
	boat_spaces:
		.word 5
		.word 4
		.word 3
		.word 2
		
	# Posición de los barcos del jugador principal
	player_boat_data: .word 0:20
	cpu_boat_data: .word 0:20
	
	player_board_matrix: .word 0:512
	targets_matrix: .word 0:512
	
	# Mensajes del menú
	menu_start_msg: .asciiz "----- BATTLESHIP -----\n\nIntroduce una de las siguientes opciones para continuar:\n\n1 - Jugar contra el CPU\n2 - Jugar contra otro jugador\n3 - Salir\n-> "
	menu_arrow: .asciiz "-> "
	
	# Mensajes de posición
	menu_rotate_out_of_bounds_right: .asciiz "\n¡No se puede rotar! Revisa si hay suficiente espacio a la derecha.\n"
	menu_rotate_out_of_bounds_up: .asciiz "\n¡No se puede rotar! Revisa si hay suficiente espacio arriba.\n"
	menu_place_overlapping: .asciiz "\n¡No puedes poner un barco encima de otro!\n"
	menu_place_hit: .asciiz "\nSelecciona el lugar de impacto con E, para moverlo utiliza las teclas WASD.\n"
	menu_hit_already_placed: .asciiz "\n¡Ya disparaste a esta posiciòn!\n"
	menu_wait_for_cpu_positioning: .asciiz "\nLa CPU está poniendo sus barcos...\n"
	menu_clear_screen: .asciiz "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
	menu_place_boat: .asciiz "\nMueve el barco a posicionar con las teclas WASD. Usa R para rotarlo y E para confirmar su posición.\n"
	menu_hit: .asciiz "\n¡IMPACTO!\n"
	menu_boat_sinked: .asciiz "\n¡BARCO HUNDIDO!\n"
	menu_hit_cpu: .asciiz "\nEl otro jugador ha impactado uno de tus barcos.\n"
	menu_sink_cpu: .asciiz "\nEl otro jugador ha hundido uno de tus barcos.\n"
	menu_cpu_turn: .asciiz "\nEl CPU está eligiendo un objetivo...\n"
	
	debug_x: .asciiz "x: "
	debug_y: .asciiz "y: "
	debug_found: .asciiz "found: "
	debug_boat_right: .asciiz "bote horizontal"
	debug_boat_up: .asciiz "bote vertical"
	
	cpu_last_hit_x: .word 0
	cpu_last_hit_y: .word 0
	
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
		j continue_menu_input
		
	invalid_menu_input:
		print_message(menu_arrow)
		j process_menu_input
		
	continue_menu_input:
		beq $v0, 1, menu_option_1
		beq $v0, 2, menu_option_2
		beq $v0, 3, menu_option_3
		
	menu_option_1:
		jal start_player_boat_positioning
		
		li $v0, 4
		la $a0, menu_clear_screen
		syscall
		
		la $a0, menu_wait_for_cpu_positioning
		syscall
		
		jal cpu_place_boats
		
		sleep(2000)
		
		game_loop_select_target:
			jal player_select_target
			beq $v0, 1, game_loop_select_target
			
			la $a0, menu_cpu_turn
			li $v0, 4
			syscall
			
			jal cpu_select_target
			
			j game_loop_select_target
			
	menu_option_2:
	menu_option_3:
		j exit

# Función para vaciar el tablero en pantalla
empty_screen_board:
	la $t0, screen_colors
	lw $t0, COLOR_WATER($t0)
	
	li $t1, 0
	
	loop_esb:
		sw $t0, screen_board($t1)
		
		beq $t1, BOARD_SIZE, return_esb
		
		add $t1, $t1, 4
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


# Convierte una coordenada en el rango (x, y) ϵ [0, 16) a la dirección de memoria correspondiente en el tablero
# gracias! https://stackoverflow.com/a/47697769
coord_to_board_address:
	sub $sp, $sp, 4
	sw $s0, 0($sp)
	
	li $s0, 31
	sub $s0, $s0, $a1
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
	bgt $a1, 15, invalid_ccbls
	
	li $v0, 1

	jr $ra
		
	invalid_ccbls:
		li $v0, 0
		jr $ra
		
check_coord_bounds_upper_screen:
	blt $a0, 0, invalid_ccbus
	bgt $a0, 15, invalid_ccbus
	blt $a1, 16, invalid_ccbus
	bgt $a1, 31, invalid_ccbus
	
	li $v0, 1
	
	jr $ra
	
	invalid_ccbus:
		li $v0, 0
		jr $ra
	
		
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
	
	li $a0, BOAT_TYPE_SUBMARINE
	jal position_boat
	
	li $a0, BOAT_TYPE_PATROL_BOAT
	jal position_boat
	
	lw $ra, 0($sp)
	add $sp, $sp, 4
	
	jr $ra

# $a0 = tipo de barco
position_boat:
	sub $sp, $sp, 24
	sw $ra, 20($sp)
	sw $s0, 16($sp)
	sw $s1, 12($sp)
	sw $s2, 8($sp)
	sw $s3, 4($sp) # flag: dibujar gris (podriamos usar operaciones de bits y almacenar todas las flags aqui) (ahora si se hace)
	sw $s4, 0($sp)
	
	move $s1, $a0
	
	li $v0, 4
	la $a0, menu_clear_screen
	syscall
	
	la $a0, menu_place_boat
	syscall
	
	li $s2, BOAT_FACING_RIGHT
	li $s3, 0
	
	# Calcular cuantas casillas toma un barco
	li $t5, 5
	sub $t5, $t5, $s1
	
	la $t9, screen_colors
	lw $t0, COLOR_SELECTION($t9)
	lw $t1, COLOR_WATER($t9)
	lw $t2, COLOR_BOAT($t9)
	lw $s4, COLOR_HIT($t9)
	
	# $s0 contiene el eje del barco
	li $s0, 0
	
	# Coordenada inicial
	li $a0, 0
	li $a1, 0
	
	j loop_input_pc
	
	redraw_carrier_pc:
		move $t7, $a0
		move $t8, $a1
			
		store_ra
		jal coord_to_board_address #redraw
		restore_ra
		
		move $s0, $v0
		sw $t0, ($s0)
			
		li $t3, 0
		beq $s2, BOAT_FACING_RIGHT, redraw_carrier_pc_right
		beq $s2, BOAT_FACING_UP, redraw_carrier_pc_up
			
		redraw_carrier_pc_right:
			add $t3, $a0, $t5
				
			redraw_carrier_pc_loop_right:
				store_ra
				jal coord_to_board_address
				move $t9, $v0
				
				la $a2, player_board_matrix
				jal get_element_in_board_matrix
				restore_ra
				
				bnez $v0, redraw_carrier_pc_loop_right_overlapping

				move $v0, $t9
				
				bit_is_set($t9, $s3, FLAG_BOAT_PLACED)
				beqz $t9, redraw_carrier_pc_loop_right_placing
				# continua a right_placed si es otro valor
				
				redraw_carrier_pc_loop_right_placed:
					sw $t2, ($v0)
					j redraw_carrier_pc_loop_right_continue
				redraw_carrier_pc_loop_right_overlapping:
					set_bit($s3, FLAG_BOAT_OVERLAPPING)
					sw $s4, ($t9)
					j redraw_carrier_pc_loop_right_continue
				redraw_carrier_pc_loop_right_placing:
					sw $t0, ($v0)
			
			redraw_carrier_pc_loop_right_continue:
				add $a0, $a0, 1
				beq $a0, $t3, redraw_carrier_pc_loop_done
				j redraw_carrier_pc_loop_right
					
		redraw_carrier_pc_up:
			add $t3, $a1, $t5
				
			redraw_carrier_pc_loop_up:
				store_ra
				jal coord_to_board_address
				move $t9, $v0
				
				la $a2, player_board_matrix
				jal get_element_in_board_matrix
				restore_ra
				
				bnez $v0, redraw_carrier_pc_loop_up_overlapping
				
				move $v0, $t9
				
				bit_is_set($t9, $s3, FLAG_BOAT_PLACED)
				beqz $t9, redraw_carrier_pc_loop_up_placing
				# continua a up_placed si es otro valor
				
				redraw_carrier_pc_loop_up_placed:
					sw $t2, ($v0)
					j redraw_carrier_pc_loop_up_continue
				redraw_carrier_pc_loop_up_overlapping:
					set_bit($s3, FLAG_BOAT_OVERLAPPING)
					sw $s4, ($t9)
					j redraw_carrier_pc_loop_up_continue
				redraw_carrier_pc_loop_up_placing:
					sw $t0, ($v0)
					
			redraw_carrier_pc_loop_up_continue:
				add $a1, $a1, 1
				beq $a1, $t3, redraw_carrier_pc_loop_done
				j redraw_carrier_pc_loop_up
					
		redraw_carrier_pc_loop_done:
			#set_bit($s3, FLAG_REDRAW_BOARD)
			
			move $a0, $t7
			move $a1, $t8
			jr $ra
		
	undraw_carrier_pc:
		move $t6, $s0
		move $t8, $a1
		sw $t1, ($t6)
		li $t7, 1
			
		beq $s2, BOAT_FACING_RIGHT, undraw_carrier_pc_loop_right
		
		add $a1, $a1, $t5
		
		beq $s2, BOAT_FACING_UP, undraw_carrier_pc_loop_up
		
		undraw_carrier_pc_loop_up:
			store_ra
			jal coord_to_board_address
			restore_ra
				
			sw $t1, ($v0)
			sub $a1, $a1, 1
			beq $a1, $t8, undraw_carrier_pc_loop_done
			j undraw_carrier_pc_loop_up
				
		undraw_carrier_pc_loop_right:
			add $t6, $t6, 4
			sw $t1, ($t6)
			add $t7, $t7, 1
			beq $t7, $t5, undraw_carrier_pc_loop_done
			j undraw_carrier_pc_loop_right
					
		undraw_carrier_pc_loop_done:
			move $a1, $t8
			jr $ra
				
	loop_input_pc:
		clear_bit($s3, FLAG_BOAT_OVERLAPPING)
		
		jal redraw_player_board
		jal redraw_carrier_pc
		
		li $v0, 12 # Read character
		syscall
		
		# lol
		beq $v0, 'd', move_carrier_right_pc
		beq $v0, 'D', move_carrier_right_pc
		beq $v0, 'a', move_carrier_left_pc
		beq $v0, 'A', move_carrier_left_pc
		beq $v0, 'w', move_carrier_up_pc
		beq $v0, 'W', move_carrier_up_pc
		beq $v0, 's', move_carrier_down_pc
		beq $v0, 'S', move_carrier_down_pc
		beq $v0, 'r', rotate_carrier_pc
		beq $v0, 'R', rotate_carrier_pc
		beq $v0, 'e', place_carrier_pc
		beq $v0, 'E', place_carrier_pc
		
		j loop_input_pc
		
		move_carrier_right_lu_out_of_bounds:
			sub $a0, $a0, 1
			j loop_input_pc
			
		move_carrier_right_lr_out_of_bounds:
			sub $a0, $a0, $t5
			j loop_input_pc
			
		move_carrier_right_pc:
			beq $s2, BOAT_FACING_UP, move_carrier_right_lu_pc
			beq $s2, BOAT_FACING_RIGHT, move_carrier_right_lr_pc
			
			move_carrier_right_lu_pc:
				# debe haber una mejor manera de hacer esto, no?
				move $t9, $a0
				add $a0, $a0, 1
				jal check_coord_bounds_lower_screen
				beqz $v0, move_carrier_right_lu_out_of_bounds
				
				move $a0, $t9
				jal undraw_carrier_pc
				
				add $a0, $a0, 1
				jal redraw_carrier_pc
				
				j loop_input_pc
				
			move_carrier_right_lr_pc:
				add $a0, $a0, $t5
				jal check_coord_bounds_lower_screen
				beqz $v0, move_carrier_right_lr_out_of_bounds	
			
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
			move $t9, $a0
			sub $a0, $a0, 1
			jal check_coord_bounds_lower_screen
			beqz $v0, move_carrier_left_out_of_bounds
				
			beq $s2, BOAT_FACING_UP, move_carrier_left_up_oriented_pc
			beq $s2, BOAT_FACING_RIGHT, move_carrier_left_right_oriented_pc
				
			move_carrier_left_up_oriented_pc:
				move $a0, $t9
				jal undraw_carrier_pc
				
				sub $a0, $a0, 1
				jal redraw_carrier_pc
				
				j loop_input_pc
				
			move_carrier_left_right_oriented_pc:
				add $a0, $a0, $t5
				jal coord_to_board_address
				sw $t1, ($v0)
			
				sub $a0, $a0, $t5
				jal coord_to_board_address
				move $s0, $v0
				sw $t0, ($s0)
			
				j loop_input_pc
				
		move_carrier_up_out_of_bounds:
			sub $a1, $a1, 1
			j loop_input_pc
			
		move_carrier_up_pc:
			beq $s2, BOAT_FACING_RIGHT, move_carrier_up_facing_right
			beq $s2, BOAT_FACING_UP, move_carrier_up_facing_up
			
			move_carrier_up_facing_up:
				add $a1, $a1, $t5
				jal check_coord_bounds_lower_screen
				sub $a1, $a1, $t5
				beqz $v0, loop_input_pc
				add $a1, $a1, 1
				j move_carrier_up_continue
				
			move_carrier_up_facing_right:
				add $a1, $a1, 1
				jal check_coord_bounds_lower_screen
				beqz $v0, move_carrier_up_out_of_bounds
			
			move_carrier_up_continue:
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
		
		rotate_carrier_up_out_of_bounds:
			move $t9, $a0
			print_message(menu_rotate_out_of_bounds_up)
			move $a0, $t9
			move $a1, $t3
			j loop_input_pc
		
		rotate_carrier_right_out_of_bounds:
			move $t9, $a0
			print_message(menu_rotate_out_of_bounds_right)
			move $a0, $t9
			move $a0, $t3
			j loop_input_pc
			
		rotate_carrier_pc:
			beq $s2, BOAT_FACING_RIGHT, rotate_carrier_up_pc
			beq $s2, BOAT_FACING_UP, rotate_carrier_right_pc
			
			rotate_carrier_up_pc:
				move $t3, $a1
				add $a1, $a1, $t5
				sub $a1, $a1, 1
				jal check_coord_bounds_lower_screen
				beqz $v0, rotate_carrier_up_out_of_bounds
				
				move $a1, $t3
				
				jal undraw_carrier_pc
				
				li $s2, BOAT_FACING_UP
				
				jal redraw_carrier_pc
				
				j loop_input_pc
			rotate_carrier_right_pc:
				move $t3, $a0
				add $a0, $a0, $t5
				sub $a0, $a0, 1
				jal check_coord_bounds_lower_screen
				beqz $v0, rotate_carrier_right_out_of_bounds
				
				move $a0, $t3
				
				jal undraw_carrier_pc
				
				li $s2, BOAT_FACING_RIGHT
				
				jal redraw_carrier_pc
				
				j loop_input_pc
				
		place_carrier_pc:
			bit_is_set($t4, $s3, FLAG_BOAT_OVERLAPPING)
			beqz $t4, place_carrier_pc_valid
			
			print_message(menu_place_overlapping)
			j loop_input_pc
			
		place_carrier_pc_valid:
			set_bit($s3, FLAG_BOAT_PLACED)
			jal redraw_carrier_pc
			toggle_bit($s3, FLAG_BOAT_PLACED)
			
			la $a3, player_board_matrix
			la $a2, player_boat_data
			sll $s1, $s1, 4 # ya a este punto no se usa $s1 so whatever
			add $a2, $a2, $s1 # player_boat_data + offset
			
			# Guardar coordenadas del eje y orientación del barco
			sw $a0, 4($a2)
			sw $a1, 8($a2)
			sw $s2, 12($a2)
			
			beq $s2, BOAT_FACING_RIGHT, place_carrier_set_data_right
			
			place_carrier_set_data_up:
				add $t8, $a1, $t5
				
				place_carrier_set_data_loop_up:
					jal set_element_in_board_matrix
					add $a1, $a1, 1
					beq $a1, $t8, loop_input_pc_done
					j place_carrier_set_data_loop_up
					
			place_carrier_set_data_right:
				add $t8, $a0, $t5
				
				place_carrier_set_data_loop_right:
					jal set_element_in_board_matrix
					add $a0, $a0, 1
					beq $a0, $t8, loop_input_pc_done
					j place_carrier_set_data_loop_right
			
	loop_input_pc_done:
		lw $s4, 0($sp)
		lw $s3, 4($sp)
		lw $s2, 8($sp)
		lw $s1, 12($sp)
		lw $s0, 16($sp)
		lw $ra, 20($sp)
		add $sp, $sp, 24
	
		jr $ra

cpu_place_boats:
	sub $sp, $sp, 12
	sw $s1, 8($sp)
	sw $s0, 4($sp)
	sw $ra, 0($sp)
	
	#li $a0, PRNG_ID
	#li $a1, PRNG_SEED
	#li $v0, 40 # set seed
	syscall
	
	li $t0, BOAT_TYPE_CARRIER
	
	cpu_place_boats_loop:
		# Orientación del barco (max 1)
		li $a0, PRNG_ID
		li $a1, 2
		li $v0, 42
		syscall
		
		move $t1, $a0
		
		# Calcular cuantos espacios toma el barco
		li $t2, 5
		sub $t2, $t2, $t0
		
		beq $t1, BOAT_FACING_RIGHT, cpu_place_boats_loop_right
		
		cpu_place_boats_loop_up:
			#print_message(debug_boat_up)
			
			li $t3, 16
			sub $t3, $t3, $t2
			add $t3, $t3, 1
			
			cpu_place_boats_loop_up_find:
				li $a0, PRNG_ID
				move $a1, $t3
				li $v0, 42
				syscall
				
				add $a0, $a0, 16 # 16 + rand_y [0, 16)
				move $s1, $a0
			
				li $a0, PRNG_ID
				li $a1, 16
				syscall
				
				move $s0, $a0
				
				li $t4, 0
				move $t8, $s1
				la $a2, player_board_matrix
				cpu_place_boats_loop_up_check:
					move $a1, $t8
					jal get_element_in_board_matrix
					bnez $v0, cpu_place_boats_loop # comprobación fallida
					
					add $t4, $t4, 1
					beq $t4, $t2, cpu_place_boats_loop_up_check_done
					add $t8, $t8, 1
					j cpu_place_boats_loop_up_check
					
				#cpu_place_boats_loop_up_check_failed:
				#	j cpu_place_boats_loop
					
				cpu_place_boats_loop_up_check_done:
					move $a0, $s0
					move $a1, $s1
					
					mul $t5, $t0, 20
					la $a2, cpu_boat_data
					add $a2, $a2, $t5
					
					lw $s0, 4($a2)
					lw $s1, 8($a2)
					lw $t1, 12($a2)
					
					la $a3, player_board_matrix
					
					li $t4, 0
					
					cpu_place_boats_loop_up_place_data:
						jal set_element_in_board_matrix
						
						add $t4, $t4, 1
						beq $t4, $t2, cpu_place_boats_loop_continue
						add $a1, $a1, 1
						j cpu_place_boats_loop_up_place_data
						
			j cpu_place_boats_loop_continue
			
		cpu_place_boats_loop_right:
			#print_message(debug_boat_right)
			
			li $t3, 16
			sub $t3, $t3, $t2
			add $t3, $t3, 1
			
			cpu_place_boats_loop_right_find:
				li $a0, PRNG_ID
				move $a1, $t3
				li $v0, 42
				syscall
				
				move $s0, $a0
			
				li $a0, PRNG_ID
				li $a1, 16
				syscall
				
				add $a0, $a0, 16 # 16 + rand_y [0, 16)
				move $s1, $a0
				
				li $t4, 0
				move $a0, $s0
				la $a2, player_board_matrix
				cpu_place_boats_loop_right_check:
					jal get_element_in_board_matrix
					bnez $v0, cpu_place_boats_loop # comprobación fallida
					
					add $t4, $t4, 1
					beq $t4, $t2, cpu_place_boats_loop_right_check_done
					add $a0, $a0, 1
					j cpu_place_boats_loop_right_check
					
				cpu_place_boats_loop_right_check_done:
					move $a0, $s0
					move $a1, $s1
					
					mul $t5, $t0, 20
					la $a2, cpu_boat_data
					add $a2, $a2, $t5
					
					lw $s0, 4($a2)
					lw $s1, 8($a2)
					lw $t1, 12($a2)
					
					la $a3, player_board_matrix
					
					li $t4, 0
					
					cpu_place_boats_loop_right_place_data:
						jal set_element_in_board_matrix
						
						add $t4, $t4, 1
						beq $t4, $t2, cpu_place_boats_loop_continue
						add $a0, $a0, 1
						j cpu_place_boats_loop_right_place_data
						
	cpu_place_boats_loop_continue:
		add $t0, $t0, 1
		bgt $t0, BOAT_TYPE_PATROL_BOAT, cpu_place_boats_done
		j cpu_place_boats_loop
	
cpu_place_boats_done:
	lw $s1, 8($sp)
	lw $s0, 4($sp)
	lw $ra, 0($sp)
	add $sp, $sp, 12
	
	jr $ra

player_select_target:
	sub $sp, $sp, 24
	sw $s4, 20($sp)
	sw $s3, 16($sp)
	sw $s2, 12($sp)
	sw $s1, 8($sp)
	sw $s0, 4($sp)
	sw $ra, 0($sp)
	
	li $v0, 4
	la $a0, menu_place_hit
	syscall
	
	la $t0, screen_colors
	lw $s0, COLOR_SELECTION($t0)
	lw $s1, COLOR_HIT($t0)
	lw $s2, COLOR_FAIL($t0)
	lw $s3, COLOR_OVERLAPPING($t0)
	
	li $a0, 0
	li $a1, 16
	
	jal coord_to_board_address
	move $s4, $v0
	
	la $a2, targets_matrix
	jal get_element_in_board_matrix
	sw $s0, ($s4)
	beqz $v0, player_select_target_loop
	
	sw $s3, ($s4)
	
	j player_select_target_loop
		
	player_select_target_loop_redraw:
		sub $sp, $sp, 4
		sw $ra, 0($sp)
		
		jal coord_to_board_address

		 beq $s4, HIT_TYPE_NONE, player_select_target_loop_redraw_none
		 beq $s4, HIT_TYPE_MISS, player_select_target_loop_redraw_miss
		 beq $s4, HIT_TYPE_CORRECT, player_select_target_loop_redraw_hit
		 
		 player_select_target_loop_redraw_none:
		 	la $t0, screen_colors
		 	lw $t0, COLOR_WATER($t0)
		 	sw $t0, ($v0)
		 	j player_select_target_loop_redraw_done
		 	
		 player_select_target_loop_redraw_miss:
		 	sw $s2, ($v0)
		 	j player_select_target_loop_redraw_done
		 	
		 player_select_target_loop_redraw_hit:
		 	sw $s1, ($v0)
  	
	player_select_target_loop_redraw_done:
		lw $ra, 0($sp)
		add $sp, $sp, 4
		
		jr $ra
		
	player_select_target_loop:
		li $v0, 12
		syscall
		
		beq $v0, 'w', player_target_move_up
		beq $v0, 's', player_target_move_down
		beq $v0, 'a', player_target_move_left
		beq $v0, 'd', player_target_move_right
		beq $v0, 'e', player_target_hit
		
		j player_select_target_loop
		
		player_target_move_up:
			add $a1, $a1, 1
			jal check_coord_bounds_upper_screen
			sub $a1, $a1, 1
			beqz $v0, player_select_target_loop
			
			la $a2, targets_matrix
			jal get_element_in_board_matrix
			move $s4, $v0
			
			jal player_select_target_loop_redraw
			add $a1, $a1, 1
			jal coord_to_board_address
			move $t0, $v0
			
			jal get_element_in_board_matrix
			bnez $v0, player_target_move_up_overlapping
			
			sw $s0, ($t0)
			j player_select_target_loop
			
			player_target_move_up_overlapping:
				sw $s3, ($t0)
				j player_select_target_loop
				
		player_target_move_down:
			sub $a1, $a1, 1
			jal check_coord_bounds_upper_screen
			add $a1, $a1, 1
			beqz $v0, player_select_target_loop
			
			la $a2, targets_matrix
			jal get_element_in_board_matrix
			move $s4, $v0
			
			jal player_select_target_loop_redraw
			sub $a1, $a1, 1
			jal coord_to_board_address
			move $t0, $v0
			
			jal get_element_in_board_matrix
			bnez $v0, player_target_move_down_overlapping
			
			sw $s0, ($t0)
			j player_select_target_loop
			
			player_target_move_down_overlapping:
				sw $s3, ($t0)
				j player_select_target_loop
				
		player_target_move_left:
			sub $a0, $a0, 1
			jal check_coord_bounds_upper_screen
			add $a0, $a0, 1
			beqz $v0, player_select_target_loop
			
			la $a2, targets_matrix
			jal get_element_in_board_matrix
			move $s4, $v0
			
			jal player_select_target_loop_redraw
			sub $a0, $a0, 1
			sub $v0, $v0, 4
			move $t0, $v0
			
			jal get_element_in_board_matrix
			bnez $v0, player_target_move_left_overlapping
			
			sw $s0, ($t0)
			j player_select_target_loop
			
			player_target_move_left_overlapping:
				sw $s3, ($t0)
				j player_select_target_loop
			
		player_target_move_right:
			add $a0, $a0, 1
			jal check_coord_bounds_upper_screen
			sub $a0, $a0, 1
			beqz $v0, player_select_target_loop
			
			la $a2, targets_matrix
			jal get_element_in_board_matrix
			move $s4, $v0
			
			jal player_select_target_loop_redraw
			
			add $a0, $a0, 1
			add $v0, $v0, 4
			move $t0, $v0
			
			jal get_element_in_board_matrix
			bnez $v0, player_target_move_right_overlapping
			
			sw $s0, ($t0)
			j player_select_target_loop
			
			player_target_move_right_overlapping:
				sw $s3, ($t0)
				j player_select_target_loop
		
		player_target_hit:
			la $a2, targets_matrix
			jal get_element_in_board_matrix
			beqz $v0, player_target_hit_continue
			
			move $t0, $a0
			
			la $a0, menu_hit_already_placed
			li $v0, 4
			syscall
			
			move $a0, $t0
			
			j player_select_target_loop
			
		player_target_hit_continue:
			la $a2, player_board_matrix
			jal get_element_in_board_matrix
			beqz $v0, player_target_hit_miss
			
		player_target_hit_correct:
			move $t0, $v0
			
			li $a2, HIT_TYPE_CORRECT
			la $a3, targets_matrix
			jal set_element_in_board_matrix
			
			jal coord_to_board_address
			sw $s1, ($v0)
			
			lw $t1, 16($t0)
			add $t1, $t1, 1
			sw $t1, 16($t0)
			
			print_message(menu_hit)
			
			lw $t2, 0($t0)
			li $t3, 5
			sub $t2, $t3, $t2
			li $v0, 1
			bne $t1, $t2, player_select_target_loop_done
			
			print_message(menu_boat_sinked)
			
			li $v0, 1
			j player_select_target_loop_done
		
		player_target_hit_miss:
			li $a2, HIT_TYPE_MISS
			la $a3, targets_matrix
			jal set_element_in_board_matrix
			
			jal coord_to_board_address
			sw $s2, ($v0)
			
			li $a2, HIT_TYPE_MISS
			la $a3, targets_matrix
			jal set_element_in_board_matrix
			
			li $v0, 0
			j player_select_target_loop_done
			
	player_select_target_loop_done:
		lw $s4, 20($sp)
		lw $s3, 16($sp)
		lw $s2, 12($sp)
		lw $s1, 8($sp)
		lw $s0, 4($sp)
		lw $ra, 0($sp)
		add $sp, $sp, 20
	
		jr $ra
		
cpu_select_target:
	sub $sp, $sp, 12
	sw $s1, 8($sp)
	sw $s0, 4($sp)
	sw $ra, 0($sp)
	
	cpu_select_target_loop:
		li $a0, PRNG_ID
		li $a1, 16
		li $v0, 42
		syscall
		move $s0, $a0
		
		li $a0, PRNG_ID
		syscall
		move $s1, $a0
		
	cpu_select_target_loop_next:
		move $a0, $s0
		move $a1, $s1
		
		la $a2 targets_matrix
		jal get_element_in_board_matrix
		bnez $v0, cpu_select_target_loop
		
		la $a2, player_board_matrix
		jal get_element_in_board_matrix
		beqz $v0, cpu_select_target_loop_miss
		
		cpu_select_target_loop_hit:
			move $t9, $v0
			
			jal coord_to_board_address
			la $t0, screen_colors
			lw $t0, COLOR_HIT($t0)
			sw $t0, ($v0)
			
			li $a2, HIT_TYPE_CORRECT
			la $a3, targets_matrix
			jal set_element_in_board_matrix
			
			sw $s0, cpu_last_hit_x
			sw $s1, cpu_last_hit_y
			
			print_message(menu_hit_cpu)
			
			lw $t0, 16($t9)
			add $t0, $t0, 1
			sw $t0, 16($t9)
			
			lw $t1, 0($t9)
			li $t2, 5
			sub $t1, $t2, $t1
			beq $t0, $t1, cpu_select_target_loop_sink
			
			bge $a0, 15, cpu_next_hit_left
			ble $a0, 0, cpu_next_hit_right
			
			cpu_next_hit_left:
				sub $s0, $s0, 1
				j cpu_select_target_loop_next
				
			cpu_next_hit_right:
				add $s0, $s0, 1
				j cpu_select_target_loop_next
				
			cpu_select_target_loop_sink:
				print_message(menu_sink_cpu)
				j cpu_select_target_loop
			
		cpu_select_target_loop_miss:
			jal coord_to_board_address
			la $t0, screen_colors
			lw $t0, COLOR_FAIL($t0)
			sw $t0, ($v0)
			
			li $a2, HIT_TYPE_MISS
			la $a3, targets_matrix
			jal set_element_in_board_matrix
			
cpu_select_target_done:
	lw $s1, 8($sp)
	lw $s0, 4($sp)
	lw $ra, 0($sp)
	add $sp, $sp, 12
	
	jr $ra
	
initialize_player_boat_data:
	la $t0, player_boat_data
	la $t3, cpu_boat_data
	li $t2, BOAT_FACING_RIGHT
	
	# Carrier
	li $t1, BOAT_TYPE_CARRIER
	sw $t1, 0($t0) # tipo
	sw $t1, 0($t3)
	sw $zero, 4($t0) # x
	sw $zero, 4($t3)
	sw $zero, 8($t0) # y
	sw $zero, 8($t3)
	sw $t2, 12($t0) # orientacion
	sw $t2, 12($t3)
	sw $zero, 16($t0) # numero de hits
	sw $zero, 16($t3)
	
	# Battleship
	li $t1, BOAT_TYPE_BATTLESHIP
	sw $t1, 20($t0) # tipo
	sw $t1, 20($t3)
	sw $zero, 24($t0) # x
	sw $zero, 24($t3)
	sw $zero, 28($t0) # y
	sw $zero, 28($t3)
	sw $t2, 32($t0) # orientacion
	sw $t2, 32($t3)
	sw $zero, 36($t0) # numero de hits
	sw $zero, 36($t3)
	
	# Submarine
	li $t1, BOAT_TYPE_SUBMARINE
	sw $t1, 40($t0) # tipo
	sw $t1, 40($t3)
	sw $zero, 44($t0) # x
	sw $zero, 44($t3)
	sw $zero, 48($t0) # y
	sw $zero, 48($t3)
	sw $t2, 52($t0) # orientacion
	sw $t2, 52($t3)
	sw $zero, 56($t0) # numero de hits
	sw $zero, 56($t3)
	
	# Patrol Boat
	li $t1, BOAT_TYPE_PATROL_BOAT
	sw $t1, 60($t0) # tipo
	sw $t1, 60($t3)
	sw $zero, 64($t0) # x
	sw $zero, 64($t3)
	sw $zero, 68($t0) # y
	sw $zero, 68($t3)
	sw $t2, 72($t0) # orientacion
	sw $t2, 72($t3)
	sw $zero, 76($t0) # numero de hits
	sw $zero, 76($t3)
	
	jr $ra

get_element_in_board_matrix:
	sub $sp, $sp, 8
	sw $s0, 4($sp)
	sw $s1, 0($sp)
	
	move $s0, $a2
	
	sll $s1, $a1, 4 # y * 16
	add $s1, $s1, $a0 # y * 16 + x
	sll $s1, $s1, 2 # (y * 16 + x) * 4
	add $s0, $s0, $s1 # base + offset
	
	lw $v0, ($s0)
	
	lw $s1, 0($sp)
	lw $s0, 4($sp)
	add $sp, $sp, 8
	
	jr $ra

set_element_in_board_matrix:
	sub $sp, $sp, 12
	sw $s0, 8($sp)
	sw $s1, 4($sp)
	sw $s2, 0($sp)
	
	move $s0, $a3
	
	sll $s2, $a1, 4 # y * 16
	add $s2, $s2, $a0 # y * 16 + x
	sll $s2, $s2, 2 # (y * 16 + x) * 4
	add $s0, $s0, $s2 # base + offset
	
	sw $a2, ($s0)
	
	lw $s2, 0($sp)
	lw $s1, 4($sp)
	lw $s0, 8($sp)
	add $sp, $sp, 12
	
	jr $ra

# TODO: optimizar!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
redraw_player_board:
	sub $sp, $sp, 24
	sw $s4, 20($sp)
	sw $s3, 16($sp)
	sw $s2, 12($sp)
	sw $s1, 8($sp)
	sw $s0, 4($sp)
	sw $ra, 0($sp)
	
	la $s4, screen_colors
	lw $s2, COLOR_WATER($s4)
	lw $s3, COLOR_BOAT($s4)
	
	move $s0, $a0
	move $s1, $a1
	
	li $a0, 0
	li $a1, 0
	
	redraw_player_board_loop:
		#print_message(debug_x)
		#print_integer($a0)
		#print_linebreak
		#print_message(debug_y)
		#print_integer($a1)
		#print_linebreak
		la $a2, player_board_matrix
		jal get_element_in_board_matrix
		#move $t9, $v0
		#print_message(debug_found)
		#print_integer_hex($t9)
		#print_linebreak
		#move $v0, $t9
		bgtz $v0, rpb_loop_boat
	
	rpb_loop_water:
		jal coord_to_board_address
		sw $s2, ($v0)
		j rpb_loop_continue
	rpb_loop_boat:
		jal coord_to_board_address
		sw $s3, ($v0)
		
	rpb_loop_continue:
		add $a0, $a0, 1
		bgt $a0, 15, rpb_loop_inc_y
		j redraw_player_board_loop
	
	rpb_loop_inc_y:
		li $a0, 0
		add $a1, $a1, 1
		bgt $a1, 31, rpb_loop_done
		j redraw_player_board_loop
	
rpb_loop_done:
	move $a0, $s0
	move $a1, $s1
	
	lw $s4, 20($sp)
	lw $s3, 16($sp)
	lw $s2, 12($sp)
	lw $s1, 8($sp)
	lw $s0, 4($sp)
	lw $ra, 0($sp)
	add $sp, $sp, 24
	
	jr $ra

exit:
	li $v0, 10
	syscall