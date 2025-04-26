-- ====================================================
-- Step 7: Restore Database Constraints
-- ====================================================

-- Constraints en ENTITY_FIELDOCCR
ALTER TABLE public.entity_fieldoccr
    ADD CONSTRAINT fkg85y6bnncn3q9y762wvrwj08u
    FOREIGN KEY (entity_id) REFERENCES public.entity(uuid) ON DELETE CASCADE;

ALTER TABLE public.entity_fieldoccr
    ADD CONSTRAINT fkaqxlq6pqglkl32ub46do5akpl
    FOREIGN KEY (fieldoccr_id) REFERENCES public.field_occurrence(id);

-- Constraints en ENTITY_SEMANTIC_IDENTIFIER
ALTER TABLE public.entity_semantic_identifier
    ADD CONSTRAINT fkinjr1aqio6tuon2ypi6ixd4ao
    FOREIGN KEY (entity_id) REFERENCES public.entity(uuid) ON DELETE CASCADE;

-- Constraints en RELATION
ALTER TABLE public.relation
    ADD CONSTRAINT fk9kavjxgi0tpvju15iab7petiw
    FOREIGN KEY (from_entity_id) REFERENCES public.entity(uuid) ON DELETE CASCADE;

ALTER TABLE public.relation
    ADD CONSTRAINT fk9wvqikvahl1a0x1xkcfdw42n
    FOREIGN KEY (to_entity_id) REFERENCES public.entity(uuid) ON DELETE CASCADE;

ALTER TABLE public.relation
    ADD CONSTRAINT fkgocmghsla07rat51y3w39n9tk
    FOREIGN KEY (relation_type_id) REFERENCES public.relation_type(id);

-- Constraints en RELATION_FIELDOCCR
ALTER TABLE public.relation_fieldoccr
    ADD CONSTRAINT relation_fieldoccr_entityfrom_uuid_fk
    FOREIGN KEY (from_entity_id) REFERENCES public.entity(uuid) ON DELETE CASCADE;

ALTER TABLE public.relation_fieldoccr
    ADD CONSTRAINT relation_fieldoccr_entityto_uuid_fk
    FOREIGN KEY (to_entity_id) REFERENCES public.entity(uuid) ON DELETE CASCADE;

ALTER TABLE public.relation_fieldoccr
    ADD CONSTRAINT fkjottc07w9a00w4ta9u48br53m -- Nombre original, verificar si es correcto
    FOREIGN KEY (relation_id) REFERENCES public.relation(id);

ALTER TABLE public.relation_fieldoccr
    ADD CONSTRAINT relation_fieldoccr_fieldoccr_id_fk
    FOREIGN KEY (fieldoccr_id) REFERENCES public.field_occurrence(id);

ALTER TABLE public.relation_fieldoccr
    ADD CONSTRAINT relation_fieldoccr_relation_type_id_fk
    FOREIGN KEY (relation_type_id) REFERENCES public.relation_type(id);

-- Constraints en SOURCE_ENTITY
ALTER TABLE public.source_entity
    ADD CONSTRAINT fk3obeh2naev2b3gyswvpvw433e
    FOREIGN KEY (final_entity_id) REFERENCES public.entity(uuid); -- Cascade might not be desired here

-- Constraints en SOURCE_ENTITY_FIELDOCCR
ALTER TABLE public.source_entity_fieldoccr
    ADD CONSTRAINT fk2f3wc4b3huh74134hloikiou7
    FOREIGN KEY (entity_id) REFERENCES public.source_entity(uuid) ON DELETE CASCADE;

ALTER TABLE public.source_entity_fieldoccr
    ADD CONSTRAINT fk6w85u7cf1rp9mu9u83lqf1g0c
    FOREIGN KEY (fieldoccr_id) REFERENCES public.field_occurrence(id);

-- Constraints en SOURCE_ENTITY_SEMANTIC_IDENTIFIER
ALTER TABLE public.source_entity_semantic_identifier
    ADD CONSTRAINT fkequg2xow14h1xdkde3c2q92o0
    FOREIGN KEY (entity_id) REFERENCES public.source_entity(uuid) ON DELETE CASCADE;

ALTER TABLE public.source_entity_semantic_identifier
    ADD CONSTRAINT fk9bf1gs0tx86f4eewbws4hkytp
    FOREIGN KEY (semantic_id) REFERENCES public.semantic_identifier(id);

-- Constraints en SOURCE_RELATION
ALTER TABLE public.source_relation
    ADD CONSTRAINT fkpiife6ava2qdk9y42tr4u5bci -- Nombre usado en DDL ORCID
    FOREIGN KEY (from_entity_id) REFERENCES public.source_entity(uuid) ON DELETE CASCADE;

ALTER TABLE public.source_relation
    ADD CONSTRAINT fkirpb50vicfsbg28olx4snn39s -- Nombre usado en DDL ORCID
    FOREIGN KEY (to_entity_id) REFERENCES public.source_entity(uuid) ON DELETE CASCADE;

ALTER TABLE public.source_relation
    ADD CONSTRAINT fk8550j1n0hyug6jgpfmuqaj0e7
    FOREIGN KEY (relation_type_id) REFERENCES public.relation_type(id);

-- Constraints en SOURCE_RELATION_FIELDOCCR
ALTER TABLE public.source_relation_fieldoccr
    ADD CONSTRAINT source_relation_fieldoccr_source_entityfrom_uuid_fk
    FOREIGN KEY (from_entity_id) REFERENCES public.source_entity(uuid) ON DELETE CASCADE;

ALTER TABLE public.source_relation_fieldoccr
    ADD CONSTRAINT source_relation_fieldoccr_source_entityto_uuid_fk
    FOREIGN KEY (to_entity_id) REFERENCES public.source_entity(uuid) ON DELETE CASCADE;

ALTER TABLE public.source_relation_fieldoccr
    ADD CONSTRAINT source_relation_fieldoccr_source_relation_id_fk
    FOREIGN KEY (relation_id) REFERENCES public.source_relation(id);

ALTER TABLE public.source_relation_fieldoccr
    ADD CONSTRAINT source_relation_fieldoccr_fieldoccr_id_fk
    FOREIGN KEY (fieldoccr_id) REFERENCES public.field_occurrence(id);

ALTER TABLE public.source_relation_fieldoccr
    ADD CONSTRAINT source_relation_fieldoccr_relation_type_id_fk
    FOREIGN KEY (relation_type_id) REFERENCES public.relation_type(id);
