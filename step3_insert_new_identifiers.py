#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import time
import sys
from utils.db_utils import get_connection, print_progress

def insert_new_identifiers():
    """Inserta los nuevos identificadores en la tabla semantic_identifier usando los IDs ya generados"""
    conn = None
    try:
        # Conectar a la base de datos
        print("Conectando a la base de datos...")
        conn = get_connection()
        if not conn:
            print("Error: No se pudo establecer conexión a la base de datos.")
            return False
            
        cursor = conn.cursor()
        
        # Obtener los new_id y new_semantic_id de wrong_orcid_semantic_identifier que no estén en semantic_identifier
        cursor.execute("""
            SELECT DISTINCT w.new_id, w.new_semantic_id
            FROM wrong_orcid_semantic_identifier w
            LEFT JOIN semantic_identifier s ON s.id = w.new_id
            WHERE w.new_id IS NOT NULL
            AND w.new_semantic_id IS NOT NULL
            AND s.id IS NULL
        """)
        
        new_identifiers = cursor.fetchall()
        total_records = len(new_identifiers)
        print(f"Se encontraron {total_records} nuevos identificadores para insertar...")
        
        # Variables para el seguimiento del progreso
        start_time = time.time()
        processed = 0
        commit_batch_size = 1000
        
        # Insertar cada nuevo identificador
        for new_id, new_semantic_id in new_identifiers:
            # Insertar el registro utilizando el new_id ya generado
            cursor.execute(
                "INSERT INTO semantic_identifier (id, semantic_id) VALUES (%s, %s)",
                (new_id, new_semantic_id)
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
        print(f"\n\nInserción completada con éxito.")
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
    insert_new_identifiers()
