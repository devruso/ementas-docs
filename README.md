# General Documentation
## Database System of Syllabus of the Subjects of the Federal University of Bahia
### In this repository you found all documentation of this project.

- [Requirements Documentation](REQUIREMENTS.md)
- [Architectural Documentation](ARCHITECTURE.md)
- [Implementation Documentation](IMPLEMENTATION.md)
- [Diario de Analise Tecnica](ANALYSIS_LOG.md)
- [Diario de Escrita Academica](WRITING_LOG.md)
- [Matriz Final de Cobertura SIGAA (2026-05-05)](SIGAA_COVERAGE_MATRIX_FINAL_2026-05-05.md)

- Snapshot canônico de regressão SIGAA: `ementas-api/src/tests/fixtures/sigaa/full-catalog-results.2026-05-05.prd-final.json`

- [Specifications](./assets/especification.pdf)
- [Clickup Manager](https://app.clickup.com/31043046/settings/team/31043046/project)
- [Figma Prototype](https://www.figma.com/file/4sI0IP4YRbJTMOepIR8XaY/Prot%C3%B3tipo?node-id=0%3A1)

## Incrementos Backend Recentes

- Importacao de documento para rascunho via endpoint autenticado de preview multipart em ementas-api, com suporte inicial a PDF e DOCX.
- Extracao heuristica de codigo, nome, departamento, semestre, ementa, objetivos, conteudo programatico, metodologia, avaliacao, bibliografia, pre-requisitos e cargas para revisao humana antes do salvamento.
- Exportacao PDF atualizada para incluir metadados de aprovacao formal da disciplina quando existirem no historico.
- Pre-requisitos agora seguem classificacao operacional no frontend (existente, pendente e nao se aplica), com selecao automatica por disciplinas publicadas e rascunhos; no backend, codigos sao normalizados e autorreferencia continua bloqueada.
- Gestao de usuarios atualizada com endpoint administrativo de criacao direta de professor, com senha provisoria segura gerada no backend e envio opcional de credenciais via SMTP institucional.
- Governanca de perfis evoluida com papel `SUPER_ADMIN` formal (compativel com `admin` atual), incluindo endpoint de alteracao de role protegido por super administracao.
- Publicacao oficial com politica de assinatura obrigatoria: aprovacao de rascunho agora valida assinatura configurada no perfil e, quando houver arquivo de imagem, incorpora a assinatura do docente no local oficial do artefato DOCX/PDF exportado.
- Publicacao global irrestrita removida para consulta de disciplinas e rascunhos; acesso publico agora ocorre por compartilhamento temporario com token, expiracao e revogacao.
- Painel de disciplinas evoluido com governanca operacional de compartilhamento: listagem de links publicos ativos por disciplina, revogacao unitaria e revogacao em massa no proprio app.
- Crawler evoluido para SIGAA publico (departamento/programa) com classificacao por nivel academico (`graduacao`, `mestrado`, `doutorado`), preservando o conteudo programatico como fonte canonica do EMENTAS.
- Parser do crawler SIGAA refinado com regressao offline baseada em HTML real: eliminacao de falsos positivos por ruído tecnico (tokens CSS/JSF) e fallback de URLs por tipo de fonte (`department`/`program`).
- Descoberta de fonte/IDs via fluxo JSF concluida para DCC (`1114`), DCI (`2440`) e PGCOMP (`1820`), com matriz de casos reais e relatorio final de acuracia para banca.
- Resumo executivo para slides da defesa, com tabela consolidada e grafico de acuracia: `SIGAA_ACCURACY_SLIDES_2026-05-05.md`.
- Painel de usuarios evoluido para governanca de perfis por `SUPER_ADMIN`, com promocao/rebaixamento de roles diretamente na interface de administracao.
- PRD de crawler executado com conexao do fluxo JSF no pipeline amplo, teste de persistencia em `component_relations` e evidencia de homologacao local em `ANALYSIS_LOG.md` e `SIGAA_COVERAGE_MATRIX_FINAL_2026-05-05.md`.

## Atualizacao 2026-05-05

### Changelog Academico dos Commits Publicados

- Commit `68a429d` em `ementas-api`: ajuste de infraestrutura no TypeScript para alinhar a resolucao de modulos do editor com o comportamento efetivo do compilador e eliminar falso positivo de dependencia relacionada ao TypeORM.
- Commit `901435a` em `ementas-app`: evolucao funcional do frontend com governanca por `SUPER_ADMIN`, assinatura obrigatoria para aprovacao oficial, compartilhamento publico temporario por token e refinamentos de experiencia de uso em fluxos de publicacao e consulta.

### Evidencias de Validacao

- `ementas-api`: `npm run typecheck` executado com sucesso apos o ajuste de configuracao em `tsconfig.json`.
- `ementas-app`: `npm run typecheck` executado com sucesso.
- `ementas-app`: `npm run test:run` executado com sucesso, totalizando 15 testes verdes no slice afetado.

### Texto em Tom de Monografia

#### Problema

O EMENTAS apresentava dois tipos distintos de necessidade evolutiva. No backend, havia divergencia entre o diagnostico do editor e a resolucao real de modulos do TypeScript, produzindo ruido operacional no desenvolvimento. No frontend, a cobertura funcional precisava avancar em aspectos centrais de governanca academica, especialmente na administracao de perfis privilegiados, na formalizacao da aprovacao de alteracoes de disciplinas e na disponibilizacao controlada de conteudo oficial para acesso publico temporario.

#### Decisao Tecnica

Optou-se por separar a evolucao em dois eixos complementares. O primeiro concentrou um ajuste nao funcional de infraestrutura no `ementas-api`, com foco em previsibilidade do ambiente de desenvolvimento. O segundo concentrou um slice funcional no `ementas-app`, reunindo a introducao do papel `SUPER_ADMIN`, a exigencia de assinatura para publicacao oficial e a criacao de links publicos temporarios com expiracao e revogacao. Essa abordagem favoreceu rastreabilidade entre requisito, implementacao, validacao e historico Git.

#### Evidencia

As mudancas foram publicadas em commits distintos e semanticamente coerentes. O backend foi consolidado no commit `68a429d`, enquanto o frontend foi consolidado no commit `901435a`. Como comprovacao tecnica, o `ementas-api` passou em `npm run typecheck`, e o `ementas-app` passou em `npm run typecheck` e `npm run test:run`, com cobertura direta dos fluxos de aprovacao e gestao de usuarios.

#### Impacto Academico

O resultado amplia a robustez do sistema, melhora a auditabilidade das operacoes administrativas e reforca a aderencia do EMENTAS ao contexto institucional do TCC. Em especial, a introducao de governanca por perfil privilegiado, de validacao explicita para aprovacao oficial e de compartilhamento publico temporario fortalece a confiabilidade do processo academico sem transferir regras criticas para a interface.

## Operacao do Endpoint de Importacao SIGAA Publico

### Endpoint

- Metodo: `POST`
- Rota: `/api/components/import/sigaa-public`
- Autenticacao: `Bearer token`
- Autorizacao: apenas perfis administrativos (`admin` e `super_admin`)

### Payload de Entrada

```json
{
	"sourceType": "department",
	"sourceId": "1114",
	"academicLevel": "graduacao"
}
```

Campos aceitos:
- `sourceType`: `department` ou `program`
- `sourceId`: identificador publico da unidade/programa no SIGAA
- `academicLevel`: `graduacao`, `mestrado` ou `doutorado`

### Resposta de Sucesso (201)

```json
{
	"source": "sigaa-public",
	"requested": 133,
	"created": 120,
	"skippedExisting": 13,
	"failed": 0,
	"failures": [],
	"parameters": {
		"sourceType": "department",
		"sourceId": "1114",
		"academicLevel": "graduacao"
	}
}
```

Interpretacao operacional:
- `requested`: total de disciplinas identificadas na fonte consultada
- `created`: total efetivamente inserido
- `skippedExisting`: total ignorado por ja existir no EMENTAS
- `failed`: total com falha de processamento
- `failures`: lista de falhas por codigo para auditoria

### Erros Esperados

- `400`: parametros obrigatorios ausentes ou invalidos
- `401`: usuario autenticado sem permissao administrativa para importacao
- `404`: nenhuma disciplina encontrada na fonte SIGAA informada




