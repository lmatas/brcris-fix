#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import time
import sys
import xxhash
from utils.db_utils import get_connection, print_progress

def generate_xxhash64_int(text):
    """Genera un hash xxhash64 a partir del texto y lo convierte a int64"""
    hash_value = xxhash.xxh64(text).intdigest()
    # Asegurar que el valor esté en el rango de int8 en PostgreSQL
    if hash_value > 9223372036854775807:
        hash_value -= 18446744073709551616
    return hash_value

def update_with_hash():
    """
    Paso 2: Genera nuevos hashes para los identificadores ORCID normalizados.
    
    Este paso:
    - Calcula un hash XXHash64 para cada identificador normalizado
    - Actualiza los registros con estos nuevos valores hash
    - Estos hashes serán la base para los nuevos identificadores semánticos
    """
    print("Paso 2: Generación de hashes para identificadores ORCID normalizados")
    print("=" * 80)
    
    conn = None
    try:
        # Conectar a la base de datos
        print("Conectando a la base de datos...")
        conn = get_connection()
        if not conn:
            print("Error: No se pudo establecer conexión a la base de datos.")
            return False
            
        cursor = conn.cursor()
        
        # Obtener registros que necesitan actualización
        query = "SELECT COUNT(*) FROM wrong_orcid_semantic_identifier WHERE new_id IS NULL"
        print(f"Operación: {query}")
        cursor.execute(query)
        total_records = cursor.fetchone()[0]
        print(f"Se encontraron {total_records} registros para actualizar...")
        
        if total_records == 0:
            print("No hay registros para actualizar. Paso 2 completado.")
            return True
        
        query = "SELECT id, new_semantic_id FROM wrong_orcid_semantic_identifier WHERE new_id IS NULL"
        print(f"Operación: {query}")
        cursor.execute(query)
        records = cursor.fetchall()
        
        # Variables para el seguimiento
        start_time = time.time()
        processed = 0
        commit_batch_size = 1000
        
        # Actualizar cada registro con su hash
        for record_id, new_semantic_id in records:
            if new_semantic_id:
                # Generar hash para el identificador normalizado
                hash_value = generate_xxhash64_int(new_semantic_id)
                
                # Actualizar el registro
                update_query = "UPDATE wrong_orcid_semantic_identifier SET new_id = %s WHERE id = %s"
                cursor.execute(update_query, (hash_value, record_id))
                
                # Actualizar el progreso
                processed += 1
                
                # Hacer commit cada cierto número de registros
                if processed % commit_batch_size == 0:
                    conn.commit()
                    print_progress(processed, total_records, start_time)
        
        # Confirmar cambios finales
        conn.commit()
        
        # Mostrar resumen final
        total_time = time.time() - start_time
        print(f"\n\nPaso 2 completado con éxito.")
        print(f"Tiempo total: {total_time/60:.2f} minutos ({total_time:.2f} segundos)")
        print(f"Registros procesados: {processed}/{total_records}")
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
    success = update_with_hash()
    sys.exit(0 if success else 1)