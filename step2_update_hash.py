#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import time
import sys
from utils.db_utils import get_connection, generate_xxhash64_int, print_progress

def update_records():
    """Actualiza los registros en wrong_orcid_semantic_identifier con el hash de new_semantic_id"""
    conn = None
    try:
        # Conectar a la base de datos
        print("Conectando a la base de datos...")
        conn = get_connection()
        if not conn:
            print("Error: No se pudo establecer conexión a la base de datos.")
            return False
            
        cursor = conn.cursor()
        
        # Obtener registros que necesitan actualización (donde new_id es NULL)
        cursor.execute("SELECT id, new_semantic_id FROM wrong_orcid_semantic_identifier WHERE new_id IS NULL")
        records = cursor.fetchall()
        
        total_records = len(records)
        print(f"Procesando {total_records} registros...")
        
        # Variables para el seguimiento del progreso
        start_time = time.time()
        processed = 0
        commit_batch_size = 1000  # Cantidad de registros para hacer commit
        
        # Actualizar cada registro
        for record_id, new_semantic_id in records:
            if new_semantic_id:
                # Generar hash para el new_semantic_id
                hash_value = generate_xxhash64_int(new_semantic_id)
                
                # Actualizar el registro
                cursor.execute(
                    "UPDATE wrong_orcid_semantic_identifier SET new_id = %s WHERE id = %s",
                    (hash_value, record_id)
                )
                
                # Actualizar el progreso
                processed += 1
                
                # Hacer commit cada 1000 registros y mostrar progreso
                if processed % commit_batch_size == 0:
                    conn.commit()
                    print_progress(processed, total_records, start_time)
            else:
                # Si no hay new_semantic_id, incrementamos el contador pero no actualizamos la BD
                processed += 1
                
        # Confirmar cambios finales
        conn.commit()
        
        # Mostrar resumen final en una nueva línea
        total_time = time.time() - start_time
        print(f"\n\nActualización completada con éxito.")
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
    update_records()
