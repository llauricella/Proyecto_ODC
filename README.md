# Battleship MIPS R2000
Recreación del juego de mesa BattleShip para el microprocesador MIPS R2000.

## Configuración
El juego está diseñado para ser ensamblado y utilizado con [MARS](https://dpetersanderson.github.io/).
El Bitmap Display debe ser configurado con los siguientes ajustes:
- **Unit Width in Pixels**: 16
- **Unit Height in Pixels**: 16
- **Display Width in Pixels**: 256
- **Display Height in Pixels**: 512
- **Base address for display**: 0x10010000 (static data)

## To-do
- [x] Inicialización del juego
- [x] Colocación de barcos
- [x] Motor de turnos
- [x] IA básica para la CPU
- [ ] IA de la CPU
- [ ] Comodín
- [x] Interfaz gráfica
- [x] Detección de hundimiento
- [x] Validación de colisiones

## Autores
- Naim Demian
- Luigi Lauricella