-- PASO 7 Update de entity_semantic_identifier y source_entity para actualizar los identificadores semánticos y las entidades finales 

-- Actualizar identificadores semánticos en entity_semantic_identifier para convertir las entidades antiguas que tenian el ORCID erróneo en entidades correctas
-- solo para los casos donde las entidades no fueron reemplazadas por otras entidades que ya tenian el orcid correcto asignado 
UPDATE public.entity_semantic_identifier esi
SET semantic_id = woeb.new_semantic_id
FROM public.wrong_orcid_entity_backup woeb
WHERE woeb.new_final_entity_id IS NULL 
  AND esi.entity_id = woeb.final_entity_id
  AND esi.semantic_id = woeb.old_semantic_id;

-- Reasignar las entidades finales en las source entities con entidades que tenian el ORCID erróneo y ya existian entidades con el ORCID correcto
UPDATE public.source_entity se
SET final_entity_id = woeb.new_final_entity_id
FROM public.wrong_orcid_entity_backup woeb
WHERE woeb.new_final_entity_id IS NOT NULL 
  AND se.uuid = woeb.source_entity_id
  AND se.final_entity_id = woeb.final_entity_id;

