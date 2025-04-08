-- Criação de índices para o campo source_id na tabela provenance para melhorar o desempenho das consultas
CREATE INDEX provenance_source_id_idx ON public.provenance (source_id);
CREATE UNIQUE INDEX provenance_id_idx ON public.provenance (id,source_id);
CREATE INDEX idx_source_entity_provenance_id ON source_entity (provenance_id);
CREATE INDEX idx_semantic_identifier_semantic_id_pattern ON public.semantic_identifier (semantic_id text_pattern_ops);

-- Tabela auxiliar para identificar as procedências do oasisbr
-- Armazena os IDs de procedência e o record_id correspondente
create table aux_oasisbr_provenance_oasis as
select p.id as provenance_id, p.record_id
from provenance p 
where p.source_id = 'oasisbr';

CREATE UNIQUE INDEX aux_oasisbr_provenance_oasis_id_idx ON public.aux_oasisbr_provenance_oasis (provenance_id);

-- Tabela auxiliar para identificar as procedências do Lattes
-- Armazena os IDs de procedência do Lattes para uso posterior
create table aux_oasisbr_provenance_lattes as
select p.id as provenance_id
from provenance p 
where p.source_id = 'lattes';

CREATE UNIQUE INDEX aux_oasisbr_provenance_lattes_id_idx ON public.aux_oasisbr_provenance_lattes (provenance_id);

-- Criação de tabela temporária para armazenar as entidades fonte correspondentes às procedências do oasisbr
-- Isso permite rastrear entidades fonte que precisam ser corrigidas
create table aux_oasisbr_source_entities_from_oasis as
SELECT se."uuid" as source_entity_id, final_entity_id  
FROM source_entity se, aux_oasisbr_provenance_oasis aop 
where se.provenance_id = aop.provenance_id and se.deleted = false and se.entity_type_id = 15;

-- Criação de índices para a tabela auxiliar aux_oasisbr_source_entities_from_oasis para otimização
CREATE INDEX aux_oasisbr_source_entities_source_entity_id_idx ON public.aux_oasisbr_source_entities_from_oasis (source_entity_id);
CREATE INDEX aux_oasisbr_source_entities_final_entity_id_idx ON public.aux_oasisbr_source_entities_from_oasis (final_entity_id);

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

-- Criação de tabela com entidades a serem corrigidas
-- Identifica as entidades finais que correspondem às entidades fonte do oasisbr com múltiplos IDs Lattes
create table aux_oasisbr_broken_entities as 
select distinct final_entity_id from aux_oasisbr_source_entities_from_oasis aose;

CREATE INDEX idx_aux_oasisbr_broken_entities_final_entity_id ON aux_oasisbr_broken_entities (final_entity_id);


-- Criação de tabela com subconjunto de source_entity_semantic_identifier com IDs semânticos Lattes
-- apenas da procedência Lattes, incluindo o final_entity_id
-- Considerando apenas entidades com problemas identificadas anteriormente
create table aux_oasisbr_source_entity_semantic_identifier_lattes_provenance_lattes as 
select sesi.*, se.final_entity_id
from semantic_identifier si, source_entity_semantic_identifier sesi, source_entity se, aux_oasisbr_provenance_lattes p, aux_oasisbr_broken_entities obe 
WHERE si.semantic_id LIKE 'lattes%' and si.id = sesi.semantic_id and se.uuid = sesi.entity_id 
and se.provenance_id = p.provenance_id and se.final_entity_id = obe.final_entity_id;

-- Remoção dos mapeamentos entre identificador semântico e entidade correspondentes às entidades com problemas
-- Remove apenas para IDs Lattes (elimina todos os mapeamentos múltiplos)
DELETE FROM entity_semantic_identifier esi
USING aux_oasisbr_broken_entities aobe, semantic_identifier si
WHERE esi.entity_id = aobe.final_entity_id
  AND si.id = esi.semantic_id
  AND si.semantic_id LIKE 'lattes%';

-- Inserção dos mapeamentos corretos para as entidades com problemas
-- Usa os IDs Lattes corretos provenientes da procedência Lattes
INSERT INTO entity_semantic_identifier (entity_id, semantic_id)
SELECT DISTINCT final_entity_id, semantic_id
FROM aux_oasisbr_source_entity_semantic_identifier_lattes_provenance;

-- Marcação das entidades com problemas como "dirty" para reprocessamento
-- Isso garante que as entidades serão reprocessadas com os dados corretos
UPDATE entity e
SET dirty = true
FROM aux_oasisbr_broken_entities aobe
WHERE e."uuid" = aobe.final_entity_id;


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

-- Criação de tabela para diagnóstico de entidades que ainda possuem mais de um Lattes como identificador semântico
-- Identifica casos de múltiplos IDs Lattes que não vêm do oasisbr e podem precisar de correções adicionais
create table aux_diagnose_multiple_lattes_entities as
select sesi.entity_id
from entity_semantic_identifier sesi, semantic_identifier si 
where sesi.semantic_id = si.id and si.semantic_id like 'lattes%'
group by sesi.entity_id
having count(*) > 1;

-- -----------------------------------------------------------------------------------------------------------------
-- IMPORTANTE: Após executar todas as consultas acima, é necessário executar o Passo 11 de merge das entidades
-- Este passo realiza a fusão das entidades marcadas como "dirty" e reprocessa suas relações e campos
-- Pode ser executado através do script Python similar ao usado em orcid:
--   python3 brcris_fix/orcid/scripts/step11_merge_entities.py
-- O script executa o procedimento SQL "execute_complete_merge_process()" que faz o merge completo das entidades
-- Isso garante que todas as correções sejam aplicadas corretamente e que as entidades fiquem consistentes no sistema
-- -----------------------------------------------------------------------------------------------------------------




