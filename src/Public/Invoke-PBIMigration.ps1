function Invoke-PBIMigration {
    <#
    .SYNOPSIS
    Entry point for the Power BI on Databricks Migration Accelerator.

    .DESCRIPTION
    Loads the configuration file, installs and loads the required TOM assembly,
    iterates through every configured local folder (.pbip) and Power BI workspace,
    and applies Update-PBIDatabase to each in-scope semantic model.

    Supports -WhatIf and -Confirm so the whole run can be simulated without
    persisting changes.

    .PARAMETER ConfigFilePath
    Path to the JSON configuration file.

    .PARAMETER LogFilePath
    Path to the transcript file that will capture all console output.

    .PARAMETER TOMVersion
    Version of the Microsoft.AnalysisServices NuGet package to install.

    .PARAMETER SchemaFilePath
    Optional path to Configuration.schema.json. When provided, the config is
    validated against the schema before any TOM work is attempted.

    .PARAMETER StrictSchema
    When specified, a schema validation failure becomes a terminating error
    instead of a warning. Has no effect when schema validation is skipped.

    .PARAMETER ModuleRoot
    Base directory used to resolve callback module paths.

    .EXAMPLE
    Invoke-PBIMigration -ConfigFilePath ./Configuration.json

    .EXAMPLE
    Invoke-PBIMigration -ConfigFilePath ./Configuration.json -WhatIf -Verbose

    .EXAMPLE
    Invoke-PBIMigration -ConfigFilePath ./Configuration.json -StrictSchema
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0)]
        [ValidateScript({
            if (-not (Test-Path -LiteralPath $_ -PathType Leaf)) {
                throw "Configuration file does not exist: $_"
            }
            $true
        })]
        [string]$ConfigFilePath = './Configuration.json',

        [Parameter(Position = 1)]
        [string]$LogFilePath,

        [Parameter(Position = 2)]
        [version]$TOMVersion = '19.84.1',

        [Parameter(Position = 3)]
        [string]$SchemaFilePath,

        [Parameter()]
        [switch]$StrictSchema,

        [Parameter()]
        [string]$ModuleRoot
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    if ([string]::IsNullOrEmpty($ModuleRoot))  { $ModuleRoot  = Split-Path -Path $PSScriptRoot -Parent }

    if ([string]::IsNullOrEmpty($LogFilePath)) {
        $LogFilePath = 'PowerBI-migration-accelerator_{0:yyyyMMddTHHmmss}.log' -f (Get-Date)
    }

    $transcriptStarted = $false
    try {
        Start-Transcript -Path $LogFilePath -Append -Force | Out-Null
        $transcriptStarted = $true
    } catch {
        Write-Warning "Could not start transcript at '$LogFilePath': $_"
    }

    try {
        Install-TomAssembly -TOMVersion $TOMVersion

        $startTime = Get-Date
        $configRaw = Get-Content -LiteralPath $ConfigFilePath -Raw

        if ([string]::IsNullOrEmpty($SchemaFilePath)) {
            $candidate = Join-Path -Path (Split-Path -Path $moduleRoot -Parent) -ChildPath 'Configuration.schema.json'
            if (Test-Path -LiteralPath $candidate) { $SchemaFilePath = $candidate }
        }

        if (-not [string]::IsNullOrEmpty($SchemaFilePath) -and (Test-Path -LiteralPath $SchemaFilePath)) {
            Write-MigrationLog "Validating configuration against schema $SchemaFilePath ..." -Level Info
            $schemaJson = Get-Content -LiteralPath $SchemaFilePath -Raw
            if (-not (Test-Json -Json $configRaw -Schema $schemaJson -ErrorAction SilentlyContinue)) {
                $msg = "Configuration file did not validate cleanly against the schema."
                if ($StrictSchema) {
                    throw $msg
                } else {
                    Write-MigrationLog "$msg (continuing; pass -StrictSchema to fail fast)." -Level Warning
                }
            }
        }

        $globalConfig = $configRaw | ConvertFrom-Json
        $stats        = New-MigrationStats

        Invoke-LocalFolderMigration -GlobalConfig $globalConfig -Stats $stats -ModuleRoot $moduleRoot
        Invoke-WorkspaceMigration   -GlobalConfig $globalConfig -Stats $stats -ModuleRoot $moduleRoot

        $finishTime = Get-Date

        Write-MigrationLog ("Start Time:   {0:s}" -f $startTime)             -Level Stat -NoTimestamp
        Write-MigrationLog ("Finish Time:  {0:s}" -f $finishTime)            -Level Stat -NoTimestamp
        Write-MigrationLog ("Elapsed Time: {0}" -f ($finishTime - $startTime))-Level Stat -NoTimestamp
        foreach ($key in $stats.Keys) {
            Write-MigrationLog ('  {0}: {1}' -f $key, $stats[$key]) -Level Stat -NoTimestamp
        }

        [pscustomobject]@{
            StartTime = $startTime
            EndTime   = $finishTime
            Elapsed   = ($finishTime - $startTime)
            Stats     = $stats
        }
    } finally {
        if ($transcriptStarted) {
            try { Stop-Transcript | Out-Null } catch { Write-Verbose "Stop-Transcript failed: $_" }
        }
    }
}
