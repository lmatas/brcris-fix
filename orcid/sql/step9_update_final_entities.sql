-- PASO 9 - ACTUALIZAR EL FINAL-ENTITY-ID PARA LAS SOURCE ENTITIES QUE RESULTARON RELACIONADAS CON ENTIDADES PREEXISTENTES CON EL ORCID CORREGIDO

-- Actualizar final_entity_id en source_entity con las entidades correctas identificadas
UPDATE public.source_entity se
SET final_entity_id = web.new_final_entity_id
FROM public.wrong_orcid_entity_backup web
WHERE se.uuid = web.source_entity_id
  AND web.new_final_entity_id IS NOT NULL;