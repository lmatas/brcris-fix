-- create indexes for provenance on source_id field
CREATE INDEX provenance_source_id_idx ON public.provenance (source_id);
CREATE UNIQUE INDEX provenance_id_idx ON public.provenance (id,source_id);
CREATE INDEX idx_source_entity_provenance_id ON source_entity (provenance_id);
CREATE INDEX idx_semantic_identifier_semantic_id_pattern ON public.semantic_identifier (semantic_id text_pattern_ops);

-- oasisbr provenances
create table aux_oasisbr_provenance_oasis as
select p.id as provenance_id, p.record_id
from provenance p 
where p.source_id = 'oasisbr';

CREATE UNIQUE INDEX aux_oasisbr_provenance_oasis_id_idx ON public.aux_oasisbr_provenance_oasis (provenance_id);

-- lattes provenances
create table aux_oasisbr_provenance_lattes as
select p.id as provenance_id
from provenance p 
where p.source_id = 'lattes';

CREATE UNIQUE INDEX aux_oasisbr_provenance_lattes_id_idx ON public.aux_oasisbr_provenance_lattes (provenance_id);


-- create a temporary table to store source_entity corresponding to oasisbr provenance
create table aux_oasisbr_source_entities_from_oasis as
SELECT se."uuid" as source_entity_id, final_entity_id  
FROM source_entity se, aux_oasisbr_provenance_oasis aop 
where se.provenance_id = aop.provenance_id and se.deleted = false and se.entity_type_id = 15;

-- create indexes for the aux_oasisbr_source_entities_from_oasis table
CREATE INDEX aux_oasisbr_source_entities_source_entity_id_idx ON public.aux_oasisbr_source_entities_from_oasis (source_entity_id);
CREATE INDEX aux_oasisbr_source_entities_final_entity_id_idx ON public.aux_oasisbr_source_entities_from_oasis (final_entity_id);

-- clean aux_oasisbr_source_entities_from_oasis
-- filter > 2 lattes, only source entities with 2 different lattes will remain
delete from aux_oasisbr_source_entities_from_oasis aose
where not exists 
	(select 1
	from source_entity_semantic_identifier sesi, semantic_identifier si 
	where aose.source_entity_id = sesi.entity_id and sesi.semantic_id = si.id and si.semantic_id like 'lattes%'
	group by sesi.entity_id
	having count(*) > 1
	);


-- create table with entities to fix, based on the final entities corresponding to the source entities of oasis br con more than one lattes semantic id
create table aux_oasisbr_broken_entities as 
select distinct final_entity_id from aux_oasisbr_source_entities_from_oasis aose;

CREATE INDEX idx_aux_oasisbr_broken_entities_final_entity_id ON aux_oasisbr_broken_entities (final_entity_id);


-- create table with entities x semanticids mappings (lattes only) based source entities of lattes provenance and corresponding to the broken entities
-- the idea is to find the right lattes ids for the broken entities based on lattes sources entities as trusted source for that identifier 
create table aux_oasisbr_source_entity_semantic_id_not_oasis as


-- create table subset of source_entity_semantic_identifier with lattes semantic ids only from lattes provenance only, add final_entity_id also 
-- only considering broken entities
create table aux_oasisbr_source_entity_semantic_identifier_lattes_provenance_lattes as 
select sesi.*, se.final_entity_id
from semantic_identifier si, source_entity_semantic_identifier sesi, source_entity se, aux_oasisbr_provenance_lattes p, aux_oasisbr_broken_entities obe 
WHERE si.semantic_id LIKE 'lattes%' and si.id = sesi.semantic_id and se.uuid = sesi.entity_id 
and se.provenance_id = p.provenance_id and se.final_entity_id = obe.final_entity_id;


-- eliminar los mapeos entre semantic identifier y entity correspondientes a broken entities solo para id lattes (elimina todos los multiples)
DELETE FROM entity_semantic_identifier esi
USING aux_oasisbr_broken_entities aobe, semantic_identifier si
WHERE esi.entity_id = aobe.final_entity_id
  AND si.id = esi.semantic_id
  AND si.semantic_id LIKE 'lattes%';

-- insertar los mapeos correctos para las broken entities usando los lattes correctos provenientes de lattes provenance 
INSERT INTO entity_semantic_identifier (entity_id, semantic_id)
SELECT DISTINCT final_entity_id, semantic_id
FROM aux_oasisbr_source_entity_semantic_identifier_lattes_provenance;

-- marcar las broken entities como dirty
UPDATE entity e
SET dirty = true
FROM aux_oasisbr_broken_entities aobe
WHERE e."uuid" = aobe.final_entity_id;

-- create a table with the records ids to be reloaded after marking problematic source entities as deleted
create table aux_to_be_reloaded_oasisbr_records as
select distinct record_id
from aux_oasisbr_source_entities_from_oasis aose, aux_oasisbr_provenance_oasis aopo, source_entity se  
where aose.source_entity_id = se."uuid" and aopo.provenance_id = se.provenance_id;

-- mark oasisbr source entities identified as problematic (dual lattes ids)
UPDATE source_entity se
SET deleted = true
FROM aux_oasisbr_source_entities_from_oasis aose
WHERE aose.source_entity_id = se."uuid";

-- crear una tabla con las entidades que aun tienes más de un lattes como semantic id (casos de multiples lattes que no vienen de oasisbr)
create table aux_diagnose_multiple_lattes_entities as
select sesi.entity_id
from entity_semantic_identifier sesi, semantic_identifier si 
where sesi.semantic_id = si.id and si.semantic_id like 'lattes%'
group by sesi.entity_id
having count(*) > 1;




