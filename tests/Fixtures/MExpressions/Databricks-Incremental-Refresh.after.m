let
    Source = Databricks.Catalogs(ServerHostname, HTTPPath, [Catalog=null, Database=null, EnableAutomaticProxyDiscovery=null]),
    samples_Database = Source{[Name=Catalog,Kind="Database"]}[Data],
    tpch_Schema = samples_Database{[Name=Schema,Kind="Schema"]}[Data],
    orders_Table = tpch_Schema{[Name="orders",Kind="Table"]}[Data],
    #"Removed Columns" = Table.RemoveColumns(orders_Table,{"O_CLERK", "O_COMMENT", "O_TOTALPRICE"}),
    #"Changed Type" = Table.TransformColumnTypes(#"Removed Columns",{{"O_ORDERDATE", type datetime}}),
    #"Filtered Rows" = Table.SelectRows(#"Changed Type", each [O_ORDERDATE] >= RangeStart and [O_ORDERDATE] < RangeEnd)
in
    #"Filtered Rows"