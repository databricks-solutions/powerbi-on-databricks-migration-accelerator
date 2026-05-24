# How to demo

1. Rebuild the demo folder from the pristine sample reports.
    ```powershell
    ./scripts/Initialize-DemoFolder.ps1
    ```
2. Open Power BI Desktop.
3. Open a sample report from `./_demo`.
4. Use the Power Query editor to show that the report uses Synapse / Snowflake / Redshift / SQL Server as a source.
5. Close Power BI Desktop.
6. Run the accelerator with the default configuration.
    ```powershell
    ./PowerBI-migration-accelerator.ps1
    ```
    Or run it against a platform-specific configuration:
    ```powershell
    ./PowerBI-migration-accelerator.ps1 -ConfigFilePath './configurations/Snowflake.json'
    ```
    Preview every change without writing anything:
    ```powershell
    ./PowerBI-migration-accelerator.ps1 -WhatIf -Verbose
    ```
7. Re-open Power BI Desktop.
8. Open the same sample report.
9. Use the Power Query editor to confirm that it now uses Databricks SQL as a source.
