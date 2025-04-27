-- Limpeza da tabela aux_oasisbr_source_entities_from_oasis
-- Filtra apenas entidades com mais de 1 identificador Lattes, que são as que apresentam problemas
delete from aux_oasisbr_source_entities_from_oasis aose
where not exists 
	(select 1
	from source_entity_semantic_identifier sesi, semantic_identifier si 
	where aose.source_entity_id = sesi.entity_id and sesi.semantic_id = si.id and si.semantic_id like 'lattes%'
	group by sesi.entity_id
	having count(*) > 1
	);