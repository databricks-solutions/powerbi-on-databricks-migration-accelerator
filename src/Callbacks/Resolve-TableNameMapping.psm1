$script:MappingCache = $null

function Get-TableNameMappingCache {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter()]
        [string]$MappingsPath = (Join-Path -Path $PSScriptRoot -ChildPath 'Mappings.csv')
    )

    if ($null -eq $script:MappingCache) {
        if (-not (Test-Path -LiteralPath $MappingsPath)) {
            throw "Mappings file not found: $MappingsPath"
        }
        $script:MappingCache = @(Import-Csv -Path $MappingsPath -Delimiter '|')
    }
    return $script:MappingCache
}

function Resolve-TableNameMapping {
    <#
    .SYNOPSIS
    Regex MatchEvaluator callback that rewrites the 'Schema' and 'Table' named groups
    using the source->target mappings defined in Mappings.csv. Unmapped schema/table
    combinations are passed through unchanged.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [System.Text.RegularExpressions.Match]$Match
    )

    $mappings     = Get-TableNameMappingCache
    $sourceSchema = $Match.Groups['Schema'].Value
    $sourceTable  = $Match.Groups['Table'].Value

    $tableMapping = $mappings | Where-Object {
        $_.SourceSchema -eq $sourceSchema -and $_.SourceTable -eq $sourceTable
    } | Select-Object -First 1

    if ($tableMapping) {
        $targetSchema = $tableMapping.TargetSchema
        $targetTable  = $tableMapping.TargetTable
    } else {
        $targetSchema = $sourceSchema
        $targetTable  = $sourceTable
    }

    $replacements = @{
        'Schema' = $targetSchema
        'Table'  = $targetTable
    }

    $builder       = [System.Text.StringBuilder]::new($Match.Length)
    $cursorInMatch = 0
    $orderedGroups = @($Match.Groups['Schema'], $Match.Groups['Table']) |
                     Where-Object { $_.Success } |
                     Sort-Object Index

    foreach ($group in $orderedGroups) {
        $groupStartInMatch = $group.Index - $Match.Index
        if ($groupStartInMatch -gt $cursorInMatch) {
            [void]$builder.Append($Match.Value.Substring($cursorInMatch, $groupStartInMatch - $cursorInMatch))
        }
        [void]$builder.Append($replacements[$group.Name])
        $cursorInMatch = $groupStartInMatch + $group.Length
    }

    if ($cursorInMatch -lt $Match.Length) {
        [void]$builder.Append($Match.Value.Substring($cursorInMatch))
    }

    return $builder.ToString()
}

Export-ModuleMember -Function 'Resolve-TableNameMapping'
