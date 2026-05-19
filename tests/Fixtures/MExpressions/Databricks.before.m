let
    Source = Databricks.Catalogs("adb-2219810816778143.3.azuredatabricks.net", "/sql/1.0/warehouses/6fdebb669d2772a3", [Catalog=null, Database=null, EnableAutomaticProxyDiscovery=null]),
    samples_Database = Source{[Name="samples",Kind="Database"]}[Data],
    tpch_Schema = samples_Database{[Name="tpch",Kind="Schema"]}[Data],
    orders_Table = tpch_Schema{[Name="orders",Kind="Table"]}[Data]
in
    orders_Table