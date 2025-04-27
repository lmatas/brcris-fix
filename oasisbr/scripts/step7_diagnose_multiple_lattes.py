#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import time
from utils.db_utils import get_connection

def diagnose_multiple_lattes(sql_filename="step7_diagnose_multiple_lattes.sql"):
    """Ejecuta el script SQL para crear tabla de diagnóstico de múltiples Lattes."""
    conn = None
    cursor = None
    start_time = time.time()
    print(f"--- Iniciando Paso 7: Diagnóstico de Múltiples Lattes ({sql_filename}) ---")
    total_rows_affected = 0 # CREATE TABLE AS no suele devolver filas afectadas
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
            # Asumiendo que el SQL de diagnóstico es una sola sentencia CREATE TABLE AS
            commands = [cmd.strip() for cmd in cleaned_sql.split(';') if cmd.strip()]

            if not commands and cleaned_sql:
                commands = [cleaned_sql]

            if not commands:
                 print("No se encontraron comandos SQL ejecutables después de limpiar comentarios y líneas vacías.")
                 success = True
            else:
                print(f"Se encontraron {len(commands)} comandos SQL para ejecutar.")
                cursor = conn.cursor()
                
                # Asumiendo una sola sentencia CREATE TABLE AS
                command = commands[0]
                command_start_time = time.time()
                print(f"\nEjecutando comando 1/{len(commands)}:\n{command[:200]}...")
                try:
                    cursor.execute(command)
                    # CREATE TABLE AS no devuelve filas afectadas de forma estándar
                    rows_affected = cursor.rowcount if cursor.rowcount is not None and cursor.rowcount >= 0 else 0
                    total_rows_affected += rows_affected # Probablemente será 0
                    command_time = time.time() - command_start_time
                    print(f"Comando 1 completado en {command_time:.2f} segundos. Filas afectadas: {rows_affected if cursor.rowcount is not None and cursor.rowcount >= 0 else 'N/A (DDL)'}")
                except Exception as exec_error:
                    conn.rollback()
                    print(f"\nError al ejecutar comando 1: {exec_error}")
                    print(f"Comando: {command[:200]}...")
                    return False

                conn.commit()
                print(f"\nTodos los comandos ejecutados y cambios confirmados.")
                success = True

        if success:
            # Informar sobre la creación de la tabla
            print(f"Diagnóstico completado. Tabla 'aux_diagnose_multiple_lattes_entities' creada/actualizada.")
        
        return success

    except Exception as e:
        print(f"\nError inesperado en el Paso 7: {e}")
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
        print(f"--- Paso 7 finalizado en {end_time - start_time:.2f} segundos ---")

if __name__ == "__main__":
    success = diagnose_multiple_lattes()
    sys.exit(0 if success else 1)
