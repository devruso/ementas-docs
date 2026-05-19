# Automacao CLI Dokku - MinIO + EMENTAS (E2E)

## O que foi automatizado
1. Deploy de app MinIO no Dokku via SSH e git push de template Dockerfile.
2. Configuracao de dominio(s), proxy de portas e variaveis MinIO.
3. Tentativa de bind de persistencia host para /data no container MinIO.
4. Validacao E2E de bucket com cliente MinIO (mc) via Docker local.
5. Configuracao das variaveis S3 na API EMENTAS e restart da app.

## Scripts
- setup-ssh-dokku-host.ps1
- setup-ssh-dokku-host.cmd
- deploy-minio-dokku.ps1
- validate-minio-bucket-e2e.ps1
- configure-ementas-api-s3.ps1
- run-minio-ementas-e2e.ps1
- run-minio-ementas-e2e.cmd
- run-api-s3-only.ps1
- run-api-s3-only.cmd
- minio-template/Dockerfile

## Fluxo simplificado (quando MinIO/S3 ja existe)
Use este fluxo quando voce recebeu somente credenciais tecnicas (Access Key e Secret Key) e nao precisa criar uma nova app MinIO no Dokku.

1. Configurar variaveis no terminal local (opcional, para evitar segredo na linha de comando):

set S3_ACCESS_KEY_ID=SEU_ACCESS_KEY
set S3_SECRET_ACCESS_KEY=SEU_SECRET_KEY

2. Aplicar configuracao S3 na API em um comando:

ementas-docs\\ops\\dokku\\run-api-s3-only.cmd -DokkuHost IP_OU_DOMINIO_DOKKU -ApiAppName ementas-api -S3Endpoint https://minio-ementas.ic.ufba.br -S3Bucket ementas-signatures-hml

3. Se quiser pular a validacao de bucket (ex.: sem Docker local):

ementas-docs\\ops\\dokku\\run-api-s3-only.cmd -DokkuHost IP_OU_DOMINIO_DOKKU -ApiAppName ementas-api -S3Endpoint https://minio-ementas.ic.ufba.br -S3Bucket ementas-signatures-hml -SkipBucketValidation

## Execucao no CMD (sem sintaxe PowerShell)
Se voce estiver no Prompt de Comando do Windows (cmd.exe), use os wrappers .cmd:

1. Configurar alias SSH:

ementas-docs\\ops\\dokku\\setup-ssh-dokku-host.cmd -HostAlias dokku-ic -HostName IP_OU_DOMINIO_DOKKU

2. Rodar fluxo E2E completo:

ementas-docs\\ops\\dokku\\run-minio-ementas-e2e.cmd -DokkuHost dokku-ic -S3Domain minio-ementas.ic.ufba.br -ConsoleDomain minio-console-ementas.ic.ufba.br -MinioRootUser admin -MinioRootPassword SUA_SENHA_FORTE -S3Bucket ementas-signatures-hml -S3AccessKeyId EMENTAS_ACCESS_KEY -S3SecretAccessKey EMENTAS_SECRET_KEY -ApiAppName ementas-api

Opcional para plano MinIO Subnet/FREE (evite expor token no historico do shell):

set MINIO_SUBNET_LICENSE=SEU_TOKEN
ementas-docs\\ops\\dokku\\run-minio-ementas-e2e.cmd -DokkuHost dokku-ic -S3Domain minio-ementas.ic.ufba.br -ConsoleDomain minio-console-ementas.ic.ufba.br -MinioRootUser admin -MinioRootPassword SUA_SENHA_FORTE -S3Bucket ementas-signatures-hml -ApiAppName ementas-api -MinioSubnetLicense %MINIO_SUBNET_LICENSE%

## Setup SSH (se ainda nao houver host configurado)
1. Criar entrada no arquivo .ssh/config:

./setup-ssh-dokku-host.ps1 \
  -HostAlias dokku-ic \
  -HostName IP_OU_DOMINIO_DOKKU \
  -IdentityFile CAMINHO_CHAVE_PRIVADA
  
Se voce omitir -IdentityFile, o script usa automaticamente:
- C:/Users/jamil/.ssh/id_ed25519_ic_ufba

2. Testar conectividade:

ssh dokku-ic dokku version

## Pre-requisitos locais
1. PowerShell 5.1+.
2. Git instalado.
3. SSH funcionando para dokku@SEU_HOST.
4. Docker local (somente para validacao de bucket com mc).

## Pre-requisitos remotos (Dokku)
1. Dokku acessivel por SSH.
2. Plugin de storage habilitado para mount persistente.
3. Plugin de letsencrypt instalado (opcional, mas recomendado).

## Execucao unica E2E
Exemplo:

./run-minio-ementas-e2e.ps1 \
  -DokkuHost SEU_HOST_DOKKU \
  -S3Domain minio-ementas.ic.ufba.br \
  -ConsoleDomain minio-console-ementas.ic.ufba.br \
  -MinioRootUser ADMIN_USER \
  -MinioRootPassword ADMIN_PASSWORD_FORTE \
  -S3Bucket ementas-signatures-hml \
  -S3AccessKeyId EMENTAS_ACCESS_KEY \
  -S3SecretAccessKey EMENTAS_SECRET_KEY \
  -ApiAppName ementas-api

Notas de parametros dinamicos:
1. `-MinioAppName` permite trocar o nome da app MinIO sem alterar script.
2. `-S3AccessKeyId` e `-S3SecretAccessKey` sao opcionais no E2E. Se omitidos, o script usa `MinioRootUser/MinioRootPassword` como fallback.
3. `-MinioSubnetLicense` permite injetar token de plano MinIO quando necessario.
4. Se `-MinioSubnetLicense` nao for informado, o script tenta usar automaticamente a variavel de ambiente `MINIO_SUBNET_LICENSE`.

## Segredos e CI/CD (GitHub Actions)

Recomendacao de seguranca:
1. Nunca commitar token em arquivo versionado.
2. Nunca passar token em texto puro no comando salvo no historico.
3. Preferir variavel de ambiente local ou GitHub Secret.

### Uso local (PowerShell)

$env:MINIO_SUBNET_LICENSE="SEU_TOKEN"
.\run-minio-ementas-e2e.ps1 -DokkuHost SEU_HOST_DOKKU -S3Domain minio-ementas.ic.ufba.br -ConsoleDomain minio-console-ementas.ic.ufba.br -MinioRootUser ADMIN_USER -MinioRootPassword ADMIN_PASSWORD_FORTE -S3Bucket ementas-signatures-hml -ApiAppName ementas-api

### Uso no GitHub Actions

Crie os Secrets no repositorio (Settings > Secrets and variables > Actions):
- DOKKU_HOST
- DOKKU_USER
- S3_DOMAIN
- CONSOLE_DOMAIN
- MINIO_ROOT_USER
- MINIO_ROOT_PASSWORD
- S3_BUCKET
- S3_ACCESS_KEY_ID
- S3_SECRET_ACCESS_KEY
- MINIO_SUBNET_LICENSE

Exemplo de job:

name: Deploy MinIO E2E
on:
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run E2E deploy
        shell: pwsh
        env:
          MINIO_SUBNET_LICENSE: ${{ secrets.MINIO_SUBNET_LICENSE }}
        run: |
          ./ementas-docs/ops/dokku/run-minio-ementas-e2e.ps1 \
            -DokkuHost ${{ secrets.DOKKU_HOST }} \
            -DokkuUser ${{ secrets.DOKKU_USER }} \
            -S3Domain ${{ secrets.S3_DOMAIN }} \
            -ConsoleDomain ${{ secrets.CONSOLE_DOMAIN }} \
            -MinioRootUser ${{ secrets.MINIO_ROOT_USER }} \
            -MinioRootPassword ${{ secrets.MINIO_ROOT_PASSWORD }} \
            -S3Bucket ${{ secrets.S3_BUCKET }} \
            -S3AccessKeyId ${{ secrets.S3_ACCESS_KEY_ID }} \
            -S3SecretAccessKey ${{ secrets.S3_SECRET_ACCESS_KEY }} \
            -ApiAppName ementas-api

## Execucao por etapas
1. Deploy MinIO:
./deploy-minio-dokku.ps1 -DokkuHost SEU_HOST_DOKKU -S3Domain minio-ementas.ic.ufba.br -MinioRootUser ADMIN_USER -MinioRootPassword ADMIN_PASSWORD_FORTE

2. Validacao bucket:
./validate-minio-bucket-e2e.ps1 -S3Endpoint https://minio-ementas.ic.ufba.br -S3AccessKeyId EMENTAS_ACCESS_KEY -S3SecretAccessKey EMENTAS_SECRET_KEY -S3Bucket ementas-signatures-hml

3. Configurar API:
./configure-ementas-api-s3.ps1 -DokkuHost SEU_HOST_DOKKU -ApiAppName ementas-api -S3Endpoint https://minio-ementas.ic.ufba.br -S3Bucket ementas-signatures-hml -S3AccessKeyId EMENTAS_ACCESS_KEY -S3SecretAccessKey EMENTAS_SECRET_KEY

## Observacoes importantes
1. O caminho de persistencia padrao no host foi configurado como /app/storage, conforme retorno do suporte IC.
2. Se a persistencia ainda nao estiver liberada, o mount pode falhar. O script segue e registra aviso para nao bloquear deploy.
3. As credenciais de acesso de aplicacao (S3AccessKeyId e S3SecretAccessKey) devem ser as credenciais tecnicas usadas pela API EMENTAS.
4. STORAGE_S3_FORCE_PATH_STYLE permanece true por compatibilidade com MinIO.

## Rollback rapido da API
./configure-ementas-api-s3.ps1 pode ser substituido por config local manual:
- STORAGE_PROVIDER=local
- STORAGE_S3_ENABLED=false
- STORAGE_LOCAL_BASE_PATH=storage


