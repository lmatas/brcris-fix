



-- PASO 11 - PROCESOS INDEPENDIENTES PARA MERGE DE DATOS
-- Versión optimizada con DISABLE/ENABLE TRIGGER y REINDEX INDEX

-- 1. PROCESO DE PREPARACIÓN Y PREOPTIMIZACIÓN
CREATE OR REPLACE FUNCTION prepare_merge_environment()
RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration INTERVAL;
BEGIN
    start_time := clock_timestamp();
    RAISE NOTICE 'Iniciando proceso de preparación para merge: %', start_time;
 
   -- Crear tabla auxiliar unificada con entidades dirty y sus source entities
    RAISE NOTICE 'Creando tabla auxiliar unificada para entidades dirty y sus source entities...';

    -- Primero creamos la tabla
    DROP TABLE IF EXISTS aux_entity_map;
    CREATE TABLE aux_entity_map (
        entity_id UUID NOT NULL,
        source_id UUID
    );

    -- Crear índice en entity_id inmediatamente para optimizar inserciones
    CREATE INDEX ON aux_entity_map(entity_id);

    -- Inserción optimizada en dos pasos:
    -- 1. Primero insertar las entidades dirty que tienen source_entities
    INSERT INTO aux_entity_map (entity_id, source_id)
    SELECT e.uuid, se.uuid
    FROM entity e
    JOIN source_entity se ON se.final_entity_id = e.uuid
    WHERE e.dirty = TRUE;

    -- Crear índice en source_id después de insertar
    CREATE INDEX ON aux_entity_map(source_id);
    -- CREATE INDEX ON aux_entity_map(entity_id); -- Ya creado arriba

    -- Calcular duración
    end_time := clock_timestamp();
    duration := end_time - start_time;

    RAISE NOTICE 'Proceso de preparación completado exitosamente (Triggers desactivados)';
    RAISE NOTICE 'Duración: % segundos', EXTRACT(EPOCH FROM duration);
END;
$$ LANGUAGE plpgsql;

-- 2. PROCESO DE ENTIDADES (Sin cambios en la lógica interna)
CREATE OR REPLACE FUNCTION process_dirty_entities()
RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration INTERVAL;
BEGIN
    start_time := clock_timestamp();
    RAISE NOTICE 'Iniciando proceso de merge de entidades dirty (con triggers desactivados): %', start_time;


    -- Crear tabla temporal para los fieldoccrs a insertar usando directamente aux_entity_map
    RAISE NOTICE 'Creando tabla temporal para fieldoccrs...';
    
    DROP TABLE IF EXISTS tmp_entity_fieldoccrs;
    CREATE TEMP TABLE tmp_entity_fieldoccrs AS
    SELECT DISTINCT aem.entity_id, sef.fieldoccr_id
    FROM aux_entity_map aem
    JOIN source_entity_fieldoccr sef ON sef.entity_id = aem.source_id
    WHERE aem.source_id IS NOT NULL;
    CREATE INDEX ON tmp_entity_fieldoccrs(entity_id);

    -- Eliminar fieldoccrs existentes de manera eficiente
    RAISE NOTICE 'Eliminando fieldoccrs existentes...';
    DELETE FROM entity_fieldoccr
    WHERE entity_id IN (SELECT DISTINCT entity_id FROM aux_entity_map);

    -- Insertar nuevos fieldoccrs en un solo paso
    -- Nota: Si hay violaciones de FK (p.ej., fieldoccr_id no existe), fallará aquí.
    RAISE NOTICE 'Insertando nuevos fieldoccrs...';
    INSERT INTO entity_fieldoccr (entity_id, fieldoccr_id)
    SELECT entity_id, fieldoccr_id FROM tmp_entity_fieldoccrs;

   -- Actualización de entidades en una sola consulta
    RAISE NOTICE 'Actualizando estado dirty de entidades...';
    UPDATE entity
    SET dirty = FALSE
    WHERE uuid IN (SELECT DISTINCT entity_id FROM aux_entity_map);

    -- Calcular duración
    end_time := clock_timestamp();
    duration := end_time - start_time;

    RAISE NOTICE 'Proceso de entidades completado exitosamente';
    RAISE NOTICE 'Duración de merge de entidades: % segundos', EXTRACT(EPOCH FROM duration);
END;
$$ LANGUAGE plpgsql;

-- 3. PROCESO DE RELACIONES (Sin cambios en la lógica interna)
CREATE OR REPLACE FUNCTION process_dirty_relations()
RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration INTERVAL;
BEGIN
    start_time := clock_timestamp();
    RAISE NOTICE 'Iniciando proceso de merge de relaciones (con triggers desactivados): %', start_time;

    -- Crear tabla temporal para las nuevas relaciones a insertar usando directamente aux_entity_map
    RAISE NOTICE 'Creando tabla temporal para nuevas relaciones...';
    DROP TABLE IF EXISTS tmp_new_relations;
    CREATE TEMP TABLE tmp_new_relations AS
    SELECT DISTINCT -- Añadido DISTINCT aquí para evitar duplicados tempranos
           se1.final_entity_id as from_entity_id,
           sr.relation_type_id,
           se2.final_entity_id as to_entity_id,
           sr.from_entity_id as source_from_entity_id,
           sr.to_entity_id as source_to_entity_id,
           true as dirty
    FROM source_relation sr
    JOIN source_entity se1 ON sr.from_entity_id = se1.uuid
    JOIN source_entity se2 ON sr.to_entity_id = se2.uuid
    WHERE (EXISTS (SELECT 1 FROM aux_entity_map aem WHERE aem.source_id = sr.from_entity_id)
        OR EXISTS (SELECT 1 FROM aux_entity_map aem WHERE aem.source_id = sr.to_entity_id))
      AND se1.deleted = FALSE -- Asegurar que las entidades fuente no estén borradas
      AND se2.deleted = FALSE
      AND se1.final_entity_id IS NOT NULL -- Asegurar que tengan mapeo final
      AND se2.final_entity_id IS NOT NULL;

    -- Crear índices para optimizar la consulta posterior
    CREATE INDEX ON tmp_new_relations(relation_type_id, from_entity_id, to_entity_id);
    CREATE INDEX ON tmp_new_relations(source_from_entity_id);
    CREATE INDEX ON tmp_new_relations(source_to_entity_id);
    ANALYZE tmp_new_relations;

    -- Marcar relaciones existentes como dirty si sus entidades finales coinciden con las de tmp_new_relations
    RAISE NOTICE 'Marcando relaciones existentes afectadas como dirty...';
    UPDATE relation r
    SET dirty = TRUE
    WHERE EXISTS (
        SELECT 1 FROM tmp_new_relations tnr
        WHERE r.relation_type_id = tnr.relation_type_id
          AND r.from_entity_id = tnr.from_entity_id
          AND r.to_entity_id = tnr.to_entity_id
    );

    -- Insertar solo las relaciones que no existan previamente
    RAISE NOTICE 'Insertando nuevas relaciones (si no existen)...';
    INSERT INTO relation (relation_type_id, from_entity_id, to_entity_id, dirty)
    SELECT DISTINCT tnr.relation_type_id, tnr.from_entity_id, tnr.to_entity_id, tnr.dirty
    FROM tmp_new_relations tnr
    ON CONFLICT (relation_type_id, from_entity_id, to_entity_id) DO UPDATE SET dirty = TRUE; -- Si existe, marcarla como dirty

    -- Eliminar relation_fieldoccr para relaciones marcadas como dirty
    RAISE NOTICE 'Eliminando relation_fieldoccr para relaciones dirty...';
    DELETE FROM relation_fieldoccr rfo
    WHERE EXISTS (
        SELECT 1 FROM relation r
        WHERE r.dirty = TRUE
          AND rfo.relation_type_id = r.relation_type_id
          AND rfo.from_entity_id = r.from_entity_id
          AND rfo.to_entity_id = r.to_entity_id
    );

    -- Insertar campos de relaciones utilizando solamente tmp_new_relations para las relaciones marcadas como dirty
    RAISE NOTICE 'Insertando campos de relaciones para relaciones dirty...';
    INSERT INTO relation_fieldoccr (from_entity_id, relation_type_id, to_entity_id, fieldoccr_id)
    SELECT DISTINCT
        tnr.from_entity_id,
        tnr.relation_type_id,
        tnr.to_entity_id,
        sro.fieldoccr_id
    FROM tmp_new_relations tnr
    JOIN source_relation_fieldoccr sro ON sro.relation_type_id = tnr.relation_type_id
                                    AND sro.from_entity_id = tnr.source_from_entity_id
                                    AND sro.to_entity_id = tnr.source_to_entity_id
    -- Asegurarse de que la relación correspondiente está marcada como dirty (implícito por cómo se generó tnr y el UPDATE/INSERT previo)
    -- Añadir ON CONFLICT por si acaso, aunque el DELETE previo debería evitarlo
    ON CONFLICT (from_entity_id, relation_type_id, to_entity_id, fieldoccr_id) DO NOTHING;

    RAISE NOTICE 'Inserción de campos de relaciones completada';

    -- Actualización final: marcar relaciones como no dirty
    RAISE NOTICE 'Actualizando estado dirty de relaciones...';
    UPDATE relation
    SET dirty = FALSE
    WHERE dirty = TRUE;

    -- Calcular duración
    end_time := clock_timestamp();
    duration := end_time - start_time;

    RAISE NOTICE 'Proceso de relaciones completado exitosamente';
    RAISE NOTICE 'Duración de merge de relaciones: % segundos', EXTRACT(EPOCH FROM duration);
END;
$$ LANGUAGE plpgsql;

-- 4. PROCESO DE RESTABLECIMIENTO Y LIMPIEZA (AJUSTADO)
CREATE OR REPLACE FUNCTION restore_environment()
RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration INTERVAL;
    -- Constraint names from DDL (needed if using VALIDATE CONSTRAINT later)
    -- entity_fieldoccr_pk TEXT := 'entity_fieldoccr_pkey'; -- Assuming PK exists
    -- relation_pk TEXT := 'relation_pkey'; -- Assuming PK exists
    -- relation_fieldoccr_pk TEXT := 'relation_fieldoccr_pkey'; -- Assuming PK exists
BEGIN
    start_time := clock_timestamp();
    RAISE NOTICE 'Iniciando proceso de restablecimiento: %', start_time;

    -- Reactivar Triggers
    RAISE NOTICE 'Reactivando triggers USER en tablas afectadas...';
    ALTER TABLE public.entity_fieldoccr ENABLE TRIGGER USER;
    ALTER TABLE public.relation ENABLE TRIGGER USER;
    ALTER TABLE public.relation_fieldoccr ENABLE TRIGGER USER;

    
    -- Calcular duración
    end_time := clock_timestamp();
    duration := end_time - start_time;

    RAISE NOTICE 'Proceso de restablecimiento completado exitosamente (Triggers reactivados, Índices específicos reindexados)';
    RAISE NOTICE 'Duración: % segundos', EXTRACT(EPOCH FROM duration);
END;
$$ LANGUAGE plpgsql;

-- Procedimiento que ejecuta los 4 pasos secuencialmente con manejo de errores
CREATE OR REPLACE FUNCTION execute_complete_merge_process()
RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    total_duration INTERVAL;
    step_name TEXT;
    error_occurred BOOLEAN := FALSE;
    error_message TEXT;
    error_detail TEXT;
    error_hint TEXT;
    error_context TEXT;
    triggers_disabled BOOLEAN := FALSE; -- Flag para saber si necesitamos reactivar triggers en caso de error
BEGIN
    start_time := clock_timestamp();
    RAISE NOTICE '=== INICIANDO PROCESO COMPLETO DE MERGE (con DISABLE/ENABLE TRIGGER) ===';
    RAISE NOTICE 'Tiempo de inicio: %', start_time;

    -- Manejo de errores principal
    BEGIN
        -- Paso 1: Preparación y preoptimización (Desactiva Triggers)
        step_name := 'prepare_merge_environment';
        RAISE NOTICE 'Ejecutando paso 1: %', step_name;
        PERFORM prepare_merge_environment();
        triggers_disabled := TRUE; -- Marcar que los triggers fueron desactivados

        -- Paso 2: Procesamiento de entidades
        step_name := 'process_dirty_entities';
        RAISE NOTICE 'Ejecutando paso 2: %', step_name;
        PERFORM process_dirty_entities();

        -- Paso 3: Procesamiento de relaciones
        step_name := 'process_dirty_relations';
        RAISE NOTICE 'Ejecutando paso 3: %', step_name;
        PERFORM process_dirty_relations();

        -- Paso 4: Restablecimiento (Reactiva Triggers y Reindexa)
        step_name := 'restore_environment';
        RAISE NOTICE 'Ejecutando paso 4: %', step_name;
        PERFORM restore_environment();
        triggers_disabled := FALSE; -- Marcar que los triggers fueron reactivados

    EXCEPTION WHEN OTHERS THEN
        -- Capturar detalles del error
        GET STACKED DIAGNOSTICS
            error_message = MESSAGE_TEXT,
            error_detail = PG_EXCEPTION_DETAIL,
            error_hint = PG_EXCEPTION_HINT,
            error_context = PG_EXCEPTION_CONTEXT;

        error_occurred := TRUE;

        -- Registrar el error
        RAISE WARNING 'ERROR en paso %:', step_name;
        RAISE WARNING 'Mensaje: %', error_message;
        RAISE WARNING 'Detalle: %', error_detail;
        RAISE WARNING 'Sugerencia: %', error_hint;
        RAISE WARNING 'Contexto: %', error_context;

        -- Intentar restaurar estado (reactivar triggers si estaban desactivados) y limpiar
        RAISE NOTICE 'Intentando restaurar estado y limpiar después del error...';
        IF triggers_disabled THEN
            RAISE NOTICE 'Intentando reactivar triggers USER...';
            -- Si alguna de estas falla, la función fallará aquí.
            ALTER TABLE public.entity_fieldoccr ENABLE TRIGGER USER;
            ALTER TABLE public.relation ENABLE TRIGGER USER;
            ALTER TABLE public.relation_fieldoccr ENABLE TRIGGER USER;
            RAISE NOTICE 'Triggers reactivados.';
        END IF;

        RAISE NOTICE 'Intentando limpiar tablas temporales...';
        DROP TABLE IF EXISTS aux_entity_map;
        DROP TABLE IF EXISTS tmp_new_relations;
        DROP TABLE IF EXISTS tmp_entity_fieldoccrs;
        RAISE NOTICE 'Tablas temporales eliminadas (si existían).';

        -- Re-lanzar el error original para que la función falle y la transacción haga rollback (si aplica)
        RAISE EXCEPTION 'Proceso de merge fallido en paso %. Error: %', step_name, error_message;
    END;

    -- Si llegamos aquí, todo ha ido bien
    -- Limpiar tablas temporales en el camino exitoso
    RAISE NOTICE 'Limpiando tablas temporales al finalizar exitosamente...';
    DROP TABLE IF EXISTS aux_entity_map;
    DROP TABLE IF EXISTS tmp_new_relations;
    DROP TABLE IF EXISTS tmp_entity_fieldoccrs;
    RAISE NOTICE 'Tablas temporales eliminadas.';

    end_time := clock_timestamp();
    total_duration := end_time - start_time;

    RAISE NOTICE '=== PROCESO COMPLETO FINALIZADO EXITOSAMENTE ===';
    RAISE NOTICE 'Tiempo de inicio: %', start_time;
    RAISE NOTICE 'Tiempo de finalización: %', end_time;
    RAISE NOTICE 'Duración total: % segundos', EXTRACT(EPOCH FROM total_duration);

    RETURN;
END;
$$ LANGUAGE plpgsql;

-- Para ejecutar todo el proceso con control de errores:
-- SELECT execute_complete_merge_process();

-- O para ejecutar pasos individuales (¡CUIDADO! deja triggers desactivados hasta restore):
-- SELECT prepare_merge_environment();
-- SELECT process_dirty_entities();
-- SELECT process_dirty_relations();
-- SELECT restore_environment();


