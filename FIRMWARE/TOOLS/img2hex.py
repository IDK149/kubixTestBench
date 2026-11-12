import argparse
import os
from PIL import Image

def append_images_to_assets(images_dir, output_path="./include/assets.h", format_type="rgb444"):
    if not os.path.exists(images_dir):
        print(f"Error: El directorio '{images_dir}' no existe.")
        return

    # Asegurarnos de que el directorio de salida exista
    out_dir = os.path.dirname(output_path)
    if out_dir and not os.path.exists(out_dir):
        os.makedirs(out_dir)

    append_content = ""
    processed_count = 0

    for filename in sorted(os.listdir(images_dir)):
        if filename.lower().endswith(".png"):
            image_path = os.path.join(images_dir, filename)
            output_name = os.path.splitext(filename)[0]
            
            try:
                img = Image.open(image_path).convert("RGB")
                width, height = img.size
                
                append_content += f"const uint16_t {output_name}[{width * height}] = {{\n"
                
                for y in range(height):
                    row_str = "    "
                    for x in range(width):
                        r, g, b = img.getpixel((x, y))
                        
                        if format_type == "rgb565":
                            val = ((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3)
                        elif format_type == "rgb444":
                            val = ((r >> 4) << 8) | ((g >> 4) << 4) | (b >> 4)
                        elif format_type == "rgb332":
                            val = ((r >> 5) << 5) | ((g >> 5) << 2) | (b >> 6)
                        else:
                            val = 0
                            
                        row_str += f"0x{val:04X}, "
                    append_content += row_str + "\n"
                    
                append_content += "};\n\n"
                processed_count += 1
                print(f"Convertida: {filename} -> {output_name} ({width}x{height})")
            except Exception as e:
                print(f"Error procesando {filename}: {e}")
                
    if processed_count > 0:
        # Usamos 'w' para sobreescribir y evitar duplicados si corres el script varias veces,
        # cámbialo a 'a' si prefieres anexarlo manualmente.
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(append_content)
        print(f"\n¡Éxito! Archivo generado en: {output_path}")
    else:
        print("No se encontraron imágenes PNG válidas para procesar.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convierte imágenes PNG a arreglos C (arrays) para assets.")
    
    parser.add_argument("-i", "--input", required=True, help="Directorio que contiene las imágenes PNG.")
    parser.add_argument("-o", "--output", default="./include/assets.h", help="Ruta del archivo de salida .h (por defecto: ./include/assets.h)")
    parser.add_argument("-f", "--format", default="rgb444", choices=["rgb565", "rgb444", "rgb332"], help="Formato de color (rgb565, rgb444 o rgb332)")

    args = parser.parse_args()
    
    append_images_to_assets(
        images_dir=args.input, 
        output_path=args.output, 
        format_type=args.format
    )
