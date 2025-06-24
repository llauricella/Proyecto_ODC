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
	