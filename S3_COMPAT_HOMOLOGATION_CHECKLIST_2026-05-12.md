# Checklist de Homologacao S3-Compatible (Universidade)

## Objetivo
Validar a transicao do provider local para endpoint S3-compatible institucional sem quebra de fluxo entre app e api.

## 1) PrÃ©-condiÃ§Ãµes
1. Conta institucional de envio operacional criada e ativa: ementas.ic.ufba@gmail.com.
2. Endpoint S3-compatible disponÃ­vel via MinIO em app dedicada no Dokku (URL, regiÃ£o, bucket, credenciais tÃ©cnicas).
3. Ambiente de homologaÃ§Ã£o com backup de banco e storage local atual.
4. PersistÃªncia do container MinIO habilitada pelo suporte IC com bind para o path informado no servidor.

## 2) ConfiguraÃ§Ã£o mÃ­nima de ambiente (API)
1. Definir no .env:
   - STORAGE_PROVIDER=s3
   - STORAGE_S3_ENABLED=true
   - STORAGE_S3_ENDPOINT=<endpoint>
   - STORAGE_S3_REGION=<regiao>
   - STORAGE_S3_BUCKET=<bucket>
   - STORAGE_S3_ACCESS_KEY_ID=<access-key>
   - STORAGE_S3_SECRET_ACCESS_KEY=<secret-key>
2. Reiniciar API e validar boot sem erro.

## 3) Casos de teste E2E App+API (assinatura)
1. Login com professor vÃ¡lido.
2. Abrir perfil e enviar arquivo de assinatura em imagem (PNG/JPG/WEBP) com assinatura textual opcional.
3. Confirmar retorno 200 e atualizaÃ§Ã£o visual do status no frontend.
4. Validar em banco atualizaÃ§Ã£o de:
   - signature_hash
   - signature_updated_at
   - signature_file_key
   - signature_file_provider
   - signature_file_content_type
   - signature_file_size
   - signature_file_hash
5. Exportar DOCX oficial e confirmar que a assinatura do docente aparece como imagem no parÃ¡grafo de assinatura, preservando a linha do chefe.
6. Publicar disciplina com assinatura validada e confirmar sucesso.
7. Exportar PDF/DOCX oficial e validar metadados de aprovaÃ§Ã£o no documento.

## 4) Casos negativos obrigatÃ³rios
1. Upload sem arquivo deve retornar 400.
2. Upload com tipo invÃ¡lido deve retornar 400.
3. Upload acima de 2MB deve retornar 400.
4. PublicaÃ§Ã£o sem assinatura vÃ¡lida deve retornar erro de autorizaÃ§Ã£o de assinatura.
5. STORAGE_PROVIDER=s3 com STORAGE_S3_ENABLED=false deve falhar explicitamente.

## 5) Integridade funcional (nÃºmero de ATA e referÃªncias)
1. Ao abrir modal de publicaÃ§Ã£o, o nÃºmero sugerido deve seguir padrÃ£o ATA-AAAA-NNN.
2. Deve haver incremento sequencial por ano de referÃªncia.
3. UI de referÃªncias deve exibir score de qualidade ABNT e linhas com pendÃªncias.
4. PublicaÃ§Ã£o oficial deve bloquear referÃªncias nÃ£o web sem ano.

## 6) EvidÃªncias mÃ­nimas para aceite
1. Capturas de tela do perfil com status de assinatura atualizado.
2. Logs da API para upload e publicaÃ§Ã£o.
3. Registro dos testes executados (app e api) com resultado.
4. Amostra de registro persistido no banco com metadados de assinatura.
5. Documento exportado (PDF ou DOCX) com versionamento/ATA de aprovaÃ§Ã£o.

## 7) Plano de rollback
1. Reverter .env para provider local:
   - STORAGE_PROVIDER=local
   - STORAGE_S3_ENABLED=false
2. Reiniciar API.
3. Reexecutar caso de upload e publicaÃ§Ã£o para validar normalizaÃ§Ã£o do fluxo.

