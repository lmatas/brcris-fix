# filepath: /Users/lmatas/source/brcris_fix/utils/db_utils.py
import psycopg2
import os
import time
import sys
from dotenv import load_dotenv
import xxhash

load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '..', '..', '.env')) # Ajustar ruta para buscar .env en oasisbr/

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
        conn = psycopg2.connect(**get_db_config())
        print("Conexión a la base de datos establecida con éxito.")
        return conn
    except Exception as e:
        print(f"Error al conectar a la base de datos: {e}")
        return None

def execute_query(conn, query, params=None):
    cursor = conn.cursor()
    try:
        cursor.execute(query, params)
        if query.strip().upper().startswith(('SELECT', 'WITH')):
            results = cursor.fetchall()
            colnames = [desc[0] for desc in cursor.description]
            print(f"Consulta SELECT ejecutada. Filas devueltas: {len(results)}")
            return results, colnames
        else:
            conn.commit()
            rows_affected = cursor.rowcount
            print(f"Consulta non-SELECT ejecutada. Filas afectadas: {rows_affected}")
            return rows_affected, None
    except Exception as e:
        print(f"Error al ejecutar consulta: {e}")
        print(f"Consulta: {query[:500]}...") # Mostrar parte de la consulta
        conn.rollback()
        return None, None
    finally:
        cursor.close()

def execute_sql_file(conn, filepath):
    """Ejecuta comandos SQL desde un archivo, comando por comando."""
    cursor = conn.cursor()
    start_time = time.time()
    executed_count = 0
    total_rows_affected = 0
    sql_commands = []

    try:
        print(f"Leyendo archivo SQL: {filepath}")
        with open(filepath, 'r', encoding='utf-8') as file:
            sql_content = file.read()
            # Dividir por ';' y filtrar comandos vacíos y comentarios
            sql_commands = [cmd.strip() for cmd in sql_content.split(';') if cmd.strip() and not cmd.strip().startswith('--')]
            print(f"Se encontraron {len(sql_commands)} comandos SQL para ejecutar.")

        if not sql_commands:
            print("El archivo SQL está vacío o solo contiene comentarios. No hay nada que ejecutar.")
            return True, 0

        print("\nIniciando ejecución de comandos SQL...")
        for i, command in enumerate(sql_commands):
            if not command: continue # Saltar si quedó algún comando vacío
            try:
                print(f"Ejecutando comando {i+1}/{len(sql_commands)}...")
                # print(f"DEBUG: Comando: {command[:100]}...") # Descomentar para depurar
                cmd_start_time = time.time()
                cursor.execute(command)
                rows_affected = cursor.rowcount
                total_rows_affected += rows_affected if rows_affected > 0 else 0
                cmd_end_time = time.time()
                print(f"Comando {i+1} ejecutado en {cmd_end_time - cmd_start_time:.2f} segundos. Filas afectadas: {rows_affected if rows_affected >= 0 else 'N/A'}")
                executed_count += 1
                # Commit después de cada comando para manejar errores individuales si es necesario
                # O mover conn.commit() fuera del bucle para una transacción única si se prefiere
                conn.commit()
            except Exception as exec_error:
                conn.rollback() # Revertir en caso de error en este comando
                print(f"\nError al ejecutar comando {i+1}: {exec_error}")
                print(f"Comando: {command[:200]}...")
                print("Se ha realizado rollback de la transacción parcial.")
                return False, total_rows_affected # Detener la ejecución

        total_time = time.time() - start_time
        print(f"\nTodos los {executed_count} comandos ejecutados con éxito.")
        print(f"Tiempo total de ejecución: {total_time:.2f} segundos")
        print(f"Total filas afectadas (aproximado): {total_rows_affected}")
        return True, total_rows_affected

    except FileNotFoundError:
        print(f"\nError: El archivo SQL '{filepath}' no fue encontrado.")
        return False, 0
    except Exception as e:
        print(f"\nError inesperado durante la lectura o ejecución del SQL: {e}")
        if conn: conn.rollback()
        return False, total_rows_affected
    finally:
        if cursor: cursor.close()

def check_table_exists(conn, table_name, schema='public'):
    cursor = conn.cursor()
    try:
        cursor.execute(f"""
            SELECT EXISTS (
                SELECT FROM information_schema.tables
                WHERE table_schema = %s
                AND table_name = %s
            )
        """, (schema, table_name))
        exists = cursor.fetchone()[0]
        print(f"Verificación de tabla '{schema}.{table_name}': {'Existe' if exists else 'No existe'}")
        return exists
    except Exception as e:
        print(f"Error al verificar existencia de tabla '{schema}.{table_name}': {e}")
        return False
    finally:
        cursor.close()

def generate_xxhash64_int(text):
    if text is None: return None
    hash_value = xxhash.xxh64(text.encode('utf-8')).intdigest()
    # Ajustar al rango de bigint de PostgreSQL (-9223372036854775808 a 9223372036854775807)
    if hash_value > 9223372036854775807:
        hash_value -= 18446744073709551616 # 2**64
    return hash_value

def print_progress(processed, total, start_time, step_name="Procesando"):
    if total == 0:
        progress_message = f"\r{step_name}: {processed}/0 (100.0%)"
        sys.stdout.write(progress_message)
        sys.stdout.flush()
        return

    progress = (processed / total) * 100
    elapsed_time = time.time() - start_time
    records_per_second = processed / elapsed_time if elapsed_time > 0 else 0
    
    if records_per_second > 0:
        remaining_time = (total - processed) / records_per_second
        remaining_time_str = f"{remaining_time/60:.1f} min" if remaining_time > 60 else f"{remaining_time:.1f} seg"
    else:
        remaining_time_str = "inf"

    progress_message = f"\r{step_name}: {progress:.1f}% ({processed}/{total}) - " \
                      f"Velocidad: {records_per_second:.2f} reg/s - " \
                      f"Tiempo restante: {remaining_time_str}"
    sys.stdout.write(progress_message)
    sys.stdout.flush()