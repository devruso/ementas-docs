# Runbook - MinIO no Dokku para EMENTAS (IC UFBA)

## Objetivo
Provisionar um MinIO como aplicacao independente no Dokku, habilitar persistencia e conectar a API do EMENTAS via provider S3-compatible sem alterar regra de negocio.

## Automacao pronta (CLI/SSH)
Existe um kit E2E pronto em `ementas-docs/ops/dokku` com scripts para deploy, validacao de bucket e configuracao da API.

Arquivos principais:
- `ementas-docs/ops/dokku/run-minio-ementas-e2e.ps1`
- `ementas-docs/ops/dokku/deploy-minio-dokku.ps1`
- `ementas-docs/ops/dokku/validate-minio-bucket-e2e.ps1`
- `ementas-docs/ops/dokku/configure-ementas-api-s3.ps1`
- `ementas-docs/ops/dokku/README.md`
- `ementas-docs/ops/dokku/EXECUTION_LOG_TEMPLATE.md`

Fluxo recomendado:
1. Rodar `run-minio-ementas-e2e.ps1` com os parametros do ambiente.
2. Se necessario, executar etapas individuais para troubleshooting.
3. Registrar evidencias no template de execucao.

## Diagnostico Atual
- A API ja possui provider local e provider S3-compatible implementados.
- A selecao de provider ja e feita por variavel de ambiente.
- Upload de assinatura (PNG/JPG/WEBP ate 2MB) ja existe e possui testes.
- Portanto, a integracao com MinIO e operacionalmente de infraestrutura e configuracao.

## Evidencias no codigo
- Factory de provider: ementas-api/src/services/storage/createStorageProvider.ts
- Provider S3-compatible: ementas-api/src/services/storage/S3CompatibleFileStorageProvider.ts
- Upload da assinatura: ementas-api/src/services/UserService.ts
- Endpoint multipart de assinatura: ementas-api/src/routers/UserRouter.ts

## Arquitetura recomendada
1. Criar app dedicada para MinIO no Dokku (nao embutir no container da API).
2. Solicitar ao suporte IC o bind de armazenamento persistente no path /app/storage do container MinIO.
3. Configurar a API EMENTAS para usar provider S3-compatible apontando para esse MinIO.

## Etapa 1 - Criar app MinIO no Dokku
Opcoes:
1. Dokku Web (recomendado se ja estiver em uso).
2. CLI do Dokku (via SSH).

### Parametros da app MinIO
- Nome sugerido da app: minio-ementas
- Imagem: minio/minio:latest
- Comando de start: minio server /data --console-address :9001
- Porta da API S3: 9000
- Porta do console: 9001

### Variaveis de ambiente da app MinIO
- MINIO_ROOT_USER=<usuario-admin-forte>
- MINIO_ROOT_PASSWORD=<senha-admin-forte>
- MINIO_BROWSER_REDIRECT_URL=https://<dominio-console>
- MINIO_SERVER_URL=https://<dominio-api-s3>
- MINIO_SUBNET_LICENSE=<token-opcional-do-plano-minio>

Recomendacao de seguranca:
1. Armazene token e segredos em variaveis de ambiente do shell/CI.
2. Evite colar token MinIO diretamente no historico de comandos.

## Etapa 2 - Persistencia com suporte IC
Apos criar a app, responder ao professor/suporte com:
1. Nome da app no Dokku.
2. Confirmacao de que o volume deve mapear /app/storage (host) para /data (container MinIO).
3. Solicitar persistencia e confirmar politica de backup/retenÃ§Ã£o.

Resultado esperado:
- Reinicio da app MinIO nao perde objetos do bucket.

## Etapa 3 - Bucket e politica minima
Criar bucket exclusivo do EMENTAS (exemplo: ementas-signatures-hml) e aplicar permissao minima:
- PutObject
- GetObject
- DeleteObject

Observacao:
- Evitar reutilizar bucket compartilhado com outras aplicacoes.
- O EMENTAS nao precisa de permissao administrativa global no MinIO.

## Etapa 4 - Configurar API EMENTAS para S3-compatible
No ambiente da API:
- STORAGE_PROVIDER=s3
- STORAGE_S3_ENABLED=true
- STORAGE_S3_ENDPOINT=https://<dominio-api-s3>
- STORAGE_S3_REGION=us-east-1
- STORAGE_S3_BUCKET=<bucket-ementas>
- STORAGE_S3_ACCESS_KEY_ID=<access-key-tecnica>
- STORAGE_S3_SECRET_ACCESS_KEY=<secret-key-tecnica>
- STORAGE_S3_FORCE_PATH_STYLE=true
- STORAGE_S3_PUBLIC_BASE_URL=<opcional>

Notas:
1. Em MinIO, manter STORAGE_S3_FORCE_PATH_STYLE=true para compatibilidade previsivel.
2. Se o endpoint usar certificado interno, validar cadeia TLS no host da API.

## Etapa 5 - Teste funcional ponta a ponta
1. Login como professor.
2. Upload em Perfil com arquivo PNG/JPG/WEBP <= 2MB.
3. Confirmar HTTP 200 no endpoint /api/users/update/signature/file.
4. Confirmar metadados no usuario:
   - signature_file_key
   - signature_file_provider=s3
   - signature_file_content_type
   - signature_file_size
   - signature_file_hash
5. Consultar preview em /api/users/signature/file.
6. Gerar exportacao oficial e validar assinatura no documento.

Observacao operacional:
1. No script `run-minio-ementas-e2e.ps1`, `S3AccessKeyId` e `S3SecretAccessKey` sao opcionais. Se omitidos, o fluxo usa `MinioRootUser` e `MinioRootPassword` como fallback para validacao e configuracao da API.

## Casos negativos obrigatorios
1. Sem arquivo: 400.
2. MIME invalido: 400.
3. Arquivo > 2MB: 400.
4. STORAGE_PROVIDER=s3 com STORAGE_S3_ENABLED=false: falha explicita na inicializacao.

## Rollback seguro
Se houver instabilidade no MinIO:
1. API:
   - STORAGE_PROVIDER=local
   - STORAGE_S3_ENABLED=false
   - STORAGE_LOCAL_BASE_PATH=storage
2. Reiniciar API.
3. Reexecutar upload e exportacao para validar fluxo local.

## Mensagem pronta para retorno ao suporte IC
"Criei a app minio-ementas no Dokku e preciso da ativacao de persistencia no container MinIO conforme combinado. Favor mapear /app/storage para /data e confirmar backup/retenÃ§Ã£o aplicados."

## Criterio de aceite
1. Upload de assinatura concluido com provider s3.
2. Preview de assinatura funcionando.
3. Exportacao oficial com assinatura de imagem funcionando.
4. Reinicio da app MinIO sem perda de objetos.


