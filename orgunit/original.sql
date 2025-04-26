Tabelas temporárias e carga de UUIDs válidos:


CREATE TABLE valid_orgunit
(
   uuid uuid NOT NULL,
   CONSTRAINT valid_orgunit_pkey PRIMARY KEY (uuid)
);


CREATE TABLE valid_orgunit_semantic_id (
   semantic_id varchar NOT NULL,
   CONSTRAINT valid_orgunit_semantic_pkey PRIMARY KEY (semantic_id)
);

CREATE TABLE entity_orgunit_tbd
(
   uuid uuid NOT NULL,
   CONSTRAINT entity_orgunit_tbd_pkey PRIMARY KEY (uuid)
);


CREATE TABLE source_entity_orgunit_tbd
(
   uuid uuid NOT NULL,
   CONSTRAINT source_entity_orgunit_tbd_pkey PRIMARY KEY (uuid)
);


shell script:
cat orgunit.xml | pcregrep --om-separator=" - " -o2 -i '(.*)<semanticIdentifier>(.*)</semanticIdentifier(.*)' | sort | uniq -u > unique_valid_semantic_identifiers.txt




\copy valid_orgunit_semantic_id FROM '/home/marcioamaral/arquivos_brcris/unique_valid_semantic_identifiers.txt'


INSERT INTO valid_orgunit
   (SELECT DISTINCT e.uuid
    from semantic_identifier si,
         valid_orgunit_semantic_id vosi,
         entity_semantic_identifier esi,
         entity e
    where  e.entity_type_id = 1
      and si.semantic_id = vosi.semantic_id
      and esi.semantic_id = si.id
      and esi.entity_id = e.uuid);






# Selecciona las entities que no tienen como id ninguno de la lista valida
INSERT INTO entity_orgunit_tbd
   (select e.uuid
    from entity e
    where e.entity_type_id = 1
      and not exists (select * from valid_orgunit vo where vo.uuid = e.uuid));







# selecciona las source_entity de tipo 1 (orgunit) que no tengan con final entity una entity de la lista válida 

INSERT INTO source_entity_orgunit_tbd
   (SELECT se.uuid
    FROM source_entity se
    WHERE se.entity_type_id = 1
      AND NOT EXISTS (SELECT * FROM valid_orgunit vo WHERE vo.uuid = se.final_entity_id))


Deletes:






DELETE
FROM source_entity_fieldoccr USING source_entity_orgunit_tbd
WHERE source_entity_fieldoccr.entity_id = source_entity_orgunit_tbd.uuid;




DELETE
FROM source_entity_semantic_identifier USING source_entity_orgunit_tbd
WHERE source_entity_semantic_identifier.entity_id = source_entity_orgunit_tbd.uuid;




DELETE
FROM source_relation USING source_entity_orgunit_tbd
WHERE source_relation.from_entity_id = source_entity_orgunit_tbd.uuid;




DELETE
FROM entity_fieldoccr USING entity_orgunit_tbd
WHERE entity_fieldoccr.entity_id = entity_orgunit_tbd.uuid;




DELETE
FROM entity_semantic_identifier USING entity_orgunit_tbd
WHERE entity_semantic_identifier.entity_id = entity_orgunit_tbd.uuid;




DELETE
FROM relation USING entity_orgunit_tbd
WHERE relation.from_entity_id = entity_orgunit_tbd.uuid;


-- NOVO 1/02
DELETE
FROM relation USING entity_orgunit_tbd
WHERE relation.to_entity_id = entity_orgunit_tbd.uuid;


DELETE
FROM source_relation USING source_entity_orgunit_tbd
WHERE source_relation.from_entity_id = source_entity_orgunit_tbd.uuid;


DELETE
FROM source_relation USING source_entity_orgunit_tbd
WHERE source_relation.to_entity_id = source_entity_orgunit_tbd.uuid;




create index entity_type_index on source_entity (entity_type_id);
create index entity_entity_type_id_index on entity (entity_type_id);


------------------------------------ Desabiliatção de check constraints


-- Referenciam source_entity
alter table source_relation
   drop constraint fk2tug80it3it1d7315h2x04fig;


alter table source_relation
   drop constraint fka85ljpk6ps09u8nya2pvpfgvk;


alter table source_entity_semantic_identifier
   drop constraint fk8u7995l8qeh56i34ij4jfm7ny;


alter table relation
   drop constraint fk9kavjxgi0tpvju15iab7petiw;


alter table relation
   drop constraint fk9wvqikvahl1a0x1xkcfdw42n;


alter table entity_fieldoccr
   drop constraint fkg85y6bnncn3q9y762wvrwj08u;


alter table entity_semantic_identifier
   drop constraint fkinjr1aqio6tuon2ypi6ixd4ao;


alter table source_entity
   drop constraint fk3obeh2naev2b3gyswvpvw433e;


-- NOVO 01/02
alter table relation_fieldoccr
   drop constraint fkjottc07w9a00w4ta9u48br53m;




------------------------------------ Desabiliatção de check constraints


DELETE
FROM source_entity USING source_entity_orgunit_tbd
WHERE source_entity.entity_type_id = 1 and source_entity.uuid = source_entity_orgunit_tbd.uuid;


-- NOVO 01/02
DELETE
FROM source_entity USING entity_orgunit_tbd
WHERE source_entity.entity_type_id = 1 and source_entity.final_entity_id = entity_orgunit_tbd.uuid;


DELETE
FROM entity USING entity_orgunit_tbd
WHERE entity.entity_type_id = 1 and entity.uuid = entity_orgunit_tbd.uuid;




-------------------------------------- Retorno das FKs


ALTER TABLE source_relation
   ADD constraint fka85ljpk6ps09u8nya2pvpfgvk FOREIGN KEY(from_entity_id)
       references source_entity;


ALTER TABLE source_relation
   ADD constraint fk2tug80it3it1d7315h2x04fig FOREIGN KEY(to_entity_id)
   references source_entity;


ALTER TABLE source_entity_fieldoccr
ADD CONSTRAINT
        fk2f3wc4b3huh74134hloikiou7 FOREIGN KEY (entity_id)
           references source_entity;


ALTER TABLE relation
   ADD constraint fk9kavjxgi0tpvju15iab7petiw FOREIGN KEY(from_entity_id)
       references entity;


ALTER TABLE relation
   ADD constraint fk9wvqikvahl1a0x1xkcfdw42n FOREIGN KEY(to_entity_id)
       references entity;




ALTER TABLE entity_fieldoccr
   ADD constraint fkg85y6bnncn3q9y762wvrwj08u FOREIGN KEY(entity_id)
       references entity;


ALTER TABLE entity_semantic_identifier
   ADD constraint fkinjr1aqio6tuon2ypi6ixd4ao FOREIGN KEY(entity_id)
       references entity;




ALTER TABLE source_entity
   ADD constraint fk3obeh2naev2b3gyswvpvw433e FOREIGN KEY(final_entity_id)
       references entity;




alter table relation_fieldoccr
   add constraint relation_fieldoccr_entityfrom_uuid_fk
       foreign key (from_entity_id) references entity;


alter table relation_fieldoccr
   add constraint relation_fieldoccr_entityto_uuid_fk
       foreign key (to_entity_id) references entity;



