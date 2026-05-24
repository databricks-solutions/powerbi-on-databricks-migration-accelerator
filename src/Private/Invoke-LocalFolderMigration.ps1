function Invoke-LocalFolderMigration {
    <#
    .SYNOPSIS
    Iterates through local .pbip files in the folders listed in the global config and
    applies Update-PBIDatabase to each one.
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

    if ($null -eq $GlobalConfig.Folders) { return }

    foreach ($folderConfig in $GlobalConfig.Folders) {
        Write-MigrationLog "Analyzing local folder ""$($folderConfig.Path)""..." -Level Section
        $Stats['TotalFolders']++

        if (-not (Test-Path -LiteralPath $folderConfig.Path)) {
            Write-MigrationLog "Folder not found: $($folderConfig.Path)" -Level Warning
            continue
        }

        $pbipFiles = Get-ChildItem -Path $folderConfig.Path -Filter '*.pbip' -ErrorAction SilentlyContinue

        foreach ($file in $pbipFiles) {
            $fileConfig = $null
            if ($null -ne $folderConfig.Datasets) {
                $fileConfig = $folderConfig.Datasets | Where-Object { $_.Name -eq $file.BaseName } | Select-Object -First 1
            }

            $shouldSkip = ($folderConfig.IncludeAll -eq $false -and $null -eq $fileConfig) -or
                          ($null -ne $fileConfig -and $fileConfig.Skip -eq $true)

            if ($shouldSkip) {
                Write-MigrationLog "Skipped file: ""$($file.BaseName)""" -Level Info
                continue
            }

            $tmdlPath    = Join-Path -Path $file.DirectoryName -ChildPath ($file.BaseName + '.SemanticModel')
            $tmdlPath    = Join-Path -Path $tmdlPath -ChildPath 'definition'
            $datasetName = $file.BaseName + '.pbip'

            if (-not (Test-Path -LiteralPath $tmdlPath)) {
                Write-MigrationLog "TMDL definition folder not found for ""$datasetName"": $tmdlPath" -Level Warning
                continue
            }

            try {
                $database = [Microsoft.AnalysisServices.Tabular.TmdlSerializer]::DeserializeDatabaseFromFolder($tmdlPath)

                $needSaveChanges = Update-PBIDatabase -Database $database `
                                                      -GlobalConfig $GlobalConfig `
                                                      -ParentConfig $folderConfig `
                                                      -DatasetConfig $fileConfig `
                                                      -DatasetName $datasetName `
                                                      -Stats $Stats `
                                                      -ModuleRoot $ModuleRoot
                $Stats['TotalFiles']++

                if ($needSaveChanges) {
                    if ($PSCmdlet.ShouldProcess($datasetName, 'Serialize TMDL changes to disk')) {
                        Write-MigrationLog "Saving changes to file ""$datasetName""..." -Level Warning
                        [Microsoft.AnalysisServices.Tabular.TmdlSerializer]::SerializeDatabaseToFolder($database, $tmdlPath)
                        Write-MigrationLog "Saving changes to file ""$datasetName"" completed" -Level Success
                        $Stats['UpdatedFiles']++
                    }
                } else {
                    Write-MigrationLog "No changes identified for file ""$datasetName""" -Level Info
                }
            } catch {
                Write-MigrationLog "Processing file ""$datasetName"" - error occurred: $_" -Level Error
            }
        }

        Write-MigrationLog "Analyzing local folder ""$($folderConfig.Path)"" completed" -Level Section
    }
}
