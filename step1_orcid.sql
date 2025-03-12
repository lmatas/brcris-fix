CREATE TABLE public.wrong_orcid_semantic_identifier (
	id int8 NOT NULL,
	semantic_id text NULL,
	new_id int8 NULL, 
	new_semantic_id text null,
	
	CONSTRAINT wo_semantic_identifier_pkey PRIMARY KEY (id)
);

CREATE INDEX idx_wrong_orcid_semantic_identifier_id ON public.wrong_orcid_semantic_identifier (id);
CREATE INDEX idx_wrong_orcid_semantic_identifier_semantic_id ON public.wrong_orcid_semantic_identifier (semantic_id);
CREATE UNIQUE INDEX idx_wrong_orcid_semantic_identifier_new_id ON public.wrong_orcid_semantic_identifier (new_id);
CREATE INDEX idx_wrong_orcid_semantic_identifier_new_semantic_id ON public.wrong_orcid_semantic_identifier (new_semantic_id);

insert into wrong_orcid_semantic_identifier 
(SELECT id, semantic_id, null, replace(semantic_id, 'https://orcid.org/', '')
 FROM public.semantic_identifier
 where semantic_id like 'orcid::https%');