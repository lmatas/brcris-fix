-- =============================================================================
-- SECCIÓN 1: DESHABILITACIÓN DE RESTRICCIONES DE CLAVE EXTERNA (FKs)
-- -----------------------------------------------------------------------------
-- Se desactivan temporalmente varias FKs para evitar errores de integridad
-- referencial durante las operaciones de eliminación masiva y para acelerar
-- dichas operaciones.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Subsección 1.1: Deshabilitar FKs que apuntan a la tabla 'public.entity'
-- -----------------------------------------------------------------------------
-- Estas FKs se encuentran en tablas que referencian directamente a 'public.entity'.
ALTER TABLE public.entity_semantic_identifier DROP CONSTRAINT IF EXISTS fkinjr1aqio6tuon2ypi6ixd4ao;
ALTER TABLE public.relation DROP CONSTRAINT IF EXISTS fk9kavjxgi0tpvju15iab7petiw;
ALTER TABLE public.relation DROP CONSTRAINT IF EXISTS fk9wvqikvahl1a0x1xkcfdw42n;
ALTER TABLE public.relation_fieldoccr DROP CONSTRAINT IF EXISTS relation_fieldoccr_entityfrom_uuid_fk;
ALTER TABLE public.relation_fieldoccr DROP CONSTRAINT IF EXISTS relation_fieldoccr_entityto_uuid_fk;
ALTER TABLE public.entity_fieldoccr DROP CONSTRAINT IF EXISTS fkg85y6bnncn3q9y762wvrwj08u;

-- -----------------------------------------------------------------------------
-- Subsección 1.2: Deshabilitar FKs adicionales en 'entity_fieldoccr', 'relation', y 'relation_fieldoccr'
-- -----------------------------------------------------------------------------
-- Estas FKs apuntan a otras tablas como 'field_occurrence', 'relation_type', etc.
-- y también se desactivan para facilitar operaciones de limpieza o carga.
-- Algunas restricciones usan nombres genéricos (ej: fk_entity_fieldoccr_field_id)
-- si sus nombres exactos del DDL no estaban disponibles o para cubrir variantes.

-- Para la tabla 'public.entity_fieldoccr':
ALTER TABLE public.entity_fieldoccr DROP CONSTRAINT IF EXISTS fk_entity_fieldoccr_field_id; -- FK genérica a field(id)
ALTER TABLE public.entity_fieldoccr DROP CONSTRAINT IF EXISTS fk_entity_fieldoccr_field_value_id; -- FK genérica a field_value(id)
ALTER TABLE public.entity_fieldoccr DROP CONSTRAINT IF EXISTS fkcnvu6hyt4mihaxjsejgmhu15r; -- FK específica desde entity_fieldoccr.fieldoccr_id a field_occurrence(id)

-- Para la tabla 'public.relation':
ALTER TABLE public.relation DROP CONSTRAINT IF EXISTS fk_relation_relation_type_id; -- FK genérica a relation_type(id)
ALTER TABLE public.relation DROP CONSTRAINT IF EXISTS fk_relation_field_id; -- FK genérica a field(id)
ALTER TABLE public.relation DROP CONSTRAINT IF EXISTS fks2nk3th0n2lygksxkloek4gd1; -- FK específica a relation_type(id)

-- Para la tabla 'public.relation_fieldoccr':
ALTER TABLE public.relation_fieldoccr DROP CONSTRAINT IF EXISTS fk9fdsesc6ey8c831brij4u1rob; -- FK específica desde relation_fieldoccr.fieldoccr_id a field_occurrence(id)

-- -----------------------------------------------------------------------------
-- Subsección 1.3: Deshabilitar FKs que apuntan a la tabla 'public.source_entity'
-- -----------------------------------------------------------------------------
-- Estas FKs se encuentran en tablas que referencian directamente a 'public.source_entity'.
ALTER TABLE public.source_entity_semantic_identifier DROP CONSTRAINT IF EXISTS fkequg2xow14h1xdkde3c2q92o0;
ALTER TABLE public.source_relation DROP CONSTRAINT IF EXISTS fka85ljpk6ps09u8nya2pvpfgvk; -- Corregido del DDL
ALTER TABLE public.source_relation DROP CONSTRAINT IF EXISTS fkirpb50vicfsbg28olx4snn39s; -- Corregido del DDL
ALTER TABLE public.source_relation_fieldoccr DROP CONSTRAINT IF EXISTS source_relation_fieldoccr_source_entityfrom_uuid_fk;
ALTER TABLE public.source_relation_fieldoccr DROP CONSTRAINT IF EXISTS source_relation_fieldoccr_source_entityto_uuid_fk;
ALTER TABLE public.source_entity_fieldoccr DROP CONSTRAINT IF EXISTS fk2f3wc4b3huh74134hloikiou7;

-- -----------------------------------------------------------------------------
-- Subsección 1.4: Deshabilitar FKs que apuntan a la tabla 'public.source_relation'
-- -----------------------------------------------------------------------------
-- Estas FKs dependen de 'public.source_relation' y, por ende, indirectamente de 'public.source_entity'.
ALTER TABLE public.source_relation_fieldoccr DROP CONSTRAINT IF EXISTS fkntrxgvqcjsy3w7nb8xxcauh84;
