# filepath: /brcris_fix/brcris_fix/scripts/step9_update_final_entities.py

import time
import sys
from utils.db_utils import get_connection, print_progress

def update_final_entities():
    """Actualiza el identificador final de las entidades fuente relacionadas con entidades preexistentes."""
    conn = None
    try:
        # Conectar a la base de datos
        print("Conectando a la base de datos...")
        conn = get_connection()
        if not conn:
            print("Error: No se pudo establecer conexión a la base de datos.")
            return False
            
        cursor = conn.cursor()
        
        # Obtener los registros que necesitan actualización
        cursor.execute("""
            SELECT se.uuid, web.new_final_entity_id
            FROM public.source_entity se
            JOIN public.wrong_orcid_entity_backup web ON se.uuid = web.source_entity_id
            WHERE web.new_final_entity_id IS NOT NULL
        """)
        
        final_entities = cursor.fetchall()
        total_records = len(final_entities)
        print(f"Se encontraron {total_records} entidades para actualizar...")
        
        # Variables para el seguimiento del progreso
        start_time = time.time()
        processed = 0
        commit_batch_size = 1000
        
        # Actualizar cada entidad
        for source_entity_id, new_final_entity_id in final_entities:
            cursor.execute(
                "UPDATE public.source_entity SET final_entity_id = %s WHERE uuid = %s",
                (new_final_entity_id, source_entity_id)
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
        print(f"\n\nActualización de identificadores finales completada con éxito.")
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
    update_final_entities()