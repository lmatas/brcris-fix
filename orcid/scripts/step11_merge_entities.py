#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import time
import sys
import os
from utils.db_utils import get_connection
import psycopg2
import psycopg2.extensions

def merge_dirty_entities():
    """
    Paso 11: Merge de entidades marcadas como dirty usando SQL directo
    """
    print("Paso 11: Merge de entidades afectadas")
    print("=" * 80)
    
    conn = None
    try:
        # Conectar a la base de datos
        print("Conectando a la base de datos...")
        conn = get_connection()
        if not conn:
            print("Error: No se pudo establecer conexión a la base de datos.")
            return False
        
        # Añadir después de establecer la conexión pero antes de ejecutar cualquier consulta

        def notice_processor(diag):
            print(f"NOTICE: {diag.message_primary}")

        # Configurar la conexión para mostrar los NOTICE en pantalla
        conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)
        # Agregar el manejador de notificaciones (usar set_notice_receiver en lugar de set_notice_handler)
        psycopg2.extensions.set_notice_receiver(conn, notice_processor)
    
        # Ruta al archivo SQL
        sql_file_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 
                                    'sql', 'step11_merge_entities.sql')
        
        print(f"Leyendo archivo SQL desde: {sql_file_path}")
        
        # Leer todo el contenido del archivo SQL
        with open(sql_file_path, 'r') as sql_file:
            sql_content = sql_file.read()
        
        # Cargar todo el contenido SQL para crear los procedimientos
        cursor = conn.cursor()
        print("Cargando y creando procedimientos SQL...")
        start_time = time.time()
        cursor.execute(sql_content)
        load_time = time.time() - start_time
        print(f"Procedimientos cargados en {load_time:.2f} segundos")
        
        # Ahora ejecutar el procedimiento principal
        print("\n" + "=" * 80)
        print("Ejecutando el procedimiento principal execute_complete_merge_process()...")
        print("=" * 80)
        
        proc_start_time = time.time()
        cursor.execute("SELECT execute_complete_merge_process();")
        proc_end_time = time.time() - proc_start_time
        
        # Mostrar resumen final
        print("\n" + "=" * 80)
        print(f"Paso 11 completado con éxito.")
        print(f"Tiempo de ejecución del procedimiento: {proc_end_time/60:.2f} minutos ({proc_end_time:.2f} segundos)")
        print(f"Tiempo total: {(time.time() - start_time)/60:.2f} minutos ({(time.time() - start_time):.2f} segundos)")
        
        return True
            
    except Exception as e:
        print(f"\nError: {e}")
        # No hacer rollback porque estamos en modo autocommit
        return False
    finally:
        if conn:
            conn.close()
            print("Conexión cerrada.")

if __name__ == "__main__":
    success = merge_dirty_entities()
    sys.exit(0 if success else 1)
