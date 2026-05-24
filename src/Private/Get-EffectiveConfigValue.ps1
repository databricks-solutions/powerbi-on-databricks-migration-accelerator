function Get-EffectiveConfigValue {
    <#
    .SYNOPSIS
    Returns the first non-null value of a property (or dotted property path) from a
    prioritized list of configuration objects.

    .DESCRIPTION
    Replaces the repeated "if dataset -> elseif parent -> elseif global" pattern used
    throughout the accelerator. The caller supplies the property path and an ordered
    list of configuration objects (most specific first); the first object that defines
    a non-null value wins.

    .PARAMETER Path
    Dotted property path to resolve (for example, 'Properties.CompatibilityLevel').

    .PARAMETER Configs
    Ordered list of configuration objects, most specific first.

    .EXAMPLE
    Get-EffectiveConfigValue -Path 'Properties.CompatibilityLevel' -Configs @($datasetConfig, $parentConfig, $globalConfig)
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [AllowNull()]
        [object[]]$Configs
    )

    if ($null -eq $Configs) { return $null }

    $segments = $Path.Split('.')

    foreach ($cfg in $Configs) {
        if ($null -eq $cfg) { continue }

        $current = $cfg
        $resolved = $true

        foreach ($segment in $segments) {
            if ($null -eq $current) { $resolved = $false; break }

            if ($current.PSObject.Properties.Match($segment).Count -eq 0) {
                $resolved = $false
                break
            }

            $current = $current.$segment
        }

        if ($resolved -and $null -ne $current) {
            return $current
        }
    }

    return $null
}
