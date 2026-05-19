# Checklist de Evidencias de Validacao (2026-05-06)

## 1) Ambiente limpo (rebuild do zero)
- [ ] Executar `docker compose down -v --remove-orphans` no projeto da API.
- [ ] Executar `docker compose build --no-cache` para rebuild completo de imagens.
- [ ] Executar `docker compose up -d` e confirmar stack ativa (`api`, `app`, `postgres`).
- [ ] Registrar evidencias de status (saida de `docker compose ps`).

## 2) Inicializacao e populacao automatica de dados
- [ ] Confirmar criacao das tabelas principais no schema publico (`components`, `component_drafts`, `users`, `migrations`).
- [ ] Validar contagem inicial de dados apos bootstrap:
  - [ ] `components_count > 0`
  - [ ] `drafts_count > 0`
  - [ ] `users_count >= 1`
- [ ] Registrar consultas SQL executadas e respectivos resultados.
- [ ] Registrar logs da API com evidencias de inicializacao bem-sucedida (sem falha persistente de conexao ao banco).

## 3) Verificacao de disponibilidade da aplicacao
- [ ] Confirmar frontend acessivel em `http://localhost:3000` (HTTP 200).
- [ ] Confirmar API acessivel em `http://localhost:3333`.
- [ ] Validar endpoint protegido sem token retornando erro de autenticacao esperado.

## 4) Qualidade tecnica (sem alteracao funcional)
- [ ] Confirmar `typecheck` do app com saida limpa.
- [ ] Confirmar `typecheck` da API com saida limpa.
- [ ] Confirmar reducao de warnings de IDE:
  - [ ] Deprecacoes de TypeScript no app silenciadas por configuracao.
  - [ ] Globais de Jest reconhecidos nos testes da API.
  - [ ] Aviso de tipagem de `Buffer.concat` eliminado no teste de fluxo documental.

## 5) Testes (registro para secao de validacao)
- [ ] Listar suites executadas no ciclo e resultado (pass/fail).
- [ ] Registrar data/hora e commit de referencia dos testes.
- [ ] Incluir evidencias de testes focados em fluxo documental e integracao app/api.

## 6) Rastreabilidade para a monografia
- [ ] Mapear cada evidencia para o objetivo de validacao correspondente.
- [ ] Separar claramente no texto: comportamento implementado vs. sugestoes futuras.
- [ ] Inserir no texto final:
  - [ ] Contexto do experimento (ambiente zerado)
  - [ ] Procedimento (rebuild + bootstrap + verificacoes)
  - [ ] Resultados observados (dados, disponibilidade, qualidade)
  - [ ] Ameacas a validade (ex.: warnings de IDE nao funcionais, dependencia de timing de subida inicial)

## 7) Exportacao oficial com assinatura digital (E2E)
- [x] Persistir assinatura de arquivo no perfil do docente aprovador (`image/png`, `image/jpeg` ou `image/webp`).
- [x] Confirmar no banco que `signature_file_key` foi associado ao usuario aprovador do componente.
- [x] Exportar DOCX oficial autenticado para componente publicado (`IC045`).
- [x] Verificar no DOCX:
  - [x] `word/media/signature-rId*.png` presente no pacote.
  - [x] relationship de imagem da assinatura em `word/_rels/document.xml.rels`.
  - [x] linha de assinatura do chefe permanece textual (sem desenho embutido indevido).
- [x] Exportar PDF oficial a partir do mesmo fluxo autenticado (status 200 e header `%PDF-`).
- [x] Registrar evidÃªncia visual do PDF em PNG (`ementas-docs/assets/validation-official-export-ic045-page1-2026-05-12.png`).
- [x] Registrar evidÃªncia visual especÃ­fica da pÃ¡gina de assinaturas no PDF (`ementas-docs/assets/validation-official-export-ic045-signature-page3-2026-05-12.png`).
- [x] Executar preflight documental do DOCX exportado com resultado aprovado.

## Evidencias coletadas neste ciclo (snapshot)
- Rebuild completo concluido com imagens atualizadas (`api` e `app`).
- Stack ativa com containers `api`, `app` e `postgres` em execucao.
- Frontend respondeu HTTP 200 na porta 3000.
- Banco populado automaticamente apos inicializacao:
  - `components_count = 132`
  - `drafts_count = 132`
  - `users_count = 1`
- Endpoint protegido da API sem token retornou erro de autenticacao esperado.

## Evidencias coletadas no ciclo de assinatura oficial (2026-05-12)
- Perfil exibindo preview persistido da assinatura do docente aprovador.
- Banco com `signature_file_key` preenchido para `jamilsonj@ufba.br`.
- DOCX oficial gerado: `ementas-api/tmp/e2e-exports/IC045-official.docx`.
- PDF oficial gerado: `ementas-api/tmp/e2e-exports/IC045-official.pdf`.
- Captura visual da renderizacao do PDF: `ementas-docs/assets/validation-official-export-ic045-page1-2026-05-12.png`.
- Captura visual da pagina com assinatura do docente: `ementas-docs/assets/validation-official-export-ic045-signature-page3-2026-05-12.png`.

