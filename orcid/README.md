# Sistema de Correção de Identificadores ORCID

Este sistema corrige identificadores ORCID incorretos no banco de dados, transformando URLs no formato `orcid::https://orcid.org/XXXX-XXXX-XXXX-XXXX` em identificadores normalizados `XXXX-XXXX-XXXX-XXXX` e atualizando todas as referências associadas.

## Problema

No banco de dados, existem identificadores ORCID armazenados em um formato incorreto que inclui o prefixo completo da URL. Isso causa problemas de normalização e consistência. O sistema deve:

1. Identificar esses identificadores incorretos.
2. Criar novos identificadores no formato correto.
3. Atualizar todas as referências relacionadas.
4. Reutilizar ou criar entidades conforme necessário.
5. Atualizar os campos das entidades afetadas.

## Pré-requisitos

- Python 3.6 ou superior.
- PostgreSQL (com acesso ao banco de dados).
- Os pacotes Python listados em `requirements.txt`.

## Instalação

```bash
# Configurar ambiente virtual e dependências
bash step0_setup_env.sh

# Ou manualmente:
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## Configuração

Crie um arquivo `.env` no diretório principal com as credenciais do banco de dados:

```
DB_HOST=localhost
DB_NAME=lrharvester
DB_USER=lrharvester
DB_PASSWORD=lrharvester
DB_PORT=5432
```

## Processo de correção passo a passo

### Passo 1: Criar e preencher tabela de identificadores incorretos

```bash
python scripts/step1_create_and_fill_tables.py
```

Este passo:
- Cria a tabela `wrong_orcid_semantic_identifier` para os identificadores incorretos.
- Extrai os identificadores ORCID que possuem o formato de URL incorreto.
- Gera uma versão normalizada sem o prefixo da URL.
- Prepara espaços para os novos valores hash.

### Passo 2: Gerar novos hashes para identificadores normalizados

```bash
python scripts/step2_update_orcid_with_hash.py
```

Este passo:
- Calcula um hash XXHash64 para cada identificador normalizado.
- Atualiza os registros com esses novos valores hash.
- Esses hashes serão usados como IDs para os novos identificadores semânticos.

### Passo 3: Inserir novos identificadores semânticos

```bash
python scripts/step3_insert_new_identifiers.py
```

Este passo:
- Insere os novos identificadores normalizados na tabela `semantic_identifier`.
- Garante que todos os identificadores necessários existam para os próximos passos.

### Passo 4: Criar tabela de backup de entidades

```bash
python scripts/step4_create_entity_backup.py
```

Este passo:
- Cria a tabela `wrong_orcid_entity_backup` que relaciona entidades com seus identificadores.
- Armazena informações sobre as entidades e seus identificadores antigos e novos.
- Cria índices para otimizar as consultas posteriores.

### Passo 5: Atualizar referências em entidades fonte

```bash
python scripts/step5_update_source_entities.py
```

Este passo:
- Atualiza as referências em `source_entity_semantic_identifier`.
- Substitui os identificadores incorretos pelos novos normalizados.

### Passo 6: Atualizar tabela de backup de entidades

```bash
python scripts/step6_update_entity_backup.py
```

Este passo:
- Atualiza a tabela de backup com informações sobre entidades existentes.
- Identifica casos onde já existe uma entidade com o identificador correto.

### Passo 7: Atualizar identificadores na tabela de entidades

```bash
python scripts/step7_update_entity_semantic.py
```

Este passo:
- Atualiza os identificadores na tabela de entidades.
- Substitui os identificadores incorretos pelos novos normalizados.
- Reutiliza entidades existentes para evitar duplicidade.

### Passo 8: Marcar entidades como "sujas"

```bash
python scripts/step8_mark_entities_dirty.py
```

Este passo:
- Marca como "sujas" (dirty) as entidades afetadas pelas mudanças.
- Essas entidades serão processadas posteriormente para atualizar seus campos.

### Passo 9: Atualizar referências finais de entidades

```bash
python scripts/step9_update_final_entities.py
```

Este passo:
- Atualiza as referências `final_entity_id` em `source_entity`.
- Estabelece as relações corretas entre entidades fonte e entidades finais.

### Passo 10: Excluir entidades com identificadores errôneos

```bash
python scripts/step10_delete_old_entities.py
```

Este passo:
- Modifica as restrições de chave estrangeira para adicionar CASCADE DELETE.
- Exclui as entidades antigas que já foram substituídas por outras entidades que já tinham o ORCID correto atribuído.
- Prepara o banco de dados para o processo final de mesclagem.

### Passo 11: Executar merge de campos para entidades afetadas

```bash
python scripts/step11_merge_entities.py
```

Este passo:
- Executa o procedimento armazenado `merge_entity_relation_data`.
- Atualiza os campos e relações das entidades marcadas como "sujas".
- Completa o processo de correção consolidando as informações.

## Estrutura do projeto

```
brcris_fix/
├── README.md                 # Este arquivo
├── requirements.txt          # Dependências do projeto
├── .env.example              # Exemplo de configuração
├── step0_setup_env.sh        # Script de configuração inicial
├── scripts/                  # Scripts Python para cada passo
│   ├── step1_create_and_fill_tables.py
│   ├── step2_update_orcid_with_hash.py
│   ├── step3_insert_new_identifiers.py
│   ├── step4_create_entity_backup.py
│   ├── step5_update_source_entities.py
│   ├── step6_update_entity_backup.py
│   ├── step7_update_entity_semantic.py
│   ├── step8_mark_entities_dirty.py
│   ├── step9_update_final_entities.py
│   ├── step10_delete_old_entities.py
│   └── step11_merge_entities.py
├── sql/                      # Scripts SQL utilizados pelos scripts Python
│   ├── step1_orcid.sql
│   ├── step2_update_hash.sql
│   ├── step3_insert_identifiers.sql
│   ├── step4_entity_backup.sql
│   ├── step5_update_source_entities.sql
│   ├── step6_update_entity_backup.sql
│   ├── step7_update_semantic.sql
│   ├── step8_mark_dirty.sql
│   ├── step9_update_final_entities.sql
│   ├── step10_delete_old_entities.sql
│   └── step11_merge_entities.sql
└── utils/                    # Utilitários comuns
    └── db_utils.py           # Funções para interagir com o banco de dados
```

## Notas técnicas

- Os hashes são gerados utilizando o algoritmo XXHash64, o mesmo utilizado pela LaReferencia.
- As operações no banco de dados são realizadas em transações para garantir a integridade dos dados.
- O progresso é exibido em tempo real durante operações longas para facilitar o acompanhamento.
- Os scripts são projetados para serem idempotentes sempre que possível, permitindo retomar o processo em caso de erro.
- Índices estratégicos são utilizados para otimizar consultas em tabelas grandes.
- O passo 10 modifica as restrições de chave estrangeira para permitir exclusões em cascata.
- As entidades excluídas no passo 10 são aquelas que tinham identificadores semânticos errados e que já foram substituídas.
- O processo preserva as relações entre entidades e seus metadados, atualizando apenas os identificadores.