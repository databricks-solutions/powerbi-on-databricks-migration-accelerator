# SQL Server to Databricks migration

> [!NOTE]
> This scenario is relevant when Power BI semantic models need to be repointed from **SQL Server** to **Databricks SQL**.

## Sample configuration file
[SqlServer.json](./SqlServer.json)


## Description
The following picture demonstrates the changes performed by the accelerator for a table in Power BI report using **SQL Server** as a data source.
![SQL Server migration](/images/SqlServer-migration.png)

The accelerator performs the following steps:

1. Change the data source connector from **SQL Server** to **Databricks** and parameterize the connection, using the ```ServerHostname```, ```HTTPPath```, ```Catalog```, and ```Schema``` parameters.
2. Convert _UPPER_ case table names to _lower_ case using ```ConvertTo-LowerCaseTableName.psm1``` callback module.


## Update Rules

### 1. SqlServer to Databricks – replace source (parameterize connection)

#### Search pattern

```
(?<Start>[\s]+)(?<Var1>[^\s]+)(?<Part1>[\s]*=[\s]*)(?<SqlServer>Sql\.Database)(?<Part2>[\s]*\([\s]*)(?<ServerHostname>"[^\"]+")(?<Part3>[\s]*\,[\s]*)(?<Database>"[^\"]+")(?<ExtProperties>[\s]*\,[\s]*\[[^\]]*\])?(?<Part4>[\s]*\)[\s]*\,[\s]*)(?<Var2>[^\s=]+)(?<Part5>[\s]*=[\s]*)(?<Var3>[^\s=]+)(?<Part6>[\s]*\{[\s]*\[[\s]*Schema[\s]*=[\s]*)(?<SchemaName>"[^\"]+")(?<Part7>[\s]*\,[\s]*Item[\s]*=[\s]*)(?<TableName>"[^\"]+")
```

#### Replace pattern

```
${Start}${Var1}${Part1}Databricks.Catalogs${Part2}ServerHostname${Part3}HTTPPath${Part4}databricks_Database = Source{[Name=Catalog,Kind="Database"]}[Data],
    databricks_Schema = databricks_Database{[Name=Schema,Kind="Schema"]}[Data],
    ${Var2}${Part5}databricks_Schema{[Name=${TableName},Kind="Table"
```

#### Purpose
Detects a SQL Server `Sql.Database(...)` source followed by a `Source{[Schema="...", Item="..."]}` table lookup and rewrites it to a parameterized `Databricks.Catalogs(...)` source with the standard three-step Databricks navigation (Catalog → Schema → Table). The schema name from SQL Server is dropped and replaced with the `Schema` parameter; the table name is preserved.

Note: the search pattern stops at the captured table name (`"..."`), and the replacement also stops at `Kind="Table"` (no closing `]}[Data]`). The unmatched original suffix `]}[Data]` is left in place by the regex engine, producing a correct closing.

#### Example

##### Before

```m
    Source = Sql.Database("sql.example.com", "AdventureWorks"),
    dbo_customer = Source{[Schema="dbo",Item="customer"]}[Data]
```

##### After

```m
    Source = Databricks.Catalogs(ServerHostname, HTTPPath),
    databricks_Database = Source{[Name=Catalog,Kind="Database"]}[Data],
    databricks_Schema = databricks_Database{[Name=Schema,Kind="Schema"]}[Data],
    dbo_customer = databricks_Schema{[Name="customer",Kind="Table"]}[Data]
```

#### When to use

This is the default SQL Server-to-Databricks migration path (enabled, `Order = 50`). Use it when you want the migrated dataset to be fully parameterized so the same `.pbip` can target multiple Databricks workspaces, catalogs and schemas without code changes.

***

### 2. SqlServer to Databricks – replace source (keep schema name untouched)

#### Search pattern

```
(?<Start>[\s]+)(?<Var1>[^\s]+)(?<Part1>[\s]*=[\s]*)(?<SqlServer>Sql\.Database)(?<Part2>[\s]*\([\s]*)(?<ServerHostname>"[^\"]+")(?<Part3>[\s]*\,[\s]*)(?<Database>"[^\"]+")(?<ExtProperties>[\s]*\,[\s]*\[[^\]]*\])?(?<Part4>[\s]*\)[\s]*\,[\s]*)(?<Var2>[^\s=]+)(?<Part5>[\s]*=[\s]*)(?<Var3>[^\s=]+)(?<Part6>[\s]*\{[\s]*\[[\s]*Schema[\s]*=[\s]*)(?<SchemaName>"[^\"]+")(?<Part7>[\s]*\,[\s]*Item[\s]*=[\s]*)(?<TableName>"[^\"]+")
```

#### Replace pattern

```
${Start}${Var1}${Part1}Databricks.Catalogs${Part2}ServerHostname${Part3}HTTPPath${Part4}databricks_Database = Source{[Name=Catalog,Kind="Database"]}[Data],
    databricks_Schema = databricks_Database{[Name=${SchemaName},Kind="Schema"]}[Data],
    ${Var2}${Part5}databricks_Schema{[Name=${TableName},Kind="Table"
```

#### Purpose
Same shape as Rule 1, but the schema name is kept as a string literal copied from the source – `${SchemaName}` – instead of being replaced with the `Schema` parameter. Server hostname, HTTP path and catalog are still parameterized; the original table name is preserved.

#### Example
##### Before

```m
    Source = Sql.Database("sql.example.com", "AdventureWorks"),
    dbo_customer = Source{[Schema="dbo",Item="customer"]}[Data]
```

##### After

```m
    Source = Databricks.Catalogs(ServerHostname, HTTPPath),
    databricks_Database = Source{[Name=Catalog,Kind="Database"]}[Data],
    databricks_Schema = databricks_Database{[Name="dbo",Kind="Schema"]}[Data],
    dbo_customer = databricks_Schema{[Name="customer",Kind="Table"]}[Data]
```

#### When to use

When the SQL Server schemas already align 1:1 with the target Databricks schemas and you do not want every dataset to depend on a `Schema` parameter. Disabled by default, `Order = 10`. Enable it instead of Rule 1 when each query should keep its original schema name hardcoded.

***

### 3. SqlServer to Databricks – replace source (replace schema name with a new name)

#### Search pattern

```
(?<Start>[\s]+)(?<Var1>[^\s]+)(?<Part1>[\s]*=[\s]*)(?<SqlServer>Sql\.Database)(?<Part2>[\s]*\([\s]*)(?<ServerHostname>"[^\"]+")(?<Part3>[\s]*\,[\s]*)(?<Database>"[^\"]+")(?<ExtProperties>[\s]*\,[\s]*\[[^\]]*\])?(?<Part4>[\s]*\)[\s]*\,[\s]*)(?<Var2>[^\s=]+)(?<Part5>[\s]*=[\s]*)(?<Var3>[^\s=]+)(?<Part6>[\s]*\{[\s]*\[[\s]*Schema[\s]*=[\s]*)(?<SchemaName>"dbo")(?<Part7>[\s]*\,[\s]*Item[\s]*=[\s]*)(?<TableName>"[^\"]+")
```

#### Replace pattern

```
${Start}${Var1}${Part1}Databricks.Catalogs${Part2}ServerHostname${Part3}HTTPPath${Part4}databricks_Database = Source{[Name=Catalog,Kind="Database"]}[Data],
    databricks_Schema = databricks_Database{[Name="sf10",Kind="Schema"]}[Data],
    ${Var2}${Part5}databricks_Schema{[Name=${TableName},Kind="Table"
```

#### Purpose
A targeted variant of Rules 1 / 2 that only matches SQL Server queries whose source schema is exactly `"dbo"` (the `SchemaName` group is fixed). When matched, the schema is hardcoded to `"sf10"` in the rewritten Databricks query. The original table name is preserved.

#### Example
##### Before

```m
    Source = Sql.Database("sql.example.com", "AdventureWorks"),
    dbo_lineitem = Source{[Schema="dbo",Item="lineitem"]}[Data]
```

##### After

```m
    Source = Databricks.Catalogs(ServerHostname, HTTPPath),
    databricks_Database = Source{[Name=Catalog,Kind="Database"]}[Data],
    databricks_Schema = databricks_Database{[Name="sf10",Kind="Schema"]}[Data],
    dbo_lineitem = databricks_Schema{[Name="lineitem",Kind="Table"]}[Data]
```

#### When to use

One-off renames where the SQL Server `dbo` schema must land in a differently named Databricks schema (here `dbo` → `sf10`). Disabled by default, `Order = 5`. Typically enabled for demos, POCs, or migrations where datasets reference a single legacy schema that was renamed during migration.

***

### 4. SqlServer to Databricks – replace source (replace schema/table names with new names)

#### Search pattern

```
(?<Start>[\s]+)(?<Var1>[^\s]+)(?<Part1>[\s]*=[\s]*)(?<SqlServer>Sql\.Database)(?<Part2>[\s]*\([\s]*)(?<ServerHostname>"[^\"]+")(?<Part3>[\s]*\,[\s]*)(?<Database>"[^\"]+")(?<ExtProperties>[\s]*\,[\s]*\[[^\]]*\])?(?<Part4>[\s]*\)[\s]*\,[\s]*)(?<Var2>[^\s=]+)(?<Part5>[\s]*=[\s]*)(?<Var3>[^\s=]+)(?<Part6>[\s]*\{[\s]*\[[\s]*Schema[\s]*=[\s]*)(?<SchemaName>"dbo")(?<Part7>[\s]*\,[\s]*Item[\s]*=[\s]*)(?<TableName>"customer")
```

#### Replace pattern

```
${Start}${Var1}${Part1}Databricks.Catalogs${Part2}ServerHostname${Part3}HTTPPath${Part4}databricks_Database = Source{[Name=Catalog,Kind="Database"]}[Data],
    databricks_Schema = databricks_Database{[Name="sf1",Kind="Schema"]}[Data],
    ${Var2}${Part5}databricks_Schema{[Name="customer",Kind="Table"
```

#### Purpose
The most specific variant: both `SchemaName` and `TableName` groups are fixed in the search pattern (`"dbo"` and `"customer"` respectively). Only that exact schema/table pair is rewritten – into `sf1`/`customer` on Databricks. Useful when a single object has been renamed during migration and must be addressed individually.

#### Example

##### Before

```m
    Source = Sql.Database("sql.example.com", "AdventureWorks"),
    dbo_customer = Source{[Schema="dbo",Item="customer"]}[Data]
```

##### After

```m
    Source = Databricks.Catalogs(ServerHostname, HTTPPath),
    databricks_Database = Source{[Name=Catalog,Kind="Database"]}[Data],
    databricks_Schema = databricks_Database{[Name="sf1",Kind="Schema"]}[Data],
    dbo_customer = databricks_Schema{[Name="customer",Kind="Table"]}[Data]
```

#### When to use

Surgical overrides for a single schema + table pair. Disabled by default, `Order = 1`. Enable it only when one specific SQL Server object must point to a custom-named Databricks object that does not follow the bulk migration convention.

***

### 5. SqlServer to Databricks – replace Native Queries

#### Search pattern

```
(?<Start>[\s]+)(?<Var1>[^\s]+)(?<Part1>[\s]*=[\s]*)(?<SqlServer>Sql\.Database)(?<Part2>[\s]*\([\s]*)(?<ServerHostname>"[^\"]+")(?<Part3>[\s]*\,[\s]*)(?<Database>"[^\"]+")(?<ExtProperties>[\s]*\,[\s]*\[[\s]*[^]]*Query[\s]*=[\s]*(?<NativeQuery>"[^\"]+")[^]]*\])(?<Part4>[\s]*\)[\s]*)
```

#### Replace pattern

```
${Start}${Var1}${Part1}Value.NativeQuery(Databricks.Catalogs${Part2}ServerHostname${Part3}HTTPPath, [Catalog=Catalog, Database=null]){[Name=Catalog,Kind="Database"]}[Data], ${NativeQuery}, null, [EnableFolding=true]${Part4}
```

#### Purpose
Detects a SQL Server `Sql.Database(...)` call whose extended-properties record carries a `Query="..."` argument (i.e. a SQL passthrough / native query) and rewrites it to use `Value.NativeQuery(...)` against `Databricks.Catalogs(...)`. The original SQL string is preserved and re-bound to the parameterized Databricks connection, with `EnableFolding=true` to allow query folding back into Databricks SQL.

#### Example

##### Before

```m
    Source = Sql.Database("sql.example.com", "AdventureWorks", [Query="SELECT TOP 100 * FROM dbo.customer"])
```

##### After

```m
    Source = Value.NativeQuery(Databricks.Catalogs(ServerHostname, HTTPPath, [Catalog=Catalog, Database=null]){[Name=Catalog,Kind="Database"]}[Data], "SELECT TOP 100 * FROM dbo.customer", null, [EnableFolding=true])
```

#### When to use

Enabled by default, `Order = 100`. Required whenever a Power BI dataset issues SQL passthrough queries against SQL Server via the `Query=` option, so the same query text continues to execute against Databricks SQL. Note that the SQL itself is left unchanged, so any T-SQL constructs not supported by Databricks SQL must still be rewritten manually.

***

### 6. SqlServer to Databricks – replace table name (lower case)

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
Normalizes table identifiers in every `{[Name="...",Kind="Table"]}` lookup to lower case. SQL Server tables are often defined with mixed-case or upper-case names (e.g., `Customer`, `SalesOrderHeader`), while Databricks Unity Catalog conventions use lower-case names. This rule converts the literal table name in the M code so the parameterized Databricks lookup resolves correctly after Rules 1–4 have rewritten the source.

#### Example

##### Before

```m
    dbo_customer = databricks_Schema{[Name="Customer",Kind="Table"]}[Data]
```

##### After

```m
    dbo_customer = databricks_Schema{[Name="customer",Kind="Table"]}[Data]
```

#### When to use

Enabled by default, `Order = 1000`, applied after the source-replacement rules. Keep it on whenever the SQL Server environment used mixed/upper-case table names but the target Databricks/UC schema uses lower-case names. Disable it only if the target tables truly preserve the original case.

***

### 7. Databricks – map schema/table names

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
    databricks_Schema = databricks_Database{[Name="dbo",Kind="Schema"]}[Data],
    customer_Table = databricks_Schema{[Name="customer",Kind="Table"]}[Data]
```

Given a row in `Mappings.csv`:

```
SourceSchema|SourceTable|TargetSchema|TargetTable
dbo|customer|sf1|customer
```

##### After

```m
    databricks_Schema = databricks_Database{[Name="sf1",Kind="Schema"]}[Data],
    customer_Table = databricks_Schema{[Name="customer",Kind="Table"]}[Data]
```

#### When to use

When the renaming matrix between source and target is too large or too dynamic to express as separate hardcoded rules (Rules 3 and 4). Disabled by default, `Order = 999`. Enable it together with a populated `Mappings.csv` whenever many schema/table pairs must be remapped during migration.

