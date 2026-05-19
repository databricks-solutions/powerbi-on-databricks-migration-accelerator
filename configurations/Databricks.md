# Databricks to Databricks migration

> [!NOTE]
> This scenario is relevant when Power BI semantic models need to be repointed from one **Databricks** workspace and/or SQL Warehouse to another **Databricks** workspace and/or SQL Warehouse.

## Sample configuration file
[Databricks.json](./Databricks.json)


## Description
The following picture demonstrates the changes performed by the accelerator for a table in Power BI report using **Databricks** as a data source.


![Databricks migration](/images/Databricks-migration.png)

The accelerator performs the following steps:

1. Parameterize the connection, using the ```ServerHostname``` and ```HTTPPath``` parameters.
2. Parameterize the hard-coded catalog name with the ```Catalog``` parameter.
3. Parameterize the hard-coded schema value with the ```Schema``` parameter.
4. Parameterize Native Queries using the ```ServerHostname```, ```HTTPPath```, and ```Catalog``` parameters.


## Update Rules

### 1. Databricks – parameterize connection

#### Search pattern

```
(?<Start>[\s]+[^\s]+[\s]*=[\s]*Databricks\.Catalogs[\s]*\([\s]*)(?<ServerHostname>"[^"]+")(?<Between>[\s]*\,[\s]*)(?<HTTPPath>"[^"]+")
```

#### Replace pattern

```
${Start}ServerHostname${Between}HTTPPath
```

#### Purpose
Matches any assignment of the form `<var> = Databricks.Catalogs("<host>", "<httpPath>", ...)` and replaces the two static double-quoted connection arguments with the `ServerHostname` and `HTTPPath` parameter references. The variable name, surrounding whitespace, and any optional record argument that follows are preserved verbatim.

#### Example

##### Before

```m
    Source = Databricks.Catalogs("adb-1234567890123456.7.azuredatabricks.net", "/sql/1.0/warehouses/abcdef0123456789", [Catalog="tpch"])
```

##### After

```m
    Source = Databricks.Catalogs(ServerHostname, HTTPPath, [Catalog="tpch"])
```

#### When to use

Enabled by default, `Order = 1`. Use whenever you want an existing Databricks-only `.pbip` to become workspace-portable: the same dataset can then be retargeted by editing only the `ServerHostname` / `HTTPPath` parameters in the Power BI Service or via deployment pipelines.

***

### 2. Databricks – parameterize catalog

#### Search pattern

```
(?<Start>=[\s]*Source[\s]*{[\s]*\[[\s]*Name[\s]*=[\s]*)(?<Catalog>"[^\"]+")(?<Ending>[\s]*,[\s]*Kind[\s]*=[\s]*"Database")
```

#### Replace pattern

```
${Start}Catalog${Ending}
```

#### Purpose
Locates the catalog navigation step that immediately follows the `Source` step in a standard Databricks query (`Source{[Name="<catalog>", Kind="Database"]}[Data]`) and replaces the static catalog string with the `Catalog` parameter reference. The search pattern is anchored on the literal variable name `Source`, so it does not affect later navigation steps (database/catalog references built on intermediate variables).

#### Example

##### Before

```m
    Source = Databricks.Catalogs(ServerHostname, HTTPPath),
    tpch_Database = Source{[Name="tpch",Kind="Database"]}[Data]
```

##### After

```m
    Source = Databricks.Catalogs(ServerHostname, HTTPPath),
    tpch_Database = Source{[Name=Catalog,Kind="Database"]}[Data]
```

#### When to use

Enabled by default, `Order = 2`. Enable whenever the dataset must become catalog-portable across Unity Catalog environments (dev / test / prod). Disable only when the catalog name is intentionally hardcoded and must not vary by environment.

***

### 3. Databricks – parameterize schema

#### Search pattern

```
(?<Start>[\s]*{[\s]*\[[\s]*Name[\s]*=[\s]*)(?<Schema>"[^\"]+")(?<Ending>[\s]*,[\s]*Kind[\s]*=[\s]*"Schema")
```

#### Replace pattern

```
${Start}Schema${Ending}
```

#### Purpose
Locates any `{[Name="<schema>", Kind="Schema"]}` navigation step (regardless of the variable it is applied to) and replaces the static schema string with the `Schema` parameter reference.

#### Example
##### Before

```m
    tpch_Database = Source{[Name=Catalog,Kind="Database"]}[Data],
    sf1_Schema = tpch_Database{[Name="sf1",Kind="Schema"]}[Data]
```

##### After

```m
    tpch_Database = Source{[Name=Catalog,Kind="Database"]}[Data],
    sf1_Schema = tpch_Database{[Name=Schema,Kind="Schema"]}[Data]
```

#### When to use

Enabled by default, `Order = 3`. Enable whenever queries should resolve their schema dynamically from a parameter. Note that this rule replaces the schema in *every* `Kind="Schema"` lookup, so disable it (or the `Schema` parameter must be set per-table) if a single dataset legitimately navigates several different schemas with hardcoded names.

***

### 4. Databricks – parameterize Native Queries

#### Search pattern

```
(?<Start>[\s]+[^\s]+[\s]*=[\s]*Value.NativeQuery\([\s]*Databricks\.Catalogs[\s]*\([\s]*)(?<ServerHostname>"[^"]+")(?<Between>[\s]*\,[\s]*)(?<HTTPPath>"[^"]+")
```

#### Replace pattern

```
${Start}ServerHostname${Between}HTTPPath
```

#### Purpose
This rule is the counterpart to Rule 1 for queries wrapped in `Value.NativeQuery(...)`. It matches `<var> = Value.NativeQuery(Databricks.Catalogs("<host>", "<httpPath>", ...), ...)` and parameterizes the Server hostname and HTTP path inside the inner `Databricks.Catalogs(...)` call without touching the surrounding native-query construct.

#### Example
##### Before

```m
    Native = Value.NativeQuery(Databricks.Catalogs("adb-1234567890123456.7.azuredatabricks.net", "/sql/1.0/warehouses/abcdef0123456789", [Catalog="tpch", Database=null]){[Name="tpch",Kind="Database"]}[Data], "SELECT * FROM sf1.nation")
```

##### After

```m
    Native = Value.NativeQuery(Databricks.Catalogs(ServerHostname, HTTPPath, [Catalog="tpch", Database=null]){[Name="tpch",Kind="Database"]}[Data], "SELECT * FROM sf1.nation")
```

#### When to use

Enabled by default, `Order = 4`. Required when a Databricks dataset uses native query (`Value.NativeQuery`) — without it, Rules 1–3 would miss the connection inside the native query wrapper.

***

### 5. Databricks – parameterize Native Queries catalog 1

#### Search pattern

```
(?<Start>Name[\s]*=[\s]*)(?<Catalog>"hive_metastore")(?<Ending>[\s]*,[\s]*Kind[\s]*=[\s]*"Database")
```

#### Replace pattern

```
${Start}Catalog${Ending}
```

#### Purpose
Targets the `{[Name="hive_metastore", Kind="Database"]}` navigation form that typically appears inside `Value.NativeQuery(Databricks.Catalogs(...){[Name="hive_metastore",Kind="Database"]}[Data], ...)` and replaces the literal `"hive_metastore"` with the `Catalog` parameter. The pattern is intentionally narrow (literal `"hive_metastore"`) so it only flips legacy HMS-bound native queries, not arbitrary catalog references.

#### Example
##### Before

```m
    Native = Value.NativeQuery(Databricks.Catalogs(ServerHostname, HTTPPath, [Catalog="hive_metastore", Database=null]){[Name="hive_metastore",Kind="Database"]}[Data], "SELECT * FROM default.nation")
```

##### After

```m
    Native = Value.NativeQuery(Databricks.Catalogs(ServerHostname, HTTPPath, [Catalog="hive_metastore", Database=null]){[Name=Catalog,Kind="Database"]}[Data], "SELECT * FROM default.nation")
```

(only the `{[Name=...,Kind="Database"]}` step is rewritten by this rule; the `[Catalog="hive_metastore", ...]` record argument is handled by Rule 6.)

#### When to use

Enabled by default, `Order = 5`. Use when migrating native queries that still reference the legacy `hive_metastore` catalog, and the catalog should become a parameter (for example, to retarget those queries to a Unity Catalog catalog).

***

### 6. Databricks – parameterize Native Queries catalog 2

#### Search pattern

```
(?<Start>Catalog[\s]*=[\s]*)(?<Catalog>"hive_metastore")
```

#### Replace pattern

```
${Start}Catalog
```

#### Purpose
Catches the other place where a native-query connection encodes the catalog: the `[Catalog="hive_metastore", ...]` record argument passed to `Databricks.Catalogs(...)`. The literal `"hive_metastore"` is replaced with the `Catalog` parameter while the `Catalog=` record-field name is preserved (note: the result `Catalog=Catalog` is intentional — the left-hand `Catalog` is the M record field, the right-hand `Catalog` is the parameter reference).

#### Example
##### Before

```m
    Native = Value.NativeQuery(Databricks.Catalogs(ServerHostname, HTTPPath, [Catalog="hive_metastore", Database=null]){[Name=Catalog,Kind="Database"]}[Data], "SELECT * FROM default.nation")
```

##### After

```m
    Native = Value.NativeQuery(Databricks.Catalogs(ServerHostname, HTTPPath, [Catalog=Catalog, Database=null]){[Name=Catalog,Kind="Database"]}[Data], "SELECT * FROM default.nation")
```

#### When to use

Enabled by default, `Order = 5`. Pairs with Rule 5: Rule 5 rewrites the `Name="hive_metastore"` lookup, this rule rewrites the `Catalog="hive_metastore"` record-field assignment. Both must run together to fully parameterize a legacy HMS-bound native query.

