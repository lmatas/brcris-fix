# Correção de Dados do OasisBR

Este diretório contém as consultas SQL necessárias para corrigir problemas relacionados aos identificadores Lattes duplicados importados do OasisBR.

## Descrição do Problema

As entidades provenientes do OasisBR podem conter múltiplos identificadores Lattes, o que causa inconsistências no sistema. Este script corrige esse problema através da identificação e correção destas entidades, garantindo que apenas os identificadores Lattes corretos sejam mantidos.

## O que as Consultas SQL Fazem

O arquivo `queries.sql` executa as seguintes operações:

1. **Criação de índices**: Melhora o desempenho das consultas subsequentes.
2. **Identificação de procedências**: Cria tabelas auxiliares para identificar as procedências do OasisBR e do Lattes.
3. **Identificação de entidades problemáticas**: Identifica as entidades fonte do OasisBR que contêm múltiplos identificadores Lattes.
4. **Correção de mapeamentos**: Remove os mapeamentos incorretos e insere os mapeamentos corretos baseados na procedência confiável do Lattes.
5. **Marcação para reprocessamento**: Marca as entidades afetadas como "dirty" para garantir que sejam reprocessadas.
6. **Limpeza de entidades fonte problemáticas**: Marca as entidades fonte do OasisBR identificadas como problemáticas como excluídas.
7. **Diagnóstico final**: Cria uma tabela para diagnóstico de entidades que ainda possuem múltiplos identificadores Lattes.

## Como Executar

### Pré-requisitos

- Acesso ao banco de dados PostgreSQL do sistema
- Permissões adequadas para criar tabelas, índices e modificar dados

### Execução das Consultas

1. Conecte-se ao banco de dados PostgreSQL:
   ```bash
   psql -U seu_usuario -d nome_do_banco -h host_do_banco
   ```

2. Execute o arquivo de consultas:
   ```bash
   \i brcris_fix/oasisbr/queries.sql
   ```

   Alternativamente, você pode copiar e colar as consultas diretamente no cliente SQL de sua preferência.

3. Verifique os resultados: As tabelas auxiliares criadas permitirão verificar as modificações realizadas.

### Passo Final: Merge de Entidades

Após executar todas as consultas, é necessário realizar o merge das entidades marcadas como "dirty". Este processo garante a consistência final dos dados:

1. Execute o script Python responsável pelo merge:
   ```bash
   python3 brcris_fix/orcid/scripts/step11_merge_entities.py
   ```

Este script inicia o procedimento SQL `execute_complete_merge_process()` que realiza o merge completo das entidades, reprocessando relações e campos.

## Tabelas Auxiliares Criadas

O script cria as seguintes tabelas auxiliares que podem ser úteis para análise:

- `aux_oasisbr_provenance_oasis`: Procedências do OasisBR
- `aux_oasisbr_provenance_lattes`: Procedências do Lattes
- `aux_oasisbr_source_entities_from_oasis`: Entidades fonte problemáticas
- `aux_oasisbr_broken_entities`: Entidades finais que precisam ser corrigidas
- `aux_oasisbr_source_entity_semantic_identifier_lattes_provenance_lattes`: Mapeamentos corretos de Lattes
- `aux_to_be_reloaded_oasisbr_records`: Registros que precisam ser recarregados
- `aux_diagnose_multiple_lattes_entities`: Entidades que ainda possuem múltiplos identificadores Lattes

## Atenção

Este script realiza modificações irreversíveis no banco de dados. Recomenda-se fortemente fazer um backup completo antes da execução.
