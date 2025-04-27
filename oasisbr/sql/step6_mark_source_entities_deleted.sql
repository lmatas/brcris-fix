-- Criação de tabela com os IDs de registros que precisam ser recarregados
-- Após marcar as entidades fonte problemáticas como excluídas
create table aux_to_be_reloaded_oasisbr_records as
select distinct record_id
from aux_oasisbr_source_entities_from_oasis aose, aux_oasisbr_provenance_oasis aopo, source_entity se  
where aose.source_entity_id = se."uuid" and aopo.provenance_id = se.provenance_id;

-- Marcação das entidades fonte do oasisbr identificadas como problemáticas como excluídas
-- Estas são entidades com IDs Lattes duplicados que precisam ser corrigidas
UPDATE source_entity se
SET deleted = true
FROM aux_oasisbr_source_entities_from_oasis aose
WHERE aose.source_entity_id = se."uuid";