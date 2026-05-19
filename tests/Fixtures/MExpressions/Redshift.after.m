let
    Source = Databricks.Catalogs(ServerHostname,HTTPPath),
    databricks_Database = Source{[Name=Catalog,Kind="Database"]}[Data],
    databricks_Schema = databricks_Database{[Name=Schema,Kind="Schema"]}[Data],
    nation = databricks_Schema{[Name="nation",Kind="Table"]}[Data]
in
    nation
