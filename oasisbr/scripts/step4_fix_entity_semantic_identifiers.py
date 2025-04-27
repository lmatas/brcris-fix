#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import time
from utils.db_utils import get_connection #, execute_sql_file # No longer using execute_sql_file

def fix_semantic_identifiers(sql_filename="step4_fix_entity_semantic_identifiers.sql"):
    """Ejecuta el script SQL para corregir identificadores semánticos."""
    conn = None
    cursor = None
    start_time = time.time()
    print(f"--- Iniciando Paso 4: Corrección de Identificadores Semánticos ({sql_filename}) ---")
    total_rows_affected = 0
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
                 print("No se encontraron comandos SQL ejecutables después de limpiar comentarios y líneas vacías.")
                 success = True # Considerar éxito si no hay nada que ejecutar
            else:
                print(f"Se encontraron {len(commands)} comandos SQL para ejecutar.")
                cursor = conn.cursor()
                
                for i, command in enumerate(commands):
                    command_start_time = time.time()
                    print(f"\nEjecutando comando {i+1}/{len(commands)}:\n{command[:200]}...")
                    try:
                        cursor.execute(command)
                        rows_affected = cursor.rowcount if cursor.rowcount is not None else 0
                        total_rows_affected += rows_affected
                        command_time = time.time() - command_start_time
                        print(f"Comando {i+1} completado en {command_time:.2f} segundos. Filas afectadas: {rows_affected}")
                    except Exception as exec_error:
                        conn.rollback() # Revertir en caso de error en cualquier comando
                        print(f"\nError al ejecutar comando {i+1}: {exec_error}")
                        print(f"Comando: {command[:200]}...")
                        return False # Detener la ejecución si un comando falla

                conn.commit() # Confirmar transacción si todos los comandos fueron exitosos
                print(f"\nTodos los comandos ejecutados y cambios confirmados.")
                success = True

        if success:
            print(f"Corrección completada. Total filas afectadas: {total_rows_affected}.")
        
        return success

    except Exception as e:
        print(f"\nError inesperado en el Paso 4: {e}")
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
        print(f"--- Paso 4 finalizado en {end_time - start_time:.2f} segundos ---")

if __name__ == "__main__":
    success = fix_semantic_identifiers()
    sys.exit(0 if success else 1)
