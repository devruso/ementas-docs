# Diario de Analise Tecnica (BDCP)

## 2026-05-05 - Slice JSF de detalhe + persistencia estruturada

### Objetivo da analise

- Destravar captura de detalhe real da lupa no SIGAA quando a navegacao ocorre por acao JSF de linha (`jsfcljs`) em vez de `href`.
- Persistir co-requisitos e equivalencias em estrutura dedicada no banco para rastreabilidade.
- Reexecutar baseline institucional completa e consolidar matriz final por campo.

### Evidencia tecnica coletada

- A listagem publica principal pode expor detalhe por `onclick` com `idComponente` e `javax.faces.ViewState`.
- O caminho de varredura ampla usado no baseline (`units`/curriculo) manteve extracao sem endpoint de detalhe no HTML processado.
- Resultado: mesmo com enriquecimento habilitado, campos dependentes de detalhe permaneceram sem cobertura no lote amplo desta execucao.

### Decisoes implementadas

- Inclusao de parser de acao JSF de detalhe no crawler, com suporte a `detailActionUrl` e `detailActionPayload`.
- Inclusao de persistencia estruturada para relacoes de componente (`CO_REQUISITE`, `EQUIVALENCE`) em tabela dedicada.
- Inclusao de metrica adicional no baseline para diferenciar `withDetailUrl`, `withDetailAction` e `withDetailEndpoint`.

### Baseline final (execucao completa)

- Comando:
  - `npm run sigaa:full-catalog -- --concurrency 6 --enrich-details true --details-concurrency 4 --output src/tests/fixtures/sigaa/full-catalog-results.2026-05-05.final.json`
- Resultado:
  - `totalUnitsScanned`: 568
  - `successfulUnits`: 568
  - `failedUnits`: 0
  - `totalComponentsExtracted`: 24468

### Risco residual aberto

- Cobertura de pre-requisitos, co-requisitos, equivalencias e ementa em lote institucional segue dependente de endpoint publico de detalhe efetivamente acessivel no fluxo de varredura ampla.
- Para fechar o requisito de enriquecimento massivo, o proximo passo e conectar a navegacao JSF de detalhe tambem no caminho de descoberta usado pelo baseline completo.

## 2026-05-05 - Execucao do PRD (destravar lote + teste de persistencia + homologacao)

### Mudancas executadas

- Conexao do pipeline amplo com busca JSF por unidade quando a listagem principal nao traz endpoint de detalhe.
- Enriquecimento de detalhe habilitado dentro do import SIGAA publico antes da persistencia final.
- Teste de integracao adicionado para comprovar persistencia de `component_relations` durante import com dados enriquecidos.

### Validacao de cobertura em lote (baseline completa)

- Comando executado:
  - `npm run sigaa:full-catalog -- --concurrency 6 --enrich-details true --details-concurrency 4 --output src/tests/fixtures/sigaa/full-catalog-results.2026-05-05.prd-final.json`
- Resultado:
  - `totalUnitsScanned`: 568
  - `successfulUnits`: 568
  - `failedUnits`: 0
  - `totalComponentsExtracted`: 24468
- Cobertura-chave:
  - `withDetailAction`: 7427 (30.35%)
  - `withDetailEndpoint`: 7427 (30.35%)
  - `withSyllabus`: 6580 (26.89%)
  - `withPrerequeriments`: 3 (0.01%)
  - `withCoRequisites`: 1 (0.00%)

### Evidencia de homologacao (migration + leitura real)

- Migration executada com variaveis de homologacao local (`DB_HOST=localhost`, `DB_PORT=15432`, `DB_NAME=bdcp`):
  - `addComponentRelationsTable1772528400000` aplicada com sucesso.
- Leitura real em banco homologado local via `psql`:
  - `components_count`: 37
  - insercao controlada de relacao (`HMLTEST01`) retornou `INSERT 0 1`
  - consulta de leitura retornou registro com `component_code=MATA67`, `relation_type=co_requisite`, `related_code=HMLTEST01`
  - limpeza tecnica executada em seguida (`DELETE 1`).