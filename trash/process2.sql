-- PASO 3 - INSERTAR LOS NUEVOS IDENTIFICADORES SEMÁNTICOS CORREGIDOS EN LA TABLA SEMANTIC_IDENTIFIER
-- ESTE PASO ES NECESARIO PARA ASEGURAR QUE TODOS LOS NUEVOS ORCID LIMPIOS EXISTAN EN LA TABLA DE IDENTIFICADORES SEMÁNTICOS
-- ANTES DE REALIZAR LAS ACTUALIZACIONES DE REFERENCIAS

-- Insertar todos los nuevos ORCIDs corregidos que aún no existen en la tabla semantic_identifier
INSERT INTO semantic_identifier (id, semantic_id)
SELECT DISTINCT w.new_id, w.new_semantic_id
FROM wrong_orcid_semantic_identifier w
WHERE w.new_id IS NOT NULL
  AND w.new_semantic_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM semantic_identifier s
      WHERE s.id = w.new_id
  );


-- PASO 4 - TABLA AUXILIAR DE CORRESPONDENCIA DE ENTIDADES
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



-- PASO 5 - ACTUALIZAR LAS ENTRADAS EN SOURCE ENTITIES X SEMANTIC IDENTIFIER, CAMBIANDO LOS ID DE SEMATIC IDS ORCID ERRONEOS
-- POR EL SEMANTIC ID DEL ORCID CORREGIDO (8horas)


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
 
 
-- PASO 6 - ACTUALIZAR LA TABLA AUXILIAR DE CORRESPONDENCIA DE ENTIDADES EL CAMPO QUE MARCA LA ENTIDAD FINAL NUEVA, 
-- SOLO PARA LOS CASOS EN DONDE SE ENCUENTRE UNA ENTIDAD PREEXISTENTE CON ESE SEMANTIC ID (EL ORCID LIMPIO)
-- HABRÁ CASOS EN DONDE NO EXISTIA UNA ENTIDAD CON ESE ORCID, EN ESE CASO NEW-FINAL-ENTITY-ID SERÁ NULL 


-- 2. Actualizar la columna con las entidades que ya tienen el nuevo semantic_id (1hora)
UPDATE public.wrong_orcid_entity_backup web
SET new_final_entity_id = esi.entity_id
FROM public.entity_semantic_identifier esi
WHERE esi.semantic_id = web.new_semantic_id;

-- Cantidad de source entities asignadas a entidades ya existentes con el orcir corregido
select count(*)
from wrong_orcid_entity_backup woeb 
where woeb.new_final_entity_id is not null

select e.*, si.*
from entity e, entity_semantic_identifier esi, semantic_identifier si 
where esi.entity_id = e.uuid and si.id = esi.semantic_id and e.uuid = '55d1472c-756c-45e7-8f5a-9b485140c7f7' 


-- Cantidad de source entities que no tienen una entidad asignada con el nuevo orcid corregido
select count(*)
from wrong_orcid_entity_backup woeb 
where woeb.new_final_entity_id is null




-- PASO 7 - ACTUALIZAR LOS SEMANTIC IDENTIFIERS (TABLA ENTITY X SEMANTIC) PARA LAS ENTIDADES FINALES CON ORCID ERRONEOS
-- LA IDEA ES REUTILIZAR LAS ENTIDADES PARA NO CREAR NUEVAS, SIMPLEMENTE ACTUALIZANDO SUS SEMANTIC IDS, DE ESTA MANERA EVITAMOS
-- TENER QUE CREAR ENTIDADES (30min)


-- Demo de un caso de una entidad antigua con un orcid antiguo cuya version limpia no existía entre la entidades antiguas
select e.*, si.*
from entity e, entity_semantic_identifier esi, semantic_identifier si 
where esi.entity_id = e.uuid and si.id = esi.semantic_id and e.uuid = '55d1472c-756c-45e7-8f5a-9b485140c7f7' 


UPDATE public.entity_semantic_identifier esi
SET semantic_id = web.new_semantic_id
FROM wrong_orcid_entity_backup web
WHERE esi.entity_id = web.final_entity_id
  AND esi.semantic_id = web.old_semantic_id;
 
 
 -- Ahora verificamos el demo del caso anterior
select e.*, si.*
from entity e, entity_semantic_identifier esi, semantic_identifier si 
where esi.entity_id = e.uuid and si.id = esi.semantic_id and e.uuid = '55d1472c-756c-45e7-8f5a-9b485140c7f7' 

-- PASO 8 - MARCAR COMO DIRTY TODAS LAS ENTIDADES QUE FUERON AFECTADAS, TANTO LAS IDENTIFICADAS COMO EXISTENTES COMO LAS 
-- QUE FUERON ACTUALIZADAS CON LOS NUEVOS SEMANTIC IDS. DE ESTA MANERA AL EJECUTAR EL SP DE MERGE SERAN REASIGNADOS LOS CAMPOS (30min)

-- Marcar todas las entidades apuntadas como new como dirty, no olvidar ningun caso
update public.entity e 
set dirty = true 
FROM public.wrong_orcid_entity_backup web
WHERE web.new_final_entity_id is not null and e.uuid = web.new_final_entity_id; 

update public.entity e 
set dirty = true 
FROM public.wrong_orcid_entity_backup web
WHERE web.new_final_entity_id  is null and e.uuid = web.final_entity_id;  


-- PASO 9 - ACTUALIZAR EL FINAL-ENTITY-ID PARA LAS SOURCE ENTITIES QUE RESULTARON RELACIONADAS CON ENTIDADES PREEXISTENES CON EL ORCID CORREGIDO
-- ESO NO HACE FALTA PARA EL OTRO CASO, DADO QUE YA ESTABA ASIGNADAS A LAS ENTIDADES QUE FUERON ACTUALIZADAS CON EL NUEVO SEMANTIC ID (3h)

-- Actualizar final_entity_id en source_entity con las entidades correctas identificadas
UPDATE public.source_entity se
SET final_entity_id = web.new_final_entity_id
FROM public.wrong_orcid_entity_backup web
WHERE se.uuid = web.source_entity_id
  AND web.new_final_entity_id IS NOT NULL;
 
-- Las otras source entity no deben ser actualizadas ya que no cambio su uuid.
 
 
 
 -- PASO 10 - BORRAR TODAS LA ENTIDADES CON SEMANTIC IDS ERROREOS QUE YA TENIAN UN ENTIDAD EXISTENTE CON EL SEMANTIC ID CORREGIDO
 
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


-- borrar las entidades antiguas que ya fueron reemplazadas por otras entidades que ya tenian el orcid correcto asignado (24horas)
DELETE FROM public.entity 
WHERE uuid IN (SELECT distinct final_entity_id from wrong_orcid_entity_backup where new_final_entity_id is not null);


-- PASO 11 - FINALMENTE LLAMOS AL PROCEDIMIENTO PARA HACER MERGE DE LOS CAMPOS DE LAS ENTIDADES AFECTADAS Y QUE FUERON MARCADAS COMO DIRTY
 
-- finalmente hay que volver a ejecutar el merge
 CALL public.merge_entity_relation_data(1);

