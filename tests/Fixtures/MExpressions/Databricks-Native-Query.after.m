let
    Source = Value.NativeQuery(Databricks.Catalogs(ServerHostname, HTTPPath,
        [Catalog=Catalog, Database=null, EnableAutomaticProxyDiscovery=null]){[Name=Catalog,Kind="Database"]}[Data], "select * from tpch_sf1_delta_nopartitions.region", null, [EnableFolding=true])
in
    Source