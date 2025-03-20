#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import time
import sys
from utils.db_utils import get_connection, print_progress

def delete_wrong_entities():
    """
    Paso 10: Borrar todas las entidades con semantic IDs erróneos que ya tenían una entidad
    existente con el semantic ID corregido.
    
    Este paso:
    - Modifica las restricciones de clave foránea para agregar CASCADE DELETE
    - Elimina las entidades antiguas que ya fueron reemplazadas por otras entidades
    """
    print("Paso 10: Borrado de entidades con semantic IDs erróneos")
    print("=" * 80)
    
    conn = None
    try:
        # Conectar a la base de datos
        print("Conectando a la base de datos...")
        conn = get_connection()
        if not conn:
            print("Error: No se pudo establecer conexión a la base de datos.")
            return False
        
        print("Modificando restricciones de clave foránea y borrando entidades...")
        start_time = time.time()
        
        cursor = conn.cursor()
        
        # 1. Modificar entity_semantic_identifier
        print("1. Modificando tabla entity_semantic_identifier...")
        cursor.execute("ALTER TABLE entity_semantic_identifier DROP CONSTRAINT fkinjr1aqio6tuon2ypi6ixd4ao")
        cursor.execute("ALTER TABLE entity_semantic_identifier ADD CONSTRAINT fkinjr1aqio6tuon2ypi6ixd4ao FOREIGN KEY (entity_id) REFERENCES entity(uuid) ON DELETE CASCADE")
        
        # 2. Modificar entity_fieldoccr
        print("2. Modificando tabla entity_fieldoccr...")
        cursor.execute("ALTER TABLE entity_fieldoccr DROP CONSTRAINT fkg85y6bnncn3q9y762wvrwj08u")
        cursor.execute("ALTER TABLE entity_fieldoccr ADD CONSTRAINT fkg85y6bnncn3q9y762wvrwj08u FOREIGN KEY (entity_id) REFERENCES entity(uuid) ON DELETE CASCADE")
        
        # 3. Modificar relation (from_entity_id)
        print("3. Modificando tabla relation (from_entity_id)...")
        cursor.execute("ALTER TABLE relation DROP CONSTRAINT fk9kavjxgi0tpvju15iab7petiw")
        cursor.execute("ALTER TABLE relation ADD CONSTRAINT fk9kavjxgi0tpvju15iab7petiw FOREIGN KEY (from_entity_id) REFERENCES entity(uuid) ON DELETE CASCADE")
        
        # 4. Modificar relation (to_entity_id)
        print("4. Modificando tabla relation (to_entity_id)...")
        cursor.execute("ALTER TABLE relation DROP CONSTRAINT fk9wvqikvahl1a0x1xkcfdw42n")
        cursor.execute("ALTER TABLE relation ADD CONSTRAINT fk9wvqikvahl1a0x1xkcfdw42n FOREIGN KEY (to_entity_id) REFERENCES entity(uuid) ON DELETE CASCADE")
        
        # 5. Modificar relation_fieldoccr (from_entity_id)
        print("5. Modificando tabla relation_fieldoccr (from_entity_id)...")
        cursor.execute("ALTER TABLE relation_fieldoccr DROP CONSTRAINT relation_fieldoccr_entityfrom_uuid_fk")
        cursor.execute("ALTER TABLE relation_fieldoccr ADD CONSTRAINT relation_fieldoccr_entityfrom_uuid_fk FOREIGN KEY (from_entity_id) REFERENCES entity(uuid) ON DELETE CASCADE")
        
        # 6. Modificar relation_fieldoccr (to_entity_id)
        print("6. Modificando tabla relation_fieldoccr (to_entity_id)...")
        cursor.execute("ALTER TABLE relation_fieldoccr DROP CONSTRAINT relation_fieldoccr_entityto_uuid_fk")
        cursor.execute("ALTER TABLE relation_fieldoccr ADD CONSTRAINT relation_fieldoccr_entityto_uuid_fk FOREIGN KEY (to_entity_id) REFERENCES entity(uuid) ON DELETE CASCADE")
        
        # Borrar las entidades
        print("Borrando entidades antiguas que ya fueron reemplazadas...")
        cursor.execute("DELETE FROM public.entity WHERE uuid IN (SELECT distinct final_entity_id from wrong_orcid_entity_backup where new_final_entity_id is not null)")
        deleted_count = cursor.rowcount
        
        conn.commit()
        
        # Mostrar resumen
        total_time = time.time() - start_time
        print(f"\n\nPaso 10 completado con éxito.")
        print(f"Tiempo total: {total_time/60:.2f} minutos ({total_time:.2f} segundos)")
        print(f"Se han eliminado {deleted_count} entidades con semantic IDs erróneos.")
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
    success = delete_wrong_entities()
    sys.exit(0 if success else 1)
