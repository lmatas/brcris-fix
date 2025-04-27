-- ====================================================
-- Create Indices for Step 5 Deletion Performance
-- ====================================================

-- Indices for source entity related tables
-- Corregido: Cambiado source_entity_id a entity_id y renombrado el índice
CREATE INDEX IF NOT EXISTS idx_source_entity_fieldoccr_entity_id ON public.source_entity_fieldoccr (entity_id);
-- Corregido: Cambiado from_source_entity_id a from_entity_id y renombrado el índice
CREATE INDEX IF NOT EXISTS idx_source_relation_fieldoccr_from_entity_id ON public.source_relation_fieldoccr (from_entity_id);
-- Corregido: Cambiado to_source_entity_id a to_entity_id y renombrado el índice
CREATE INDEX IF NOT EXISTS idx_source_relation_fieldoccr_to_entity_id ON public.source_relation_fieldoccr (to_entity_id);
-- Corregido: Cambiado from_source_entity_id a from_entity_id y renombrado el índice
CREATE INDEX IF NOT EXISTS idx_source_relation_from_entity_id ON public.source_relation (from_entity_id);
-- Corregido: Cambiado to_source_entity_id a to_entity_id y renombrado el índice
CREATE INDEX IF NOT EXISTS idx_source_relation_to_entity_id ON public.source_relation (to_entity_id);
CREATE INDEX IF NOT EXISTS idx_source_entity_semantic_identifier_entity_id ON public.source_entity_semantic_identifier (entity_id);
CREATE INDEX IF NOT EXISTS idx_source_entity_semantic_identifier_semantic_id ON public.source_entity_semantic_identifier (semantic_id); -- Added for ORCID script performance
CREATE INDEX IF NOT EXISTS idx_sesi_entity_id_semantic_id ON public.source_entity_semantic_identifier (entity_id, semantic_id); -- Added for ORCID script performance (composite)
CREATE INDEX IF NOT EXISTS idx_source_entity_entity_type_id ON public.source_entity (entity_type_id); -- Useful for the final DELETE

-- Indices for entity related tables
CREATE INDEX IF NOT EXISTS idx_relation_fieldoccr_from_entity_id ON public.relation_fieldoccr (from_entity_id);
CREATE INDEX IF NOT EXISTS idx_relation_fieldoccr_to_entity_id ON public.relation_fieldoccr (to_entity_id);
CREATE INDEX IF NOT EXISTS idx_relation_from_entity_id ON public.relation (from_entity_id);
CREATE INDEX IF NOT EXISTS idx_relation_to_entity_id ON public.relation (to_entity_id);
CREATE INDEX IF NOT EXISTS idx_entity_fieldoccr_entity_id ON public.entity_fieldoccr (entity_id);
CREATE INDEX IF NOT EXISTS idx_entity_semantic_identifier_entity_id ON public.entity_semantic_identifier (entity_id);
CREATE INDEX IF NOT EXISTS idx_entity_semantic_identifier_semantic_id ON public.entity_semantic_identifier (semantic_id); -- Added for ORCID script performance
CREATE INDEX IF NOT EXISTS idx_entity_entity_type_id ON public.entity (entity_type_id); -- Useful for the final DELETE

-- Nota: Los índices en las columnas UUID (claves primarias) generalmente ya existen.
-- Estos índices adicionales se centran en las claves foráneas y columnas usadas en WHERE.
-- El uso de 'IF NOT EXISTS' evita errores si los índices ya fueron creados.
-- Se añadieron índices en columnas semantic_id para optimizar scripts específicos como el de ORCID.
