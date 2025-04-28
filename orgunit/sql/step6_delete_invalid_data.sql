-- ====================================================
-- Deleting data related to INVALID SOURCE ORGUNITS (Type 1)
-- Assumes aux_invalid_source_orgunit only contains UUIDs for entity_type_id = 1
-- ====================================================

-- Delete source entity field occurrences linked to invalid source orgunits (Type 1)
DELETE FROM public.source_entity_fieldoccr
WHERE entity_id IN (SELECT source_entity_uuid FROM aux_invalid_source_orgunit);

-- Delete source relation field occurrences linked to invalid source orgunits (Type 1)
DELETE FROM public.source_relation_fieldoccr
WHERE from_entity_id IN (SELECT source_entity_uuid FROM aux_invalid_source_orgunit);

DELETE FROM public.source_relation_fieldoccr
WHERE to_entity_id IN (SELECT source_entity_uuid FROM aux_invalid_source_orgunit);

-- Delete source relations linked to invalid source orgunits (Type 1)
DELETE FROM public.source_relation
WHERE from_entity_id IN (SELECT source_entity_uuid FROM aux_invalid_source_orgunit);

DELETE FROM public.source_relation
WHERE to_entity_id IN (SELECT source_entity_uuid FROM aux_invalid_source_orgunit);

-- Delete semantic identifiers linked to invalid source orgunits (Type 1)
DELETE FROM public.source_entity_semantic_identifier
WHERE entity_id IN (SELECT source_entity_uuid FROM aux_invalid_source_orgunit);

-- Delete invalid source orgunits (Type 1) - Keeping direct type check for safety
DELETE FROM public.source_entity
WHERE uuid IN (SELECT source_entity_uuid FROM aux_invalid_source_orgunit)
  AND entity_type_id = 1;


-- ====================================================
-- Deleting data related to INVALID ORGUNITS (Entity - Type 1)
-- Assumes aux_invalid_orgunit only contains UUIDs for entity_type_id = 1
-- ====================================================

-- Delete relation field occurrences linked to invalid orgunits (Type 1)
DELETE FROM public.relation_fieldoccr
WHERE from_entity_id IN (SELECT uuid FROM aux_invalid_orgunit);

DELETE FROM public.relation_fieldoccr
WHERE to_entity_id IN (SELECT uuid FROM aux_invalid_orgunit);

-- Delete relations linked to invalid orgunits (Type 1)
DELETE FROM public.relation
WHERE from_entity_id IN (SELECT uuid FROM aux_invalid_orgunit);

DELETE FROM public.relation
WHERE to_entity_id IN (SELECT uuid FROM aux_invalid_orgunit);

-- Delete entity field occurrences linked to invalid orgunits (Type 1)
DELETE FROM public.entity_fieldoccr
WHERE entity_id IN (SELECT uuid FROM aux_invalid_orgunit);

-- Delete entity semantic identifiers linked to invalid orgunits (Type 1)
DELETE FROM public.entity_semantic_identifier
WHERE entity_id IN (SELECT uuid FROM aux_invalid_orgunit);

-- Delete invalid orgunits (Type 1) - Keeping direct type check for safety
DELETE FROM public.entity
WHERE uuid IN (SELECT uuid FROM aux_invalid_orgunit)
  AND entity_type_id = 1;

-- Nota: Se asume que las tablas auxiliares (aux_invalid_source_orgunit, aux_invalid_orgunit)
-- contienen los UUIDs de las entidades a eliminar (y que son de tipo 1) y existen en el schema 'public'.
-- Ajusta el schema si es necesario.
-- Se asume que entity_type_id = 1 corresponde al tipo de entidad OrgUnit.
