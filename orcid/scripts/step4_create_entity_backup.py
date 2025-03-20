# filepath: /brcris_fix/brcris_fix/scripts/step4_create_entity_backup.py

import time
import sys
import os
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
            
        # Ruta al archivo SQL
        sql_file_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 
                                    'sql', 'step4_entity_backup.sql')
        
        print(f"Leyendo SQL desde: {sql_file_path}")
        
        # Leer el contenido del archivo SQL
        with open(sql_file_path, 'r') as sql_file:
            sql_content = sql_file.read()
        
        # Dividir el SQL por las sentencias (asumiendo que están separadas por punto y coma)
        sql_statements = [stmt.strip() for stmt in sql_content.split(';') if stmt.strip()]
        
        # Variables para el seguimiento del progreso
        start_time = time.time()
        
        # Ejecutar cada sentencia SQL
        cursor = conn.cursor()
        for i, stmt in enumerate(sql_statements):
            # Obtener la primera línea (comentario) de la consulta
            first_line = stmt.split('\n')[0].strip()
            print(f"\nEjecutando sentencia SQL {i+1}/{len(sql_statements)}:")
            print(f"Operación: {first_line}")
            
            # Ignorar comentarios en el SQL
            if stmt.strip():
                cursor.execute(stmt)
                
                # Obtener número de filas afectadas
                rows_affected = cursor.rowcount
                print(f"Filas afectadas: {rows_affected}")
        
        # Confirmar cambios
        conn.commit()
        
        # Mostrar resumen final
        total_time = time.time() - start_time
        print(f"\n\nTabla de respaldo creada con éxito.")
        print(f"Tiempo total: {total_time/60:.2f} minutos ({total_time:.2f} segundos)")
        
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