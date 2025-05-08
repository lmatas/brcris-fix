-- 2. PROCESO DE ENTIDADES 
CREATE OR REPLACE FUNCTION process_dirty_entities()
RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration INTERVAL;
BEGIN
    -- Registrar inicio del proceso
    start_time := clock_timestamp();
    RAISE NOTICE 'Iniciando proceso de merge de entidades dirty (con triggers desactivados): %', start_time;

    -- Preparación para el merge
    RAISE NOTICE 'Iniciando proceso de preparación para merge: %', start_time;

    -- Crear tabla auxiliar unificada con entidades dirty y sus source entities
    RAISE NOTICE 'Creando tabla auxiliar unificada para entidades dirty y sus source entities...';

    -- Eliminar tabla auxiliar si ya existe
    DROP TABLE IF EXISTS aux_entity_map;
    CREATE TABLE aux_entity_map (
        entity_id UUID NOT NULL,
        source_id UUID
    );

    -- Insertar entidades dirty con sus source_entities
    INSERT INTO aux_entity_map (entity_id, source_id)
    SELECT e.uuid, se.uuid
    FROM entity e
    JOIN source_entity se ON se.final_entity_id = e.uuid
    WHERE e.dirty = TRUE;

    -- Crear índices en la tabla auxiliar
    CREATE INDEX ON aux_entity_map(entity_id);
    CREATE INDEX ON aux_entity_map(source_id);

    -- Crear tabla temporal para los fieldoccrs a insertar
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

    -- Insertar nuevos fieldoccrs
    RAISE NOTICE 'Insertando nuevos fieldoccrs...';
    INSERT INTO entity_fieldoccr (entity_id, fieldoccr_id)
    SELECT entity_id, fieldoccr_id FROM tmp_entity_fieldoccrs;

    -- Actualizar estado dirty de las entidades
    RAISE NOTICE 'Actualizando estado dirty de entidades...';
    UPDATE entity
    SET dirty = FALSE
    WHERE uuid IN (SELECT DISTINCT entity_id FROM aux_entity_map);

    -- Proceso de merge de relaciones
    RAISE NOTICE 'Iniciando proceso de merge de relaciones (con triggers desactivados): %', start_time;

    -- Crear tabla temporal para nuevas relaciones
    RAISE NOTICE 'Creando tabla temporal para nuevas relaciones...';
    DROP TABLE IF EXISTS tmp_new_relations;
    CREATE TABLE tmp_new_relations (
        from_entity_id UUID,
        relation_type_id UUID,
        to_entity_id UUID,
        source_from_entity_id UUID,
        source_to_entity_id UUID,
        dirty BOOLEAN
    );

    -- Añadir restricción de unicidad
    ALTER TABLE tmp_new_relations ADD CONSTRAINT unique_tmp_new_relations UNIQUE (from_entity_id, relation_type_id, to_entity_id);

    -- Insertar nuevas relaciones en la tabla temporal
    INSERT INTO tmp_new_relations (from_entity_id, relation_type_id, to_entity_id, source_from_entity_id, source_to_entity_id, dirty)
    SELECT 
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
    AND se2.final_entity_id IS NOT NULL
    ON CONFLICT (from_entity_id, relation_type_id, to_entity_id) DO NOTHING;

    -- Crear índices para optimizar consultas posteriores
    CREATE INDEX ON tmp_new_relations(relation_type_id, from_entity_id, to_entity_id);
    CREATE INDEX ON tmp_new_relations(source_from_entity_id);
    CREATE INDEX ON tmp_new_relations(source_to_entity_id);

    -- Eliminar relaciones antiguas que involucren a las entidades dirty
    RAISE NOTICE 'Eliminando relaciones antiguas de entidades dirty...';
    DELETE FROM relation r
    WHERE EXISTS (
        SELECT 1 FROM aux_entity_map aem
        WHERE aem.entity_id = r.from_entity_id OR aem.entity_id = r.to_entity_id
    );

    -- Crear índice único para relaciones si no existe
    CREATE UNIQUE INDEX CONCURRENTLY idx_rel_unique ON relation (relation_type_id, from_entity_id, to_entity_id);

    -- Insertar nuevas relaciones
    RAISE NOTICE 'Insertando nuevas relaciones...';
    INSERT INTO relation (relation_type_id, from_entity_id, to_entity_id, dirty)
    SELECT tnr.relation_type_id,
        tnr.from_entity_id,
        tnr.to_entity_id,
        true
    FROM tmp_new_relations tnr
    ON CONFLICT (relation_type_id, from_entity_id, to_entity_id) DO NOTHING;

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

    -- Insertar campos de relaciones para relaciones dirty
    RAISE NOTICE 'Insertando campos de relaciones para relaciones dirty...';
    INSERT INTO relation_fieldoccr (from_entity_id, relation_type_id, to_entity_id, fieldoccr_id)
    SELECT
        tnr.from_entity_id,
        tnr.relation_type_id,
        tnr.to_entity_id,
        sro.fieldoccr_id
    FROM tmp_new_relations tnr
    JOIN source_relation_fieldoccr sro ON sro.relation_type_id = tnr.relation_type_id
                                    AND sro.from_entity_id = tnr.source_from_entity_id
                                    AND sro.to_entity_id = tnr.source_to_entity_id
    ON CONFLICT (from_entity_id, relation_type_id, to_entity_id, fieldoccr_id) DO NOTHING;

    RAISE NOTICE 'Inserción de campos de relaciones completada';

    -- Actualizar estado dirty de relaciones
    RAISE NOTICE 'Actualizando estado dirty de relaciones...';
    UPDATE relation
    SET dirty = FALSE
    WHERE dirty = TRUE;

    -- Calcular duración del proceso
    end_time := clock_timestamp();
    duration := end_time - start_time;

    -- Finalizar proceso
    RAISE NOTICE 'Proceso de entidades completado exitosamente';
    RAISE NOTICE 'Duración de merge de entidades: % segundos', EXTRACT(EPOCH FROM duration);
END;
$$ LANGUAGE plpgsql;
