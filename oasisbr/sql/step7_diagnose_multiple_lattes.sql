-- Criação de tabela para diagnóstico de entidades que ainda possuem mais de um Lattes como identificador semântico
-- Identifica casos de múltiplos IDs Lattes que não vêm do oasisbr e podem precisar de correções adicionais
create table aux_diagnose_multiple_lattes_entities as
select sesi.entity_id
from entity_semantic_identifier sesi, semantic_identifier si 
where sesi.semantic_id = si.id and si.semantic_id like 'lattes%'
group by sesi.entity_id
having count(*) > 1;