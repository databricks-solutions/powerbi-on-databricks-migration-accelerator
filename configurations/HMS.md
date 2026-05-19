# HMS to Unity Catalog migration

> [!NOTE]
> This scenario is relevant when Power BI semantic models need to be repointed from **Hive metastore** to **Unity Catalog**.

## Sample configuration file
[HMS.json](./HMS.json)


## Description
The following picture demonstrates the changes performed by the accelerator for a table in Power BI report using **Hive metastore** as a data source.
![HMS migration](/images/HMS-migration.png)

The accelerator performs the following steps:

1. Parameterize the connection, using the ```ServerHostname``` and ```HTTPPath``` parameters.
2. Replace the hard-coded catalog name ```hive_metastore``` with the ```Catalog``` parameter.
3. Replace the hard-coded schema value with the ```Schema``` parameter.


## Update Rules

### 1. HMS to UC – parameterize connection

#### Search pattern

```
(?<Start>[\s]+[^\s]+[\s]*=[\s]*Databricks\.Catalogs[\s]*\([\s]*)(?<ServerHostname>"[^"]+")(?<Between>[\s]*\,[\s]*)(?<HTTPPath>"[^"]+")
```

#### Replace pattern

```
${Start}ServerHostname${Between}HTTPPath
```

#### Purpose
This rule matches any assignment of the form `<var> = Databricks.Catalogs("<host>", "<httpPath>", ...)` and replaces the two static double-quoted connection arguments with the `ServerHostname` and `HTTPPath` parameter references. The variable name, surrounding whitespace, and any optional record argument that follows are preserved verbatim.

#### Example
##### Before

```m
    Source = Databricks.Catalogs("adb-1234567890123456.7.azuredatabricks.net", "/sql/1.0/warehouses/abcdef0123456789", [Catalog="hive_metastore"])
```

##### After

```m
    Source = Databricks.Catalogs(ServerHostname, HTTPPath, [Catalog="hive_metastore"])
```

#### When to use

Enabled by default, `Order = 1`. Use when migrating from a static `Databricks.Catalogs(...)` connection to a parameterized form so the same `.pbip` becomes workspace-portable across dev / test / prod.

***

### 2. HMS to UC – parameterize catalog "hive_metastore"

#### Search pattern

```
(?<Start>=[\s]*[^\s]+[\s]*{[\s]*\[[\s]*Name[\s]*=[\s]*)(?<HMS>"hive_metastore")(?<Ending>[\s]*,[\s]*Kind[\s]*=[\s]*"Database")
```

#### Replace pattern

```
${Start}Catalog${Ending}
```

#### Purpose
This rule finds catalog navigation steps where the catalog is hardcoded to `"hive_metastore"` (`= <var>{[Name="hive_metastore",Kind="Database"]}`) and replaces the literal string with the `Catalog` parameter reference. Anchored on `=` and the variable preceding the lookup so it only fires on real navigation steps, not on incidental occurrences of the string.

#### Example

##### Before

```m
    hive_metastore_Database = Source{[Name="hive_metastore",Kind="Database"]}[Data]
```

##### After

```m
    hive_metastore_Database = Source{[Name=Catalog,Kind="Database"]}[Data]
```

#### When to use

Enabled by default, `Order = 2`. Required core HMS-to-UC migration step. It removes the hardcoded `"hive_metastore"` catalog reference so the dataset can be retargeted to any Unity Catalog catalog by changing the `Catalog` parameter.

***

### 3. HMS to UC – parameterize catalog "SPARK"

#### Search pattern

```
(?<Start>=[\s]*[^\s]+[\s]*{[\s]*\[[\s]*Name[\s]*=[\s]*)(?<HMS>"SPARK")(?<Ending>[\s]*,[\s]*Kind[\s]*=[\s]*"Database")
```

#### Replace pattern

```
${Start}Catalog${Ending}
```

#### Purpose
Rule 3 is identical in structure to Rule 2, except that it targets the literal `"SPARK"` catalog instead of `"hive_metastore"`. The `"SPARK"` catalog is the historical name surfaced by the legacy Spark connector to Power BI; this rule replaces it with the `Catalog` parameter.

#### Example

##### Before

```m
    SPARK_Database = Source{[Name="SPARK",Kind="Database"]}[Data]
```

##### After

```m
    SPARK_Database = Source{[Name=Catalog,Kind="Database"]}[Data]
```

#### When to use

Disabled by default, `Order = 2`. Enable only when the source `.pbip` was authored against the legacy Spark connector (which exposes a single catalog called `SPARK`) and you want to retarget those queries to a Unity Catalog catalog.

***

### 4. HMS to UC – parameterize schema 1

#### Search pattern

```
(?<Start>[\s]*{[\s]*\[[\s]*Name[\s]*=[\s]*)(?<Schema>"tpch_sf1_delta_nopartitions")(?<Ending>[\s]*,[\s]*Kind[\s]*=[\s]*"Schema")
```

#### Replace pattern

```
${Start}Schema${Ending}
```

#### Purpose
This rule locates schema navigation steps that hardcode the specific schema name `"tpch_sf1_delta_nopartitions"` and replaces the literal with the `Schema` parameter reference. The pattern is intentionally narrow — it only matches that exact schema name — so it acts as a safe, opt-in rewrite rather than touching every `Kind="Schema"` lookup.

#### Example

##### Before

```m
    tpch_sf1_delta_nopartitions_Schema = hive_metastore_Database{[Name="tpch_sf1_delta_nopartitions",Kind="Schema"]}[Data]
```

##### After

```m
    tpch_sf1_delta_nopartitions_Schema = hive_metastore_Database{[Name=Schema,Kind="Schema"]}[Data]
```

#### When to use

Enabled by default, `Order = 3`. Useful as-is for the bundled `_demo` HMS dataset; for real migrations, edit the literal in the search pattern to match the legacy schema name(s) used in your `.pbip` files (e.g., `"default"`, `"bronze"`, `"silver_landing"`).

***

### 5. HMS to UC – parameterize catalog 2

#### Search pattern

```
(?<Start>.+Databricks\.Catalogs.+Catalog[\s]*=[\s]*)(?<Catalog>"[^"]+")
```

#### Replace pattern

```
${Start}Catalog
```

#### Purpose
This rule finds occurrences of the `[Catalog="..."]` record-field assignment inside a `Databricks.Catalogs(...)` call and replaces the static catalog string with the `Catalog` parameter. The search pattern uses a greedy `.+` prefix anchored on `Databricks.Catalogs`, so it only fires when a `Catalog=` argument is part of an actual `Databricks.Catalogs(...)` call (not in some unrelated record literal).

#### Example

##### Before

```m
    Source = Databricks.Catalogs(ServerHostname, HTTPPath, [Catalog="hive_metastore", Database=null])
```

##### After

```m
    Source = Databricks.Catalogs(ServerHostname, HTTPPath, [Catalog=Catalog, Database=null])
```

(the resulting `Catalog=Catalog` is intentional — the left-hand `Catalog` is the M record field name, the right-hand `Catalog` is the parameter reference.)

#### When to use

Enabled by default, `Order = 4`. Pairs with Rule 2: Rule 2 rewrites the `{[Name="hive_metastore",Kind="Database"]}` lookup, this rule rewrites the `[Catalog="hive_metastore", ...]` argument that some `Databricks.Catalogs` invocations carry.

***

### 6. HMS to UC – parameterize catalog 3

#### Search pattern

```
(?<Start>.+=.+Item[\s]*=.+Catalog[\s]*=[\s]*)(?<Catalog>"[^"]+")
```

#### Replace pattern

```
${Start}Catalog
```

#### Purpose
This rule targets a different shape of M code: the `Source{[Item="<table>", Schema="<schema>", Catalog="<catalog>"]}` record-form table lookup that the Databricks ODBC connector sometimes produces. Replaces the static `Catalog="..."` value with the `Catalog` parameter.

#### Example

##### Before

```m
    nation_Table = Source{[Item="nation",Schema="default",Catalog="hive_metastore"]}[Data]
```

##### After

```m
    nation_Table = Source{[Item="nation",Schema="default",Catalog=Catalog]}[Data]
```

#### When to use

Enabled by default, `Order = 4`. Required when migrating datasets that use the record-form table lookup (`{[Item=..., Schema=..., Catalog=...]}`) instead of the navigation-step form (`{[Name=..., Kind="..."]}`).

***

### 7. HMS to UC – parameterize schema 2

#### Search pattern

```
(?<Start>.+Databricks\.Catalogs.+Database[\s]*=[\s]*)(?<Schema>"[^"]+")
```

#### Replace pattern

```
${Start}Schema
```

#### Purpose
This rule finds occurrences of the `[Database="..."]` record-field assignment inside a `Databricks.Catalogs(...)` call and replaces the static value with the `Schema` parameter. Note: in the `Databricks.Catalogs` API, the field is called `Database` (legacy naming), but it actually identifies the *schema*, which is why the parameter name on the right-hand side is `Schema`.

#### Example

##### Before

```m
    Source = Databricks.Catalogs(ServerHostname, HTTPPath, [Catalog=Catalog, Database="default"])
```

##### After

```m
    Source = Databricks.Catalogs(ServerHostname, HTTPPath, [Catalog=Catalog, Database=Schema])
```

#### When to use

Enabled by default, `Order = 5`. Pairs with Rule 5 to fully parameterize the `[Catalog=..., Database=...]` argument record on `Databricks.Catalogs(...)` calls.

***

### 8. HMS to UC – parameterize schema 3

#### Search pattern

```
(?<Start>.+=.+Item[\s]*=.+Schema[\s]*=[\s]*)(?<Schema>"[^"]+")
```

#### Replace pattern

```
${Start}Schema
```

#### Purpose
This rule mirrors Rule 6 for schemas: it finds the `Schema="..."` field inside a record-form table lookup (`Source{[Item="...", Schema="...", Catalog="..."]}`) and replaces the literal with the `Schema` parameter.

#### Example

##### Before

```m
    nation_Table = Source{[Item="nation",Schema="default",Catalog=Catalog]}[Data]
```

##### After

```m
    nation_Table = Source{[Item="nation",Schema=Schema,Catalog=Catalog]}[Data]
```

#### When to use

Enabled by default, `Order = 5`. Required to parameterize the schema in record-form table lookups (`{[Item=..., Schema=..., Catalog=...]}`). Pairs with Rule 6, which handles the catalog in the same lookup form.

***

### 9. HMS to UC – parameterize Native Queries

#### Search pattern

```
(?<Start>[\s]+[^\s]+[\s]*=[\s]*Value.NativeQuery\([\s]*Databricks\.Catalogs[\s]*\([\s]*)(?<ServerHostname>"[^"]+")(?<Between>[\s]*\,[\s]*)(?<HTTPPath>"[^"]+")
```

#### Replace pattern

```
${Start}ServerHostname${Between}HTTPPath
```

#### Purpose
This rule is the counterpart to Rule 1 for native queries. It matches `<var> = Value.NativeQuery(Databricks.Catalogs("<host>", "<httpPath>", ...), ...)` and parameterizes the hostname and HTTP path inside the inner `Databricks.Catalogs(...)` call without touching the surrounding `Value.NativeQuery` construct.

#### Example

##### Before

```m
    Native = Value.NativeQuery(Databricks.Catalogs("adb-1234567890123456.7.azuredatabricks.net", "/sql/1.0/warehouses/abcdef0123456789", [Catalog="hive_metastore", Database=null]){[Name="hive_metastore",Kind="Database"]}[Data], "SELECT * FROM default.nation")
```

##### After

```m
    Native = Value.NativeQuery(Databricks.Catalogs(ServerHostname, HTTPPath, [Catalog="hive_metastore", Database=null]){[Name="hive_metastore",Kind="Database"]}[Data], "SELECT * FROM default.nation")
```

#### When to use

Enabled by default, `Order = 100`. Required when an HMS dataset uses native query (`Value.NativeQuery`) — without it, Rule 1 would miss the connection inside the native-query wrapper.

***

### 10. HMS to UC – parameterize Native Queries catalog 1

#### Search pattern

```
(?<Start>Name[\s]*=[\s]*)(?<Catalog>"hive_metastore")(?<Ending>[\s]*,[\s]*Kind[\s]*=[\s]*"Database")
```

#### Replace pattern

```
${Start}Catalog${Ending}
```

#### Purpose
This rule targets the `{[Name="hive_metastore", Kind="Database"]}` navigation step that typically appears inside `Value.NativeQuery(Databricks.Catalogs(...){[Name="hive_metastore",Kind="Database"]}[Data], ...)` and replaces the literal `"hive_metastore"` with the `Catalog` parameter. The pattern is intentionally narrow (literal `"hive_metastore"`) so it only flips legacy HMS-bound native queries.

#### Example

##### Before

```m
    Native = Value.NativeQuery(Databricks.Catalogs(ServerHostname, HTTPPath, [Catalog="hive_metastore", Database=null]){[Name="hive_metastore",Kind="Database"]}[Data], "SELECT * FROM default.nation")
```

##### After

```m
    Native = Value.NativeQuery(Databricks.Catalogs(ServerHostname, HTTPPath, [Catalog="hive_metastore", Database=null]){[Name=Catalog,Kind="Database"]}[Data], "SELECT * FROM default.nation")
```

(only the `{[Name=...,Kind="Database"]}` step is rewritten by this rule; the `[Catalog="hive_metastore", ...]` record argument is handled by Rule 11.)

#### When to use

Enabled by default, `Order = 1000`. Use when migrating native queries that still reference the legacy `hive_metastore` catalog and the catalog should become a parameter (so the same SQL can be retargeted to a Unity Catalog catalog).

***

### 11. HMS to UC – parameterize Native Queries catalog 2

#### Search pattern

```
(?<Start>Catalog[\s]*=[\s]*)(?<Catalog>"hive_metastore")
```

#### Replace pattern

```
${Start}Catalog
```

#### Purpose
This rule catches the other place where a native-query connection encodes the catalog: the `[Catalog="hive_metastore", ...]` record argument passed to `Databricks.Catalogs(...)`. The literal `"hive_metastore"` is replaced with the `Catalog` parameter while the `Catalog=` record-field name is preserved (the result `Catalog=Catalog` is intentional — record field on the left, parameter reference on the right).

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

Enabled by default, `Order = 1000`. Pairs with Rule 10: Rule 10 rewrites the `Name="hive_metastore"` lookup, this rule rewrites the `Catalog="hive_metastore"` record-field assignment. Both must run together to fully parameterize a legacy HMS-bound native query.

