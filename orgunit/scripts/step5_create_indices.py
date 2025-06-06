#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import time
import sys
import os
from utils.db_utils import get_connection

def create_indices():
    """
    Paso 5: Crear índices para mejorar el rendimiento de las eliminaciones del paso 6.
    """
    print("Paso 5: Creación de índices")
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
                                    'sql', 'step5_create_indices.sql')

        print(f"Leyendo SQL desde: {sql_file_path}")

        # Leer el contenido del archivo SQL
        with open(sql_file_path, 'r') as sql_file:
            sql_content = sql_file.read()

        # Dividir el SQL por las sentencias (asumiendo que están separadas por punto y coma)
        sql_statements = [stmt.strip() for stmt in sql_content.split(';') if stmt.strip()]

        # Variables para el seguimiento del progreso
        start_time = time.time()

        # Ejecutar cada sentencia SQL
        for i, stmt in enumerate(sql_statements):
            # Obtener la primera línea (comentario) de la consulta
            first_line = stmt.split('\n')[0].strip()
            print(f"\nEjecutando sentencia SQL {i+1}/{len(sql_statements)}:")
            print(f"Operación: {first_line}")

            # Ignorar comentarios en el SQL
            if stmt.strip():
                cursor.execute(stmt)
                # Para CREATE INDEX, rowcount no es relevante o es -1
                print(f"Índice creado o ya existente.")

        # Confirmar cambios (aunque CREATE INDEX suele ser DDL y autocommit en algunos sistemas)
        conn.commit()

        # Mostrar resumen final
        total_time = time.time() - start_time
        print(f"\n\nPaso 5 completado con éxito.")
        print(f"Tiempo total: {total_time/60:.2f} minutos ({total_time:.2f} segundos)")

        return True

    except Exception as e:
        print(f"\nError durante el Paso 5: {e}")
        if conn:
            conn.rollback()
        return False
    finally:
        if conn:
            conn.close()
            print("Conexión cerrada.")

if __name__ == "__main__":
    success = create_indices()
    sys.exit(0 if success else 1)
