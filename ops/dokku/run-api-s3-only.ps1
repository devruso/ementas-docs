param(
    [Parameter(Mandatory = $true)] [string] $DokkuHost,
    [Parameter(Mandatory = $false)] [string] $ApiAppName = "ementas-api",
    [Parameter(Mandatory = $false)] [string] $DokkuUser = "dokku",
    [Parameter(Mandatory = $true)] [string] $S3Endpoint,
    [Parameter(Mandatory = $true)] [string] $S3Bucket,
    [Parameter(Mandatory = $false)] [string] $S3AccessKeyId = "",
    [Parameter(Mandatory = $false)] [string] $S3SecretAccessKey = "",
    [Parameter(Mandatory = $false)] [string] $S3Region = "us-east-1",
    [Parameter(Mandatory = $false)] [switch] $SkipBucketValidation
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = $PSScriptRoot
$configScript = Join-Path $root "configure-ementas-api-s3.ps1"
$validateScript = Join-Path $root "validate-minio-bucket-e2e.ps1"

if (-not (Test-Path $configScript)) { throw "Script ausente: $configScript" }
if (-not (Test-Path $validateScript)) { throw "Script ausente: $validateScript" }

if ([string]::IsNullOrWhiteSpace($S3AccessKeyId)) {
    if (-not [string]::IsNullOrWhiteSpace($env:S3_ACCESS_KEY_ID)) {
        $S3AccessKeyId = $env:S3_ACCESS_KEY_ID
    }
}

if ([string]::IsNullOrWhiteSpace($S3SecretAccessKey)) {
    if (-not [string]::IsNullOrWhiteSpace($env:S3_SECRET_ACCESS_KEY)) {
        $S3SecretAccessKey = $env:S3_SECRET_ACCESS_KEY
    }
}

if ([string]::IsNullOrWhiteSpace($S3AccessKeyId) -or [string]::IsNullOrWhiteSpace($S3SecretAccessKey)) {
    throw "S3AccessKeyId/S3SecretAccessKey ausentes. Informe por parametro ou variaveis S3_ACCESS_KEY_ID e S3_SECRET_ACCESS_KEY."
}

if (-not $SkipBucketValidation.IsPresent) {
    & $validateScript `
        -S3Endpoint $S3Endpoint `
        -S3AccessKeyId $S3AccessKeyId `
        -S3SecretAccessKey $S3SecretAccessKey `
        -S3Bucket $S3Bucket

    if ($LASTEXITCODE -ne 0) {
        throw "Falha na validacao de bucket."
    }
}

& $configScript `
    -DokkuHost $DokkuHost `
    -ApiAppName $ApiAppName `
    -DokkuUser $DokkuUser `
    -S3Endpoint $S3Endpoint `
    -S3Bucket $S3Bucket `
    -S3AccessKeyId $S3AccessKeyId `
    -S3SecretAccessKey $S3SecretAccessKey `
    -S3Region $S3Region

if ($LASTEXITCODE -ne 0) {
    throw "Falha na configuracao da API."
}

Write-Host "" 
Write-Host "Configuracao API->S3 concluida." -ForegroundColor Green
Write-Host "Dokku host: $DokkuHost"
Write-Host "API app: $ApiAppName"
Write-Host "S3 endpoint: $S3Endpoint"
Write-Host "Bucket: $S3Bucket"
