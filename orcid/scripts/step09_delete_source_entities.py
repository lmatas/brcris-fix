#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import time
import sys
import os
from utils.db_utils import get_connection

def delete_source_entities():
    """
    Paso 9: Borrar source_entities marcadas como borradas (deleted=true) 
    configurando los cascade deletes necesarios
    """
    print("Paso 9: Borrado de source_entities marcadas como deleted=true")
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
                                    'sql', 'step09_delete_source_entities.sql')
        
        print(f"Leyendo SQL desde: {sql_file_path}")
        
        # Leer el contenido del archivo SQL
        with open(sql_file_path, 'r') as sql_file:
            sql_content = sql_file.read()
        
        # Dividir el SQL por las sentencias (asumiendo que están separadas por punto y coma)
        sql_statements = [stmt.strip() for stmt in sql_content.split(';') if stmt.strip()]
        
        # Variables para el seguimiento del progreso
        start_time = time.time()
        
        # Ejecutar cada sentencia SQL
        for i, stmt in enumerate(sql_statements):
            # Obtener la primera línea (comentario) de la consulta
            first_line = stmt.split('\n')[0].strip()
            print(f"\nEjecutando sentencia SQL {i+1}/{len(sql_statements)}:")
            print(f"Operación: {first_line}")
            
            # Ignorar comentarios en el SQL
            if stmt.strip():
                cursor = conn.cursor()
                cursor.execute(stmt)
                
                # Obtener número de filas afectadas
                rows_affected = cursor.rowcount
                print(f"Filas afectadas: {rows_affected}")
        
        # Confirmar cambios
        conn.commit()
        
        # Mostrar resumen final
        total_time = time.time() - start_time
        print(f"\n\nPaso 9 completado con éxito.")
        print(f"Tiempo total: {total_time/60:.2f} minutos ({total_time:.2f} segundos)")
        
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

if __name__ == "__main__":
    success = delete_source_entities()
    sys.exit(0 if success else 1)