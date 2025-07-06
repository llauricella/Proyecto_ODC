.eqv BOARD_SIZE 2048

.eqv BOAT_TYPE_CARRIER 0
.eqv BOAT_TYPE_BATTLESHIP 1
.eqv BOAT_TYPE_SUBMARINE 2
.eqv BOAT_TYPE_PATROL_BOAT 3

.eqv BOAT_FACING_UP 0
.eqv BOAT_FACING_RIGHT 1

.eqv OFFSET_CARRIER 0
.eqv OFFSET_BATTLESHIP 20
.eqv OFFSET_SUBMARINE 40
.eqv OFFSET_PATROL_BOAT 60

.eqv FLAG_BOAT_PLACED 1
.eqv FLAG_BOAT_OVERLAPPING 2
.eqv FLAG_REDRAW_BOARD 4

.eqv COLOR_WATER 0
.eqv COLOR_BOAT 4
.eqv COLOR_HIT 8
.eqv COLOR_FAIL 12
.eqv COLOR_SELECTION 16
.eqv COLOR_OVERLAPPING 20

.eqv HIT_TYPE_NONE 0
.eqv HIT_TYPE_MISS 1
.eqv HIT_TYPE_CORRECT 2

.eqv PRNG_ID 1
.eqv PRNG_SEED 1751782628

.macro print_linebreak
	sub $sp, $sp, 4
	sw $a0, 0($sp)
	li $a0, '\n'
	li $v0, 11
	syscall 
	lw $a0, 0($sp)
	add $sp, $sp, 4
.end_macro

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
	sub $sp, $sp, 4
	sw $a0, 0($sp)
	li $v0, 4
	la $a0, %msg
	syscall
	lw $a0, 0($sp)
	add $sp, $sp, 4
.end_macro

.macro print_integer(%reg)
	sub $sp, $sp, 4
	sw $a0, 0($sp)
	li $v0, 1
	move $a0, %reg
	syscall
	lw $a0, 0($sp)
	add $sp, $sp, 4
.end_macro

.macro print_integer_hex(%reg)
	sub $sp, $sp, 4
	sw $a0, 0($sp)
	li $v0, 34
	move $a0, %reg
	syscall
	lw $a0, 0($sp)
	add $sp, $sp, 4
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
	sub $sp, $sp, 4
	sw $s0, 0($sp)
	
	la $s0, screen_colors
	lw %reg, %idx($s0)
	
	lw $s0, 0($sp)
	add $sp, $sp, 4
.end_macro

.macro sleep(%time)
	li $a0, %time
	li $v0, 32 # sleep en MARS
	syscall
.end_macro

# para fines de legibilidad

.macro set_bit(%reg, %bit)
	ori %reg, %reg, %bit
.end_macro

.macro bit_is_set(%dest, %reg, %bit)
	andi %dest, %reg, %bit
	sgt %dest, %dest, $zero
.end_macro

.macro toggle_bit(%reg, %bit)
	xori %reg, %reg, %bit
.end_macro

.macro clear_bit(%reg, %bit)
	sub $sp, $sp, 4
	sw $t0, 0($sp)
	
	li $t0, %bit
	not $t0, $t0
	and %reg, %reg, $t0
	
	lw $t0, 0($sp)
	add $sp, $sp, 4
.end_macro


