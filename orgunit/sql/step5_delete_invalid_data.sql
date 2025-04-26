-- ====================================================
-- Deleting data related to INVALID SOURCE ORGUNITS
-- ====================================================

-- Delete source entity field occurrences linked to invalid source orgunits
DELETE FROM public.source_entity_fieldoccr
WHERE source_entity_id IN (SELECT source_entity_uuid FROM aux_invalid_source_orgunit);

-- Delete source relation field occurrences linked to invalid source orgunits
DELETE FROM public.source_relation_fieldoccr
WHERE from_source_entity_id IN (SELECT source_entity_uuid FROM aux_invalid_source_orgunit);

DELETE FROM public.source_relation_fieldoccr
WHERE to_source_entity_id IN (SELECT source_entity_uuid FROM aux_invalid_source_orgunit);

-- Delete source relations linked to invalid source orgunits
DELETE FROM public.source_relation
WHERE from_source_entity_id IN (SELECT source_entity_uuid FROM aux_invalid_source_orgunit);

DELETE FROM public.source_relation
WHERE to_source_entity_id IN (SELECT source_entity_uuid FROM aux_invalid_source_orgunit);

-- Delete semantic identifiers linked to invalid source orgunits
DELETE FROM public.source_entity_semantic_identifier
WHERE entity_id IN (SELECT source_entity_uuid FROM aux_invalid_source_orgunit);

-- Delete invalid source orgunits
DELETE FROM public.source_entity
WHERE uuid IN (SELECT source_entity_uuid FROM aux_invalid_source_orgunit);


-- ====================================================
-- Deleting data related to INVALID ORGUNITS (Entity)
-- ====================================================

-- Delete relation field occurrences linked to invalid orgunits
DELETE FROM public.relation_fieldoccr
WHERE from_entity_id IN (SELECT uuid FROM aux_invalid_orgunit);

DELETE FROM public.relation_fieldoccr
WHERE to_entity_id IN (SELECT uuid FROM aux_invalid_orgunit);

-- Delete relations linked to invalid orgunits
DELETE FROM public.relation
WHERE from_entity_id IN (SELECT uuid FROM aux_invalid_orgunit);

DELETE FROM public.relation
WHERE to_entity_id IN (SELECT uuid FROM aux_invalid_orgunit);

-- Delete entity field occurrences linked to invalid orgunits
DELETE FROM public.entity_fieldoccr
WHERE entity_id IN (SELECT uuid FROM aux_invalid_orgunit);

-- Delete entity semantic identifiers linked to invalid orgunits
DELETE FROM public.entity_semantic_identifier
WHERE entity_id IN (SELECT uuid FROM aux_invalid_orgunit);

-- Delete invalid orgunits
DELETE FROM public.entity
WHERE uuid IN (SELECT uuid FROM aux_invalid_orgunit);

-- Nota: Se asume que las tablas auxiliares (aux_invalid_source_orgunit, aux_invalid_orgunit)
-- contienen los UUIDs de las entidades a eliminar y existen en el schema 'public'.
-- Ajusta el schema si es necesario.
