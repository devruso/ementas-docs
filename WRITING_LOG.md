# Diario de Escrita Academica (BDCP)

## 2026-05-05 - Consolidacao do slice de crawler institucional

### Problema

O fluxo de importacao institucional do BDCP precisava evoluir para capturar detalhes curriculares acionados por navegacao JSF de linha e, ao mesmo tempo, armazenar relacoes curriculares com estrutura auditavel. Sem isso, a cobertura de campos ricos permanecia limitada no processo automatizado de larga escala.

### Justificativa tecnica

Foi priorizada uma evolucao incremental e de baixo risco: primeiro habilitar a navegacao JSF de detalhe no crawler; em seguida formalizar persistencia dedicada para co-requisitos/equivalencias; por fim reexecutar a baseline completa para medir impacto real e registrar evidencias reproduziveis.

### Decisao de implementacao

- Navegacao de detalhe: parser do `onclick` JSF (`jsfcljs`) com montagem de payload (`javax.faces.ViewState` + `idComponente`) e requisicao POST para pagina de detalhe.
- Persistencia estruturada: criacao da entidade de relacao de componente e migracao com unicidade por (`component_id`, `relation_type`, `related_code`).
- Medicao: ampliacao da matriz para separar cobertura por `detailUrl`, `detailAction` e `detailEndpoint`.

### Evidencia

- Build validado com `npm run typecheck`.
- Testes focados validados: `CrawlerSigaaParser.spec.ts` e `CrawlerSigaaImportIntegration.spec.ts`.
- Baseline final completa executada com 568 unidades varridas e 24.468 componentes extraidos.

### Impacto academico

O trabalho reforca a rastreabilidade entre requisito, codigo, teste e evidencia de campo. Mesmo com lacuna residual de cobertura rica no lote amplo, o sistema avancou em robustez arquitetural e auditabilidade de dados curriculares, aproximando a implementacao dos criterios de reprodutibilidade exigidos no contexto de TCC.

## 2026-05-05 - Complemento de escrita (PRD executado)

### Problema

O pipeline institucional em larga escala ainda concentrava extração no HTML de listagem, sem conectar de forma efetiva o caminho JSF de detalhe para grande parte das unidades. Isso limitava a cobertura de campos ricos e enfraquecia a evidencia de aderencia ao requisito de enriquecimento em lote.

### Decisao tecnica

Foi adotada uma estratégia de fusao incremental: manter a listagem ampla como fonte de varredura e, quando faltar endpoint de detalhe, complementar por busca JSF de unidade para anexar `detailActionUrl/detailActionPayload` por codigo de componente.

### Evidencia objetiva

- Baseline completa pos-ajuste manteve estabilidade de processamento (568/568 unidades).
- Cobertura de detalhe por acao subiu para 7.427 componentes (30,35%).
- Cobertura de ementa subiu para 6.580 componentes (26,89%).
- Migration de `component_relations` aplicada em ambiente homologado local, com leitura SQL real de relacao persistida e limpeza rastreada.

### Impacto academico

O resultado transforma um requisito antes parcialmente estrutural em evidencia operacional mensuravel: houve ganho concreto na coleta rica em lote, mantendo rastreabilidade de governanca de dados e validacao em banco homologado. Permanecem lacunas de cobertura em equivalencias e co-requisitos, claramente delimitadas como trabalho incremental posterior.