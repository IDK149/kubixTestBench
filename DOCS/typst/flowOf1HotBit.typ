#import "@preview/bytefield:0.0.8": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import fletcher.shapes: diamond

#set page(
  paper: "a4",
  margin: (x: 2cm, y: 2.5cm),
  header: align(right)[
    #text(size: 8pt, fill: luma(120))[Controlador LED FemtoRV — Mapeo de Memoria y Flujo de Bits]
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
      #text(fill: white, weight: "bold", size: 18pt)[Control de LED en FemtoRV32] \
      #v(4pt)
      #text(fill: rgb("#cbd5e1"), size: 11pt)[Desde C (Software) hasta el Registro Interno y el Pin Físico]
    ],
  )
]

#v(12pt)

== Resumen del Flujo de Datos

El sistema transmite comandos de control de encendido/apagado desde el procesador *FemtoRV32* (escritura en C) hacia el pin físico del LED mediante el siguiente flujo:

1. *Software en C:* Escribe un valor binario (`0` o `1`) dirigido a la dirección base asignada al periférico `leds`.
2. *Bus del CPU (RISC-V):* Envía las señales de control de bus (`sel`, `wstrb`, `rstrb`) junto con el dato de 32 bits (`wdata`).
3. *Decodificador Hardware (`leds.v`):* Evalúa la selección del módulo y el estrobo de escritura para actualizar el registro interno `led_state`.
4. *Salida Física:* El estado almacenado controla directamente el pin `LED` y retroalimenta la lectura a través de `rdata`.

== Estructura del Módulo Verilog

El módulo hardware implementa la lógica de selección de bus, almacenamiento síncrono del estado y lectura combinacional:

#align(center)[
  #block(
    fill: bg-light,
    inset: 10pt,
    radius: 4pt,
    stroke: 1pt + secondary-color,
    [
      ```verilog
      module leds (
          input clk,
          input rstrb,
          input wstrb,
          input sel,
          input [31:0] wdata,
          output [31:0] rdata,
          output wire LED
      );
          reg led_state;
          
          assign LED   = led_state;
          assign rdata = (sel ? {31'b0, led_state} : 32'b0);

          always @(posedge clk) begin
              if (sel && wstrb) begin
                  led_state <= wdata[0];
              end
          end
      endmodule
      ```
    ],
  )
]

== Operación y Lógica de Bits

=== A. Escritura en el Registro (`wstrb`)
El cambio de estado ocurre exclusivamente en el flanco positivo del reloj (`posedge clk`) cuando las condiciones del bus periférico se cumplen:
- `sel`: El circuito periférico está seleccionado en el mapa de memoria.
- `wstrb`: La señal de escritura (`write strobe`) está activa.
- `wdata[0]`: El bit menos significativo determina si el LED se enciende (`1`) o se apaga (`0`).

=== B. Lectura del Estado (`rdata`)
Cuando el bus solicita una lectura (`sel` activo), el hardware devuelve el estado actual del LED posicionado en el bit menos significativo de la palabra de 32 bits, rellenando los 31 bits restantes con ceros (`31'b0`).

== Diagrama del Flujo de Ejecución

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
      `*(volatile uint32_t *)LEDS_ADDR = 0x01;` \
      #text(size: 8.5pt, fill: rgb("#64748b"))[
        Envía una orden de encendido escribiendo sobre el espacio de memoria mapeado.
      ]
    ], width: 360pt, fill: rgb("#ffffff")),

    // --- FLECHA 1 ---
    edge((0, 0), (0, 2), "-|>", label: text(size: 8pt)[Bus RISC-V (sel, wstrb, wdata)], label-side: right),

    // --- NODO 2: HARDWARE LEDS ---
    node((0, 2), align(left)[
      #text(weight: "bold", fill: rgb("#0f172a"))[2. CONTROLADOR LEDS (`leds.v`)] \
      #v(3pt)
      #text(size: 8.5pt)[
        Validación: si (`sel && wstrb`) se activa en el flanco de subida... \
        `led_state <= wdata[0];`
      ]
    ], width: 360pt, fill: rgb("#fef3c7")),

    // --- FLECHA 2 ---
    edge((0, 2), (0, 4), "-|>", label: text(size: 8pt)[Flanco Positivo de Reloj (posedge clk)], label-side: right),

    // --- NODO 3: SALIDA FÍSICA ---
    node((0, 4), align(left)[
      #text(weight: "bold", fill: rgb("#0f172a"))[3. SALIDA FÍSICA Y RETROALIMENTACIÓN] \
      #v(3pt)
      #text(size: 8.5pt)[
        `LED = led_state;` (Control directo del pin de hardware) \
        `rdata = {31'b0, led_state};` (Disponible para lectura del CPU)
      ]
    ], width: 360pt, fill: rgb("#dcfce7")),
  )
]
