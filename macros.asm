.eqv BOARD_SIZE 2048

.macro read_integer
	li $v0, 5
	syscall
.end_macro

# Equivalente a read_integer, pero mueve el resultado a un registro especificado
.macro read_integer_move(%reg)
	li $v0, 5
	syscall
	move %reg, $v0
.end_macro

.macro print_message(%msg)
	li $v0, 4
	la $a0, %msg
	syscall
.end_macro

# Para llamadas a funciones dentro de una función: almacena $ra en el stack
.macro store_ra
	sub $sp, $sp, 4
	sw $ra, 0($sp)
.end_macro

.macro restore_ra
	lw $ra, 0($sp)
	add $sp, $sp, 4
.end_macro

.macro load_color(%reg, %idx)
	la $a0, screen_colors
	li $a1, %idx
	store_ra
	jal get_from_array
	restore_ra
	move %reg, $v0
.end_macro

.macro sleep(%time)
	li $a0, %time
	li $v0, 32 # sleep en MARS
	syscall
.end_macro