#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import time
import sys
import os
# Ajusta la ruta para importar desde el directorio utils hermano de scripts
try:
    script_dir = os.path.dirname(os.path.abspath(__file__))
    # Ir un nivel arriba para llegar al directorio 'orgunit'
    parent_dir = os.path.abspath(os.path.join(script_dir, '..'))
    # Añadir el directorio 'orgunit' a sys.path para poder importar 'utils'
    if parent_dir not in sys.path:
        sys.path.insert(0, parent_dir)
    # Importar funciones necesarias desde utils.db_utils
    from utils.db_utils import get_connection
except ImportError:
    print("Error: No se pudo encontrar el módulo 'db_utils' en la carpeta 'utils' dentro del directorio padre.")
    print("Asegúrate de que la estructura sea 'orgunit/utils/db_utils.py'.")
    sys.exit(1)

def execute_sql_script(sql_filename="step4_prepare_aux_tables.sql"):
    """
    Ejecuta un script SQL para poblar las tablas auxiliares, ubicado en el
    directorio 'sql' relativo al directorio padre 'orgunit'.
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

        # Ejecutar los comandos SQL del archivo
        sql_commands = [cmd.strip() for cmd in sql_content.split(';') if cmd.strip()]
        print(f"Ejecutando {len(sql_commands)} comandos SQL...")

        total_rows_affected = 0

        for i, command in enumerate(sql_commands):
            try:
                # Extraer comentario inicial si existe para descripción
                comment = command.splitlines()[0] if command.startswith('--') else f"Comando {i+1}"
                print(f"\nEjecutando: {comment}...")
                command_start_time = time.time()

                cursor.execute(command)
                rows_affected = cursor.rowcount
                # Acumular filas afectadas solo si rowcount es válido (>= 0)
                total_rows_affected += rows_affected if rows_affected > 0 else 0
                command_time = time.time() - command_start_time
                print(f"Comando completado en {command_time:.2f} segundos. Filas afectadas: {rows_affected if rows_affected >= 0 else 'N/A'}")

            except Exception as exec_error:
                conn.rollback() # Revertir en caso de error en cualquier comando
                print(f"\nError al ejecutar comando: {exec_error}")
                print(f"Comando: {command[:200]}...")
                return False

        # Confirmar todos los cambios si todos los comandos fueron exitosos
        conn.commit()
        print(f"\nTodos los comandos ejecutados y cambios confirmados.")

        total_time = time.time() - start_time
        print(f"\nEjecución completada con éxito.")
        print(f"Tiempo total: {total_time:.2f} segundos")
        print(f"Total filas afectadas (aproximado): {total_rows_affected}") # Muestra suma de filas afectadas
        return True

    except FileNotFoundError:
        print(f"\nError: El archivo SQL '{sql_filepath}' no fue encontrado.")
        return False
    except Exception as e:
        print(f"\nError inesperado durante la ejecución del SQL: {e}")
        if conn:
            conn.rollback() # Asegurar rollback en caso de error general
            print("Se ha realizado rollback de la transacción.")
        return False
    finally:
        if conn:
            conn.close()
            print("Conexión a la base de datos cerrada.")

if __name__ == "__main__":
    # El nombre del archivo SQL se busca en orgunit/sql/
    sql_file = "step4_prepare_aux_tables.sql"
    success = execute_sql_script(sql_file)
    sys.exit(0 if success else 1)

