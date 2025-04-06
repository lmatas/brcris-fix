-- PASO 5 - ACTUALIZAR LAS ENTRADAS EN SOURCE ENTITIES X SEMANTIC IDENTIFIER, CAMBIANDO LOS ID DE SEMANTIC IDS ORCID ERRONEOS
-- POR EL SEMANTIC ID DEL ORCID CORREGIDO

-- Desactivar restricción
ALTER TABLE source_entity_semantic_identifier DROP CONSTRAINT IF EXISTS fk9bf1gs0tx86f4eewbws4hkytp;

-- Actualizar referencias en source_entity_semantic_identifier
UPDATE public.source_entity_semantic_identifier sesi
SET semantic_id = web.new_semantic_id
FROM public.wrong_orcid_entity_backup web
WHERE sesi.entity_id = web.source_entity_id
  AND sesi.semantic_id = web.old_semantic_id;

-- Reactivar restricción
ALTER TABLE source_entity_semantic_identifier ADD CONSTRAINT fk9bf1gs0tx86f4eewbws4hkytp 
FOREIGN KEY (semantic_id) REFERENCES public.semantic_identifier(id); 

