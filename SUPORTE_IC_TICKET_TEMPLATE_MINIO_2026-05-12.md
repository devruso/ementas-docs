# Template de Ticket - Suporte IC UFBA (MinIO + EMENTAS)

## TÃ³pico do chamado
Suporte TI: hospedagem de aplicaÃ§Ã£o

## Assunto sugerido
SolicitaÃ§Ã£o de hospedagem MinIO (compatÃ­vel com API S3) para EMENTAS - assinatura de professores

## Contexto
Precisamos de um serviÃ§o de armazenamento de objetos compatÃ­vel com API S3 para armazenar arquivos de assinatura de docentes no EMENTAS (API Node/TypeScript + App React/TypeScript), com integraÃ§Ã£o jÃ¡ preparada para MinIO.

## Dados tÃ©cnicos para provisionamento
1. Tipo de serviÃ§o solicitado: MinIO (compatÃ­vel com API S3) em Dokku.
2. Ambiente inicial: homologaÃ§Ã£o.
3. PersistÃªncia obrigatÃ³ria: sim (volume persistente no host).
4. DomÃ­nio desejado (exemplo): minio-ementas.ic.ufba.br.
5. TLS/HTTPS: obrigatÃ³rio.
6. Tamanho mÃ¡ximo de upload de assinatura: 2MB por arquivo.
7. Tipos de arquivo permitidos: PNG, JPG e WEBP.

## Credenciais e acessos
1. Chave SSH pÃºblica do responsÃ¡vel: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE1FOhd5UOsXKTTTlWHI/2CwFBiRR+rv3LuXHOeTRHaD devruso
2. ResponsÃ¡vel tÃ©cnico: devruso.
3. Identificador tÃ©cnico do responsÃ¡vel (GitHub ou e-mail institucional): devruso / jamilsonjr@live.com.
4. Conta UFBA vinculada ao chamado: <login UFBA>.

## VariÃ¡veis de ambiente necessÃ¡rias na API
1. STORAGE_PROVIDER=s3
2. STORAGE_S3_ENABLED=true
3. STORAGE_S3_ENDPOINT=<fornecido pelo IC>
4. STORAGE_S3_REGION=<fornecido pelo IC>
5. STORAGE_S3_BUCKET=<fornecido pelo IC>
6. STORAGE_S3_ACCESS_KEY_ID=<fornecido pelo IC>
7. STORAGE_S3_SECRET_ACCESS_KEY=<fornecido pelo IC>
8. STORAGE_S3_FORCE_PATH_STYLE=true
9. STORAGE_S3_PUBLIC_BASE_URL=<opcional>

## ObservaÃ§Ã£o sobre terminologia
- O EMENTAS usa integraÃ§Ã£o compatÃ­vel com API S3 (padrÃ£o de mercado para object storage).
- Isso nÃ£o implica uso de AWS S3 gerenciado; MinIO Ã© totalmente adequado como implementaÃ§Ã£o S3-compatible.

## Requisitos de operaÃ§Ã£o
1. Garantir isolamento de acesso ao bucket do projeto EMENTAS.
2. Permitir operaÃ§Ãµes PutObject/DeleteObject/GetObject para o bucket alocado.
3. Fornecer instruÃ§Ãµes de rotaÃ§Ã£o de credenciais.
4. Informar polÃ­tica de backup e retenÃ§Ã£o (a documentaÃ§Ã£o pÃºblica indica que o serviÃ§o pode ser sem backup por padrÃ£o).

## Checklist de aceite solicitado ao suporte
1. Endpoint de object storage compatÃ­vel com API S3 acessÃ­vel via HTTPS.
2. Bucket criado e permissÃµes mÃ­nimas aplicadas.
3. Credenciais tÃ©cnicas entregues por canal seguro.
4. Teste de upload/listagem/download bÃ¡sico concluÃ­do.
5. InstruÃ§Ã£o de troubleshooting e limites de uso documentada.

## ObservaÃ§Ãµes
- O backend do EMENTAS jÃ¡ estÃ¡ preparado para alternar de storage local para provider compatÃ­vel com API S3 apenas por configuraÃ§Ã£o.
- O frontend jÃ¡ suporta assinatura textual e assinatura desenhada (canvas) convertida para PNG.


