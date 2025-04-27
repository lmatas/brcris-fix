-- Marcação das entidades com problemas como "dirty" para reprocessamento
-- Isso garante que as entidades serão reprocessadas com os dados corretos
UPDATE entity e
SET dirty = true
FROM aux_oasisbr_broken_entities aobe
WHERE e."uuid" = aobe.final_entity_id;