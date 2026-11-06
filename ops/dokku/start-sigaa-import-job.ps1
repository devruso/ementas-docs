param(
    [Parameter(Mandatory = $true)] [string] $Email,
    [Parameter(Mandatory = $true)] [string] $Password,
    [Parameter(Mandatory = $false)] [string] $ApiBaseUrl = "https://ementas-api.app.ic.ufba.br",
    [Parameter(Mandatory = $false)] [ValidateSet("department", "program")] [string] $SourceType = "department",
    [Parameter(Mandatory = $false)] [ValidateSet("graduacao", "mestrado", "doutorado", "all")] [string] $AcademicLevel = "all",
    [Parameter(Mandatory = $false)] [string] $SourceId = "",
    [Parameter(Mandatory = $false)] [string] $GraduacaoSourceId = "",
    [Parameter(Mandatory = $false)] [string] $MestradoSourceId = "",
    [Parameter(Mandatory = $false)] [string] $DoutoradoSourceId = "",
    [Parameter(Mandatory = $false)] [int] $BatchSize = 20,
    [Parameter(Mandatory = $false)] [int] $RequestTimeoutMs = 120000,
    [Parameter(Mandatory = $false)] [int] $PollIntervalSeconds = 10,
    [Parameter(Mandatory = $false)] [switch] $EnrichDetails,
    [Parameter(Mandatory = $false)] [switch] $SkipTlsValidation
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-OptionalProperty {
    param([object] $Object, [string] $Name)
    $property = $Object.PSObject.Properties[$Name]
    if ($null -ne $property) { return $property.Value }
    return $null
}

function Invoke-JsonRequest {
    param(
        [Parameter(Mandatory = $true)] [string] $Method,
        [Parameter(Mandatory = $true)] [string] $Uri,
        [Parameter(Mandatory = $false)] [hashtable] $Headers,
        [Parameter(Mandatory = $false)] $Body
    )

    $requestParams = @{
        Method      = $Method
        Uri         = $Uri
        Headers     = $Headers
        ContentType = "application/json"
        TimeoutSec  = [Math]::Max(1, [Math]::Ceiling($RequestTimeoutMs / 1000))
    }

    if ($null -ne $Body) {
        $requestParams.Body = ($Body | ConvertTo-Json -Depth 12)
    }

    $previousCallback = [System.Net.ServicePointManager]::ServerCertificateValidationCallback
    try {
        if ($SkipTlsValidation) {
            if ((Get-Command Invoke-RestMethod).Parameters.ContainsKey("SkipCertificateCheck")) {
                $requestParams.SkipCertificateCheck = $true
            } else {
                [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
            }
        }
        return Invoke-RestMethod @requestParams
    } finally {
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $previousCallback
    }
}

$normalizedBaseUrl = $ApiBaseUrl.TrimEnd("/")

Write-Host "Verificando API em $normalizedBaseUrl/api/status ..." -ForegroundColor Cyan
$status = Invoke-JsonRequest -Method "GET" -Uri "$normalizedBaseUrl/api/status"

if (-not $status.ok) {
    throw "API respondeu sem ok=true em /api/status."
}

Write-Host "Fazendo login com $Email ..." -ForegroundColor Cyan
$loginResponse = Invoke-JsonRequest -Method "POST" -Uri "$normalizedBaseUrl/api/auth/login" -Body @{
    email = $Email
    password = $Password
}

$token = [string] $loginResponse.token

if ([string]::IsNullOrWhiteSpace($token)) {
    throw "Login nao retornou token."
}

$headers = @{
    Authorization = "Bearer $token"
}

$payload = @{
    sourceType = $SourceType
    academicLevel = $AcademicLevel
    batchSize = [Math]::Max(1, $BatchSize)
    enrichDetails = [bool] $EnrichDetails
    requestTimeoutMs = [Math]::Max(1000, $RequestTimeoutMs)
}

if (-not [string]::IsNullOrWhiteSpace($SourceId)) {
    $payload.sourceId = $SourceId
}

$sourceIdsByLevel = @{}

if (-not [string]::IsNullOrWhiteSpace($GraduacaoSourceId)) {
    $sourceIdsByLevel.graduacao = $GraduacaoSourceId
}

if (-not [string]::IsNullOrWhiteSpace($MestradoSourceId)) {
    $sourceIdsByLevel.mestrado = $MestradoSourceId
}

if (-not [string]::IsNullOrWhiteSpace($DoutoradoSourceId)) {
    $sourceIdsByLevel.doutorado = $DoutoradoSourceId
}

if ($sourceIdsByLevel.Count -gt 0) {
    $payload.sourceIdsByLevel = $sourceIdsByLevel
}

Write-Host "Criando job de importacao SIGAA ..." -ForegroundColor Cyan
$jobResponse = Invoke-JsonRequest -Method "POST" -Uri "$normalizedBaseUrl/api/components/import/sigaa-public/jobs" -Headers $headers -Body $payload

$job = $jobResponse.job

if ($null -eq $job -or [string]::IsNullOrWhiteSpace([string] $job.id)) {
    throw "A API nao retornou um job valido."
}

$jobId = [string] $job.id
Write-Host "Job criado: $jobId" -ForegroundColor Green
Write-Host "Status inicial: $($job.status)" -ForegroundColor Green

while ($true) {
    Start-Sleep -Seconds ([Math]::Max(2, $PollIntervalSeconds))

    $current = Invoke-JsonRequest -Method "GET" -Uri "$normalizedBaseUrl/api/components/import/sigaa-public/jobs/$jobId" -Headers $headers

    $summary = [ordered]@{
        id = $current.id
        status = $current.status
        currentLevel = Get-OptionalProperty -Object $current.progress -Name "currentLevel"
        completedLevels = $current.progress.completedLevels
        totalLevels = $current.progress.totalLevels
        batchesProcessed = $current.progress.batchesProcessed
        requested = $current.totals.requested
        created = $current.totals.created
        skippedExisting = $current.totals.skippedExisting
        reconciled = $current.totals.reconciled
        failed = $current.totals.failed
        lastError = Get-OptionalProperty -Object $current -Name "lastError"
    }

    Write-Host ("[" + (Get-Date -Format "HH:mm:ss") + "] " + ($summary | ConvertTo-Json -Compress)) -ForegroundColor Yellow

    if ($current.status -in @("completed", "failed", "cancelled")) {
        Write-Host "" 
        Write-Host "Resultado final:" -ForegroundColor Cyan
        $current | ConvertTo-Json -Depth 12

        if ($current.status -ne "completed") {
            exit 1
        }

        exit 0
    }
}
