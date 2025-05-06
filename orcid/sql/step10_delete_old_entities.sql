-- PASO 10 - BORRAR TODAS LA ENTIDADES CON SEMANTIC IDS ERROREOS QUE YA TENIAN UN ENTIDAD EXISTENTE CON EL SEMANTIC ID CORREGIDO
 
-- Asegurar que las restricciones tengan ON DELETE CASCADE para permitir el borrado de entidades.
-- Se eliminan y recrean todas las restricciones relevantes para garantizar el estado deseado.

-- 1. entity_semantic_identifier (entity_id -> entity)
ALTER TABLE entity_semantic_identifier DROP CONSTRAINT IF EXISTS fkinjr1aqio6tuon2ypi6ixd4ao;
ALTER TABLE entity_semantic_identifier ADD CONSTRAINT fkinjr1aqio6tuon2ypi6ixd4ao 
    FOREIGN KEY (entity_id) REFERENCES entity(uuid) ON DELETE CASCADE;

-- 2. entity_fieldoccr (entity_id -> entity)
ALTER TABLE entity_fieldoccr DROP CONSTRAINT IF EXISTS fkg85y6bnncn3q9y762wvrwj08u;
ALTER TABLE entity_fieldoccr ADD CONSTRAINT fkg85y6bnncn3q9y762wvrwj08u 
    FOREIGN KEY (entity_id) REFERENCES entity(uuid) ON DELETE CASCADE;

-- 3. relation (from_entity_id -> entity)
ALTER TABLE relation DROP CONSTRAINT IF EXISTS fk9kavjxgi0tpvju15iab7petiw;
ALTER TABLE relation ADD CONSTRAINT fk9kavjxgi0tpvju15iab7petiw 
    FOREIGN KEY (from_entity_id) REFERENCES entity(uuid) ON DELETE CASCADE;

-- 4. relation (to_entity_id -> entity)
ALTER TABLE relation DROP CONSTRAINT IF EXISTS fk9wvqikvahl1a0x1xkcfdw42n;
ALTER TABLE relation ADD CONSTRAINT fk9wvqikvahl1a0x1xkcfdw42n 
    FOREIGN KEY (to_entity_id) REFERENCES entity(uuid) ON DELETE CASCADE;

-- 5. relation_fieldoccr (from_entity_id -> entity)
ALTER TABLE relation_fieldoccr DROP CONSTRAINT IF EXISTS relation_fieldoccr_entityfrom_uuid_fk;
ALTER TABLE relation_fieldoccr ADD CONSTRAINT relation_fieldoccr_entityfrom_uuid_fk 
    FOREIGN KEY (from_entity_id) REFERENCES entity(uuid) ON DELETE CASCADE;

-- 6. relation_fieldoccr (to_entity_id -> entity)
ALTER TABLE relation_fieldoccr DROP CONSTRAINT IF EXISTS relation_fieldoccr_entityto_uuid_fk;
ALTER TABLE relation_fieldoccr ADD CONSTRAINT relation_fieldoccr_entityto_uuid_fk 
    FOREIGN KEY (to_entity_id) REFERENCES entity(uuid) ON DELETE CASCADE;
-- FIN DE LOS ALTER TABLE


-- Borrar las entidades que tenian el ORCID erróneo y ya existian entidades con el ORCID correcto
DELETE FROM public.entity 
WHERE uuid IN (
    SELECT woeb.final_entity_id
    FROM public.wrong_orcid_entity_backup woeb
    WHERE woeb.new_final_entity_id IS NOT NULL
);
