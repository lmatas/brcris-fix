-- PASO 3 - INSERTAR LOS NUEVOS IDENTIFICADORES SEMÁNTICOS CORREGIDOS

-- Insertar los nuevos identificadores ORCID normalizados en la tabla semantic_identifier
INSERT INTO semantic_identifier (id, semantic_id)
SELECT DISTINCT w.new_id, w.new_semantic_id
FROM wrong_orcid_semantic_identifier w
WHERE w.new_id IS NOT NULL
  AND w.new_semantic_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 
      FROM semantic_identifier s 
      WHERE s.id = w.new_id
  );