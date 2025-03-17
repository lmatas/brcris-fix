-- 1. Crear una tabla para guardar la información de las entidades y sus identificadores
CREATE TABLE public.wrong_orcid_entity_backup AS
SELECT 
    se.uuid AS source_entity_id,
    se.final_entity_id,
    sesi.semantic_id AS old_semantic_id,
    wosi.new_id AS new_semantic_id
FROM public.source_entity se
JOIN public.source_entity_semantic_identifier sesi ON se.uuid = sesi.entity_id
JOIN public.wrong_orcid_semantic_identifier wosi ON sesi.semantic_id = wosi.id
WHERE wosi.new_id IS NOT NULL;


-- Índice para las búsquedas por source_entity_id (utilizado en muchas consultas)
CREATE INDEX idx_woeb_source_entity_id ON public.wrong_orcid_entity_backup(source_entity_id);

-- Índice para las búsquedas por final_entity_id (para relacionar con entity)
CREATE INDEX idx_woeb_final_entity_id ON public.wrong_orcid_entity_backup(final_entity_id);

-- Índice para las búsquedas por old_semantic_id (utilizado en joins con entity_semantic_identifier)
-- CREATE INDEX idx_woeb_old_semantic_id ON public.wrong_orcid_entity_backup(old_semantic_id);

-- Índice para las búsquedas por new_semantic_id (utilizado en consultas de actualización)
-- CREATE INDEX idx_woeb_new_semantic_id ON public.wrong_orcid_entity_backup(new_semantic_id);

-- Índice compuesto para consultas que usen source_entity_id y old_semantic_id juntos
-- CREATE INDEX idx_woeb_source_old_semantic ON public.wrong_orcid_entity_backup(source_entity_id, old_semantic_id);

-- 2. Actualizar source_entity usando la nueva tabla
UPDATE public.source_entity se
SET final_entity_id = NULL
FROM wrong_orcid_entity_backup web
WHERE se.uuid = web.source_entity_id;

-- 3. Actualizar referencias en source_entity_semantic_identifier
UPDATE public.source_entity_semantic_identifier sesi
SET semantic_id = web.new_semantic_id
FROM wrong_orcid_entity_backup web
WHERE sesi.entity_id = web.source_entity_id
  AND sesi.semantic_id = web.old_semantic_id;

-- Eliminar la entidades basadas en semantic ids erroneos
DELETE FROM public.entity 
WHERE uuid IN (SELECT distinct final_entity_id from wrong_orcid_entity_backup)
CASCADE;


-- 1. Agregar la nueva columna para almacenar el UUID de la entidad final nueva
ALTER TABLE public.wrong_orcid_entity_backup
ADD COLUMN new_final_entity_id uuid NULL;

-- 2. Actualizar la columna con las entidades que ya tienen el nuevo semantic_id
UPDATE public.wrong_orcid_entity_backup web
SET new_final_entity_id = esi.entity_id
FROM public.entity_semantic_identifier esi
WHERE esi.semantic_id = web.new_semantic_id;

-- Actualizar final_entity_id en source_entity con las entidades correctas identificadas
UPDATE public.source_entity se
SET final_entity_id = web.new_final_entity_id
FROM public.wrong_orcid_entity_backup web
WHERE se.uuid = web.source_entity_id
  AND web.new_final_entity_id IS NOT NULL;
 
 
