-- PASO 6 - ACTUALIZAR LA TABLA AUXILIAR DE CORRESPONDENCIA DE ENTIDADES EL CAMPO QUE MARCA LA ENTIDAD FINAL NUEVA, 
-- SOLO PARA LOS CASOS EN DONDE SE ENCUENTRE UNA ENTIDAD PREEXISTENTE CON ESE SEMANTIC ID (EL ORCID LIMPIO)
-- HABRÁ CASOS EN DONDE NO EXISTIA UNA ENTIDAD CON ESE ORCID, EN ESE CASO NEW-FINAL-ENTITY-ID SERÁ NULL 

-- Actualizar la columna con las entidades que ya tienen el nuevo semantic_id
UPDATE public.wrong_orcid_entity_backup web
SET new_final_entity_id = esi.entity_id
FROM public.entity_semantic_identifier esi
WHERE esi.semantic_id = web.new_semantic_id;