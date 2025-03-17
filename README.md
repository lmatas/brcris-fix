# Sistema de Corrección de Entidades ORCID

Este sistema corrige referencias a identificadores ORCID incorrectos en la base de datos, transformando URLs de formato `orcid::https://orcid.org/XXXX-XXXX-XXXX-XXXX` a identificadores normalizados `XXXX-XXXX-XXXX-XXXX`.

## Problema

En la base de datos existen identificadores ORCID almacenados con un formato incorrecto que incluye el prefijo URL completo. El sistema debe:

1. Identificar estos identificadores incorrectos
2. Crear nuevos identificadores con el formato correcto
3. Actualizar todas las referencias relacionadas
4. Crear nuevas entidades cuando sea necesario

## Requisitos previos

1. Python 3.6 o superior
2. PostgreSQL con acceso a la base de datos
3. Los paquetes Python listados en `requirements.txt`

## Instalación

```bash
# Configurar entorno virtual y dependencias
bash step0_setup_env.sh

# O manualmente:
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## Configuración

Cree un archivo `.env` en el directorio principal basado en `.env.example`:

```
DB_HOST=localhost
DB_NAME=lrharvester
DB_USER=lrharvester
DB_PASSWORD=lrharvester
DB_PORT=5432
```

## Proceso de corrección paso a paso

### Paso 1: Creación y llenado de la tabla de identificadores incorrectos

```bash
python step1_create_and_fill_tables.py
```

Este paso crea una tabla `wrong_orcid_semantic_identifier` que:
- Almacena los identificadores semánticos originales incorrectos
- Crea una versión normalizada sin el prefijo URL
- Prepara el espacio para los nuevos hashes que se generarán

### Paso 2: Generación de nuevos hashes para identificadores normalizados

```bash
python step_2_update_orcid_with_hash.py
```

Este paso:
- Calcula un nuevo hash XXHash64 para cada identificador normalizado
- Actualiza los registros con estos nuevos valores hash
- Estos hashes serán la base para los nuevos identificadores semánticos

### Paso 3: Inserción de los nuevos identificadores semánticos

```bash
python step3_insert_new_identifiers.py
```

Este paso:
- Inserta los nuevos identificadores y sus hashes en la tabla `semantic_identifier`
- Garantiza que existan todos los nuevos identificadores para el siguiente paso

### Paso 4: Corrección de entidades (procedimiento almacenado) y Actualización de referencias a entidades

```bash
python step4_execute_entity_correction.py --skip-update
```

Este paso ejecuta el procedimiento almacenado que:
- Identifica entidades que usan identificadores ORCID incorrectos
- Busca o crea entidades con los identificadores correctos
- Registra las correspondencias en la tabla `wrong_orcid_entity_correction`
- Actualiza las referencias en `source_entity_semantic_identifier`
- Reemplaza las referencias a los IDs antiguos con los nuevos


## Estructura de archivos

- `step0_setup_env.sh` - Configura el entorno virtual y dependencias
- `step1_create_and_fill_tables.py` - Crea tabla de trabajo y llena con datos iniciales
- `step1_orcid.sql` - SQL para crear tabla de identificadores incorrectos
- `step2_update_hash.py` - Actualiza con nuevos hashes para identificadores normalizados
- `step3_insert_new_identifiers.py` - Inserta nuevos identificadores en la BD
- `crear_tabla_correccion.sql` - Crea tabla para seguimiento de correcciones
- `step4_procedimiento_correccion_entidades.sql` - Procedimiento para corregir entidades
- `execute_entity_correction.py` - Script principal que ejecuta todo el proceso
- `verificacion_paso4.sql` - Consultas para verificar el estado antes/después

## Tablas principales

- `wrong_orcid_semantic_identifier` - Mapeo entre IDs incorrectos y correctos
- `wrong_orcid_entity_correction` - Registro de entidades corregidas
- `semantic_identifier` - Tabla de identificadores semánticos del sistema
- `source_entity_semantic_identifier` - Relación entre entidades y sus identificadores
- `entity` - Tabla principal de entidades

## Notas técnicas

- Los hashes se generan utilizando el algoritmo XXHash64
- Las transacciones se manejan con cuidado para garantizar integridad
- El proceso está diseñado para ser reanudable si ocurre un error
- Se reporta progreso en tiempo real para operaciones largas
