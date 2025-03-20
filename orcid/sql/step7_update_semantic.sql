-- PASO 7 - ACTUALIZAR LOS IDENTIFICADORES SEMÁNTICOS EN LA TABLA DE ENTIDADES
-- Este paso reutiliza las entidades existentes en lugar de crear nuevas, actualizando sus identificadores semánticos.

-- Actualizar los identificadores semánticos en la tabla entity
UPDATE public.entity e
SET semantic_id = web.new_semantic_id
FROM public.wrong_orcid_entity_backup web
WHERE e.uuid = web.final_entity_id
  AND web.new_semantic_id IS NOT NULL;

