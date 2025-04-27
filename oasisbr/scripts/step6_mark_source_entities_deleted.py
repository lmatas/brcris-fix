#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import time
from utils.db_utils import get_connection

def mark_source_entities_deleted(sql_filename="step6_mark_source_entities_deleted.sql"):
    """Ejecuta el script SQL para marcar entidades fuente como eliminadas y crear tabla de recarga."""
    conn = None
    cursor = None
    start_time = time.time()
    print(f"--- Iniciando Paso 6: Marcado de Source Entities como Deleted ({sql_filename}) ---")
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
        cleaned_sql = "\n".join(cleaned_lines).strip()

        if not cleaned_sql:
            print("El archivo SQL está vacío o solo contiene comentarios. No hay nada que ejecutar.")
            success = True
        else:
            # 2. Dividir el SQL limpio por punto y coma; filtrar cadenas vacías
            commands = [cmd.strip() for cmd in cleaned_sql.split(';') if cmd.strip()]

            if not commands and cleaned_sql:
                commands = [cleaned_sql]

            if not commands:
                 print("No se encontraron comandos SQL ejecutables después de limpiar comentarios y líneas vacías.")
                 success = True
            else:
                print(f"Se encontraron {len(commands)} comandos SQL para ejecutar.")
                cursor = conn.cursor()
                
                for i, command in enumerate(commands):
                    command_start_time = time.time()
                    print(f"\nEjecutando comando {i+1}/{len(commands)}:\n{command[:200]}...")
                    try:
                        cursor.execute(command)
                        # CREATE TABLE no devuelve filas afectadas de forma estándar, UPDATE sí.
                        rows_affected = cursor.rowcount if cursor.rowcount is not None and cursor.rowcount >= 0 else 0
                        total_rows_affected += rows_affected
                        command_time = time.time() - command_start_time
                        print(f"Comando {i+1} completado en {command_time:.2f} segundos. Filas afectadas: {rows_affected if cursor.rowcount is not None and cursor.rowcount >= 0 else 'N/A (DDL)'}")
                    except Exception as exec_error:
                        conn.rollback()
                        print(f"\nError al ejecutar comando {i+1}: {exec_error}")
                        print(f"Comando: {command[:200]}...")
                        return False

                conn.commit()
                print(f"\nTodos los comandos ejecutados y cambios confirmados.")
                success = True

        if success:
            print(f"Marcado completado. Total filas afectadas (en UPDATEs): {total_rows_affected}.")
        
        return success

    except Exception as e:
        print(f"\nError inesperado en el Paso 6: {e}")
        if conn:
            conn.rollback()
        return False
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
            print("Conexión a la base de datos cerrada.")
        end_time = time.time()
        print(f"--- Paso 6 finalizado en {end_time - start_time:.2f} segundos ---")

if __name__ == "__main__":
    success = mark_source_entities_deleted()
    sys.exit(0 if success else 1)
