#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import time
import importlib.util
import colorama
from colorama import Fore, Style

# Inicializar colorama para colores en la consola
colorama.init()

def print_header(number, title, script_name):
    """Imprime un encabezado formateado para cada paso"""
    print("\n" + "=" * 80)
    print(f"{Fore.GREEN}PASO {number}: {title}{Style.RESET_ALL}")
    print(f"{Fore.CYAN}Script: {script_name}{Style.RESET_ALL}")
    print("=" * 80 + "\n")

def import_module_from_file(file_path):
    """Importa dinámicamente un módulo Python desde su ruta de archivo"""
    module_name = os.path.basename(file_path).replace('.py', '')
    spec = importlib.util.spec_from_file_location(module_name, file_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

def run_all_steps():
    """Ejecuta todos los scripts de los pasos en orden"""
    script_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'scripts')
    
    # Definir los pasos con sus descripciones
    steps = [
        (1, "Crear y llenar tabla de identificadores incorrectos", "step1_create_and_fill_tables.py", "create_and_fill_tables"),
        (2, "Generar nuevos hashes para identificadores normalizados", "step2_update_orcid_with_hash.py", "update_with_hash"),
        (3, "Insertar nuevos identificadores semánticos", "step3_insert_new_identifiers.py", "insert_new_identifiers"),
        (4, "Crear tabla de backup de entidades", "step4_create_entity_backup.py", "create_entity_backup"),
        (5, "Actualizar referencias en entidades fuente", "step5_update_source_entities.py", "update_source_entities"),
        (6, "Actualizar tabla de backup de entidades", "step6_update_entity_backup.py", "update_entity_backup"),
        (7, "Actualizar identificadores en la tabla de entidades", "step7_update_entity_semantic.py", "update_entity_semantic"),
        (8, "Marcar entidades como 'sucias'", "step8_mark_entities_dirty.py", "mark_entities_dirty"),
        (9, "Eliminar source entities marcadas como eliminadas", "step09_delete_source_entities.py", "delete_source_entities"),
        (10, "Excluir entidades con identificadores erróneos", "step10_delete_old_entities.py", "delete_wrong_entities"),
        (11, "Ejecutar merge de campos para entidades afectadas", "step11_merge_entities.py", "merge_dirty_entities")
    ]
    
    start_time = time.time()
    
    print(f"{Fore.YELLOW}SISTEMA DE CORRECCIÓN DE IDENTIFICADORES ORCID{Style.RESET_ALL}")
    print(f"{Fore.YELLOW}Iniciando ejecución de todos los pasos{Style.RESET_ALL}")
    print("\nFecha y hora de inicio:", time.strftime("%Y-%m-%d %H:%M:%S"))
    print("=" * 80)
    
    success_count = 0
    
    for step_num, description, script_name, function_name in steps:
        script_path = os.path.join(script_dir, script_name)
        
        # Verificar que el script existe
        if not os.path.exists(script_path):
            print(f"{Fore.RED}Error: No se encontró el script {script_path}{Style.RESET_ALL}")
            continue
        
        print_header(step_num, description, script_name)
        
        try:
            # Importar el módulo dinámicamente
            module = import_module_from_file(script_path)
            
            # Obtener la función principal
            main_function = getattr(module, function_name)
            
            # Ejecutar la función principal
            step_start_time = time.time()
            result = main_function()
            step_end_time = time.time()
            # Mostrar resultado
            # Check result - Each script function returns True on success, False on failure
            if result is True:
                print(f"\n{Fore.GREEN}✓ Paso {step_num} completado con éxito{Style.RESET_ALL}")
                print(f"Tiempo: {(step_end_time - step_start_time)/60:.2f} minutos")
                success_count += 1
            elif result is False:
                print(f"\n{Fore.RED}✗ Paso {step_num} falló{Style.RESET_ALL}")
                print("Abortando la ejecución...")
                break
            elif result is None:
                print(f"\n{Fore.YELLOW}⚠ Paso {step_num} no devolvió un resultado, asumiendo éxito{Style.RESET_ALL}")
                print(f"Tiempo: {(step_end_time - step_start_time)/60:.2f} minutos")
                success_count += 1
            else:
                print(f"\n{Fore.RED}✗ Paso {step_num} devolvió un resultado inesperado: {result}{Style.RESET_ALL}")
                print("Abortando la ejecución...")
                break
                
        except Exception as e:
            print(f"\n{Fore.RED}Error al ejecutar el paso {step_num}: {e}{Style.RESET_ALL}")
            print("Abortando la ejecución...")
            break
    
    # Mostrar resumen final
    end_time = time.time()
    total_time = end_time - start_time
    
    print("\n" + "=" * 80)
    print(f"{Fore.YELLOW}RESUMEN DE EJECUCIÓN{Style.RESET_ALL}")
    print(f"Pasos completados: {success_count}/{len(steps)}")
    print(f"Tiempo total: {total_time/60:.2f} minutos ({total_time:.2f} segundos)")
    print("Fecha y hora de finalización:", time.strftime("%Y-%m-%d %H:%M:%S"))
    
    if success_count == len(steps):
        print(f"\n{Fore.GREEN}¡Todos los pasos se ejecutaron correctamente!{Style.RESET_ALL}")
        return True
    else:
        print(f"\n{Fore.RED}La ejecución se detuvo en el paso {success_count + 1}{Style.RESET_ALL}")
        return False

if __name__ == "__main__":
    success = run_all_steps()
    sys.exit(0 if success else 1)
