# filepath: /Users/lmatas/source/brcris_fix/utils/db_utils.py
import psycopg2
import os
import time
import sys
from dotenv import load_dotenv
import xxhash

load_dotenv()

def get_db_config():
    return {
        'host': os.getenv('DB_HOST', 'localhost'),
        'database': os.getenv('DB_NAME', 'postgres'),
        'user': os.getenv('DB_USER', 'postgres'),
        'password': os.getenv('DB_PASSWORD', ''),
        'port': os.getenv('DB_PORT', '5432')
    }

def get_connection():
    try:
        return psycopg2.connect(**get_db_config())
    except Exception as e:
        print(f"Error al conectar a la base de datos: {e}")
        return None

def execute_query(conn, query, params=None):
    cursor = conn.cursor()
    try:
        cursor.execute(query, params)
        if query.strip().upper().startswith('SELECT'):
            return cursor.fetchall(), [desc[0] for desc in cursor.description]
        return True, None
    except Exception as e:
        print(f"Error al ejecutar consulta: {e}")
        print(f"Consulta: {query}")
        return None, None
    finally:
        cursor.close()

def execute_sql_file(conn, filepath):
    cursor = conn.cursor()
    
    try:
        print(f"Ejecutando SQL desde archivo: {filepath}")
        with open(filepath, 'r') as sql_file:
            sql = sql_file.read()
            cursor.execute(sql)
            conn.commit()
        print(f"Archivo SQL ejecutado con éxito")
        return True
    except Exception as e:
        print(f"Error al ejecutar SQL desde archivo: {e}")
        conn.rollback()
        return False
    finally:
        cursor.close()

def check_table_exists(conn, table_name):
    cursor = conn.cursor()
    try:
        cursor.execute(f"""
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_schema = 'public'
                AND table_name = %s
            )
        """, (table_name,))
        return cursor.fetchone()[0]
    except Exception as e:
        print(f"Error al verificar existencia de tabla: {e}")
        return False
    finally:
        cursor.close()

def generate_xxhash64_int(text):
    hash_value = xxhash.xxh64(text).intdigest()
    if hash_value > 9223372036854775807:
        hash_value -= 18446744073709551616
    return hash_value

def print_progress(processed, total, start_time):
    progress = (processed / total) * 100
    elapsed_time = time.time() - start_time
    records_per_second = processed / elapsed_time if elapsed_time > 0 else 0
    remaining_time = (total - processed) / records_per_second if records_per_second > 0 else 0
    
    progress_message = f"\rProgreso: {progress:.1f}% ({processed}/{total}) - " \
                      f"Velocidad: {records_per_second:.2f} reg/s - " \
                      f"Tiempo restante: {remaining_time/60:.1f} min"
    sys.stdout.write(progress_message)
    sys.stdout.flush()