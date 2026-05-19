<#
    .SYNOPSIS
    Rebuilds the sample report folders used by the demo configuration.

    .DESCRIPTION
    Copies the pristine "samples-pbip" folder into the demo folders so
    each demo run starts from a clean state. The target folders are removed and
    recreated.

    .PARAMETER SourceFolder
    The pristine source folder. Defaults to "./samples-pbip".

    .PARAMETER TargetFolders
    List of demo folders to rebuild.

    .EXAMPLE
    ./scripts/Initialize-DemoFolder.ps1
#>

#Requires -Version 7.4

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [string]$SourceFolder = './samples-pbip',

    [Parameter()]
    [string[]]$TargetFolders = @(
        './_demo'
    )
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $SourceFolder)) {
    throw "Source folder not found: $SourceFolder"
}

foreach ($target in $TargetFolders) {
    if (Test-Path -LiteralPath $target) {
        if ($PSCmdlet.ShouldProcess($target, 'Remove existing demo folder')) {
            Remove-Item -Path $target -Recurse -Force
        }
    }
    if ($PSCmdlet.ShouldProcess($target, "Copy from $SourceFolder")) {
        Copy-Item -Path $SourceFolder -Destination $target -Recurse
    }
}

Write-Information "Demo folders refreshed." -InformationAction Continue
