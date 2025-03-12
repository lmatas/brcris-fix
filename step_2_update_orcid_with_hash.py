import psycopg2
import xxhash
import os
from dotenv import load_dotenv
import time
import sys

# Cargar variables de entorno (opcionalmente desde un archivo .env)
load_dotenv()

# Configuración de conexión a la base de datos
db_config = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'database': os.getenv('DB_NAME', 'postgres'),
    'user': os.getenv('DB_USER', 'postgres'),
    'password': os.getenv('DB_PASSWORD', ''),
    'port': os.getenv('DB_PORT', '5432')
}

def generate_xxhash64_int(text):
    """Genera un hash xxhash64 a partir del texto y lo convierte a int64"""
    hash_value = xxhash.xxh64(text).intdigest()
    # Asegurar que el valor esté en el rango de int8 en PostgreSQL (-9223372036854775808 a 9223372036854775807)
    if hash_value > 9223372036854775807:
        hash_value -= 18446744073709551616
    return hash_value

def update_records():
    """Actualiza los registros en wrong_orcid_semantic_identifier con el hash de new_semantic_id"""
    conn = None
    try:
        # Conectar a la base de datos
        conn = psycopg2.connect(**db_config)
        cursor = conn.cursor()
        
        # Obtener registros que necesitan actualización (donde new_id es NULL)
        # Ahora seleccionamos new_semantic_id en lugar de semantic_id
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
                    
                    # Calcular estadísticas de progreso
                    progress = (processed / total_records) * 100
                    elapsed_time = time.time() - start_time
                    records_per_second = processed / elapsed_time if elapsed_time > 0 else 0
                    remaining_time = (total_records - processed) / records_per_second if records_per_second > 0 else 0
                    
                    # Mostrar progreso en la misma línea
                    progress_message = f"\rProgreso: {progress:.1f}% ({processed}/{total_records}) - Velocidad: {records_per_second:.2f} reg/s - Tiempo restante: {remaining_time/60:.1f} min"
                    sys.stdout.write(progress_message)
                    sys.stdout.flush()
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
        
    except Exception as e:
        print(f"\nError: {e}")
        if conn:
            conn.rollback()
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    update_records()
