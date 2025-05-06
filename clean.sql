-- Deshabilitar FKs que apuntan a entity (con IF EXISTS)
ALTER TABLE public.entity_semantic_identifier DROP CONSTRAINT IF EXISTS fkinjr1aqio6tuon2ypi6ixd4ao;
ALTER TABLE public.relation DROP CONSTRAINT IF EXISTS fk9kavjxgi0tpvju15iab7petiw;
ALTER TABLE public.relation DROP CONSTRAINT IF EXISTS fk9wvqikvahl1a0x1xkcfdw42n;
ALTER TABLE public.relation_fieldoccr DROP CONSTRAINT IF EXISTS relation_fieldoccr_entityfrom_uuid_fk;
ALTER TABLE public.relation_fieldoccr DROP CONSTRAINT IF EXISTS relation_fieldoccr_entityto_uuid_fk;
ALTER TABLE public.entity_fieldoccr DROP CONSTRAINT IF EXISTS fkg85y6bnncn3q9y762wvrwj08u;

-- Deshabilitar FKs que apuntan a source_entity (con IF EXISTS)
ALTER TABLE public.source_entity_semantic_identifier DROP CONSTRAINT IF EXISTS fkequg2xow14h1xdkde3c2q92o0;
ALTER TABLE public.source_relation DROP CONSTRAINT IF EXISTS fka85ljpk6ps09u8nya2pvpfgvk; -- Corregido del DDL
ALTER TABLE public.source_relation DROP CONSTRAINT IF EXISTS fkirpb50vicfsbg28olx4snn39s; -- Corregido del DDL
ALTER TABLE public.source_relation_fieldoccr DROP CONSTRAINT IF EXISTS source_relation_fieldoccr_source_entityfrom_uuid_fk;
ALTER TABLE public.source_relation_fieldoccr DROP CONSTRAINT IF EXISTS source_relation_fieldoccr_source_entityto_uuid_fk;
ALTER TABLE public.source_entity_fieldoccr DROP CONSTRAINT IF EXISTS fk2f3wc4b3huh74134hloikiou7;

-- Deshabilitar FKs que apuntan a source_relation (depende de source_entity) (con IF EXISTS)
ALTER TABLE public.source_relation_fieldoccr DROP CONSTRAINT IF EXISTS fkntrxgvqcjsy3w7nb8xxcauh84;

-- Crear tabla temporal para almacenar los UUIDs de source_entity marcados como deleted
CREATE TABLE temp_deleted_source_entities (
    source_entity_uuid uuid NOT NULL
);

-- Poblar la tabla temporal con los UUIDs de source_entity marcados como deleted
INSERT INTO temp_deleted_source_entities (source_entity_uuid)
SELECT "uuid"
FROM public.source_entity
WHERE deleted = true;

-- Crear un índice en la tabla temporal para búsquedas rápidas
CREATE INDEX idx_temp_deleted_source_entities_uuid ON temp_deleted_source_entities (source_entity_uuid);


-- Borrar de source_relation_fieldoccr usando la tabla temporal
DELETE FROM public.source_relation_fieldoccr srf
USING temp_deleted_source_entities tmp
WHERE srf.from_entity_id = tmp.source_entity_uuid OR srf.to_entity_id = tmp.source_entity_uuid;

-- Borrar de source_entity_fieldoccr usando la tabla temporal
DELETE FROM public.source_entity_fieldoccr sef
USING temp_deleted_source_entities tmp
WHERE sef.entity_id = tmp.source_entity_uuid;

-- Borrar de source_entity_semantic_identifier usando la tabla temporal
DELETE FROM public.source_entity_semantic_identifier sesi
USING temp_deleted_source_entities tmp
WHERE sesi.entity_id = tmp.source_entity_uuid;

-- Borrar de source_relation usando la tabla temporal
DELETE FROM public.source_relation sr
USING temp_deleted_source_entities tmp
WHERE sr.from_entity_id = tmp.source_entity_uuid OR sr.to_entity_id = tmp.source_entity_uuid;

-- Finalmente, borrar las source_entity marcadas como deleted
DELETE FROM public.source_entity se
USING temp_deleted_source_entities tmp
WHERE se."uuid" = tmp.source_entity_uuid;


-- Eliminar la tabla temporal cuando ya no se necesite
DROP TABLE temp_deleted_source_entities;

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- Bloque para borrar entidades 'huérfanas' (sin source_entity asociada) --
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Crear tabla temporal para almacenar los UUIDs de entity 'huérfanas'
CREATE TABLE temp_orphaned_entities (
    entity_uuid uuid NOT NULL
);

-- Poblar la tabla temporal con los UUIDs de entity que no están en source_entity.final_entity_id
INSERT INTO temp_orphaned_entities (entity_uuid)
SELECT e."uuid"
FROM public.entity e
WHERE NOT EXISTS (
    SELECT 1
    FROM public.source_entity se
    WHERE se.final_entity_id = e."uuid"
);

-- Crear un índice en la tabla temporal para búsquedas rápidas
CREATE INDEX idx_temp_orphaned_entities_uuid ON temp_orphaned_entities (entity_uuid);

-- Borrar de relation_fieldoccr usando la tabla temporal de huérfanas
DELETE FROM public.relation_fieldoccr rf
USING temp_orphaned_entities tmp
WHERE rf.from_entity_id = tmp.entity_uuid OR rf.to_entity_id = tmp.entity_uuid;

-- Borrar de relation usando la tabla temporal de huérfanas
DELETE FROM public.relation r
USING temp_orphaned_entities tmp
WHERE r.from_entity_id = tmp.entity_uuid OR r.to_entity_id = tmp.entity_uuid;

-- Borrar de entity_fieldoccr usando la tabla temporal de huérfanas
DELETE FROM public.entity_fieldoccr ef
USING temp_orphaned_entities tmp
WHERE ef.entity_id = tmp.entity_uuid;

-- Borrar de entity_semantic_identifier usando la tabla temporal de huérfanas
DELETE FROM public.entity_semantic_identifier esi
USING temp_orphaned_entities tmp
WHERE esi.entity_id = tmp.entity_uuid;

-- Finalmente, borrar las entity 'huérfanas'
DELETE FROM public.entity e
USING temp_orphaned_entities tmp
WHERE e."uuid" = tmp.entity_uuid;

-- Eliminar la tabla temporal cuando ya no se necesite
DROP TABLE temp_orphaned_entities;