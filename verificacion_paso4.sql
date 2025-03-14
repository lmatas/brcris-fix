-- =====================================================
-- CONSULTAS PARA EJECUTAR ANTES DEL PASO 4
-- =====================================================

-- 1. Recuento de referencias a identificadores ORCID incorrectos
SELECT COUNT(*) AS total_referencias_incorrectas
FROM source_entity_semantic_identifier sesi
JOIN wrong_orcid_semantic_identifier w ON sesi.semantic_id = w.id
WHERE w.new_id IS NOT NULL;

-- 2. Muestra ejemplos de referencias que serán modificadas (muestra los primeros 10)
SELECT 
    sesi.entity_id,
    w.id AS id_semantico_antiguo,
    w.new_id AS id_semantico_nuevo
FROM source_entity_semantic_identifier sesi
JOIN wrong_orcid_semantic_identifier w ON sesi.semantic_id = w.id
WHERE w.new_id IS NOT NULL
LIMIT 10;

-- 3. Distribución por tipo de entidad (opcional)
SELECT 
    e.type AS tipo_entidad,
    COUNT(*) AS cantidad_referencias
FROM source_entity_semantic_identifier sesi
JOIN wrong_orcid_semantic_identifier w ON sesi.semantic_id = w.id
JOIN entity e ON sesi.entity_id = e.id
WHERE w.new_id IS NOT NULL
GROUP BY e.type
ORDER BY COUNT(*) DESC;

-- =====================================================
-- CONSULTAS PARA EJECUTAR DESPUÉS DEL PASO 4
-- =====================================================

-- 1. Verifica que no queden referencias a los IDs antiguos
SELECT COUNT(*) AS referencias_pendientes
FROM source_entity_semantic_identifier sesi
JOIN wrong_orcid_semantic_identifier w ON sesi.semantic_id = w.id
WHERE w.new_id IS NOT NULL;

-- 2. Verifica que existan referencias a los IDs nuevos
SELECT 
    COUNT(*) AS referencias_actualizadas
FROM source_entity_semantic_identifier sesi
JOIN wrong_orcid_semantic_identifier w ON sesi.semantic_id = w.new_id
WHERE w.new_id IS NOT NULL;

-- 3. Verifica integridad - Entidades que deberían tener referencias pero no las tienen
WITH entidades_a_actualizar AS (
    SELECT DISTINCT sesi.entity_id
    FROM source_entity_semantic_identifier sesi
    JOIN wrong_orcid_semantic_identifier w ON sesi.semantic_id = w.id
    WHERE w.new_id IS NOT NULL
)
SELECT 
    e.id AS entity_id,
    e.type AS tipo_entidad
FROM entidades_a_actualizar ea
JOIN entity e ON ea.entity_id = e.id
LEFT JOIN source_entity_semantic_identifier sesi ON e.id = sesi.entity_id
JOIN wrong_orcid_semantic_identifier w ON w.new_id = sesi.semantic_id
WHERE sesi.entity_id IS NULL
LIMIT 100;

-- 4. Resumen general del estado final
SELECT 
    'Total referencias actualizadas' AS descripcion,
    COUNT(*) AS cantidad
FROM source_entity_semantic_identifier sesi
JOIN wrong_orcid_semantic_identifier w ON sesi.semantic_id = w.new_id
WHERE w.new_id IS NOT NULL

UNION ALL

SELECT 
    'Referencias pendientes' AS descripcion,
    COUNT(*) AS cantidad
FROM source_entity_semantic_identifier sesi
JOIN wrong_orcid_semantic_identifier w ON sesi.semantic_id = w.id
WHERE w.new_id IS NOT NULL;
