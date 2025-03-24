--  Crear una tabla para guardar la información de las entidades y sus identificadores
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

-- Agregar la nueva columna para almacenar el UUID de la entidad final nueva
ALTER TABLE public.wrong_orcid_entity_backup
ADD COLUMN new_final_entity_id uuid NULL;


-- Índices para acelerar las queries
CREATE INDEX idx_woeb_source_entity_id ON public.wrong_orcid_entity_backup(source_entity_id);
CREATE INDEX idx_woeb_final_entity_id ON public.wrong_orcid_entity_backup(final_entity_id);
CREATE INDEX idx_woeb_old_semantic_id ON public.wrong_orcid_entity_backup(old_semantic_id);
CREATE INDEX idx_woeb_new_semantic_id ON public.wrong_orcid_entity_backup(new_semantic_id);
CREATE INDEX idx_woeb_source_old_semantic ON public.wrong_orcid_entity_backup(source_entity_id, old_semantic_id);
CREATE INDEX idx_sesi_entity_id_semantic_id ON public.source_entity_semantic_identifier (entity_id, semantic_id);


-- Desactivar restricción
ALTER TABLE source_entity_semantic_identifier DROP CONSTRAINT fk9bf1gs0tx86f4eewbws4hkytp;

-- Actualizar referencias en source_entity_semantic_identifier (8horas)
UPDATE public.source_entity_semantic_identifier sesi
SET semantic_id = web.new_semantic_id
FROM wrong_orcid_entity_backup web
WHERE sesi.entity_id = web.source_entity_id
  AND sesi.semantic_id = web.old_semantic_id;

-- Reactivar restricción
ALTER TABLE source_entity_semantic_identifier ADD CONSTRAINT fk9bf1gs0tx86f4eewbws4hkytp 
FOREIGN KEY (semantic_id) REFERENCES public.semantic_identifier(id); 
 
 
-- 2. Actualizar la columna con las entidades que ya tienen el nuevo semantic_id (1hora)
UPDATE public.wrong_orcid_entity_backup web
SET new_final_entity_id = esi.entity_id
FROM public.entity_semantic_identifier esi
WHERE esi.semantic_id = web.new_semantic_id;

-- Cantidad de source entities asignadas a entidades ya existentes con el orcir corregido
select count(*)
from wrong_orcid_entity_backup woeb 
where woeb.new_final_entity_id is not null

-- Cantidad de source entities que no tienen una entidad asignada con el nuevo orcid corregido
select count(*)
from wrong_orcid_entity_backup woeb 
where woeb.new_final_entity_id is null

--- ANTES DE BORRAR LAS ENTIDADES VAMOS A HACER QUE LAS RELACIONES TENGA DELETES EN CASCADE
-- 1. entity_semantic_identifier
ALTER TABLE entity_semantic_identifier DROP CONSTRAINT fkinjr1aqio6tuon2ypi6ixd4ao;
ALTER TABLE entity_semantic_identifier ADD CONSTRAINT fkinjr1aqio6tuon2ypi6ixd4ao 
    FOREIGN KEY (entity_id) REFERENCES entity(uuid) ON DELETE CASCADE;

-- 2. entity_fieldoccr
ALTER TABLE entity_fieldoccr DROP CONSTRAINT fkg85y6bnncn3q9y762wvrwj08u;
ALTER TABLE entity_fieldoccr ADD CONSTRAINT fkg85y6bnncn3q9y762wvrwj08u 
    FOREIGN KEY (entity_id) REFERENCES entity(uuid) ON DELETE CASCADE;

-- 3. relation (from_entity_id)
ALTER TABLE relation DROP CONSTRAINT fk9kavjxgi0tpvju15iab7petiw;
ALTER TABLE relation ADD CONSTRAINT fk9kavjxgi0tpvju15iab7petiw 
    FOREIGN KEY (from_entity_id) REFERENCES entity(uuid) ON DELETE CASCADE;

-- 4. relation (to_entity_id)
ALTER TABLE relation DROP CONSTRAINT fk9wvqikvahl1a0x1xkcfdw42n;
ALTER TABLE relation ADD CONSTRAINT fk9wvqikvahl1a0x1xkcfdw42n 
    FOREIGN KEY (to_entity_id) REFERENCES entity(uuid) ON DELETE CASCADE;

-- 5. relation_fieldoccr (from_entity_id)
ALTER TABLE relation_fieldoccr DROP CONSTRAINT relation_fieldoccr_entityfrom_uuid_fk;
ALTER TABLE relation_fieldoccr ADD CONSTRAINT relation_fieldoccr_entityfrom_uuid_fk 
    FOREIGN KEY (from_entity_id) REFERENCES entity(uuid) ON DELETE CASCADE;

-- 6. relation_fieldoccr (to_entity_id)
ALTER TABLE relation_fieldoccr DROP CONSTRAINT relation_fieldoccr_entityto_uuid_fk;
ALTER TABLE relation_fieldoccr ADD CONSTRAINT relation_fieldoccr_entityto_uuid_fk 
    FOREIGN KEY (to_entity_id) REFERENCES entity(uuid) ON DELETE CASCADE;
------------------------------
--- FIN DE LOS ALTER TABLE


-- borrar las entidades antiguas que ya fueron reemplazadas por otras entidades que ya tenian el orcid correcto asignado
DELETE FROM public.entity 
WHERE uuid IN (SELECT distinct final_entity_id from wrong_orcid_entity_backup where new_final_entity_id is not null);

-- Ahora hay que actualizar la entidades antiguas (orcid erroneos) que no fueron reemplazadas por otra entidad pre existente,
-- Eso significa que debemos actualizar sus semantic identifiers basados en orcid para que se correspondan con los correctos,
-- Luego marcarlas como dirty para que sean reprocesados sus campos y relaciones

-- Entonces en la tabla wrong_orcid_entity_backup deben ahora actualizarse la new_final entities para estos casos donde se reaprovecha 
-- la misma que la entidad anterior



-- Atencion marcar todas las entidades apuntadas como new como dirty, no olvidar ningun caso



-- Actualizar final_entity_id en source_entity con las entidades correctas identificadas
UPDATE public.source_entity se
SET final_entity_id = web.new_final_entity_id
FROM public.wrong_orcid_entity_backup web
WHERE se.uuid = web.source_entity_id
  AND web.new_final_entity_id IS NOT NULL;
 
 





 
