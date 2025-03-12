-- public.entity_orgunit_tbd definition

-- Drop table

-- DROP TABLE public.entity_orgunit_tbd;

CREATE TABLE public.entity_orgunit_tbd (
	uuid uuid NOT NULL,
	CONSTRAINT entity_orgunit_tbd_pkey PRIMARY KEY (uuid)
);


-- public.entity_type definition

-- Drop table

-- DROP TABLE public.entity_type;

CREATE TABLE public.entity_type (
	id int8 NOT NULL,
	description varchar(255) NULL,
	"name" varchar(255) NULL,
	CONSTRAINT entity_type_pkey PRIMARY KEY (id),
	CONSTRAINT uk_kg3s1d935edaf7me4vq9vv15v UNIQUE (name)
);


-- public.flyway_schema_history definition

-- Drop table

-- DROP TABLE public.flyway_schema_history;

CREATE TABLE public.flyway_schema_history (
	installed_rank int4 NOT NULL,
	"version" varchar(50) NULL,
	description varchar(200) NOT NULL,
	"type" varchar(20) NOT NULL,
	script varchar(1000) NOT NULL,
	checksum int4 NULL,
	installed_by varchar(100) NOT NULL,
	installed_on timestamp NOT NULL DEFAULT now(),
	execution_time int4 NOT NULL,
	success bool NOT NULL,
	CONSTRAINT flyway_schema_history_pk PRIMARY KEY (installed_rank)
);
CREATE INDEX flyway_schema_history_s_idx ON public.flyway_schema_history USING btree (success);


-- public.oaimetadata definition

-- Drop table

-- DROP TABLE public.oaimetadata;

CREATE TABLE public.oaimetadata (
	hash varchar(32) NOT NULL,
	metadata text NOT NULL,
	CONSTRAINT oaimetadata_pkey PRIMARY KEY (hash)
);


-- public.provenance definition

-- Drop table

-- DROP TABLE public.provenance;

CREATE TABLE public.provenance (
	id int8 NOT NULL,
	last_update timestamp NULL,
	record_id varchar(255) NULL,
	source_id varchar(255) NULL,
	CONSTRAINT provenance_pkey PRIMARY KEY (id)
);


-- public.semantic_identifier definition

-- Drop table

-- DROP TABLE public.semantic_identifier;

CREATE TABLE public.semantic_identifier (
	id int8 NOT NULL,
	semantic_id text NULL,
	CONSTRAINT semantic_identifier_pkey PRIMARY KEY (id)
);


-- public.source_entity_orgunit_tbd definition

-- Drop table

-- DROP TABLE public.source_entity_orgunit_tbd;

CREATE TABLE public.source_entity_orgunit_tbd (
	uuid uuid NOT NULL,
	CONSTRAINT source_entity_orgunit_tbd_pkey PRIMARY KEY (uuid)
);


-- public.transformer definition

-- Drop table

-- DROP TABLE public.transformer;

CREATE TABLE public.transformer (
	id bigserial NOT NULL,
	description varchar(255) NULL,
	"name" varchar(255) NOT NULL,
	CONSTRAINT transformer_pkey PRIMARY KEY (id)
);


-- public.valid_orgunit definition

-- Drop table

-- DROP TABLE public.valid_orgunit;

CREATE TABLE public.valid_orgunit (
	uuid uuid NOT NULL,
	CONSTRAINT valid_orgunit_pkey PRIMARY KEY (uuid)
);


-- public.valid_orgunit_semantic_id definition

-- Drop table

-- DROP TABLE public.valid_orgunit_semantic_id;

CREATE TABLE public.valid_orgunit_semantic_id (
	semantic_id varchar NOT NULL,
	CONSTRAINT valid_orgunit_semantic_pkey PRIMARY KEY (semantic_id)
);


-- public."validator" definition

-- Drop table

-- DROP TABLE public."validator";

CREATE TABLE public."validator" (
	id bigserial NOT NULL,
	description varchar(255) NULL,
	"name" varchar(255) NOT NULL,
	CONSTRAINT validator_pkey PRIMARY KEY (id)
);


-- public.entity definition

-- Drop table

-- DROP TABLE public.entity;

CREATE TABLE public.entity (
	uuid uuid NOT NULL,
	entity_type_id int8 NULL,
	dirty bool NULL,
	CONSTRAINT entity_pkey PRIMARY KEY (uuid),
	CONSTRAINT fk21ec1ub943occfcpm2jaovtsa FOREIGN KEY (entity_type_id) REFERENCES public.entity_type(id)
);
CREATE INDEX entity_entity_type_id_index ON public.entity USING btree (entity_type_id);


-- public.entity_semantic_identifier definition

-- Drop table

-- DROP TABLE public.entity_semantic_identifier;

CREATE TABLE public.entity_semantic_identifier (
	entity_id uuid NOT NULL,
	semantic_id int8 NOT NULL,
	CONSTRAINT entity_semantic_identifier_pkey PRIMARY KEY (entity_id, semantic_id),
	CONSTRAINT fkinjr1aqio6tuon2ypi6ixd4ao FOREIGN KEY (entity_id) REFERENCES public.entity(uuid),
	CONSTRAINT fkstp4rub2i3fywyrbsebuwjosa FOREIGN KEY (semantic_id) REFERENCES public.semantic_identifier(id)
);
CREATE INDEX esi_entity_id ON public.entity_semantic_identifier USING btree (entity_id);
CREATE INDEX esi_semantic_id ON public.entity_semantic_identifier USING btree (semantic_id);


-- public.field_type definition

-- Drop table

-- DROP TABLE public.field_type;

CREATE TABLE public.field_type (
	id bigserial NOT NULL,
	description varchar(255) NULL,
	kind int4 NULL,
	maxoccurs int4 NULL,
	"name" varchar(255) NULL,
	entity_relation_type_id int8 NULL,
	parent_field_type_id int8 NULL,
	subfields text NULL DEFAULT '[]'::text,
	CONSTRAINT field_type_pkey PRIMARY KEY (id),
	CONSTRAINT fkf1e4wfupyw60nca04lvdpchs0 FOREIGN KEY (parent_field_type_id) REFERENCES public.field_type(id)
);


-- public.network definition

-- Drop table

-- DROP TABLE public.network;

CREATE TABLE public.network (
	id bigserial NOT NULL,
	acronym varchar(20) NOT NULL,
	institutionacronym varchar(255) NULL,
	institutionname varchar(255) NOT NULL,
	"name" varchar(255) NOT NULL,
	published bool NOT NULL,
	schedulecronexpression varchar(255) NULL,
	secondary_transformer_id int8 NULL,
	transformer_id int8 NULL,
	validator_id int8 NULL,
	"attributes" text NULL DEFAULT '{}'::text,
	metadataprefix varchar(255) NULL DEFAULT 'oai_dc'::character varying,
	metadatastoreschema varchar(255) NULL DEFAULT 'xoai'::character varying,
	originurl varchar(255) NULL DEFAULT NULL::character varying,
	properties text NULL DEFAULT '{}'::text,
	"sets" text NULL DEFAULT '[]'::text,
	pre_validator_id int8 NULL,
	CONSTRAINT network_pkey PRIMARY KEY (id),
	CONSTRAINT uk_g8pr1g502c72o0tii4ebxgfcp UNIQUE (acronym),
	CONSTRAINT fk_prevalidator FOREIGN KEY (pre_validator_id) REFERENCES public."validator"(id),
	CONSTRAINT fk_primary_transformer FOREIGN KEY (transformer_id) REFERENCES public.transformer(id),
	CONSTRAINT fk_secondary_transformer FOREIGN KEY (secondary_transformer_id) REFERENCES public.transformer(id),
	CONSTRAINT fk_validator FOREIGN KEY (validator_id) REFERENCES public."validator"(id)
);


-- public.networksnapshot definition

-- Drop table

-- DROP TABLE public.networksnapshot;

CREATE TABLE public.networksnapshot (
	id bigserial NOT NULL,
	deleted bool NOT NULL,
	endtime timestamp NULL,
	indexstatus int4 NOT NULL,
	resumptiontoken varchar(255) NULL,
	"size" int4 NOT NULL,
	starttime timestamp NOT NULL,
	status int4 NOT NULL,
	transformedsize int4 NOT NULL,
	validsize int4 NOT NULL,
	network_id int8 NULL,
	lastincrementaltime timestamp NULL,
	previoussnapshotid int8 NULL,
	CONSTRAINT networksnapshot_pkey PRIMARY KEY (id),
	CONSTRAINT fks8wjtppucgkji6it4luvoc0wm FOREIGN KEY (network_id) REFERENCES public.network(id)
);


-- public.networksnapshotlog definition

-- Drop table

-- DROP TABLE public.networksnapshotlog;

CREATE TABLE public.networksnapshotlog (
	id bigserial NOT NULL,
	message text NOT NULL,
	"timestamp" timestamp NOT NULL,
	snapshot_id int8 NOT NULL,
	CONSTRAINT networksnapshotlog_pkey PRIMARY KEY (id),
	CONSTRAINT fkr7nf4n9k9w0vc1gmiltfljnct FOREIGN KEY (snapshot_id) REFERENCES public.networksnapshot(id)
);


-- public.oaibitstream definition

-- Drop table

-- DROP TABLE public.oaibitstream;

CREATE TABLE public.oaibitstream (
	checksum varchar(255) NOT NULL,
	identifier varchar(255) NOT NULL,
	datestamp timestamp NOT NULL,
	filename varchar(255) NOT NULL,
	fulltext text NULL,
	mime varchar(255) NOT NULL,
	sid int4 NOT NULL,
	status int4 NOT NULL,
	"type" varchar(255) NOT NULL,
	url varchar(255) NOT NULL,
	network_id int8 NOT NULL,
	CONSTRAINT oaibitstream_pkey PRIMARY KEY (checksum, identifier, network_id),
	CONSTRAINT fki631xlh52ite94886rdm6gbsg FOREIGN KEY (network_id) REFERENCES public.network(id)
);


-- public.oairecord definition

-- Drop table

-- DROP TABLE public.oairecord;

CREATE TABLE public.oairecord (
	id int8 NOT NULL DEFAULT nextval('oai_record_id_seq'::regclass),
	datestamp timestamp NOT NULL,
	identifier varchar(255) NOT NULL,
	originalmetadatahash varchar(32) NULL DEFAULT NULL::character varying,
	publishedmetadatahash varchar(32) NULL DEFAULT NULL::character varying,
	snapshot_id int8 NULL,
	status int4 NOT NULL,
	transformed bool NOT NULL,
	CONSTRAINT oairecord_pkey PRIMARY KEY (id),
	CONSTRAINT fk_snapshot FOREIGN KEY (snapshot_id) REFERENCES public.networksnapshot(id)
);
CREATE INDEX oairecord_originalmetadatahash_idx ON public.oairecord USING btree (originalmetadatahash);
CREATE INDEX oairecord_publishedmetadatahash_idx ON public.oairecord USING btree (publishedmetadatahash);
CREATE INDEX oairecord_snapid_index ON public.oairecord USING btree (snapshot_id);
CREATE INDEX oairecord_snapid_status_id_index ON public.oairecord USING btree (snapshot_id, status, id);


-- public.relation_type definition

-- Drop table

-- DROP TABLE public.relation_type;

CREATE TABLE public.relation_type (
	id int8 NOT NULL,
	description varchar(255) NULL,
	"name" varchar(255) NULL,
	from_entity_id int8 NULL,
	to_entity_id int8 NULL,
	CONSTRAINT relation_type_pkey PRIMARY KEY (id),
	CONSTRAINT uk_dqprukb42qt2xmwu1vgg1oqsv UNIQUE (name),
	CONSTRAINT fk3is6dski9xnfyk1mo8cv14led FOREIGN KEY (from_entity_id) REFERENCES public.entity_type(id),
	CONSTRAINT fkndcced7wia4vkdvhydsvi7rld FOREIGN KEY (to_entity_id) REFERENCES public.entity_type(id)
);


-- public.source_entity definition

-- Drop table

-- DROP TABLE public.source_entity;

CREATE TABLE public.source_entity (
	uuid uuid NOT NULL,
	entity_type_id int8 NULL,
	deleted bool NULL,
	final_entity_id uuid NULL,
	provenance_id int8 NULL,
	to_be_removed bool NULL,
	CONSTRAINT source_entity_pkey PRIMARY KEY (uuid),
	CONSTRAINT fk1cg02lhoal5xq86jpj1a7qokg FOREIGN KEY (entity_type_id) REFERENCES public.entity_type(id),
	CONSTRAINT fknwk1uql6xtcgjny8k6nq8ja8j FOREIGN KEY (provenance_id) REFERENCES public.provenance(id)
);
CREATE INDEX entity_type_index ON public.source_entity USING btree (entity_type_id);
CREATE INDEX idx_final_entity_id ON public.source_entity USING btree (final_entity_id);
CREATE INDEX se_provenance_id ON public.source_entity USING btree (provenance_id);
CREATE INDEX to_be_removed_index ON public.source_entity USING btree (to_be_removed);


-- public.source_entity_semantic_identifier definition

-- Drop table

-- DROP TABLE public.source_entity_semantic_identifier;

CREATE TABLE public.source_entity_semantic_identifier (
	entity_id uuid NOT NULL,
	semantic_id int8 NOT NULL,
	CONSTRAINT source_entity_semantic_identifier_pkey PRIMARY KEY (entity_id, semantic_id),
	CONSTRAINT fk9bf1gs0tx86f4eewbws4hkytp FOREIGN KEY (semantic_id) REFERENCES public.semantic_identifier(id)
);
CREATE INDEX ssi_entity_id ON public.source_entity_semantic_identifier USING btree (entity_id);
CREATE INDEX ssi_semantic_id ON public.source_entity_semantic_identifier USING btree (semantic_id);


-- public.source_relation definition

-- Drop table

-- DROP TABLE public.source_relation;

CREATE TABLE public.source_relation (
	from_entity_id uuid NOT NULL,
	relation_type_id int8 NOT NULL,
	to_entity_id uuid NOT NULL,
	confidence float8 NOT NULL,
	enddate timestamp NULL,
	startdate timestamp NULL,
	CONSTRAINT source_relation_pkey PRIMARY KEY (from_entity_id, relation_type_id, to_entity_id),
	CONSTRAINT fk2tug80it3it1d7315h2x04fig FOREIGN KEY (to_entity_id) REFERENCES public.source_entity(uuid),
	CONSTRAINT fka85ljpk6ps09u8nya2pvpfgvk FOREIGN KEY (from_entity_id) REFERENCES public.source_entity(uuid),
	CONSTRAINT fkhr0udguiwn7dos2o77lwt0abj FOREIGN KEY (relation_type_id) REFERENCES public.relation_type(id)
);
CREATE INDEX source_relation_type_members ON public.source_relation USING btree (relation_type_id, from_entity_id, to_entity_id);


-- public.transformerrule definition

-- Drop table

-- DROP TABLE public.transformerrule;

CREATE TABLE public.transformerrule (
	id bigserial NOT NULL,
	jsonserialization text NULL,
	description varchar(255) NULL,
	"name" varchar(255) NOT NULL,
	runorder int4 NOT NULL,
	transformer_id int8 NULL,
	CONSTRAINT transformerrule_pkey PRIMARY KEY (id),
	CONSTRAINT fkbueretrgfy97gyw05cvbpdv6g FOREIGN KEY (transformer_id) REFERENCES public.transformer(id)
);


-- public.validatorrule definition

-- Drop table

-- DROP TABLE public.validatorrule;

CREATE TABLE public.validatorrule (
	id bigserial NOT NULL,
	jsonserialization text NULL,
	description varchar(255) NULL,
	mandatory bool NOT NULL,
	"name" varchar(255) NOT NULL,
	quantifier int4 NOT NULL,
	validator_id int8 NULL,
	CONSTRAINT validatorrule_pkey PRIMARY KEY (id),
	CONSTRAINT fk8g1xrgw6x1rnhse1jhr9v2sai FOREIGN KEY (validator_id) REFERENCES public."validator"(id)
);


-- public.field_occurrence definition

-- Drop table

-- DROP TABLE public.field_occurrence;

CREATE TABLE public.field_occurrence (
	kind varchar(31) NOT NULL,
	id int8 NOT NULL,
	field_type_id int8 NULL,
	lang varchar(255) NULL,
	"content" text NULL,
	preferred bool NOT NULL DEFAULT false,
	CONSTRAINT field_occurrence_pkey PRIMARY KEY (id),
	CONSTRAINT fklygjgmk42bw7il8p85svic8hg FOREIGN KEY (field_type_id) REFERENCES public.field_type(id)
);


-- public.relation definition

-- Drop table

-- DROP TABLE public.relation;

CREATE TABLE public.relation (
	from_entity_id uuid NOT NULL,
	relation_type_id int8 NOT NULL,
	to_entity_id uuid NOT NULL,
	dirty bool NULL,
	CONSTRAINT relation_pkey PRIMARY KEY (from_entity_id, relation_type_id, to_entity_id),
	CONSTRAINT fk9kavjxgi0tpvju15iab7petiw FOREIGN KEY (from_entity_id) REFERENCES public.entity(uuid),
	CONSTRAINT fk9wvqikvahl1a0x1xkcfdw42n FOREIGN KEY (to_entity_id) REFERENCES public.entity(uuid),
	CONSTRAINT fks2nk3th0n2lygksxkloek4gd1 FOREIGN KEY (relation_type_id) REFERENCES public.relation_type(id)
);
CREATE INDEX relation_from_entity_id_idx ON public.relation USING btree (from_entity_id);
CREATE INDEX relation_to_entity_id_idx ON public.relation USING btree (to_entity_id);
CREATE INDEX relation_type_members ON public.relation USING btree (relation_type_id, from_entity_id, to_entity_id);


-- public.relation_fieldoccr definition

-- Drop table

-- DROP TABLE public.relation_fieldoccr;

CREATE TABLE public.relation_fieldoccr (
	from_entity_id uuid NOT NULL,
	relation_type_id int8 NOT NULL,
	to_entity_id uuid NOT NULL,
	fieldoccr_id int8 NOT NULL,
	CONSTRAINT relation_fieldoccr_pkey PRIMARY KEY (from_entity_id, relation_type_id, to_entity_id, fieldoccr_id),
	CONSTRAINT fk9fdsesc6ey8c831brij4u1rob FOREIGN KEY (fieldoccr_id) REFERENCES public.field_occurrence(id),
	CONSTRAINT relation_fieldoccr_entityfrom_uuid_fk FOREIGN KEY (from_entity_id) REFERENCES public.entity(uuid),
	CONSTRAINT relation_fieldoccr_entityto_uuid_fk FOREIGN KEY (to_entity_id) REFERENCES public.entity(uuid)
);


-- public.source_entity_fieldoccr definition

-- Drop table

-- DROP TABLE public.source_entity_fieldoccr;

CREATE TABLE public.source_entity_fieldoccr (
	entity_id uuid NOT NULL,
	fieldoccr_id int8 NOT NULL,
	CONSTRAINT source_entity_fieldoccr_pkey PRIMARY KEY (entity_id, fieldoccr_id),
	CONSTRAINT fk2f3wc4b3huh74134hloikiou7 FOREIGN KEY (entity_id) REFERENCES public.source_entity(uuid),
	CONSTRAINT fkitn5f8xb60m8w8t5ppsu4wgff FOREIGN KEY (fieldoccr_id) REFERENCES public.field_occurrence(id)
);
CREATE INDEX sfo_entity_id ON public.source_entity_fieldoccr USING btree (entity_id);
CREATE INDEX sfo_fieldoccr_id ON public.source_entity_fieldoccr USING btree (fieldoccr_id);


-- public.source_relation_fieldoccr definition

-- Drop table

-- DROP TABLE public.source_relation_fieldoccr;

CREATE TABLE public.source_relation_fieldoccr (
	from_entity_id uuid NOT NULL,
	relation_type_id int8 NOT NULL,
	to_entity_id uuid NOT NULL,
	fieldoccr_id int8 NOT NULL,
	CONSTRAINT source_relation_fieldoccr_pkey PRIMARY KEY (from_entity_id, relation_type_id, to_entity_id, fieldoccr_id),
	CONSTRAINT fk10s6vmwa91jkhcc3m14debj7k FOREIGN KEY (fieldoccr_id) REFERENCES public.field_occurrence(id),
	CONSTRAINT fkntrxgvqcjsy3w7nb8xxcauh84 FOREIGN KEY (from_entity_id,relation_type_id,to_entity_id) REFERENCES public.source_relation(from_entity_id,relation_type_id,to_entity_id)
);


-- public.entity_fieldoccr definition

-- Drop table

-- DROP TABLE public.entity_fieldoccr;

CREATE TABLE public.entity_fieldoccr (
	entity_id uuid NOT NULL,
	fieldoccr_id int8 NOT NULL,
	CONSTRAINT entity_fieldoccr_pkey PRIMARY KEY (entity_id, fieldoccr_id),
	CONSTRAINT fkcnvu6hyt4mihaxjsejgmhu15r FOREIGN KEY (fieldoccr_id) REFERENCES public.field_occurrence(id),
	CONSTRAINT fkg85y6bnncn3q9y762wvrwj08u FOREIGN KEY (entity_id) REFERENCES public.entity(uuid)
);
CREATE INDEX efo_entity_id ON public.entity_fieldoccr USING btree (entity_id);
CREATE INDEX efo_fieldoccr_id ON public.entity_fieldoccr USING btree (fieldoccr_id);