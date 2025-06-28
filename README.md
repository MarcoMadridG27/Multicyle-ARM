
# Implementación del Procesador ARM Multi-Ciclo

Este proyecto se enfoca en diseñar e implementar una versión simplificada del procesador ARMv4 con soporte multi-ciclo. El procesador es capaz de ejecutar instrucciones de procesamiento de datos como `ADD`, `SUB`, `AND`, `ORR`, así como instrucciones de carga/almacenamiento como `LDR` y `STR`. Una de las principales características añadidas a esta implementación es la instrucción `MUL` (multiplicación).

## Visión General del Proyecto

El objetivo de este proyecto es diseñar un procesador ARM multi-ciclo que pueda ejecutar eficientemente un conjunto de instrucciones ARMv4 a lo largo de varios ciclos de reloj. Este enfoque aumenta el control sobre la ejecución de las instrucciones, permitiendo una mayor flexibilidad y eficiencia.

### Características Clave

- **Arquitectura Multi-Ciclo**: Cada instrucción se ejecuta en varios ciclos de reloj, lo que permite un mejor control sobre la memoria, el registro de instrucciones y la ALU (Unidad Aritmético-Lógica).
- **Instrucción MUL**: La operación de multiplicación (`MUL`) fue integrada en el procesador, requiriendo modificaciones al datapath y la unidad de control para manejar esta instrucción.
- **Unidad de Control**: La unidad de control genera las señales necesarias para coordinar las etapas del procesamiento de instrucciones.
- **Datapath**: El datapath maneja el flujo de datos entre los registros y las unidades de procesamiento, como la ALU y la memoria.

## Implementación de la Instrucción MUL

La implementación de la instrucción `MUL` representó un desafío particular, ya que requirió cambios tanto en la unidad de control como en el datapath para manejar adecuadamente la operación de multiplicación.

### Cambios en la Unidad de Control

- Se agregó un nuevo estado a la máquina de estados finita (FSM) para manejar la ejecución de la instrucción `MUL`.
- El decodificador de instrucciones en la unidad de control fue modificado para reconocer la instrucción `MUL` verificando los bits correspondientes en la instrucción.

**Ejemplo de fragmento de código para el manejo de estado FSM para `MUL`**:

```verilog
// Agregar un nuevo estado para la ejecución de MUL en la FSM
localparam [3:0] EXECUTEMUL = 11; // Estado para multiplicación
...
// Lógica para transitar al estado EXECUTEMUL cuando se detecta la instrucción MUL
always @(*) begin
    casex (state)
        DECODE:
            case (Op)
                2'b00: if (Funct[5:4] == 2'b00 && MulFunct == 4'b1001) 
                        nextstate = EXECUTEMUL; // Transición al estado MUL
                ...
            endcase
        ...
    endcase
end
```

### Cambios en el Datapath

El datapath fue modificado para incluir lógica que detecta la instrucción `MUL` y selecciona los registros correctos para los operandos. Específicamente, se añadieron multiplexores para elegir los registros correctos según si la instrucción es `MUL`.

**Fragmento de código para detectar `MUL` en el datapath**:

```verilog
// Detectando la instrucción MUL
assign is_mul = (Instr[27:22] == 6'b000000) && (Instr[7:4] == 4'b1001);

// Modificando los multiplexores para seleccionar los operandos correctos para MUL
mux2 #(4) ra1mux(
    .d0(is_mul ? Instr[3:0] : Instr[19:16]), // Rn para MUL
    .d1(4'b1111),
    .s(RegSrc[0]),
    .y(RA1)
);

mux2 #(4) ra2mux(
    .d0(is_mul ? Instr[11:8] : Instr[3:0]), // Rm para MUL
    .d1(Instr[15:12]),
    .s(RegSrc[1]),
    .y(RA2)
);
```

### Instrucciones de Prueba y Resultado Esperado

El procesador fue probado con una serie de instrucciones, incluyendo la instrucción `MUL`. A continuación se muestra el conjunto de instrucciones usadas en la prueba, así como el resultado esperado para `WriteData`:

**Instrucciones de Prueba (memfile)**:

```
SUB R0, R15, R15
ADD R2, R0, #2
ADD R3, R0, #3
MUL R4, R2, R3
LDR R5, =100
STR R4, [R5]
```

- **Paso 1**: La primera instrucción (`SUB R0, R15, R15`) establece `R0` a 0.
- **Paso 2**: `ADD R2, R0, #2` establece `R2` a 2.
- **Paso 3**: `ADD R3, R0, #3` establece `R3` a 3.
- **Paso 4**: La instrucción `MUL R4, R2, R3` multiplica `R2` (2) y `R3` (3), almacenando el resultado (6) en `R4`.
- **Paso 5**: `LDR R5, =100` carga la dirección 100 en `R5`.
- **Paso 6**: `STR R4, [R5]` almacena el valor de `R4` (que es 6) en la dirección de memoria `100`.

**Resultado Esperado**:

Al final de la ejecución, el valor de `WriteData` debería ser `6`, ya que el resultado de la multiplicación se almacena en la dirección `100`.

## Conclusión

Esta implementación integra con éxito la instrucción `MUL` en el procesador ARM multi-ciclo. Ahora, el procesador puede realizar multiplicación junto con otras operaciones básicas como adición, sustracción y operaciones lógicas. El programa de prueba verificó con éxito que el procesador puede manejar la instrucción de multiplicación y almacenar el resultado en la memoria como se esperaba.

Para obtener una visión detallada de toda la implementación, incluido el código fuente, consulte el repositorio de GitHub:

[Repositorio GitHub: Multicycle-ARM](https://github.com/MarcoMadridG27/Multicyle-ARM)
