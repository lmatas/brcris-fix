-- Remoção dos mapeamentos entre identificador semântico e entidade correspondentes às entidades com problemas
-- Remove apenas para IDs Lattes (elimina todos os mapeamentos múltiplos)
DELETE FROM entity_semantic_identifier esi
USING aux_oasisbr_broken_entities aobe, semantic_identifier si
WHERE esi.entity_id = aobe.final_entity_id
  AND si.id = esi.semantic_id
  AND si.semantic_id LIKE 'lattes%';

-- Inserção dos mapeamentos corretos para as entidades com problemas
-- Usa os IDs Lattes corretos provenientes da procedência Lattes
INSERT INTO entity_semantic_identifier (entity_id, semantic_id)
SELECT DISTINCT final_entity_id, semantic_id
FROM aux_oasisbr_source_entity_semantic_identifier_lattes_provenance_lattes; -- Corrected table name