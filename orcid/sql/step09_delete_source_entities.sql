-- Configurar las restricciones de integridad para permitir borrado en cascada
-- Se eliminan y recrean todas las restricciones relevantes para asegurar ON DELETE CASCADE.

-- 1. source_entity_semantic_identifier (entity_id -> source_entity)
ALTER TABLE source_entity_semantic_identifier DROP CONSTRAINT IF EXISTS fkequg2xow14h1xdkde3c2q92o0;
ALTER TABLE source_entity_semantic_identifier ADD CONSTRAINT fkequg2xow14h1xdkde3c2q92o0
    FOREIGN KEY (entity_id) REFERENCES source_entity(uuid) ON DELETE CASCADE;

-- 2. source_entity_fieldoccr (entity_id -> source_entity)
ALTER TABLE source_entity_fieldoccr DROP CONSTRAINT IF EXISTS fk2f3wc4b3huh74134hloikiou7;
ALTER TABLE source_entity_fieldoccr ADD CONSTRAINT fk2f3wc4b3huh74134hloikiou7
    FOREIGN KEY (entity_id) REFERENCES source_entity(uuid) ON DELETE CASCADE;

-- 3. source_relation (from_entity_id -> source_entity)
ALTER TABLE source_relation DROP CONSTRAINT IF EXISTS fkpiife6ava2qdk9y42tr4u5bci; -- Nombre alternativo del DDL/Script anterior
ALTER TABLE source_relation DROP CONSTRAINT IF EXISTS fka85ljpk6ps09u8nya2pvpfgvk; -- Nombre del DDL/Error
ALTER TABLE source_relation ADD CONSTRAINT fka85ljpk6ps09u8nya2pvpfgvk -- Nombre de restricción preferido
    FOREIGN KEY (from_entity_id) REFERENCES source_entity(uuid) ON DELETE CASCADE;

-- 4. source_relation (to_entity_id -> source_entity)
ALTER TABLE source_relation DROP CONSTRAINT IF EXISTS fk2tug80it3it1d7315h2x04fig; -- Nombre alternativo del DDL
ALTER TABLE source_relation DROP CONSTRAINT IF EXISTS fkirpb50vicfsbg28olx4snn39s; -- Nombre del DDL/Script
ALTER TABLE source_relation ADD CONSTRAINT fkirpb50vicfsbg28olx4snn39s -- Nombre de restricción preferido
    FOREIGN KEY (to_entity_id) REFERENCES source_entity(uuid) ON DELETE CASCADE;

-- 5. source_relation_fieldoccr (from_entity_id -> source_entity)
ALTER TABLE source_relation_fieldoccr DROP CONSTRAINT IF EXISTS source_relation_fieldoccr_source_entityfrom_uuid_fk;
ALTER TABLE source_relation_fieldoccr ADD CONSTRAINT source_relation_fieldoccr_source_entityfrom_uuid_fk
    FOREIGN KEY (from_entity_id) REFERENCES source_entity(uuid) ON DELETE CASCADE;

-- 6. source_relation_fieldoccr (to_entity_id -> source_entity)
ALTER TABLE source_relation_fieldoccr DROP CONSTRAINT IF EXISTS source_relation_fieldoccr_source_entityto_uuid_fk;
ALTER TABLE source_relation_fieldoccr ADD CONSTRAINT source_relation_fieldoccr_source_entityto_uuid_fk
    FOREIGN KEY (to_entity_id) REFERENCES source_entity(uuid) ON DELETE CASCADE;

-- Borrar las referencias de source_entity a final_entity_id cuando deleted = TRUE
UPDATE source_entity
SET final_entity_id = NULL
WHERE deleted = TRUE;

-- Eliminar las source_entities marcadas como deleted=true
DELETE FROM source_entity
WHERE deleted = true;