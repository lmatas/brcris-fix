#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import time
import sys
from utils.db_utils import get_connection, execute_sql_file, print_progress

def insert_new_identifiers():
    """
    Paso 3: Inserta los nuevos identificadores ORCID normalizados en la tabla semantic_identifier.
    
    Este paso:
    - Inserta los nuevos identificadores en la tabla semantic_identifier
    """
    print("Paso 3: Inserción de nuevos identificadores semánticos ORCID")
    print("=" * 80)
    
    conn = None
    try:
        # Conectar a la base de datos
        print("Conectando a la base de datos...")
        conn = get_connection()
        if not conn:
            print("Error: No se pudo establecer conexión a la base de datos.")
            return False
            
        # Ruta al archivo SQL
        sql_file_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 
                                   'sql', 'step3_insert_identifiers.sql')
        
        if not os.path.exists(sql_file_path):
            print(f"Error: No se encontró el archivo SQL en {sql_file_path}")
            return False
            
        print(f"Ejecutando script SQL: {sql_file_path}")
        start_time = time.time()
        
        # Ejecutar el archivo SQL y obtener el número de filas afectadas directamente
        success, affected_rows = execute_sql_file(conn, sql_file_path, return_affected_rows=True)
        
        if success:
            # Mostrar resumen
            total_time = time.time() - start_time
            print(f"\n\nPaso 3 completado con éxito.")
            print(f"Tiempo total: {total_time/60:.2f} minutos ({total_time:.2f} segundos)")
            print(f"Nuevos identificadores insertados: {affected_rows}")
            return True
        else:
            print("Error al ejecutar el script SQL.")
            return False
            
    except Exception as e:
        print(f"\nError: {e}")
        if conn:
            conn.rollback()
        return False
    finally:
        if conn:
            conn.close()
            print("Conexión cerrada.")