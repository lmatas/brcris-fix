#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import time
import sys
from utils.db_utils import get_connection, print_progress, execute_sql_file

def create_and_fill_tables():
    """
    Paso 1: Crea la tabla wrong_orcid_semantic_identifier y la llena con los identificadores ORCID incorrectos
    """
    print("Paso 1: Creación y llenado de la tabla de identificadores ORCID incorrectos")
    print("=" * 80)
    
    start_time = time.time()
    conn = None
    
    try:
        # Conectar a la base de datos
        print("Conectando a la base de datos...")
        conn = get_connection()
        if not conn:
            print("Error: No se pudo establecer conexión a la base de datos.")
            return False
            
        cursor = conn.cursor()
        
        # Ruta al archivo SQL
        sql_file_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'sql', 'step1_orcid.sql')
        
        if not os.path.exists(sql_file_path):
            print(f"Error: No se encontró el archivo SQL en {sql_file_path}")
            return False
            
        print(f"Ejecutando script SQL desde: {sql_file_path}")
        
        # Ejecutar el archivo SQL
        with open(sql_file_path, 'r') as sql_file:
            sql_commands = sql_file.read().split(';')
            total_commands = len([cmd for cmd in sql_commands if cmd.strip()])
            
            print(f"Ejecutando {total_commands} comandos SQL...")
            
            processed = 0
            for command in sql_commands:
                command = command.strip()
                if command:
                    try:
                        # Obtener la primera línea (comentario) de la consulta
                        first_line = command.split('\n')[0].strip()
                        print(f"\nEjecutando comando SQL {processed+1}/{total_commands}:")
                        print(f"Operación: {first_line}")
                        
                        cursor.execute(command)
                        processed += 1
                        print_progress(processed, total_commands, start_time)
                    except Exception as e:
                        print(f"\nError al ejecutar comando SQL: {e}")
                        print(f"Comando: {command[:100]}...")
                        conn.rollback()
                        return False
            
            # Confirmar todos los cambios
            conn.commit()
        
        # Verificar conteo final de registros
        try:
            cursor.execute("SELECT COUNT(*) FROM wrong_orcid_semantic_identifier")
            count = cursor.fetchone()[0]
            
            # Mostrar resumen
            total_time = time.time() - start_time
            print(f"\n\nPaso 1 completado con éxito.")
            print(f"Tiempo total: {total_time/60:.2f} minutos ({total_time:.2f} segundos)")
            print(f"Registros en wrong_orcid_semantic_identifier: {count}")
            print(f"Comandos SQL ejecutados: {processed}")
            
            return True
        except Exception as e:
            print(f"\nError al verificar resultados: {e}")
            return False
            
    except Exception as e:
        print(f"\nError general: {e}")
        if conn:
            conn.rollback()
        return False
    finally:
        if conn:
            conn.close()
            print("Conexión a la base de datos cerrada")

if __name__ == "__main__":
    success = create_and_fill_tables()
    sys.exit(0 if success else 1)
