function ConvertTo-LowerCaseTableName {
    <#
    .SYNOPSIS
    Regex MatchEvaluator callback that lower-cases the value captured by the 'Table'
    named group and returns the full match with only that group rewritten.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [System.Text.RegularExpressions.Match]$Match
    )

    $oldTableName = $Match.Groups['Table'].Value
    $newTableName = $oldTableName.ToLowerInvariant()
    $newValue     = $Match.Value.Replace($oldTableName, $newTableName)

    Write-Debug "ConvertTo-LowerCaseTableName: ""$($Match.Value)"" -> ""$newValue"""
    return $newValue
}

Export-ModuleMember -Function 'ConvertTo-LowerCaseTableName'
