-- =============================================================================
-- SECCIÓN 1: HABILITACIÓN DE RESTRICCIONES DE CLAVE EXTERNA (FKs)
-- -----------------------------------------------------------------------------
-- Se reactivan las FKs que fueron desactivadas temporalmente.
-- Es crucial que los nombres de columna (ej. entity_uuid, field_id)
-- y las tablas/columnas referenciadas (ej. public.entity(uuid))
-- coincidan exactamente con el esquema de la base de datos.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Subsección 1.1: Habilitar FKs que apuntan a la tabla 'public.entity'
-- -----------------------------------------------------------------------------
ALTER TABLE public.entity_semantic_identifier ADD CONSTRAINT fkinjr1aqio6tuon2ypi6ixd4ao FOREIGN KEY (entity_uuid) REFERENCES public.entity(uuid);
ALTER TABLE public.relation ADD CONSTRAINT fk9kavjxgi0tpvju15iab7petiw FOREIGN KEY (entityfrom_uuid) REFERENCES public.entity(uuid);
ALTER TABLE public.relation ADD CONSTRAINT fk9wvqikvahl1a0x1xkcfdw42n FOREIGN KEY (entityto_uuid) REFERENCES public.entity(uuid);
ALTER TABLE public.relation_fieldoccr ADD CONSTRAINT relation_fieldoccr_entityfrom_uuid_fk FOREIGN KEY (entityfrom_uuid) REFERENCES public.entity(uuid);
ALTER TABLE public.relation_fieldoccr ADD CONSTRAINT relation_fieldoccr_entityto_uuid_fk FOREIGN KEY (entityto_uuid) REFERENCES public.entity(uuid);
ALTER TABLE public.entity_fieldoccr ADD CONSTRAINT fkg85y6bnncn3q9y762wvrwj08u FOREIGN KEY (entity_uuid) REFERENCES public.entity(uuid);

-- -----------------------------------------------------------------------------
-- Subsección 1.2: Habilitar FKs adicionales en 'entity_fieldoccr', 'relation', y 'relation_fieldoccr'
-- -----------------------------------------------------------------------------
-- Para la tabla 'public.entity_fieldoccr':
-- Nota: Si 'fk_entity_fieldoccr_field_id' era un nombre genérico para una FK existente con otro nombre,
-- este comando podría fallar o crear una FK duplicada si la original no fue eliminada por su nombre específico.
-- Asumimos que los nombres en turnoff.sql son los nombres reales o los únicos que se intentaron eliminar.
ALTER TABLE public.entity_fieldoccr ADD CONSTRAINT fk_entity_fieldoccr_field_id FOREIGN KEY (field_id) REFERENCES public.field(id);
ALTER TABLE public.entity_fieldoccr ADD CONSTRAINT fk_entity_fieldoccr_field_value_id FOREIGN KEY (field_value_id) REFERENCES public.field_value(id);
ALTER TABLE public.entity_fieldoccr ADD CONSTRAINT fkcnvu6hyt4mihaxjsejgmhu15r FOREIGN KEY (fieldoccr_id) REFERENCES public.field_occurrence(id);

-- Para la tabla 'public.relation':
-- Se restaura la FK específica 'fks2nk3th0n2lygksxkloek4gd1'.
-- Si 'fk_relation_relation_type_id' y 'fk_relation_field_id' eran nombres genéricos para FKs
-- que también tenían nombres específicos eliminados en turnoff.sql, asegúrate de restaurar
-- solo la FK con el nombre correcto para evitar duplicados o errores.
-- Aquí se asume que 'fks2nk3th0n2lygksxkloek4gd1' es la FK correcta para relation_type_id.
-- Si 'fk_relation_relation_type_id' era una FK distinta, debe añadirse también.
-- Basado en el script turnoff, parece que fks2nk3th0n2lygksxkloek4gd1 es la FK real para relation_type.
ALTER TABLE public.relation ADD CONSTRAINT fks2nk3th0n2lygksxkloek4gd1 FOREIGN KEY (relation_type_id) REFERENCES public.relation_type(id);
ALTER TABLE public.relation ADD CONSTRAINT fk_relation_field_id FOREIGN KEY (field_id) REFERENCES public.field(id);
-- Si 'fk_relation_relation_type_id' era una restricción separada y válida con ese nombre, añádela:
-- ALTER TABLE public.relation ADD CONSTRAINT fk_relation_relation_type_id FOREIGN KEY (relation_type_id) REFERENCES public.relation_type(id);
-- Sin embargo, es más probable que 'fks2nk3th0n2lygksxkloek4gd1' sea el nombre DDL de la FK a relation_type.

-- Para la tabla 'public.relation_fieldoccr':
ALTER TABLE public.relation_fieldoccr ADD CONSTRAINT fk9fdsesc6ey8c831brij4u1rob FOREIGN KEY (fieldoccr_id) REFERENCES public.field_occurrence(id);

-- -----------------------------------------------------------------------------
-- Subsección 1.3: Habilitar FKs que apuntan a la tabla 'public.source_entity'
-- -----------------------------------------------------------------------------
ALTER TABLE public.source_entity_semantic_identifier ADD CONSTRAINT fkequg2xow14h1xdkde3c2q92o0 FOREIGN KEY (source_entity_uuid) REFERENCES public.source_entity(uuid);
ALTER TABLE public.source_relation ADD CONSTRAINT fka85ljpk6ps09u8nya2pvpfgvk FOREIGN KEY (source_entityfrom_uuid) REFERENCES public.source_entity(uuid);
ALTER TABLE public.source_relation ADD CONSTRAINT fkirpb50vicfsbg28olx4snn39s FOREIGN KEY (source_entityto_uuid) REFERENCES public.source_entity(uuid);
ALTER TABLE public.source_relation_fieldoccr ADD CONSTRAINT source_relation_fieldoccr_source_entityfrom_uuid_fk FOREIGN KEY (source_entityfrom_uuid) REFERENCES public.source_entity(uuid);
ALTER TABLE public.source_relation_fieldoccr ADD CONSTRAINT source_relation_fieldoccr_source_entityto_uuid_fk FOREIGN KEY (source_entityto_uuid) REFERENCES public.source_entity(uuid);
ALTER TABLE public.source_entity_fieldoccr ADD CONSTRAINT fk2f3wc4b3huh74134hloikiou7 FOREIGN KEY (source_entity_uuid) REFERENCES public.source_entity(uuid);

-- -----------------------------------------------------------------------------
-- Subsección 1.4: Habilitar FKs que apuntan a la tabla 'public.source_relation'
-- -----------------------------------------------------------------------------
ALTER TABLE public.source_relation_fieldoccr ADD CONSTRAINT fkntrxgvqcjsy3w7nb8xxcauh84 FOREIGN KEY (source_relation_uuid) REFERENCES public.source_relation(uuid);

-- =============================================================================
-- FIN DEL SCRIPT DE HABILITACIÓN DE FKs
-- =============================================================================
