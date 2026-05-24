# Redshift to Databricks migration

> [!NOTE]
> This scenario is relevant when Power BI semantic models need to be repointed from **Amazon Redshift** to **Databricks SQL**.

## Sample configuration file
[Redshift.json](./Redshift.json)


## Description

The following picture demonstrates the changes performed by the accelerator for a table in Power BI report using **Amazon Redshift** as a data source.
![Redshift migration](/images/Redshift-migration.png)

The accelerator performs the following steps:

1. Change the source connector from **Redshift** to **Databricks**.
2. Parameterize the connection, using the ```ServerHostname``` and ```HTTPPath``` parameters.
3. Replace the hard-coded catalog value with the ```Catalog``` parameter.
4. Replace the hard-coded schema value with the ```Schema``` parameter.
5. Convert _UPPER_ case table names to _lower_ case using ```ConvertTo-LowerCaseTableName.psm1``` callback module.
6. _Optionally_ map schema/table names using ```Resolve-TableNameMapping.psm1``` callback module.


## Update Rules

### 1. Redshift to Databricks – replace source (parameterize connection)

#### Search pattern

```
(?<Start>[\s]+)(?<Var1>[^\s]+)(?<Part1>[\s]*=[\s]*)(?<Redshift>AmazonRedshift\.Database)(?<Part2>[\s]*\([\s]*)(?<ServerHostname>"[^\"]+")(?<Part3>[\s]*\,[\s]*)(?<Database>"[^\"]+")(?<ExtProperties>[\s]*\,[\s]*\[[^\]]*\])?(?<Part4>[\s]*\)[\s]*\,)[\s]*(?<Var2>[^\s=]+)(?<Part5>[\s]*=[\s]*)(?<Var3>[^\s=]+)(?<Part6>[\s]*\{[\s]*\[[\s]*Name[\s]*=[\s]*\")(?<Schema>[^\"]+)(?<Part7>\"[\s]*\]\}\[Data\][\s]*,)[\s]*(?<Var4>[^\s=]+)(?<Part8>[\s]*=[\s]*)(?<Var5>[^\s=]+)(?<Part9>[\s]*\{[\s]*\[[\s]*Name[\s]*=[\s]*\")(?<Table>[^\"]+)(?<Part10>\"[\s]*\]\}\[Data\])
```

#### Replace pattern

```
${Start}${Var1}${Part1}Databricks.Catalogs${Part2}ServerHostname${Part3}HTTPPath${ExtProperties}${Part4}
    databricks_Database = ${Var1}{[Name=Catalog,Kind="Database"]}[Data],
    databricks_Schema = databricks_Database{[Name=Schema,Kind="Schema"]}[Data],
    ${Var4}${Part8}databricks_Schema{[Name="${Table}",Kind="Table"]}[Data]
```

#### Purpose
Detects a complete `AmazonRedshift.Database(...)` source definition – including the schema lookup and the table lookup steps that typically follow it – and rewrites the entire fragment to use a parameterized `Databricks.Catalogs(...)` source. The connection identifiers (server, HTTP path), the catalog and the schema are all replaced by the parameters `ServerHostname`, `HTTPPath`, `Catalog` and `Schema`. The original table name is preserved verbatim.

#### Example
##### Before

```m
    Source = AmazonRedshift.Database("redshift.example.com:5439", "dev"),
    tpch_Schema = Source{[Name="tpch",Kind="Schema"]}[Data],
    NATION_Table = tpch_Schema{[Name="NATION",Kind="Table"]}[Data]
```

##### After

```m
    Source = Databricks.Catalogs(ServerHostname, HTTPPath),
    databricks_Database = Source{[Name=Catalog,Kind="Database"]}[Data],
    databricks_Schema = databricks_Database{[Name=Schema,Kind="Schema"]}[Data],
    NATION_Table = databricks_Schema{[Name="NATION",Kind="Table"]}[Data]
```

#### When to use

This is the default Redshift-to-Databricks migration path (enabled, `Order = 50`). Use it when you want the migrated dataset to be fully parameterized so the same `.pbip` can target multiple Databricks workspaces, catalogs and schemas without code changes.

***

### 2. Redshift to Databricks – replace source (keep schema name untouched)

#### Search pattern

```
(?<Start>[\s]+)(?<Var1>[^\s]+)(?<Part1>[\s]*=[\s]*)(?<Redshift>AmazonRedshift\.Database)(?<Part2>[\s]*\([\s]*)(?<ServerHostname>"[^\"]+")(?<Part3>[\s]*\,[\s]*)(?<Database>"[^\"]+")(?<ExtProperties>[\s]*\,[\s]*\[[^\]]*\])?(?<Part4>[\s]*\)[\s]*\,)[\s]*(?<Var2>[^\s=]+)(?<Part5>[\s]*=[\s]*)(?<Var3>[^\s=]+)(?<Part6>[\s]*\{[\s]*\[[\s]*Name[\s]*=[\s]*\")(?<Schema>[^\"]+)(?<Part7>\"[\s]*\]\}\[Data\][\s]*,)[\s]*(?<Var4>[^\s=]+)(?<Part8>[\s]*=[\s]*)(?<Var5>[^\s=]+)(?<Part9>[\s]*\{[\s]*\[[\s]*Name[\s]*=[\s]*\")(?<Table>[^\"]+)(?<Part10>\"[\s]*\]\}\[Data\])
```

#### Replace pattern

```
${Start}${Var1}${Part1}Databricks.Catalogs${Part2}ServerHostname${Part3}HTTPPath${ExtProperties}${Part4}
    databricks_Database = ${Var1}{[Name=Catalog,Kind="Database"]}[Data],
    databricks_Schema = databricks_Database{[Name="${Schema}",Kind="Schema"]}[Data],
    ${Var4}${Part8}databricks_Schema{[Name="${Table}",Kind="Table"]}[Data]
```

#### Purpose
Same shape as Rule 1, but the schema name is kept as a string literal copied from the source – `${Schema}` – instead of being replaced with the `Schema` parameter. Server hostname, HTTP path and catalog are still parameterized; the original table name is preserved.

#### Example
##### Before

```m
    Source = AmazonRedshift.Database("redshift.example.com:5439", "dev"),
    tpch_Schema = Source{[Name="tpch",Kind="Schema"]}[Data],
    NATION_Table = tpch_Schema{[Name="NATION",Kind="Table"]}[Data]
```

##### After

```m
    Source = Databricks.Catalogs(ServerHostname, HTTPPath),
    databricks_Database = Source{[Name=Catalog,Kind="Database"]}[Data],
    databricks_Schema = databricks_Database{[Name="tpch",Kind="Schema"]}[Data],
    NATION_Table = databricks_Schema{[Name="NATION",Kind="Table"]}[Data]
```

#### When to use

When the Redshift schemas already align 1:1 with the target Databricks schemas and you do not want every dataset to depend on a `Schema` parameter. Disabled by default, `Order = 10`. Enable it instead of Rule 1 when each query should keep its original schema name hardcoded.

***

### 3. Redshift to Databricks – replace source (replace schema name with a new name)

#### Search pattern

```
(?<Start>[\s]+)(?<Var1>[^\s]+)(?<Part1>[\s]*=[\s]*)(?<Redshift>AmazonRedshift\.Database)(?<Part2>[\s]*\([\s]*)(?<ServerHostname>"[^\"]+")(?<Part3>[\s]*\,[\s]*)(?<Database>"[^\"]+")(?<ExtProperties>[\s]*\,[\s]*\[[^\]]*\])?(?<Part4>[\s]*\)[\s]*\,)[\s]*(?<Var2>[^\s=]+)(?<Part5>[\s]*=[\s]*)(?<Var3>[^\s=]+)(?<Part6>[\s]*\{[\s]*\[[\s]*Name[\s]*=[\s]*\")(?<Schema>tpch)(?<Part7>\"[\s]*\]\}\[Data\][\s]*,)[\s]*(?<Var4>[^\s=]+)(?<Part8>[\s]*=[\s]*)(?<Var5>[^\s=]+)(?<Part9>[\s]*\{[\s]*\[[\s]*Name[\s]*=[\s]*\")(?<Table>[^\"]+)(?<Part10>\"[\s]*\]\}\[Data\])
```

#### Replace pattern

```
${Start}${Var1}${Part1}Databricks.Catalogs${Part2}ServerHostname${Part3}HTTPPath${ExtProperties}${Part4}
    databricks_Database = ${Var1}{[Name=Catalog,Kind="Database"]}[Data],
    databricks_Schema = databricks_Database{[Name="sf10",Kind="Schema"]}[Data],
    ${Var4}${Part8}databricks_Schema{[Name="${Table}",Kind="Table"]}[Data]
```

#### Purpose
A targeted variant of Rule 1 / Rule 2 that only matches Redshift queries whose source schema is exactly `tpch` (the `Schema` group is fixed: `(?<Schema>tpch)`). When matched, the schema is hardcoded to `"sf10"` in the rewritten Databricks query. The original table name is preserved.

#### Example
##### Before

```m
    Source = AmazonRedshift.Database("redshift.example.com:5439", "dev"),
    tpch_Schema = Source{[Name="tpch",Kind="Schema"]}[Data],
    LINEITEM_Table = tpch_Schema{[Name="LINEITEM",Kind="Table"]}[Data]
```

##### After

```m
    Source = Databricks.Catalogs(ServerHostname, HTTPPath),
    databricks_Database = Source{[Name=Catalog,Kind="Database"]}[Data],
    databricks_Schema = databricks_Database{[Name="sf10",Kind="Schema"]}[Data],
    LINEITEM_Table = databricks_Schema{[Name="LINEITEM",Kind="Table"]}[Data]
```

#### When to use

One-off renames where a specific Redshift schema must land in a differently named Databricks schema (here `tpch` → `sf10`). Disabled by default, `Order = 5`. Typically enabled for demos, POCs, or migrations where datasets reference a single legacy schema that was renamed during migration.

***

### 4. Redshift to Databricks – replace source (replace schema/table names with new names)

#### Search pattern

```
(?<Start>[\s]+)(?<Var1>[^\s]+)(?<Part1>[\s]*=[\s]*)(?<Redshift>AmazonRedshift\.Database)(?<Part2>[\s]*\([\s]*)(?<ServerHostname>"[^\"]+")(?<Part3>[\s]*\,[\s]*)(?<Database>"[^\"]+")(?<ExtProperties>[\s]*\,[\s]*\[[^\]]*\])?(?<Part4>[\s]*\)[\s]*\,)[\s]*(?<Var2>[^\s=]+)(?<Part5>[\s]*=[\s]*)(?<Var3>[^\s=]+)(?<Part6>[\s]*\{[\s]*\[[\s]*Name[\s]*=[\s]*\")(?<Schema>tpch)(?<Part7>\"[\s]*\]\}\[Data\][\s]*,)[\s]*(?<Var4>[^\s=]+)(?<Part8>[\s]*=[\s]*)(?<Var5>[^\s=]+)(?<Part9>[\s]*\{[\s]*\[[\s]*Name[\s]*=[\s]*\")(?<Table>NATION)(?<Part10>\"[\s]*\]\}\[Data\])
```

#### Replace pattern

```
${Start}${Var1}${Part1}Databricks.Catalogs${Part2}ServerHostname${Part3}HTTPPath${ExtProperties}${Part4}
    databricks_Database = ${Var1}{[Name=Catalog,Kind="Database"]}[Data],
    databricks_Schema = databricks_Database{[Name="sf100",Kind="Schema"]}[Data],
    ${Var4}${Part8}databricks_Schema{[Name="nation",Kind="Table"]}[Data]
```

#### Purpose
The most specific variant: both `Schema` and `Table` groups are fixed in the search pattern (`tpch` and `NATION` respectively). Only that exact schema/table pair is rewritten – into `sf100`/`nation` on Databricks. Useful when a single object has been renamed during migration and must be addressed individually.

#### Example
##### Before

```m
    Source = AmazonRedshift.Database("redshift.example.com:5439", "dev"),
    tpch_Schema = Source{[Name="tpch",Kind="Schema"]}[Data],
    NATION_Table = tpch_Schema{[Name="NATION",Kind="Table"]}[Data]
```

##### After

```m
    Source = Databricks.Catalogs(ServerHostname, HTTPPath),
    databricks_Database = Source{[Name=Catalog,Kind="Database"]}[Data],
    databricks_Schema = databricks_Database{[Name="sf100",Kind="Schema"]}[Data],
    NATION_Table = databricks_Schema{[Name="nation",Kind="Table"]}[Data]
```

#### When to use

Surgical overrides for a single schema + table pair. Disabled by default, `Order = 1`. Enable it only when one specific Redshift object must point to a custom-named Databricks object that does not follow the bulk migration convention.

***

### 5. Redshift to Databricks – replace table name (lower case)

#### Search pattern

```
(?<Start>[\s]*{[\s]*\[[\s]*Name[\s]*=[\s]*)(?<Table>"[^\"]+")(?<Ending>[\s]*,[\s]*Kind[\s]*=[\s]*"Table")
```

#### Replace pattern

This rule has `ReplacePattern: null`. Replacement is performed by a PowerShell `MatchEvaluator` callback:

- Module: [src/Callbacks/ConvertTo-LowerCaseTableName.psm1](/src/Callbacks/ConvertTo-LowerCaseTableName.psm1)
- Function: `ConvertTo-LowerCaseTableName`

The callback takes the captured `Table` group, lower-cases it with `ToLowerInvariant()`, and returns the original match with only the table name rewritten.

#### Purpose
Normalizes table identifiers in every `{[Name="...",Kind="Table"]}` lookup to lower case. Redshift identifiers are typically upper-case (e.g., `NATION`, `LINEITEM`), while Databricks Unity Catalog conventions use lower-case names. This rule converts the literal table name in the M code so the parameterized Databricks lookup resolves correctly.

#### Example
##### Before

```m
    NATION_Table = databricks_Schema{[Name="NATION",Kind="Table"]}[Data]
```

##### After

```m
    NATION_Table = databricks_Schema{[Name="nation",Kind="Table"]}[Data]
```

#### When to use

Enabled by default, `Order = 1000`, applied after the source-replacement rules. Keep it on whenever the Redshift environment used upper-case table names but the target Databricks/UC schema uses lower-case names. Disable it only if the target tables truly preserve the original case.

***

### 6. Databricks – map schema/table names

#### Search pattern

```
(?<Var1>[^\s=]+|#\"[^\"]+\")[\s]*=[\s]*(?<Var2>[^\s=]+|#\"[^\"]+\")(?<Start1>[\s]*{[\s]*\[[\s]*Name[\s]*=[\s]*)"(?<Schema>[^\"]+)"(?<Ending1>[\s]*,[\s]*Kind[\s]*=[\s]*"Schema")\]}\[Data\],[\s]*(?<Var3>[^\s=]+|#\"[^\"]+\")[\s]*=[\s]*(?<Var4>[^\s=]+|#\"[^\"]+\")(?<Start2>[\s]*{[\s]*\[[\s]*Name[\s]*=[\s]*)"(?<Table>[^\"]+)"(?<Ending2>[\s]*,[\s]*Kind[\s]*=[\s]*"Table")
```

#### Replace pattern

This rule has `ReplacePattern: null`. Replacement is performed by a PowerShell `MatchEvaluator` callback:

- Module: [src/Callbacks/Resolve-TableNameMapping.psm1](/src/Callbacks/Resolve-TableNameMapping.psm1)
- Function: `Resolve-TableNameMapping`
- Mapping data: [src/Callbacks/Mappings.csv](/src/Callbacks/Mappings.csv) (pipe-delimited: `SourceSchema|SourceTable|TargetSchema|TargetTable`)

For each match the callback looks up the captured `Schema` + `Table` pair in the CSV. If a row matches, it rewrites both the `Schema` and `Table` groups in place; if no row matches, the values pass through unchanged.

#### Purpose
Captures the typical two-step Databricks schema/table lookup (one `Kind="Schema"` step immediately followed by a `Kind="Table"` step) and routes the schema/table pair through an external mapping file. This decouples renaming logic from the regex engine and lets non-trivial schema+table renames live in `Mappings.csv` instead of being baked into multiple update rules.

#### Example
##### Before

```m
    databricks_Schema = databricks_Database{[Name="tpch",Kind="Schema"]}[Data],
    NATION_Table = databricks_Schema{[Name="NATION",Kind="Table"]}[Data]
```

Given a row in `Mappings.csv`:

```
SourceSchema|SourceTable|TargetSchema|TargetTable
tpch|NATION|sf100|nation
```

##### After

```m
    databricks_Schema = databricks_Database{[Name="sf100",Kind="Schema"]}[Data],
    NATION_Table = databricks_Schema{[Name="nation",Kind="Table"]}[Data]
```

#### When to use

When the renaming matrix between source and target is too large or too dynamic to express as separate hardcoded rules (Rules 3 and 4). Disabled by default, `Order = 999`, intended to be applied just before Rule 5 lower-casing. Enable it together with a populated `Mappings.csv` whenever many schema/table pairs must be remapped during migration.

***

