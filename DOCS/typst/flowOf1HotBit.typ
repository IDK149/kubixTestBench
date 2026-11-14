#import "@preview/bytefield:0.0.8": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import fletcher.shapes: diamond

#set page(
  paper: "a4",
  margin: (x: 2cm, y: 2.5cm),
  header: align(right)[
    #text(size: 8pt, fill: luma(120))[Arquitectura FemtoRV + HUB75 — Mapeo de Memoria y Flujo de Bits]
  ],
)

#let todo(content) = box(
  fill: rgb("#f1f5f9"),
  stroke: 1pt + rgb("#64748b"),
  radius: 4pt,
  inset: 8pt,
  width: 100%,
  [
    #text(fill: rgb("#0f172a"), weight: "bold")[📌 TODO: ]
    #text(fill: rgb("#0f172a"))[#content]
  ],
)

#let warning(content) = box(
  fill: rgb("#fef3c7"),
  stroke: 1pt + rgb("#f59e0b"),
  radius: 4pt,
  inset: 8pt,
  width: 100%,
  [
    #text(fill: rgb("#b45309"), weight: "bold")[⚠️ ADVERTENCIA: ]
    #text(fill: rgb("#b45309"))[#content]
  ],
)

#let note(content) = box(
  fill: rgb("#eff6ff"),
  stroke: 1pt + rgb("#3b82f6"),
  radius: 4pt,
  inset: 8pt,
  width: 100%,
  [
    #text(fill: rgb("#1d4ed8"), weight: "bold")[📝 NOTA: ]
    #text(fill: rgb("#1d4ed8"))[#content]
  ],
)

#set text(
  font: "Liberation Sans",
  size: 10pt,
  lang: "es",
)

#let secondary-color = rgb("#0284c7")
#let accent-color = rgb("#1e3a8a")
#let bg-light = rgb("#f8fafc")

// Document Title
#align(center)[
  #block(
    fill: accent-color,
    inset: 16pt,
    radius: 6pt,
    width: 100%,
    [
      #text(fill: white, weight: "bold", size: 18pt)[Flujo de bits FemtoRV32 (ejemplo HUB75)] \
      #v(4pt)
      #text(fill: rgb("#cbd5e1"), size: 11pt)[Desde C (Software) hasta la Memoria BRAM y la Pantalla HUB75 en FemtoRV32]
    ],
  )
]

#v(12pt)

== Resumen del Flujo de Datos

El sistema transmite datos de color desde el procesador *FemtoRV32* (escritura en C) hacia la pantalla LED *HUB75* dividiendo la responsabilidad entre software y hardware:

1. *Software en C:* Calcula la coordenada lineal del píxel, aplica alineación de palabras y codificación _1-Hot_ para I/O.
2. *Bus del CPU (RISC-V):* Envía una dirección de byte de 32 bits y un dato RGB444 de 12 bits en paralelo.
3. *Decodificador Verilog (`hub75.v`):* Separa los bits de dirección para seleccionar la capa (_Background_, _Sprite_, _Text_) y empaqueta la dirección compacta de la RAM de 12 bits.
4. *Memoria de Video (`panel_memory.v`):* Almacena los píxeles en tres bloques BRAM independientes de 4096 casilleros.
5. *Controlador de Barrido HUB75:* Lee continuamente la RAM, aplica lógica de prioridad entre capas y serializa los bits de color hacia los pines físicos del panel LED.

== Estructura de la Dirección de Memoria en el Bus C / CPU (32 bits)

En C, la dirección completa se construye mediante la expresión:
#align(center)[
  ```c
  // FIRMAWARE/PROGRAMS/include/hub75.h
  volatile uint32_t *ptr = (volatile uint32_t *)(HUB75_BASE_ADDR | layer | address_offset);
  ```
]

#show table.cell.where(y: 0): set text(fill: white, weight: "bold")

== Mapa de Bits Jerárquico del Registro HUB75
La siguiente tabla representa el mapa de bits del bus de direcciones de 32 bits enviado por la CPU:

#align(center)[
  #v(0.8em)

  #bytefield(
    bitheader(
      "bits",
      0,
      [],
      1,
      [],
      2,
      [],
      3,
      [],
      4,
      [],
      5,
      [],
      6,
      [],
      7,
      [],
      8,
      [],
      9,
      [],
      10,
      [],
      11,
      [],
      12,
      [],
      13,
      [],
      14,
      [],
      15,
      [],
      16,
      [],
      17,
      [],
      18,
      [],
      19,
      [],
      20,
      [],
      21,
      [],
      22,
      [],
      23,
      [],
      24,
      [],
      25,
      [],
      26,
      [],
      27,
      [],
      28,
      [],
      29,
      [],
      30,
      [],
      31,
      [],
      angle: -45deg,
      text-size: 7pt,
    ),

    bits(2, fill: rgb("#e2e8f0"))[--],
    bits(8, fill: rgb("#fde68a"))[Col/X],
    bits(1, fill: rgb("#e2e8f0"))[--],
    bits(4, fill: rgb("#bbf7d0"))[Row/Y],
    bits(2, fill: rgb("#fed7aa"))[Capa],
    bits(15, fill: rgb("#f1f5f9"))[--],

    bits(23, fill: rgb("#bae6fd").lighten(50%))[BASE ADDRESS],
    bits(9, fill: rgb("#f1f5f9").lighten(50%))[--],
  )
]

== 3. Transformación de Coordenadas y Remapeo de Bits (Bit-Slicing)



#align(center)[
  #block(
    fill: bg-light,
    inset: 10pt,
    radius: 4pt,
    stroke: 1pt + red,
    [

      *RECOMENDACIÓN*:  \
      Se recomienda para esta sección revisar directamente el código. Se citarán todos los archivos donde esté definido el código que se mencione.

    ],
  )
]

=== A. De Coordenada 2D $(x,y)$ a Dirección Lineal `pixel_addr`
Para un panel de $64 times 64$ píxeles:
$ text("pixel_addr") = (y times 64) + x quad text("rango: 0 a 4095") $
- *Bits [7:0] de `pixel_addr`:* Posición X (Columna).
- *Bits [11:8] de `pixel_addr`:* Posición Y (Fila).

=== B. Desplazamiento en C (`address_offset`)
```c
uint32_t address_offset = ((pixel_addr & 0x00FFU) << 2) | ((pixel_addr & 0x0F00U) << 3);
```
- `<< 2`: Alinea los 8 bits bajos a la palabra de 32 bits de RISC-V (multiplica por 4 bytes).
- `<< 3`: Alinea los 4 bits altos e introduce un salto en el bit 10 para coincidir con la alineación de buffer en C.

=== C. Reorganización en Verilog (`wr_addr`)
Cuando el bus llega a Verilog, la señal `word_addr` (que es `byte_addr >> 2`) se reestructura omitiendo el bit 8 sobrante para guardar los datos de forma continua en BRAM:
```verilog
wire [1:0]  wr_sel  = word_addr[14:13];
wire [11:0] wr_addr = {word_addr[12:9], word_addr[7:0]};
wire [11:0] wr_data = wdata[11:0]; // Formato RGB444 (4b R, 4b G, 4b B)
```

#align(center)[
  #block(
    fill: bg-light,
    inset: 10pt,
    radius: 4pt,
    stroke: 1pt + secondary-color,
    [
      *Esquema de Ensamblado de `wr_addr` en Verilog:* \
      `word_addr[12:9]` (4 bits de Y) $+$ `word_addr[7:0]` (8 bits de X) $arrow$ *`wr_addr[11:0]`* (12 bits continua para BRAM)
    ],
  )
]

== 4. Estructura de Capas y Prioridad Visual en `panel_memory.v`

La memoria `panel_memory` contiene *3 bancos BRAM independientes* (4096 casilleros de 12 bits cada uno). `wr_sel` decide cuál se escribe:

- `2'b00`: `BACKGROUND_MEM` (Fondo)
- `2'b01`: `SPRITE_MEM` (Sprites / Personajes)
- `2'b10`: `TEXT_MEM` (Texto / Interfaz OSD)

=== Lógica de Prioridad de Lectura para la Pantalla:
Durante el escaneo del panel LED, la pantalla lee simultáneamente la misma dirección `addr_top` / `addr_bottom` en las tres memorias y combina el color final:

```verilog
// RTL/DEVICES/hub75/panel_memory.v
if (text_top != 12'b0)
    pix_top = text_top;       // 1° Prioridad: Texto
else if (sprite_top != 12'b0)
    pix_top = sprite_top;     // 2° Prioridad: Sprite
else
    pix_top = background_top; // 3° Prioridad: Fondo
```

== 5. Diagrama del Flujo (Ejemplo)
#align(center)[
  #v(1em)

  #diagram(
    node-stroke: 1pt + rgb("#cbd5e1"),
    node-fill: rgb("#f8fafc"),
    node-inset: 10pt,
    spacing: (15pt, 25pt),

    // --- NODO 1: SOFTWARE EN C ---
    node((0, 0), align(left)[
      #text(weight: "bold", fill: rgb("#0f172a"))[1. SOFTWARE EN C] \
      #v(3pt)
      `hub75_draw_pixel(LAYER_SPRITE, x=15, y=2, color=0x0F00);` \
      #text(size: 8.5pt, fill: rgb("#64748b"))[
        Calcula: pixel_addr = 143 (0x08F) -> address_offset \
        Escribe en ptr: 0x4000283C (32 bits)
      ]
    ], width: 360pt, fill: rgb("#ffffff")),

    // --- FLECHA 1 ---
    edge((0, 0), (0, 2), "-|>", label: text(size: 8pt)[Bus RISC-V (32-bit Memory Address & Data)], label-side: right),

    // --- NODO 2: DECODIFICACIÓN HARDWARE ---
    node((0, 2), align(left)[
      #text(weight: "bold", fill: rgb("#0f172a"))[2. DECODIFICACIÓN HARDWARE (top / hub75.v)] \
      #v(3pt)
      #text(size: 8.5pt)[
        Bit 22 = 1 --\> sel_hub75 = 1 (Activa el módulo) \
        word_addr[14:13] = 2'b01 --\> wr_sel = SPRITE_MEM \
        {word_addr[12:9], word_addr[7:0]} --\> wr_addr = 143 \
        wdata[11:0] --\> wr_data = 12'b1111_0000_0000 (Rojo RGB444)
      ]
    ], width: 360pt, fill: rgb("#fef3c7")),

    // --- FLECHA 2 ---
    edge((0, 2), (0, 4), "-|>", label: text(size: 8pt)[Flanco Positivo de Reloj (posedge clk)], label-side: right),

    // --- NODO 3: ALMACENAMIENTO EN BRAM ---
    node((0, 4), align(left)[
      #text(weight: "bold", fill: rgb("#0f172a"))[3. ALMACENAMIENTO EN BRAM (panel_memory.v)] \
      #v(3pt)
      #text(size: 8.5pt)[
        SPRITE_MEM[143] \<= 12'b1111_0000_0000;
      ]
    ], width: 360pt, fill: rgb("#f1f5f9")),

    // --- FLECHA 3 ---
    edge((0, 4), (0, 6), "-|>", label: text(size: 8pt)[Barrido Continuo (scan_counter.v)], label-side: right),

    // --- NODO 4: LECTURA Y SALIDA FÍSICA HUB75 ---
    node((0, 6), align(left)[
      #text(weight: "bold", fill: rgb("#0f172a"))[4. LECTURA Y SALIDA FÍSICA HUB75] \
      #v(3pt)
      #text(size: 8.5pt)[
        scan_counter le pide addr_top = 143 a la BRAM \
        MUX de prioridad evalúa: text=0, sprite=Rojo --\> pix_top = Rojo \
        Deserializador envía R0, G0, B0 + clk_out + latch + oe al panel LED
      ]
    ], width: 360pt, fill: rgb("#dcfce7")),
  )
]
