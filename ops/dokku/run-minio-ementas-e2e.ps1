param(
    [Parameter(Mandatory = $true)] [string] $DokkuHost,
    [Parameter(Mandatory = $true)] [string] $S3Domain,
    [Parameter(Mandatory = $false)] [string] $ConsoleDomain = "",
    [Parameter(Mandatory = $true)] [string] $MinioRootUser,
    [Parameter(Mandatory = $true)] [string] $MinioRootPassword,
    [Parameter(Mandatory = $true)] [string] $S3Bucket,
    [Parameter(Mandatory = $false)] [string] $S3AccessKeyId = "",
    [Parameter(Mandatory = $false)] [string] $S3SecretAccessKey = "",
    [Parameter(Mandatory = $false)] [string] $MinioAppName = "minio-ementas",
    [Parameter(Mandatory = $false)] [string] $MinioSubnetLicense = "",
    [Parameter(Mandatory = $false)] [string] $ApiAppName = "ementas-api",
    [Parameter(Mandatory = $false)] [string] $DokkuUser = "dokku",
    [Parameter(Mandatory = $false)] [string] $HostStoragePath = "/app/storage",
    [Parameter(Mandatory = $false)] [string] $S3Region = "us-east-1",
    [Parameter(Mandatory = $false)] [switch] $SkipLetsEncrypt,
    [Parameter(Mandatory = $false)] [switch] $SkipBucketValidation,
    [Parameter(Mandatory = $false)] [switch] $SkipApiConfig
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = $PSScriptRoot
$deployScript = Join-Path $root "deploy-minio-dokku.ps1"
$configScript = Join-Path $root "configure-ementas-api-s3.ps1"
$validateScript = Join-Path $root "validate-minio-bucket-e2e.ps1"

if (-not (Test-Path $deployScript)) { throw "Script ausente: $deployScript" }
if (-not (Test-Path $configScript)) { throw "Script ausente: $configScript" }
if (-not (Test-Path $validateScript)) { throw "Script ausente: $validateScript" }

# Evita expor token em historico de shell: aceita fallback por variavel de ambiente.
if ([string]::IsNullOrWhiteSpace($MinioSubnetLicense) -and -not [string]::IsNullOrWhiteSpace($env:MINIO_SUBNET_LICENSE)) {
    $MinioSubnetLicense = $env:MINIO_SUBNET_LICENSE
}

$effectiveAccessKeyId = if ([string]::IsNullOrWhiteSpace($S3AccessKeyId)) { $MinioRootUser } else { $S3AccessKeyId }
$effectiveSecretAccessKey = if ([string]::IsNullOrWhiteSpace($S3SecretAccessKey)) { $MinioRootPassword } else { $S3SecretAccessKey }

& $deployScript `
    -DokkuHost $DokkuHost `
    -S3Domain $S3Domain `
    -ConsoleDomain $ConsoleDomain `
    -DokkuUser $DokkuUser `
    -AppName $MinioAppName `
    -HostStoragePath $HostStoragePath `
    -MinioRootUser $MinioRootUser `
    -MinioRootPassword $MinioRootPassword `
    -MinioSubnetLicense $MinioSubnetLicense `
    -SkipLetsEncrypt:$SkipLetsEncrypt

if ($LASTEXITCODE -ne 0) {
    throw "Falha no deploy do MinIO."
}

$endpoint = "https://$S3Domain"

if (-not $SkipBucketValidation.IsPresent) {
    & $validateScript `
        -S3Endpoint $endpoint `
        -S3AccessKeyId $effectiveAccessKeyId `
        -S3SecretAccessKey $effectiveSecretAccessKey `
        -S3Bucket $S3Bucket

    if ($LASTEXITCODE -ne 0) {
        throw "Falha na validacao de bucket."
    }
}

if (-not $SkipApiConfig.IsPresent) {
    & $configScript `
        -DokkuHost $DokkuHost `
        -ApiAppName $ApiAppName `
        -DokkuUser $DokkuUser `
        -S3Endpoint $endpoint `
        -S3Bucket $S3Bucket `
        -S3AccessKeyId $effectiveAccessKeyId `
        -S3SecretAccessKey $effectiveSecretAccessKey `
        -S3Region $S3Region

    if ($LASTEXITCODE -ne 0) {
        throw "Falha na configuracao da API."
    }
}

Write-Host "" 
Write-Host "E2E concluido." -ForegroundColor Green
Write-Host "Dokku host: $DokkuHost"
Write-Host "MinIO app: $MinioAppName"
Write-Host "MinIO endpoint: $endpoint"
Write-Host "Bucket: $S3Bucket"
if (-not $SkipApiConfig.IsPresent) {
    Write-Host "API configurada: $ApiAppName"
}


