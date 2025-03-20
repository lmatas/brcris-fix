-- PASO 2 - ACTUALIZAR LOS REGISTROS CON LOS NUEVOS HASHES

-- Este archivo está vacío ya que el proceso de generación de hash se realiza en Python
-- debido a la necesidad de utilizar la función xxhash64 que no está disponible de forma nativa en PostgreSQL.
-- El script de Python correspondiente se encargará de:
-- 1. Leer los registros de wrong_orcid_semantic_identifier que no tienen hash
-- 2. Calcular el hash XXHash64 para cada identificador normalizado
-- 3. Actualizar los registros con estos nuevos valores hash