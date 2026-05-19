# Relatorio Final de Acuracia - Crawler SIGAA Publico

Data de consolidacao: 2026-05-04  
Projeto: EMENTAS (TCC)  
Objetivo: apresentar evidencias reais de descoberta de fonte, acuracia por campo e prontidao para banca.

## 1) Escopo e Metodo

- Fluxo de coleta: sessao JSF publica com submissao de formulario (`javax.faces.ViewState`) em `busca_componentes.jsf`.
- Fontes reais validadas:
  - DCC/IC (`unidade=1114`, nivel `G`)
  - DCI/IC (`unidade=2440`, nivel `G`)
  - PGCOMP/IC (`unidade=1820`, nivel `S`, mapeado para `mestrado` no parser)
- Verdade-terreno: amostra manual estratificada com 15 disciplinas (5 por fonte).
- Motor de avaliacao: script reprodutivel em `ementas-api/src/scripts/sigaa-accuracy-report.ts`.

## 2) Descoberta Concluida (IDs/Fonte)

| Fonte | Source Type | Parametro de busca | Nivel | Evidencia |
|---|---|---|---|---|
| Departamento de Ciencia da Computacao (DCC/IC) | department | `form:unidades=1114` | `G` | 133 itens extraidos |
| Departamento de Computacao Interdisciplinar (DCI/IC) | department | `form:unidades=2440` | `G` | 32 itens extraidos |
| Programa de Pos-Graduacao em Ciencia da Computacao (PGCOMP/IC) | program | `form:unidades=1820` | `S` | 70 itens extraidos |

## 3) Resultado de Acuracia (Lote Positivo)

Base medida: 15 amostras estratificadas (5 DCC, 5 DCI, 5 PGCOMP).

| Campo | Acertos | Total | Acuracia |
|---|---:|---:|---:|
| code | 15 | 15 | 100% |
| name | 15 | 15 | 100% |
| department | 15 | 15 | 100% |
| academicLevel | 15 | 15 | 100% |

### Resumo visual (barra)

| Campo | Visual |
|---|---|
| code | `?-^?-^?-^?-^?-^?-^?-^?-^?-^?-^ 100%` |
| name | `?-^?-^?-^?-^?-^?-^?-^?-^?-^?-^ 100%` |
| department | `?-^?-^?-^?-^?-^?-^?-^?-^?-^?-^ 100%` |
| academicLevel | `?-^?-^?-^?-^?-^?-^?-^?-^?-^?-^ 100%` |

## 4) Ajustes Tecnicos que Viabilizaram o Resultado

- Parser endurecido para ignorar ruído de layout/JSF e manter foco em linhas tabulares reais.
- Suporte a codigo com prefixo de programa, ex.: `PGCOMP/IC0032` -> codigo normalizado `IC0032`.
- Refino de heuristica de departamento para evitar falso positivo em termos como `PROGRAMACAO`.
- Regressao automatizada adicionada para os cenarios acima.

## 5) Evidencias Reproduziveis

- Script de medicao: `ementas-api/src/scripts/sigaa-accuracy-report.ts`
- Verdade-terreno estratificada: `ementas-api/src/tests/fixtures/sigaa/manual-ground-truth-stratified.json`
- Resultado consolidado bruto: `ementas-api/src/tests/fixtures/sigaa/accuracy-results.json`
- Fixtures reais de entrada:
  - `ementas-api/src/tests/fixtures/sigaa/source-busca-componentes-dcc-1114.html`
  - `ementas-api/src/tests/fixtures/sigaa/source-busca-componentes-dci-2440.html`
  - `ementas-api/src/tests/fixtures/sigaa/source-busca-componentes-pgcomp-1820.html`

## 6) Leitura para Banca

- Confiabilidade observada no escopo medido: alta, com 100% nos campos avaliados.
- Risco residual: baixo para os cenarios cobertos; medio para unidades/fontes ainda nao estratificadas fora do recorte de computacao.
- Recomendacao de continuidade:
  1. ampliar amostra estratificada para outros institutos e niveis;
  2. incluir validacao de mudancas de layout do SIGAA em monitoramento periodico;
  3. manter conteudo programatico como fonte canonica no EMENTAS para publicacao oficial.

## 7) Equivalencia de Campos SIGAA x EMENTAS (Atualizado)

| Origem SIGAA | Campo SIGAA | Campo EMENTAS | Status atual | Regra de mapeamento |
|---|---|---|---|---|
| Listagem publica (`busca_componentes`) | Codigo | `Component.code` | Implementado | Extracao por regex, com normalizacao para codigos com prefixo de programa (`PGCOMP/IC0032` -> `IC0032`). |
| Listagem publica (`busca_componentes`) | Nome | `Component.name` | Implementado | Captura da coluna textual principal da linha de componente. |
| Listagem publica (`busca_componentes`) | Tipo da atividade | `Component.modality` | Implementado | Captura de valor conhecido como `DISCIPLINA`; fallback para `DISCIPLINA` quando ausente. |
| Listagem publica (`busca_componentes`) | CH / CH Total | `ComponentWorkload.studentTheory` | Implementado (parcial) | CH total em horas e mapeada para carga teorica inicial quando nao ha distribuicao detalhada. |
| Listagem publica (`busca_componentes`) | Unidade/Programa no contexto da pagina | `Component.department` | Implementado | Normalizacao por label de departamento/programa identificada na pagina. |
| Fluxo de importacao | Nivel academico (`G`/`S`) | `Component.academicLevel` | Implementado | `G` -> `graduacao`, `S` -> `mestrado`/`doutorado` conforme parametro de entrada. |
| Lupa (detalhes do componente) | Pre-requisitos | `Component.prerequeriments` | Parcial | Hoje permanece `NAO_SE_APLICA` na importacao SIGAA publica sem etapa de enriquecimento por detalhe. |
| Lupa (detalhes do componente) | Ementa/Descricao | `Component.syllabus`/`Component.program` | Parcial | No fluxo atual, sem parser de detalhe por item, entram textos de fallback quando a listagem nao informa ementa. |
| Lupa (detalhes do componente) | Modalidade de educacao | `Component.modality` | Parcial | Atualmente preenchida pelo tipo da linha da listagem; detalhe de modalidade especifica ainda nao e consumido por parser dedicado. |
| Lupa (detalhes do componente) | Cargas (teorica/pratica/extensionista) | `ComponentWorkload` | Parcial | Atualmente so CH total da listagem; distribuicao fina da lupa ainda pendente. |
| Lupa (detalhes do componente) | Co-requisitos / Equivalencias | Sem campo canonico dedicado | Pendente | Requer definir persistencia em campos auxiliares ou tabela dedicada para manter rastreabilidade sem ambiguidade. |

### Gap Objetivo para o Proximo Slice

1. Implementar parser da pagina de detalhe (lupa) para enriquecer prerequisitos, ementa e distribuicao de carga horaria.
2. Definir persistencia de co-requisitos e equivalencias sem perder semantica institucional.
3. Validar a equivalencia com casos reais (ex.: `MATF34` e `MAT154`) em teste de parser e teste de integracao.

## 8) Cobertura Ampla (Todos os Cursos/Unidades) e Agrupamentos

Para sair do recorte por poucos casos e cobrir a base ampla, foi adicionado um pipeline de varredura total do SIGAA publico:

- Script: `ementas-api/src/scripts/sigaa-full-catalog.ts`
- Comando: `npm run sigaa:full-catalog`

### O que o script faz

1. Descobre automaticamente unidades no formulario publico de busca de componentes para os niveis `G` (graduacao) e `S` (stricto).
2. Executa busca de componentes por unidade para todas as entradas descobertas.
3. Classifica e agrupa resultados por:
  - nivel academico (`graduacao`, `mestrado`, `doutorado`, `stricto_indefinido`),
  - categoria de unidade (`department`, `program`, `institute`, `other`),
  - instituto (codigo inferido, ex.: `IC`) com departamentos associados.
4. Gera relatorio estruturado com totais, agrupamentos, amostras de codigos e falhas por unidade.

### Exemplo de execucao

```bash
npm run sigaa:full-catalog
```

### Opcoes

- `--limit <n>`: limita quantidade de unidades varridas (util para validacao incremental).
- `--concurrency <n>`: controla paralelismo das buscas por unidade.
- `--output <arquivo>`: define caminho do JSON de saida.

Exemplo:

```bash
npm run sigaa:full-catalog -- --limit 100 --concurrency 6 --output src/tests/fixtures/sigaa/full-catalog-results.json
```

### Evidencia de comparativo amplo

O relatorio JSON contem os blocos:

- `grouped.byAcademicBucket`
- `grouped.byCategory`
- `grouped.byInstitute`
- `units` (detalhe de cada unidade)
- `failures` (erros por unidade)

Com isso, o comparativo deixa de ser por amostra pequena e passa a ser rastreavel para o conjunto de unidades descobertas no portal publico.

### Baseline institucional (execucao completa em 2026-05-05)

Comando executado (sem limite):

```bash
npm run sigaa:full-catalog -- --concurrency 6 --enrich-details true --details-concurrency 4 --output src/tests/fixtures/sigaa/full-catalog-results.2026-05-05.json
```

Resultado consolidado:

- `totalUnitsScanned`: 568
- `successfulUnits`: 568
- `failedUnits`: 0
- `totalComponentsExtracted`: 24468

Cobertura por agrupamento (resumo):

- `grouped.byAcademicBucket`: 284 unidades de graduacao e 284 em stricto_indefinido
- `grouped.byCategory`: 170 departamentos, 216 programas, 182 outros
- `grouped.byInstitute`: consolidado por instituto com departamentos associados em `instituteDepartmentModel`

Arquivo versionado de baseline:

- `ementas-api/src/tests/fixtures/sigaa/full-catalog-results.2026-05-05.json`

### Cobertura de campos ricos e lacuna atual

Mesmo com `--enrich-details true`, a execucao completa indicou:

- `withDetailUrl`: 0
- `withPrerequeriments`: 0
- `withCoRequisites`: 0
- `withEquivalences`: 0
- `withSyllabus`: 0
- `withWorkloadBreakdown`: 23590

Interpretacao tecnica:

1. O pipeline amplo esta robusto para varredura, agregacao institucional e carga horaria da listagem.
2. A fonte publica acessada neste ciclo nao expôs links de detalhe da lupa no HTML efetivamente consumido.
3. Assim, prerequisitos/co-requisitos/equivalencias/ementa continuam como lacuna de coleta automatica em lote.

## 9) Atualizacao do Slice Prioritario (2026-05-05)

As tres acoes do proximo slice foram executadas:

1. Navegacao JSF de detalhe por acao de linha foi implementada no crawler (suporte a `detailActionUrl` e `detailActionPayload`).
2. Persistencia estruturada de co-requisitos/equivalencias foi implementada com tabela dedicada e migracao.
3. Baseline completa foi reexecutada e matriz final publicada em `ementas-docs/SIGAA_COVERAGE_MATRIX_FINAL_2026-05-05.md`.

Resultado observado na baseline final: a cobertura rica em lote institucional permaneceu zero para campos de detalhe, indicando que o fluxo amplo ainda nao recebeu endpoint de detalhe efetivo no HTML processado nesta varredura.

Interpretacao: houve fechamento de infraestrutura e governanca de dados, com lacuna residual de integracao para enriquecimento massivo por detalhe em todos os cursos/unidades.




