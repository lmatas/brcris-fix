-- =====================================================
-- PROCEDIMIENTO ALMACENADO PARA CORRECCIÓN DE ENTIDADES
-- =====================================================

CREATE OR REPLACE PROCEDURE public.fix_wrong_orcid_entities()
LANGUAGE plpgsql
AS $$
DECLARE 
    r RECORD;
    new_entity_id UUID;
    total_updates INT := 0;
    new_entities INT := 0;
    existing_entities INT := 0;
BEGIN
    -- 1. Identificar y procesar entidades existentes que ya tengan el nuevo ID semántico
    INSERT INTO wrong_orcid_entity_correction (old_entity_id, new_entity_id, old_semantic_id, new_semantic_id, entity_created)
    SELECT 
        old_entity.uuid AS old_entity_id,
        existing_entity.entity_id AS new_entity_id,
        w.id AS old_semantic_id,
        w.new_id AS new_semantic_id,
        FALSE AS entity_created
    FROM source_entity_semantic_identifier old_sesi
    JOIN wrong_orcid_semantic_identifier w ON old_sesi.semantic_id = w.id
    JOIN entity old_entity ON old_sesi.entity_id = old_entity.uuid
    JOIN entity_semantic_identifier existing_entity ON existing_entity.semantic_id = w.new_id
    WHERE w.new_id IS NOT NULL
    ON CONFLICT (old_entity_id) DO NOTHING;
    
    GET DIAGNOSTICS existing_entities = ROW_COUNT;
    RAISE NOTICE 'Entidades existentes procesadas: %', existing_entities;
    
    -- 2. Procesar casos donde no existe entidad con el ID semántico nuevo
    FOR r IN 
        SELECT DISTINCT 
            old_entity.uuid AS old_entity_id,
            w.id AS old_semantic_id,
            w.new_id AS new_semantic_id,
            old_entity.entity_type_id
        FROM source_entity_semantic_identifier old_sesi
        JOIN wrong_orcid_semantic_identifier w ON old_sesi.semantic_id = w.id
        JOIN entity old_entity ON old_sesi.entity_id = old_entity.uuid
        LEFT JOIN entity_semantic_identifier existing_entity ON existing_entity.semantic_id = w.new_id
        LEFT JOIN wrong_orcid_entity_correction wec ON old_entity.uuid = wec.old_entity_id
        WHERE w.new_id IS NOT NULL
        AND existing_entity.entity_id IS NULL
        AND wec.old_entity_id IS NULL
    LOOP
        -- Generar nuevo UUID
        new_entity_id := gen_random_uuid();
        
        -- Insertar nueva entidad
        INSERT INTO entity (uuid, entity_type_id, dirty)
        VALUES (new_entity_id, r.entity_type_id, TRUE);
        
        -- Asignar identificador semántico correcto
        INSERT INTO entity_semantic_identifier (entity_id, semantic_id)
        VALUES (new_entity_id, r.new_semantic_id);
        
        -- Registrar en tabla de corrección
        INSERT INTO wrong_orcid_entity_correction 
            (old_entity_id, new_entity_id, old_semantic_id, new_semantic_id, entity_created)
        VALUES 
            (r.old_entity_id, new_entity_id, r.old_semantic_id, r.new_semantic_id, TRUE);
            
        new_entities := new_entities + 1;
        
        -- Reportar progreso cada 100 entidades
        IF new_entities % 100 = 0 THEN
            RAISE NOTICE 'Nuevas entidades creadas: %', new_entities;
        END IF;
    END LOOP;
    
    total_updates := existing_entities + new_entities;
    RAISE NOTICE 'Proceso completado. Total de entidades procesadas: %. Existentes: %. Nuevas: %', 
                 total_updates, existing_entities, new_entities;
END $$;

-- Instrucciones para ejecutar el procedimiento
-- CALL fix_wrong_orcid_entities();
