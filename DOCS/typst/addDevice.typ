#set page(
  paper: "a4",
  margin: (top: 2cm, bottom: 2.5cm, left: 2cm, right: 2cm),
  header: align(right)[
    #text(size: 8pt, fill: rgb("#64748b"))[Guía de Desarrollo FemtoRV32 -- Integración de Periféricos]
  ],
  footer: [
    #line(length: 100%, stroke: 0.5pt + rgb("#cbd5e1"))
    #align(center)[
      #text(size: 8pt, fill: rgb("#64748b"))[FemtoSOC / FemtoRV32 Architecture Guide]
    ]
  ]
)

#set text(font: "Liberation Sans", lang: "es", size: 10pt)
#set par(justify: true, leading: 0.65em)

#show heading.where(level: 3): it => text(
  fill: rgb("#38bdf8"),
  it.body,
)

#show raw.where(block: true): it => block(
  fill: rgb("#f1f5f9"),          // Color de fondo gris suave
  stroke: 0.5pt + rgb("#cbd5e1"), // Borde gris
  radius: 6pt,                   // Esquinas redondeadas
  inset: 10pt,                   // Margen interno para que el código "respire"
  width: 100%,                   // Que ocupe todo el ancho del contenedor
  it                             // El contenido del bloque de código
)

// Título Principal
#align(center)[
  #block(
    fill: rgb("#0f172a"),
    inset: 16pt,
    radius: 6pt,
    width: 100%,
    [
      #text(fill: white, size: 18pt, weight: "bold")[Guia para añadir nuevo dispositivo al FemtoRV32]
      #v(2pt)
      #text(fill: rgb("#38bdf8"), size: 10pt, weight: "medium")[Integración Hardware (Verilog), Software (C/Assembly) y Mapeo I/O de Bajo Nivel]
    ]
  )
]

#v(1em)

== 1. Visión General de la Arquitectura I/O

En el SoC *FemtoSOC* (basado en el procesador *FemtoRV32*), la comunicación entre el núcleo RISC-V y los periféricos se realiza mediante *Memory-Mapped I/O (MMIO)* con esquemas de decodificación por *1-Hot Encoding*.

- *MMIO Base:* La dirección base I/O se activa cuando el bit 22 del bus de direcciones es igual a 1.
```c
(IO_BASE = 0x400000)
```
- *1-Hot Encoding:* Cada periférico tiene asignado un bit único dentro de la dirección de palabra (`word_addr`). Esto evita comparadores complejos y ahorra Look-Up Tables (LUTs) en la FPGA.
- *Recepción y Envío:* El periférico recibe la señal de selección `sel_xxx`, la señal de strobe de escritura `wstrb`, la dirección de palabra `mem_wordaddr` (si requiere registros internos) y los datos de escritura `wdata[31:0]`. Retorna datos de lectura `rdata[31:0]` y señales de estado de ocupado `wbusy` / `rbusy`.

#align(center)[
  ``` 
  CPU (SW) -> "Bus I/O (MMIO)" -> "Decoder (1-Hot)" -> "Módulo Hardware Periférico" 
  ```
]


== 2. Estructura de Archivos en la Carpeta `RTL/DEVICES/`

Dependiendo de la complejidad del nuevo periférico, la organización en el repositorio debe seguir estas pautas:

=== Caso A: Módulo Pequeño / Simple

Si el periférico es autocontenido y requiere pocos componentes (ejemplo: un controlador de matriz de LEDs `MAX7219` o un generador PWM básico):
- Se crea *un único archivo `.v`* directamente dentro de la carpeta `RTL/DEVICES/`.
- *Ruta:* `RTL/DEVICES/mi_periferico.v`

=== Caso B: Módulo Grande / Complejo

Si el periférico incluye submódulos, memorias dual-port, generadores de reloj o máquinas de estado compuestas (ejemplo: controlador de pantalla `HUB75`, acelerador gráfico `FGA`, o controlador `SDCard`):
- Se crea *una subcarpeta dedicada* dentro de `RTL/DEVICES/`.
- *Ruta:* `RTL/DEVICES/mi_periferico/`
- *Archivos interiores:* `mi_periferico_top.v`, `mi_periferico_mem.v`, `mi_periferico_pwm.v`.

=== Filosofía de Código: Evitar Abstracciones Innecesarias

Para mantener la naturaleza didáctica y ligera de FemtoRV:
- *No importar librerías externas complejas* ni wrappers opacos sin documentación.
- Diseñar código Verilog estándar y legible (Verilog-2001), fácilmente sintetizable por *Yosys*.
- Mantener la interfaz de bus simple (`clk`, `rst`, `sel`, `wstrb`, `wdata`, `rdata`).

---

== 3. Configuración del Sistema (`HardwareConfig_bits`)

FemtoSOC utiliza archivos de configuración para permitir la síntesis condicional de periféricos mediante flags.

=== 3.1 Archivo Verilog: `RTL/HardwareConfig_bits.v`

Se define una macro de compilación para habilitar o deshabilitar el dispositivo en hardware:
```verilog
// Activa o desactiva la síntesis del hardware en la FPGA
`define NRV_IO_MI_PERIFERICO
```

=== 3.2 Archivo C: `FIRMWARE/include/HardwareConfig_bits.h`

Se define el índice de bit único (1-Hot bit ID) asignado al periférico:

```c
// Define la posición del bit en el bus de direcciones para el periférico
#define IO_MI_PERIFERICO_bit 5
```

== 4. Conexión Hardware en `femtosoc.v`

El archivo `RTL/femtosoc.v` es el módulo principal del SoC donde se interconectan la CPU, la memoria RAM y todos los dispositivos I/O.

=== Paso 1: Decodificación del Strobe de Selección (1-Hot)

```verilog
`ifdef NRV_IO_MI_PERIFERICO
  wire sel_mi_periferico = isIO && mem_wordaddr[IO_MI_PERIFERICO_bit];
`endif
```

=== Paso 2: Instanciación del Módulo Verilog

```verilog
`ifdef NRV_IO_MI_PERIFERICO
  wire [31:0] mi_periferico_rdata;
  wire        mi_periferico_wbusy;
  wire        mi_periferico_rbusy;

  mi_periferico U_mi_periferico (
      .clk      (clk),
      .rst      (!resetn),
      .sel      (sel_mi_periferico),
      .wstrb    (mem_wstrb),
      .wdata    (mem_wdata),
      .word_addr(mem_wordaddr), // Si utiliza múltiples registros internos
      .rdata    (mi_periferico_rdata),
      .wbusy    (mi_periferico_wbusy),
      .rbusy    (mi_periferico_rbusy),
      // Pines físicos de la FPGA
      .PIN_OUT  (MI_PERIFERICO_PIN)
  );
`endif
```

=== Paso 3: Multiplexado de Datos de Lectura y Estado (`OR` Lógico)

En FemtoSOC, las señales de retorno de todos los dispositivos se unen mediante operaciones *OR a nivel de bits*:

```verilog
// Unificación del bus de lectura RDATA
wire [31:0] IO_rdata =
    (sel_uart   ? uart_rdata   : 32'b0) |
`ifdef NRV_IO_MI_PERIFERICO
    (sel_mi_periferico ? mi_periferico_rdata : 32'b0) |
`endif
    32'b0;

// Unificación de señales de ocupado (Busy)
wire IO_wbusy = uart_wbusy
`ifdef NRV_IO_MI_PERIFERICO
    || mi_periferico_wbusy
`endif
    ;
```

== 5. Integración en Software (`femtoRV32.h` y Drivers C)
Para interactuar con el periférico desde programas en C o Ensamblador:

=== 5.1 Registro en `femtoRV32.h`

Se declara la dirección del puerto utilizando la macro `IO_BIT_TO_OFFSET`:

```c
// Conversión de bit 1-Hot a dirección de byte MMIO
#define IO_MI_PERIFERICO IO_BIT_TO_OFFSET(IO_MI_PERIFERICO_bit)
```

=== 5.2 Funciones / Macros de Acceso en C
```c
// Funciones inline o macros para lectura y escritura directa
static inline void mi_periferico_write(uint32_t val) {
    IO_OUT(IO_MI_PERIFERICO, val);
}

static inline uint32_t mi_periferico_read(void) {
    return IO_IN(IO_MI_PERIFERICO);
}
```

== 6. Resumen del Flujo Completo

Cuando la CPU ejecuta IO_OUT(IO_MI_PERIFERICO, val) en C:
1. El procesador emite una dirección de byte con bit 22=1 y bit (2+ID)=1.
2. El hardware decodifica sel_mi_periferico = 1 en un solo ciclo de reloj.
3. El módulo Verilog detecta el strobe wstrb y captura wdata enviando la señal a los pines físicos.
4. Si el software realiza una lectura IO_IN, el módulo devuelve rdata a través de la red OR del SoC.
