param(
    [Parameter(Mandatory = $true)] [string] $DokkuHost,
    [Parameter(Mandatory = $true)] [string] $ApiAppName,
    [Parameter(Mandatory = $true)] [string] $S3Endpoint,
    [Parameter(Mandatory = $true)] [string] $S3Bucket,
    [Parameter(Mandatory = $true)] [string] $S3AccessKeyId,
    [Parameter(Mandatory = $true)] [string] $S3SecretAccessKey,
    [Parameter(Mandatory = $false)] [string] $DokkuUser = "dokku",
    [Parameter(Mandatory = $false)] [string] $S3Region = "us-east-1",
    [Parameter(Mandatory = $false)] [string] $S3PublicBaseUrl = "",
    [Parameter(Mandatory = $false)] [string] $S3ForcePathStyle = "true"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Quote-Sh {
    param([Parameter(Mandatory = $true)] [string] $Value)
    $single = [char]39
    $double = [char]34
    $replacement = "$single$double$single$double$single"
    return "$single" + ($Value -replace "$single", $replacement) + "$single"
}

function Build-ConfigPair {
    param(
        [Parameter(Mandatory = $true)] [string] $Key,
        [Parameter(Mandatory = $true)] [string] $Value
    )

    return "$Key=$(Quote-Sh $Value)"
}

function Invoke-Remote {
    param([Parameter(Mandatory = $true)] [string] $Command)

    Write-Host ">> SSH: $Command" -ForegroundColor Cyan
    $attempts = @(
        "bash -lc '$Command'",
        $Command
    )

    if ($Command -match '^dokku\s+') {
        $attempts += ($Command -replace '^dokku\s+', '')
    }

    $exitCode = 1
    foreach ($attempt in $attempts) {
        & ssh "$DokkuUser@$DokkuHost" $attempt
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0) {
            break
        }
    }

    if ($exitCode -ne 0) {
        throw "Falha ao executar comando remoto. ExitCode=$exitCode"
    }
}

$pairs = @(
    (Build-ConfigPair -Key "STORAGE_PROVIDER" -Value "s3"),
    (Build-ConfigPair -Key "STORAGE_S3_ENABLED" -Value "true"),
    (Build-ConfigPair -Key "STORAGE_S3_ENDPOINT" -Value $S3Endpoint),
    (Build-ConfigPair -Key "STORAGE_S3_REGION" -Value $S3Region),
    (Build-ConfigPair -Key "STORAGE_S3_BUCKET" -Value $S3Bucket),
    (Build-ConfigPair -Key "STORAGE_S3_ACCESS_KEY_ID" -Value $S3AccessKeyId),
    (Build-ConfigPair -Key "STORAGE_S3_SECRET_ACCESS_KEY" -Value $S3SecretAccessKey),
    (Build-ConfigPair -Key "STORAGE_S3_FORCE_PATH_STYLE" -Value $S3ForcePathStyle)
)

if (-not [string]::IsNullOrWhiteSpace($S3PublicBaseUrl)) {
    $pairs += (Build-ConfigPair -Key "STORAGE_S3_PUBLIC_BASE_URL" -Value $S3PublicBaseUrl)
}

$joined = ($pairs -join " ")
Invoke-Remote "dokku config:set --no-restart $ApiAppName $joined"
Invoke-Remote "dokku ps:restart $ApiAppName"

Write-Host "Configuracao S3 aplicada na API $ApiAppName" -ForegroundColor Green
