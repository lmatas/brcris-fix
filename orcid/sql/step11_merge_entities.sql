-- PASO 11 - FINALMENTE HACER MERGE DE LOS CAMPOS DE LAS ENTIDADES AFECTADAS Y QUE FUERON MARCADAS COMO DIRTY

-- Eliminar temporalmente las constraints para mejorar el rendimiento
-- Solo si las constraints existen

-- Verificar y eliminar constraints de entity_fieldoccr

  -- FK entity_fieldoccr a entity(uuid)
ALTER TABLE IF EXISTS entity_fieldoccr DROP CONSTRAINT IF EXISTS fkg85y6bnncn3q9y762wvrwj08u;

-- FK entity_fieldoccr a fieldoccr(id)
ALTER TABLE IF EXISTS entity_fieldoccr DROP CONSTRAINT IF EXISTS fkaqxlq6pqglkl32ub46do5akpl;

-- FK relation a entity(uuid) from_entity_id
ALTER TABLE IF EXISTS relation DROP CONSTRAINT IF EXISTS fk9kavjxgi0tpvju15iab7petiw;

-- FK relation a entity(uuid) to_entity_id
ALTER TABLE IF EXISTS relation DROP CONSTRAINT IF EXISTS fk9wvqikvahl1a0x1xkcfdw42n;

-- FK relation a relation_type(id)
ALTER TABLE IF EXISTS relation DROP CONSTRAINT IF EXISTS fkgocmghsla07rat51y3w39n9tk;

-- FK relation_fieldoccr a entity(uuid) from_entity_id
ALTER TABLE IF EXISTS relation_fieldoccr DROP CONSTRAINT IF EXISTS relation_fieldoccr_entityfrom_uuid_fk;

-- FK relation_fieldoccr a entity(uuid) to_entity_id
ALTER TABLE IF EXISTS relation_fieldoccr DROP CONSTRAINT IF EXISTS relation_fieldoccr_entityto_uuid_fk;

-- FK relation_fieldoccr a fieldoccr(id)
ALTER TABLE IF EXISTS relation_fieldoccr DROP CONSTRAINT IF EXISTS relation_fieldoccr_fieldoccr_id_fk;

-- FK relation_fieldoccr a relation_type(id)
ALTER TABLE IF EXISTS relation_fieldoccr DROP CONSTRAINT IF EXISTS relation_fieldoccr_relation_type_id_fk;


-- Desactivar temporalmente el chequeo de restricciones para mejorar rendimiento
SET session_replication_role = 'replica';

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

-- Reactivar el chequeo de restricciones después de completar todas las operaciones
SET session_replication_role = 'origin';

-- Restaurar las constraints que fueron eliminadas
-- Vincula campos a entidades (CASCADE borra campos si se borra la entidad)
ALTER TABLE entity_fieldoccr ADD CONSTRAINT fkg85y6bnncn3q9y762wvrwj08u 
    FOREIGN KEY (entity_id) REFERENCES entity(uuid) ON DELETE CASCADE; 

-- Vincula campos a su definición
ALTER TABLE entity_fieldoccr ADD CONSTRAINT fkaqxlq6pqglkl32ub46do5akpl 
    FOREIGN KEY (fieldoccr_id) REFERENCES fieldoccr(id); 

-- Vincula relación con entidad origen (CASCADE borra relación si se borra la entidad)
ALTER TABLE relation ADD CONSTRAINT fk9kavjxgi0tpvju15iab7petiw 
    FOREIGN KEY (from_entity_id) REFERENCES entity(uuid) ON DELETE CASCADE; 

-- Vincula relación con entidad destino (CASCADE borra relación si se borra la entidad)
ALTER TABLE relation ADD CONSTRAINT fk9wvqikvahl1a0x1xkcfdw42n 
    FOREIGN KEY (to_entity_id) REFERENCES entity(uuid) ON DELETE CASCADE; 

-- Vincula relación con su tipo
ALTER TABLE relation ADD CONSTRAINT fkgocmghsla07rat51y3w39n9tk 
    FOREIGN KEY (relation_type_id) REFERENCES relation_type(id); 

-- Vincula campo de relación con entidad origen (CASCADE borra campos si se borra la entidad)
ALTER TABLE relation_fieldoccr ADD CONSTRAINT relation_fieldoccr_entityfrom_uuid_fk 
    FOREIGN KEY (from_entity_id) REFERENCES entity(uuid) ON DELETE CASCADE; 

-- Vincula campo de relación con entidad destino (CASCADE borra campos si se borra la entidad)
ALTER TABLE relation_fieldoccr ADD CONSTRAINT relation_fieldoccr_entityto_uuid_fk 
    FOREIGN KEY (to_entity_id) REFERENCES entity(uuid) ON DELETE CASCADE; 

-- Vincula campo de relación con su definición
ALTER TABLE relation_fieldoccr ADD CONSTRAINT relation_fieldoccr_fieldoccr_id_fk 
    FOREIGN KEY (fieldoccr_id) REFERENCES fieldoccr(id);

-- Vincula campo de relación con su tipo de relación
ALTER TABLE relation_fieldoccr ADD CONSTRAINT relation_fieldoccr_relation_type_id_fk 
    FOREIGN KEY (relation_type_id) REFERENCES relation_type(id); 

-- Opcional: verificar integridad de datos después de las operaciones
-- SELECT count(*) FROM entity WHERE uuid NOT IN (SELECT entity_id FROM entity_fieldoccr) AND dirty = FALSE;
-- SELECT count(*) FROM relation WHERE dirty = FALSE AND NOT EXISTS (SELECT 1 FROM relation_fieldoccr WHERE relation_fieldoccr.relation_type_id = relation.relation_type_id AND relation_fieldoccr.from_entity_id = relation.from_entity_id AND relation_fieldoccr.to_entity_id = relation.to_entity_id);


