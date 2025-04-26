# Sistema de Limpeza de Unidades Organizacionais (OrgUnit) Inválidas

Este sistema identifica e remove entidades do tipo `OrgUnit` (tipo 1) que não possuem um identificador semântico considerado válido, com base em uma lista fornecida. Ele também remove dados relacionados a essas entidades inválidas em outras tabelas.

## Problema

Existem entidades `OrgUnit` no banco de dados que não correspondem a unidades organizacionais válidas ou reconhecidas. Isso pode ocorrer devido a erros de importação, dados desatualizados ou falta de padronização. Essas entidades inválidas poluem o banco de dados e podem afetar a qualidade das análises e relatórios.

## Solução

O sistema utiliza uma lista de identificadores semânticos válidos (geralmente extraídos de um arquivo XML ou similar) para identificar quais `OrgUnits` são legítimas. As etapas do processo são:

1.  **Criação de Tabelas Auxiliares**: Tabelas temporárias são criadas para armazenar os identificadores válidos e os UUIDs das entidades válidas e inválidas.
2.  **Carga de Identificadores Válidos**: Os identificadores semânticos válidos são lidos de um arquivo de entrada (`orgunit.xml` por padrão) e carregados em uma tabela auxiliar. O hash xxHash64 é calculado para cada identificador.
3.  **Desativação Temporária de Constraints**: As restrições de chave estrangeira (Foreign Key constraints) que referenciam as tabelas a serem modificadas são temporariamente desativadas para permitir a exclusão de dados.
4.  **Identificação de Entidades Válidas e Inválidas**: As tabelas auxiliares são populadas para marcar quais `OrgUnits` (tanto `entity` quanto `source_entity`) são consideradas válidas (possuem um identificador semântico válido) e quais são inválidas.
5.  **Exclusão de Dados Inválidos**: As `OrgUnits` inválidas e todos os registros relacionados a elas em tabelas como `source_entity_fieldoccr`, `source_entity_semantic_identifier`, `source_relation`, `entity_fieldoccr`, `entity_semantic_identifier`, `relation`, etc., são excluídos.
6.  **Reativação de Constraints**: As restrições de chave estrangeira são reativadas.

## Pré-requisitos

*   Python 3.x
*   `pip` (gerenciador de pacotes Python)
*   Acesso ao banco de dados PostgreSQL onde os dados do BRCris estão armazenados.
*   Um arquivo contendo a lista de identificadores semânticos válidos para `OrgUnits` (por exemplo, `orgunit.xml`).

## Instalação

1.  Clone o repositório (se ainda não o fez).
2.  Navegue até o diretório `orgunit`.
3.  Execute o script de configuração do ambiente:
    ```bash
    bash step0_setup_env.sh
    ```
    Isso criará um ambiente virtual, o ativará e instalará as dependências listadas em `requirements.txt`.

## Configuração

1.  **Arquivo de Entrada**: Certifique-se de que o arquivo com os identificadores semânticos válidos (por exemplo, `orgunit.xml`) esteja presente no diretório raiz `orgunit`. O script `step2_load_valid_semantic_ids.py` espera encontrá-lo lá por padrão. Se o nome ou local for diferente, ajuste o script correspondente.
2.  **Variáveis de Ambiente**: Crie um arquivo `.env` na raiz do diretório `orgunit` (o script `step0_setup_env.sh` copia `.env.example` para `.env` se ele não existir). Edite o arquivo `.env` com as credenciais corretas do seu banco de dados:
    ```dotenv
    DB_HOST=localhost
    DB_NAME=lrharvester
    DB_USER=lrharvester
    DB_PASSWORD=lrharvester
    DB_PORT=5432
    ```

## Processo de Limpeza Passo a Passo

Execute cada passo individualmente a partir do diretório `scripts` (`cd scripts`).

**Nota sobre o Tempo de Execução:** Os passos 4 e 5 podem demorar um tempo considerável para serem concluídos, dependendo do tamanho das tabelas `entity`, `source_entity` e relacionadas no banco de dados.

### Passo 1: Criar Tabelas Auxiliares

```bash
python step1_create_tables.py
```

Cria as tabelas temporárias necessárias (`aux_valid_orgunit_semantic_id`, `aux_valid_orgunit`, `aux_invalid_source_orgunit`, `aux_invalid_orgunit`).

### Passo 2: Carregar Identificadores Semânticos Válidos

```bash
python step2_load_valid_semantic_ids.py [caminho_para_arquivo_xml]
```

Lê o arquivo XML (padrão: `../orgunit.xml`), extrai os identificadores semânticos, calcula o hash xxHash64 e os insere na tabela `aux_valid_orgunit_semantic_id`. O argumento com o caminho para o arquivo XML é opcional.

### Passo 3: Desativar Constraints

```bash
python step3_turn_off_constraints.py
```

Executa o script SQL `step3_turn_off_contraints.sql` para desativar temporariamente as chaves estrangeiras relevantes.

### Passo 4: Preparar Tabelas Auxiliares (Identificar Válidos/Inválidos)

```bash
python step4_prepare_aux_tables.py
```

Executa o script SQL `step4_prepare_aux_tables.sql` para popular as tabelas `aux_valid_orgunit`, `aux_invalid_source_orgunit` e `aux_invalid_orgunit`. **Este passo pode ser demorado.**

### Passo 5: Excluir Entidades Inválidas e Dados Relacionados

```bash
python step5_delete_invalid_data.py
```

Executa o script SQL `step5_delete_invalid_data.sql` para remover as `OrgUnits` inválidas e dados associados. **Este é geralmente o passo mais demorado do processo.**

### Passo 6: Reativar Constraints

```bash
python step6_turn_on_constraints.py
```

Executa o script SQL `step6_turn_on_constraints.sql` para reativar as chaves estrangeiras que foram desativadas no Passo 3.

## Estrutura do Projeto

```
orgunit/
├── README.md                 # Este arquivo
├── requirements.txt          # Dependências Python
├── .env.example              # Exemplo de configuração do banco de dados
├── .env                      # Configuração do banco de dados (criado a partir do .env.example)
├── step0_setup_env.sh        # Script para configurar o ambiente virtual
├── orgunit.xml               # Arquivo de exemplo/entrada com identificadores válidos
├── scripts/                  # Scripts Python para cada passo
│   ├── step1_create_tables.py
│   ├── step2_load_valid_semantic_ids.py
│   ├── step3_turn_off_constraints.py
│   ├── step4_prepare_aux_tables.py
│   ├── step5_delete_invalid_data.py
│   ├── step6_turn_on_constraints.py
│   └── utils/                # Utilitários comuns
│       └── db_utils.py       # Funções para interagir com o banco de dados
└── sql/                      # Scripts SQL utilizados pelos scripts Python
    ├── step1_create_tables.sql
    ├── step3_turn_off_contraints.sql
    ├── step4_prepare_aux_tables.sql
    ├── step5_delete_invalid_data.sql
    └── step6_turn_on_constraints.sql

```

## Notas Técnicas

*   O tipo de entidade `OrgUnit` é identificado pelo `entity_type_id = 1`.
*   O script `step2` utiliza a biblioteca `xml.etree.ElementTree` para parsear o XML e `xxhash` para gerar o hash do identificador semântico.
*   Os scripts Python utilizam `psycopg2` para interagir com o banco de dados PostgreSQL.
*   É crucial garantir que o arquivo de entrada (`orgunit.xml` ou similar) contenha **apenas** os identificadores semânticos válidos. Qualquer identificador presente nesse arquivo será considerado válido.
*   **Backup**: É altamente recomendável realizar um backup completo do banco de dados antes de executar este processo, especialmente em um ambiente de produção.
