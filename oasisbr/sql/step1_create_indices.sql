-- Criação de índices para o campo source_id na tabela provenance para melhorar o desempenho das consultas
CREATE INDEX provenance_source_id_idx ON public.provenance (source_id);
CREATE UNIQUE INDEX provenance_id_idx ON public.provenance (id,source_id);
CREATE INDEX idx_source_entity_provenance_id ON source_entity (provenance_id);
CREATE INDEX idx_semantic_identifier_semantic_id_pattern ON public.semantic_identifier (semantic_id text_pattern_ops);