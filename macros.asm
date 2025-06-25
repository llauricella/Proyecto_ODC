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

# Almacena %addr(%idx * 4) en %reg
# Registros $t8 y $t9 reservados
.macro get_from_array(%reg, %addr, %idx)
	# Pushea $t8, $t9 al stack para preservar sus valores
	sub $sp, $sp, 8
	sw $t8, 4($sp)
	sw $t9, 0($sp)
	
	li $t8, %idx
	mul $t9, $t8, 4
	
	la $t8, %addr
	add $t8, $t8, $t9
	lw %reg, ($t8)
	
	# Restaura los registros $t8, $t9 del stack
	lw $t9, 0($sp)
	lw $t8, 4($sp)
	add $sp, $sp, 8
.end_macro
