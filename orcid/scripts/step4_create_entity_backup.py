# filepath: /brcris_fix/brcris_fix/scripts/step4_create_entity_backup.py

import time
import sys
from utils.db_utils import get_connection, execute_sql_file

def create_entity_backup():
    """Crea una tabla de respaldo de entidades incorrectas en la base de datos."""
    conn = None
    try:
        # Conectar a la base de datos
        print("Conectando a la base de datos...")
        conn = get_connection()
        if not conn:
            print("Error: No se pudo establecer conexión a la base de datos.")
            return False
            
        # Ejecutar el archivo SQL para crear la tabla de respaldo
        sql_file_path = 'sql/step4_entity_backup.sql'
        print(f"Ejecutando script SQL: {sql_file_path}")
        start_time = time.time()
        
        if execute_sql_file(conn, sql_file_path):
            total_time = time.time() - start_time
            print(f"\n\nTabla de respaldo creada con éxito.")
            print(f"Tiempo total: {total_time:.2f} segundos")
        else:
            print("Error al crear la tabla de respaldo.")
        
    except Exception as e:
        print(f"\nError: {e}")
        if conn:
            conn.rollback()
    finally:
        if conn:
            conn.close()
            print("Conexión a la base de datos cerrada")

if __name__ == "__main__":
    create_entity_backup()