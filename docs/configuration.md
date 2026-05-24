# Configuration overview

> Every configuration file is validated against [Configuration.schema.json](/Configuration.schema.json) at startup. Add `"$schema": "./Configuration.schema.json"` (or `"../Configuration.schema.json"` for files in subfolders) as the first property of your JSON to get IDE autocomplete and inline validation.

The configuration file contains a set of key-value pairs that are required to run the [PowerBI-migration-accelerator.ps1](../PowerBI-migration-accelerator.ps1) script. The configuration is defined hierarchically: general → workspaces → datasets. This means that:
1. General settings are applied first;
2. If workspace-level settings are defined, they override general settings;
3. If dataset-level settings are defined, they override general and workspace-level settings.

This enables implementing flexible and concise configuration to process hundreds of Power BI semantic models in multiple workspaces.


## General Properties
These are the settings you may configure globally.

| **Setting** 	| **Type** | **Sample values** 	| Description 	|
|---	|--- |---	|---	|
| ``` Backup ``` 	| boolean | ```true``` / ```false``` 	| The flag indicating whether semantic model backups will be created before applying changes	|
| ```RefreshAfterUpdate``` | boolean | ```true``` / ```false``` | The flag indicating whether semantic model refresh should be performed after all updates 	|
| ```Properties``` 	| object | see [Properties](#properties) | Common semantic model properties, e.g., Compatibility Mode 	|
| ```Parameterize``` 	| boolean | ```true``` / ```false``` 	| The flag indicating whether semantic model parameters will be created 	|
| ```Parameters``` 	| array | see [Parameters](#parameters) 	| The list of parameters to be created in semantic models |
| ```Updates``` 	| array | see [Updates](#updates) | The list of updates to be applied on semantic models |
| ```SkipTables``` 	| array | ```["TableA", "TableB"]``` 	| The list of table names to skip during processing. Matching tables are not analyzed and their partitions are not updated. Can be overridden at workspace, folder, or dataset level.	|
| ```Workspaces``` 	| array | see [Workspace Properties](#workspace-properties) 	| The array of workspace configurations. The accelerator will analyze and update every workspace explicitly mentioned in this array.	|
| ```Folders``` 	| array | see [Folder Properties](#folder-properties) 	| The array of local folder configurations. The accelerator will analyze and update every folder explicitly mentioned in this array.	|

> [!WARNING]
> **`SkipTables` matching is case-sensitive and requires an exact match against the table name as it appears in the original Power BI report (the `Name` of the table in the semantic model, not the visual caption).**
> A name that does not match any table in a dataset is reported as a warning in the run log so typos and renames surface immediately. Matching is literal — no wildcards or regular expressions.


## Workspace Properties
These properties are configured at workspace level. The format is a list of key-value pairs in JSON. If the settings are not provided, the general settings will be used:

| **Setting** 	| **Type** | **Sample values** 	| Description 	|
|---	|--- |---	|---	|
| ```WorkspaceUrl``` | string | ```powerbi://api.powerbi.com/v1.0/myorg/***```	| The URL of the workspace	|
| ```IncludeAll``` | boolean | ```true``` / ```false```	| The flag indicating whether all semantic models in the workspace should be included by default; otherwise, only explicitly included semantic models will be analyzed	|
| ```RefreshAfterUpdate``` 	| boolean | ```true``` / ```false```	| The flag indicating whether semantic model refresh should be performed after all updates	|
| ```Properties```	| object | see [Properties](#properties)	| Common semantic model properties, e.g., Compatibility Mode	|
| ```Parameterize``` | boolean | ```true``` / ```false```	| The flag indicating whether semantic model parameters will be created 	|
| ```Parameters```	| array | see [Parameters](#parameters)	| The list of parameters to be created in semantic models	|
| ```Datasets```	| array |   see [Dataset Properties](#dataset-properties)	| Configurations to be set at dataset (semantic model) level.<br>For a detailed description, see the Dataset Properties section of this guide	|
| ```Updates```	| array | see [Updates](#updates)	| The array of semantic model configurations. The accelerator will analyze and update every semantic model explicitly mentioned in this array.	|
| ```SkipTables```	| array | ```["TableA", "TableB"]```	| The list of table names to skip during processing. Overrides the general setting for this workspace.	|


## Folder Properties
These properties are configured at local folder level. The format is a list of key-value pairs in JSON. If the settings are not provided, the general settings will be used:

| **Setting** 	| **Type** | **Sample values**                  | Description 	|
|---	|--- |---	|---	|
| ```Path``` | string | ```.\Sample Reports```	| The path to the local folder	|
| ```IncludeAll``` | boolean | ```true``` / ```false```	| The flag indicating whether all Power BI reports in the folder should be included by default; otherwise, only explicitly included Power BI reports will be analyzed	|
| ```RefreshAfterUpdate``` 	| boolean | ```true``` / ```false```	| Not applicable to local folders	|
| ```Properties```	| object | see [Properties](#properties)	| Not applicable to local folders	|
| ```Parameterize``` | boolean | ```true``` / ```false```	| The flag indicating whether semantic model parameters will be created 	|
| ```Parameters```	| array | see [Parameters](#parameters)	| The list of parameters to be created in semantic models	|
| ```Datasets```	| array |   see [Dataset Properties](#dataset-properties)	| Configurations to be set at dataset (semantic model) level.<br>For a detailed description, see the Dataset Properties section of this guide	|
| ```Updates```	| array | see [Updates](#updates)	| The array of semantic model configurations. The accelerator will analyze and update every semantic model explicitly mentioned in this array.	|
| ```SkipTables```	| array | ```["TableA", "TableB"]```	| The list of table names to skip during processing. Overrides the general setting for this folder.	|


## Dataset Properties
These properties are configured at dataset level. The format is a list of key-value pairs in JSON. If these settings are not provided, the workspace settings will be applied. In case the latter is not provided either, general settings will be used:

| **Setting** 	| **Type** | **Sample Values** 	| Description 	|
|---	|--- |---	|---	|
| ```Name```	| string | ```sample-dataset-name```	| The name of a published semantic model or file name (without extension) for local files	|
| ```Skip```	| boolean   | ```true``` / ```false```	| The flag indicating whether to update a semantic model or skip it	|
| ```Properties```	| object    | see [Properties](#properties)	| Common semantic model properties, e.g., Compatibility Mode	|
| ```Parameterize```	| boolean   | ```true``` / ```false```	| The flag indicating whether semantic model parameters will be created 	|
| ```Parameters```	| array | see [Parameters](#parameters)	| The list of parameters to be created in the semantic model	|
| ```Updates```	| array | see [Updates](#updates)	| The list of updates to be applied on the semantic model	|
| ```SkipTables```	| array | ```["TableA", "TableB"]```	| The list of table names to skip during processing. Overrides workspace/folder/general settings for this dataset.	|


## Properties
The **Properties** block contains key-value pairs for common properties configured for semantic models. Currently, only the following properties are supported:
- ```CompatibilityLevel```
- ```MaxParallelismPerQuery```
- ```DataSourceDefaultMaxConnections```

For more details regarding these properties, see Microsoft documentation.
```json
"Properties": {
    "CompatibilityLevel":              1569,
    "MaxParallelismPerQuery":          11,
    "DataSourceDefaultMaxConnections": 20 
}
```

## Parameters
The **Parameters** block defines the list of parameters for semantic models. Every parameter definition includes three key-value pairs:
- ```Name``` - the name of a parameter.
- ```Value``` - the default value of a parameter.
- ```Type``` - the data type of a parameter.
```json
[ 
    { 
        "Name":     "HostName",
        "Value":    "adb-******.azuredatabricks.net",
        "Type":     "Text"
    },
    {
        "Name":     "HttpPath",
        "Value":    "/sql/1.0/warehouses/a5ad*********",
        "Type":     "Text"
    }
]
```

## Updates
The **Updates** block defines the list of update rules for semantic models. Every object in this array is defined as key-value pairs:
- ```Name``` - the name of the update rule, informational only.
- ```Enabled``` - the flag indicating whether this update rule should be applied or skipped.
- ```Order``` - the order in which this update rule will be applied.
- ```SearchPattern``` - regular expression to search in Power Query M code.
- ```ReplacePattern``` - regular expression to apply to Power Query M code.
- ```Callback``` - the definition of the callback function that performs additional M code processing, e.g., changing table name capitalization.
    - ```Module``` - the path to a PowerShell module file (*.psm1) containing the callback function definition. Paths are resolved relative to the repo root. The shipped callbacks live under [src/Callbacks/](/src/Callbacks/).
    - ```Function``` - the Verb-Noun name of the callback function exported by the module (e.g., `ConvertTo-LowerCaseTableName`, `ConvertTo-SafeTableName`, `Resolve-TableNameMapping`).


```json
[
    {
        "Name":             "update 1 name",
        "Enabled":          true/false,
        "Order":            1,
        "SearchPattern":    "regexp search pattern",
        "ReplacePattern":   "regexp replace pattern"
    },
    {
        "Name":             "update 2 name",
        "Enabled":          true/false,
        "Order":            2,
        "SearchPattern":    "regexp search pattern",
        "ReplacePattern":   null,
        "Callback":       {
            "Module":   "src/Callbacks/ConvertTo-LowerCaseTableName.psm1",
            "Function": "ConvertTo-LowerCaseTableName"
        }
    }
]

```