let
    Source = Sql.Database("myserver.sql.azuresynapse.net", "tpch"),
    dbo_LINEITEM = Source{[Schema="dbo",Item="LINEITEM"]}[Data]
in
    dbo_LINEITEM
