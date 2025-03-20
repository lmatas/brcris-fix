-- PASO 11 - FINALMENTE LLAMAMOS AL PROCEDIMIENTO PARA HACER MERGE DE LOS CAMPOS DE LAS ENTIDADES AFECTADAS Y QUE FUERON MARCADAS COMO DIRTY

-- Ejecutar el procedimiento de merge para actualizar las entidades afectadas
CALL public.merge_entity_relation_data(1);
