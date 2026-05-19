function New-MigrationStats {
    <#
    .SYNOPSIS
    Creates an ordered hashtable that tracks statistics across a migration run.
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param()

    return [ordered]@{
        TotalWorkspaces    = 0
        TotalFolders       = 0
        TotalFiles         = 0
        UpdatedFiles       = 0
        TotalDatasets      = 0
        UpdatedDatasets    = 0
        CreatedParameters  = 0
        TotalTables        = 0
        UpdatedTables      = 0
        SkippedTables      = 0
        TotalPartitions    = 0
        UpdatedPartitions  = 0
    }
}
