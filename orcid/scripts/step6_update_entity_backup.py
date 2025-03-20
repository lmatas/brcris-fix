# filepath: /Users/lmatas/source/brcris_fix/scripts/step6_update_entity_backup.py
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import time
import sys
from utils.db_utils import get_connection, print_progress

def update_entity_backup():
    """Actualiza la tabla de respaldo de entidades con los nuevos identificadores semánticos"""
    conn = None
    try:
        # Conectar a la base de datos
        print("Conectando a la base de datos...")
        conn = get_connection()
        if not conn:
            print("Error: No se pudo establecer conexión a la base de datos.")
            return False
            
        cursor = conn.cursor()
        
        # Obtener los nuevos identificadores semánticos que necesitan ser actualizados
        cursor.execute("""
            SELECT DISTINCT w.source_entity_id, w.new_semantic_id
            FROM wrong_orcid_entity_backup w
            WHERE w.new_final_entity_id IS NOT NULL
        """)
        
        new_identifiers = cursor.fetchall()
        total_records = len(new_identifiers)
        print(f"Se encontraron {total_records} nuevos identificadores para actualizar en la tabla de respaldo...")
        
        # Variables para el seguimiento del progreso
        start_time = time.time()
        processed = 0
        commit_batch_size = 1000
        
        # Actualizar cada nuevo identificador
        for source_entity_id, new_semantic_id in new_identifiers:
            # Actualizar el registro en la tabla de respaldo
            cursor.execute(
                "UPDATE wrong_orcid_entity_backup SET new_semantic_id = %s WHERE source_entity_id = %s",
                (new_semantic_id, source_entity_id)
            )
            
            # Actualizar el progreso
            processed += 1
            
            # Hacer commit cada X registros y mostrar progreso
            if processed % commit_batch_size == 0:
                conn.commit()
                print_progress(processed, total_records, start_time)
        
        # Confirmar cambios finales
        conn.commit()
        
        # Mostrar resumen final
        total_time = time.time() - start_time
        print(f"\n\nActualización de la tabla de respaldo completada con éxito.")
        print(f"Tiempo total: {total_time/60:.2f} minutos ({total_time:.2f} segundos)")
        print(f"Registros procesados: {processed}")
        print(f"Velocidad media: {processed/total_time:.2f} registros por segundo")
        return True
        
    except Exception as e:
        print(f"\nError: {e}")
        if conn:
            conn.rollback()
        return False
    finally:
        if conn:
            conn.close()
            print("Conexión a la base de datos cerrada")

if __name__ == "__main__":
    update_entity_backup()