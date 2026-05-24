@{
    RootModule           = 'PBIMigrationAccelerator.psm1'
    ModuleVersion        = '0.1.0'
    GUID                 = 'a1b2c3d4-5e6f-7890-abcd-ef0123456789'
    Author               = 'Andrey Mirskiy, Mohammad Shahedi'
    CompanyName          = 'Databricks Field Engineering'
    Copyright            = '(c) Databricks. All rights reserved.'
    Description          = 'Automates switching Power BI semantic models from legacy sources (Snowflake, Synapse, Redshift, SQL Server, HMS) to Databricks SQL / Unity Catalog by rewriting Power Query M code and updating model properties.'

    PowerShellVersion    = '7.4'
    CompatiblePSEditions = @('Core')

    FunctionsToExport    = @(
        'Invoke-PBIMigration'
        'Update-PBIDatabase'
    )
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()

    PrivateData = @{
        PSData = @{
            Tags         = @('PowerBI', 'Databricks', 'Migration', 'TOM', 'Tabular', 'PowerQuery', 'M')
            LicenseUri   = 'https://github.com/databricks-solutions/powerbi-on-databricks-migration-accelerator/blob/main/LICENSE.md'
            ProjectUri   = 'https://github.com/databricks-solutions/powerbi-on-databricks-migration-accelerator'
            ReleaseNotes = 'See CHANGELOG.md'
        }
    }
}
