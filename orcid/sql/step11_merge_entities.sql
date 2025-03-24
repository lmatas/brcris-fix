SET client_min_messages TO NOTICE;
SELECT merge_all_dirty_data();

-- PASO 11 - FINALMENTE HACER MERGE DE LOS CAMPOS DE LAS ENTIDADES AFECTADAS Y QUE FUERON MARCADAS COMO DIRTY

-- Función principal que coordina la ejecución secuencial de los dos procesos
CREATE OR REPLACE FUNCTION merge_all_dirty_data()
RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration INTERVAL;
BEGIN
    start_time := clock_timestamp();
    RAISE NOTICE 'Iniciando proceso completo de merge de datos dirty: %', start_time;
    
    -- Limpiar tablas temporales que pudieran haber quedado de ejecuciones previas
    DROP TABLE IF EXISTS tmp_dirty_entities;
    DROP TABLE IF EXISTS tmp_final_entities;
    DROP TABLE IF EXISTS tmp_entity_fieldoccrs;
    DROP TABLE IF EXISTS tmp_new_relations;
    DROP TABLE IF EXISTS tmp_relation_fieldoccrs;
    
    -- Preparación inicial (aplicable a ambos procesos)
    RAISE NOTICE 'Preparando entorno para procesos de merge...';
    
    -- Eliminar temporalmente las constraints para mejorar el rendimiento
    RAISE NOTICE 'Eliminando constraints temporalmente...';
    -- Solo si las constraints existen
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

    -- Configuración de memoria para operaciones masivas
    RAISE NOTICE 'Configurando parámetros de memoria...';
    SET work_mem = '1GB';
    SET maintenance_work_mem = '2GB';
    SET temp_buffers = '1GB';
    SET random_page_cost = 1.1;

    -- Paso 1: Ejecutar merge de entidades
    PERFORM merge_dirty_entities();
    
    -- Paso 2: Ejecutar merge de relaciones
    PERFORM merge_dirty_relations();
    
    -- Asegurar que todas las tablas temporales han sido eliminadas
    DROP TABLE IF EXISTS tmp_dirty_entities;
    DROP TABLE IF EXISTS tmp_final_entities;
    DROP TABLE IF EXISTS tmp_entity_fieldoccrs;
    DROP TABLE IF EXISTS tmp_new_relations;
    DROP TABLE IF EXISTS tmp_relation_fieldoccrs;
    
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
    
    -- Calcular duración
    end_time := clock_timestamp();
    duration := end_time - start_time;
    
    RAISE NOTICE 'Proceso completo finalizado exitosamente';
    RAISE NOTICE 'Tiempo de inicio: %', start_time;
    RAISE NOTICE 'Tiempo de finalización: %', end_time;
    RAISE NOTICE 'Duración total: % segundos', EXTRACT(EPOCH FROM duration);
END;
$$ LANGUAGE plpgsql;

-- Función para procesar solo las entidades
CREATE OR REPLACE FUNCTION merge_dirty_entities()
RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration INTERVAL;
BEGIN
    start_time := clock_timestamp();
    RAISE NOTICE 'Iniciando proceso de merge de entidades dirty: %', start_time;

    -- Creación de índices específicos para entidades
    DROP INDEX IF EXISTS idx_entity_dirty;
    DROP INDEX IF EXISTS idx_source_entity_deleted;
    DROP INDEX IF EXISTS idx_source_entity_final_id;
    CREATE INDEX idx_entity_dirty ON entity(dirty) WHERE dirty = TRUE;
    CREATE INDEX idx_source_entity_deleted ON source_entity(deleted) WHERE deleted = FALSE;
    CREATE INDEX idx_source_entity_final_id ON source_entity(final_entity_id);

    -- Preparar datos de dirty entities en una tabla temporal
    RAISE NOTICE 'Creando tabla temporal de entidades dirty...';
    DROP TABLE IF EXISTS tmp_dirty_entities;
    CREATE TEMP TABLE tmp_dirty_entities AS 
    SELECT uuid FROM entity WHERE dirty = TRUE;
    CREATE INDEX ON tmp_dirty_entities(uuid);

    -- Preparar datos de entidades finales en una tabla temporal
    RAISE NOTICE 'Creando tabla temporal de entidades finales...';
    DROP TABLE IF EXISTS tmp_final_entities;
    CREATE TEMP TABLE tmp_final_entities AS
    SELECT se.final_entity_id, se.uuid AS source_entity_id
    FROM source_entity se 
    WHERE se.deleted = FALSE
      AND se.final_entity_id IN (SELECT uuid FROM tmp_dirty_entities);
    CREATE INDEX ON tmp_final_entities(final_entity_id);
    CREATE INDEX ON tmp_final_entities(source_entity_id);

    -- Crear tabla temporal para los fieldoccrs a insertar
    RAISE NOTICE 'Creando tabla temporal para fieldoccrs...';
    DROP TABLE IF EXISTS tmp_entity_fieldoccrs;
    CREATE TEMP TABLE tmp_entity_fieldoccrs AS
    SELECT DISTINCT fe.final_entity_id AS entity_id, sef.fieldoccr_id
    FROM tmp_final_entities fe
    JOIN source_entity_fieldoccr sef ON sef.entity_id = fe.source_entity_id;
    CREATE INDEX ON tmp_entity_fieldoccrs(entity_id);

    -- Ya no necesitamos tmp_final_entities, la liberamos
    DROP TABLE IF EXISTS tmp_final_entities;
    RAISE NOTICE 'Tabla tmp_final_entities liberada';

    -- Eliminar fieldoccrs existentes de manera eficiente
    RAISE NOTICE 'Eliminando fieldoccrs existentes...';
    DELETE FROM entity_fieldoccr
    WHERE entity_id IN (SELECT uuid FROM tmp_dirty_entities);

    -- Insertar nuevos fieldoccrs en un solo paso
    RAISE NOTICE 'Insertando nuevos fieldoccrs...';
    INSERT INTO entity_fieldoccr (entity_id, fieldoccr_id)
    SELECT entity_id, fieldoccr_id FROM tmp_entity_fieldoccrs;

    -- Ya no necesitamos tmp_entity_fieldoccrs, la liberamos
    DROP TABLE IF EXISTS tmp_entity_fieldoccrs;
    RAISE NOTICE 'Tabla tmp_entity_fieldoccrs liberada';

    -- Actualización de entidades en una sola consulta
    RAISE NOTICE 'Actualizando estado dirty de entidades...';
    UPDATE entity 
    SET dirty = FALSE
    WHERE dirty = TRUE;

    -- Mantenemos tmp_dirty_entities para el proceso de relaciones
    -- Se liberará en merge_dirty_relations() después de usarla

    -- Calcular duración
    end_time := clock_timestamp();
    duration := end_time - start_time;
    
    RAISE NOTICE 'Proceso de entidades completado exitosamente';
    RAISE NOTICE 'Duración de merge de entidades: % segundos', EXTRACT(EPOCH FROM duration);
END;
$$ LANGUAGE plpgsql;

-- Función para procesar solo las relaciones
CREATE OR REPLACE FUNCTION merge_dirty_relations()
RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration INTERVAL;
BEGIN
    start_time := clock_timestamp();
    RAISE NOTICE 'Iniciando proceso de merge de relaciones: %', start_time;

    -- Verificamos si ya existe la tabla de entidades dirty
    DROP TABLE IF EXISTS tmp_dirty_entities_exists;
    CREATE TEMP TABLE tmp_dirty_entities_exists AS
    SELECT EXISTS (
        SELECT 1 FROM pg_tables 
        WHERE schemaname = 'pg_temp' 
        AND tablename = 'tmp_dirty_entities'
    ) AS exists;
    
    -- Si no existe tmp_dirty_entities, la creamos
    DO $$
    DECLARE
        exists_flag BOOLEAN;
    BEGIN
        SELECT exists INTO exists_flag FROM tmp_dirty_entities_exists;
        IF NOT exists_flag THEN
            RAISE NOTICE 'Creando tabla temporal de entidades dirty para relaciones...';
            CREATE TEMP TABLE tmp_dirty_entities AS 
            SELECT uuid FROM entity WHERE dirty = TRUE;
            CREATE INDEX ON tmp_dirty_entities(uuid);
        END IF;
    END $$;
    
    DROP TABLE tmp_dirty_entities_exists;
    
    -- Crear tabla temporal para relaciones nuevas
    RAISE NOTICE 'Creando tabla temporal para nuevas relaciones...';
    DROP TABLE IF EXISTS tmp_new_relations;
    CREATE TEMP TABLE tmp_new_relations AS
    SELECT DISTINCT sr.relation_type_id, e1.uuid AS from_entity_id, e2.uuid AS to_entity_id
    FROM source_relation sr
    JOIN source_entity se1 ON sr.from_entity_id = se1.uuid AND se1.deleted = FALSE
    JOIN source_entity se2 ON sr.to_entity_id = se2.uuid AND se2.deleted = FALSE
    JOIN entity e1 ON se1.final_entity_id = e1.uuid
    JOIN entity e2 ON se2.final_entity_id = e2.uuid
    WHERE (e1.uuid IN (SELECT uuid FROM tmp_dirty_entities) OR 
           e2.uuid IN (SELECT uuid FROM tmp_dirty_entities))
      AND NOT EXISTS (
        SELECT 1 FROM relation r
        WHERE r.relation_type_id = sr.relation_type_id
          AND r.from_entity_id = e1.uuid
          AND r.to_entity_id = e2.uuid
      );

    -- Ya no necesitamos tmp_dirty_entities, la liberamos
    DROP TABLE IF EXISTS tmp_dirty_entities;
    RAISE NOTICE 'Tabla tmp_dirty_entities liberada';

    -- Insertar nuevas relaciones
    RAISE NOTICE 'Insertando nuevas relaciones...';
    INSERT INTO relation (relation_type_id, from_entity_id, to_entity_id, dirty)
    SELECT relation_type_id, from_entity_id, to_entity_id, TRUE
    FROM tmp_new_relations;
    
    -- Ya no necesitamos tmp_new_relations, la liberamos
    DROP TABLE IF EXISTS tmp_new_relations;
    RAISE NOTICE 'Tabla tmp_new_relations liberada';

    -- Eliminar relation_fieldoccr para relaciones dirty
    RAISE NOTICE 'Eliminando relation_fieldoccr para relaciones dirty...';
    DELETE FROM relation_fieldoccr
    USING relation
    WHERE relation.dirty = TRUE 
      AND relation_fieldoccr.relation_type_id = relation.relation_type_id
      AND relation_fieldoccr.from_entity_id = relation.from_entity_id
      AND relation_fieldoccr.to_entity_id = relation.to_entity_id;

    -- Preparar datos en tabla temporal para campos de relaciones
    RAISE NOTICE 'Preparando tabla temporal para campos de relaciones...';
    DROP TABLE IF EXISTS tmp_relation_fieldoccrs;
    CREATE TEMP TABLE tmp_relation_fieldoccrs AS
    SELECT DISTINCT r.from_entity_id, r.relation_type_id, r.to_entity_id, sro.fieldoccr_id
    FROM relation r
    JOIN source_entity se1 ON se1.final_entity_id = r.from_entity_id
    JOIN source_entity se2 ON se2.final_entity_id = r.to_entity_id
    JOIN source_relation_fieldoccr sro ON sro.from_entity_id = se1.uuid
                                       AND sro.to_entity_id = se2.uuid
                                       AND sro.relation_type_id = r.relation_type_id
    WHERE r.dirty = TRUE;

    -- Insertar campos de relaciones
    RAISE NOTICE 'Insertando campos de relaciones...';
    INSERT INTO relation_fieldoccr (from_entity_id, relation_type_id, to_entity_id, fieldoccr_id)
    SELECT from_entity_id, relation_type_id, to_entity_id, fieldoccr_id
    FROM tmp_relation_fieldoccrs;
    
    -- Ya no necesitamos tmp_relation_fieldoccrs, la liberamos
    DROP TABLE IF EXISTS tmp_relation_fieldoccrs;
    RAISE NOTICE 'Tabla tmp_relation_fieldoccrs liberada';

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

-- Para llamar a las funciones individualmente:
-- SELECT merge_dirty_entities();
-- SELECT merge_dirty_relations();
-- O para ejecutar todo el proceso:
-- SELECT merge_all_dirty_data();


