-- Poblar la tabla aux_valid_orgunit con los UUIDs de las entidades OrgUnit válidas
INSERT INTO aux_valid_orgunit (uuid) -- Especificar columna de destino
SELECT DISTINCT e.uuid
FROM aux_valid_orgunit_semantic_id vosi -- Usar el nombre de tabla correcto con prefijo aux_
JOIN entity_semantic_identifier esi ON vosi.id = esi.semantic_id -- Unir directamente usando el ID (hash)
JOIN entity e ON esi.entity_id = e.uuid
WHERE e.entity_type_id = 1; -- Filtrar por tipo de entidad OrgUnit

-- Poblar la tabla aux_invalid_source_orgunit con los UUIDs de las source_entity OrgUnit inválidas
INSERT INTO aux_invalid_source_orgunit (source_entity_uuid)
SELECT se.uuid
FROM source_entity se
WHERE se.entity_type_id = 1 -- Seleccionar solo source_entity de tipo OrgUnit
  AND NOT EXISTS ( -- Verificar que el final_entity_id NO esté en la tabla de orgunits válidas
      SELECT 1
      FROM aux_valid_orgunit avo
      WHERE avo.uuid = se.final_entity_id
  );

-- Poblar la tabla aux_invalid_orgunit con los UUIDs de las entidades OrgUnit inválidas
INSERT INTO aux_invalid_orgunit (uuid)
SELECT e.uuid
FROM entity e
WHERE e.entity_type_id = 1 -- Seleccionar solo entidades de tipo OrgUnit
  AND NOT EXISTS ( -- Verificar que el UUID de la entidad NO esté en la tabla de orgunits válidas
      SELECT 1
      FROM aux_valid_orgunit avo
      WHERE avo.uuid = e.uuid
  );
