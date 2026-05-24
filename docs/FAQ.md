# Frequently Asked Questions

## 1. What are currently supported source platforms?
- HMS
- Snowflake
- Redshift
- Synapse (both Dedicated and Serverless)
- SQL Server family
    - SQL Server
    - Azure SQL Database
    - Azure SQL Managed Instance


## 2. Does it support `.pbix` files?
No. PBIX is a proprietary, closed file format. Microsoft introduced the PBIP file format as an open, future-proof file format that makes semantic model management easier.


## 3. Does it support Native Queries?
Yes. However, it does not update SQL queries inside NativeQuery functions. This means that SQL queries must be updated manually.


## 4. Can we use the mix of data source connections in the same report / semantic model (for example, Synapse and SharePoint)?
Yes. This is supported. Other data source connections (e.g., SharePoint) should not be changed. However, we recommend testing carefully.


## 5. Does it support Catalog, Schema, and Table name changes when migrating to DBSQL/UC?
Yes, mapping from source to target Catalogs/Schemas/Tables can be implemented via callback modules. See example in [Resolve-TableNameMapping.psm1](/src/Callbacks/Resolve-TableNameMapping.psm1).


## 6. Does it support updates to Table names, e.g., replacing special characters (spaces, hyphens), when migrating to DBSQL/UC?
Yes, this can be implemented via callback modules. See example in [ConvertTo-SafeTableName.psm1](/src/Callbacks/ConvertTo-SafeTableName.psm1).


## 7. Does it create backups before applying changes?
The accelerator creates backups for semantic models in Power BI Service if the corresponding feature is configured for the workspace. Creating backups for local `.pbip` files is the user's responsibility.


## 8. What if I don't have local administrator permissions on my machine?
The accelerator itself does not require local administrator permissions. Local admin permissions may be required to install PowerShell 7. However, as a workaround it can be installed from [Microsoft Store](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.4#installing-from-the-microsoft-store).


## 9. Does it support Tableau or other BI tools?
No, this accelerator is for Power BI only. That said, we are happy to hear your feedback on Tableau and other BI tools.


## 10. I have hundreds of `.pbix` files. How can I automate conversion to `.pbip`?
We came across this [community project](https://www.c-sharpcorner.com/article/automated-way-for-pbix-to-pbip-file-conversion/#:~:text=Use%20PBIXtoPBIP_PBITConversion%20%2DPBIXFilePath%20%22%3C%3C,%3E%22%20to%20perform%20the%20conversion.&text=As%20of%20Sep%204%2C%202024,BI%20Desktop's%20File%20%3E%20Save%20As.) that can serve the purpose. However, as this is neither a Databricks nor a Microsoft project, we cannot recommend it. It should be used at the user's discretion and risk.


## 11. Why am I unable to download a `.pbix` file after migrating a published dataset?
While this limitation has been lifted by Microsoft, in some cases semantic models cannot be downloaded as `.pbix` files after being modified via XMLA.


## 12. I am using upper-case characters in table names in my source platform (Snowflake, Synapse, Redshift). Are there any special considerations related to that?
Yes, as Databricks SQL presents all object names (catalogs, schemas, tables, views) as lower case, all object names in Power BI semantic models must be converted to lower case to avoid errors at runtime. This can be achieved by using a callback function that lowers object names. See `Callback` property in `Updates` configuration objects. The accelerator comes with two sample callback functions:
- [ConvertTo-LowerCaseTableName](/src/Callbacks/ConvertTo-LowerCaseTableName.psm1) - changes table names to lower case.
- [ConvertTo-SafeTableName](/src/Callbacks/ConvertTo-SafeTableName.psm1) - replaces special characters in table names (whitespace, hyphens, parentheses) with underscores.
- [Resolve-TableNameMapping](/src/Callbacks/Resolve-TableNameMapping.psm1) - rewrites schema/table names using the mappings defined in [Mappings.csv](/src/Callbacks/Mappings.csv).