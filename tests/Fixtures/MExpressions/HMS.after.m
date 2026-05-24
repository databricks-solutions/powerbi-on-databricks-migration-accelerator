let
    Source = Databricks.Catalogs(ServerHostname, HTTPPath, [Catalog=null, Database=null, EnableAutomaticProxyDiscovery=null]),
    samples_Database = Source{[Name=Catalog,Kind="Database"]}[Data],
    tpch_Schema = samples_Database{[Name=Schema,Kind="Schema"]}[Data],
    orders_Table = tpch_Schema{[Name="orders",Kind="Table"]}[Data]
in
    orders_Table