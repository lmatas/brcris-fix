-- PASO 11 - FINALMENTE HACER MERGE DE LOS CAMPOS DE LAS ENTIDADES AFECTADAS Y QUE FUERON MARCADAS COMO DIRTY

-- OPTIMIZACIÓN A: USAR PARTITIONING TEMPORAL
-- Antes de comenzar, desactivar autovacuum durante las operaciones masivas
ALTER SYSTEM SET autovacuum = off;
SELECT pg_reload_conf();

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

-- OPTIMIZACIÓN B: CONFIGURACIÓN DE MEMORIA Y TRABAJO
-- Aumentar memoria de trabajo para operaciones masivas
SET work_mem = '1GB';                  -- Más memoria para operaciones de ordenamiento
SET maintenance_work_mem = '2GB';      -- Más memoria para mantenimiento
SET temp_buffers = '1GB';              -- Buffers temporales
SET random_page_cost = 1.1;            -- Optimizar para SSD

-- Drop indices if they exist
DROP INDEX IF EXISTS idx_entity_dirty;
DROP INDEX IF EXISTS idx_source_entity_deleted;
DROP INDEX IF EXISTS idx_source_entity_final_id;

-- Create indices to improve performance
CREATE INDEX idx_entity_dirty ON entity(dirty) WHERE dirty = TRUE;
CREATE INDEX idx_source_entity_deleted ON source_entity(deleted) WHERE deleted = FALSE;
CREATE INDEX idx_source_entity_final_id ON source_entity(final_entity_id);

-- OPTIMIZACIÓN C: USAR TABLAS TEMPORALES PARA CÁLCULOS INTERMEDIOS
-- 1. Preparar datos de dirty entities en una tabla temporal
CREATE TEMP TABLE tmp_dirty_entities AS 
SELECT uuid FROM entity WHERE dirty = TRUE;
CREATE INDEX ON tmp_dirty_entities(uuid);

-- 2. Preparar datos de entidades finales en una tabla temporal
CREATE TEMP TABLE tmp_final_entities AS
SELECT se.final_entity_id, se.uuid AS source_entity_id
FROM source_entity se 
WHERE se.deleted = FALSE
  AND se.final_entity_id IN (SELECT uuid FROM tmp_dirty_entities);
CREATE INDEX ON tmp_final_entities(final_entity_id);
CREATE INDEX ON tmp_final_entities(source_entity_id);

-- 3. Crear tabla temporal para los fieldoccrs a insertar
CREATE TEMP TABLE tmp_entity_fieldoccrs AS
SELECT DISTINCT fe.final_entity_id AS entity_id, sef.fieldoccr_id
FROM tmp_final_entities fe
JOIN source_entity_fieldoccr sef ON sef.entity_id = fe.source_entity_id;
CREATE INDEX ON tmp_entity_fieldoccrs(entity_id);

-- OPTIMIZACIÓN D: PROCESAMIENTO POR LOTES PARA OPERACIONES MASIVAS
BEGIN;
-- 1. Eliminar fieldoccrs existentes de manera eficiente
DELETE FROM entity_fieldoccr
WHERE entity_id IN (SELECT uuid FROM tmp_dirty_entities);

-- 2. Insertar nuevos fieldoccrs en un solo paso
INSERT INTO entity_fieldoccr (entity_id, fieldoccr_id)
SELECT entity_id, fieldoccr_id FROM tmp_entity_fieldoccrs;

-- 3. Crear tabla temporal para relaciones nuevas para minimizar cálculos repetidos
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

-- 4. Insertar nuevas relaciones
INSERT INTO relation (relation_type_id, from_entity_id, to_entity_id, dirty)
SELECT relation_type_id, from_entity_id, to_entity_id, TRUE
FROM tmp_new_relations;

-- OPTIMIZACIÓN E: USAR TRUNCATE PARA LIMPIEZA RÁPIDA DE RELATION_FIELDOCCR
-- Eliminar primero todas las ocurrencias para relaciones dirty
DELETE FROM relation_fieldoccr
USING relation
WHERE relation.dirty = TRUE 
  AND relation_fieldoccr.relation_type_id = relation.relation_type_id
  AND relation_fieldoccr.from_entity_id = relation.from_entity_id
  AND relation_fieldoccr.to_entity_id = relation.to_entity_id;

-- OPTIMIZACIÓN F: INSERCIÓN DIRECTA EN RELATION_FIELDOCCR
-- Preparar datos en tabla temporal para evitar cálculos repetidos
CREATE TEMP TABLE tmp_relation_fieldoccrs AS
SELECT DISTINCT r.from_entity_id, r.relation_type_id, r.to_entity_id, sro.fieldoccr_id
FROM relation r
JOIN source_entity se1 ON se1.final_entity_id = r.from_entity_id
JOIN source_entity se2 ON se2.final_entity_id = r.to_entity_id
JOIN source_relation_fieldoccr sro ON sro.from_entity_id = se1.uuid
                                   AND sro.to_entity_id = se2.uuid
                                   AND sro.relation_type_id = r.relation_type_id
WHERE r.dirty = TRUE;

-- Insertar en un solo paso
INSERT INTO relation_fieldoccr (from_entity_id, relation_type_id, to_entity_id, fieldoccr_id)
SELECT from_entity_id, relation_type_id, to_entity_id, fieldoccr_id
FROM tmp_relation_fieldoccrs;

-- Actualización de entidades en una sola consulta
UPDATE entity 
SET dirty = FALSE
WHERE dirty = TRUE;

-- Actualización de relaciones en una sola consulta
UPDATE relation 
SET dirty = FALSE
WHERE dirty = TRUE;

COMMIT;

-- OPTIMIZACIÓN G: RECONSTRUCCIÓN DE ÍNDICES
-- Reconstruir índices para mejorar rendimiento futuro
REINDEX TABLE entity;
REINDEX TABLE relation;
REINDEX TABLE entity_fieldoccr;
REINDEX TABLE relation_fieldoccr;

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

-- OPTIMIZACIÓN H: REACTIVAR AUTOVACUUM Y EJECUTAR VACUUM ANALYZE
ALTER SYSTEM SET autovacuum = on;
SELECT pg_reload_conf();

VACUUM ANALYZE entity;
VACUUM ANALYZE relation;
VACUUM ANALYZE entity_fieldoccr;
VACUUM ANALYZE relation_fieldoccr;

-- Opcional: verificar integridad de datos después de las operaciones
-- SELECT count(*) FROM entity WHERE uuid NOT IN (SELECT entity_id FROM entity_fieldoccr) AND dirty = FALSE;
-- SELECT count(*) FROM relation WHERE dirty = FALSE AND NOT EXISTS (SELECT 1 FROM relation_fieldoccr WHERE relation_fieldoccr.relation_type_id = relation.relation_type_id AND relation_fieldoccr.from_entity_id = relation.from_entity_id AND relation_fieldoccr.to_entity_id = relation.to_entity_id);


