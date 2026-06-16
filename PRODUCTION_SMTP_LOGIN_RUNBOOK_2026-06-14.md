# Runbook - Login em producao e SMTP Gmail no EMENTAS

## Objetivo

Resolver o bloqueio de login em producao, habilitar envio real de e-mails com Gmail e registrar o checklist minimo para operar o EMENTAS no dominio institucional.

## Diagnostico objetivo

### 1. Login em producao

Achado principal:

- O frontend publicado estava apontando para `http://localhost:3333/api` no bundle estatico, o que impede autenticacao real fora do ambiente local.

Impacto:

- A tela de login ate carrega, mas as requisicoes de autenticacao nao alcançam a API correta em producao.

Correcao implementada:

- O app agora aceita `VITE_API_URL` em runtime via arquivo `runtime-config.js` gerado no startup do container.
- Se nenhuma variavel for definida, o fallback passa a ser `window.location.origin/api`.

Arquivos alterados:

- `ementas-app/src/lib/api.ts`
- `ementas-app/index.html`
- `ementas-app/public/runtime-config.js`
- `ementas-app/nginx.conf`
- `ementas-app/Dockerfile`
- `ementas-app/docker-entrypoint.d/40-runtime-config.sh`

### 2. Convite e recuperacao de senha por e-mail

Achado principal:

- O backend ja possuia `nodemailer`, mas a configuracao era fraca para producao: remetente hardcoded, placeholders inseguros e sem contrato operacional claro para Gmail.

Correcao implementada:

- SMTP configuravel por variaveis de ambiente.
- Remetente padrao alinhado com `ementas.ic.ufba@gmail.com`.
- Fallback mock mantido para desenvolvimento.
- README da API atualizado com configuracao recomendada para Gmail App Password.

Arquivos alterados:

- `ementas-api/src/middlewares/Mailer.ts`
- `ementas-api/.env.example`
- `ementas-api/README.md`
- `ementas-api/src/tests/UserTest.spec.ts`
- `ementas-api/src/tests/AuthTest.spec.ts`

## Configuracao de producao recomendada

### Frontend

Defina no app do frontend:

```sh
VITE_API_URL=https://api.ementas.app.ic.ufba.com.br/api
```

Se o backend estiver exposto no mesmo dominio do frontend com reverse proxy de `/api`, essa variavel pode ficar ausente.

### Backend SMTP Gmail

Defina na API:

```sh
MAILER_HOST=smtp.gmail.com
MAILER_PORT=587
MAILER_SECURE=false
MAILER_TLS_REJECT_UNAUTHORIZED=false
MAILER_REQUIRE_TLS=false
MAILER_CONNECTION_TIMEOUT_MS=10000
MAILER_GREETING_TIMEOUT_MS=10000
MAILER_SOCKET_TIMEOUT_MS=15000
MAILER_USER=ementas.ic.ufba@gmail.com
MAILER_PASSWORD=<gmail-app-password>
MAILER_FROM_NAME=EMENTAS IC UFBA
MAILER_FROM_ADDRESS=ementas.ic.ufba@gmail.com
MAILER_MOCK=false
```

### Backend API no Dokku

Configuracao minima recomendada para a app `ementas-api` no Dokku:

```sh
dokku config:set ementas-api \
NODE_ENV=production \
PORT=3333 \
DB_HOST=<host-postgres> \
DB_NAME=ementas \
DB_PORT=<porta-postgres> \
DB_USER=<usuario-postgres> \
DB_PASS=<senha-postgres> \
JWT_SECRET=<jwt-secret-forte> \
JWT_DEADLINE=28800 \
JWT_REFRESH_SECRET=<jwt-refresh-secret-forte> \
JWT_REFRESH_DEADLINE=86400 \
SWAGGER_SERVER_URL=https://api.ementas.app.ic.ufba.com.br \
MAILER_HOST=smtp.gmail.com \
MAILER_PORT=587 \
MAILER_SECURE=false \
MAILER_TLS_REJECT_UNAUTHORIZED=false \
MAILER_USER=ementas.ic.ufba@gmail.com \
MAILER_PASSWORD=<gmail-app-password> \
MAILER_FROM_NAME="EMENTAS IC UFBA" \
MAILER_FROM_ADDRESS=ementas.ic.ufba@gmail.com \
MAILER_MOCK=false \
LIBREOFFICE_BIN=/usr/bin/libreoffice \
PDF_CONVERSION_TIMEOUT_MS=45000 \
STORAGE_PROVIDER=local \
STORAGE_LOCAL_BASE_PATH=/app/storage \
STORAGE_S3_ENABLED=false
```

Variaveis opcionais mas importantes:

```sh
dokku config:set ementas-api \
SUPER_ADMIN_EMAIL=<email-ufba> \
SUPER_ADMIN_NAME="Seu Nome" \
SUPER_ADMIN_PASSWORD=<senha-forte>
```

Se decidir usar bootstrap automatico de carga inicial, acrescentar:

```sh
dokku config:set ementas-api \
BOOTSTRAP_IMPORT_ON_EMPTY_DB=true \
BOOTSTRAP_IMPORT_SOURCE=sigaa-public \
BOOTSTRAP_ADMIN_EMAIL=<email-ufba> \
BOOTSTRAP_ADMIN_NAME="Bootstrap Super Admin" \
BOOTSTRAP_ADMIN_PASSWORD=<senha-forte> \
BOOTSTRAP_SIGAA_SOURCE_TYPE=department \
BOOTSTRAP_SIGAA_SOURCE_ID=<id-fonte> \
BOOTSTRAP_SIGAA_ACADEMIC_LEVEL=all
```

### Frontend no Dokku

Configuracao minima recomendada para a app `ementas`:

```sh
dokku config:set ementas \
VITE_API_URL=https://api.ementas.app.ic.ufba.com.br/api
```

Se o frontend e a API estiverem no mesmo dominio com reverse proxy de `/api`, a variavel pode ser omitida.

Observacoes:

- Use App Password do Gmail; nao use a senha comum da conta.
- Se `MAILER_MOCK=true`, o backend continua sem enviar e-mail real.
- O endpoint de convite por e-mail agora retorna `emailDeliveryStatus=failed` com `emailDeliveryError` quando o SMTP falhar, mantendo o link de convite para compartilhamento manual.
- Recuperacao de senha nao revela mais se o e-mail existe no banco, reduzindo enumeracao de contas.

## Atualizacao 2026-06-16 (producao)

- Exclusao de usuario endurecida: apenas `SUPER_ADMIN` pode remover contas.
- Autoexclusao bloqueada para evitar perda de governanca.
- Exclusao aplica `is_deleted=true` e `is_user_active=false` (soft delete).
- Lista de usuarios nao exclui mais automaticamente o usuario autenticado, facilitando auditoria de perfis.
- Convite e recuperacao de senha com e-mail HTML (UTF-8), botao de acao e identidade visual do IC.
- Backend de convite agora envia `text + html` e preserva fallback para compartilhamento manual do link quando o SMTP falha.
- Ajuste no importador SIGAA: em `academicLevel=all`, o backend aceita IDs por nivel (`sourceIdsByLevel`) sem exigir `sourceId` global.
- Favicon reforcado no frontend com `icon`, `shortcut icon` e `apple-touch-icon` com cache-busting.

## O que ainda falta para uso real em producao

### 1. Garantir um usuario inicial com acesso administrativo

Sem `super_admin`, voce nao consegue governar convites, perfis nem onboarding de professores.

Opcao recomendada:

```sh
npm run user:ensure-super-admin -- --email=<seu-email-ufba> --name="Seu Nome" --password="SenhaForte@2026"
```

Alternativa:

- Configurar `SUPER_ADMIN_EMAIL`, `SUPER_ADMIN_NAME` e `SUPER_ADMIN_PASSWORD` e executar o script no ambiente do servidor.

### 2. Confirmar migracoes do banco

Antes do uso real:

```sh
npm run migration:run
```

### 3. Verificar URL publica real da API

Se o frontend usar `VITE_API_URL`, a URL precisa estar acessivel externamente e responder em `/api/auth/login`.

Teste minimo:

```sh
curl -X GET https://api.ementas.app.ic.ufba.com.br/api/status
```

### 4. Confirmar template DOCX e LibreOffice

Para exportacao oficial em PDF/DOCX funcionar em producao:

- `UFBA_TEMPLATE.docx` precisa existir no backend.
- LibreOffice precisa estar disponivel no runtime da API.

### 5. Validar persistencia local atual

Como o storage S3 de assinaturas foi adiado, o backend continua dependendo do provider local para arquivos.

Minimo necessario:

- Volume persistente montado para `storage` na API.

### 6. Corrigir a documentacao publica da API

- Defina `SWAGGER_SERVER_URL` com a URL real do backend; sem isso, a UI de docs pode anunciar um host incorreto.

## Fluxo de validacao pos-deploy

1. Acessar o frontend publicado.
2. Fazer login com o `super_admin` criado.
3. Abrir a tela de usuarios.
4. Enviar convite por e-mail para um endereco `@ufba.br`.
5. Confirmar recebimento do e-mail.
6. Abrir o link `/cadastrar/{token}`.
7. Concluir cadastro do professor.
8. Testar recuperacao de senha.

## Evidencias de validacao desta etapa

Frontend:

- `npm run typecheck` passou.
- `npm run build` passou.
- `docker build` ficou bloqueado por erro de rede no `npm ci`, nao por erro funcional da alteracao.

Backend:

- `npm test -- --runTestsByPath src/tests/UserTest.spec.ts src/tests/AuthTest.spec.ts` passou com banco local preparado.
- `npm run typecheck` passou.

## Resumo executivo para monografia

Foi identificada uma falha de configuracao de ambiente no frontend que tornava o login em producao inviavel, pois o bundle apontava para a API local. A correcao adotada foi mover a URL da API para configuracao em runtime no container do frontend, reduzindo acoplamento com o build e aumentando portabilidade entre ambientes. Em paralelo, o subsistema de e-mail foi endurecido para uso com Gmail via SMTP, permitindo convite institucional e recuperacao de senha com remetente padrao do projeto. Essas mudancas aumentam a prontidao operacional do sistema sem alterar regras centrais de negocio.