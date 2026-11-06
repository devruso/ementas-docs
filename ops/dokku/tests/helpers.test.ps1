# Run with powershell -NoProfile -ExecutionPolicy Bypass -File ops/dokku/tests/helpers.test.ps1.
# All HTTP, SSH and sleep calls are replaced locally; this never changes a live environment.
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$scriptsPath = Split-Path $PSScriptRoot -Parent
$global:OpsHelperTestState = @{
    Polls = 0
    SentPayload = $null
    RemoteCommands = [System.Collections.Generic.List[string]]::new()
}

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw $Message }
}

function Start-Sleep { param([int] $Seconds) }

function Invoke-RestMethod {
    param($Method, $Uri, $Headers, $ContentType, $TimeoutSec, $Body)
    Assert-True ($TimeoutSec -gt 0) "Requests must have a timeout."
    if ($Uri.EndsWith("/api/status")) { return [pscustomobject]@{ ok = $true } }
    if ($Uri.EndsWith("/api/auth/login")) { return [pscustomobject]@{ token = "fixture-token" } }
    Assert-True ($Headers.Authorization -eq "Bearer fixture-token") "Expected authenticated request."
    if ($Method -eq "POST") {
        $global:OpsHelperTestState.SentPayload = $Body | ConvertFrom-Json
        return [pscustomobject]@{ job = [pscustomobject]@{ id = "fixture-job"; status = "pending" } }
    }
    $global:OpsHelperTestState.Polls += 1
    return [pscustomobject]@{
        id = "fixture-job"
        status = $(if ($global:OpsHelperTestState.Polls -eq 1) { "pending" } else { "completed" })
        # Deliberately omit optional currentLevel and lastError, as the real API does.
        progress = [pscustomobject]@{ completedLevels = 0; totalLevels = 1; batchesProcessed = 0 }
        totals = [pscustomobject]@{ requested = 0; created = 0; skippedExisting = 0; reconciled = 0; failed = 0 }
    }
}

function ssh {
    param([string] $Destination, [string] $RemoteCommand)
    $global:OpsHelperTestState.RemoteCommands.Add($RemoteCommand)
    if ($RemoteCommand.Contains("config:set")) { Write-Output "configured fixture-secret-key" }
    $global:LASTEXITCODE = 0
}

$previousCallback = [System.Net.ServicePointManager]::ServerCertificateValidationCallback
$importOutput = & (Join-Path $scriptsPath "start-sigaa-import-job.ps1") `
    -Email "fixture@ufba.br" -Password "fixture-password" -ApiBaseUrl "https://fixture.invalid" `
    -GraduacaoSourceId "1114" -SkipTlsValidation *>&1
Assert-True ($LASTEXITCODE -eq 0) "Import helper should complete successfully."
Assert-True ($global:OpsHelperTestState.Polls -eq 2) "Expected polling to continue when optional properties are absent."
Assert-True (-not $global:OpsHelperTestState.SentPayload.enrichDetails) "Detail enrichment should remain opt-in."
Assert-True ($global:OpsHelperTestState.SentPayload.sourceIdsByLevel.graduacao -eq "1114") "Source ID was lost."
Assert-True ([object]::ReferenceEquals($previousCallback, [System.Net.ServicePointManager]::ServerCertificateValidationCallback)) `
    "TLS validation was not restored."

$storageOutput = & (Join-Path $scriptsPath "configure-ementas-api-s3.ps1") `
    -DokkuHost "fixture.invalid" -ApiAppName "fixture-api" -S3Endpoint "https://fixture.invalid" `
    -S3Bucket "fixture-bucket" -S3AccessKeyId "fixture-access-key" -S3SecretAccessKey "fixture-secret-key" *>&1
$renderedOutput = $storageOutput | Out-String
Assert-True (-not $renderedOutput.Contains("fixture-access-key")) "Storage output exposed the access key."
Assert-True (-not $renderedOutput.Contains("fixture-secret-key")) "Storage output exposed the secret key."
Assert-True ($global:OpsHelperTestState.RemoteCommands.Count -eq 2) "Expected config and restart calls."
Assert-True ($global:OpsHelperTestState.RemoteCommands[0].Contains("STORAGE_S3_AUTO_CREATE_BUCKET='false'")) "Missing bucket policy."
Write-Output "PASS: import polling, TLS restoration, request timeout and redacted storage output."
