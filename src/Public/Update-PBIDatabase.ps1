function Update-PBIDatabase {
    <#
    .SYNOPSIS
    Applies configuration-driven updates to a single Power BI semantic model loaded
    via the Tabular Object Model (TOM).

    .DESCRIPTION
    Updates model-level properties (CompatibilityLevel, MaxParallelismPerQuery,
    DataSourceDefaultMaxConnections), adds any missing parameters, and rewrites the
    M-expression of every non-system partition using the configured update rules.

    Configuration precedence: DatasetConfig -> ParentConfig -> GlobalConfig. The
    precedence is resolved via Get-EffectiveConfigValue, so there are no repeated
    if/elseif chains.

    Statistics are accumulated into the ordered hashtable passed via -Stats; the
    function itself returns $true if any change was made that requires persistence.

    .PARAMETER Database
    A Microsoft.AnalysisServices.Tabular.Database instance (loaded from TMDL folder
    or from the XMLA endpoint of a Power BI workspace).

    .PARAMETER GlobalConfig
    The root configuration object (from ConvertFrom-Json).

    .PARAMETER ParentConfig
    The workspace or folder configuration object containing this dataset.

    .PARAMETER DatasetConfig
    The dataset-specific configuration object, if any.

    .PARAMETER DatasetName
    Human-readable dataset name used in log lines. Defaults to Database.Name.

    .PARAMETER Stats
    Ordered hashtable returned by New-MigrationStats that accumulates run counters.

    .PARAMETER ModuleRoot
    Base directory used to resolve callback module paths.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNull()]
        $Database,

        [Parameter(Mandatory, Position = 1)]
        [ValidateNotNull()]
        $GlobalConfig,

        [Parameter(Position = 2)]
        $ParentConfig,

        [Parameter(Position = 3)]
        $DatasetConfig,

        [Parameter(Position = 4)]
        [string]$DatasetName,

        [Parameter()]
        [System.Collections.Specialized.OrderedDictionary]$Stats,

        [Parameter()]
        [string]$ModuleRoot
    )

    if ([string]::IsNullOrEmpty($DatasetName)) { $DatasetName = $Database.Name }
    if ($null -eq $Stats)                      { $Stats       = New-MigrationStats }
    if ([string]::IsNullOrEmpty($ModuleRoot))  { $ModuleRoot  = Split-Path -Path $PSScriptRoot -Parent }

    $datasetId = $null
    if ($Database.PSObject.Properties.Match('ID').Count -gt 0) { $datasetId = $Database.ID }

    $configChain = @($DatasetConfig, $ParentConfig, $GlobalConfig)

    Write-MigrationLog "Dataset name: ""$DatasetName""" -Level Success
    Write-MigrationLog "Dataset ID: ""$datasetId""" -Level Success
    Write-MigrationLog "CompatibilityMode:  ""$($Database.CompatibilityMode)""" -Level Debug
    Write-MigrationLog "CompatibilityLevel: ""$($Database.CompatibilityLevel)""" -Level Debug
    Write-MigrationLog "EstimatedSize:      ""$($Database.EstimatedSize)""" -Level Debug
    Write-MigrationLog "LastUpdated:        ""$($Database.LastUpdate)""" -Level Debug
    Write-MigrationLog "LastProcessed:      ""$($Database.LastProcessed)""" -Level Debug
    Write-MigrationLog "LastSchemaUpdate:   ""$($Database.LastSchemaUpdate)""" -Level Debug

    $needSaveChanges = $false
    $model           = $Database.Model

    $backup = Get-EffectiveConfigValue -Path 'Backup' -Configs $configChain
    if ($backup -and $null -ne $datasetId) {
        $backupFileName = '{0} {1:yyyyMMddTHHmmss}.abf' -f $Database.Name, (Get-Date)
        if ($PSCmdlet.ShouldProcess($DatasetName, "Back up to $backupFileName")) {
            Write-MigrationLog "Backing up dataset ""$DatasetName""..." -Level Warning
            $Database.Backup($backupFileName)
            Write-MigrationLog "Backing up dataset ""$DatasetName"" completed" -Level Success
        }
    }

    if ($null -ne $datasetId) {
        $targetCompatibilityLevel = Get-EffectiveConfigValue -Path 'Properties.CompatibilityLevel' -Configs $configChain
        if ($null -ne $targetCompatibilityLevel -and $Database.CompatibilityLevel -lt $targetCompatibilityLevel) {
            if ($PSCmdlet.ShouldProcess($DatasetName, "Set CompatibilityLevel=$targetCompatibilityLevel")) {
                $Database.CompatibilityLevel = $targetCompatibilityLevel
                $Database.Update()
                Write-MigrationLog "Updated dataset ""$DatasetName"" : Compatibility Level = $targetCompatibilityLevel" -Level Warning
            }
        }

        $targetMaxParallelismPerQuery = Get-EffectiveConfigValue -Path 'Properties.MaxParallelismPerQuery' -Configs $configChain
        if ($null -ne $targetMaxParallelismPerQuery -and $model.MaxParallelismPerQuery -ne $targetMaxParallelismPerQuery) {
            $needSaveChanges = $true
            $model.MaxParallelismPerQuery = $targetMaxParallelismPerQuery
            Write-MigrationLog "Updated dataset ""$DatasetName"" : Max Parallelism per Query = $targetMaxParallelismPerQuery" -Level Warning
        }
    }

    $targetMaxConnections = Get-EffectiveConfigValue -Path 'Properties.DataSourceDefaultMaxConnections' -Configs $configChain
    if ($null -ne $targetMaxConnections -and $model.DataSourceDefaultMaxConnections -ne $targetMaxConnections) {
        $needSaveChanges = $true
        $model.DataSourceDefaultMaxConnections = $targetMaxConnections
        Write-MigrationLog "Updated dataset ""$DatasetName"" : Data Source Default Max Connections = $targetMaxConnections" -Level Warning
    }

    $parameterize = Get-EffectiveConfigValue -Path 'Parameterize' -Configs $configChain
    if ($parameterize) {
        $newParamCollection = Get-EffectiveConfigValue -Path 'Parameters' -Configs $configChain

        foreach ($configParameter in @($newParamCollection)) {
            if ($null -eq $configParameter) { continue }

            $paramName  = $configParameter.Name
            $paramValue = $configParameter.Value
            $paramType  = $configParameter.Type

            if (-not $model.Expressions.ContainsName($paramName)) {
                Write-MigrationLog "Updating dataset ""$DatasetName"" : adding parameter $paramName=$paramValue" -Level Info
                $newParam = New-Object Microsoft.AnalysisServices.Tabular.NamedExpression
                $newParam.Name       = $paramName
                $newParam.Kind       = [Microsoft.AnalysisServices.Tabular.ExpressionKind]::M
                $newParam.Expression = '"{0}" meta [IsParameterQuery=true, Type="{1}", IsParameterQueryRequired=false]' -f $paramValue, $paramType
                $newParam.LineageTag = (New-Guid).ToString()
                $model.Expressions.Add($newParam)
                $needSaveChanges = $true
                $Stats['CreatedParameters']++
            }
        }
    }

    $updates = Get-EffectiveConfigValue -Path 'Updates' -Configs $configChain
    if ($null -ne $updates) {
        $updates = @($updates | Where-Object { $_.Enabled -eq $true } | Sort-Object Order)
    }

    $skipTables = @(Get-EffectiveConfigValue -Path 'SkipTables' -Configs $configChain)
    $unmatchedSkipTables = [System.Collections.Generic.HashSet[string]]::new(
        [string[]]$skipTables,
        [System.StringComparer]::Ordinal
    )

    foreach ($table in $model.Tables) {
        if ($table.SystemManaged) { continue }

        if ($skipTables -ccontains $table.Name) {
            Write-MigrationLog "Skipping table ""$($table.Name)"" (matched SkipTables)" -Level Info
            $Stats['SkippedTables']++
            $null = $unmatchedSkipTables.Remove($table.Name)
            continue
        }

        Write-MigrationLog "Analyzing table ""$($table.Name)""..." -Level Info

        if ($null -eq $updates -or $updates.Count -eq 0) { continue }

        $Stats['TotalTables']++
        $tableChanged = $false

        if ($null -ne $table.RefreshPolicy) {
            $expression   = $table.RefreshPolicy.SourceExpression
            $newExpression = Update-MExpression -Expression $expression -UpdateRules $updates -ModuleRoot $ModuleRoot

            if ($newExpression -ne $expression -and -not [string]::IsNullOrEmpty($newExpression)) {
                Write-MigrationLog "Updating table ""$($table.Name)"" refresh policy..." -Level Info
                $table.RefreshPolicy.SourceExpression = $newExpression
                $needSaveChanges = $true
            }
        }

        foreach ($partition in $table.Partitions) {
            if ($partition.SourceType -ne 'M') { continue }

            $Stats['TotalPartitions']++

            $expression    = $partition.Source.Expression
            $newExpression = Update-MExpression -Expression $expression -UpdateRules $updates -ModuleRoot $ModuleRoot

            if ($newExpression -ne $expression -and -not [string]::IsNullOrEmpty($newExpression)) {
                Write-MigrationLog "Updating table ""$($table.Name)"" partition ""$($partition.Name)""..." -Level Info
                $partition.Source.Expression = $newExpression
                $needSaveChanges = $true
                $tableChanged    = $true
                $Stats['UpdatedPartitions']++
            }
        }

        if ($tableChanged) { $Stats['UpdatedTables']++ }
    }

    foreach ($unmatched in $unmatchedSkipTables) {
        Write-MigrationLog "SkipTables entry ""$unmatched"" did not match any table in dataset ""$DatasetName"" (names are case-sensitive)" -Level Warning
    }

    return $needSaveChanges
}
