# Published Power BI semantic models migration

> [!NOTE]
> This example demonstrates the migration of Power BI semantic models published in a Power BI workspace.

## Sample configuration file
[Workspaces.json](./Workspaces.json)

## Description
The following configuration guides the accelerator to perform the following steps:
1. The accelerator connects to Power BI workspace `powerbi://api.powerbi.com/v1.0/myorg/_%20Power%20BI%20Migration%20Accelerator` and iterates through semantic models in the workspace.
2. Semantic model **HMS-incremental-refresh** is explicitly skipped.
3. Semantic model **HMS** is explicitly included.
4. For every semantic model the accelerator performs the following steps:
    - backup semantic model to default ADLS account configured at Power BI workspace
    - set semantic model properties:
        - *CompatibilityLevel* = 1569
        - *MaxParallelismPerQuery* = 11
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
    "Backup":               true,
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
            "SearchPattern":  "(?<Start>[\\s]+Source[\\s]*=[\\s]*Databricks\\.Catalogs[\\s]*\\([\\s]*)(?<ServerHostname>\"[^\"]+\")(?<Between>[\\s]*\\,[\\s]*)(?<HTTPPath>\"[^\"]+\")",
            "ReplacePattern": "${Start}ServerHostname${Between}HTTPPath"
        },
        {
            "Name":           "hive_metastore to UC - replace catalog",
            "Enabled":        true,
            "Order":          2,
            "SearchPattern":  "(?<Start>=[\\s]*Source[\\s]*{[\\s]*\\[[\\s]*Name[\\s]*=[\\s]*)(?<HMS>\"hive_metastore\")(?<Ending>[\\s]*,[\\s]*Kind[\\s]*=[\\s]*\"Database\")",
            "ReplacePattern": "${Start}Catalog${Ending}"
        },
        {
            "Name":           "SPARK to UC - replace catalog",
            "Enabled":        false,
            "Order":          2,
            "SearchPattern":  "(?<Start>=[\\s]*Source[\\s]*{[\\s]*\\[[\\s]*Name[\\s]*=[\\s]*)(?<HMS>\"SPARK\")(?<Ending>[\\s]*,[\\s]*Kind[\\s]*=[\\s]*\"Database\")",
            "ReplacePattern": "${Start}Catalog${Ending}"
        },
        {
            "Name":           "HMS to UC - replace schema",
            "Enabled":        true,
            "Order":          3,
            "SearchPattern":  "(?<Start>[\\s]*{[\\s]*\\[[\\s]*Name[\\s]*=[\\s]*)(?<Schema>\"tpch_sf1_delta_nopartitions\")(?<Ending>[\\s]*,[\\s]*Kind[\\s]*=[\\s]*\"Schema\")",
            "ReplacePattern": "${Start}Schema${Ending}"
        }
    ],

    "Folders":
    [
    ],

    "Workspaces":
    [
        {
            "WorkspaceUrl": "powerbi://api.powerbi.com/v1.0/myorg/_%20Power%20BI%20Migration%20Accelerator",

            "RefreshAfterUpdate":   null,
            "Properties":           {}, 

            "Parameterize":         null,
            "Parameters":           null,

            "Datasets": [
                {
                    "Name":         "HMS-incremental-refresh",
                    "Skip":         true,

                    "Properties":   {}, 
                    
                    "Parameterize": null,
                    "Parameters":   null,
                    
                    "Updates":      null
                },
                {
                    "Name":         "HMS",
                    "Skip":         false,
                    "Properties":   {}
                }
            ]
        }
    ]

}
```