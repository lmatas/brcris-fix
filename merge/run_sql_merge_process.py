#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import time
import sys
import os
# Asumiendo que 'utils' es accesible vía PYTHONPATH o que el script se ejecuta 
# desde un directorio que permite esta importación (ej. orcid/).
from utils.db_utils import get_connection 
import psycopg2
import psycopg2.extensions

def execute_sql_merge_from_file():
    """
    Ejecuta el proceso de merge de entidades cargando y corriendo un archivo SQL.
    """
    overall_start_time = time.time()
    print("Inicio del proceso de merge de entidades (script independiente desde archivo SQL)")
    print("=" * 80)
    
    conn = None
    try:
        # Conectar a la base de datos
        print("Conectando a la base de datos...")
        conn = get_connection()
        if not conn:
            print("Error: No se pudo establecer conexión a la base de datos.")
            return False
            
        # Ruta al archivo SQL. 
        # Asumiendo que este script está en PROJECT_ROOT/merge/
        # y el archivo SQL está en PROJECT_ROOT/sql/
        current_script_dir = os.path.dirname(os.path.abspath(__file__))
        # Se corrige la ruta para subir un solo nivel ('..') para llegar a la raíz del proyecto
        # y luego acceder al directorio 'sql'.
        sql_file_path = os.path.join(current_script_dir, 'merge_entities.sql')
        
        if not os.path.exists(sql_file_path):
            print(f"Error: No se encontró el archivo SQL en la ruta: {sql_file_path}")
            return False
            
        print(f"Leyendo archivo SQL desde: {sql_file_path}")
        
        # Leer todo el contenido del archivo SQL
        with open(sql_file_path, 'r') as sql_file:
            sql_content = sql_file.read()
        
        cursor = conn.cursor()
        
        # Cargar todo el contenido SQL para crear los procedimientos
        print("Cargando y creando procedimientos SQL desde el archivo...")
        load_sql_start_time = time.time()
        cursor.execute(sql_content)
        conn.commit() # Asegurar que la creación de funciones/procedimientos se persista
        load_sql_time = time.time() - load_sql_start_time
        print(f"Procedimientos SQL cargados y creados en {load_sql_time:.2f} segundos")
        
        # Ahora ejecutar el procedimiento principal definido en el archivo SQL
        print("\n" + "=" * 80)
        print("Ejecutando el procedimiento principal de merge... (esto puede tardar un tiempo)")
        print("=" * 80)
        
        proc_start_time = time.time()
        # Asumiendo que el archivo SQL define una función llamada 'execute_complete_merge_process'
        # y que esta función es la que se debe llamar para iniciar el proceso.
        cursor.execute("SELECT process_dirty_entities()")
        conn.commit() # Commit después de la ejecución del procedimiento principal
        proc_run_time = time.time() - proc_start_time
        
        # Mostrar resumen final
        print("\n" + "=" * 80)
        print(f"Proceso de merge SQL completado con éxito.")
        print(f"Tiempo de ejecución del procedimiento SQL: {proc_run_time/60:.2f} minutos ({proc_run_time:.2f} segundos)")
        total_script_duration = time.time() - overall_start_time
        print(f"Tiempo total de ejecución del script: {total_script_duration/60:.2f} minutos ({total_script_duration:.2f} segundos)")
        
        return True
            
    except psycopg2.Error as db_err:
        print(f"\nError de base de datos: {db_err}")
        if conn:
            conn.rollback() # Rollback en caso de error de base de datos
        return False
    except Exception as e:
        print(f"\nError inesperado durante el proceso de merge: {e}")
        if conn: # Podría no haber conexión si falla antes
            conn.rollback()
        return False
    finally:
        if conn:
            conn.close()
            print("Conexión cerrada.")

if __name__ == "__main__":
    print(f"Ejecutando script: {os.path.abspath(__file__)}")
    # Para que 'from utils.db_utils import get_connection' funcione,
    # el directorio que contiene 'utils' (probablemente 'orcid/') debe estar en PYTHONPATH,
    # o el script debe ejecutarse desde un directorio que haga 'utils' directamente accesible.
    
    # Ejemplo de cómo añadir el directorio padre de 'scripts' (es decir, 'orcid') a sys.path
    # si 'utils' está en 'orcid/utils/':
    # script_parent_dir = os.path.dirname(os.path.dirname(current_script_dir)) # Esto sería 'orcid/'
    # sys.path.insert(0, script_parent_dir)
    # from utils.db_utils import get_connection
    # Esta lógica de modificación de sys.path es opcional y depende de tu estructura y PYTHONPATH.

    success = execute_sql_merge_from_file()
    sys.exit(0 if success else 1)
