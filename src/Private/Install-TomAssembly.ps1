function Install-TomAssembly {
    <#
    .SYNOPSIS
    Downloads the Microsoft.AnalysisServices NuGet package (if needed) and loads the
    Tabular Object Model assembly into the current session.

    .PARAMETER TOMVersion
    Version of Microsoft.AnalysisServices to install.

    .PARAMETER Destination
    Directory into which the NuGet package will be installed. Defaults to the current
    working directory.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [version]$TOMVersion ,

        [Parameter()]
        [string]$Destination = (Join-Path(Get-Location).ProviderPath ".libraries")
    )

    if (-not (Get-Module -ListAvailable -Name 'MicrosoftPowerBIMgmt.Profile')) {
        Write-MigrationLog "Installing module MicrosoftPowerBIMgmt.Profile..." -Level Warning
        Install-Module -Name MicrosoftPowerBIMgmt.Profile -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
    }

    if (-not (Get-PackageSource -ProviderName NuGet -ErrorAction SilentlyContinue)) {
        Write-MigrationLog "NuGet package source not found. Registering nuget.org..." -Level Warning
        Register-PackageSource -Name 'nuget.org' `
                               -Location 'https://api.nuget.org/v3/index.json' `
                               -ProviderName NuGet `
                               -Trusted `
                               -Force | Out-Null
    }

    $installParams = @{
        Name             = 'Microsoft.AnalysisServices'
        RequiredVersion  = $TOMVersion.ToString()
        ProviderName     = 'NuGet'
        Scope            = 'CurrentUser'
        SkipDependencies = $true
        Destination      = $Destination
        Force            = $false
        ErrorAction      = 'Stop'
    }
    Install-Package @installParams | Out-Null

    Write-MigrationLog "Loading TOM library ..." -Level Warning

    $candidate = Join-Path -Path $Destination -ChildPath "Microsoft.AnalysisServices.$TOMVersion/lib/net8.0/Microsoft.AnalysisServices.Tabular.dll"
    if (-not (Test-Path -LiteralPath $candidate)) {
        throw "Could not find TOM library at '$candidate'. NuGet install may have failed."
    }

    [System.Reflection.Assembly]::LoadFrom($candidate) | Out-Null
}

#Install-TomAssembly -TOMVersion '19.84.1'