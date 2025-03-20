# filepath: /Users/lmatas/source/brcris_fix/scripts/step7_update_entity_semantic.py
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import time
import sys
from utils.db_utils import get_connection, print_progress

def update_entity_semantic():
    """Actualiza los identificadores semánticos en la tabla de entidades reutilizando las entidades existentes"""
    conn = None
    try:
        # Conectar a la base de datos
        print("Conectando a la base de datos...")
        conn = get_connection()
        if not conn:
            print("Error: No se pudo establecer conexión a la base de datos.")
            return False
            
        cursor = conn.cursor()
        
        # Obtener los identificadores semánticos que necesitan ser actualizados
        cursor.execute("""
            SELECT sesi.entity_id, web.new_semantic_id
            FROM public.source_entity_semantic_identifier sesi
            JOIN public.wrong_orcid_entity_backup web ON sesi.semantic_id = web.old_semantic_id
            WHERE web.new_semantic_id IS NOT NULL
        """)
        
        records = cursor.fetchall()
        total_records = len(records)
        print(f"Se encontraron {total_records} identificadores semánticos para actualizar...")
        
        # Variables para el seguimiento del progreso
        start_time = time.time()
        processed = 0
        commit_batch_size = 1000
        
        # Actualizar cada identificador semántico
        for entity_id, new_semantic_id in records:
            cursor.execute(
                "UPDATE public.source_entity_semantic_identifier SET semantic_id = %s WHERE entity_id = %s",
                (new_semantic_id, entity_id)
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
        print(f"\n\nActualización de identificadores semánticos completada con éxito.")
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
    update_entity_semantic()