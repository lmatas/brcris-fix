#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import time
from utils.db_utils import get_connection, execute_sql_file

def create_aux_tables(sql_filename="step2_create_aux_tables.sql"):
    """Ejecuta el script SQL para crear tablas auxiliares."""
    conn = None
    start_time = time.time()
    print(f"--- Iniciando Paso 2: Creación de Tablas Auxiliares ({sql_filename}) ---")

    try:
        script_dir = os.path.dirname(__file__)
        sql_file_path = os.path.join(script_dir, '..', 'sql', sql_filename)

        conn = get_connection()
        if not conn:
            print("Error: No se pudo establecer conexión a la base de datos.")
            return False

        success, _ = execute_sql_file(conn, sql_file_path)
        return success

    except Exception as e:
        print(f"\nError inesperado en el Paso 2: {e}")
        return False
    finally:
        if conn:
            conn.close()
            print("Conexión a la base de datos cerrada.")
        end_time = time.time()
        print(f"--- Paso 2 finalizado en {end_time - start_time:.2f} segundos ---")

if __name__ == "__main__":
    success = create_aux_tables()
    sys.exit(0 if success else 1)
