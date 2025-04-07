-- create indexes for provenance on source_id field
CREATE INDEX provenance_source_id_idx ON public.provenance (source_id);

-- create a temporary table to store source_entity corresponding to oasisbr provenance
create table aux_oasisbr_source_entities as
SELECT se."uuid" as source_entity_id, final_entity_id  
FROM provenance p, source_entity se 
where p.source_id = 'oasisbr' and se.provenance_id = p.id and se.deleted = false;

-- create indexes for the aux_oasisbr_source_entities table
CREATE INDEX aux_oasisbr_source_entities_source_entity_id_idx ON public.aux_oasisbr_source_entities (source_entity_id);
CREATE INDEX aux_oasisbr_source_entities_final_entity_id_idx ON public.aux_oasisbr_source_entities (final_entity_id);

-- create a temporary table to store sourcesemantic_identifier corresponding to oasisbr provenance with more that one semantic_id of brcris type 
create table aux_oasis_brcris_count as
select aose.source_entity_id, count(*) as size
from aux_oasisbr_source_entities aose, source_entity_semantic_identifier sesi, semantic_identifier si 
where aose.source_entity_id = sesi.entity_id and sesi.semantic_id = si.id and si.semantic_id like 'brcris%'
group by aose.source_entity_id
having count(*) > 1

-- count the number of source_entity with more that one semantic_id of brcris type
select count(*) from aux_oasis_brcris_count aobc  
-- resultado 263604