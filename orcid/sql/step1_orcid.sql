-- PASO 1 - CREAR Y LLENAR LA TABLA DE IDENTIFICADORES ORCID INCORRECTOS

-- Crear la tabla para almacenar los identificadores semánticos incorrectos
CREATE TABLE IF NOT EXISTS public.wrong_orcid_semantic_identifier (
    id int8 NOT NULL,
    semantic_id text NULL,
    new_id int8 NULL, 
    new_semantic_id text NULL,
    
    CONSTRAINT wo_semantic_identifier_pkey PRIMARY KEY (id)
);

-- Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_wrong_orcid_semantic_identifier_id ON public.wrong_orcid_semantic_identifier (id);
CREATE INDEX IF NOT EXISTS idx_wrong_orcid_semantic_identifier_semantic_id ON public.wrong_orcid_semantic_identifier (semantic_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_wrong_orcid_semantic_identifier_new_id ON public.wrong_orcid_semantic_identifier (new_id) WHERE new_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_wrong_orcid_semantic_identifier_new_semantic_id ON public.wrong_orcid_semantic_identifier (new_semantic_id);

-- Insertar los identificadores ORCID incorrectos
INSERT INTO wrong_orcid_semantic_identifier 
(SELECT id, semantic_id, NULL, replace(semantic_id, 'https://orcid.org/', '')
 FROM public.semantic_identifier
 WHERE semantic_id LIKE 'orcid::https%' 
 AND NOT EXISTS (
     SELECT 1 FROM wrong_orcid_semantic_identifier w WHERE w.id = semantic_identifier.id
 ));
