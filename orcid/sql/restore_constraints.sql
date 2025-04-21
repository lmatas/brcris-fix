-- Script para restaurar las constraints potencialmente eliminadas por versiones anteriores
-- del proceso de merge o para asegurar que existen.

DO $$
BEGIN
    RAISE NOTICE 'Iniciando restauración/verificación de constraints...';

    -- Constraints para entity_fieldoccr
    RAISE NOTICE 'Restaurando constraints para entity_fieldoccr...';
    ALTER TABLE entity_fieldoccr
        ADD CONSTRAINT fkg85y6bnncn3q9y762wvrwj08u IF NOT EXISTS
        FOREIGN KEY (entity_id) REFERENCES entity(uuid) ON DELETE CASCADE;

    ALTER TABLE entity_fieldoccr
        ADD CONSTRAINT fkaqxlq6pqglkl32ub46do5akpl IF NOT EXISTS
        FOREIGN KEY (fieldoccr_id) REFERENCES fieldoccr(id);

    -- Constraints para relation
    RAISE NOTICE 'Restaurando constraints para relation...';
    ALTER TABLE relation
        ADD CONSTRAINT fk9kavjxgi0tpvju15iab7petiw IF NOT EXISTS
        FOREIGN KEY (from_entity_id) REFERENCES entity(uuid) ON DELETE CASCADE;

    ALTER TABLE relation
        ADD CONSTRAINT fk9wvqikvahl1a0x1xkcfdw42n IF NOT EXISTS
        FOREIGN KEY (to_entity_id) REFERENCES entity(uuid) ON DELETE CASCADE;

    ALTER TABLE relation
        ADD CONSTRAINT fkgocmghsla07rat51y3w39n9tk IF NOT EXISTS
        FOREIGN KEY (relation_type_id) REFERENCES relation_type(id);

    -- Constraints para relation_fieldoccr
    RAISE NOTICE 'Restaurando constraints para relation_fieldoccr...';
    ALTER TABLE relation_fieldoccr
        ADD CONSTRAINT relation_fieldoccr_entityfrom_uuid_fk IF NOT EXISTS
        FOREIGN KEY (from_entity_id) REFERENCES entity(uuid) ON DELETE CASCADE;

    ALTER TABLE relation_fieldoccr
        ADD CONSTRAINT relation_fieldoccr_entityto_uuid_fk IF NOT EXISTS
        FOREIGN KEY (to_entity_id) REFERENCES entity(uuid) ON DELETE CASCADE;

    ALTER TABLE relation_fieldoccr
        ADD CONSTRAINT relation_fieldoccr_fieldoccr_id_fk IF NOT EXISTS
        FOREIGN KEY (fieldoccr_id) REFERENCES fieldoccr(id);

    ALTER TABLE relation_fieldoccr
        ADD CONSTRAINT relation_fieldoccr_relation_type_id_fk IF NOT EXISTS
        FOREIGN KEY (relation_type_id) REFERENCES relation_type(id);

    RAISE NOTICE 'Restauración/verificación de constraints completada.';

EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Error durante la restauración/verificación de constraints: %', SQLERRM;
    RAISE WARNING 'Es posible que algunas constraints no se hayan restaurado correctamente.';
END;
$$;
