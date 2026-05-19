param(
    [Parameter(Mandatory = $true)] [string] $S3Endpoint,
    [Parameter(Mandatory = $true)] [string] $S3AccessKeyId,
    [Parameter(Mandatory = $true)] [string] $S3SecretAccessKey,
    [Parameter(Mandatory = $true)] [string] $S3Bucket
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
if ($null -eq $dockerCmd) {
    throw "Docker nao encontrado localmente. Necessario para rodar o cliente MinIO (mc) de validacao."
}

$aliasName = "ementas"
$objectName = "healthchecks/e2e-$(Get-Date -Format yyyyMMdd-HHmmss).txt"
$payload = "EMENTAS MinIO E2E $(Get-Date -Format o)"
$endpointForMc = $S3Endpoint

if ($endpointForMc -match '^https?://(127\.0\.0\.1|localhost)(:\d+)?') {
    $endpointForMc = $endpointForMc -replace '^https?://(127\.0\.0\.1|localhost)', 'http://host.docker.internal'
}

$tempFile = Join-Path $env:TEMP "ementas-minio-e2e.txt"
Set-Content -Path $tempFile -Value $payload -NoNewline -Encoding UTF8

try {
    & docker run --rm --entrypoint /bin/sh -v "${tempFile}:/tmp/e2e.txt" minio/mc -c @"
mc alias set $aliasName $endpointForMc $S3AccessKeyId $S3SecretAccessKey
mc mb --ignore-existing $aliasName/$S3Bucket
mc cp /tmp/e2e.txt $aliasName/$S3Bucket/$objectName
mc ls $aliasName/$S3Bucket/$objectName
mc rm --force $aliasName/$S3Bucket/$objectName || true
"@

    if ($LASTEXITCODE -ne 0) {
        throw "Validacao E2E de bucket falhou."
    }
}
finally {
    Remove-Item $tempFile -ErrorAction SilentlyContinue
}

Write-Host "Validacao E2E de bucket concluida em $S3Bucket" -ForegroundColor Green


