.data
	displayAddress: .word 0x10010000 # (Static Data)
	paleta:
		.word 0x0000FF # (azul/agua)
		.word 0x808080 # (gris/barco)
		.word 0xFF0000 # (rojo/impacto)
		.word 0xFFFFFF # (blanco/fallo)
		.word 0xFFFF00 # (amarillo/seleccion)
		
	# Mensajes
	msg_impacto: .asciiz "¡Impactaste un barco!\n"
	msg_fallo: .asciiz "Fallaste...\n"
	msg_hundir: .asciiz "¡Hundiste un barco!\n"
	msg_atacar: .asciiz "Selecciona WASD para moverte, R para rotar y Espacio para colocar \n"
	
	# Tablero
	tablero_jugador: .space 256 #16x16
	tablero_enemigo: .space 256 #16x16
	
	# Barcos
	barcos_jugador:
		.word 5, 0, 0, 1 # Portaaviones
		.word 4, 0, 0, 1 # Acorazado
		.word 3, 0, 0, 1 # Submarino
		.word 2, 0, 0, 1 # Fragata
	
	conteo_barcos: .word 5
	barco_actual: .word 0
	modo_colocacion: .word 1 # 1 = colocado, 0 = jugando
	
.text
main: 
	jal iniciar_juegos
	fase_colocar:
		jal dibujar_tableros
		jal dibujar_cursor
		
		# Leer entrada
		jal get_input
		
		# Procesar entrada
		beq $v0, 0x77, mover_arriba # 'w'
		beq $v0, 0x61, mover_izquierda  # 'a'
        	beq $v0, 0x73, mover_abajo  # 's'
        	beq $v0, 0x64, mover_derecha # 'd'
        	beq $v0, 0x72, rotar_barco # 'r'
        	beq $v0, 0x20, colocar_barco # espacio
        	
        	j pla