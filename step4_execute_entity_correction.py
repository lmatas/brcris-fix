#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import time
import sys
import argparse
from dotenv import load_dotenv
from tabulate import tabulate
from colorama import init, Fore, Style
from utils.db_utils import get_connection, execute_query, execute_sql_file, check_table_exists

# Inicializar colorama para salida de color
init()

# Cargar variables de entorno
load_dotenv()

def print_section_header(title):
    """Imprime un encabezado de sección formateado"""
    print(f"\n{Fore.CYAN}{'=' * 80}")
    print(f" {title}")
    print(f"{'=' * 80}{Style.RESET_ALL}\n")

def print_query_results(conn, query, title, params=None):
    """Ejecuta una consulta y muestra los resultados en formato tabular"""
    print(f"\n{Fore.GREEN}== {title} =={Style.RESET_ALL}")
    results, headers = execute_query(conn, query, params)
    if results:
        print(tabulate(results, headers=headers, tablefmt="pretty"))
    else:
        print(f"{Fore.YELLOW}No se encontraron resultados{Style.RESET_ALL}")

def create_correction_table(conn):
    """Crea la tabla de corrección si no existe"""
    print_section_header("VERIFICANDO/CREANDO TABLA DE CORRECCIÓN")
    
    if check_table_exists(conn, 'wrong_orcid_entity_correction'):
        print(f"{Fore.YELLOW}La tabla wrong_orcid_entity_correction ya existe en la base de datos{Style.RESET_ALL}")
        return True
    
    # Si la tabla no existe, la creamos desde el archivo SQL
    return execute_sql_file(conn, '/Users/lmatas/source/brcris_fix/crear_tabla_correccion.sql')

def verify_before_process(conn):
    """Ejecuta consultas de verificación antes del proceso"""
    print_section_header("VERIFICACIÓN ANTES DEL PROCESO")
    
    # 1. Total de referencias incorrectas
    print_query_results(conn, 
        """
        SELECT COUNT(*) AS total_referencias_incorrectas
        FROM source_entity_semantic_identifier sesi
        JOIN wrong_orcid_semantic_identifier w ON sesi.semantic_id = w.id
        WHERE w.new_id IS NOT NULL
        """, 
        "Total de referencias con ORCID incorrecto"
    )
    

def execute_correction_procedure(conn):
    """Ejecuta el procedimiento de corrección de entidades"""
    print_section_header("EJECUTANDO PROCEDIMIENTO DE CORRECCIÓN")
    
    cursor = conn.cursor()
    try:
        # Verificar si el procedimiento existe
        cursor.execute("""
            SELECT EXISTS (
                SELECT FROM pg_proc
                JOIN pg_namespace ON pg_namespace.oid = pg_proc.pronamespace
                WHERE proname = 'fix_wrong_orcid_entities' 
                AND pg_namespace.nspname = 'public'
            )
        """)
        proc_exists = cursor.fetchone()[0]
        
        if not proc_exists:
            print(f"{Fore.YELLOW}El procedimiento almacenado no existe. Creándolo...{Style.RESET_ALL}")
            execute_sql_file(conn, './procedimiento_correccion_entidades.sql')
        
        # Registrar tiempo de inicio
        start_time = time.time()
        
        print(f"{Fore.YELLOW}Ejecutando procedimiento fix_wrong_orcid_entities...{Style.RESET_ALL}")
        cursor.execute("CALL fix_wrong_orcid_entities()")
        conn.commit()
        
        # Registrar tiempo total
        total_time = time.time() - start_time
        print(f"{Fore.GREEN}Procedimiento ejecutado correctamente en {total_time:.2f} segundos{Style.RESET_ALL}")
        return True
    except Exception as e:
        print(f"{Fore.RED}Error al ejecutar el procedimiento: {e}{Style.RESET_ALL}")
        conn.rollback()
        return False
    finally:
        cursor.close()

def verify_after_process(conn):
    """Ejecuta consultas de verificación después del proceso"""
    print_section_header("VERIFICACIÓN DESPUÉS DEL PROCESO")
    
    # 1. Referencias pendientes (no debería haber ninguna)
    print_query_results(conn,
        """
        SELECT COUNT(*) AS referencias_pendientes
        FROM source_entity_semantic_identifier sesi
        JOIN wrong_orcid_semantic_identifier w ON sesi.semantic_id = w.id
        WHERE w.new_id IS NOT NULL
        """,
        "Referencias pendientes (debería ser 0)"
    )
    
    # 2. Referencias actualizadas a IDs nuevos
    print_query_results(conn,
        """
        SELECT 
            COUNT(*) AS referencias_actualizadas
        FROM source_entity_semantic_identifier sesi
        JOIN wrong_orcid_semantic_identifier w ON sesi.semantic_id = w.new_id
        WHERE w.new_id IS NOT NULL
        """,
        "Referencias actualizadas a IDs nuevos"
    )
    
    # 3. Resumen de corrección de entidades
    print_query_results(conn,
        """
        SELECT 
            COUNT(*) AS total_correcciones,
            SUM(CASE WHEN entity_created THEN 1 ELSE 0 END) AS entidades_creadas,
            SUM(CASE WHEN NOT entity_created THEN 1 ELSE 0 END) AS entidades_existentes
        FROM wrong_orcid_entity_correction
        """,
        "Resumen de corrección de entidades"
    )


def update_source_entity_references(conn):
    """Actualiza las referencias en source_entity_semantic_identifier"""
    print_section_header("ACTUALIZANDO REFERENCIAS EN SOURCE_ENTITY_SEMANTIC_IDENTIFIER")
    
    cursor = conn.cursor()
    try:
        # Obtener la cantidad total de registros a procesar
        cursor.execute("""
            SELECT COUNT(*)
            FROM source_entity_semantic_identifier sesi
            JOIN wrong_orcid_semantic_identifier w ON sesi.semantic_id = w.id
            WHERE w.new_id IS NOT NULL
        """)
        
        total_records = cursor.fetchone()[0]
        if total_records == 0:
            print(f"{Fore.GREEN}No hay referencias que actualizar{Style.RESET_ALL}")
            return True
            
        print(f"{Fore.YELLOW}Se deben actualizar {total_records} referencias{Style.RESET_ALL}")
        
        # Variables para el seguimiento del progreso
        start_time = time.time()
        processed = 0
        progress_report_interval = 1000
        
        # Utilizar un cursor del servidor para procesar lotes grandes
        cursor.execute("DECLARE ref_cursor CURSOR FOR "
                      "SELECT sesi.entity_id, w.id as old_id, w.new_id "
                      "FROM source_entity_semantic_identifier sesi "
                      "JOIN wrong_orcid_semantic_identifier w ON sesi.semantic_id = w.id "
                      "WHERE w.new_id IS NOT NULL")
        
        # Procesar los lotes
        while True:
            cursor.execute("FETCH 5000 FROM ref_cursor")
            records = cursor.fetchall()
            
            if not records:
                break
                
            for entity_id, old_semantic_id, new_semantic_id in records:
                # Eliminar referencia antigua
                cursor.execute(
                    "DELETE FROM source_entity_semantic_identifier WHERE entity_id = %s AND semantic_id = %s",
                    (entity_id, old_semantic_id)
                )
                
                # Insertar nueva referencia
                cursor.execute(
                    "INSERT INTO source_entity_semantic_identifier (entity_id, semantic_id) VALUES (%s, %s) "
                    "ON CONFLICT DO NOTHING",
                    (entity_id, new_semantic_id)
                )
                
                processed += 1
                
                if processed % progress_report_interval == 0:
                    # Calcular estadísticas de progreso
                    from utils.db_utils import print_progress
                    print_progress(processed, total_records, start_time)
                
        # Cerrar cursor
        cursor.execute("CLOSE ref_cursor")
        
        # Confirmar los cambios
        conn.commit()
        
        # Mostrar resumen final
        total_time = time.time() - start_time
        print(f"\n{Fore.GREEN}Actualización de referencias completada con éxito{Style.RESET_ALL}")
        print(f"Tiempo total: {total_time/60:.2f} minutos ({total_time:.2f} segundos)")
        print(f"Registros procesados: {processed}")
        print(f"Velocidad media: {processed/total_time:.2f} registros por segundo")
        return True
    except Exception as e:
        print(f"{Fore.RED}Error al actualizar referencias: {e}{Style.RESET_ALL}")
        conn.rollback()
        return False
    finally:
        cursor.close()

def run_full_process():
    """Ejecuta el proceso completo de corrección de entidades"""
    conn = None
    try:
        # Conectar a la base de datos
        print(f"{Fore.YELLOW}Conectando a la base de datos...{Style.RESET_ALL}")
        conn = get_connection()
        if not conn:
            print(f"{Fore.RED}No se pudo conectar a la base de datos. Proceso abortado.{Style.RESET_ALL}")
            return False
            
        # Mostrar información de la conexión
        db_info = conn.info
        print(f"{Fore.GREEN}Conexión establecida: {db_info.host}:{db_info.port}/{db_info.dbname} (usuario: {db_info.user}){Style.RESET_ALL}")
        
        # Registrar tiempo de inicio
        start_time = time.time()
        
        # 1. Verificación previa
        verify_before_process(conn)
        
        # 2. Crear tabla de corrección
        if not create_correction_table(conn):
            print(f"{Fore.RED}Error al crear tabla de corrección. Proceso abortado.{Style.RESET_ALL}")
            return False
        
        # 3. Ejecutar procedimiento de corrección
        if not execute_correction_procedure(conn):
            print(f"{Fore.RED}Error en el procedimiento de corrección. Proceso abortado.{Style.RESET_ALL}")
            return False

        # 4. Actualizar referencias (ahora después del procedimiento de corrección)
        if not update_source_entity_references(conn):
            print(f"{Fore.RED}Error al actualizar referencias. Proceso abortado.{Style.RESET_ALL}")
            return False
        
        # 5. Verificación posterior
        verify_after_process(conn)
        
        # Mostrar tiempo total
        total_time = time.time() - start_time
        print(f"\n{Fore.GREEN}{'=' * 80}")
        print(f" PROCESO COMPLETADO CON ÉXITO")
        print(f"{'=' * 80}{Style.RESET_ALL}")
        print(f"Tiempo total de ejecución: {total_time/60:.2f} minutos ({total_time:.2f} segundos)")
        return True
    except Exception as e:
        print(f"{Fore.RED}Error en el proceso: {e}{Style.RESET_ALL}")
        return False
    finally:
        if conn:
            conn.close()
            print(f"{Fore.YELLOW}Conexión a la base de datos cerrada{Style.RESET_ALL}")

def parse_arguments():
    """Analiza los argumentos de la línea de comandos"""
    parser = argparse.ArgumentParser(description='Script de corrección de entidades ORCID')
    
    parser.add_argument('--only-verify', action='store_true',
                      help='Solo realizar verificaciones sin ejecutar el proceso')
    
    parser.add_argument('--skip-update', action='store_true',
                      help='Omitir la actualización de referencias en la tabla source_entity_semantic_identifier')
    
    return parser.parse_args()

if __name__ == "__main__":
    args = parse_arguments()
    
    if args.only_verify:
        # Solo realizar verificaciones
        conn = None
        try:
            conn = get_connection()
            if conn:
                verify_before_process(conn)
                if check_table_exists(conn, 'wrong_orcid_entity_correction'):
                    verify_after_process(conn)
            else:
                print(f"{Fore.RED}No se pudo conectar a la base de datos.{Style.RESET_ALL}")
        finally:
            if conn:
                conn.close()
    else:
        # Ejecutar el procedimiento de corrección pero omitir la actualización si se solicita
        if args.skip_update:
            conn = None
            try:
                conn = get_connection()
                if conn:
                    verify_before_process(conn)
                    create_correction_table(conn)
                    execute_correction_procedure(conn)
                    print(f"{Fore.YELLOW}Omitiendo la actualización de referencias según solicitado con --skip-update{Style.RESET_ALL}")
                else:
                    print(f"{Fore.RED}No se pudo conectar a la base de datos.{Style.RESET_ALL}")
            finally:
                if conn:
                    conn.close()
        else:
            # Ejecutar proceso completo
            run_full_process()
