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
        
        # Leer el contenido del archivo SQL
        with open(sql_file_path, 'r') as sql_file:
            sql_content = sql_file.read()
        
        # Dividir el SQL por las sentencias (asumiendo que están separadas por punto y coma)
        sql_statements = [stmt.strip() for stmt in sql_content.split(';') if stmt.strip()]
        
        # Ejecutar cada sentencia SQL
        cursor = conn.cursor()
        affected_rows = 0
        
        for i, stmt in enumerate(sql_statements):
            # Obtener la primera línea (comentario) de la consulta
            first_line = stmt.split('\n')[0].strip()
            print(f"\nEjecutando sentencia SQL {i+1}/{len(sql_statements)}:")
            print(f"Operación: {first_line}")
            
            # Ignorar comentarios en el SQL
            if stmt.strip():
                cursor.execute(stmt)
                affected_rows += cursor.rowcount
                print(f"Filas afectadas: {cursor.rowcount}")
        
        # Confirmar cambios
        conn.commit()
            
        # Mostrar resumen
        total_time = time.time() - start_time
        print(f"\n\nPaso 3 completado con éxito.")
        print(f"Tiempo total: {total_time/60:.2f} minutos ({total_time:.2f} segundos)")
        print(f"Nuevos identificadores insertados: {affected_rows}")
        return True
            
    except Exception as e:
        print(f"\nError: {e}")
        if conn:
            conn.rollback()
        return False
    finally:
        if conn:
            conn.close()
            print("Conexión cerrada.")