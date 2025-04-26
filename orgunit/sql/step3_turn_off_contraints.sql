-- Constraints en ENTITY_FIELDOCCR
ALTER TABLE entity_fieldoccr
   DROP CONSTRAINT IF EXISTS fkg85y6bnncn3q9y762wvrwj08u, -- FK a entity (entity_id)
   DROP CONSTRAINT IF EXISTS fkaqxlq6pqglkl32ub46do5akpl; -- FK a field_occurrence (fieldoccr_id)

-- Constraints en ENTITY_SEMANTIC_IDENTIFIER
ALTER TABLE entity_semantic_identifier
   DROP CONSTRAINT IF EXISTS fkinjr1aqio6tuon2ypi6ixd4ao; -- FK a entity (entity_id)

-- Constraints en RELATION
ALTER TABLE relation
   DROP CONSTRAINT IF EXISTS fk9kavjxgi0tpvju15iab7petiw, -- FK a entity (from_entity_id)
   DROP CONSTRAINT IF EXISTS fk9wvqikvahl1a0x1xkcfdw42n, -- FK a entity (to_entity_id)
   DROP CONSTRAINT IF EXISTS fkgocmghsla07rat51y3w39n9tk; -- FK a relation_type (relation_type_id)

-- Constraints en RELATION_FIELDOCCR
ALTER TABLE relation_fieldoccr
   DROP CONSTRAINT IF EXISTS relation_fieldoccr_entityfrom_uuid_fk, -- FK a entity (from_entity_id)
   DROP CONSTRAINT IF EXISTS relation_fieldoccr_entityto_uuid_fk,   -- FK a entity (to_entity_id)
   DROP CONSTRAINT IF EXISTS fkjottc07w9a00w4ta9u48br53m,          -- FK a relation (relation_id) -- Nombre original, no encontrado en DDL de ORCID
   DROP CONSTRAINT IF EXISTS relation_fieldoccr_fieldoccr_id_fk,    -- FK a field_occurrence (fieldoccr_id)
   DROP CONSTRAINT IF EXISTS relation_fieldoccr_relation_type_id_fk; -- FK a relation_type (relation_type_id)

-- Constraints en SOURCE_ENTITY
ALTER TABLE source_entity
   DROP CONSTRAINT IF EXISTS fk3obeh2naev2b3gyswvpvw433e; -- FK a entity (final_entity_id)

-- Constraints en SOURCE_ENTITY_FIELDOCCR
ALTER TABLE source_entity_fieldoccr
    -- El DDL de ORCID usa fk2f3wc4b3huh74134hloikiou7 para la FK a source_entity
    DROP CONSTRAINT IF EXISTS fk2f3wc4b3huh74134hloikiou7, -- FK a source_entity (entity_id)
    DROP CONSTRAINT IF EXISTS fk6w85u7cf1rp9mu9u83lqf1g0c; -- FK a field_occurrence (fieldoccr_id)

-- Constraints en SOURCE_ENTITY_SEMANTIC_IDENTIFIER
ALTER TABLE source_entity_semantic_identifier
   -- El DDL de ORCID usa fkequg2xow14h1xdkde3c2q92o0 para la FK a source_entity
   DROP CONSTRAINT IF EXISTS fkequg2xow14h1xdkde3c2q92o0, -- FK a source_entity (entity_id)
   DROP CONSTRAINT IF EXISTS fk9bf1gs0tx86f4eewbws4hkytp; -- FK a semantic_identifier (semantic_id)

-- Constraints en SOURCE_RELATION
ALTER TABLE source_relation
   -- El DDL de ORCID usa fkpiife6ava2qdk9y42tr4u5bci para la FK from_entity_id
   DROP CONSTRAINT IF EXISTS fkpiife6ava2qdk9y42tr4u5bci, -- FK a source_entity (from_entity_id)
   -- El DDL de ORCID usa fkirpb50vicfsbg28olx4snn39s para la FK to_entity_id
   DROP CONSTRAINT IF EXISTS fkirpb50vicfsbg28olx4snn39s, -- FK a source_entity (to_entity_id)
   DROP CONSTRAINT IF EXISTS fk8550j1n0hyug6jgpfmuqaj0e7; -- FK a relation_type (relation_type_id)

-- Constraints en SOURCE_RELATION_FIELDOCCR
ALTER TABLE source_relation_fieldoccr
    DROP CONSTRAINT IF EXISTS source_relation_fieldoccr_source_entityfrom_uuid_fk, -- FK a source_entity (from_entity_id)
    DROP CONSTRAINT IF EXISTS source_relation_fieldoccr_source_entityto_uuid_fk,   -- FK a source_entity (to_entity_id)
    DROP CONSTRAINT IF EXISTS source_relation_fieldoccr_source_relation_id_fk,     -- FK a source_relation (relation_id)
    DROP CONSTRAINT IF EXISTS source_relation_fieldoccr_fieldoccr_id_fk,         -- FK a field_occurrence (fieldoccr_id)
    DROP CONSTRAINT IF EXISTS source_relation_fieldoccr_relation_type_id_fk;    -- FK a relation_type (relation_type_id)
