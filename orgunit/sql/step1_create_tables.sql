DROP TABLE IF EXISTS aux_valid_orgunit_semantic_id;
CREATE TABLE aux_valid_orgunit_semantic_id (
   id int8 NOT NULL,
   semantic_id varchar NOT NULL,
   CONSTRAINT aux_valid_orgunit_semantic_id_pkey PRIMARY KEY (id)
);

DROP TABLE IF EXISTS aux_valid_orgunit;
CREATE TABLE aux_valid_orgunit
(
   uuid uuid NOT NULL,
   CONSTRAINT aux_valid_orgunit_pkey PRIMARY KEY (uuid)
);

DROP TABLE IF EXISTS aux_invalid_source_orgunit;
CREATE TABLE aux_invalid_source_orgunit
(
    source_entity_uuid uuid NOT NULL,
    CONSTRAINT aux_invalid_source_orgunit_pkey PRIMARY KEY (source_entity_uuid)
);

DROP TABLE IF EXISTS aux_invalid_orgunit;
CREATE TABLE aux_invalid_orgunit
(
    uuid uuid NOT NULL,
    CONSTRAINT aux_invalid_orgunit_pkey PRIMARY KEY (uuid)
);