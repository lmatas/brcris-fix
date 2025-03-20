# filepath: /brcris_fix/brcris_fix/scripts/step8_mark_entities_dirty.py
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import time
import sys
from utils.db_utils import get_connection, print_progress

def mark_entities_dirty():
    """Marca las entidades afectadas como 'sucias' para reprocesarlas"""
    conn = None
    try:
        # Conectar a la base de datos
        print("Conectando a la base de datos...")
        conn = get_connection()
        if not conn:
            print("Error: No se pudo establecer conexión a la base de datos.")
            return False
            
        cursor = conn.cursor()
        
        # Obtener las entidades que necesitan ser marcadas como 'sucias'
        cursor.execute("""
            SELECT DISTINCT e.uuid
            FROM public.entity e
            JOIN public.wrong_orcid_entity_backup web ON e.uuid = web.new_final_entity_id
            WHERE web.new_final_entity_id IS NOT NULL
        """)
        
        dirty_entities = cursor.fetchall()
        total_records = len(dirty_entities)
        print(f"Se encontraron {total_records} entidades para marcar como 'sucias'...")
        
        # Variables para el seguimiento del progreso
        start_time = time.time()
        processed = 0
        commit_batch_size = 1000
        
        # Marcar cada entidad como 'sucia'
        for (entity_id,) in dirty_entities:
            cursor.execute(
                "UPDATE public.entity SET dirty = true WHERE uuid = %s",
                (entity_id,)
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
        print(f"\n\nMarcado completado con éxito.")
        print(f"Tiempo total: {total_time/60:.2f} minutos ({total_time:.2f} segundos)")
        print(f"Entidades procesadas: {processed}")
        print(f"Velocidad media: {processed/total_time:.2f} entidades por segundo")
        
    except Exception as e:
        print(f"\nError: {e}")
        if conn:
            conn.rollback()
    finally:
        if conn:
            conn.close()
            print("Conexión a la base de datos cerrada")

if __name__ == "__main__":
    mark_entities_dirty()