-- =============================================================================
-- SCRIPT DE LIMPIEZA DE BASE DE DATOS
-- -----------------------------------------------------------------------------
-- Este script realiza las siguientes operaciones principales:
-- 2. Elimina registros de 'source_entity' marcados como 'deleted' y sus dependencias.
-- 3. Elimina registros de 'entity' que han quedado huérfanos (sin 'source_entity' asociada).
-- 4. Elimina registros de 'semantic_identifier' que han quedado huérfanos.
-- =============================================================================



-- =============================================================================
-- SECCIÓN 2: LIMPIEZA DE ENTIDADES DE ORIGEN ('source_entity') MARCADAS COMO ELIMINADAS
-- -----------------------------------------------------------------------------
-- Este bloque se encarga de eliminar todas las 'source_entity' que han sido
-- marcadas con 'deleted = true', junto con todos sus registros dependientes
-- en otras tablas.
-- =============================================================================

-- Paso 2.1: Crear tabla temporal para almacenar los UUIDs de 'source_entity' marcadas como 'deleted'.
-- Esta tabla optimiza las operaciones de eliminación subsiguientes.
CREATE TABLE temp_deleted_source_entities (
    source_entity_uuid uuid NOT NULL
);

-- Paso 2.2: Poblar la tabla temporal con los UUIDs de 'source_entity' marcadas como 'deleted'.
INSERT INTO temp_deleted_source_entities (source_entity_uuid)
SELECT "uuid"
FROM public.source_entity
WHERE deleted = true;

-- Paso 2.3: Crear un índice en la tabla temporal para búsquedas rápidas.
CREATE INDEX idx_temp_deleted_source_entities_uuid ON temp_deleted_source_entities (source_entity_uuid);

-- Paso 2.4: Borrar de 'public.source_relation_fieldoccr' usando la tabla temporal.
-- Se eliminan los registros donde 'from_entity_id' o 'to_entity_id' coinciden con una 'source_entity' eliminada.
DELETE FROM public.source_relation_fieldoccr srf
USING temp_deleted_source_entities tmp
WHERE srf.from_entity_id = tmp.source_entity_uuid OR srf.to_entity_id = tmp.source_entity_uuid;

-- Paso 2.5: Borrar de 'public.source_entity_fieldoccr' usando la tabla temporal.
-- Se eliminan los registros donde 'entity_id' coincide con una 'source_entity' eliminada.
DELETE FROM public.source_entity_fieldoccr sef
USING temp_deleted_source_entities tmp
WHERE sef.entity_id = tmp.source_entity_uuid;

-- Paso 2.6: Borrar de 'public.source_entity_semantic_identifier' usando la tabla temporal.
-- Se eliminan los registros donde 'entity_id' coincide con una 'source_entity' eliminada.
DELETE FROM public.source_entity_semantic_identifier sesi
USING temp_deleted_source_entities tmp
WHERE sesi.entity_id = tmp.source_entity_uuid;

-- Paso 2.7: Borrar de 'public.source_relation' usando la tabla temporal.
-- Se eliminan los registros donde 'from_entity_id' o 'to_entity_id' coinciden con una 'source_entity' eliminada.
DELETE FROM public.source_relation sr
USING temp_deleted_source_entities tmp
WHERE sr.from_entity_id = tmp.source_entity_uuid OR sr.to_entity_id = tmp.source_entity_uuid;

-- Paso 2.8: Finalmente, borrar las 'source_entity' marcadas como 'deleted'.
DELETE FROM public.source_entity se
USING temp_deleted_source_entities tmp
WHERE se."uuid" = tmp.source_entity_uuid;

-- Paso 2.9: Eliminar la tabla temporal cuando ya no se necesite.
DROP TABLE temp_deleted_source_entities;

-- =============================================================================
-- SECCIÓN 3: LIMPIEZA DE ENTIDADES FINALES ('entity') HUÉRFANAS
-- -----------------------------------------------------------------------------
-- Este bloque identifica y elimina las 'entity' que no tienen ninguna
-- 'source_entity' apuntando hacia ellas a través de 'final_entity_id'.
-- Estas 'entity' se consideran huérfanas y se eliminan junto con sus dependencias.
-- =============================================================================

-- Paso 3.1: Crear tabla temporal para almacenar los UUIDs de 'entity' huérfanas.
CREATE TABLE temp_orphaned_entities (
    entity_uuid uuid NOT NULL
);

-- Paso 3.2: Poblar la tabla temporal con los UUIDs de 'entity' que no están referenciadas
-- por ninguna 'source_entity' en el campo 'final_entity_id'.
INSERT INTO temp_orphaned_entities (entity_uuid)
SELECT e."uuid"
FROM public.entity e
WHERE NOT EXISTS (
    SELECT 1
    FROM public.source_entity se
    WHERE se.final_entity_id = e."uuid"
);

-- Paso 3.3: Crear un índice en la tabla temporal para búsquedas rápidas.
CREATE INDEX idx_temp_orphaned_entities_uuid ON temp_orphaned_entities (entity_uuid);

-- Paso 3.4: Borrar de 'public.relation_fieldoccr' usando la tabla temporal de huérfanas.
-- Se eliminan los registros relacionados con entidades huérfanas.
DELETE FROM public.relation_fieldoccr rf
USING temp_orphaned_entities tmp
WHERE rf.from_entity_id = tmp.entity_uuid OR rf.to_entity_id = tmp.entity_uuid;

-- Paso 3.5: Borrar de 'public.relation' usando la tabla temporal de huérfanas.
-- Se eliminan las relaciones que involucran entidades huérfanas.
DELETE FROM public.relation r
USING temp_orphaned_entities tmp
WHERE r.from_entity_id = tmp.entity_uuid OR r.to_entity_id = tmp.entity_uuid;

-- Paso 3.6: Borrar de 'public.entity_fieldoccr' usando la tabla temporal de huérfanas.
-- Se eliminan los 'fieldoccr' asociados a entidades huérfanas.
DELETE FROM public.entity_fieldoccr ef
USING temp_orphaned_entities tmp
WHERE ef.entity_id = tmp.entity_uuid;

-- Paso 3.7: Borrar de 'public.entity_semantic_identifier' usando la tabla temporal de huérfanas.
-- Se eliminan los identificadores semánticos asociados a entidades huérfanas.
DELETE FROM public.entity_semantic_identifier esi
USING temp_orphaned_entities tmp
WHERE esi.entity_id = tmp.entity_uuid;

-- Paso 3.8: Finalmente, borrar las 'entity' huérfanas.
DELETE FROM public.entity e
USING temp_orphaned_entities tmp
WHERE e."uuid" = tmp.entity_uuid;

-- Paso 3.9: Eliminar la tabla temporal cuando ya no se necesite.
DROP TABLE temp_orphaned_entities;

-- =============================================================================
-- SECCIÓN 4: LIMPIEZA DE IDENTIFICADORES SEMÁNTICOS ('semantic_identifier') HUÉRFANOS
-- -----------------------------------------------------------------------------
-- Este bloque identifica y elimina los 'semantic_identifier' que no están
-- referenciados ni por 'source_entity_semantic_identifier' ni por
-- 'entity_semantic_identifier'.
-- =============================================================================

-- Paso 4.1: Crear tabla temporal para almacenar los IDs de 'semantic_identifier' huérfanos.
CREATE TABLE temp_orphaned_semantic_identifiers (
    semantic_id int8 NOT NULL
);

-- Paso 4.2: Poblar la tabla temporal con los IDs de 'semantic_identifier' que no están
-- referenciados en 'source_entity_semantic_identifier' NI en 'entity_semantic_identifier'.
INSERT INTO temp_orphaned_semantic_identifiers (semantic_id)
SELECT si.id
FROM public.semantic_identifier si
WHERE NOT EXISTS (
    SELECT 1
    FROM public.source_entity_semantic_identifier sesi
    WHERE sesi.semantic_id = si.id
    )
 AND NOT EXISTS (
     SELECT 1
     FROM public.entity_semantic_identifier esi
     WHERE esi.semantic_id = si.id
 );

-- Paso 4.3: Crear un índice en la tabla temporal para búsquedas rápidas.
CREATE INDEX idx_temp_orphaned_semantic_identifiers_id ON temp_orphaned_semantic_identifiers (semantic_id);

-- Paso 4.4: Borrar de 'public.entity_semantic_identifier' usando la tabla temporal.
-- Este paso es importante si la condición NOT EXISTS en el Paso 4.2 no fuera suficiente
-- o para asegurar la limpieza de referencias que pudieran haberse creado concurrentemente.
DELETE FROM public.entity_semantic_identifier esi
USING temp_orphaned_semantic_identifiers tmp
WHERE esi.semantic_id = tmp.semantic_id;

-- Paso 4.5: Borrar de 'public.source_entity_semantic_identifier' usando la tabla temporal.
-- Similar al paso anterior, asegura la limpieza completa. Puede ser redundante si las FKs
-- o la lógica de inserción en Paso 4.2 son estrictas.
DELETE FROM public.source_entity_semantic_identifier sesi
USING temp_orphaned_semantic_identifiers tmp
WHERE sesi.semantic_id = tmp.semantic_id;

-- Paso 4.6: Finalmente, borrar los 'semantic_identifier' huérfanos.
DELETE FROM public.semantic_identifier si
USING temp_orphaned_semantic_identifiers tmp
WHERE si.id = tmp.semantic_id;

-- Paso 4.7: Eliminar la tabla temporal cuando ya no se necesite.
DROP TABLE temp_orphaned_semantic_identifiers;

-- =============================================================================
-- SECCIÓN 5: LIMPIEZA DE OCURRENCIAS DE CAMPO ('field_occurrence') HUÉRFANAS
-- -----------------------------------------------------------------------------
-- Este bloque identifica y elimina los 'field_occurrence' que no están
-- referenciados en ninguna de las tablas de enlace:
-- 'entity_fieldoccr', 'source_entity_fieldoccr',
-- 'relation_fieldoccr', 'source_relation_fieldoccr'.
-- =============================================================================

-- Paso 5.1: Crear tabla temporal para almacenar los IDs de 'field_occurrence' huérfanos.
CREATE TABLE temp_orphaned_field_occurrences (
    field_occurrence_id int8 NOT NULL
);

-- Paso 5.2: Poblar la tabla temporal con los IDs de 'field_occurrence' que no están referenciados.
INSERT INTO temp_orphaned_field_occurrences (field_occurrence_id)
SELECT fo.id
FROM public.field_occurrence fo
WHERE NOT EXISTS (
    SELECT 1
    FROM public.entity_fieldoccr efo
    WHERE efo.fieldoccr_id = fo.id
)
AND NOT EXISTS (
    SELECT 1
    FROM public.source_entity_fieldoccr sefo
    WHERE sefo.fieldoccr_id = fo.id
)
AND NOT EXISTS (
    SELECT 1
    FROM public.relation_fieldoccr rfo
    WHERE rfo.fieldoccr_id = fo.id
)
AND NOT EXISTS (
    SELECT 1
    FROM public.source_relation_fieldoccr srfo
    WHERE srfo.fieldoccr_id = fo.id
);

-- Paso 5.3: Crear un índice en la tabla temporal para búsquedas rápidas.
CREATE INDEX idx_temp_orphaned_field_occurrences_id ON temp_orphaned_field_occurrences (field_occurrence_id);

-- Paso 5.4: Finalmente, borrar los 'field_occurrence' huérfanos.
DELETE FROM public.field_occurrence fo
USING temp_orphaned_field_occurrences tmp
WHERE fo.id = tmp.field_occurrence_id;

-- Paso 5.5: Eliminar la tabla temporal cuando ya no se necesite.
DROP TABLE temp_orphaned_field_occurrences;

-- =============================================================================
-- FIN DEL SCRIPT DE LIMPIEZA
-- =============================================================================