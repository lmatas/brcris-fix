#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import time
import sys
import os
import xxhash
# Importar directamente desde el subdirectorio utils
from utils.db_utils import get_connection, print_progress, generate_xxhash64_int

def load_semantic_ids(input_filename="valid_semantic_ids.txt"):
    """
    Lee identificadores semánticos de un archivo, calcula su hash xxhash64,
    e inserta el hash (id) y el identificador (semantic_id) en la tabla
    aux_valid_orgunit_semantic_id.
    """
    # Construir la ruta completa al archivo de entrada relativo al directorio padre (orgunit/)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    input_filepath = os.path.abspath(os.path.join(script_dir, '..', input_filename))

    print(f"Iniciando carga desde el archivo: {input_filepath}")
    print("=" * 80)

    conn = None
    processed = 0
    inserted = 0
    skipped_duplicates = 0
    skipped_empty = 0
    total_lines = 0
    commit_batch_size = 1000 # Hacer commit cada N inserciones

    try:
        # Contar líneas primero para la barra de progreso
        print("Contando líneas en el archivo...")
        with open(input_filepath, 'r', encoding='utf-8') as f:
            # Contar solo líneas no vacías y sin espacios en blanco
            total_lines = sum(1 for line in f if line.strip())
        print(f"Se encontraron {total_lines} identificadores no vacíos para procesar.")

        if total_lines == 0:
            print("El archivo está vacío o no contiene líneas válidas. No hay nada que cargar.")
            return True

        # Conectar a la base de datos
        print("Conectando a la base de datos...")
        conn = get_connection()
        if not conn:
            print("Error: No se pudo establecer conexión a la base de datos.")
            return False

        cursor = conn.cursor()
        start_time = time.time()

        print("Procesando archivo e insertando en la base de datos...")
        with open(input_filepath, 'r', encoding='utf-8') as f:
            for line in f:
                semantic_id = line.strip()

                if not semantic_id:
                    skipped_empty += 1
                    continue # Saltar líneas vacías

                # Calcular hash usando la función importada de db_utils
                hash_id = generate_xxhash64_int(semantic_id)

                # Intentar insertar
                insert_query = """
                    INSERT INTO aux_valid_orgunit_semantic_id (id, semantic_id)
                    VALUES (%s, %s)
                    ON CONFLICT (id) DO NOTHING;
                """
                try:
                    cursor.execute(insert_query, (hash_id, semantic_id))
                    # rowcount indica si se insertó (1) o si hubo conflicto (0)
                    if cursor.rowcount > 0:
                        inserted += 1
                    else:
                        skipped_duplicates +=1

                    processed += 1

                    # Hacer commit en lotes y mostrar progreso
                    if processed % commit_batch_size == 0:
                        conn.commit()
                        print_progress(processed, total_lines, start_time)

                except Exception as insert_error:
                    conn.rollback() # Revertir lote actual en caso de error inesperado
                    print(f"\nError insertando ID: {semantic_id} (Hash: {hash_id}): {insert_error}")
                    # Considerar si continuar o detenerse. Aquí continuamos.
                    # return False # Descomentar para detener en el primer error

        # Confirmar cambios finales que no llegaron al tamaño del lote
        conn.commit()
        print_progress(processed, total_lines, start_time) # Actualización final del progreso

        # Mostrar resumen final
        total_time = time.time() - start_time
        print(f"\n\nCarga completada con éxito.")
        print(f"Tiempo total: {total_time/60:.2f} minutos ({total_time:.2f} segundos)")
        print(f"Líneas procesadas (no vacías): {processed}/{total_lines}")
        print(f"Registros insertados: {inserted}")
        print(f"Registros omitidos (ID duplicado): {skipped_duplicates}")
        print(f"Líneas vacías omitidas: {skipped_empty}")
        if total_time > 0:
             print(f"Velocidad media: {processed/total_time:.2f} registros por segundo")

        return True

    except FileNotFoundError:
        print(f"\nError: El archivo '{input_filepath}' no fue encontrado.")
        return False
    except Exception as e:
        print(f"\nError inesperado durante el proceso: {e}")
        if conn:
            conn.rollback() # Asegurar rollback en caso de error general
        return False
    finally:
        if conn:
            conn.close()
            print("Conexión a la base de datos cerrada.")

if __name__ == "__main__":
    # El nombre del archivo se asume relativo al directorio padre (orgunit/)
    # Se busca 'valid_semantic_ids.txt' en /Users/lmatas/source/brcris_fix/orgunit/
    filename = "valid_semantic_ids.txt"
    success = load_semantic_ids(filename)
    sys.exit(0 if success else 1)