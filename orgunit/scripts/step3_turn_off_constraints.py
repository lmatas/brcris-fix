#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import time
import sys
import os
# Eliminar el ajuste de ruta para importar desde el directorio utils hermano de scripts
# try:
#     script_dir = os.path.dirname(os.path.abspath(__file__))
#     # Ir un nivel arriba para llegar al directorio 'orgunit'
#     parent_dir = os.path.abspath(os.path.join(script_dir, '..'))
#     # Añadir el directorio 'orgunit' a sys.path para poder importar 'utils'
#     if parent_dir not in sys.path:
#         sys.path.insert(0, parent_dir)
#     # Importar funciones necesarias desde utils.db_utils
#     from utils.db_utils import get_connection
# except ImportError:
#     print("Error: No se pudo encontrar el módulo 'db_utils' en la carpeta 'utils' dentro del directorio padre.")
#     print("Asegúrate de que la estructura sea 'orgunit/utils/db_utils.py'.")
#     sys.exit(1)
# Importar directamente desde el subdirectorio utils
from utils.db_utils import get_connection

def execute_sql_script(sql_filename="step3_turn_off_contraints.sql"):
    """
    Ejecuta un script SQL para desactivar restricciones, ubicado en el directorio 'sql'
    relativo al directorio padre 'orgunit'.
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
        # Dividir por ';' para ejecutar comandos individualmente, manejando errores
        sql_commands = [cmd.strip() for cmd in sql_content.split(';') if cmd.strip()]
        print(f"Ejecutando {len(sql_commands)} comandos SQL...")

        executed_count = 0
        for command in sql_commands:
            try:
                print(f"Ejecutando: {command.splitlines()[0]}...") # Mostrar primera línea del comando
                cursor.execute(command)
                executed_count += 1
            except Exception as exec_error:
                # Advertir sobre el error pero continuar si es posible (ej. constraint no existe)
                print(f"Advertencia al ejecutar comando: {exec_error}")
                print(f"Comando: {command}")
                conn.rollback() # Revertir el comando fallido
                # Podrías decidir detenerte aquí si el error es crítico
                # return False
                # Continuamos con el siguiente comando
                conn = get_connection() # Reabrir cursor si es necesario tras rollback
                cursor = conn.cursor()


        conn.commit()
        print(f"\n{executed_count}/{len(sql_commands)} comandos SQL ejecutados.")

        total_time = time.time() - start_time
        print(f"\nEjecución completada.")
        print(f"Tiempo total: {total_time:.2f} segundos")
        return True

    except FileNotFoundError:
        print(f"\nError: El archivo SQL '{sql_filepath}' no fue encontrado.")
        return False
    except Exception as e:
        print(f"\nError inesperado durante la ejecución del SQL: {e}")
        if conn:
            conn.rollback() # Revertir en caso de error general
            print("Se ha realizado rollback de la transacción.")
        return False
    finally:
        if conn:
            conn.close()
            print("Conexión a la base de datos cerrada.")

if __name__ == "__main__":
    # El nombre del archivo SQL se busca en orgunit/sql/
    sql_file = "step3_turn_off_contraints.sql"
    success = execute_sql_script(sql_file)
    sys.exit(0 if success else 1)
