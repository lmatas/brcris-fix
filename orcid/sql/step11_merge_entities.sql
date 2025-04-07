-- PASO 11 - PROCESOS INDEPENDIENTES PARA MERGE DE DATOS

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

    -- Eliminar temporalmente las constraints para mejorar el rendimiento
    RAISE NOTICE 'Eliminando constraints temporalmente...';
    ALTER TABLE IF EXISTS entity_fieldoccr DROP CONSTRAINT IF EXISTS fkg85y6bnncn3q9y762wvrwj08u;
    ALTER TABLE IF EXISTS entity_fieldoccr DROP CONSTRAINT IF EXISTS fkaqxlq6pqglkl32ub46do5akpl;
    ALTER TABLE IF EXISTS relation DROP CONSTRAINT IF EXISTS fk9kavjxgi0tpvju15iab7petiw;
    ALTER TABLE IF EXISTS relation DROP CONSTRAINT IF EXISTS fk9wvqikvahl1a0x1xkcfdw42n;
    ALTER TABLE IF EXISTS relation DROP CONSTRAINT IF EXISTS fkgocmghsla07rat51y3w39n9tk;
    ALTER TABLE IF EXISTS relation_fieldoccr DROP CONSTRAINT IF EXISTS relation_fieldoccr_entityfrom_uuid_fk;
    ALTER TABLE IF EXISTS relation_fieldoccr DROP CONSTRAINT IF EXISTS relation_fieldoccr_entityto_uuid_fk;
    ALTER TABLE IF EXISTS relation_fieldoccr DROP CONSTRAINT IF EXISTS relation_fieldoccr_fieldoccr_id_fk;
    ALTER TABLE IF EXISTS relation_fieldoccr DROP CONSTRAINT IF EXISTS relation_fieldoccr_relation_type_id_fk;
    

    -- Desactivar temporalmente el chequeo de restricciones
    RAISE NOTICE 'Desactivando chequeo de restricciones...';
    SET session_replication_role = 'replica';
   
    -- Creación de índices específicos
    CREATE INDEX IF NOT EXISTS idx_entity_dirty ON entity(dirty) WHERE dirty = TRUE;
    CREATE INDEX IF NOT EXISTS idx_source_entity_deleted ON source_entity(deleted) WHERE deleted = FALSE;
    CREATE INDEX IF NOT EXISTS idx_source_entity_final_id ON source_entity(final_entity_id);
    CREATE INDEX IF NOT EXISTS idx_source_relation_from_entity_id ON source_relation(from_entity_id);
    CREATE INDEX IF NOT EXISTS idx_source_relation_to_entity_id ON source_relation(to_entity_id);
    CREATE INDEX IF NOT EXISTS idx_srf_relation_entities ON source_relation_fieldoccr(relation_type_id, from_entity_id, to_entity_id);

   -- Crear tabla auxiliar unificada con entidades dirty y sus source entities
    RAISE NOTICE 'Creando tabla auxiliar unificada para entidades dirty y sus source entities...';

    -- Primero creamos la tabla
    DROP TABLE IF EXISTS aux_entity_map;
    CREATE TEMP TABLE aux_entity_map (
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
    WHERE e.dirty = TRUE
    AND se.deleted = FALSE;

    -- 2. Verificar si hay entidades dirty sin source_entities (no debería ocurrir)
    RAISE NOTICE '% entidades dirty sin source_entities (posible error)', 
        (SELECT COUNT(*) FROM entity e WHERE e.dirty = TRUE 
         AND NOT EXISTS (SELECT 1 FROM aux_entity_map am WHERE am.entity_id = e.uuid));

    -- Crear índice en source_id después de insertar
    CREATE INDEX ON aux_entity_map(source_id);
    CREATE INDEX ON aux_entity_map(entity_id);
    

    -- Actualizar estadísticas
    ANALYZE aux_entity_map;

    -- Reportar estadísticas
    RAISE NOTICE '% entidades dirty encontradas, % con source_entities asociadas', 
        (SELECT COUNT(DISTINCT entity_id) FROM aux_entity_map),
        (SELECT COUNT(*) FROM aux_entity_map WHERE source_id IS NOT NULL);

    -- Calcular duración
    end_time := clock_timestamp();
    duration := end_time - start_time;
    
    RAISE NOTICE 'Proceso de preparación completado exitosamente';
    RAISE NOTICE 'Duración: % segundos', EXTRACT(EPOCH FROM duration);
END;
$$ LANGUAGE plpgsql;

-- 2. PROCESO DE ENTIDADES
CREATE OR REPLACE FUNCTION process_dirty_entities()
RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration INTERVAL;
BEGIN
    start_time := clock_timestamp();
    RAISE NOTICE 'Iniciando proceso de merge de entidades dirty: %', start_time;

    -- Verificar que la tabla auxiliar exista
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'aux_entity_map') THEN
        RAISE EXCEPTION 'La tabla aux_entity_map no existe. Ejecute prepare_merge_environment primero.';
    END IF;

    -- Crear tabla temporal para los fieldoccrs a insertar usando directamente aux_entity_map
    RAISE NOTICE 'Creando tabla temporal para fieldoccrs...';
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
    RAISE NOTICE 'Insertando nuevos fieldoccrs...';
    INSERT INTO entity_fieldoccr (entity_id, fieldoccr_id)
    SELECT entity_id, fieldoccr_id FROM tmp_entity_fieldoccrs;

    -- Ya no necesitamos tmp_entity_fieldoccrs, la liberamos
    DROP TABLE tmp_entity_fieldoccrs;
    RAISE NOTICE 'Tabla tmp_entity_fieldoccrs liberada';

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

-- 3. PROCESO DE RELACIONES
CREATE OR REPLACE FUNCTION process_dirty_relations()
RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration INTERVAL;
BEGIN
    start_time := clock_timestamp();
    RAISE NOTICE 'Iniciando proceso de merge de relaciones: %', start_time;
    
    -- Verificar que la tabla auxiliar exista
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'aux_entity_map') THEN
        RAISE EXCEPTION 'La tabla aux_entity_map no existe. Ejecute prepare_merge_environment primero.';
    END IF;
  
    -- Crear tabla temporal para las nuevas relaciones a insertar usando directamente aux_entity_map
    RAISE NOTICE 'Creando tabla temporal para nuevas relaciones...';
    DROP TABLE IF EXISTS tmp_new_relations;
    CREATE TEMP TABLE tmp_new_relations AS
    select se1.final_entity_id as from_entity_id, sr.relation_type_id, se2.final_entity_id as to_entity_id, sr.from_entity_id as source_from_entity_id, sr.to_entity_id as source_to_entity_id, true as dirty  
    from source_relation sr, source_entity se1, source_entity se2
    where exists (select 1 from aux_entity_map aem where aem.source_id = sr.from_entity_id or aem.source_id = sr.to_entity_id )
    and sr.from_entity_id = se1.uuid and sr.to_entity_id = se2.uuid; 

    
    -- Crear índices para optimizar la consulta posterior
    CREATE INDEX ON tmp_new_relations(relation_type_id, from_entity_id, to_entity_id);
    CREATE INDEX ON tmp_new_relations(source_from_entity_id, source_to_entity_id);
    ANALYZE tmp_new_relations;
    
    -- Insertar solo las relaciones que no existan previamente
    RAISE NOTICE 'Insertando nuevas relaciones...';
    INSERT INTO relation (relation_type_id, from_entity_id, to_entity_id, dirty)
    SELECT DISTINCT tnr.relation_type_id, tnr.from_entity_id, tnr.to_entity_id, tnr.dirty
    FROM tmp_new_relations tnr
    WHERE NOT EXISTS (
        SELECT 1 FROM relation r
        WHERE r.relation_type_id = tnr.relation_type_id
          AND r.from_entity_id = tnr.from_entity_id
          AND r.to_entity_id = tnr.to_entity_id
    );
    
    -- Eliminar relation_fieldoccr para relaciones dirty
    RAISE NOTICE 'Eliminando relation_fieldoccr para relaciones dirty...';
    DELETE FROM relation_fieldoccr
    USING relation r
    WHERE r.dirty = TRUE 
      AND relation_fieldoccr.relation_type_id = r.relation_type_id
      AND relation_fieldoccr.from_entity_id = r.from_entity_id
      AND relation_fieldoccr.to_entity_id = r.to_entity_id;

    -- Insertar campos de relaciones utilizando solamente tmp_new_relations
    RAISE NOTICE 'Insertando campos de relaciones...';
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
    WHERE NOT EXISTS (
        SELECT 1 
        FROM relation_fieldoccr rfo
        WHERE rfo.from_entity_id = tnr.from_entity_id
          AND rfo.relation_type_id = tnr.relation_type_id
          AND rfo.to_entity_id = tnr.to_entity_id
          AND rfo.fieldoccr_id = sro.fieldoccr_id
    );

    RAISE NOTICE 'Inserción de campos de relaciones completada';

    -- Actualización de relaciones
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

-- 4. PROCESO DE RESTABLECIMIENTO Y LIMPIEZA
CREATE OR REPLACE FUNCTION restore_environment()
RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration INTERVAL;
BEGIN
    start_time := clock_timestamp();
    RAISE NOTICE 'Iniciando proceso de restablecimiento y limpieza: %', start_time;
    
    -- Reconstrucción de índices
    RAISE NOTICE 'Reconstruyendo índices...';
    EXECUTE 'REINDEX TABLE entity';
    EXECUTE 'REINDEX TABLE relation';
    EXECUTE 'REINDEX TABLE entity_fieldoccr';
    EXECUTE 'REINDEX TABLE relation_fieldoccr';

    -- Restaurar ambiente
    RAISE NOTICE 'Reactivando chequeo de restricciones...';
    SET session_replication_role = 'origin';

    RAISE NOTICE 'Restaurando constraints...';
    ALTER TABLE entity_fieldoccr ADD CONSTRAINT fkg85y6bnncn3q9y762wvrwj08u 
        FOREIGN KEY (entity_id) REFERENCES entity(uuid) ON DELETE CASCADE; 
    ALTER TABLE entity_fieldoccr ADD CONSTRAINT fkaqxlq6pqglkl32ub46do5akpl 
        FOREIGN KEY (fieldoccr_id) REFERENCES fieldoccr(id); 
    ALTER TABLE relation ADD CONSTRAINT fk9kavjxgi0tpvju15iab7petiw 
        FOREIGN KEY (from_entity_id) REFERENCES entity(uuid) ON DELETE CASCADE; 
    ALTER TABLE relation ADD CONSTRAINT fk9wvqikvahl1a0x1xkcfdw42n 
        FOREIGN KEY (to_entity_id) REFERENCES entity(uuid) ON DELETE CASCADE; 
    ALTER TABLE relation ADD CONSTRAINT fkgocmghsla07rat51y3w39n9tk 
        FOREIGN KEY (relation_type_id) REFERENCES relation_type(id); 
    ALTER TABLE relation_fieldoccr ADD CONSTRAINT relation_fieldoccr_entityfrom_uuid_fk 
        FOREIGN KEY (from_entity_id) REFERENCES entity(uuid) ON DELETE CASCADE; 
    ALTER TABLE relation_fieldoccr ADD CONSTRAINT relation_fieldoccr_entityto_uuid_fk 
        FOREIGN KEY (to_entity_id) REFERENCES entity(uuid) ON DELETE CASCADE; 
    ALTER TABLE relation_fieldoccr ADD CONSTRAINT relation_fieldoccr_fieldoccr_id_fk 
        FOREIGN KEY (fieldoccr_id) REFERENCES fieldoccr(id);
    ALTER TABLE relation_fieldoccr ADD CONSTRAINT relation_fieldoccr_relation_type_id_fk 
        FOREIGN KEY (relation_type_id) REFERENCES relation_type(id);
    
    -- Eliminar tablas auxiliares
    RAISE NOTICE 'Eliminando tablas auxiliares...';
    DROP TABLE IF EXISTS aux_entity_map;
    
    -- Calcular duración
    end_time := clock_timestamp();
    duration := end_time - start_time;
    
    RAISE NOTICE 'Proceso de restablecimiento completado exitosamente';
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
BEGIN
    start_time := clock_timestamp();
    RAISE NOTICE '=== INICIANDO PROCESO COMPLETO DE MERGE ===';
    RAISE NOTICE 'Tiempo de inicio: %', start_time;
    
    -- Manejo de errores con bloques anidados
    BEGIN
        -- Paso 1: Preparación y preoptimización
        step_name := 'prepare_merge_environment';
        RAISE NOTICE 'Ejecutando paso 1: %', step_name;
        PERFORM prepare_merge_environment();
        
        -- Paso 2: Procesamiento de entidades
        step_name := 'process_dirty_entities';
        RAISE NOTICE 'Ejecutando paso 2: %', step_name;
        PERFORM process_dirty_entities();
        
        -- Paso 3: Procesamiento de relaciones
        step_name := 'process_dirty_relations';
        RAISE NOTICE 'Ejecutando paso 3: %', step_name;
        PERFORM process_dirty_relations();
        
        -- Paso 4: Restablecimiento y limpieza
        step_name := 'restore_environment';
        RAISE NOTICE 'Ejecutando paso 4: %', step_name;
        PERFORM restore_environment();
        
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
        
        -- Intentar restaurar el entorno incluso después de un error
        BEGIN
            RAISE NOTICE 'Intentando restaurar el entorno después del error...';
            -- Forzar restauración del entorno para evitar dejar la base de datos en estado inconsistente
            SET session_replication_role = 'origin';
            
            -- Restaurar constraints solo si aún no se han restaurado
            IF EXISTS (
                SELECT 1 
                FROM information_schema.table_constraints 
                WHERE constraint_name = 'fkg85y6bnncn3q9y762wvrwj08u' 
                  AND table_name = 'entity_fieldoccr'
            ) THEN
                RAISE NOTICE 'Las constraints parecen estar intactas, no es necesario restaurarlas.';
            ELSE
                PERFORM restore_environment();
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Error adicional durante la restauración del entorno: %', SQLERRM;
            RAISE WARNING 'La base de datos podría estar en un estado inconsistente.';
            RAISE WARNING 'Es posible que necesites restaurar manualmente las constraints e índices.';
        END;
        
        -- Re-lanzar el error original para que la función falle
        RAISE EXCEPTION 'Proceso de merge fallido en paso %: %', step_name, error_message;
    END;
    
    -- Si llegamos aquí, todo ha ido bien
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

-- O para ejecutar pasos individuales:
-- SELECT prepare_merge_environment();
-- SELECT process_dirty_entities();
-- SELECT process_dirty_relations();
-- SELECT restore_environment();


