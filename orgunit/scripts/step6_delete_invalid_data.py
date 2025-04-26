#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import time
import sys
import os
from utils.db_utils import get_connection

def delete_invalid_data():
    """
    Paso 6: Eliminar datos inválidos de OrgUnit (source y entity) basados en tablas auxiliares.
    """
    print("Paso 6: Eliminación de datos inválidos de OrgUnit")
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

        # Ruta al archivo SQL
        sql_file_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                                    'sql', 'step6_delete_invalid_data.sql')

        print(f"Leyendo SQL desde: {sql_file_path}")

        # Leer el contenido del archivo SQL
        with open(sql_file_path, 'r') as sql_file:
            sql_content = sql_file.read()

        # Dividir el SQL por las sentencias (asumiendo que están separadas por punto y coma)
        sql_statements = [stmt.strip() for stmt in sql_content.split(';') if stmt.strip()]

        # Variables para el seguimiento del progreso
        start_time = time.time()
        total_rows_affected = 0

        # Ejecutar cada sentencia SQL
        for i, stmt in enumerate(sql_statements):
            # Obtener la primera línea (comentario) de la consulta si existe
            first_line = stmt.split('\n')[0].strip()
            if first_line.startswith('--'):
                print(f"\nEjecutando sentencia SQL {i+1}/{len(sql_statements)}:")
                print(f"Operación: {first_line}")
            else:
                 print(f"\nEjecutando sentencia SQL {i+1}/{len(sql_statements)}:")
                 print(f"Operación: {stmt[:80]}...") # Mostrar inicio de la sentencia si no hay comentario

            # Ignorar comentarios en el SQL
            if stmt.strip() and not stmt.strip().startswith('--'):
                try:
                    cursor.execute(stmt)
                    rows_affected = cursor.rowcount
                    print(f"Filas afectadas: {rows_affected}")
                    if rows_affected > 0:
                        total_rows_affected += rows_affected
                except Exception as exec_error:
                    print(f"Error al ejecutar la sentencia: {exec_error}")
                    # Decidir si continuar o detenerse en caso de error
                    # Por ahora, continuamos con las siguientes sentencias
                    # conn.rollback() # Podría ser necesario si una sentencia falla
                    # return False

        # Confirmar cambios
        conn.commit()

        # Mostrar resumen final
        total_time = time.time() - start_time
        print(f"\n\nPaso 6 completado con éxito.")
        print(f"Total de filas eliminadas (aproximado): {total_rows_affected}")
        print(f"Tiempo total: {total_time/60:.2f} minutos ({total_time:.2f} segundos)")

        return True

    except Exception as e:
        print(f"\nError durante el Paso 6: {e}")
        if conn:
            conn.rollback()
        return False
    finally:
        if conn:
            conn.close()
            print("Conexión cerrada.")

if __name__ == "__main__":
    success = delete_invalid_data()
    sys.exit(0 if success else 1)
