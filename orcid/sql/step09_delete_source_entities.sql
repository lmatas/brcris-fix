-- Configurar las restricciones de integridad para permitir borrado en cascada

-- 1. source_entity_semantic_identifier
ALTER TABLE source_entity_semantic_identifier DROP CONSTRAINT IF EXISTS fkequg2xow14h1xdkde3c2q92o0;
ALTER TABLE source_entity_semantic_identifier ADD CONSTRAINT fkequg2xow14h1xdkde3c2q92o0 
    FOREIGN KEY (entity_id) REFERENCES source_entity(uuid) ON DELETE CASCADE;

-- 2. source_entity_fieldoccr
-- CORREGIR EL NOMBRE DE LA RESTRICCIÓN AL INDICADO EN EL ERROR
ALTER TABLE source_entity_fieldoccr DROP CONSTRAINT IF EXISTS fk2f3wc4b3huh74134hloikiou7;
ALTER TABLE source_entity_fieldoccr ADD CONSTRAINT fk2f3wc4b3huh74134hloikiou7 
    FOREIGN KEY (entity_id) REFERENCES source_entity(uuid) ON DELETE CASCADE;

-- 3. source_relation (from_entity_id)
ALTER TABLE source_relation DROP CONSTRAINT IF EXISTS fkpiife6ava2qdk9y42tr4u5bci;
ALTER TABLE source_relation ADD CONSTRAINT fkpiife6ava2qdk9y42tr4u5bci 
    FOREIGN KEY (from_entity_id) REFERENCES source_entity(uuid) ON DELETE CASCADE;

-- 4. source_relation (to_entity_id)
ALTER TABLE source_relation DROP CONSTRAINT IF EXISTS fkirpb50vicfsbg28olx4snn39s;
ALTER TABLE source_relation ADD CONSTRAINT fkirpb50vicfsbg28olx4snn39s 
    FOREIGN KEY (to_entity_id) REFERENCES source_entity(uuid) ON DELETE CASCADE;

-- 5. source_relation_fieldoccr (from_entity_id)
ALTER TABLE source_relation_fieldoccr DROP CONSTRAINT IF EXISTS source_relation_fieldoccr_source_entityfrom_uuid_fk;
ALTER TABLE source_relation_fieldoccr ADD CONSTRAINT source_relation_fieldoccr_source_entityfrom_uuid_fk 
    FOREIGN KEY (from_entity_id) REFERENCES source_entity(uuid) ON DELETE CASCADE;

-- 6. source_relation_fieldoccr (to_entity_id)
ALTER TABLE source_relation_fieldoccr DROP CONSTRAINT IF EXISTS source_relation_fieldoccr_source_entityto_uuid_fk;
ALTER TABLE source_relation_fieldoccr ADD CONSTRAINT source_relation_fieldoccr_source_entityto_uuid_fk 
    FOREIGN KEY (to_entity_id) REFERENCES source_entity(uuid) ON DELETE CASCADE;

-- Eliminar las source_entities marcadas como deleted=true
DELETE FROM source_entity
WHERE deleted = true;