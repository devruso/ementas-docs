param(
    [Parameter(Mandatory = $true)] [string] $DokkuHost,
    [Parameter(Mandatory = $true)] [string] $S3Domain,
    [Parameter(Mandatory = $false)] [string] $ConsoleDomain = "",
    [Parameter(Mandatory = $false)] [string] $DokkuUser = "dokku",
    [Parameter(Mandatory = $false)] [string] $AppName = "minio-ementas",
    [Parameter(Mandatory = $false)] [string] $HostStoragePath = "/app/storage",
    [Parameter(Mandatory = $true)] [string] $MinioRootUser,
    [Parameter(Mandatory = $true)] [string] $MinioRootPassword,
    [Parameter(Mandatory = $false)] [string] $MinioSubnetLicense = "",
    [Parameter(Mandatory = $false)] [switch] $SkipLetsEncrypt
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
    param(
        [Parameter(Mandatory = $true)] [string] $Command,
        [Parameter(Mandatory = $false)] [switch] $AllowFail
    )

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

    if (($exitCode -ne 0) -and (-not $AllowFail)) {
        throw "Falha ao executar comando remoto. ExitCode=$exitCode"
    }

    return $exitCode
}

function Set-Config {
    param(
        [Parameter(Mandatory = $true)] [string[]] $Pairs
    )

    $joined = ($Pairs -join " ")
    Invoke-Remote "dokku config:set --no-restart $AppName $joined"
}

Write-Host "Iniciando deploy MinIO no Dokku host $DokkuHost" -ForegroundColor Green

$existsExitCode = Invoke-Remote "dokku apps:exists $AppName" -AllowFail
if ($existsExitCode -ne 0) {
    Invoke-Remote "dokku apps:create $AppName"
}

Set-Config -Pairs @(
    (Build-ConfigPair -Key "MINIO_ROOT_USER" -Value $MinioRootUser),
    (Build-ConfigPair -Key "MINIO_ROOT_PASSWORD" -Value $MinioRootPassword),
    (Build-ConfigPair -Key "MINIO_SERVER_URL" -Value "https://$S3Domain")
)

if (-not [string]::IsNullOrWhiteSpace($MinioSubnetLicense)) {
    Set-Config -Pairs @(
        (Build-ConfigPair -Key "MINIO_SUBNET_LICENSE" -Value $MinioSubnetLicense)
    )
}

if (-not [string]::IsNullOrWhiteSpace($ConsoleDomain)) {
    Set-Config -Pairs @(
        (Build-ConfigPair -Key "MINIO_BROWSER_REDIRECT_URL" -Value "https://$ConsoleDomain")
    )
}

Invoke-Remote "dokku domains:clear $AppName" -AllowFail | Out-Null
Invoke-Remote "dokku domains:add $AppName $S3Domain"
if (-not [string]::IsNullOrWhiteSpace($ConsoleDomain)) {
    Invoke-Remote "dokku domains:add $AppName $ConsoleDomain"
}

# Porta 80 -> API S3 (9000). Se console estiver no mesmo app, expomos 8080 -> 9001.
$portMap = "http:80:9000"
if (-not [string]::IsNullOrWhiteSpace($ConsoleDomain)) {
    $portMap = "http:80:9000 http:8080:9001"
}
Invoke-Remote "dokku config:set --no-restart $AppName $(Build-ConfigPair -Key 'DOKKU_PROXY_PORT_MAP' -Value $portMap)"

# Persistencia: suporte IC informou disponibilidade em /app/storage no host.
Invoke-Remote "dokku storage:mount $AppName ${HostStoragePath}:/data" -AllowFail | Out-Null

$templatePath = Join-Path $PSScriptRoot "minio-template"
if (-not (Test-Path $templatePath)) {
    throw "Template de app MinIO nao encontrado em $templatePath"
}

Push-Location $templatePath
try {
    if (-not (Test-Path ".git")) {
        & git init | Out-Null
        & git add Dockerfile | Out-Null
        & git -c user.name="EMENTAS Automation" -c user.email="ementas-automation@local" commit -m "chore: minio dokku template" | Out-Null
    }

    $remoteName = "dokku-$AppName"
    $remoteUrl = "$DokkuUser@$DokkuHost`:$AppName"

    $remoteExists = (& git remote) -contains $remoteName
    if ($remoteExists) {
        & git remote remove $remoteName | Out-Null
    }
    & git remote add $remoteName $remoteUrl
    & git push $remoteName HEAD:master --force

    if ($LASTEXITCODE -ne 0) {
        throw "Falha no git push para Dokku."
    }
}
finally {
    Pop-Location
}

if (-not $SkipLetsEncrypt.IsPresent) {
    Invoke-Remote "dokku letsencrypt:enable $AppName" -AllowFail | Out-Null
}

Write-Host "" 
Write-Host "Deploy concluido." -ForegroundColor Green
Write-Host "App: $AppName"
Write-Host "S3 endpoint: https://$S3Domain"
if (-not [string]::IsNullOrWhiteSpace($ConsoleDomain)) {
    Write-Host "Console endpoint: https://$ConsoleDomain"
}
Write-Host "Storage host mount: $HostStoragePath -> /data"


