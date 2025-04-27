#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import time
import sys
import os
# Importar directamente desde el subdirectorio utils
from utils.db_utils import get_connection

def execute_sql_script(sql_filename="step1_create_tables.sql"):
    """
    Ejecuta un script SQL ubicado en el directorio 'sql' relativo
    al directorio padre 'orgunit'.
    """
    # Construir la ruta completa al archivo SQL relativo al directorio padre (orgunit/sql/)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    sql_dir = os.path.abspath(os.path.join(script_dir, '..', 'sql'))
    sql_filepath = os.path.join(sql_dir, sql_filename)

    print(f"Iniciando ejecución del script SQL: {sql_filepath}")
    print("=" * 80)

    conn = None
    start_time = time.time()

    try:
        # Leer el contenido del archivo SQL
        print(f"Leyendo archivo SQL: {sql_filename}...")
        with open(sql_filepath, 'r', encoding='utf-8') as f:
            sql_content = f.read()
        print("Archivo SQL leído correctamente.")

        if not sql_content.strip():
            print("El archivo SQL está vacío. No hay nada que ejecutar.")
            return True

        # Conectar a la base de datos
        print("Conectando a la base de datos...")
        conn = get_connection()
        if not conn:
            print("Error: No se pudo establecer conexión a la base de datos.")
            return False

        cursor = conn.cursor()

        # Ejecutar el script SQL
        print("Ejecutando script SQL...")
        cursor.execute(sql_content)
        conn.commit()
        print("Script SQL ejecutado y cambios confirmados.")

        total_time = time.time() - start_time
        print(f"\nEjecución completada con éxito.")
        print(f"Tiempo total: {total_time:.2f} segundos")
        return True

    except FileNotFoundError:
        print(f"\nError: El archivo SQL '{sql_filepath}' no fue encontrado.")
        return False
    except Exception as e:
        print(f"\nError inesperado durante la ejecución del SQL: {e}")
        if conn:
            conn.rollback() # Revertir en caso de error
            print("Se ha realizado rollback de la transacción.")
        return False
    finally:
        if conn:
            conn.close()
            print("Conexión a la base de datos cerrada.")

if __name__ == "__main__":
    # El nombre del archivo SQL se busca en orgunit/sql/
    sql_file = "step1_create_tables.sql"
    success = execute_sql_script(sql_file)
    sys.exit(0 if success else 1)
