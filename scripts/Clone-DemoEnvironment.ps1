<#
    .SYNOPSIS
    Clones a fresh copy of the accelerator repository into a local demo folder,
    then strips the .git directory so the copy is stand-alone.

    .PARAMETER DemoFolder
    Target directory. Will be removed and recreated.

    .PARAMETER RepositoryUrl
    Git URL to clone from.

    .EXAMPLE
    ./scripts/Clone-DemoEnvironment.ps1
#>

#Requires -Version 7.4

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [string]$DemoFolder = 'C:\_powerbi-on-databricks-migration-accelerator',

    [Parameter()]
    [string]$RepositoryUrl = 'https://github.com/databricks-solutions/powerbi-on-databricks-migration-accelerator.git'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (Test-Path -LiteralPath $DemoFolder) {
    if ($PSCmdlet.ShouldProcess($DemoFolder, 'Remove existing demo folder')) {
        Remove-Item -Path $DemoFolder -Recurse -Force
    }
}

if ($PSCmdlet.ShouldProcess($DemoFolder, "git clone $RepositoryUrl")) {
    git clone $RepositoryUrl $DemoFolder
}

$gitFolder = Join-Path -Path $DemoFolder -ChildPath '.git'
if (Test-Path -LiteralPath $gitFolder) {
    if ($PSCmdlet.ShouldProcess($gitFolder, 'Remove .git directory')) {
        Remove-Item -Path $gitFolder -Recurse -Force
    }
}
