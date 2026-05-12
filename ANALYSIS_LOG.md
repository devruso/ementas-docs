# Diario de Analise Tecnica (BDCP)

## 2026-05-11 - Convite por e-mail com fallback sem SMTP em ambiente de desenvolvimento

### Problema reportado

- Fluxo de convite e envio de credenciais ficava dependente de SMTP configurado, bloqueando operação local quando credenciais não estavam válidas.

### Implementacao

- Backend (`MailerService`):
  - Mantido modo explícito `MAILER_MOCK=true`.
  - Adicionado fallback automático para mock quando `MAILER_USER`/`MAILER_PASSWORD` não estão definidos.
  - Em fallback, o backend registra conteúdo do e-mail em log e não interrompe o fluxo de criação/convite.
- Backend (`UserService.createTeacherByAdmin`):
  - `emailDeliveryStatus` passa a refletir o modo real retornado pelo `Mailer` (`sent` ou `mock`), sem inferência indireta por variável de ambiente.
- Documentação (`ementas-api/README.md`):
  - Seção de mailer atualizada para deixar explícito que SMTP é opcional em desenvolvimento.

### Evidencias de validacao

- `ementas-api`:
  - `npm run typecheck` concluido sem erro.

## 2026-05-11 - Unicidade de numero de ATA com idempotencia e concorrencia no publish

### Problema reportado

- Publicacoes concorrentes de disciplinas diferentes podiam reutilizar o mesmo numero de ATA, gerando inconsistencias de governanca.

### Implementacao

- Backend (`ComponentDraftService.approve`):
  - Adicionado pre-check de disponibilidade do numero de ATA para logs de aprovacao.
  - Adicionado tratamento explicito para conflito de unicidade em corrida concorrente (erro 409 com mensagem amigavel).
- Banco (`migration 1778122800000`):
  - Criado indice unico parcial em `component_logs` para `LOWER(BTRIM(agreement_number))` apenas quando `type = 'approval'` e numero informado.
  - Incluida verificacao de duplicidades preexistentes na migration para falhar com diagnostico claro em caso de base inconsistente.

### Evidencias de validacao

- `ementas-api`:
  - `npm run typecheck` concluido sem erro.
  - `npm run migration:run` executado com sucesso, aplicando `addUniqueApprovalAgreementNumber1778122800000`.
  - Checagem SQL de duplicidades atuais (`component_logs` de `approval` por `LOWER(BTRIM(agreement_number))`) retornou `0 rows`.
  - Teste de integracao adicionado para bloquear segunda publicacao com mesmo numero de ATA.

## 2026-05-11 - Polimento UX da validacao ABNT no fluxo de publicacao oficial

### Problema reportado

- Usuario final recebia erro 400 no momento de publicar sem orientacao suficiente sobre como corrigir referencias nao web sem ano.
- O rascunho era salvo (comportamento correto), mas faltava aviso preventivo explicito de que a publicacao oficial seguiria bloqueada.

### Implementacao

- Frontend (`DisciplineEditorForm`):
  - Adicionado painel de prontidao de publicacao com diagnostico em tempo real dos bloqueios de publicacao oficial.
  - Incluidos exemplos curtos de referencia ABNT (livro e web) ao lado do campo de referencias complementares.
  - Apos `Salvar`, quando houver pendencias de publicacao, a UI passa a exibir aviso claro: rascunho salvo com sucesso, publicacao ainda bloqueada.
  - Fluxo `Salvar e publicar` manteve bloqueio por validacao, agora com feedback reforcado no painel e nos campos.
- Frontend (`DisciplineDetailsPage`):
  - Erro do modal de publicacao passou a mapear mensagens ABNT para texto amigavel e acionavel, com exemplo e orientacao de continuidade por rascunho.
- Backend (`ComponentDraftService`):
  - Mensagens de erro ABNT para referencias basicas/complementares foram tornadas acionaveis com exemplo de formato esperado.

### Evidencias de validacao

- `ementas-app`:
  - `npm run typecheck` concluido sem erro.
  - `npm run test -- --run src/components/DisciplineEditorForm.test.tsx src/pages/DisciplineEditPage.test.tsx` aprovado (2/2).
  - `npm run test -- --run src/pages/DisciplineDetailsPage.test.tsx` aprovado (9/9), incluindo caso de erro ABNT no modal.
- `ementas-api`:
  - `npm run typecheck` concluido sem erro.
- Runtime local:
  - `docker compose up -d --build api app` concluido com sucesso.
  - `GET /api/status` retornando `{"ok":true}`.

## 2026-05-11 - Correcoes de exportacao oficial, metadados de aprovacao e convite por e-mail

### Problemas reportados

- Metadados de aprovacao na tela de exportacao oficial aparecendo como `Nao informada`/`Nao informado` mesmo com historico existente.
- PDF/DOCX oficial com quebra visual por renderizacao de modalidade (`Presencial`) fora do padrao esperado do template.
- Convite por e-mail sem rastreabilidade clara entre envio real, modo mock e falha SMTP.

### Implementacao

- Frontend (`DisciplineDetailsPage`):
  - Calculo de ultima aprovacao passou a usar historico consolidado (logs da disciplina + logs carregados), com deduplicacao por id, evitando falso negativo por paginação.
- Backend (`ComponentService.export`):
  - Exportacao oficial passou a carregar `logs.user` explicitamente na query, garantindo `Publicado por` quando houver log de aprovacao.
  - Normalizacao da modalidade no template oficial para `Disciplina Teórico /Prática` quando aplicavel, removendo variacoes que quebravam layout no PDF.
- Backend/App (`createTeacherByAdmin`):
  - Fluxo agora retorna `emailDeliveryStatus` (`sent|mock|failed|disabled`) e `emailDeliveryError` para rastreabilidade operacional.
  - UI de usuarios exibe feedback explicito para envio real, mock e falha de SMTP.

### Evidencias de validacao

- `ementas-api`:
  - `npm run typecheck` concluido sem erro.
- `ementas-app`:
  - `npm run typecheck` concluido sem erro.
  - `npm run test -- --run src/pages/UsersPage.test.tsx src/pages/DisciplineDetailsPage.test.tsx` aprovado (12/12).

### Observacao operacional

- No ambiente local atual, `MAILER_MOCK=true` e a verificacao SMTP com as credenciais atuais falha com `535-5.7.8 Username and Password not accepted` (Gmail). Portanto, envio real requer credencial valida (idealmente senha de app) e `MAILER_MOCK=false`.

## 2026-05-11 - Estabilizacao do fluxo de salvar rascunho e feedback de falha na Home

### Problema reportado

- Apos acionar salvar no editor de disciplina, a API podia entrar em estado degradado durante autosaves/edicoes sucessivas.
- Ao retornar para a Home, a listagem podia aparecer vazia sem mensagem clara de erro, gerando percepcao de perda de dados.

### Implementacao

- Backend (`ComponentDraftService`):
  - Transacoes de `update` e `approve` passaram a usar ciclo completo de `queryRunner.connect()`, `startTransaction()`, `commit/rollback` e `release()` em `finally`.
  - Preservacao de erros de dominio (`AppError`) no `update`, evitando mascaramento por erro generico.
- Frontend (`DisciplineListPage`):
  - Inclusao de estado de erro para carregamento da listagem principal e do dataset hibrido por departamento.
  - Exibicao explicita de painel de erro na tela, substituindo estado silencioso de grid vazio quando a API falhar.

### Evidencias de validacao

- `ementas-api`:
  - `npm run typecheck` concluido sem erro.
  - Suite completa de testes depende de banco local (`ECONNREFUSED` em testes de integracao SIGAA), sem relacao direta com a mudanca aplicada.
- `ementas-app`:
  - `npm run test -- --run` aprovado (31/31).
  - `npm run typecheck` concluido sem erro.

## 2026-05-06 - Padrao oficial de carga horaria (template UFBA atual)

### Decisao registrada

- O preenchimento de carga horaria no DOCX oficial foi estabilizado para o layout vigente do template UFBA.
- Vetor oficial por bloco: `T, T/P, P, PP, Ext, E, TOTAL`.
- Blocos cobertos: `CARGA HORARIA (estudante)`, `CARGA HORARIA (docente/turma)` e `MODULO`.

### Motivacao

- O template institucional vigente exige consistencia visual estrita nas colunas `TOTAL` e `E`.
- A prioridade desta etapa foi garantir robustez imediata com o layout efetivo de producao.

### Impacto esperado

- Presenca consistente das colunas `TOTAL` para estudante e docente/turma.
- Presenca consistente da coluna `E` no bloco de modulo.
- Base documentada para evolucao futura quando houver nova versao oficial do template.

## 2026-05-05 - Hardening do DOCX (assinatura) e padronizacao ABNT de referencias

### Problemas reportados

- Exportacao DOCX mantinha imagem sobre o bloco de assinatura docente, causando conflito visual no documento oficial.
- Em alguns cenarios de ajuste do template havia risco de perda da linha de assinatura do chefe.
- Referencias precisavam de padrao ABNT mais consistente, com data e horario de acesso para fontes web.

### Implementacao

- Backend DOCX:
  - Remocao controlada de `w:drawing`/`w:pict` no paragrafo institucional de `Docente(s) Responsavel(is)` durante o preenchimento do template.
  - Garantia explicita de preservacao da linha de assinatura do chefe (`Nome: ____ Assinatura: ____`).
  - Suporte a objetivos multiline com recuo por paragrafo e preenchimento adicional de `OBJETIVOS ESPECIFICOS` quando o heading existir no template.
- Referencias ABNT:
  - Criado helper reutilizavel para formatacao de referencias no backend e frontend.
  - Referencias web agora recebem normalizacao com `Disponivel em:` e `Acesso em: DD/MM/AAAA, HH:MM` quando ausente.
  - Publicacao no frontend passou a validar referencias nao-web sem ano, com mensagem explicita de conformidade ABNT.

### Evidencias de validacao

- `ementas-api`:
  - `npm run -s typecheck` concluido sem erro.
  - `npm test -- --runInBand src/tests/ReferenceSections.spec.ts` aprovado (5/5).
  - Guardrails adicionados em `ComponentDocumentFlow.spec.ts` para bloquear imagem no paragrafo institucional e verificar linha de assinatura do chefe.
- `ementas-app`:
  - `npm run -s typecheck` concluido sem erro.
  - `npm run -s test:run -- src/lib/componentDraft.test.ts src/components/DisciplineEditorForm.test.tsx` aprovado (5/5).

### Bloqueio residual

- Suite E2E de exportacao documental no backend continua dependente de `testdatabase` local para execucao completa (`ComponentDocumentFlow.spec.ts`).

### Execucao real de validacao (curta/media/longa)

- Foi criado um lote real de 3 documentos DOCX a partir do pipeline atual de exportacao (`fillDocxTemplateFromBase`) usando script de geracao dedicado.
- Arquivos gerados:
  - `ementas-api/tmp/docx-validation/docx-curta-IC900.docx`
  - `ementas-api/tmp/docx-validation/docx-media-IC901.docx`
  - `ementas-api/tmp/docx-validation/docx-longa-IC902.docx`
- Preflight DOCX executado em lote com resultado `3/3` aprovados nos checks obrigatorios:
  - integridade ZIP/XML
  - ausencia de caracteres de controle invalidos
  - ausencia de drawing no paragrafo institucional de assinatura docente
  - presenca da linha de assinatura do chefe
  - leitura Mammoth registrada como check opcional (pode retornar limitacao da lib para alguns documentos complexos sem invalidar o DOCX).

## 2026-05-05 - Correção de nível acadêmico e exportação DOCX com template base

### Problemas reportados

- Filtro de nível acadêmico sem resultados em mestrado/doutorado por importação inicial concentrada em graduação.
- Exportação DOCX com perda de identidade visual por geração via HTML, divergindo do modelo Word institucional.

### Implementação

- Importação SIGAA passou a aceitar `academicLevel=all` no backend e no frontend.
- Fluxo `all` ganhou suporte a `sourceIdsByLevel` (IDs distintos para graduação/mestrado/doutorado), permitindo carga geral real por nível.
- Exportação DOCX foi migrada para preenchimento direto do `UFBA_TEMPLATE.docx` (substituição de conteúdo no XML do documento), preservando estrutura e formatação base do Word.

### Evidências locais

- API em execução local via Docker com migração aplicada.
- Exportação DOCX validada com preservação do cabeçalho institucional e substituição dos dados do componente (sem textos fixos do template de exemplo).
- Importação multi-fonte por nível validada: `mestrado` populado localmente; `doutorado` depende de fonte SIGAA com oferta disponível.

## 2026-05-05 - Execucao do slice de migracao de referencias estruturadas

### Implementacao realizada

- Migration aditiva criada para `components` e `component_drafts` com novos campos `referencesBasic` e `referencesComplementary`.
- Backfill inicial aplicado na migration sem perda historica, preservando `bibliography` legado.
- Servicos de create/update (component e draft) passaram a sincronizar campos novos com `bibliography` para manter compatibilidade de contrato.
- Exportacao oficial passou a priorizar campos estruturados e manter fallback para texto legado.
- Frontend passou a enviar e consumir referencias estruturadas (`referencesBasic`/`referencesComplementary`) no fluxo editorial e na importacao documental.

### Evidencias de validacao

- Frontend: novos testes executados com sucesso (`componentDraft.test.ts` e `DisciplineEditorForm.test.tsx`), 3 testes aprovados.
- Backend: validacao estatica por arquivo sem erros no editor para migration, entidades, servicos e teste novo `ReferenceSections.spec.ts`.

### Bloqueio local identificado

- Execucao de `npm run typecheck` e `npm test` no `ementas-api` bloqueada por ambiente sem binarios locais (`tsc`/`jest` nao reconhecidos), indicando dependencias nao instaladas neste workspace da API.

## 2026-05-05 - Fortalecimento template-first no fluxo editorial

### Objetivo da analise

- Tornar explícito no produto que o preenchimento oficial segue o template institucional (independente de SIGAA/SIAC).
- Garantir cobertura de campos críticos para publicação oficial, com ênfase em Referências.
- Melhorar consistência entre editor, visualização e exportação (PDF/DOCX).

### Decisoes implementadas

- Editor passou a separar `Referencias basicas` e `Referencias complementares` no frontend.
- Publicação via editor passou a validar campos essenciais do template: ementa, objetivos, conteúdo programático, metodologia, avaliação da aprendizagem e referências básicas.
- Fluxo de edição (`DisciplineEditPage`) recebeu autopreenchimento de data de aprovação (data atual) e sugestão automática de número de ATA.
- Modal de aprovação ganhou orientação explícita: assinatura de aprovação não é senha e pode ser configurada na página de perfil.
- Template de exportação deixou de duplicar bibliografia e passou a separar referências básicas/complementares por parsing estruturado do campo armazenado.
- Texto de aprovação no template foi neutralizado para "sistema institucional", removendo citação direta ao BDCP.

### Evidencia tecnica coletada

- Não foram detectados erros estáticos nos arquivos alterados (checagem por arquivo no editor).
- Estrutura de payload da API foi preservada (continua usando `bibliography`), evitando breaking change.

### Risco residual aberto

- Migração futura recomendada: separar referências básicas/complementares em colunas próprias no backend para eliminar necessidade de parsing textual.
- Testes automatizados específicos desse slice (formulário + template parser) ainda podem ser adicionados para regressão de borda.

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