function ConvertTo-SafeTableName {
    <#
    .SYNOPSIS
    Regex MatchEvaluator callback that replaces whitespace, hyphens, and parentheses
    in the captured 'Table' group with underscores so the name is safe to use in
    Databricks SQL / Unity Catalog identifiers.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [System.Text.RegularExpressions.Match]$Match
    )

    $oldTableName = $Match.Groups['Table'].Value
    $newTableName = $oldTableName -replace '[\s()\-]', '_'
    $newValue     = $Match.Value.Replace($oldTableName, $newTableName)

    Write-Debug "ConvertTo-SafeTableName: ""$($Match.Value)"" -> ""$newValue"""
    return $newValue
}

Export-ModuleMember -Function 'ConvertTo-SafeTableName'
