let
    Source = Databricks.Catalogs("adb-2219810816778143.3.azuredatabricks.net", "/sql/1.0/warehouses/6fdebb669d2772a3", [Catalog=null, Database=null, EnableAutomaticProxyDiscovery=null]),
    samples_Database = Source{[Name="hive_metastore",Kind="Database"]}[Data],
    tpch_Schema = samples_Database{[Name="tpch_sf1_delta_nopartitions",Kind="Schema"]}[Data],
    orders_Table = tpch_Schema{[Name="orders",Kind="Table"]}[Data],
    #"Removed Columns" = Table.RemoveColumns(orders_Table,{"O_CLERK", "O_COMMENT", "O_TOTALPRICE"}),
    #"Changed Type" = Table.TransformColumnTypes(#"Removed Columns",{{"O_ORDERDATE", type datetime}}),
    #"Filtered Rows" = Table.SelectRows(#"Changed Type", each [O_ORDERDATE] >= RangeStart and [O_ORDERDATE] < RangeEnd)
in
    #"Filtered Rows"