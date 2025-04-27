-- Tabela auxiliar para identificar as procedências do oasisbr
-- Armazena os IDs de procedência e o record_id correspondente
DROP TABLE IF EXISTS public.aux_oasisbr_provenance_oasis CASCADE;
create table public.aux_oasisbr_provenance_oasis as
select p.id as provenance_id, p.record_id
from provenance p 
where p.source_id = 'oasisbr';

CREATE UNIQUE INDEX aux_oasisbr_provenance_oasis_id_idx ON public.aux_oasisbr_provenance_oasis (provenance_id);

-- Tabela auxiliar para identificar as procedências do Lattes
-- Armazena os IDs de procedência do Lattes para uso posterior
DROP TABLE IF EXISTS public.aux_oasisbr_provenance_lattes CASCADE;
create table public.aux_oasisbr_provenance_lattes as
select p.id as provenance_id
from provenance p 
where p.source_id = 'lattes';

CREATE UNIQUE INDEX aux_oasisbr_provenance_lattes_id_idx ON public.aux_oasisbr_provenance_lattes (provenance_id);

-- Criação de tabela temporária para armazenar as entidades fonte correspondentes às procedências do oasisbr
-- Isso permite rastrear entidades fonte que precisam ser corrigidas
DROP TABLE IF EXISTS public.aux_oasisbr_source_entities_from_oasis CASCADE;
create table public.aux_oasisbr_source_entities_from_oasis as
SELECT se."uuid" as source_entity_id, final_entity_id  
FROM source_entity se, public.aux_oasisbr_provenance_oasis aop 
where se.provenance_id = aop.provenance_id and se.deleted = false and se.entity_type_id = 15;

-- Criação de índices para a tabela auxiliar aux_oasisbr_source_entities_from_oasis para otimização
CREATE INDEX aux_oasisbr_source_entities_source_entity_id_idx ON public.aux_oasisbr_source_entities_from_oasis (source_entity_id);
CREATE INDEX aux_oasisbr_source_entities_final_entity_id_idx ON public.aux_oasisbr_source_entities_from_oasis (final_entity_id);

-- Criação de tabela com entidades a serem corrigidas
-- Identifica as entidades finais que correspondem às entidades fonte do oasisbr com múltiplos IDs Lattes
DROP TABLE IF EXISTS public.aux_oasisbr_broken_entities CASCADE;
create table public.aux_oasisbr_broken_entities as 
select distinct final_entity_id from public.aux_oasisbr_source_entities_from_oasis aose;

CREATE INDEX idx_aux_oasisbr_broken_entities_final_entity_id ON public.aux_oasisbr_broken_entities (final_entity_id);

-- Criação de tabela com subconjunto de source_entity_semantic_identifier com IDs semânticos Lattes
-- apenas da procedência Lattes, incluindo o final_entity_id
-- Considerando apenas entidades com problemas identificadas anteriormente
DROP TABLE IF EXISTS public.aux_oasisbr_source_entity_semantic_identifier_lattes_provenance_lattes CASCADE;
create table public.aux_oasisbr_source_entity_semantic_identifier_lattes_provenance_lattes as 
select sesi.*, se.final_entity_id
from semantic_identifier si, source_entity_semantic_identifier sesi, source_entity se, public.aux_oasisbr_provenance_lattes p, public.aux_oasisbr_broken_entities obe 
WHERE si.semantic_id LIKE 'lattes%' and si.id = sesi.semantic_id and se.uuid = sesi.entity_id 
and se.provenance_id = p.provenance_id and se.final_entity_id = obe.final_entity_id;

-- Adicionar índices para a nova tabela, se necessário (opcional, mas recomendado para performance)
CREATE INDEX idx_aux_oasisbr_sesi_lattes_prov_lattes_entity_id ON public.aux_oasisbr_source_entity_semantic_identifier_lattes_provenance_lattes (entity_id);
CREATE INDEX idx_aux_oasisbr_sesi_lattes_prov_lattes_final_entity_id ON public.aux_oasisbr_source_entity_semantic_identifier_lattes_provenance_lattes (final_entity_id);
CREATE INDEX idx_aux_oasisbr_sesi_lattes_prov_lattes_semantic_id ON public.aux_oasisbr_source_entity_semantic_identifier_lattes_provenance_lattes (semantic_id);