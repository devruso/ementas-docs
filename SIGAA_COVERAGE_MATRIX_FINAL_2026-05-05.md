# Matriz Final de Cobertura Rica por Campo - 2026-05-05

Projeto: BDCP (TCC)  
Data de execucao: 2026-05-05  
Arquivo de baseline: `api-bdcp/src/tests/fixtures/sigaa/full-catalog-results.2026-05-05.final.json`

## 1) Comando reproduzivel

```bash
npm run sigaa:full-catalog -- --concurrency 6 --enrich-details true --details-concurrency 4 --output src/tests/fixtures/sigaa/full-catalog-results.2026-05-05.final.json
```

## 2) Resumo de execucao

- `totalUnitsScanned`: 568
- `successfulUnits`: 568
- `failedUnits`: 0
- `totalComponentsExtracted`: 24468

## 3) Cobertura consolidada por campo

| Campo | Cobertos | Total | Cobertura |
|---|---:|---:|---:|
| withDetailUrl | 0 | 24468 | 0.00% |
| withDetailAction | 7427 | 24468 | 30.35% |
| withDetailEndpoint | 7427 | 24468 | 30.35% |
| withPrerequeriments | 3 | 24468 | 0.01% |
| withCoRequisites | 1 | 24468 | 0.00% |
| withEquivalences | 0 | 24468 | 0.00% |
| withSyllabus | 6580 | 24468 | 26.89% |
| withWorkloadBreakdown | 23590 | 24468 | 96.41% |

## 4) Leitura tecnica do resultado

1. A varredura institucional ampla esta estavel (100% de unidades processadas com sucesso).
2. A conexao do caminho amplo com busca JSF por unidade destravou coleta de detalhe por acao para 7.427 componentes.
3. Campos textuais de detalhe passam a ter cobertura parcial em lote (ex.: ementa em 6.580 componentes), com lacunas residuais em equivalencias e baixa cobertura de co-requisitos.

## 5) Implicacao para requisitos

- Requisito de persistencia estruturada de co-requisitos/equivalencias: **implementado no backend**.
- Requisito de cobertura rica automatizada em lote institucional: **parcialmente destravado**, com evidencias de progresso e lacuna residual de dados para campos de equivalencia/co-requisito.

## 6) Evidencia de comando desta consolidacao

```bash
npm run sigaa:full-catalog -- --concurrency 6 --enrich-details true --details-concurrency 4 --output src/tests/fixtures/sigaa/full-catalog-results.2026-05-05.prd-final.json
```

Arquivo de saida consolidado:

- `api-bdcp/src/tests/fixtures/sigaa/full-catalog-results.2026-05-05.prd-final.json`