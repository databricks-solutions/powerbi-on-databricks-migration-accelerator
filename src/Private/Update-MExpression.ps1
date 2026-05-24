function Update-MExpression {
    <#
    .SYNOPSIS
    Applies an ordered list of regex-based update rules to a Power Query M expression.

    .DESCRIPTION
    Each rule either performs a plain Regex::Replace or invokes a callback function
    loaded from an external .psm1 module. Callback modules are cached per invocation
    so they are imported at most once even when the same callback is referenced by
    many rules and partitions.

    .PARAMETER Expression
    The M expression to transform.

    .PARAMETER UpdateRules
    Array of rule objects with SearchPattern, ReplacePattern, and optional Callback
    (Module + Function) properties.

    .PARAMETER ModuleRoot
    Base directory used to resolve relative Callback.Module paths. Defaults to the
    module's parent directory.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [AllowEmptyString()]
        [string]$Expression,

        [Parameter(Mandatory, Position = 1)]
        [AllowNull()]
        [object[]]$UpdateRules,

        [Parameter(Position = 2)]
        [string]$ModuleRoot = (Split-Path -Path $PSScriptRoot -Parent)
    )

    if ($null -eq $UpdateRules -or $UpdateRules.Count -eq 0) {
        return $Expression
    }

    $regexOptions = [Text.RegularExpressions.RegexOptions]'IgnoreCase, CultureInvariant, Multiline'
    $result       = $Expression
    $loadedModules = @{}

    foreach ($rule in $UpdateRules) {
        if ($null -eq $rule) { continue }

        $searchPattern  = $rule.SearchPattern
        $replacePattern = $rule.ReplacePattern

        if ([string]::IsNullOrEmpty($searchPattern)) {
            Write-Verbose "Skipping rule '$($rule.Name)' - empty SearchPattern"
            continue
        }

        if ($rule.PSObject.Properties.Match('Callback').Count -gt 0 -and $null -ne $rule.Callback) {
            $modulePath = $rule.Callback.Module
            if (-not [System.IO.Path]::IsPathRooted($modulePath)) {
                $modulePath = Join-Path -Path $ModuleRoot -ChildPath $modulePath
            }

            if (-not $loadedModules.ContainsKey($modulePath)) {
                if (-not (Test-Path -LiteralPath $modulePath)) {
                    throw "Callback module not found: $modulePath"
                }
                Import-Module -Name $modulePath -Force -DisableNameChecking 
                $loadedModules[$modulePath] = $true
            }

            $callbackName = $rule.Callback.Function
            
            $evaluator = [System.Text.RegularExpressions.MatchEvaluator] {
                param($match)
                & $callbackName $match
            }

            $result = [regex]::Replace($result, $searchPattern, $evaluator, $regexOptions)
        } else {
            if ($null -eq $replacePattern) { $replacePattern = '' }
            $result = [regex]::Replace($result, $searchPattern, $replacePattern, $regexOptions)
        }
    }

    return $result
}
