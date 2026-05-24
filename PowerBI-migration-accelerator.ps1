<#
    .SYNOPSIS
    Power BI on Databricks Migration Accelerator.

    .DESCRIPTION
    Thin wrapper around the PBIMigrationAccelerator PowerShell module. The actual
    implementation lives under src/. This script loads the
    module and dispatches to Invoke-PBIMigration so that the existing CLI entry
    point keeps working unchanged.

    The accelerator automates switching Power BI semantic models from legacy data
    sources (Snowflake, Synapse, Redshift, SQL Server, HMS) to Databricks SQL and
    Unity Catalog. It is not an officially supported Databricks tool and is
    provided "AS IS" - use at your own risk.

    .PARAMETER ConfigFilePath
    Path to the configuration file. Default is './Configuration.json'.

    .PARAMETER LogFilePath
    Path to the transcript file. Default is
    'PowerBI-migration-accelerator_yyyyMMddTHHmmss.log'.

    .PARAMETER TOMVersion
    Version of the Microsoft.AnalysisServices NuGet package to install. Default is '19.84.1'.

    .PARAMETER SchemaFilePath
    Optional path to Configuration.schema.json for configuration validation.

    .PARAMETER StrictSchema
    When specified, a schema validation failure becomes a terminating error
    instead of a warning.

    .EXAMPLE
    ./PowerBI-migration-accelerator.ps1

    .EXAMPLE
    ./PowerBI-migration-accelerator.ps1 -ConfigFilePath './configurations/Snowflake.json' -Verbose

    .EXAMPLE
    ./PowerBI-migration-accelerator.ps1 -WhatIf

    .EXAMPLE
    ./PowerBI-migration-accelerator.ps1 -StrictSchema

    .NOTES
    Authors:  Andrey Mirskiy, Mohammad Shahedi, Matteo Monaldi

    Useful links:
      JSON-decoding for regex:  https://jsonformatter.org/json-decode
      JSON-encoding for regex:  https://jsonformatter.org/json-encode
      Regex tester:             https://regex101.com/

    .LINK
    https://github.com/databricks-solutions/powerbi-on-databricks-migration-accelerator
#>

#Requires -Version 7.4
#Requires -PSEdition Core

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Position = 0)]
    [ValidateScript({
        if (-not (Test-Path -LiteralPath $_ -PathType Leaf)) {
            throw "Configuration file does not exist: $_"
        }
        $true
    })]
    [string]$ConfigFilePath = "./configurations/Snowflake.json", #"./Configuration.json",

    [Parameter(Position = 1)]
    [string]$LogFilePath,

    [Parameter(Position = 2)]
    [version]$TOMVersion = '19.113.7',

    [Parameter(Position = 3)]
    [string]$SchemaFilePath,

    [Parameter(Position = 4)]
    [switch]$StrictSchema
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$modulePath = Join-Path -Path $PSScriptRoot -ChildPath 'src/PBIMigrationAccelerator.psd1'
if (-not (Test-Path -LiteralPath $modulePath)) {
    throw "PBIMigrationAccelerator module not found at '$modulePath'."
}

Import-Module -Name $modulePath -Force -DisableNameChecking

$invokeParams = @{
    ConfigFilePath = $ConfigFilePath
    TOMVersion     = $TOMVersion
    ModuleRoot     = $PSScriptRoot
}
if ($PSBoundParameters.ContainsKey('LogFilePath'))    { $invokeParams['LogFilePath']    = $LogFilePath }
if ($PSBoundParameters.ContainsKey('SchemaFilePath')) { $invokeParams['SchemaFilePath'] = $SchemaFilePath }
if ($PSBoundParameters.ContainsKey('StrictSchema'))   { $invokeParams['StrictSchema']   = $StrictSchema }

Invoke-PBIMigration @invokeParams
