#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import time
from utils.db_utils import get_connection #, execute_sql_file # No longer using execute_sql_file

def clean_aux_tables(sql_filename="step3_clean_aux_tables.sql"):
    """Ejecuta el script SQL para limpiar tablas auxiliares."""
    conn = None
    cursor = None
    start_time = time.time()
    print(f"--- Iniciando Paso 3: Limpieza de Tablas Auxiliares ({sql_filename}) ---")
    rows_affected = 0
    success = False

    try:
        script_dir = os.path.dirname(__file__)
        sql_file_path = os.path.join(script_dir, '..', 'sql', sql_filename)

        conn = get_connection()
        if not conn:
            print("Error: No se pudo establecer conexión a la base de datos.")
            return False
        
        print(f"Conexión a la base de datos establecida con éxito.")
        print(f"Leyendo archivo SQL: {sql_file_path}")

        with open(sql_file_path, 'r', encoding='utf-8') as f:
            sql_content = f.read()

        # 1. Eliminar líneas de comentario y limpiar espacios en blanco
        lines = sql_content.splitlines()
        cleaned_lines = [line for line in lines if not line.strip().startswith('--')]
        cleaned_sql = "\n".join(cleaned_lines).strip() # Unir líneas de nuevo y quitar espacios extra

        if not cleaned_sql:
            print("El archivo SQL está vacío o solo contiene comentarios. No hay nada que ejecutar.")
            success = True
        else:
            # 2. Dividir el SQL limpio por punto y coma; filtrar cadenas vacías
            commands = [cmd.strip() for cmd in cleaned_sql.split(';') if cmd.strip()]

            # Caso especial: si cleaned_sql no estaba vacío pero no se encontraron comandos
            # (p.ej., una sola sentencia sin punto y coma al final), tratar todo como un comando.
            if not commands and cleaned_sql:
                commands = [cleaned_sql]

            if not commands:
                 # Esto no debería ocurrir si cleaned_sql tenía contenido, pero por seguridad:
                 print("No se encontraron comandos SQL ejecutables después de limpiar comentarios y líneas vacías.")
                 success = True # Considerar éxito si no hay nada que ejecutar
            else:
                print(f"Se encontraron {len(commands)} comandos SQL para ejecutar.")
                cursor = conn.cursor()
                # Ejecutar el/los comando(s) - asumiendo un comando basado en el archivo SQL
                # Para múltiples comandos, iterar sobre `commands`
                print(f"Ejecutando SQL:\n{commands[0][:200]}...") # Imprimir inicio del comando
                cursor.execute(commands[0])
                rows_affected = cursor.rowcount if cursor.rowcount is not None else 0
                conn.commit()
                print(f"Comando SQL ejecutado con éxito.")
                success = True

        if success:
            # Mensaje actualizado para ser más específico
            print(f"Limpieza completada. {rows_affected} filas afectadas.") # Mensaje genérico de filas afectadas
        
        return success

    except Exception as e:
        print(f"\nError inesperado en el Paso 3: {e}")
        if conn:
            conn.rollback() # Rollback on error
        return False
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
            print("Conexión a la base de datos cerrada.")
        end_time = time.time()
        print(f"--- Paso 3 finalizado en {end_time - start_time:.2f} segundos ---")

if __name__ == "__main__":
    success = clean_aux_tables()
    sys.exit(0 if success else 1)
