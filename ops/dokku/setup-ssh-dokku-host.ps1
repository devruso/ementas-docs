param(
    [Parameter(Mandatory = $true)] [string] $HostAlias,
    [Parameter(Mandatory = $true)] [string] $HostName,
    [Parameter(Mandatory = $false)] [string] $User = "dokku",
    [Parameter(Mandatory = $false)] [string] $IdentityFile = "",
    [Parameter(Mandatory = $false)] [int] $Port = 22
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$sshDir = Join-Path $HOME ".ssh"
$configPath = Join-Path $sshDir "config"
$defaultKey = Join-Path $sshDir "id_ed25519_ic_ufba"

if (-not (Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir | Out-Null
}

if ([string]::IsNullOrWhiteSpace($IdentityFile)) {
    if (Test-Path $defaultKey) {
        $IdentityFile = $defaultKey
    }
    else {
        throw "Nenhuma chave SSH encontrada automaticamente. Informe -IdentityFile explicitamente."
    }
}

if (-not (Test-Path $IdentityFile)) {
    throw "IdentityFile nao encontrado: $IdentityFile"
}

$block = @"
Host $HostAlias
    HostName $HostName
    User $User
    Port $Port
    IdentityFile $IdentityFile
    IdentitiesOnly yes
"@

if (Test-Path $configPath) {
    $existing = Get-Content $configPath -Raw
    if ($existing -match "(?m)^Host\s+$([Regex]::Escape($HostAlias))\s*$") {
        throw "Ja existe um bloco Host $HostAlias no arquivo $configPath. Ajuste manualmente para evitar conflito."
    }
    Add-Content -Path $configPath -Value "`n$block"
}
else {
    Set-Content -Path $configPath -Value $block
}

Write-Host "Host SSH adicionado em $configPath" -ForegroundColor Green
Write-Host "Alias: $HostAlias"
Write-Host "HostName: $HostName"
Write-Host "User: $User"
Write-Host "Port: $Port"
Write-Host "IdentityFile: $IdentityFile"
Write-Host ""
Write-Host "Teste recomendado:" -ForegroundColor Yellow
Write-Host "ssh $HostAlias dokku version"
