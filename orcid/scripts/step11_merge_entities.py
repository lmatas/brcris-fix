#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import time
import sys
from utils.db_utils import get_connection, print_progress

def merge_dirty_entities():
    """
    Paso 11: Llamada al procedimiento para hacer merge de los campos de entidades marcadas como dirty.
    
    Este paso:
    - Ejecuta el procedimiento de merge para actualizar las entidades afectadas
    """
    print("Paso 11: Merge de entidades afectadas")
    print("=" * 80)
    
    conn = None
    try:
        # Conectar a la base de datos
        print("Conectando a la base de datos...")
        conn = get_connection()
        if not conn:
            print("Error: No se pudo establecer conexión a la base de datos.")
            return False
        
        print("Ejecutando procedimiento de merge para entidades marcadas como dirty...")
        start_time = time.time()
        
        cursor = conn.cursor()
        print("Llamando al procedimiento: public.merge_entity_relation_data(1)")
        
        # Ejecutar el procedimiento almacenado
        cursor.execute("CALL public.merge_entity_relation_data(1)")
        conn.commit()
        
        # Mostrar resumen
        total_time = time.time() - start_time
        print(f"\n\nPaso 11 completado con éxito.")
        print(f"Tiempo total: {total_time/60:.2f} minutos ({total_time:.2f} segundos)")
        print("Se ha completado el merge de las entidades afectadas.")
        return True
            
    except Exception as e:
        print(f"\nError: {e}")
        if conn:
            conn.rollback()
        return False
    finally:
        if conn:
            conn.close()
            print("Conexión cerrada.")

if __name__ == "__main__":
    success = merge_dirty_entities()
    sys.exit(0 if success else 1)
