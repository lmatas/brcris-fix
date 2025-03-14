-- =====================================================
-- CREACIÓN DE TABLA PARA RASTREO DE CORRECCIONES
-- =====================================================

-- Tabla para almacenar las correspondencias entre entidades con ORCID incorrecto y sus correcciones
CREATE TABLE public.wrong_orcid_entity_correction (
    old_entity_id uuid NOT NULL,                -- ID de la entidad con ORCID incorrecto
    new_entity_id uuid NOT NULL,                -- ID de la entidad con ORCID correcto (existente o creada)
    old_semantic_id int8 NOT NULL,              -- ID semántico antiguo (incorrecto)
    new_semantic_id int8 NOT NULL,              -- ID semántico nuevo (correcto)
    entity_created boolean NOT NULL DEFAULT false, -- True si se tuvo que crear una nueva entidad
    CONSTRAINT wrong_orcid_entity_correction_pkey PRIMARY KEY (old_entity_id),
    CONSTRAINT fk_old_entity FOREIGN KEY (old_entity_id) REFERENCES public.entity(uuid),
    CONSTRAINT fk_new_entity FOREIGN KEY (new_entity_id) REFERENCES public.entity(uuid)
);

-- Crear índices para mejorar rendimiento
CREATE INDEX wrong_orcid_entity_correction_new_entity_id_idx ON public.wrong_orcid_entity_correction(new_entity_id);
CREATE INDEX wrong_orcid_entity_correction_old_semantic_id_idx ON public.wrong_orcid_entity_correction(old_semantic_id);
CREATE INDEX wrong_orcid_entity_correction_new_semantic_id_idx ON public.wrong_orcid_entity_correction(new_semantic_id);
