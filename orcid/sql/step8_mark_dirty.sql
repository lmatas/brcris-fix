-- Marcar todas las entidades apuntadas como new como dirty
UPDATE public.entity e 
SET dirty = true 
FROM public.wrong_orcid_entity_backup web
WHERE web.new_final_entity_id IS NOT NULL AND e.uuid = web.new_final_entity_id; 

UPDATE public.entity e 
SET dirty = true 
FROM public.wrong_orcid_entity_backup web
WHERE web.new_final_entity_id IS NULL AND e.uuid = web.final_entity_id; 