function Invoke-WorkspaceMigration {
    <#
    .SYNOPSIS
    Connects to Power BI Service, iterates through the configured workspaces, and
    applies Update-PBIDatabase to every semantic model that is in-scope.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [object]$GlobalConfig,

        [Parameter(Mandatory)]
        [System.Collections.Specialized.OrderedDictionary]$Stats,

        [Parameter(Mandatory)]
        [string]$ModuleRoot
    )

    if ($null -eq $GlobalConfig.Workspaces -or $GlobalConfig.Workspaces.Count -eq 0) { return }

    $connectedToService = $false
    try {
        Connect-PowerBIServiceAccount -ErrorAction Stop | Out-Null
        $connectedToService = $true

        $pbiToken = (Get-PowerBIAccessToken -AsString) -replace '^Bearer ', ''

        foreach ($workspaceConfig in $GlobalConfig.Workspaces) {
            Write-MigrationLog "Analyzing workspace ""$($workspaceConfig.WorkspaceUrl)""..." -Level Section
            $Stats['TotalWorkspaces']++

            $server = New-Object Microsoft.AnalysisServices.Tabular.Server
            try {
                $connectString = "DataSource=$($workspaceConfig.WorkspaceUrl);Password=$pbiToken"
                $server.Connect($connectString)

                foreach ($database in ($server.Databases | Sort-Object Name)) {
                    $datasetConfig = $null
                    if ($null -ne $workspaceConfig.Datasets) {
                        $datasetConfig = $workspaceConfig.Datasets |
                                         Where-Object { $_.Name -eq $database.Name } |
                                         Select-Object -First 1
                    }

                    $shouldSkip = ($workspaceConfig.IncludeAll -eq $false -and $null -eq $datasetConfig) -or
                                  ($null -ne $datasetConfig -and $datasetConfig.Skip -eq $true)

                    if ($shouldSkip) {
                        Write-MigrationLog "Skipped dataset: ""$($database.Name)""" -Level Info
                        continue
                    }

                    $datasetName = $database.Name

                    try {
                        $needSaveChanges = Update-PBIDatabase -Database $database `
                                                              -GlobalConfig $GlobalConfig `
                                                              -ParentConfig $workspaceConfig `
                                                              -DatasetConfig $datasetConfig `
                                                              -DatasetName $datasetName `
                                                              -Stats $Stats `
                                                              -ModuleRoot $ModuleRoot
                        $Stats['TotalDatasets']++

                        if ($needSaveChanges) {
                            if ($PSCmdlet.ShouldProcess($datasetName, 'Persist TOM changes (Model.SaveChanges)')) {
                                Write-MigrationLog "Saving changes to dataset ""$datasetName""..." -Level Warning
                                $database.Model.SaveChanges() | Out-Null
                                Write-MigrationLog "Saving changes to dataset ""$datasetName"" completed" -Level Success
                                $Stats['UpdatedDatasets']++
                            }

                            $needRefresh = Get-EffectiveConfigValue -Path 'RefreshAfterUpdate' -Configs @($datasetConfig, $workspaceConfig, $GlobalConfig)
                            if ($needRefresh) {
                                if ($PSCmdlet.ShouldProcess($datasetName, 'Request full refresh')) {
                                    Write-MigrationLog "Refreshing dataset ""$datasetName"" started..." -Level Warning
                                    $database.Model.RequestRefresh([Microsoft.AnalysisServices.Tabular.RefreshType]'Full')
                                    Write-MigrationLog "Refreshing dataset ""$datasetName"" completed" -Level Success
                                }
                            }
                        } else {
                            Write-MigrationLog "No changes identified for dataset ""$datasetName""" -Level Info
                        }
                    } catch {
                        Write-MigrationLog "Processing dataset ""$datasetName"" - error occurred: $_" -Level Error
                    }
                }
            } finally {
                try { $server.Disconnect() } catch { Write-Verbose "Server.Disconnect failed: $_" }
                try { $server.Dispose() }    catch { Write-Verbose "Server.Dispose failed: $_" }
            }

            Write-MigrationLog "Analyzing workspace ""$($workspaceConfig.WorkspaceUrl)"" completed" -Level Section
        }
    } finally {
        if ($connectedToService) {
            try { Disconnect-PowerBIServiceAccount | Out-Null } catch { Write-Verbose "Disconnect-PowerBIServiceAccount failed: $_" }
        }
    }
}
