# Local Power BI Project files migration

> [!NOTE]
> This example demonstrates the migration of Power BI project files (*.pbip) residing in a local folder.

## Sample configuration file
[Files.json](./Files.json)

## Description
The following configuration guides the accelerator to perform the following steps:
1. The accelerator analyzes `.pbip` files in local folder `./_demo`.
2. The files **Redshift**, **Snowflake**, **SqlServer**, and **Synapse** are explicitly skipped.
3. For every semantic model the accelerator performs the following steps:
    - set semantic model properties:
        - *CompatibilityLevel* - skipped, not supported for files
        - *MaxParallelismPerQuery* - skipped, not supported for files
        - *DataSourceDefaultMaxConnections* = 20
    - create new parameters:
        - *ServerHostname* = adb-2219810816778143.3.azuredatabricks.net
        - *HTTPPath* = /sql/1.0/warehouses/a5ad4687dadae274
        - *Catalog* = tpch
        - *Schema* = sf1
    - parameterize Databricks connection using **ServerHostname** and **HTTPPath** parameters
    - replace the hard-coded catalog name ```hive_metastore``` with the ```Catalog``` parameter
    - replace the hard-coded schema value with the ```Schema``` parameter


```json
{
    "$schema":              "../Configuration.schema.json",
    "Backup":               false,
    "RefreshAfterUpdate":   false,

    "Properties": {
        "CompatibilityLevel":              1569,
        "MaxParallelismPerQuery":          11,
        "DataSourceDefaultMaxConnections": 20
    }, 

    "Parameterize": true,
    "Parameters": [
        {
            "Name" : "ServerHostname",
            "Value": "adb-2219810816778143.3.azuredatabricks.net",
            "Type":  "Text"
        },
        {
            "Name" : "HTTPPath",
            "Value": "/sql/1.0/warehouses/a5ad4687dadae274",
            "Type":  "Text"
        },
        {
            "Name" : "Catalog",
            "Value": "tpch",
            "Type":  "Text"
        },
        {
            "Name" : "Schema",
            "Value": "sf1",
            "Type":  "Text"
        }
    ],

    "Updates": [
        {
            "Name":           "HMS to UC - parameterize connection",
            "Enabled":        true,
            "Order":          1,
            "SearchPattern":  "(?<Start>[\\s]+[^\\s]+[\\s]*=[\\s]*Databricks\\.Catalogs[\\s]*\\([\\s]*)(?<ServerHostname>\"[^\"]+\")(?<Between>[\\s]*\\,[\\s]*)(?<HTTPPath>\"[^\"]+\")",
            "ReplacePattern": "${Start}ServerHostname${Between}HTTPPath"
        },
        {
            "Name":           "hive_metastore to UC – parameterize catalog 1",
            "Enabled":        true,
            "Order":          2,
            "SearchPattern":  "(?<Start>=[\\s]*[^\\s]+[\\s]*{[\\s]*\\[[\\s]*Name[\\s]*=[\\s]*)(?<HMS>\"hive_metastore\")(?<Ending>[\\s]*,[\\s]*Kind[\\s]*=[\\s]*\"Database\")",
            "ReplacePattern": "${Start}Catalog${Ending}"
        },
        {
            "Name":           "SPARK to UC – parameterize catalog",
            "Enabled":        false,
            "Order":          2,
            "SearchPattern":  "(?<Start>=[\\s]*[^\\s]+[\\s]*{[\\s]*\\[[\\s]*Name[\\s]*=[\\s]*)(?<HMS>\"SPARK\")(?<Ending>[\\s]*,[\\s]*Kind[\\s]*=[\\s]*\"Database\")",
            "ReplacePattern": "${Start}Catalog${Ending}"
        },
        {
            "Name":           "HMS to UC - parameterize schema 1",
            "Enabled":        true,
            "Order":          3,
            "SearchPattern":  "(?<Start>[\\s]*{[\\s]*\\[[\\s]*Name[\\s]*=[\\s]*)(?<Schema>\"tpch_sf1_delta_nopartitions\")(?<Ending>[\\s]*,[\\s]*Kind[\\s]*=[\\s]*\"Schema\")",
            "ReplacePattern": "${Start}Schema${Ending}"
        },
        {
            "Name":           "HMS to UC - parameterize catalog 2",
            "Enabled":        true,
            "Order":          4,
            "SearchPattern":  "(?<Start>.+Databricks\\.Catalogs.+Catalog[\\s]*=[\\s]*)(?<Catalog>\"[^\"]+\")",
            "ReplacePattern": "${Start}Catalog"
        },
        {
            "Name":           "HMS to UC - parameterize catalog 3",
            "Enabled":        true,
            "Order":          4,
            "SearchPattern":  "(?<Start>.+=.+Item[\\s]*=.+Catalog[\\s]*=[\\s]*)(?<Catalog>\"[^\"]+\")",
            "ReplacePattern": "${Start}Catalog"
        },
        {
            "Name":           "HMS to UC - parameterize schema 2",
            "Enabled":        true,
            "Order":          5,
            "SearchPattern":  "(?<Start>.+Databricks\\.Catalogs.+Database[\\s]*=[\\s]*)(?<Schema>\"[^\"]+\")",
            "ReplacePattern": "${Start}Schema"
        },
        {
            "Name":           "HMS to UC - parameterize schema 3",
            "Enabled":        true,
            "Order":          5,
            "SearchPattern":  "(?<Start>.+=.+Item[\\s]*=.+Schema[\\s]*=[\\s]*)(?<Schema>\"[^\"]+\")",
            "ReplacePattern": "${Start}Schema"
        },

        {
            "Name":           "Databricks - parameterize Native Queries",
            "Enabled":        true,
            "Order":          100,
            "SearchPattern":  "(?<Start>[\\s]+[^\\s]+[\\s]*=[\\s]*Value.NativeQuery\\([\\s]*Databricks\\.Catalogs[\\s]*\\([\\s]*)(?<ServerHostname>\"[^\"]+\")(?<Between>[\\s]*\\,[\\s]*)(?<HTTPPath>\"[^\"]+\")",
            "ReplacePattern": "${Start}ServerHostname${Between}HTTPPath"
        },
        {
            "Name":           "Databricks - parameterize Native Queries catalog 1",
            "Enabled":        true,
            "Order":          1000,
            "SearchPattern":  "(?<Start>Name[\\s]*=[\\s]*)(?<Catalog>\"hive_metastore\")(?<Ending>[\\s]*,[\\s]*Kind[\\s]*=[\\s]*\"Database\")",
            "ReplacePattern": "${Start}Catalog${Ending}"
        },
        {
            "Name":           "Databricks - parameterize Native Queries catalog 2",
            "Enabled":        true,
            "Order":          1000,
            "SearchPattern":  "(?<Start>Catalog[\\s]*=[\\s]*)(?<Catalog>\"hive_metastore\")",
            "ReplacePattern": "${Start}Catalog"
        } 
    ],


    "Folders":
    [
        {
            "Path":                 "./_demo",
            "IncludeAll":           true,

            "RefreshAfterUpdate":   null,
            "Properties":           {}, 

            "Parameterize":         null,
            "Parameters":           null,
            
            "Datasets": [
                {
                    "Name":         "Redshift",
                    "Skip":         true
                },
                {
                    "Name":         "Snowflake",
                    "Skip":         true
                },
                {
                    "Name":         "SqlServer",
                    "Skip":         true
                },
                {
                    "Name":         "Synapse",
                    "Skip":         true
                }
            ]
        }
    ]
}
```