-- Indices para acelerar las queries
CREATE INDEX IF NOT EXISTS ssi_entity_id ON public.source_entity_semantic_identifier(entity_id);
CREATE INDEX IF NOT EXISTS ssi_semantic_id ON public.source_entity_semantic_identifier(semantic_id);

-- Crear una tabla para guardar la información de las entidades y sus identificadores
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