#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import time
import sys
from utils.db_utils import get_connection, print_progress

def execute_sql_file(file_path):
    """Ejecuta el contenido de un archivo SQL"""
    conn = None
    try:
        # Conectar a la base de datos
        print("Conectando a la base de datos...")
        conn = get_connection()
        if not conn:
            print("Error: No se pudo establecer la conexión a la base de datos.")
            return False
            
        db_info = conn.info
        print(f"Conexión establecida: {db_info.host}:{db_info.port}/{db_info.dbname} (usuario: {db_info.user})")
        
        cursor = conn.cursor()
        
        # Leer el contenido del archivo SQL
        print(f"Leyendo archivo SQL: {file_path}")
        with open(file_path, 'r') as sql_file:
            sql_content = sql_file.read()
        
        # Dividir el contenido en instrucciones SQL individuales
        # Asumimos que cada instrucción termina con un punto y coma
        sql_commands = sql_content.split(';')
        
        print(f"Ejecutando {len(sql_commands)} comandos SQL...")
        start_time = time.time()
        command_count = 0
        
        # Ejecutar cada comando SQL individualmente
        for command in sql_commands:
            # Ignorar líneas en blanco y comentarios SQL
            command = command.strip()
            if command and not command.startswith('--'):
                try:
                    cursor.execute(command)
                    command_count += 1
                    # Mostrar progreso
                    print_progress(command_count, len(sql_commands), start_time)
                except Exception as e:
                    print(f"\nError al ejecutar comando: {e}")
                    print(f"Comando problemático: {command[:100]}...")
        
        # Confirmar cambios
        conn.commit()
        
        # Tiempo transcurrido
        elapsed_time = time.time() - start_time
        print(f"\n\nScript SQL ejecutado con éxito.")
        print(f"Tiempo total: {elapsed_time:.2f} segundos")
        print(f"Comandos ejecutados: {command_count}")
        
        # Contar registros insertados
        try:
            cursor.execute("SELECT COUNT(*) FROM wrong_orcid_semantic_identifier")
            count = cursor.fetchone()[0]
            print(f"Registros en wrong_orcid_semantic_identifier: {count}")
            return True
        except Exception as e:
            print(f"Error al contar registros: {e}")
            return False
        
    except Exception as e:
        print(f"Error general: {e}")
        if conn:
            conn.rollback()
        return False
    finally:
        if conn:
            conn.close()
            print("Conexión a la base de datos cerrada")

if __name__ == "__main__":
    sql_file_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'step1_orcid.sql')
    execute_sql_file(sql_file_path)
