let
    Source = Databricks.Catalogs(ServerHostname, HTTPPath),
    databricks_Database = Source{[Name=Catalog,Kind="Database"]}[Data],
    databricks_Schema = databricks_Database{[Name=Schema,Kind="Schema"]}[Data],
    dbo_LINEITEM = databricks_Schema{[Name="lineitem",Kind="Table"]}[Data]
in
    dbo_LINEITEM
