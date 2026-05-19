let
    Source = Value.NativeQuery(Databricks.Catalogs("adb-2219810816778143.3.azuredatabricks.net", "/sql/1.0/warehouses/6fdebb669d2772a3",
        [Catalog="hive_metastore", Database=null, EnableAutomaticProxyDiscovery=null]){[Name="hive_metastore",Kind="Database"]}[Data], "select * from tpch_sf1_delta_nopartitions.region", null, [EnableFolding=true])
in
    Source