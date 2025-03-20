-- PASO 11 - FINALMENTE HACER MERGE DE LOS CAMPOS DE LAS ENTIDADES AFECTADAS Y QUE FUERON MARCADAS COMO DIRTY

-- Drop indices if they exist
DROP INDEX IF EXISTS idx_entity_dirty;
DROP INDEX IF EXISTS idx_source_entity_deleted;
DROP INDEX IF EXISTS idx_source_entity_final_id;

-- Create indices to improve performance
CREATE INDEX idx_entity_dirty ON entity(dirty) WHERE dirty = TRUE;
CREATE INDEX idx_source_entity_deleted ON source_entity(deleted) WHERE deleted = FALSE;
CREATE INDEX idx_source_entity_final_id ON source_entity(final_entity_id);

-- Delete occrs from dirty entities - Optimizada usando JOIN explícito
DELETE FROM entity_fieldoccr
USING entity
WHERE entity_fieldoccr.entity_id = entity.uuid 
  AND entity.dirty = true;

-- Insert occrs from related (non deleted) source entities into entities - Optimizada usando JOIN explícito
INSERT INTO entity_fieldoccr
SELECT DISTINCT e.uuid, sef.fieldoccr_id
FROM entity e
INNER JOIN source_entity se ON e.uuid = se.final_entity_id
INNER JOIN source_entity_fieldoccr sef ON sef.entity_id = se.uuid
WHERE e.dirty = TRUE 
  AND se.deleted = FALSE;

-- Update relations usando JOIN explícito y optimizando la subquery con NOT EXISTS
INSERT INTO relation (relation_type_id, from_entity_id, to_entity_id, dirty)
SELECT DISTINCT sr.relation_type_id, e1.uuid, e2.uuid, TRUE 
FROM source_relation sr
INNER JOIN source_entity se1 ON sr.from_entity_id = se1.uuid
INNER JOIN source_entity se2 ON sr.to_entity_id = se2.uuid
INNER JOIN entity e1 ON se1.final_entity_id = e1.uuid
INNER JOIN entity e2 ON se2.final_entity_id = e2.uuid
WHERE (e1.dirty = TRUE OR e2.dirty = TRUE) 
  AND se1.deleted = FALSE 
  AND se2.deleted = FALSE 
  AND NOT EXISTS (
    SELECT 1 FROM relation x 
    WHERE x.relation_type_id = sr.relation_type_id 
      AND x.from_entity_id = e1.uuid 
      AND x.to_entity_id = e2.uuid
  );

-- Delete dirty relations field occrs - Optimizada con JOIN
DELETE FROM relation_fieldoccr
USING relation
WHERE relation.dirty = TRUE 
  AND relation.relation_type_id = relation_fieldoccr.relation_type_id 
  AND relation.from_entity_id = relation_fieldoccr.from_entity_id 
  AND relation.to_entity_id = relation_fieldoccr.to_entity_id;

-- Insert field occrs from dirty relations - Optimizada usando JOINs explícitos
INSERT INTO relation_fieldoccr (from_entity_id, relation_type_id, to_entity_id, fieldoccr_id)
SELECT DISTINCT r.from_entity_id, r.relation_type_id, r.to_entity_id, sro.fieldoccr_id
FROM relation r
INNER JOIN source_entity se1 ON r.from_entity_id = se1.final_entity_id
INNER JOIN source_entity se2 ON r.to_entity_id = se2.final_entity_id
INNER JOIN source_relation_fieldoccr sro ON sro.from_entity_id = se1.uuid 
                                        AND sro.to_entity_id = se2.uuid 
                                        AND sro.relation_type_id = r.relation_type_id
WHERE r.dirty = TRUE;

-- Actualización de entidades en una sola consulta
UPDATE entity 
SET dirty = FALSE
WHERE dirty = TRUE;

-- Actualización de relaciones en una sola consulta
UPDATE relation 
SET dirty = FALSE
WHERE dirty = TRUE;


