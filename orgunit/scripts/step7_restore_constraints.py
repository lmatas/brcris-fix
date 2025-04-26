import psycopg2
import os
import sys
import time
from dotenv import load_dotenv

# Cargar variables de entorno desde .env
load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '..', '.env'))

# Configuración de la base de datos (leer desde variables de entorno)
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")

def get_connection():
    """Establece y devuelve una conexión a la base de datos."""
    try:
        conn = psycopg2.connect(
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            host=DB_HOST,
            port=DB_PORT
        )
        return conn
    except psycopg2.OperationalError as e:
        print(f"Error al conectar a la base de datos: {e}")
        sys.exit(1)

def execute_sql_script(sql_filename="step7_restore_constraints.sql"):
    """Lee y ejecuta comandos SQL desde un archivo."""
    conn = None
    cursor = None
    start_time = time.time()
    executed_count = 0
    sql_commands = []

    # Construir la ruta al archivo SQL (asumiendo que está en ../sql/)
    script_dir = os.path.dirname(__file__)
    sql_file_path = os.path.join(script_dir, '..', 'sql', sql_filename)

    try:
        print(f"Leyendo archivo SQL: {sql_file_path}")
        with open(sql_file_path, 'r') as file:
            # Leer todo el contenido y dividir por ';' para obtener comandos individuales
            # Filtrar comandos vacíos resultantes de la división
            sql_content = file.read()
            sql_commands = [cmd.strip() for cmd in sql_content.split(';') if cmd.strip() and not cmd.strip().startswith('--')]
            print(f"Se encontraron {len(sql_commands)} comandos SQL para ejecutar.")

        conn = get_connection()
        cursor = conn.cursor()

        print("\nIniciando ejecución de comandos SQL...")
        for i, command in enumerate(sql_commands):
            if not command: # Saltar comandos vacíos
                continue
            try:
                print(f"Ejecutando comando {i+1}/{len(sql_commands)}...")
                # print(f"DEBUG: Comando: {command[:100]}...") # Descomentar para depurar
                start_cmd_time = time.time()
                cursor.execute(command)
                end_cmd_time = time.time()
                print(f"Comando {i+1} ejecutado en {end_cmd_time - start_cmd_time:.2f} segundos.")
                executed_count += 1
                # Commit después de cada comando para manejar errores individuales si es necesario
                # O mover conn.commit() fuera del bucle para una transacción única
                conn.commit()
            except psycopg2.Error as exec_error:
                conn.rollback() # Revertir el comando fallido
                # Verificar si el error es 'duplicate object' (constraint ya existe)
                if exec_error.pgcode == '42710': # 42710 = duplicate_object
                    print(f"Información: La restricción en el comando {i+1} probablemente ya existe (Error {exec_error.pgcode}). Continuando...")
                    # No contamos esto como ejecutado exitosamente en el sentido de 'creado ahora'
                    # pero no es un error fatal para el script.
                else:
                    # Otro tipo de error, imprimir advertencia/error
                    print(f"Advertencia/Error al ejecutar comando {i+1}: {exec_error} (Código: {exec_error.pgcode})")
                    print(f"Comando: {command}")
                    # Podrías decidir detenerte aquí si el error es crítico
                    # return False

                # Asegurarse de que la conexión sigue activa o reabrir si es necesario
                if conn.closed:
                    print("La conexión se cerró, intentando reconectar...")
                    conn = get_connection()
                    cursor = conn.cursor()
                elif cursor.closed:
                     cursor = conn.cursor()


        # conn.commit() # Descomentar si se prefiere una única transacción
        # El contador ahora refleja comandos que no fallaron o fallaron con 'duplicate object'
        # Para ser más precisos, podríamos tener un contador de 'ya existentes'
        print(f"\n{executed_count} comandos SQL intentados (algunos podrían ya existir).")

        total_time = time.time() - start_time
        print(f"\nEjecución completada.")
        print(f"Tiempo total: {total_time:.2f} segundos")
        return True

    except FileNotFoundError:
        print(f"Error: No se encontró el archivo SQL '{sql_file_path}'.")
        return False
    except Exception as e:
        print(f"Error inesperado durante la ejecución: {e}")
        if conn:
            conn.rollback()
        return False
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
        print("Conexión a la base de datos cerrada.")

if __name__ == "__main__":
    # El nombre del archivo SQL se busca en ../sql/ relativo a este script
    sql_file = "step7_restore_constraints.sql"
    print(f"--- Iniciando Step 7: Restaurar Constraints ---")
    success = execute_sql_script(sql_file)
    print(f"--- Step 7 completado {'con éxito' if success else 'con errores'}. ---")
    sys.exit(0 if success else 1)
