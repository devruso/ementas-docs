# Automacao CLI Dokku - MinIO + EMENTAS (E2E)

## Onde cada comando roda
1. Comandos que comecam com `dokku ...` rodam no host Linux do Dokku, via SSH, e nao dentro do shell do container da aplicacao.
2. Se voce estiver vendo um prompt como `ementas-api - /app %`, voce ja esta dentro do container da app. Nesse caso, rode apenas `node`, `curl`, `ls` etc., sem o prefixo `dokku`.
3. Para executar `dokku run ...`, `dokku enter ...`, `dokku logs ...` e afins, abra um shell no servidor Dokku, por exemplo:

```sh
ssh dokku@SEU_HOST_DOKKU
```

4. Se a interface que voce abriu for um terminal do proprio container web da app, use comandos equivalentes sem `dokku`, por exemplo:

```sh
node -e "console.log('rodando dentro do container')"
```

5. A imagem atual da API pode nao ter `curl` instalado. Nesses casos, prefira `node` com scripts locais do proprio backend.

## O que foi automatizado
1. Deploy de app MinIO no Dokku via SSH e git push de template Dockerfile.
2. Configuracao de dominio(s), proxy de portas e variaveis MinIO.
3. Configuracao de persistencia host para `/app/storage` no container MinIO.
4. Validacao E2E de bucket com cliente MinIO (mc) via Docker local.
5. Configuracao das variaveis S3 na API EMENTAS e restart da app.

## Scripts
- setup-ssh-dokku-host.ps1
- setup-ssh-dokku-host.cmd
- deploy-minio-dokku.ps1
- validate-minio-bucket-e2e.ps1
- configure-ementas-api-s3.ps1
- start-sigaa-import-job.ps1
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

4. Depois de aplicar a configuracao, valide o provider de dentro do container da API:

```sh
node /app/src/scripts/storage-ensure-bucket.js
node /app/src/scripts/storage-smoke-test.js
```

Se preferir que a propria API crie o bucket na primeira gravacao, habilite tambem:

```sh
STORAGE_S3_AUTO_CREATE_BUCKET=true
```

5. Para validar o upload real de assinatura pela API, ainda dentro do container:

```sh
export SIGNATURE_TEST_EMAIL='SEU_EMAIL@ufba.br'
export SIGNATURE_TEST_PASSWORD='SUA_SENHA'
node /app/src/scripts/validate-signature-upload-flow.js \
  --baseUrl=http://127.0.0.1:3333
```

Esse login e o proprio login da aplicacao EMENTAS. O endpoint de upload e autenticado porque a assinatura precisa ser salva no usuario correto. Para reduzir exposicao no historico do shell, prefira `SIGNATURE_TEST_EMAIL` e `SIGNATURE_TEST_PASSWORD` em variavel de ambiente. Se voce ja tiver um JWT valido, prefira `SIGNATURE_TEST_TOKEN` ou `--token=SEU_TOKEN` no lugar de email/senha.

6. Para validar se a assinatura foi parar no DOCX oficial do componente:

```sh
export SIGNATURE_TEST_EMAIL='SEU_EMAIL@ufba.br'
export SIGNATURE_TEST_PASSWORD='SUA_SENHA'
node /app/src/scripts/validate-signature-docx-export-flow.js \
  --baseUrl=http://127.0.0.1:3333 \
  --componentId=UUID_DO_COMPONENTE \
  --expectedApproverName='NOME DO PROFESSOR'
```

Se a API e o MinIO estiverem na mesma rede attachable do Dokku, prefira endpoint interno entre apps em vez do dominio publico, por exemplo `http://minio-ementas.web:9000`. Segundo a documentacao oficial do Dokku, apps anexadas a uma rede compartilham alias DNS no formato `APP.PROC_TYPE`, como `minio-ementas.web`, e o plugin de storage e o mecanismo recomendado para volumes persistentes.

## Leitura rapida de diagnostico do MinIO
Se a UI de arquivos do Dokku mostrar `/app/storage/.minio.sys`, isso normalmente significa que o processo do MinIO subiu e conseguiu inicializar o diretorio de dados. Em outras palavras: o problema deixa de ser "falta pasta" e passa a ser "a API nao gravou objeto util ainda".

Interprete assim:

1. `/app/storage/.minio.sys` existe:
   o MinIO esta escrevendo no caminho certo do container.
2. Buckets vazios ou apenas arquivos internos/binarios:
   o provider S3 da API ainda nao concluiu upload real para o bucket esperado.
3. Console com `ERR_TOO_MANY_REDIRECTS` em `/minio`:
   isso afeta a UI do console, mas nao prova falha da API S3 em `:9000`.

Checklist minimo antes de culpar o backend:

1. O bucket configurado em `STORAGE_S3_BUCKET` existe de fato.
2. `STORAGE_S3_ACCESS_KEY_ID` e `STORAGE_S3_SECRET_ACCESS_KEY` na API batem com uma credencial valida do MinIO.
3. `STORAGE_PROVIDER=s3` e `STORAGE_S3_ENABLED=true` estao ativos na `ementas-api`.
4. O endpoint usado pela API aponta para o servico S3 correto.
   Se API e MinIO compartilham rede interna do Dokku, prefira `http://minio-ementas.web:9000`.
   Se usar o dominio publico `https://minio-ementas.app.ic.ufba.br`, ele precisa responder como API S3, nao apenas console/web redirect.
5. Rode dentro do container da API:

```sh
node /app/src/scripts/storage-ensure-bucket.js
node /app/src/scripts/storage-smoke-test.js
```

6. Se o smoke test passar, valide o fluxo real da assinatura:

```sh
node /app/src/scripts/validate-signature-upload-flow.js \
  --baseUrl=http://127.0.0.1:3333 \
  --email=SEU_EMAIL@ufba.br \
  --password='SUA_SENHA'
```

7. Se quiser comprovar o uso no DOCX oficial, rode tambem:

```sh
node /app/src/scripts/validate-signature-docx-export-flow.js \
  --baseUrl=http://127.0.0.1:3333 \
  --componentId=UUID_DO_COMPONENTE \
  --expectedApproverName='NOME DO PROFESSOR' \
  --email=SEU_EMAIL@ufba.br \
  --password='SUA_SENHA'
```

Resultado esperado:

1. `storage-smoke-test` deve logar `saved` e depois `success`.
2. `validate-signature-upload-flow` deve logar `upload success` e depois `preview success`.
3. So depois disso faz sentido esperar objetos uteis aparecendo no bucket, normalmente com chave `signatures/...`.

## Disparar importacao SIGAA via API publicada
Use este fluxo quando a API ja estiver no ar e voce so precisar autenticar como admin/super_admin para iniciar o job de carga.

Exemplo com os IDs de producao discutidos para UFBA:

```powershell
.\ementas-docs\ops\dokku\start-sigaa-import-job.ps1 `
  -Email SEU_EMAIL@ufba.br `
  -Password SUA_SENHA `
  -ApiBaseUrl https://ementas-api.app.ic.ufba.br `
  -AcademicLevel all `
  -SourceType department `
  -GraduacaoSourceId 1118 `
  -MestradoSourceId 1820 `
  -BatchSize 20 `
  -RequestTimeoutMs 120000
```

Notas:
1. Use HTTPS com certificado valido. `-SkipTlsValidation` e uma opcao explicita para diagnostico; nao e necessaria no fluxo normal. O script restaura a validacao TLS apos cada requisicao.
2. O script faz login, cria o job em `/api/components/import/sigaa-public/jobs` e acompanha o status ate concluir/falhar.
3. Para reduzir risco operacional, o default do script usa `enrichDetails=false`; acrescente `-EnrichDetails` apenas se quiser buscar detalhes ricos do SIGAA.
4. Para os tres cursos de graduacao do IC, rode tres jobs separados ou use o bootstrap multi-fonte com `BOOTSTRAP_SIGAA_SOURCE_IDS_GRADUACAO=1118,1935,1934`.

## Disparar importacao de dentro do container da API
Se voce estiver no shell do container e a imagem nao tiver `curl`, use Node diretamente.

No deploy que incluir o script abaixo, rode:

```sh
node /app/src/scripts/start-local-sigaa-import-job.js \
  --email=SEU_EMAIL@ufba.br \
  --password='SUA_SENHA' \
  --sourceType=department \
  --academicLevel=graduacao \
  --sourceId=1114 \
  --batchSize=20 \
  --requestTimeoutMs=120000
```

Para SIAC, que costuma ser melhor para carga curricular fechada e uma populacao unica:

```sh
node /app/src/scripts/start-local-siac-import.js \
  --email=SEU_EMAIL@ufba.br \
  --password='SUA_SENHA' \
  --cdCurso=112140 \
  --nuPerCursoInicial=20111
```

Para todos os niveis usando as fontes validadas:

```sh
node /app/src/scripts/start-local-sigaa-import-job.js \
  --email=SEU_EMAIL@ufba.br \
  --password='SUA_SENHA' \
  --sourceType=department \
  --academicLevel=all \
  --graduacaoSourceId=1114 \
  --mestradoSourceId=1820 \
  --doutoradoSourceId=43753 \
  --batchSize=20 \
  --requestTimeoutMs=120000
```

## Bootstrap offline por snapshot
Se o host Dokku nao consegue acessar o SIGAA, gere o snapshot localmente e deixe a producao importar do arquivo.

1. No projeto `ementas-api`, gere o snapshot com o Docker/local que ja funciona:

```sh
npm run sigaa:bootstrap-snapshot -- \
  --graduacaoSourceIds=1118,1935,1934 \
  --mestradoSourceIds=1820 \
  --output=bootstrap-data/sigaa-bootstrap.snapshot.json
```

2. Faca o deploy com:

```sh
BOOTSTRAP_IMPORT_ON_EMPTY_DB=true
BOOTSTRAP_IMPORT_SOURCE=sigaa-snapshot
BOOTSTRAP_SIGAA_SNAPSHOT_PATH=/app/bootstrap-data/sigaa-bootstrap.snapshot.json
BOOTSTRAP_SIGAA_ACADEMIC_LEVEL=all
BOOTSTRAP_SIGAA_SOURCE_IDS_GRADUACAO=1118,1935,1934
BOOTSTRAP_SIGAA_SOURCE_IDS_MESTRADO=1820
```

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

4. Validar provider S3 ja dentro do container da API:
```sh
ssh dokku@SEU_HOST_DOKKU
dokku enter ementas-api web
node /app/src/scripts/storage-smoke-test.js
```

5. Validar upload e preview reais de assinatura:
```sh
node /app/src/scripts/validate-signature-upload-flow.js \
  --baseUrl=http://127.0.0.1:3333 \
  --email=SEU_EMAIL@ufba.br \
  --password='SUA_SENHA'
```

## Observacoes importantes
1. O caminho de persistencia padrao no host foi configurado como /app/storage, conforme retorno do suporte IC.
2. Se a persistencia ainda nao estiver liberada, o mount pode falhar. O script segue e registra aviso para nao bloquear deploy.
3. As credenciais de acesso de aplicacao (S3AccessKeyId e S3SecretAccessKey) devem ser as credenciais tecnicas usadas pela API EMENTAS.
4. STORAGE_S3_FORCE_PATH_STYLE permanece true por compatibilidade com MinIO.
5. Se `STORAGE_S3_REGION` ficar vazio, o backend passa a assumir `us-east-1`.

## Rollback rapido da API
./configure-ementas-api-s3.ps1 pode ser substituido por config local manual:
- STORAGE_PROVIDER=local
- STORAGE_S3_ENABLED=false
- STORAGE_LOCAL_BASE_PATH=storage


